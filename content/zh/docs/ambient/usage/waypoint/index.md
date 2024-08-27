---
title: 配置 waypoint 代理
description: 通过可选的 Layer 7 代理获得完整的 Istio 功能集。
weight: 30
aliases:
  - /zh/docs/ops/ambient/usage/waypoint
  - /zh/latest/docs/ops/ambient/usage/waypoint
owner: istio/wg-networking-maintainers
test: yes
---

**waypoint 代理**是基于 Envoy 代理的可选部署，用于将 Layer 7（L7）处理添加到一组定义的工作负载中。

waypoint 代理的安装、升级和扩缩独立于应用；应用所有者不会感知到它们的存在。
与每个工作负载并行运行 Envoy 代理实例的 Sidecar {{< gloss "data plane" >}}数据平面{{< /gloss >}}模式相比，
所需的代理数量可以大大减少。

一个或一组 waypoint 可以在具有相似安全边界的应用之间共享。
这可能是特定工作负载的所有实例，或者命名空间中的所有工作负载。

与 {{< gloss "sidecar" >}}Sidecar{{< /gloss >}} 模式相比，在 Ambient 模式下，
策略由**目标** waypoint 强制执行。在许多方面，waypoint 充当资源（命名空间、服务或 Pod）的网关。
Istio 强制所有进入资源的流量都经过 waypoint，然后 waypoint 强制执行该资源的所有策略。

## 您需要 waypoint 代理吗？ {#do-you-need-a-waypoint-proxy}

Ambient 的分层方法允许用户以更细致的递进方式采用 Istio，
从无网格平滑过渡到安全的 L4 覆盖，再到完整的 L7 处理。

Ambient 模式的大部分功能都是由 ztunnel 节点代理提供的。
ztunnel 的范围仅限于处理 Layer 4（L4）的流量，因此它可以作为共享组件安全地运行。

当您配置重定向到某个 waypoint 时，流量将由 ztunnel 转发到该 waypoint。
如果您的应用需要以下任一 L7 网格功能，您将需要使用 waypoint 代理：

* **流量管理**：HTTP 路由和负载均衡、熔断、限流、故障注入、重试、超时
* **安全性**：基于请求类型或 HTTP 头等 L7 原装特性的丰富授权策略
* **可观察性**：HTTP 指标、访问日志、链路追踪

## 部署 waypoint 代理 {#deploy-a-waypoint-proxy}

waypoint 代理是使用 Kubernetes Gateway 资源部署的。

{{< boilerplate gateway-api-install-crds >}}

您可以使用 istioctl waypoint 子命令来生成、应用或列出这些资源。

