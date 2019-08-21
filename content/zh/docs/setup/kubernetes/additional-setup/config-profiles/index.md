---
title: 安装配置
description: Istio 内置的安装配置文件介绍。
weight: 35
keywords: [profiles,install,helm]
---

本页面描述了内置的安装配置文件，可以在[使用 Helm 安装 Istio](/zh//docs/setup/kubernetes/install/helm/) 的过程中使用。这些配置文件提供了对 Istio 控制面和数据面的定制内容。可以从内置的配置文件入手，开始安装 Istio，也可以根据这些配置文件进行进一步的按需定制。其中包括：

1. **default**：根据缺省的[安装选项](/zh/docs/reference/config/installation-options/)启用组件（生产环境部署时推荐使用本方案）。

1. **demo**：这一配置用于演示 Istio 的功能，使用了较为保守的资源需求。可以用于运行 [Bookinfo](/zh/docs/examples/bookinfo/) 以及相关任务。

    这个配置和[快速开始](/zh/docs/setup/kubernetes/install/kubernetes/)中介绍的配置是一致的，只是在有更多需求的时候，可以通过 Helm 来进行定制。这个配置包含了两个变体，分别代表启用或未启用认证功能：

    {{< warning >}}
    这个配置中启用了较多的访问日志和跟踪数据，所以不适合用于性能测试的场合。
    {{< /warning >}}

1. **minimal**：使用 Istio [流量管理](/zh/docs/tasks/traffic-management/)功能所需的最小组件集。

1. **sds**：和 **default** 配置类似，但是启用了 [SDS (secret discovery service)](/docs/tasks/security/auth-sds) 功能。

    这一配置中也启用了认证功能。

下表中标记为 **X** 的功能就是包含在配置文件里面的内容：

| | default | demo | minimal | sds |
| --- | :---: | :---: | :---: | :---: |
| Profile filename | `values.yaml` | `values-istio-demo.yaml` | `values-istio-minimal.yaml` | `values-istio-sds-auth.yaml` |
| Core components | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-citadel` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-egressgateway` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-galley` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-ingressgateway` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-nodeagent` | | | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-pilot` | X | X | X | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-policy` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-sidecar-injector` | X | X | | X |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-telemetry` | X | X | | X |
| Addons | | | | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`grafana` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`istio-tracing` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`kiali` | | X | | |
| &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`prometheus` | X | X | | X |

有些配置文件会有一个带有认证功能的变体，文件名会加入 `-auth`，这种配置会加入以下几个功能：

| | default | demo | minimal | sds |
| --- | :---: | :---: | :---: | :---: |
| Control Plane Security | | X | | |
| Strict Mutual TLS | | X | | X |
| SDS | | | | X |

要进一步的对 Istio 进行定制或添加插件，可以在 `helm template` 或者 `helm install` 命令中加入一个或多个的 `--set <key>=<value>`，[安装选项说明](/zh/docs/reference/config/installation-options/)中介绍了安装过程中可用的完整的键值对。

## 多集群配置

Istio 提供了两种附加的内置配置，专门用于搭建[多集群服务网格](/docs/concepts/deployment-models/#multiple-clusters)。

1. **remote**：用于搭建[单控制平面拓扑](/docs/concepts/deployment-models/#single-control-plane)的多集群网格。

1. **multicluster-gateways**：用来搭建[多控制平面拓扑](/docs/concepts/deployment-models/#multiple-control-planes)的多集群网络。

**remote** 配置对应的配置文件是 `values-istio-remote.yaml`。这个配置仅安装两个核心组件：

1. `istio-citadel`

1. `istio-sidecar-injector`

**multicluster-gateways** 配置使用的配置文件是 `values-istio-multicluster-gateways.yaml`。它安装了跟 **default** 安装相同的组件之外，还加入了两个组件：

1. `istio-egressgateway` 核心组件。

1. `coredns` 插件。

参考[多集群安装](/zh/docs/setup/kubernetes/install/multicluster/)文档获取更多相关信息。
