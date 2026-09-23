---
title: 前提条件
overview: 检查本教程的前提条件。
weight: 1
owner: istio/wg-docs-maintainers
test: n/a
---

{{< boilerplate work-in-progress >}}

对于本教程，您需要一个 Kubernetes 集群，集群中需要包含本教程模块所用的命名空间，
您还需要一台本地电脑来执行命令。如果您有自己的集群，确保集群满足这些前提条件。

如果您在一个学习班上，并且讲师提供了一个集群，让他们来处理集群的前提条件，您可以跳过本地电脑的设置。

## Kubernetes 集群 {#kubernetes-cluster}

确保满足以下条件：

- 您拥有名为 `tutorial-cluster` 的 Kubernetes 集群管理员权限和集群上运行的虚拟机的管理员权限。
- 您可以在集群中为每个参与者创建命名空间。

## 本地电脑 {#local-computer}

确保满足以下条件：

- 您拥有本地电脑 `/etc/hosts` 文件的写入权限。
- 您可以在本地电脑下载、安装和运行命令行工具。
- 您可以在本次上课期间连接到互联网。
