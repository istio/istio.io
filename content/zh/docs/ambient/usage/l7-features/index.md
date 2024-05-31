---
title: 使用七层功能
description: 使用 L7 waypoint 代理时所支持的功能。
weight: 50
owner: istio/wg-networking-maintainers
test: no
---

通过向您的流量流添加 waypoint 代理，您可以启用更多 [Istio 的功能](/zh/docs/concepts)。
waypoint 使用 {{< gloss "gateway api" >}}Kubernetes Gateway API{{< /gloss >}} 配置。

{{< warning >}}
Istio 经典流量管理 API（虚拟服务、目标规则等）在与 Ambient 数据平面模式一起使用时仍处于 Alpha 阶段。

不支持混合使用 Istio 经典 API 和 Gateway API 配置，这会导致未定义的行为。
{{< /warning >}}

## Route and policy attachment

The Gateway API defines the relationship between objects (such as routes and gateways) in terms of *attachment*.

* Route objects (such as [HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/)) include a way to reference the **parent** resources it wants to attach to.
* Policy objects are considered [*metaresources*](https://gateway-api.sigs.k8s.io/geps/gep-713/): objects that augments the behavior of a **target** object in a standard way.

The tables below show the type of attachment that is configured for each object.

## 流量路由 {#traffic-routing}

部署 waypoint 代理后，您可以使用以下流量路由类型：

|  名称  | 功能状态 | 附加方式 |
| --- | --- | --- |
| [`HTTPRoute`](https://gateway-api.sigs.k8s.io/guides/http-routing/) | Beta | `parentRefs` |
| [`TLSRoute`](https://gateway-api.sigs.k8s.io/guides/tls) | Alpha | `parentRefs` |
| [`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/) | Alpha | `parentRefs` |


请参阅[流量管理](/zh/docs/tasks/traffic-management/)文档以查看可以使用这些路由实现的功能范围。

## 安全 {#security}

如果没有安装航点，则只能使用 [Layer 4 安全策略](/zh/docs/ambient/usage/l4-policy/)。
通过添加航点，您可以访问以下策略：

|  名称  | 功能状态 | 附加方式 |
| --- | --- | --- |
| [`AuthorizationPolicy`](/zh/docs/reference/config/security/authorization-policy/) （包括 L7 功能） | Beta | `targetRefs` |
| [`RequestAuthentication`](/zh/docs/reference/config/security/request_authentication/) | Beta | `targetRefs` |

### Considerations for authorization policies {#considerations}

In ambient mode, authorization policies can either be *targeted* (for ztunnel enforcement) or *attached* (for waypoint enforcement). For an authorization policy to be attached to a waypoint it must have a `targetRef` which refers to the waypoint, or a Service which uses that waypoint.

The ztunnel cannot enforce L7 policies. If a policy with rules matching L7 attributes is targeted with a workload selector (rather than attached with a `targetRef`), such that it is enforced by a ztunnel, it will fail safe by becoming a `DENY` policy.

See [the L4 policy guide](/docs/ambient/usage/l4-policy/) for more information, including when to attach policies to waypoints for TCP-only use cases.

## 可观测性 {#observability}

[全套 Istio 流量指标](/zh/docs/reference/config/metrics/) 由 waypoint 代理导出。

## 扩展 {#extension}

由于 waypoint 代理是 {{< gloss >}}Envoy{{< /gloss >}} 的部署，
因此在 {{< gloss "sidecar">}}Sidecar 模式{{< /gloss >}}中 Envoy 可以使用的扩展机制模式也可用于 waypoint 代理。

|  名称  | 功能状态 | 附加方式 |
| --- | --- | --- |
| `WasmPlugin` †  | Alpha | `targetRefs` |
| `EnvoyFilter` | Alpha | `targetRefs` |

† [阅读更多关于如何使用 WebAssembly 插件扩展航点的信息](/zh/docs/ambient/usage/extend-waypoint-wasm/)。

Extension configurations are considered policy by the Gateway API definition.

## Scoping routes or policies

A route or policy can be scoped to apply to all traffic traversing a waypoint proxy, or only specific services.

### 附加到整个 waypoint 代理 {#attach-to-the-entire-waypoint-proxy}

要将策略或路由规则附加到整个 waypoint - 因此它适用于注册并使用它的所有流量 - 请将
`Gateway` 设置为 `parentRefs` 或 `targetRefs` 值，具体取决于类型。

例如，要将 `AuthorizationPolicy` 策略应用到 `default` 命名空间的名为 `waypoint` 的 waypoint：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: viewer
  namespace: default
spec:
  targetRefs:
  - kind: Gateway
    group: gateway.networking.k8s.io
    name: waypoint
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["default", "istio-system"]
    to:
    - operation:
        methods: ["GET"]
EOF
{{< /text >}}

### 附加到特定服务 {#attach-to-a-specific-service}

您还可以将策略或路由规则附加到 waypoint 内的特定服务。
在适当的情况下将 `Service` 设置为 `parentRefs` 或 `targetRefs` 值。

下面的示例展示了如何将 `reviews` HTTPRoute 应用到 `default` 命名空间中的 `reviews` 服务：

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
EOF
{{< /text >}}
