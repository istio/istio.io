---
title: Kubernetes
description: 关于如何在 Kubernetes 集群中安装 Istio 控制平面和添加虚拟机到 mesh 中的说明。
weight: 10
icon: kubernetes
keywords: [kubernetes,install,quick-start,setup,installation]
content_above: true
---

{{< tip >}}
Istio {{< istio_version >}} 已经在这些 Kubernetes 版本上进行过测试：{{< supported_kubernetes_versions >}}。
{{< /tip >}}

## 入门

Istio 提供多种安装路径，具体取决于您的 Kubernetes 平台。

但是，无论平台如何，基本流程都是相同的：

1. [查看 pod 要求](/zh/docs/setup/kubernetes/additional-setup/requirements/)
1. [准备您的 Istio 平台](/zh/docs/setup/kubernetes/platform-setup/)
1. [在您的平台上安装 Istio](/zh/docs/setup/kubernetes/)

某些平台还需要您手动[下载最新的Istio版本](/zh/docs/setup/kubernetes/download-release/)。

在决定时，您是否打算在生产中使用 Istio 是至关重要的
要执行哪个安装。

## 评估 Istio

要快速测试 Istio 的功能，您可以：

- 在[没有 Helm 的情况下在 Kubernetes](/zh/docs/setup/kubernetes/install/kubernetes/) 上安装 Istio
- 执行 Istio 的[最小安装](/zh/docs/setup/kubernetes/install/minimal/)

## 安装 Istio 用于生产

我们建议您使用 [Helm 安装指南](/zh/docs/setup/kubernetes/install/helm/)安装Istio进行生产

如果在支持的平台上运行 Kubernetes，则可以按照说明进行操作
特定于您的 Kubernetes 平台：

- [Alibaba Cloud Kubernetes Container Service](/zh/docs/setup/kubernetes/install/alicloud/)
- [Google Kubernetes Engine](/zh/docs/setup/kubernetes/install/gke/)
- [IBM Cloud](/zh/docs/setup/kubernetes/install/ibm/)

如果要通过容器网络接口安装和使用 Istio
（CNI），访问我们的 [CNI 指南](/zh/docs/setup/kubernetes/install/cni/)。

如果要执行多集群设置，请访问我们的 [Multicluster 安装文档](/zh/docs/setup/kubernetes/multicluster/)。

## 向网格添加服务

使用未运行的其他容器或 VM 扩展现有网格
你的网格的 Kubernetes 集群，请遵循我们的[网格扩展指南](/zh/docs/setup/kubernetes/additional-setup/mesh-expansion/).

添加服务需要详细了解 sidecar 注入。请访问我们的[安装 sidecar 指南](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/)以了解更多信息。
