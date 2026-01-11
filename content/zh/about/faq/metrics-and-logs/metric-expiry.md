---
title: 如何管理短期指标？
weight: 20
---

短期指标可能会阻碍 Prometheus 的性能，因为它们通常是标签基数的重要来源。
基数是标签唯一值数量的度量。要管理短期指标对 Prometheus 的影响，
您必须首先确定高基数指标和标签。Prometheus 在其 `/status` 页面上提供基数信息。
可以通过 [PromQL](https://www.robustperception.io/which-are-my-biggest-metrics)
检索其他信息。

有几种方法可以减少 Istio 指标的基数：

* 在 Istio 1.28.0 及更高版本中，为工作负载 Pod 添加
  [`sidecar.istio.io/statsEvictionInterval`](/zh/docs/reference/config/annotations/) 注解，
  以使非活动对等节点的指标过期。这将有助于防止 Istio 代理的指标抓取响应无限增长，
  从而避免作业实例的 `scrape_samples_scraped` 和 `scrape_response_size_bytes`
  指标值过大。这并不能阻止 Prometheus TSDB 索引膨胀和标签频繁变化，
  因为 Prometheus 仍然必须记录所有唯一值。但它有助于减少抓取时过多的内存使用。
* 禁用主机报头回退。
  `destination_service` 标签是高基数的一个潜在来源。
  如果 Istio 代理无法从其他请求元数据中确定目标服务，则 `destination_service` 的值默认出现在主机报头中。
  如果客户端使用各种主机报头，这可能会导致 `destination_service` 产生的大量值。
  在这种情况下，请按照[指标自定义](/zh/docs/tasks/observability/metrics/customize-metrics/)指南禁用主机报头回退网格范围。
  要禁用特定工作负载或命名空间的主机头回退，您需要复制统计 `EnvoyFilter` 配置，更新它以禁用主机报头回退，并应用一个更具体的选择器。
  [这个问题](https://github.com/istio/istio/issues/25963#issuecomment-666037411)有更多关于如何实现这一点的细节。
* 禁用不必要的标签或整个指标系列。如果不需要基数较高的标签或指标，
  您可以通过使用 `Telemetry` 资源的 [`metricsOverrides`](/zh/docs/reference/config/telemetry/#MetricsOverrides) 字段，
  在指标生成过程中将其删除（参见[指标自定义](/zh/docs/tasks/observability/metrics/customize-metrics/)）。
  有关示例，请参阅 [Telemetry API](/zh/docs/tasks/observability/telemetry/)。
* 通过联邦或分类来规范化标签值。如果需要标签提供的信息，
  可以使用 [Prometheus 联邦](/zh/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring)、
  Istio 工作负载 Kubernetes 标签（例如 [`service.istio.io/workload-name`](/zh/docs/reference/config/labels/index.html)）
  或[请求分类](/zh/docs/tasks/observability/metrics/classify-metrics/)来规范化标签。

不建议使用 Prometheus 的抓取时间标签重写功能来删除不需要的标签以降低基数。
Prometheus 在标签重写过程中不会执行聚合操作，因此删除标签可能会创建冲突的时间序列，
即两个或多个时间序列具有相同的标签但值不同。建议使用 Istio 的 `Telemetry` 配置来抑制不需要的维度。
