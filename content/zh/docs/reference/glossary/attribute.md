---
title: 属性
---

属性控制着网格中服务运行时的行为，是一堆有名字的、有类型的元数据，它们描述了 ingress 和 egress 流量，以及这些流量所在的环境。
一个 Istio 属性包含了一段特定的信息，例如 API 请求的错误代码、API 请求的延迟或TCP请求的原始IP地址。例如：

{{< text yaml >}}
request.path: xyz/abc
request.size: 234
request.time: 12:34:56.789 04/17/2017
source.ip: 192.168.0.1
destination.workload.name: example
{{< /text >}}

属性被 Istio 的 [策略和遥测](/docs/reference/config/policy-and-telemetry/) 功能所使用。
