---
title: 故障注入
description: 介绍故障注入的概念，该功能可以在服务间发现故障恢复策略的冲突。
weight: 40
keywords: [traffic-management,fault-injection]
---

虽然 Envoy sidecar/proxy 为在 Istio 上运行的服务提供了大量的[故障恢复机制](/docs/concepts/traffic-management/handling-failures/)，但测试整个应用程序端到端的故障恢复能力依然是必须的。错误配置的故障恢复策略（例如，跨服务调用的不兼容/限制性超时）可能导致应用程序中的关键服务持续不可用，从而破坏用户体验。

Istio 能在不杀死 Pod 的情况下，将协议特定的故障注入到网络中，在 TCP 层制造数据包的延迟或损坏。我们的理由是，无论网络级别的故障如何，应用层观察到的故障都是一样的，并且可以在应用层注入更有意义的故障（例如，HTTP 错误代码），以检验和改善应用的弹性。

运维人员可以为符合特定条件的请求配置故障，还可以进一步限制遭受故障的请求的百分比。可以注入两种类型的故障：延迟和中断。延迟是计时故障，模拟网络延迟上升或上游服务超载的情况。中断是模拟上游服务的崩溃故障。中断通常以 HTTP 错误代码或 TCP 连接失败的形式表现。

有关详细信息，请参阅 [Istio 的流量管理规则](/docs/concepts/traffic-management/rules-configuration/)。