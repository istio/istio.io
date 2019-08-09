---
title: 虚拟机集成
description: 在单一服务网格中，如何使用 Istio 对 Kubernetes 集群以及虚拟机进行控制。
weight: 60
keywords: [vms]
---

这个例子把 Bookinfo 服务部署到 Kubernetes 集群和一组虚拟机上，然后演示从单一服务网格的角度，如何使用 Istio 来对其进行控制。

{{< warning >}}
这个例子还在开发之中，只在 Google Cloud Platform 上进行了测试。Pod 叠加网络和虚拟机网络之间进行隔离的平台，例如 IBM Cloud，即使有 Istio 的帮助，虚拟机还是无法建立到 Kubernetes Pod 的直接连接的。
{{< /warning >}}

## 概述

{{< image width="80%"
    link="mesh-expansion.svg"
    caption="网格扩展环境下的 Bookinfo 应用"
    >}}

<!-- 原图 https://docs.google.com/drawings/d/1gQp1OTusiccd-JUOHktQ9RFZaqREoQbwl2Vb-P3XlRQ/edit -->

## 开始之前

* 依照[安装指南](/zh/docs/setup/kubernetes/install/kubernetes/)部署 Istio。

* 部署 [Bookinfo](/zh/docs/examples/bookinfo/) 示例应用（在 `bookinfo` 命名空间）。

* 创建一个虚拟机，命名为 `vm1`，和 Istio 集群处于同一项目之中，并且将其[加入集群](/zh/docs/setup/kubernetes/additional-setup/mesh-expansion/)。

## 在虚拟机上运行 MySQL

首先在虚拟机上安装 MySQL，然后将其作为 `ratings` 服务的后端。

虚拟机端：

{{< text bash >}}
$ sudo apt-get update && sudo apt-get install -y mariadb-server
$ sudo mysql
# 授予 root 权限
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'password' WITH GRANT OPTION;
quit;
{{< /text >}}

{{< text bash >}}
$ sudo systemctl restart mysql
{{< /text >}}

可以在 [Mysql 网站](https://mariadb.com/kb/en/library/download/)获取关于 MySQL 配置方面的信息。

在虚拟机上把 `ratings` 数据库加入 MySQL。

{{< text bash >}}
$ curl -q {{< github_file >}}/samples/bookinfo/src/mysql/mysqldb-init.sql | mysql -u root -ppassword
{{< /text >}}

为了更清晰的观察 Bookinfo 应用在输出方面的差异，可以用下面的命令来修改评级记录，从而生成不同的评级显示：

{{< text bash >}}
$ mysql -u root -ppassword test -e "select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      5 |
|        2 |      4 |
+----------+--------+
{{< /text >}}

修改评级数据：

{{< text bash >}}
$ mysql -u root -ppassword test -e  "update ratings set rating=1 where reviewid=1;select * from ratings;"
+----------+--------+
| ReviewID | Rating |
+----------+--------+
|        1 |      1 |
|        2 |      4 |
+----------+--------+
 {{< /text >}}

## 查找虚拟机的 IP 地址，用来加入服务网格

虚拟机端：

{{< text bash >}}
$ hostname -I
{{< /text >}}

## 在网格中注册 MySQL 服务

在一个能够使用 `istioctl` 命令的主机上，注册虚拟机和 MySQL 服务：

{{< text bash >}}
$ istioctl register -n vm mysqldb <ip-address-of-vm> 3306
I1108 20:17:54.256699   40419 register.go:43] Registering for service 'mysqldb' ip '10.150.0.5', ports list [{3306 mysql}]
I1108 20:17:54.256815   40419 register.go:48] 0 labels ([]) and 1 annotations ([alpha.istio.io/kubernetes-serviceaccounts=default])
W1108 20:17:54.573068   40419 register.go:123] Got 'services "mysqldb" not found' looking up svc 'mysqldb' in namespace 'vm', attempting to create it
W1108 20:17:54.816122   40419 register.go:138] Got 'endpoints "mysqldb" not found' looking up endpoints for 'mysqldb' in namespace 'vm', attempting to create them
I1108 20:17:54.886657   40419 register.go:180] No pre existing exact matching ports list found, created new subset {[{10.150.0.5  <nil> nil}] [] [{mysql 3306 }]}
I1108 20:17:54.959744   40419 register.go:191] Successfully updated mysqldb, now with 1 endpoints
{{< /text >}}

注意 'mysqldb' 虚拟机不需要也不应该具有特别的 Kubernetes 授权。

## 使用 MySQL 服务

Bookinfo 应用中的 `ratings` 服务会使用刚才部署的数据库服务。要验证他的工作情况，可以创建 `ratings:v2` 服务来访问虚拟机上的 MySQL 服务。然后制定路由规则，强制 `review` 服务使用 `ratings:v2`。

{{< text bash >}}
$ istioctl kube-inject -n bookinfo -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2-mysql-vm.yaml@ | kubectl apply -n bookinfo -f -
{{< /text >}}

创建路由规则，强制 Bookinfo 使用 ratings 后端：

{{< text bash >}}
$ istioctl create -n bookinfo -f @samples/bookinfo/networking/virtual-service-ratings-mysql-vm.yaml@
{{< /text >}}

可以检查一下 Bookinfo 应用的输出，会看到 Reviewer1 给出了 1 星，而 Reviewer2 给出了 4 星，或者还可以修改虚拟机上的数据来查看变更的结果。

另外可以在 [RawVM MySQL]({{< github_blob >}}/samples/rawvm/README.md) 文档中找到除错等方面的详细信息。
