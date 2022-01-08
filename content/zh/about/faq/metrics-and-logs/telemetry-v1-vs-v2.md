---
title: 代理内的 Telemetry（又名 v2）和基于 Mixer 的 Telemetry（又名 v1）Telemetry 报告有什么不同？
weight: 10
---

与基于 Mixer 的 Telemetry（又名 v1）相比，
代理内的 Telemetry（又名 v2）降低了资源成本并改善了代理，
并且是在 Istio 中呈现 Telemetry 的首选机制。
但是，v1 和 v2 之间报告的 Telemetry 几乎没有区别，
如下所示：

* **缺少网格外流量的标签**
  代理内的 Telemetry 依靠 Envoy 代理之间的元数据交换来收集数据
  诸如对等工作负载名称、名称空间和标签等信息。
  在基于 Mixer 的 Telemetry 中，这个功能是由 Mixer 来执行，
  作为将请求属性与平台数据组合的一部分。此元数据交换由 Envoy 代理执行，
  方法是为 HTTP 协议添加特定的 HTTP 报头，
  或为 TCP 协议增加 ALPN 协议，
  如[这里](/zh/docs/tasks/observability/metrics/tcp-metrics/#understanding-tcp-telemetry-collection)所述。
  这需要在客户端和服务器工作负载中都注入 Envoy 代理，
  这意味着当一个对等点不在网格中时，
  Telemetry 报告将丢失对等点属性，如工作负载名称、命名空间和标签。
  但是，如果两个对等点都有代理注入，
  [这里](/zh/docs/reference/config/metrics/)提到的所有标签都在生成的指标中可用。
  当服务器工作负载脱离网格时，
  服务器工作负载元数据仍被分发到客户端 sidecar，
  导致客户端指标填充了服务器工作负载元数据标签。

* **TCP 数据交换需要 mTLS**
  TCP 元数据交换依赖于 [Istio ALPN 协议](/zh/docs/tasks/observability/metrics/tcp-metrics/#understanding-tcp-telemetry-collection)，
  该协议需要启用双向 TLS（mTLS）才能使 Envoy 代理成功交换元数据。
  这意味着如果您的集群中未启用 mTLS，
  则 TCP 协议的 Telemetry 将不包括
  工作负载名称、命名空间和标签等对等信息。

* **没有为直方图指标配置自定义存储桶的机制**
  基于 Mixer 的 Telemetry 支持为直方图类型指标，
  （如请求持续时间和 TCP 字节大小）自定义存储桶。
  代理内 Telemetry 没有这样的可用机制。此外，与基于 Mixer 的 Telemetry 中的秒相比，
  代理内 Telemetry 中可用于延迟指标的存储桶以毫秒为单位。
  但是，默认情况下，
  代理内 Telemetry 中有更多存储桶可用于较低延迟级别的延迟度量。

* **短期指标没有指标到期**
  基于 Mixer 的 Telemetry 支持指标到期，
  即在可配置的时间内未生成的指标，
  将被取消注册以供 Prometheus 收集。这在生成短期指标的场景（例如一次性作业）中很有用。
  取消注册中不再更改的度量标准的报告将被阻止，
  从而减少 Prometheus 中的网络流量和存储。
  此过期机制在代理内 Telemetry 中不可用。
  可以在[此处](/zh/about/faq/#metric-expiry)找到解决方法。
