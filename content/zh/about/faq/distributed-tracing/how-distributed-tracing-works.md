---
title: 如何使用 Istio 实现分布式追踪？
weight: 0
---

Istio 使用 [Envoy](#how-envoy-based-tracing-works)的分布式追踪系统集成。
由[应用程序负责为后续传出请求转发追踪的 header 信息](#istio-copy-headers)。

您可以在[分布式链路追踪概述](/zh/docs/tasks/observability/distributed-tracing/overview/)和
[Envoy 链路追踪文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing)中找到更多信息。
