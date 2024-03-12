---
title: 架构
description: 描述 Istio 的整体架构与设计目标。
weight: 10
aliases:
  - /zh/docs/concepts/architecture
  - /zh/docs/ops/architecture
owner: istio/wg-environments-maintainers
test: n/a
---

Istio 服务网格从逻辑上分为**数据平面**和**控制平面** 。

- **数据平面** 由一组被部署为 Sidecar 的智能代理（[Envoy](https://www.envoyproxy.io/)）
  组成。这些代理负责协调和控制微服务之间的所有网络通信。
  它们还收集和报告所有网格流量的遥测数据。

- **控制平面** 管理并配置代理来进行流量路由。

下图展示了组成每个平面的不同组件：

{{< image width="80%"
    link="./arch.svg"
    alt="基于 Istio 应用程序的总体架构"
    caption="Istio 架构"
    >}}

## 组件 {#components}

以下各节概述了 Istio 的每个核心组件。

### Envoy

Istio 使用 [Envoy](https://www.envoyproxy.io/) 代理的扩展版本。Envoy
是用 C++ 开发的高性能代理，用于协调服务网格中所有服务的入站和出站流量。Envoy
代理是唯一与数据平面流量交互的 Istio 组件。

Envoy 代理被部署为服务的 Sidecar，在逻辑上为服务增加了 Envoy 的许多内置特性，例如：

- 动态服务发现
- 负载均衡
- TLS 终端
- HTTP/2 与 gRPC 代理
- 熔断器
- 健康检查
- 基于百分比流量分割的分阶段发布
- 故障注入
- 丰富的指标

这种 Sidecar 部署允许 Istio 可以执行策略决策，并提取丰富的遥测数据，
接着将这些数据发送到监视系统以提供有关整个网格行为的信息。

Sidecar 代理模型还允许您向现有的部署添加 Istio 功能，而不需要重新设计架构或重写代码。

由 Envoy 代理启用的一些 Istio 的功能和任务包括：

- 流量控制功能：通过丰富的 HTTP、gRPC、WebSocket 和 TCP 流量路由规则来执行细粒度的流量控制。
- 网络弹性特性：重试设置、故障转移、熔断器和故障注入。
- 安全性和身份认证特性：执行安全性策略，并强制实行通过配置 API 定义的访问控制和速率限制。
- 基于 WebAssembly 的可插拔扩展模型，允许通过自定义策略执行和生成网格流量的遥测。

### Istiod

Istiod 提供服务发现、配置和证书管理。

Istiod 将控制流量行为的高级路由规则转换为 Envoy 特定的配置，
并在运行时将其传播给 Sidecar。Pilot 提取了特定平台的服务发现机制，
并将其综合为一种所有符合 [Envoy API](https://www.envoyproxy.io/docs/envoy/latest/api/api)
的 Sidecar 都可以使用的标准格式。

Istio 可以支持发现 Kubernetes 或 VM 等多种环境。

您可以使用 Istio [流量管理 API](/zh/docs/concepts/traffic-management/#introducing-istio-traffic-management)
让 Istiod 重新构造 Envoy 的配置，以便对服务网格中的流量进行更精细的控制。

Istiod [安全](/zh/docs/concepts/security/)通过内置的身份和凭证管理，
实现了强大的服务对服务和终端用户认证。您可以使用 Istio 来升级服务网格中未加密的流量。
使用 Istio，运营商可以基于服务身份而不是相对不稳定的第 3 层或第 4 层网络标识符来执行策略。
此外，您可以使用 [Istio 的授权功能](/zh/docs/concepts/security/#authorization)控制谁可以访问您的服务。

Istiod 充当证书授权机构（CA）并生成证书，以允许在数据平面中进行安全的 mTLS 通信。
