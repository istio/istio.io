---
title: 在虚拟机上部署 Bookinfo 应用程序
description: 使用在网格内的虚拟机上运行的 MySQL 服务运行 Bookinfo 应用程序。
weight: 60
keywords:
- virtual-machine
- vms
aliases:
- /zh/docs/examples/integrating-vms/
- /zh/docs/examples/mesh-expansion/bookinfo-expanded
- /zh/docs/examples/virtual-machines/bookinfo/
- /zh/docs/examples/vm-bookinfo
owner: istio/wg-environments-maintainers
test: yes
---

本示例通过在虚拟机（VM）上运行一项服务来跨 Kubernetes 部署 Bookinfo 应用程序，
并说明了如何以单个网格的形式控制此基础架构。

## 概述  {#overview}

{{< image width="80%" link="./vm-bookinfo.svg" caption="在虚拟机上运行 Bookinfo" >}}

<!-- source of the drawing
https://docs.google.com/drawings/d/1G1592HlOVgtbsIqxJnmMzvy6ejIdhajCosxF1LbvspI/edit
-->

## 开始之前  {#before-you-begin}

- 按照[虚拟机安装引导](/zh/docs/setup/install/virtual-machine/)的介绍来配置 Istio。

- 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用（在 `bookinfo` 命名空间下）。

- 按照[虚拟机配置](/zh/docs/setup/install/virtual-machine/#configure-the-virtual-machine)
  创建一个虚拟机并添加到 `vm` 命名空间下。

## 在虚拟机上运行 MySQL  {#running-MySQL-on-the-VM}

您将在虚拟机上安装 MySQL，并将其配置为 ratings 服务的后端。

下列的所有命令都在虚拟机上执行。

安装 `mariadb`：

{{< text bash >}}
$ sudo apt-get update && sudo apt-get install -y mariadb-server
$ sudo sed -i '/bind-address/c\bind-address  = 0.0.0.0' /etc/mysql/mariadb.conf.d/50-server.cnf
{{< /text >}}

设置认证信息：

{{< text bash >}}
$ cat <<EOF | sudo mysql
# 授予 root 的访问权限
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;
# 授予 root 其他 IP 的访问权限
CREATE USER 'root'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
quit;
EOF
$ sudo systemctl restart mysql
{{< /text >}}

您可以在 [Mysql](https://mariadb.com/kb/en/library/download/)
中找到配置 MySQL 的详细信息。

在虚拟机上，将 ratings 数据库导入到 mysql 中。

{{< text bash >}}
$ curl -LO {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql
$ mysql -u root -ppassword < mysqldb-init.sql
{{< /text >}}

为了便于直观地检查 Bookinfo 应用程序输出中的差异，您可以使用以下命令来更改并检查所生成的
`ratings` 数据库：

{{< text bash >}}
$ mysql -u root -ppassword test -e "select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      5 |
|        2 |      4 |
+----------+--------+
{{< /text >}}

更改 `ratings` 数据库：

{{< text bash >}}
$ mysql -u root -ppassword test -e  "update ratings set rating=1 where reviewid=1;select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      1 |
|        2 |      4 |
+----------+--------+
{{< /text >}}

## 将 mysql 服务暴露给网格  {#expose-the-mysql-service-to-the-mesh}

当虚拟机启动时，将会自动被注册到网格中。
然而，就像创建 Pod 时一样，我们仍然需要创建一个 Service，然后才能轻松访问它。

{{< text bash >}}
$ cat <<EOF | kubectl apply -f - -n vm
apiVersion: v1
kind: Service
metadata:
  name: mysqldb
  labels:
    app: mysqldb
spec:
  ports:
  - port: 3306
    name: tcp
  selector:
    app: mysqldb
EOF
{{< /text >}}

## 使用 mysql 服务  {#using-the-mysql-service}

Bookinfo 中的 ratings 服务将使用该虚拟机上的数据库。
为了验证它是否正常工作，请在虚拟机上创建使用 mysql 数据库的 ratings 服务第二个版本。
然后指定路由规则，用于强制 review 服务使用 ratings 服务的第二个版本。

{{< text bash >}}
$ kubectl apply -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql-vm.yaml@
{{< /text >}}

创建强制 Bookinfo 使用 ratings 后端的路由规则：

{{< text bash >}}
$ kubectl apply -n bookinfo -f @samples/bookinfo/networking/virtual-service-ratings-mysql-vm.yaml@
{{< /text >}}

您可以验证 Bookinfo 应用程序的输出显示的是 Reviewer1 的 1 个星，
还是 Reviewer2 的 4 个星，或者更改虚拟机的 ratings 服务并查看结果。

## 从虚拟机访问 Kubernetes 服务  {#reaching-Kubernetes-services-from-the-virtual-machine}

在上面的示例中，我们将虚拟机视为一个服务。
您还可以在您的虚拟机中无缝调用 Kubernetes 的服务：

{{< text bash >}}
$ curl productpage.bookinfo:9080
...
    <title>Simple Bookstore App</title>
...
{{< /text >}}

Istio 的 [DNS 代理](/zh/docs/ops/configuration/traffic-management/dns-proxy/)自动为您的虚拟机配置
DNS，允许通过 Kubernetes 的主机名进行访问。

## 清理  {#cleanup}

- 按照 [`Bookinfo` 清理](/zh/docs/examples/bookinfo/#cleanup)中的步骤，
  删除 `Bookinfo` 样例应用及其配置。
- 删除 `mysqldb` Service：

    {{< text syntax=bash snip_id=none >}}
    $ kubectl delete service mysqldb
    {{< /text >}}

- 按照[虚拟机卸载](/zh/docs/setup/install/virtual-machine/#configure-the-virtual-machine)
  中的步骤清理 VM。
