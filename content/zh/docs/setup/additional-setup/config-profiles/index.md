---
title: 安装配置文件
description: 描述 Istio 内置的安装配置文件。
weight: 35
aliases:
    - /zh/docs/setup/kubernetes/additional-setup/config-profiles/
keywords: [profiles,install,helm]
owner: istio/wg-environments-maintainers
test: n/a
---

本页面描述了在[安装 Istio](/zh/docs/setup/install/istioctl/) 时所能够使用的内置配置文件。

这些配置文件是内置于 Helm Chart 中的一组带有名称的覆盖集合，在通过
`helm` 或 `istioctl` 安装 Istio 时可以使用这些配置文件。

这些配置文件为常见的部署拓扑结构和目标平台提供了对 Istio 控制面和数据面的高级定制能力。

{{< tip >}}
配置文件可以与其他值覆盖或参数组合使用，
因此配置文件中设置的任何单独值都可以通过在命令中添加 `--set` 参数手动覆盖。
{{< /tip >}}

配置文件分为两类：**部署**配置文件和**平台**配置文件，建议同时使用这两类配置文件。

- **部署**配置文件用于为特定部署拓扑（如 `default`、`remote`、`ambient` 等）提供合理的默认设置。
- **平台**配置文件用于为特定目标平台（如 `eks`、`gke`、`openshift` 等）提供必要的平台特定默认设置。

例如，如果您希望在 GKE 上安装 `default` Sidecar 数据面，建议使用如下部署和平台配置文件作为起点：

{{< tabset category-name="install-method" >}}

{{< tab name="Helm" category-value="helm" >}}

对于 Helm，请为您安装的每个 Chart 指定相同的 `profile` 和 `platform`，例如安装 `istiod`：

{{< text syntax=bash snip_id=install_istiod_helm_platform >}}
$ helm install istiod istio/istiod -n istio-system --set profile=default --set global.platform=gke --wait
{{< /text >}}

{{< /tab >}}

{{< tab name="istioctl" category-value="istioctl" >}}

对于 `istioctl`，以参数形式传入相同的 `profile` 和 `platform`：

{{< text syntax=bash snip_id=install_istiod_istioctl_platform >}}
$ istioctl install --set profile=default --set values.global.platform=gke
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< warning >}}
请注意，`helm` 和 `istioctl` 安装方式之间的一个关键区别是：
`istioctl` 的配置文件中还包含了将由 `istioctl` 自动安装的 Istio 组件列表。

而 `helm` 并不会这样做，用户需要单独使用 `helm install` 安装每一个所需的
Istio 组件，并为每个组件单独提供所需的配置文件参数。

您可以将 `istioctl` 和 `helm` 理解为共享相同名称、相同内容的配置文件，但
`istioctl` 会基于所选配置文件自动决定安装哪些组件，因此只需一条命令就能实现完整的安装效果。
{{< /warning >}}

## 部署配置文件 {#deployment-profiles}

以下是当前可用于 `istioctl` 和 `helm` 安装方式的内置于部署配置文件。
请注意，这些配置文件本质上只是 Helm 值的预设集合，并不是安装 Istio 的强制要求，
但它们为新用户提供了便捷的基础配置，推荐使用。此外，
您还可以[根据具体需求自定义配置](/zh/docs/setup/additional-setup/customize-installation/)，
超出配置文件所提供的范围。当前提供以下几种内置配置文件：

1. **default**：根据 [`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/)
    的默认设置来启用组件。
    建议用于生产部署和[多集群网格](/zh/docs/ops/deployment/deployment-models/#multiple-clusters)
    中的{{< gloss "primary cluster" >}}主集群{{< /gloss >}}。

1. **demo**：这一配置具有适度的资源需求，旨在展示 Istio 的功能。
    它适合运行 [Bookinfo](/zh/docs/examples/bookinfo/) 应用程序和相关任务。
    这是通过[快速开始](/zh/docs/setup/getting-started/)指导安装的配置。

    {{< warning >}}
    此配置文件启用了高级别的追踪和访问日志，因此不适合进行性能测试。
    {{< /warning >}}

1. **minimal**：与默认配置文件相同，但只安装了控制平面组件。
    它允许您使用[单独的配置文件](/zh/docs/setup/additional-setup/gateway/#deploying-a-gateway)
    配置控制平面和数据平面组件（例如 Gateway）。

1. **remote**：用于配置一个{{< gloss "remote cluster" >}}从集群{{< /gloss >}}，
    这个从集群由{{< gloss "external control plane" >}}外部控制平面{{< /gloss >}}管理，
    或者由[多集群网格](/zh/docs/ops/deployment/deployment-models/#multiple-clusters)的
    {{< gloss "primary cluster" >}}主集群{{< /gloss >}}中的控制平面管理。

1. **ambient**：Ambient 配置文件旨在帮助您开始使用 [Ambient 模式](/zh/docs/ambient)。

1. **empty**：不部署任何内容。可以作为自定义配置的基本配置文件。

1. **preview**：预览文件包含的功能都属于实验性阶段。该配置文件是为了探索 Istio 的新功能。
    确保稳定性、安全性和性能（使用风险需自负）。

Istio 的[部署配置文件值集合在此定义]({{< github_tree >}}/manifests/helm-profiles)，适用于 `istioctl` 和 `helm`。

仅在使用 `istioctl` 时，指定配置文件还会**自动选择**某些 Istio 组件进行安装，这些组件在下表中以 &#x2714; 标记：

| | default | demo | minimal | remote | empty | preview | ambient |
| -- | ---- | ---- | ------- | ------ | ----- | ------- | ------- |
| 核心组件（Core components） | | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | &#x2714; | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | &#x2714; | &#x2714; | | | | &#x2714; | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istiod` | &#x2714; | &#x2714; | &#x2714; | | | &#x2714; | &#x2714; |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`CNI` | | | | | | | &#x2714; |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`Ztunnel` | | | | | | | &#x2714; |

{{< tip >}}
如需进一步自定义 Istio，还可以安装多个附加组件。
详情请参阅[集成文档](/zh/docs/ops/integrations)。
{{< /tip >}}

## 平台配置文件 {#platform-profiles}

以下是目前可用于 `istioctl` 和 `helm` 安装方式的内置于平台配置文件。请注意，
这些配置文件本质上只是 Helm 值的预设集合，虽然在这些环境中安装 Istio
并不强制使用它们，但它们提供了方便的基础设置，推荐新用户使用：

1. **gke**：为在 Google Kubernetes Engine（GKE）环境中安装 Istio 设置了必要或推荐的图表选项。

1. **eks**：为在 Amazon Elastic Kubernetes Service（EKS）环境中安装 Istio 设置了必要或推荐的图表选项。

1. **openshift**：为在 OpenShift 环境中安装 Istio 设置了必要或推荐的图表选项。

1. **k3d**：为在 [k3d](https://k3d.io/) 环境中安装 Istio 设置了必要或推荐的图表选项。

1. **k3s**：为在 [K3s](https://k3s.io/) 环境中安装 Istio 设置了必要或推荐的图表选项。

1. **microk8s**：为在 [MicroK8s](https://microk8s.io/) 环境中安装 Istio 设置了必要或推荐的图表选项。

1. **minikube**：为在 [minikube](https://kubernetes.io/zh-cn/docs/tasks/tools/install-minikube/)
   环境中安装 Istio 设置了必要或推荐的图表选项。

Istio 的[平台配置文件在此定义]({{< github_tree >}}/manifests/helm-profiles)，适用于 `istioctl` 和 `helm`。
