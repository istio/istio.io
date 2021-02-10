---
title: How to work around missing metric expiry with in-proxy telemetry?
weight: 20
---

First step is to identify the metric name and label which has high cardinality.
Prometheus provides cardinality information at its `/status` page.
Based on the labels which have high cardinality, there are several ways to reduce the cardinality:

* `destination_service` could cause high cardinality since for intra mesh traffic, destination service could fallback to host header if Istio proxy does not know which service the request heads to.
   you can follow [metric customization](https://istio.io/latest/docs/tasks/observability/metrics/customize-metrics/) guide to disable host header fallback mesh wide.
   To disable host header fallback for a particular workload or namespace, you need to copy the stats `EnvoyFilter` configuration, update it to have host header fallback disabled, and apply it with a more specific selector.
   [This issue](https://github.com/istio/istio/issues/25963#issuecomment-666037411) has more detail on how to achieve this.
* If the label with high cardinality is not needed, you can drop is from metric collection via [metric customization](/docs/tasks/observability/metrics/customize-metrics/) using `tags_to_remove`.
* If the information provided by the label is desired, you can use [prometheus federation](/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring) or [request classification](/docs/tasks/observability/metrics/classify-metrics/) to normalize the label.
