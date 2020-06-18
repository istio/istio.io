---
title: Can I use Prometheus to scrape application metrics with Istio?
weight: 90
---

Yes. Istio ships with [configuration for Prometheus]({{< github_file >}}/manifests/charts/istio-telemetry/prometheus/templates/configmap.yaml)
that enables collection of application metrics when mutual TLS is enabled or disabled.

The `kubernetes-pods` job collects application metrics from pods in environments without mutual TLS. The `kubernetes-pods-istio-secure` job collects metrics
from application pods when mutual TLS is enabled for Istio.

Both jobs require that the following annotations are added to any deployments from which application metric collection is desired:

- `prometheus.io/scrape: "true"`
- `prometheus.io/path: "<metrics path>"`
- `prometheus.io/port: "<metrics port>"`

A few notes:

- If the Prometheus pod started before the Istio Citadel pod could generate the required certificates and distribute them to Prometheus, the Prometheus pod will need to
be restarted in order to collect from mutual TLS-protected targets.
- If your application exposes Prometheus metrics on a dedicated port, that port should be added to the service and deployment specifications.
