---
title: 使用 Layer 7 功能
description: 使用 L7 waypoint 代理时所支持的功能。
weight: 50
owner: istio/wg-networking-maintainers
test: no
---

通过向流量添加 waypoint 代理，您可以启用更多 [Istio 功能](/zh/docs/concepts)。

Ambient 模式支持使用 Kubernetes Gateway API 配置 waypoint。
适用于 Gateway API 的配置被称为**策略**。

{{< warning >}}
Istio 经典流量管理 API（虚拟服务、目标规则等）在 Ambient 数据平面模式下仍处于 Alpha 状态。

不支持混合使用 Istio 经典 API 和 Gateway API 配置，这会导致未定义的行为。
{{< /warning >}}

## 流量路由 {#traffic-routing}

部署 waypoint 代理后，您可以使用以下 API 类型：

|  名称  | 功能状态 | 附加方式 |
| --- | --- | --- |
| `HTTPRoute` | Beta | `parentRefs` |
| `TCPRoute` | Alpha | `parentRefs` |
| `TLSRoute` | Alpha | `parentRefs` |

请参阅[流量管理](/zh/docs/tasks/traffic-management/)文档以查看可以使用这些路由实现的功能范围。

## 安全 {#security}

如果没有安装航点，则只能使用 [Layer 4 安全策略](/zh/docs/ambient/usage/l4-policy/)。
通过添加航点，您可以访问以下策略：

|  名称  | 功能状态 | 附加方式 |
| --- | --- | --- |
| `AuthorizationPolicy`（包括 L7 功能） | Beta | `targetRefs` |
| `RequestAuthentication` | Beta | `targetRefs` |

## 可观测性 {#observability}

[全套 Istio 流量指标](/zh/docs/reference/config/metrics/) 由 waypoint 代理导出。

## 扩展 {#extension}

由于 waypoint 代理是 {{< gloss >}}Envoy{{< /gloss >}} 的部署，
因此在 {{< gloss "sidecar" >}}Sidecar{{< /gloss >}} 中 Envoy 可以使用的扩展机制模式也可用于 waypoint 代理。

|  名称  | 功能状态 | 附加方式 |
| --- | --- | --- |
| `WasmPlugin` | Alpha | `targetRefs` |
| `EnvoyFilter` | Alpha | `targetRefs` |

## 目标策略或路由规则 {#targeting-policies-or-routing-rules}

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
