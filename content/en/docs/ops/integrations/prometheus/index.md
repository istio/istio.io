---
title: Prometheus
description: How to integrate with Prometheus.
weight: 20
keywords: [integration,prometheus]
---

[Prometheus](https://prometheus.io/) is an open source monitoring system and time series database. You can use Prometheus with Istio to record metrics that track the health of Istio and of applications within the service mesh. You can visualize metrics using tools like [Grafana](/docs/ops/integrations/grafana/) and [Kiali](/docs/tasks/observability/kiali/).

## Configuration

In an Istio mesh, each component exposes an endpoint that emits metrics. Prometheus works by scraping these endpoints and collecting the results. This is configured through the [Prometheus configuration file](https://prometheus.io/docs/prometheus/latest/configuration/configuration/) which controls settings for which endpoints to query, the port and path to query, TLS settings, and more.

To gather metrics for the entire mesh, configure Prometheus to scrape:

1. The control plane (`istiod` deployment)
1. Ingress and Egress gateways
1. The Envoy sidecar
1. The user applications (if they expose Prometheus metrics)

To simplify the configuration of metrics, Istio offers two modes of operation.

### Option 1: Customized scraping configurations

The built-in demo installation of Prometheus contains all the required scraping configuration. To deploy this instance of Prometheus, follow the steps in [Customizable Install with Istioctl](/docs/setup/install/istioctl/) to install Istio and pass `--set values.prometheus.enabled=true` during installation.

This built-in deployment of Prometheus is intended for new users to help them quickly getting started. However, it does not offer advanced customization, like persistence or authentication and as such should not be considered production ready. To use an existing Prometheus instance, add the scraping configurations in [`prometheus/configmap.yaml`]({{< github_file>}}/manifests/charts/istio-telemetry/prometheus/templates/configmap.yaml) to your configuration.

This configuration will add scrape job configurations for the control plane, as well as for all Envoy sidecars. Additionally, a job is configured to scrape application metrics for all pods with relevant `prometheus.io` annotations:

* `prometheus.io/scrape` determines if a pod should be scraped. Set to `true` to enable scraping.
* `prometheus.io/path` determines the path to scrape metrics at. Defaults to `/metrics`.
* `prometheus.io/port` determines the port to scrape metrics at. Defaults to `80`.

#### TLS settings

The control plane, gateway, and Envoy sidecar metrics will all be scraped over plaintext. However, the application metrics will follow whatever Istio configuration has been configured for the workload. In particular, if [Strict mTLS](/docs/tasks/security/authentication/authn-policy/#globally-enabling-istio-mutual-tls-in-strict-mode) is enabled, then Prometheus will need to be configured to scrape using Istio certificates.

When using the bundled Prometheus deployment, this is configured by default. For custom Prometheus deployments, please follow [Provision a certificate and key for an application without sidecars](/blog/2020/proxy-cert/) to provision a certificate for Prometheus, then add the TLS scraping configuration.

### Option 2: Metrics merging

{{< warning >}}
This option is newly introduced in Istio 1.6 and is considered `alpha` at this time.
{{< /warning >}}

To simplify configuration, Istio has the ability to control scraping entirely by `prometheus.io` annotations. This allows Istio scraping to work out of the box with standard configurations such as the ones provided by the [Helm `stable/prometheus`](https://github.com/helm/charts/tree/master/stable/prometheus) charts.

{{< tip >}}
While `prometheus.io` annotations are not a core part of Prometheus, they have become the de facto standard to configure scraping.
{{< /tip >}}

To enable this setting, pass `--set meshConfig.enablePrometheusMerge=true` during [installation](/docs/setup/install/istioctl/). When this setting is enabled, appropriate `prometheus.io` annotations will be added to all workloads to set up scraping. If these annotations already exists, they will be overwritten. In these case, the Envoy sidecar will merge Istio's metrics with the application metrics.

This option exposes all the metrics in plain text.

This feature may not suit your needs in the following situations:

* You need to scrape metrics using TLS.
* Your application exposes metrics with the same names as Istio metrics. For example, your application metrics expose an `istio_requests_total` metric. This might happen if the application is itself running Envoy.
* Your Prometheus deployment is not configured to scrape based on standard `prometheus.io` annotations.

If required, this feature can be disabled per workload by adding a `prometheus.istio.io/merge-metrics: "false"` annotation on a pod.

## Best practices

For larger meshes, advanced configuration might help Prometheus scale. See [Using Prometheus for production-scale monitoring](/docs/ops/best-practices/observability/#using-prometheus-for-production-scale-monitoring) for more information.
