---
title: 安装配置
description: 描述 Istio 内置的安装配置文件。
weight: 35
aliases:
    - /zh/docs/setup/kubernetes/additional-setup/config-profiles/
keywords: [profiles,install,helm]
---

本页面描述了在[安装 Istio](/zh/docs/setup/install/istioctl/) 时所能够使用的内置配置文件。这些配置文件提供了对 Istio 控制平面和 Istio 数据平面 sidecar 的定制内容。
您可以从 Istio 内置配置文件的其中一个开始入手，然后根据您的特定需求进一步自定义配置文件。当前提供以下几种内置配置文件:

1. **default**: 根据默认的[安装选项](/zh/docs/reference/config/installation-options/)启用组件
    (建议用于生产部署)。

1. **demo**: 这一配置具有适度的资源需求，旨在展示 Istio 的功能。它适合运行 [Bookinfo](/zh/docs/examples/bookinfo/) 应用程序和相关任务。
    这是通过[快速开始](/zh/docs/setup/getting-started/)指导安装的配置，但是您以后可以通过[自定义配置](/zh/docs/setup/install/istioctl/#customizing-the-configuration)
    启用其他功能来探索更高级的任务。

    {{< warning >}}
    此配置文件启用了高级别的追踪和访问日志，因此不适合进行性能测试。
    {{< /warning >}}

1. **minimal**: 使用 Istio 的[流量管理](/zh/docs/tasks/traffic-management/)功能所需的最少组件集。

1. **sds**: 和 **default** 配置类似，但是启用了 Istio 的 [SDS (secret discovery service)](/zh/docs/tasks/security/citadel-config/auth-sds/) 功能。
    这个配置文件默认启用了附带的认证功能 (Strict Mutual TLS)。

下表中标记为 **X** 的组件就是包含在配置文件里的内容:

|     | default | demo | minimal | sds |
| --- | --- | --- | --- | --- |
| 核心组件 | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-citadel` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-galley` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-nodeagent` | | | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-pilot` | X | X | X | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-policy` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-sidecar-injector` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-telemetry` | X | X | | X |
| 插件 | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`grafana` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-tracing` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`kiali` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`prometheus` | X | X | | X |

为了进一步自定义 Istio 和安装插件，您可以在安装 Istio 时所使用的 `istioctl manifest` 命令中添加一个或多个 `--set <key>=<value>` 选项。
[安装选项](/zh/docs/reference/config/installation-options/)中列出了完整的当前所支持的安装键值对集合。

## 多集群配置{#multicluster-profiles}

Istio 提供了两个附加的内置配置文件，被专门用于配置[多集群部署](/zh/docs/ops/deployment/deployment-models/#multiple-clusters):

1. **remote**: 用于配置通过[共享控制平面](/zh/docs/setup/install/multicluster/shared-vpn/)搭建的多集群网格里的远程集群。

1. **multicluster-gateways**: 用于配置通过[多控制平面](/zh/docs/setup/install/multicluster/gateways/)搭建的多集群网格里的集群。

 **remote** 配置文件仅安装两个 Istio 核心组件:

1. `istio-citadel`

1. `istio-sidecar-injector`

 **multicluster-gateways** 配置文件除了安装和 **default** 配置文件相同的组件外，还增加了两个额外组件:

1. `istio-egressgateway` 核心组件。

1. `coredns` 插件。

参考[多集群安装说明](/zh/docs/setup/install/multicluster/)获取更多详细信息。
