---
title: 属性
---

属性控制着在网格里面运行的服务的运行时行为。属性是一堆有名字的、有类型的元数据，它们描述着入口和出口流量，以及这些流量存在的环境。一个 Istio 属性承载着一些特点的信息，比如 API 请求的错误码，或者一个 API 请求的耗时，又或者一个 TCP 连接的源 IP 地址，如下：

{{< text yaml >}}
request.path: xyz/abc
request.size: 234
request.time: 12:34:56.789 04/17/2017
source.ip: 192.168.0.1
destination.workload.name: example
{{< /text >}}

属性在 Istio 的 [策略与遥测](/zh/docs/concepts/policies-and-telemetry/)特性里面会用到。
