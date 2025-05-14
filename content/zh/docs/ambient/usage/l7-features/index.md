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
VirtualService 与 Ambient 数据平面模式的结合使用仍处于 Alpha 阶段。
不支持与 Gateway API 配置混合使用，否则会导致未定义的行为。
{{< /warning >}}

{{< warning >}}
`EnvoyFilter` 是 Istio 的应急 API，用于对 Envoy 代理进行高级配置。
请注意，**`EnvoyFilter` 目前不支持任何带有 waypoint 代理的现有 Istio 版本**。
虽然在有限的场景下可以使用带有 waypoint 的 `EnvoyFilter`，
但目前尚不支持该 API，并且维护人员也极力劝阻。随着 Alpha API 的不断发展，
未来版本中可能会出现问题。我们预计官方支持将在稍后提供。
{{< /warning >}}

## 路由和策略附件 {#route-and-policy-attachment}

Gateway API 根据**附件**来定义对象（例如路由和网关）之间的关系。

* 路由对象（例如 [HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/)）
  包含一种引用其想要附加到的**父**资源的方法。
* 策略对象被视为 [**metaresources**](https://gateway-api.sigs.k8s.io/geps/gep-713/)：
  以标准方式增强**目标**对象行为的对象。

下表展示了为每个对象配置的附件类型。

## 流量路由 {#traffic-routing}

部署 waypoint 代理后，您可以使用以下流量路由类型：

|  名称  | 功能状态 | 附加方式 |
| --- | --- | --- |
| [`HTTPRoute`](https://gateway-api.sigs.k8s.io/guides/http-routing/) | Beta | `parentRefs` |
| [`TLSRoute`](https://gateway-api.sigs.k8s.io/guides/tls) | Alpha | `parentRefs` |
| [`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/) | Alpha | `parentRefs` |

请参阅[流量管理](/zh/docs/tasks/traffic-management/)文档以查看可以使用这些路由实现的功能范围。

## 安全 {#security}

如果没有安装航点，则只能使用[四层安全策略](/zh/docs/ambient/usage/l4-policy/)。
通过添加航点，您可以访问以下策略：

|  名称  | 功能状态 | 附加方式 |
| --- | --- | --- |
| [`AuthorizationPolicy`](/zh/docs/reference/config/security/authorization-policy/) （包括 L7 功能） | Beta | `targetRefs` |
| [`RequestAuthentication`](/zh/docs/reference/config/security/request_authentication/) | Beta | `targetRefs` |

### 鉴权策略注意事项 {#considerations}

在 Ambient 模式下，鉴权策略可以是**目标**（用于 ztunnel 执行）或**附加**（用于 waypoint 执行）。
要将鉴权策略附加到 waypoint，它必须具有引用 waypoint 的 `targetRef`，或使用该 waypoint 的服务。

ztunnel 无法强制执行 L7 策略。如果使用工作负载选择器（而不是附加 `targetRef`）
来定位具有与 L7 属性匹配的规则的策略，从而由 ztunnel 强制执行，
则该策略将由于安全被变更为 `DENY` 策略而失效。

有关更多信息，请参阅 [L4 策略指南](/zh/docs/ambient/usage/l4-policy/)，
包括何时将策略附加到仅限 TCP 用例的 waypoint。

## 可观测性 {#observability}

[全套 Istio 流量指标](/zh/docs/reference/config/metrics/) 由 waypoint 代理导出。

## 扩展 {#extension}

由于 waypoint 代理是 {{< gloss >}}Envoy{{< /gloss >}} 的部署，
因此在 {{< gloss "sidecar">}}Sidecar 模式{{< /gloss >}}中 Envoy 可以使用的某些扩展机制模式也可用于 waypoint 代理。

|  名称  | 功能状态 | 附加方式 |
| --- | --- | --- |
| `WasmPlugin` †  | Alpha | `targetRefs` |

† [阅读更多关于如何使用 WebAssembly 插件扩展 waypoint 的信息](/zh/docs/ambient/usage/extend-waypoint-wasm/)。

扩展配置被 Gateway API 定义视为策略。

## 确定路由或策略的范围 {#scoping-routes-or-policies}

路由或策略可以适用于穿越 waypoint 代理的所有流量，或者仅适用于特定服务。

### 附加到整个 waypoint 代理 {#attach-to-the-entire-waypoint-proxy}

要将路由或策略附加到整个 waypoint（以便它适用于所有注册使用它的流量），
请根据类型将 `Gateway` 设置为 `parentRefs` 或 `targetRefs` 值。

要将 `AuthorizationPolicy` 策略应用于 `default` 命名空间中名为 `default` 的 waypoint，请执行以下操作：

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: view-only
  namespace: default
spec:
  targetRefs:
  - kind: Gateway
    group: gateway.networking.k8s.io
    name: default
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["default", "istio-system"]
    to:
    - operation:
        methods: ["GET"]
{{< /text >}}

### 附加到特定服务 {#attach-to-a-specific-service}

您还可以将路由附加到 waypoint 内的一个或多个特定服务。
根据需要将 `Service` 设置为 `parentRefs` 或 `targetRefs` 值。

要将 `reviews` HTTPRoute 应用于 `default` 命名空间中的 `reviews` 服务：

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: default
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
{{< /text >}}
