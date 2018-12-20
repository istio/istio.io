---
title: Can I use Prometheus to scrape application metrics with Istio?
weight: 90
---

Yes. Istio ships with [configuration for Prometheus](https://raw.githubusercontent.com/istio/istio/release-1.1/install/kubernetes/helm/subcharts/prometheus/templates/configmap.yaml)
that enables collection of application metrics in both mTLS-enabled and non-mTLS environments.

The `kubernetes-pods` job collects application metrics from pods in non-mTLS protected environments. The `kubernetes-pods-istio-secure` job collects metrics
from application pods when mTLS is on for Istio.

Both jobs require that the following annotations are added to any deployments from which application metric collection is desired:

- `prometheus.io/scrape: "true"`
- `prometheus.io/path: "<metrics path>"`
- `prometheus.io/port: "<metrics port>"`

A few notes:

- If the Prometheus pod started before the Istio Citadel pod could generate the required certs and distribute them to Prometheus, the Prometheus pod will need to
be restarted in order to collect from mTLS-protected targets.
- In mTLS-enabled environments, you will need to add the Prometheus metrics port to the service and deployment specifications.

