---
title: Can I use Prometheus to scrape application metrics with Istio?
weight: 90
---

Yes. [Prometheus](https://prometheus.io/) is an open source monitoring system and time series database.
You can use Prometheus with Istio to record metrics that track the health of Istio and of
applications within the service mesh. You can visualize metrics using tools like
[Grafana](/docs/ops/integrations/grafana/) and [Kiali](/docs/tasks/observability/kiali/).
See [Configuration for Prometheus](/docs/ops/integrations/prometheus/#Configuration) to understand how to enable collection of metrics.

A few notes:

- If the Prometheus pod started before the Istio Citadel pod could generate the required certificates and distribute them to Prometheus, the Prometheus pod will need to
be restarted in order to collect from mutual TLS-protected targets.
- If your application exposes Prometheus metrics on a dedicated port, that port should be added to the service and deployment specifications.
