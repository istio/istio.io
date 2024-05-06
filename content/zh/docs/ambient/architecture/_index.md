---
title: 架构
description: 深入探讨 Ambient 模式的架构。
weight: 20
aliases:
  - /zh/docs/ops/ambient/architecture
  - /zh/latest/docs/ops/ambient/architecture
owner: istio/wg-networking-maintainers
test: n/a
---

## Ambient API {#ambient-apis}

要实施 L7 策略，请将 `istio.io/use-waypoint`
标签添加到您的资源中，以便对被标记的资源使用 waypoint。
  - 如果命名空间被标记为 `istio.io/use-waypoint` 并且拥有命名空间的默认 waypoint，
    则该 waypoint 将应用于命名空间中的所有 Pod。
  - 当不需要为整个命名空间使用 waypoint 时，也可以在单个服务或 Pod 上设置 `istio.io/use-waypoint` 标签。
  - 如果命名空间和服务上都存在 `istio.io/use-waypoint` 标签，
    则只要服务 waypoint 可以处理服务流量或所有流量，则服务 waypoint 优先级就高于命名空间 waypoint。
    同样，Pod 上的标签优先级将高于命名空间标签。

### 标签 {#labels}

您可以使用以下标签将资源添加到网格中，
流向资源的流量使用 waypoint，并控制被发送到 waypoint 的流量。

|  名称  | 功能状态 | 资源 | 描述 |
| --- | --- | --- | --- |
| `istio.io/dataplane-mode` | Beta | `Namespace` |  将您的资源添加到 Ambient 网格中。<br><br>有效值：`ambient`。 |
| `istio.io/use-waypoint` | Beta | `Namespace`、`Service` 或 `Pod` | 使用 waypoint 对被标记资源的流量执行 L7 策略。<br><br>有效值：`{waypoint-name}`、`{namespace}/{waypoint-name}` 或 `#none`（带有哈希值）。 |
| `istio.io/waypoint-for` | Alpha | `Gateway` | 指定 waypoint 将处理流量的端点类型。<br><br>有效值：`service`、`workload`、`none` 或 `all`。该标签是可选的，其默认值为 `service`。 |

为了使您的 `istio.io/use-waypoint` 标签值有效，
您必须确保为使用 waypoint 的端点配置 waypoint。默认情况下，waypoint 接受针对服务端点的流量。
例如，当您通过 `istio.io/use-waypoint` 标签将 Pod 标记为使用特定 waypoint 时，
该 waypoint 应添加值为 `workload` 或 `all` 的标签 `istio.io./waypoint-for`。

### 附加 7 层策略到 waypoint {#layer-7-policy-attachment-to-waypoints}

您可以使用 `targetRefs` 将 7 层策略
（例如 `AuthorizationPolicy`、`RequestAuthentication`、`Telemetry`、`WasmPlugin` 等）附加到您的 waypoint。

- 要将 L7 策略附加到整个 waypoint，请将 `Gateway` 设置到 `targetRefs` 的值中。
  下面的示例展示了如何将 `viewer` 策略附加到 `default` 命名空间的名为 `waypoint` 的 waypoint：

    {{< text yaml >}}
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
    {{< /text >}}

- 要将 L7 策略附加到 waypoint 内的特定服务，请将 `Service` 设置到 `targetRefs` 的值中。
  下面的示例展示了如何将 `productpage-viewer` 策略附加到 `default` 命名空间中的 `productpage` 服务：

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
      name: productpage-viewer
      namespace: default
    spec:
      targetRefs:
      - kind: Service
        group: ""
        name: productpage
    {{< /text >}}
