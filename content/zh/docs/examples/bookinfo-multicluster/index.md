---
title: Bookinfo 应用 - 多集群
description: 跨多集群网格部署示例应用程序。
weight: 11
keywords: [multicluster]
---

{{< boilerplate experimental-feature-warning >}}

本示例是对[简化版多集群设置过程](/zh/docs/setup/install/multicluster/simplified)的补充。
它向您展示了如何跨多集群网格部署 Istio 的经典 [Bookinfo](/zh/docs/examples/bookinfo) 示例应用。

## 让它运行起来{#getting-it-running}

1. 请先从[这些说明](/zh/docs/setup/install/multicluster/simplified)开始，它将向您展示如何配置一个 3 集群的网格。

1. 下载 [`setup-bookinfo.sh` 脚本]({{< github_file >}}/samples/multicluster/setup-bookinfo.sh)并保存至上一步中创建的工作目录中。

1. 运行下载的脚本：

    {{< text bash >}}
    $ ./setup-bookinfo.sh install
    {{< /text >}}

    这将会把 Bookinfo 部署到网格的所有集群中。

## 观察它能否正常工作{#showing-that-its-working}

现在 Bookinfo 已经部署到所有的集群中了，我们可以禁用掉它的某些集群中的某些服务，然后观察整个应用继续保持响应状态，表明流量可以根据需要在群集之间透明地流动。

让我们禁用掉一些服务：

{{< text bash >}}
$ for DEPLOYMENT in details-v1 productpage-v1 reviews-v2 reviews-v3; do
$    kubectl --context=context-east-1 scale deployment ${DEPLOYMENT} --replicas=0
$ done
$ for DEPLOYMENT in details-v1 reviews-v2 reviews-v3 ratings-v1; do
$    kubectl --context=context-east-2 scale deployment ${DEPLOYMENT} --replicas=0
$ done
$ for DEPLOYMENT in productpage-v1 reviews-v2 reviews-v1 ratings-v1; do
$    kubectl --context=context-west-1 scale deployment ${DEPLOYMENT} --replicas=0
$ done
{{< /text >}}

现在请参考 [常规的 Bookinfo](/zh/docs/examples/bookinfo) 来证明多集群部署是可以正常运行的。

## 清理{#clean-up}

您可以使用以下命令从所有集群中删除 Bookinfo：

{{< text bash >}}
$ ./setup-bookinfo.sh uninstall
{{< /text >}}
