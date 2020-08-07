---
title: Prometheus
description: How to integrate with Prometheus.
weight: 30
keywords: [integration,prometheus]
owner: istio/wg-environments-maintainers
test: n/a
---

[Prometheus](https://prometheus.io/) is an open source monitoring system and time series database. You can use Prometheus with Istio to record metrics that track the health of Istio and of applications within the service mesh. You can visualize metrics using tools like [Grafana](/docs/ops/integrations/grafana/) and [Kiali](/docs/tasks/observability/kiali/).

## Installation

### Option 1: Quick start

Istio provides a basic sample installation to quickly get Prometheus up and running:

{{< text bash >}}
$ kubectl apply -f {{< github_file >}}/samples/addons/prometheus.yaml
{{< /text >}}

This will deploy Prometheus into your cluster. This is intended for demonstration only, and is not tuned for performance or security.

### Option 2: Customizable install

Consult the [Prometheus documentation](https://www.prometheus.io/) to get started deploying Prometheus into your environment. See [Configuration](#Configuration) for more information on configuring Prometheus to scrape Istio deployments.

## Configuration

In an Istio mesh, each component exposes an endpoint that emits metrics. Prometheus works by scraping these endpoints and collecting the results. This is configured through the [Prometheus configuration file](https://prometheus.io/docs/prometheus/latest/configuration/configuration/) which controls settings for which endpoints to query, the port and path to query, TLS settings, and more.

To gather metrics for the entire mesh, configure Prometheus to scrape:

1. The control plane (`istiod` deployment)
1. Ingress and Egress gateways
1. The Envoy sidecar
1. The user applications (if they expose Prometheus metrics)

To simplify the configuration of metrics, Istio offers two modes of operation.

### Option 1: Metrics merging

To simplify configuration, Istio has the ability to control scraping entirely by `prometheus.io` annotations. This allows Istio scraping to work out of the box with standard configurations such as the ones provided by the [Helm `stable/prometheus`](https://github.com/helm/charts/tree/master/stable/prometheus) charts.

{{< tip >}}
While `prometheus.io` annotations are not a core part of Prometheus, they have become the de facto standard to configure scraping.
{{< /tip >}}

This option is enabled by default but can be disabled by passing `--set meshConfig.enablePrometheusMerge=false` during [installation](/docs/setup/install/istioctl/). When enabled, appropriate `prometheus.io` annotations will be added to all data plane pods to set up scraping. If these annotations already exist, they will be overwritten. With this option, the Envoy sidecar will merge Istio's metrics with the application metrics. The merged metrics will be scraped from `/stats/prometheus:15020`.

This option exposes all the metrics in plain text.

This feature may not suit your needs in the following situations:

* You need to scrape metrics using TLS.
* Your application exposes metrics with the same names as Istio metrics. For example, your application metrics expose an `istio_requests_total` metric. This might happen if the application is itself running Envoy.
* Your Prometheus deployment is not configured to scrape based on standard `prometheus.io` annotations.

If required, this feature can be disabled per workload by adding a `prometheus.istio.io/merge-metrics: "false"` annotation on a pod.

### Option 2: Customized scraping configurations

The built-in demo installation of Prometheus contains all the required scraping configuration. To deploy this instance of Prometheus, follow the steps in [Customizable Install with Istioctl](/docs/setup/install/istioctl/) to install Istio and pass `--set values.prometheus.enabled=true` during installation.

This built-in deployment of Prometheus is intended for new users to help them quickly getting started. However, it does not offer advanced customization, like persistence or authentication and as such should not be considered production ready. To use an existing Prometheus instance, add the scraping configurations in [`prometheus/configmap.yaml`]({{< github_file>}}/manifests/charts/istio-telemetry/prometheus/templates/configmap.yaml) to your configuration.

This configuration will add scrape job configurations for the control plane, as well as for all Envoy sidecars. Additionally, a job is configured to scrape application metrics for all data plane pods with relevant `prometheus.io` annotations:

{{< text yaml >}}
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: true   # determines if a pod should be scraped. Set to true to enable scraping.
        prometheus.io/path: /metrics # determines the path to scrape metrics at. Defaults to /metrics.
        prometheus.io/port: 80       # determines the port to scrape metrics at. Defaults to 80.
{{< /text >}}

#### TLS settings

The control plane, gateway, and Envoy sidecar metrics will all be scraped over plaintext. However, the application metrics will follow whatever Istio configuration has been configured for the workload. In particular, if [Strict mTLS](/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode) is enabled, then Prometheus will need to be configured to scrape using Istio certificates.

When using the bundled Prometheus deployment, this is configured by default. For custom Prometheus deployments, please follow [Provision a certificate and key for an application without sidecars](/blog/2020/proxy-cert/) to provision a certificate for Prometheus, then add the TLS scraping configuration.

## Best practices

For larger meshes, advanced configuration might help Prometheus scale. See [Using Prometheus for production-scale monitoring](/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring) for more information.
