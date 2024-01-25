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
这些配置文件提供了对 Istio 控制平面和 Istio 数据平面 Sidecar 的定制内容。

您可以从其中一个 Istio 内置配置文件开始入手，
然后根据您的特定需求进一步[自定义配置文件](/zh/docs/setup/additional-setup/customize-installation/)。
当前提供以下几种内置配置文件：

1. **default**：根据 [`IstioOperator` API](/zh/docs/reference/config/istio.operator.v1alpha1/) 的默认设置来启用组件。
    建议用于生产部署和[多集群网格](/zh/docs/ops/deployment/deployment-models/#multiple-clusters)
    中的{{< gloss "primary cluster" >}}主集群{{< /gloss >}}。

    您可以运行 `istioctl profile dump` 命令来查看默认设置。

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

1. **empty**：不部署任何内容。可以作为自定义配置的基本配置文件。

1. **preview**：预览文件包含的功能都属于实验性阶段。该配置文件是为了探索 Istio 的新功能。
    确保稳定性、安全性和性能（使用风险需自负）。

1. **ambient**：Ambient 配置文件旨在帮助您开始使用 [Ambient Mesh](/zh/docs/ops/ambient)。

    {{< boilerplate ambient-alpha-warning >}}

{{< tip >}}
此外，还提供了一些其他特定的配置文件。更多相关信息，
请参阅[平台安装](/zh/docs/setup/platform-setup)。
{{< /tip >}}

标注 &#x2714; 的组件安装在每个配置文件中：

|     | default | demo | minimal | remote | empty | preview | ambient |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 核心组件 | | | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | &#x2714; | | | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | &#x2714; | &#x2714; | | | | &#x2714; | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istiod` | &#x2714; | &#x2714; | &#x2714; | | | &#x2714; | &#x2714; |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`CNI` | | | | | | | &#x2714; |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`Ztunnel` | | | | | | | &#x2714; |

为了进一步自定义 Istio，还可以安装一些附加组件。详情请参阅[集成](/zh/docs/ops/integrations)。
