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
- /zh/docs/examples/vm-bookinfo
---

本示例通过在虚拟机（VM）上运行一项服务来跨 Kubernetes 部署 Bookinfo 应用程序，并说明了如何以单个网格的形式控制此基础架构。

{{< warning >}}
此示例仍在开发中，仅在 Google Cloud Platform 上进行了测试。
在 Pod 的覆盖网络与 VM 网络隔离的 IBM Cloud 或其他平台上，
即使使用 Istio，虚拟机也无法与 Kubernetes Pod 进行任何直接通信活动。
{{< /warning >}}

## 概述{#overview}

{{< image width="80%" link="./vm-bookinfo.svg" caption="Bookinfo running on VMs" >}}

<!-- source of the drawing
https://docs.google.com/drawings/d/1G1592HlOVgtbsIqxJnmMzvy6ejIdhajCosxF1LbvspI/edit
 -->

## 开始之前{#before-you-begin}

- 按照[安装指南](/zh/docs/setup/getting-started/) 中的说明安装 Istio。

- 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用程序（在 `bookinfo` 命名空间中）。

- 在与 Istio 集群相同的项目中创建一个名为 'vm-1' 的虚拟机，然后[加入网格](/zh/docs/examples/virtual-machines/single-network/)。

## 在 VM 上运行 MySQL{#running-MySQL-on-the-VM}

我们将首先在虚拟机上安装 MySQL，并将其配置为 ratings 服务的后端。

在虚拟机上：

{{< text bash >}}
$ sudo apt-get update && sudo apt-get install -y mariadb-server
$ sudo mysql
# 授予 root 的访问权限
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;
quit;
{{< /text >}}

{{< text bash >}}
$ sudo systemctl restart mysql
{{< /text >}}

您可以在 [Mysql](https://mariadb.com/kb/en/library/download/) 中找到配置 MySQL 的详细信息。

在虚拟机上，将 ratings 数据库添加到 mysql 中。

{{< text bash >}}
$ curl -q {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql | mysql -u root -ppassword
{{< /text >}}

为了便于直观地检查 Bookinfo 应用程序输出中的差异，您可以使用以下命令来更改所生成的 ratings 数据库并且检查它：

{{< text bash >}}
$ mysql -u root -password test -e "select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      5 |
|        2 |      4 |
+----------+--------+
{{< /text >}}

更改 ratings 数据库：

{{< text bash >}}
$ mysql -u root -ppassword test -e  "update ratings set rating=1 where reviewid=1;select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      1 |
|        2 |      4 |
+----------+--------+
 {{< /text >}}

## 找出将用于添加到网格中的虚拟机的 IP 地址{#find-out-the-IP-address-of-the-VM-that-will-be-used-to-add-it-to-the-mesh}

在虚拟机上：

{{< text bash >}}
$ hostname -I
{{< /text >}}

## 向网格中注册 mysql 服务{#registering-the-mysql-service-with-the-mesh}

在可以访问 [`istioctl`](/zh/docs/reference/commands/istioctl) 命令的主机上，注册虚拟机和 mysql 数据库服务。

{{< text bash >}}
$ istioctl register -n vm mysqldb <ip-address-of-vm> 3306
I1108 20:17:54.256699   40419 register.go:43] Registering for service 'mysqldb' ip '10.150.0.5', ports list [{3306 mysql}]
I1108 20:17:54.256815   40419 register.go:48] 0 labels ([]) and 1 annotations ([alpha.istio.io/kubernetes-serviceaccounts=default])
W1108 20:17:54.573068   40419 register.go:123] Got 'services "mysqldb" not found' looking up svc 'mysqldb' in namespace 'vm', attempting to create it
W1108 20:17:54.816122   40419 register.go:138] Got 'endpoints "mysqldb" not found' looking up endpoints for 'mysqldb' in namespace 'vm', attempting to create them
I1108 20:17:54.886657   40419 register.go:180] No pre existing exact matching ports list found, created new subset {[{10.150.0.5  <nil> nil}] [] [{mysql 3306 }]}
I1108 20:17:54.959744   40419 register.go:191] Successfully updated mysqldb, now with 1 endpoints
{{< /text >}}

请注意，'mysqldb' 虚拟机不需要也不应具有特殊的 Kubernetes 特权。

## 使用 mysql 服务{#using-the-mysql-service}

Bookinfo 中的 ratings 服务将使用该虚拟机上的数据库。为了验证它是否正常工作，请在虚拟机上创建使用 mysql 数据库的 ratings 服务第二个版本。然后指定路由规则，用于强制 review 服务使用 ratings 服务的第二个版本。

{{< text bash >}}
$ istioctl kube-inject -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql-vm.yaml@ | kubectl apply -n bookinfo -f -
{{< /text >}}

创建将强制 Bookinfo 使用 ratings 后端的路由规则：

{{< text bash >}}
$ kubectl apply -n bookinfo -f @samples/bookinfo/networking/virtual-service-ratings-mysql-vm.yaml@
{{< /text >}}

您可以验证 Bookinfo 应用程序的输出显示的是 Reviewer1 的 1 个星，还是 Reviewer2 的 4 个星，或者更改虚拟机的 ratings 服务并查看结果。

同时，您还可以在 [RawVM MySQL]({{< github_blob >}}/samples/rawvm/README.md) 文档中找到一些疑难解答和其他信息。
