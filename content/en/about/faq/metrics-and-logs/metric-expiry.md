---
title: How can I manage short-lived metrics?
weight: 20
---

Short-lived metrics can hamper the performance of Prometheus, as they often are a large source of label cardinality. Cardinality is a measure of the number of unique values for a label. To manage the impact of your short-lived metrics on Prometheus, you must first identify the high cardinality metrics and labels. Prometheus provides cardinality information at its `/status` page. Additional information can be retrieved [via PromQL](https://www.robustperception.io/which-are-my-biggest-metrics).
There are several ways to reduce the cardinality of Istio metrics:

* Disable host header fallback.
  The `destination_service` label is one potential source of high-cardinality.
  The values for `destination_service` default to the host header if the Istio proxy is not able to determine the destination service from other request metadata.
  If clients are using a variety of host headers, this could result in a large number of values for the  `destination_service`.
  In this case, follow the [metric customization](/docs/tasks/observability/metrics/customize-metrics/) guide to disable host header fallback mesh wide.
  To disable host header fallback for a particular workload or namespace, you need to copy the stats `EnvoyFilter` configuration, update it to have host header fallback disabled, and apply it with a more specific selector.
  [This issue](https://github.com/istio/istio/issues/25963#issuecomment-666037411) has more detail on how to achieve this.
* Drop unnecessary labels from collection. If the label with high cardinality is not needed, you can drop it from metric collection via [metric customization](/docs/tasks/observability/metrics/customize-metrics/) using `tags_to_remove`.
* Normalize label values, either through federation or classification.
  If the information provided by the label is desired, you can use [Prometheus federation](/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring) or [request classification](/docs/tasks/observability/metrics/classify-metrics/) to normalize the label.
