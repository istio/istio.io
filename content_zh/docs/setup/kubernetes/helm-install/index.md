---
title: 使用 Helm 进行安装
description: 使用内含的 Helm chart 安装 Istio。
weight: 30
keywords: [kubernetes,helm]
aliases:
    - /docs/setup/kubernetes/helm.html
    - /docs/tasks/integrating-services-into-istio.html
---

使用 Helm 安装和配置 Istio 的快速入门说明。
这是将 Istio 安装到您的生产环境的推荐安装方式，因为它为 Istio 控制平面和数据平面 sidecar 提供了丰富的配置。

## 先决条件

1. [下载](/docs/setup/kubernetes/quick-start/#download-and-prepare-for-the-installation) 最新的 Istio 发布版本。

1. [安装 Helm 客户端](https://docs.helm.sh/using_helm/#installing-helm)。

1. Istio 默认使用 LoadBalancer service 对象类型。某些平台可能不支持该类型。对于不支持 LoadBalancer 的平台，请通过在 helm 操作的末尾添加 `--set ingress.service.type=NodePort --set ingressgateway.service.type=NodePort --set egressgateway.service.type=NodePort` 参数使用 NodePort 作为替代来安装 Istio。

## 选项1：通过 `helm template` 安装 Helm

1. 将 Istio 的核心组件渲染为名为 `istio.yaml` 的 Kubernetes 清单文件：

    * 使用 [自动 sidecar 注入](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection)（要求 Kubernetes >=1.9.0）：

        {{< text bash >}}
        $ helm template @install/kubernetes/helm/istio@ --name istio --namespace istio-system > $HOME/istio.yaml
        {{< /text >}}

    * 未使用 sidecar 注入 webhook：

        {{< text bash >}}
        $ helm template @install/kubernetes/helm/istio@ --name istio --namespace istio-system --set sidecarInjectorWebhook.enabled=false > $HOME/istio.yaml
        {{< /text >}}

1. 通过清单文件安装组件

    {{< text bash >}}
    $ kubectl create namespace istio-system
    $ kubectl create -f $HOME/istio.yaml
    {{< /text >}}

## 选项2：通过 `helm install` 安装 Helm 和 Tiller

此选项允许 Helm 和 [Tiller](https://github.com/kubernetes/helm/blob/master/docs/architecture.md#components) 管理 Istio 的生命周期。

{{< warning_icon >}} 使用 Helm 升级 Istio 还没有进行全面的测试。

1. 如果还没有为 Tiller 配置 service account，请配置一个：

    {{< text bash >}}
    $ kubectl create -f @install/kubernetes/helm/helm-service-account.yaml@
    {{< /text >}}

1. 使用 service account 在您的集群中安装 Tiller：

    {{< text bash >}}
    $ helm init --service-account tiller
    {{< /text >}}

1. 安装 Istio：

    * 使用[自动 sidecar 注入](/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection)（要求 Kubernetes >=1.9.0）：

        {{< text bash >}}
        $ helm install @install/kubernetes/helm/istio@ --name istio --namespace istio-system
        {{< /text >}}

    * 未使用 sidecar 注入 webhook：

        {{< text bash >}}
        $ helm install @install/kubernetes/helm/istio@ --name istio --namespace istio-system --set sidecarInjectorWebhook.enabled=false
        {{< /text >}}

## 使用 Helm 进行自定义

Helm chart 具有合理的默认值。在某些情况下，默认值需要被覆盖。要覆盖 Helm 值，请在 `helm install` 命令中使用 `--set key=value` 参数。在同一个 Helm 操作中可以使用多个 `--set`。

Helm chart 公开的配置选项目前处于 alpha 状态。目前公开的选项如下表所示：

| 参数 | 描述 | 值 | 默认值 |
| --- | --- | --- | --- |
| `global.hub` | 为 Istio 使用的大多数镜像指定 HUB | registry/namespace | `docker.io/istio` |
| `global.tag` | 为 Istio 使用的大多数镜像指定 TAG | 有效的镜像 tag | `0.8.0` |
| `global.proxy.image` | 指定代理镜像名 | 有效的镜像名 | `proxyv2` |
| `global.proxy.includeIPRanges` | 指定出站流量重定向到 Envoy 的 IP 范围 | CIDR 表示法表示的 IP 范围列表，使用转义的逗号（`\，`）分隔。使用 `*` 将所有出站流量重定向到 Envoy | `*` |
| `global.proxy.envoyStatsd` | 指定 Envoy 应将统计信息发送到的 Statsd server 的 host/IP 和端口 | host/IP 和 端口 | `istio-statsd-prom-bridge:9125` |
| `global.imagePullPolicy` | 指定镜像拉取策略 | 有效的镜像拉取策略 | `IfNotPresent` |
| `global.controlPlaneSecurityEnabled` | 指定是否启用控制平面 mTLS | true/false | `false` |
| `global.mtls.enabled` | 指定是否在 service 之间默认启用 TLS | true/false | `false` |
| `global.rbacEnabled` | 指定是否创建 Istio RBAC 规则 | true/false | `true` |
| `global.refreshInterval` | 指定网格发现刷新间隔 | 后跟 s 的整数 | `10s` |
| `global.arch.amd64` | 指定 `amd64` 体系结构的调度策略 | 0 = 从不, 1 = 最不优选, 2 = 无偏好, 3 = 最优选 | `2` |
| `global.arch.s390x` | 指定 `s390x` 体系结构的调度策略 | 0 = 从不, 1 = 最不优选, 2 = 无偏好, 3 = 最优选 | `2` |
| `global.arch.ppc64le` | 指定 `ppc64le` 体系结构的调度策略 | 0 = 从不, 1 = 最不优选, 2 = 无偏好, 3 = 最优选 | `2` |
| `galley.enabled` | 指定是否应安装 Galley 以进行服务器端配置验证。要求 Kubernetes 1.9 或更高版本 | true/false | `true` |

Helm chart 还为每个独立的 service 提供了显示配置选项。自定义这些每服务（per-service）的选项将由您自担风险。每服务选项通过  [`values.yaml`](https://raw.githubusercontent.com/istio/istio/{{<branch_name>}}/install/kubernetes/helm/istio/values.yaml) 文件公开。

## 自定义示例：流量管理最小集

Istio 配备了一组丰富而强大的功能，一些用户可能只需要这些功能的一部分。例如，用户可能只对安装 Istio 的流量管理所需的最小集合感兴趣。
[Helm 自定义](#使用-Helm-进行自定义)提供了选项以安装一个功能子集，该子集启用了感兴趣的功能并禁用了那些不需要的功能。

在这个示例中，我们将仅使用一组进行[流量管理](/docs/tasks/traffic-management/)所必须的组件集合来安装 Istio。

执行以下命令来安装 Pilot、Citadel、IngressGateway 和 Sidecar-Injector：

{{< text bash >}}
$ helm install install/kubernetes/helm/istio --name istio --namespace istio-system \
  --set ingress.enabled=false,gateways.istio-egressgateway.enabled=false,galley.enabled=false \
  --set mixer.enabled=false,prometheus.enabled=false,global.proxy.envoyStatsd.enabled=false
{{< /text >}}

请确保下列 Kubernetes pod 已经部署并且他们的容器已经启动并运行：`istio-pilot-*`、`istio-ingressgateway-*`、`istio-citadel-*` 和 `istio-sidecar-injector-*`。

{{< text bash >}}
$ kubectl get pods -n istio-system
NAME                                     READY     STATUS    RESTARTS   AGE
istio-citadel-b48446f79-wd4tk            1/1       Running   0          1m
istio-ingressgateway-7b77d995f7-t6ssx    1/1       Running   0          1m
istio-pilot-58c65f74bc-2f5xn             2/2       Running   0          1m
istio-sidecar-injector-86cc99578-4t58m   1/1       Running   0          1m
{{< /text >}}

在这个最小集合之下，您可以继续安装示例的 [Bookinfo](/docs/examples/bookinfo/) 应用，或者安装您自己的应用并为实例[配置请求路由](/docs/tasks/traffic-management/request-routing/)。

当然如果不需要 ingress 并且使用[手动注入](/docs/setup/kubernetes/sidecar-injection/#manual-sidecar-injection) sidecar 时，你可以进一步减少这个最小集合，只有 Pilot 和 Citadel。然而，Pilot 依赖 Citadel，所以您不能只安装其中一个。

## 卸载

* 对于选项1，使用 kubectl 进行卸载：

    {{< text bash >}}
    $ kubectl delete -f $HOME/istio.yaml
    {{< /text >}}

* 对于选项2，使用 Helm 进行卸载：

    {{< text bash >}}
    $ helm delete --purge istio
    {{< /text >}}

    如果您的 helm 版本低于 2.9.0，那么在重新部署新版 Istio chart 之前，您需要手动清理额外的 job 资源：

    {{< text bash >}}
    $ kubectl -n istio-system delete job --all
    {{< /text >}}