部署 waypoint 后，整个命名空间（或您选择的任何服务或 Pod）必须先进行[注册](#useawaypoint)才能使用。

您在为特定命名空间部署 waypoint 代理之前，
请先确认该命名空间带有 `istio.io/dataplane-mode: ambient` 标签：

{{< text syntax=bash snip_id=check_ns_label >}}
$ kubectl get ns -L istio.io/dataplane-mode
NAME              STATUS   AGE   DATAPLANE-MODE
istio-system      Active   24h
default           Active   24h   ambient
{{< /text >}}

`istioctl` 可以为 waypoint 代理生成 Kubernetes Gateway 资源。
例如，要为 `default` 命名空间生成名为 `waypoint` 的 waypoint 代理，该代理可以处理命名空间中这些服务的流量：

{{< text syntax=bash snip_id=gen_waypoint_resource >}}
$ istioctl waypoint generate --for service -n default
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
{{< /text >}}

请注意，Gateway 资源具有设置为 `gatewayClassName` 的 `istio-waypoint` 标签，
这表明它是 Istio 所提供的 waypoint。Gateway 资源标有 `istio.io/waypoint-for: service`，
表示该 waypoint 默认可以处理这些服务的流量。

要直接部署 waypoint 代理，请使用 `apply` 代替 `generate`：

{{< text syntax=bash snip_id=apply_waypoint >}}
$ istioctl waypoint apply -n default
waypoint default/waypoint applied
{{< /text >}}

或者，您可以部署生成的 Gateway 资源：

{{< text syntax=bash >}}
$ kubectl apply -f - <<EOF
kind: Gateway
metadata:
  labels:
    istio.io/waypoint-for: service
  name: waypoint
  namespace: default
spec:
  gatewayClassName: istio-waypoint
  listeners:
  - name: mesh
    port: 15008
    protocol: HBONE
EOF
{{< /text >}}

当 Gateway 资源被应用后，istiod 会监控资源，
自动为用户部署和管理相应的 waypoint Deployment 和服务。

### waypoint 流量类型 {#waypoint-traffic-types}

默认情况下，waypoint 仅处理发往其命名空间中**服务**的流量。
做出这种选择是因为单独指向 Pod 的流量很少，
并且通常被用于 Prometheus 抓取等内部目的，
而且通过 L7 处理会产生额外开销，这是预期之外的开销。

waypoint 也可以处理所有流量，仅处理直接发送到集群中**工作负载**（Pod 或 VM）的流量，
或者根本不处理任何流量。被重定向到 waypoint 的流量类型由
`Gateway` 对象上的 `istio.io/waypoint-for` 标签决定。

`istioctl waypoint apply` 的 `--for` 参数可用于更改重定向到 waypoint
的[流量类型](#waypoint-traffic-types)：

| `waypoint-for` 值 | 目标类型             |
|------------------|----------------------|
| `service`        | Kubernetes 服务      |
| `workload`       | Pod IP 或 VM IP      |
| `all`            | 服务和工作负载流量     |
| `none`           | 无流量（用于测试）     |

{{< tip >}}
流量类型与原始寻址有关。一旦服务被服务网格解析为 Pod，到服务的流量就不会变成到工作负载的流量。
{{< /tip >}}

## 使用 waypoint 代理 {#useawaypoint}

当 waypoint 代理被部署后，除非您显式配置某些资源来使用它，否则它默认不会被任何资源使用。

要使命名空间、服务或 Pod 能够使用 waypoint，
请添加 `istio.io/use-waypoint` 标签，取值为 waypoint 名称。

{{< tip >}}
大多数用户希望将 waypoint 应用到整个命名空间，我们建议您从这种方法开始。
{{< /tip >}}

如果您使用 `istioctl` 部署命名空间的 waypoint，
则可以使用 `--enroll-namespace` 参数自动标记一个命名空间：

{{< text syntax=bash snip_id=enroll_ns_waypoint >}}
$ istioctl waypoint apply -n default --enroll-namespace
waypoint default/waypoint applied
namespace default labeled with "istio.io/use-waypoint: waypoint"
{{< /text >}}

或者，您可以使用 `kubectl` 将 `istio.io/use-waypoint: waypoint` 标签添加到 `default` 命名空间：

{{< text syntax=bash >}}
$ kubectl label ns default istio.io/use-waypoint=waypoint
namespace/default labeled
{{< /text >}}

当一个命名空间被注册为使用 waypoint 后，使用 Ambient 数据平面模式的任何 Pod
向该命名空间中运行的任何服务发出的所有请求都将通过 waypoint 进行路由，以进行 L7 处理和策略执行。

如果您喜欢更精细的操作粒度，而不是对整个命名空间使用 waypoint，
则可以仅注册特定服务或 Pod 来使用 waypoint。如果您只需要命名空间中的某些服务具有 L7 功能，
如果您只想将 `WasmPlugin` 之类的扩展应用于特定服务，或者如果您正在通过其 Pod IP 地址调用 Kubernetes
[无头服务](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#headless-services)，
这可能很有用。

{{< tip >}}
如果命名空间和服务上都存在 `istio.io/use-waypoint` 标签，
那么只要服务的 waypoint 可以处理 `service` 或 `all` 的流量，
该服务的 waypoint 优先级就高于命名空间的 waypoint。
同样，Pod 上的标签优先级也高于命名空间标签。
{{< /tip >}}

### 配置服务以使用特定 waypoint {#configure-a-service-to-use-a-specific-waypoint}

使用示例 [Bookinfo 应用](/zh/docs/examples/bookinfo/)中的服务，
我们可以为 `reviews` 服务部署一个名为 `reviews-svc-waypoint` 的 waypoint：

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-svc-waypoint
waypoint default/reviews-svc-waypoint applied
{{< /text >}}

为 `reviews` 服务打标签以使用 `reviews-svc-waypoint` waypoint：

{{< text syntax=bash >}}
$ kubectl label service reviews istio.io/use-waypoint=reviews-svc-waypoint
service/reviews labeled
{{< /text >}}

从网格中的 Pod 到 `reviews` 服务的所有请求现在都将通过
`reviews-svc-waypoint` waypoint 进行路由。

### 配置 Pod 以使用特定 waypoint {#configure-a-pod-to-use-a-specific-waypoint}

为 `reviews-v2` Pod 部署一个名为 `reviews-v2-pod-waypoint` 的 waypoint。

{{< tip >}}
回想一下，waypoint 默认指向服务；由于我们明确希望以 Pod 为目标，
所以需要使用 `istio.io/waypoint-for: workload` 标签，
我们可以通过使用 istioctl 的 `--for workload` 参数来生成此标签。
{{< /tip >}}

{{< text syntax=bash >}}
$ istioctl waypoint apply -n default --name reviews-v2-pod-waypoint --for workload
waypoint default/reviews-v2-pod-waypoint applied
{{< /text >}}

为 `reviews-v2` Pod 打标签以使用 `reviews-v2-pod-waypoint` waypoint：

{{< text syntax=bash >}}
$ kubectl label pod -l version=v2,app=reviews istio.io/use-waypoint=reviews-v2-pod-waypoint
pod/reviews-v2-5b667bcbf8-spnnh labeled
{{< /text >}}

从 Ambient 网格中的 Pod 到 `reviews-v2` Pod IP 的所有请求现在都将通过
`reviews-v2-pod-waypoint` waypoint 进行路由，以进行 L7 处理和策略执行。

{{< tip >}}
流量的原始寻址用于确定是否应使用服务或工作负载 waypoint。
寻址到服务的流量（即使最终会解析为 Pod IP）始终被 Ambient 网格视为服务，
并使用服务附加 waypoint。仅当客户端将流量寻址到 Pod 本身时，才会使用工作负载附加 waypoint。
{{< /tip >}}

### 清理 {#cleaning-up}

您可以通过执行以下操作从命名空间中删除所有 waypoint：

{{< text syntax=bash snip_id=delete_waypoint >}}
$ istioctl waypoint delete --all -n default
$ kubectl label ns default istio.io/use-waypoint-
{{< /text >}}

{{< boilerplate gateway-api-remove-crds >}}
