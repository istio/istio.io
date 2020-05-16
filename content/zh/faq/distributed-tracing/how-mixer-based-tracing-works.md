---
title: 基于 Mixer 的跟踪是如何工作的？
weight: 12
---

对于基于 Mixer 的跟踪集成，Mixer （通过 `istio-telemetry` 服务解决）提供了后端跟踪的集成。Mixer 集成允许操作员对分布式跟踪进行更高级别的控制，包括对跟踪范围中包含的数据进行细粒度选择。它还提供将跟踪发送给 Envoy 不直接支持的后端。

对于基于 Mixer 的集成，Envoy：

- 在请求流经代理时为请求生成 ID 和跟踪报头 （例如，`X-B3-TraceId`）
- 调用 Mixer 进行常规异步遥测报告
- 将跟踪报头转发到代理的应用程序

Mixer：

- 基于 *operator-supplied* 配置为每个请求生成跟踪的范围
- 将生成的跟踪范围发送到 *operator-designated* 跟踪后端

使用 Istio 的 [Stackdriver 跟踪集成](https://cloud.google.com/istio/docs/istio-on-gke/installing#tracing_and_logging)是通过 Mixer 进行跟踪集成的一个示例。
