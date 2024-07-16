---
title: 概述
description: Istio Ambient 数据平面模式概述。
weight: 1
owner: istio/wg-docs-maintainers-english
test: no
---

在 **Ambient 模式**下，Istio 在每个节点使用
Layer 4（L4）代理实现其[各项特性](/zh/docs/concepts)，
还可以选择在每个命名空间使用 Layer 7（L7）代理。

这种分层方法允许您以逐步递进的方式采用 Istio，您可以根据需要基于每个命名空间，
从无网格平滑过渡到安全的 L4 覆盖，再到完整的 L7 处理和策略。此外，
在不同 Istio {{< gloss "data plane" >}}数据平面{{< /gloss >}}模式下运行的工作负载可以无缝互操作，
允许用户随时间变化的特定需求来混合和匹配各项功能。

由于工作负载 Pod 不再需要在 Sidecar 中运行代理才能参与网格，
因此 Ambient 模式通常被非正式地称为“无 Sidecar 网格”。

## 工作原理 {#how-it-works}

Ambient 模式将 Istio 的功能分为两个不同的层。在底层，**ztunnel** 安全覆盖处理流量的路由和零信任安全。
除此之外，在需要时，用户可以启用 L7 **waypoint 代理**来访问 Istio 的全部功能。
waypoint 代理虽然比单独的 ztunnel 覆盖更重，但仍然作为基础设施的 Ambient 组件运行，
不需要对应用程序 Pod 进行修改。

{{< tip >}}
使用 Sidecar 模式的 Pod 和工作负载可以与使用 Ambient 模式的 Pod 共存于同一网格内。
术语“Ambient 网格”是指被安装时就支持 Ambient 模式的 Istio 网格，它可以支持使用任一类型数据平面的网格 Pod。
{{< /tip >}}

有关 Ambient 模式的设计以及它如何与 Istio {{< gloss "control plane" >}}控制平面{{< /gloss >}}交互的详细信息，
请参阅[数据平面](/zh/docs/ambient/architecture/data-plane)和[控制平面](/zh/docs/ambient/architecture/control-plane)架构文档。

## ztunnel

ztunnel（Zero Trust tunnel，零信任隧道）组件是一个专门构建的基于每个节点的代理，
为 Istio 的 Ambient 数据平面模式提供支持。

ztunnel 负责安全连接和验证网格内的工作负载。ztunnel 代理是用 Rust 编写的，
旨在处理 L3 和 L4 功能，例如 mTLS、身份验证、L4 鉴权和遥测。
ztunnel 不会终止工作负载 HTTP 流量或解析工作负载 HTTP 标头。
ztunnel 确保 L3 和 L4 流量能够被高效、安全地传输到工作负载、其他 ztunnel 代理或 waypoint 代理。

术语“安全覆盖”用于统一描述通过 ztunnel 代理在 Ambient 网格中实现的 L4 网络功能集。
在传输层，这是通过称为 [HBONE](/zh/docs/ambient/architecture/hbone)
的基于 HTTP CONNECT 的流量隧道协议来实现的。

## waypoint 代理 {#waypoint-proxies}

waypoint 代理是 {{< gloss >}}Envoy{{</ gloss >}} 代理的部署；与 Istio 用于 Sidecar 数据平面模式的引擎相同。

waypoint 代理在应用程序 Pod 之外运行。它们的安装、升级和扩展独立于应用程序。

Istio 在 Ambient 模式下的一些用例可以仅通过 L4 安全覆盖功能来解决，
并且不需要 L7 功能，因此不需要部署 waypoint 代理。需要高级流量管理和 L7 网络功能的用例将需要部署 waypoint。

| 应用程序部署用例 | Ambient 模式配置 |
| ------------------------------- | -------------------------- |
| 通过双向 TLS、客户端应用程序流量的加密和隧道数据传输、L4 授权、L4 遥测实现零信任网络 | 仅 ztunnel（默认） |
| 如上所述，加上高级 Istio 流量管理功能（包括 L7 授权、遥测和 VirtualService 路由） | ztunnel 及 waypoint 代理 |
