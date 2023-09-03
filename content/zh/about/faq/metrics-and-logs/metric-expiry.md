---
title: 如何管理短期指标？
weight: 20
---

短期指标可能会阻碍 Prometheus 的性能，因为它们通常是标签基数的重要来源。
基数是标签唯一值数量的度量。要管理短期指标对 Prometheus 的影响，
您必须首先确定高基数指标和标签。Prometheus 在其 `/status` 页面上提供基数信息。
可以通过 [PromQL](https://www.robustperception.io/which-are-my-biggest-metrics)
检索其他信息。有几种方法可以减少 Istio 指标的基数：

* 禁用主机报头回退。
  `destination_service` 标签是高基数的一个潜在来源。
  如果 Istio 代理无法从其他请求元数据中确定目标服务，则 `destination_service` 的值默认出现在主机报头中。
  如果客户端使用各种主机报头，这可能会导致 `destination_service` 产生的大量值。
  在这种情况下，请按照[指标自定义](/zh/docs/tasks/observability/metrics/customize-metrics/)指南禁用主机报头回退网格范围。
  要禁用特定工作负载或命名空间的主机头回退，您需要复制统计 `EnvoyFilter` 配置，更新它以禁用主机报头回退，并应用一个更具体的选择器。
  [这个问题](https://github.com/istio/istio/issues/25963#issuecomment-666037411)有更多关于如何实现这一点的细节。
* 从集合中删除不必要的标签。如果不需要具有高基数的标签，您可以使用 `tags_to_remove`
  通过[指标自定义](/zh/docs/tasks/observability/metrics/customize-metrics/) 将其从指标集合中删除。
* 通过联合或分类规范化标签值。如果需要标签提供的信息，
  您可以使用 [Prometheus 联邦](/zh/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring)或[请求分类](/zh/docs/tasks/observability/metrics/classify-metrics/)来规范化标签。
