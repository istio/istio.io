---
title: 基于 Mixer 的追踪是如何工作的？
weight: 12
---

对于基于 Mixer 的追踪，由 Mixer (通过 `istio-telemetry` 服务)提供与追踪后端的集成支持。
Mixer 追踪允许对分布式追踪进行额外级别的操作控制，包括对追踪 span 中包含数据的细粒度选择。
它还提供了将追踪数据发送到不被 Envoy 直接支持的后端的能力。

对于基于 Mixer 的追踪集成，Envoy：

- 当请求通过代理时生成请求 ID 和 追踪 header（例如，`X-B3-TraceId`）
- 调用 Mixer 异步进行遥测数据汇报
- 将追踪 header 转发给被代理的应用程序

Mixer：

- 基于 *operator-supplied* 配置为每个请求生成追踪 span
- 发送生成的追踪 span 到 *operator-designated* 追踪后端

[Stackdriver 与 Istio 的追踪集成](https://cloud.google.com/istio/docs/istio-on-gke/installing#enabling_tracing)是通过 Mixer 进行追踪集成的一个例子。