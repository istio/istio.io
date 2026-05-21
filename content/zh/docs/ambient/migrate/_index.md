---
title: 从 Sidecar 迁移至 Ambient
description: 将现有的基于 Sidecar 的网格迁移至 Ambient 模式。
weight: 12
owner: istio/wg-networking-maintainers
test: no
skip_list: true
next: /zh/docs/ambient/migrate/before-you-begin
---

本指南将引导您将现有的 Istio 部署从 {{< gloss >}}Sidecar{{< /gloss >}}
模式迁移至 {{< gloss "ambient" >}}Ambient 模式{{< /gloss >}}。
此次迁移旨在实现渐进式且可逆的操作：在迁移过程中，
Sidecar 模式与 Ambient 模式下的工作负载可在同一服务网格中共存，从而允许您逐个命名空间地进行迁移。

{{< warning >}}
**如果您配置了 L7 策略，目前尚无法实现零停机迁移。**在过渡期间，
存在一个 L7 策略无法生效的窗口期：旧的基于选择器（selector）的策略必须从 Sidecar 端移除，
并由新的基于 waypoint 的等效策略取而代之。在这两项操作之间，L7 规则将无法被应用。
这是一个已知的局限性。如果您的 L7 策略必须保持持续生效，请务必规划相应的维护窗口。
Istio 社区目前正致力于实现零停机迁移功能；如需了解相关的最新问题与讨论进展，请查阅我们的 Slack 频道。
{{< /warning >}}

## 迁移策略 {#migration-strategy}

迁移采用循序渐进的方法：

1. **安装 Ambient 组件：**添加 ztunnel 并更新 CNI 以支持 Ambient 模式，
   同时保持所有现有的 Sidecar 工作负载不变。
1. **迁移策略：**将 `VirtualService` 资源转换为 `HTTPRoute`；
   根据需要更新 `AuthorizationPolicy` 资源，使其指向 waypoint；
   并将 `RequestAuthentication` 和 `WasmPlugin` 资源挂载到 waypoint 上。
   **如果您仅使用 L4 策略，请跳过此步骤。** 如果您使用了 L7 策略，
   请注意在迁移过程中会出现短暂的策略执行空窗期，详见上方的警告。
1. **按命名空间启用 Ambient 模式：**为命名空间添加标签以加入 Ambient 网格，
   激活 waypoint，移除 Sidecar 注入，并重启 Pod。

每一个步骤均可独立撤销。无需一次性迁移所有命名空间。

## 资源迁移概述 {#resource-migration-overview}

下表总结了 Sidecar 模式资源如何映射至其 Ambient 模式下的对应资源：

| Sidecar 资源 | Ambient 模式下的操作 |
|---|---|
| `VirtualService` | 迁移至 `HTTPRoute`（`VirtualService` 在 Ambient 模式下的支持处于 Alpha 阶段） |
| `DestinationRule`（流量策略：连接池、异常点检测、TLS） | 无变化；waypoint 应用流量策略。 |
| `DestinationRule`（与 `HTTPRoute` 配合使用的路由子集） | 为 `HTTPRoute` 创建特定版本的 Kubernetes Service 作为 `backendRefs` |
| 包含 L4 规则的 `AuthorizationPolicy` | 无变化；ztunnel 直接执行 L4 策略。 |
| 包含 L7 规则的 `AuthorizationPolicy` | 使用 `targetRefs` 关联至 waypoint |
| `RequestAuthentication` | 使用 `targetRefs` 关联至 waypoint |
| `EnvoyFilter` | waypoint 不支持 |
| `WasmPlugin` | 使用 `targetRefs` 关联至 waypoint |
| `Gateway`（networking.istio.io/v1） | 无需任何更改；Istio Gateway 资源在 Ambient 模式下仍可正常工作。添加 `istio.io/ingress-use-waypoint` 标签，即可将入口流量通过 Waypoint 进行路由。 |

## 您需要 waypoint 代理吗？ {#do-you-need-waypoint-proxies}

{{< tip >}}
waypoint 代理是**可选的**。如果您仅需要 mTLS 和 L4 授权策略，
您可以迁移至 ztunnel，而无需部署 waypoint，也无需更改任何现有策略。
{{< /tip >}}

如果您的工作负载使用了以下任何一项，您就需要使用 waypoint 代理：

- L7 `AuthorizationPolicy` 规则（基于 HTTP 方法、路径或请求头进行匹配）。
- 基于 `HTTPRoute` 的 L7 流量路由（重试、故障注入、请求头操纵、流量拆分）。
  如果您目前使用 `VirtualService` 来实现此功能，则需要迁移至 `HTTPRoute`；
  `VirtualService` 在 Ambient 模式下的支持目前处于 Alpha 阶段。
- `RequestAuthentication`（JWT 验证）。
- L7 遥测数据丰富。

如果您不确定，迁移策略页面可协助您审计现有资源。

## 不支持的内容 {#what-is-not-supported}

{{< tip >}}
下文列出的限制反映了当前 Istio 稳定版本的状况。Ambient 模式仍在持续演进，
其中部分限制可能会在后续版本中解除。请查阅[发布说明](/zh/news/releases/)，
以获取针对您所用 Istio 版本的具体更新信息。
{{< /tip >}}

以下为硬性阻碍，在解决这些问题之前，无法进行迁移：

- 网格内的 **VM 工作负载**。基于 VM 的工作负载无法加入 Ambient 网格。
- 将 **SPIRE** 作为证书提供方。Ambient 模式不支持集成 SPIRE。
- 包含 `mode: DISABLE` 的 **`PeerAuthentication` 策略**。
  Ambient 模式始终在网格工作负载之间强制执行 mTLS。
  配置为 `DISABLE` 模式的策略将被忽略，且无法进行迁移。
- **主-远端（Primary-remote）多集群配置**。
  仅支持多主集群配置。包含一个或多个远端集群的部署将无法正常工作。

以下是已知限制，会影响迁移期间或迁移后的行为：

- **针对 waypoint 的 `EnvoyFilter` 资源目前不受支持**。
  如果您依赖 `EnvoyFilter` 对 Sidecar 代理进行高级 Envoy 配置，
  这些配置将无法沿用到 waypoint 上。此 API 功能可能会在未来的版本中得到支持。
- **来自 Sidecar 模式工作负载的流量会绕过 waypoint 代理**。
  在增量迁移过程中，如果一个 Sidecar 模式的工作负载调用了带有 waypoint 的
  Ambient 模式工作负载，该流量将完全绕过 waypoint。
  除非源工作负载也迁移至 Ambient 模式，否则 waypoint 上配置的 L7 策略将不会对该流量生效。
- **Ingress 网关默认会绕过 waypoint**；但您可以通过在 Gateway 资源上添加 `istio.io/ingress-use-waypoint` 标签，
  将其配置为通过 waypoint 路由流量。
- **针对同一工作负载混用 `VirtualService` 和 `HTTPRoute` 是不受支持的**，
  且会导致未定义的行为。请在继续操作之前，确保已将每个工作负载完全迁移至使用其中一种 API。

## 后续步骤 {#next-steps}

请从开始之前入手，以验证您的环境并备份配置。
