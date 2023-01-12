---
title: Observability Best Practices
description: Best practices for observing applications using Istio.
force_inline_toc: true
weight: 50
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

## Using Prometheus for production-scale monitoring

The recommended approach for production-scale monitoring of Istio meshes with Prometheus
is to use [hierarchical federation](https://prometheus.io/docs/prometheus/latest/federation/#hierarchical-federation)
in combination with a collection of [recording rules](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/).

Although installing Istio does not deploy [Prometheus](http://prometheus.io) by default, the
[Getting Started](/docs/setup/getting-started/) instructions install the `Option 1: Quick Start` deployment
of Prometheus described in the [Prometheus integration guide](/docs/ops/integrations/prometheus/).
This deployment of Prometheus is intentionally configured with a very short retention window (6 hours). The
quick-start Prometheus deployment is also configured to collect metrics from each Envoy proxy
running in the mesh, augmenting each metric with a set of labels about their origin (`instance`,
`pod`, and `namespace`).

{{< image width="80%"
    link="./production-prometheus.svg"
    alt="Architecture for production monitoring of Istio using Prometheus."
    caption="Production-scale Istio monitoring with Istio"
    >}}

### Workload-level aggregation via recording rules

In order to aggregate metrics across instances and pods, update the default Prometheus configuration with
the following recording rules:

{{< tabset category-name="workload-metrics-aggregation" >}}

{{< tab name="Plain Prometheus Rules" category-value="prom-rules" >}}

{{< text yaml >}}
groups:
- name: "istio.recording-rules"
  interval: 5s
  rules:
  - record: "workload:istio_requests_total"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_requests_total)

  - record: "workload:istio_request_duration_milliseconds_count"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_duration_milliseconds_count)

  - record: "workload:istio_request_duration_milliseconds_sum"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_duration_milliseconds_sum)

  - record: "workload:istio_request_duration_milliseconds_bucket"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_duration_milliseconds_bucket)

  - record: "workload:istio_request_bytes_count"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_bytes_count)

  - record: "workload:istio_request_bytes_sum"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_bytes_sum)

  - record: "workload:istio_request_bytes_bucket"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_bytes_bucket)

  - record: "workload:istio_response_bytes_count"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_response_bytes_count)

  - record: "workload:istio_response_bytes_sum"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_response_bytes_sum)

  - record: "workload:istio_response_bytes_bucket"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_response_bytes_bucket)

  - record: "workload:istio_tcp_sent_bytes_total"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_tcp_sent_bytes_total)

  - record: "workload:istio_tcp_received_bytes_total"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_tcp_received_bytes_total)

  - record: "workload:istio_tcp_connections_opened_total"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_tcp_connections_opened_total)

  - record: "workload:istio_tcp_connections_closed_total"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_tcp_connections_closed_total)
{{< /text >}}

{{< /tab >}}

{{< tab name="Prometheus Operator Rules CRD" category-value="prom-operator-rules" >}}

{{< text yaml >}}
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: istio-metrics-aggregation
  labels:
    app.kubernetes.io/name: istio-prometheus
spec:
  groups:
  - name: "istio.metricsAggregation-rules"
    interval: 5s
    rules:
    - record: "workload:istio_requests_total"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_requests_total)"

    - record: "workload:istio_request_duration_milliseconds_count"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_duration_milliseconds_count)"
    - record: "workload:istio_request_duration_milliseconds_sum"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_duration_milliseconds_sum)"
    - record: "workload:istio_request_duration_milliseconds_bucket"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_duration_milliseconds_bucket)"

    - record: "workload:istio_request_bytes_count"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_bytes_count)"
    - record: "workload:istio_request_bytes_sum"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_bytes_sum)"
    - record: "workload:istio_request_bytes_bucket"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_bytes_bucket)"

    - record: "workload:istio_response_bytes_count"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_response_bytes_count)"
    - record: "workload:istio_response_bytes_sum"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_response_bytes_sum)"
    - record: "workload:istio_response_bytes_bucket"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_response_bytes_bucket)"

    - record: "workload:istio_tcp_sent_bytes_total"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_tcp_sent_bytes_total)"
    - record: "workload:istio_tcp_received_bytes_total"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_tcp_received_bytes_total)"
    - record: "workload:istio_tcp_connections_opened_total"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_tcp_connections_opened_total)"
    - record: "workload:istio_tcp_connections_closed_total"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_tcp_connections_closed_total)"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< tip >}}
The recording rules above only aggregate across pods and instances. They still preserve the full set of
[Istio Standard Metrics](/docs/reference/config/metrics/), including all Istio dimensions. While this
will help with controlling metrics cardinality via federation, you may want to further optimize the recording rules
to match your existing dashboards, alerts, and ad-hoc queries.

For more information on tailoring your recording rules, see the section on
[Optimizing metrics collection with recording rules](#optimizing-metrics-collection-with-recording-rules).
{{< /tip >}}

### Federation using workload-level aggregated metrics

To establish Prometheus federation, modify the configuration of your production-ready deployment of Prometheus to
scrape the federation endpoint of the Istio Prometheus.

Add the following job to your configuration:

{{< text yaml >}}
- job_name: 'istio-prometheus'
  honor_labels: true
  metrics_path: '/federate'
  kubernetes_sd_configs:
  - role: pod
    namespaces:
      names: ['istio-system']
  metric_relabel_configs:
  - source_labels: [__name__]
    regex: 'workload:(.*)'
    target_label: __name__
    action: replace
  params:
    'match[]':
    - '{__name__=~"workload:(.*)"}'
    - '{__name__=~"pilot(.*)"}'
{{< /text >}}

If you are using the [Prometheus Operator](https://github.com/coreos/prometheus-operator), use the following configuration instead:

{{< text yaml >}}
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: istio-federation
  labels:
    app.kubernetes.io/name: istio-prometheus
spec:
  namespaceSelector:
    matchNames:
    - istio-system
  selector:
    matchLabels:
      app: prometheus
  endpoints:
  - interval: 30s
    scrapeTimeout: 30s
    params:
      'match[]':
      - '{__name__=~"workload:(.*)"}'
      - '{__name__=~"pilot(.*)"}'
    path: /federate
    targetPort: 9090
    honorLabels: true
    metricRelabelings:
    - sourceLabels: ["__name__"]
      regex: 'workload:(.*)'
      targetLabel: "__name__"
      action: replace
{{< /text >}}

{{< tip >}}
The key to the federation configuration is matching on the job in the Istio-deployed Prometheus that is collecting
[Istio Standard Metrics](/docs/reference/config/metrics/) and renaming any metrics collected by removing
the prefix used in the workload-level recording rules (`workload:`). This will allow existing dashboards and
queries to seamlessly continue working when pointed at the production Prometheus instance (and away from the Istio instance).

You can also include additional metrics (for example, envoy, go, etc.) when setting up federation.

Control plane metrics are also collected and federated up to the production Prometheus.
{{< /tip >}}

### Optimizing metrics collection with recording rules

Beyond just using recording rules to [aggregate over pods and instances](#workload-level-aggregation-via-recording-rules), you may
want to use recording rules to generate aggregated metrics tailored specifically to your existing dashboards and alerts. Optimizing
your collection in this manner can result in large savings in resource consumption in your production instance of Prometheus, in
addition to faster query performance.

For example, imagine a custom monitoring dashboard that used the following Prometheus queries:

* Total rate of requests averaged over the past minute by destination service name and namespace

    {{< text plain >}}
    sum(irate(istio_requests_total{reporter="source"}[1m]))
    by (
        destination_canonical_service,
        destination_workload_namespace
    )
    {{< /text >}}

* P95 client latency averaged over the past minute by source and destination service names and namespace

    {{< text plain >}}
    histogram_quantile(0.95,
      sum(irate(istio_request_duration_milliseconds_bucket{reporter="source"}[1m]))
      by (
        destination_canonical_service,
        destination_workload_namespace,
        source_canonical_service,
        source_workload_namespace,
        le
      )
    )
    {{< /text >}}

The following set of recording rules could be added to the Istio Prometheus configuration, using the `istio` prefix
to make identifying these metrics for federation simple.

{{< text yaml >}}
groups:
- name: "istio.recording-rules"
  interval: 5s
  rules:
  - record: "istio:istio_requests:by_destination_service:rate1m"
    expr: |
      sum(irate(istio_requests_total{reporter="destination"}[1m]))
      by (
        destination_canonical_service,
        destination_workload_namespace
      )
  - record: "istio:istio_request_duration_milliseconds_bucket:p95:rate1m"
    expr: |
      histogram_quantile(0.95,
        sum(irate(istio_request_duration_milliseconds_bucket{reporter="source"}[1m]))
        by (
          destination_canonical_service,
          destination_workload_namespace,
          source_canonical_service,
          source_workload_namespace,
          le
        )
      )
{{< /text >}}

The production instance of Prometheus would then be updated to federate from the Istio instance with:

* match clause of `{__name__=~"istio:(.*)"}`

* metric relabeling config with: `regex: "istio:(.*)"`

The original queries would then be replaced with:

* `istio_requests:by_destination_service:rate1m`

* `avg(istio_request_duration_milliseconds_bucket:p95:rate1m)`

{{< tip >}}
A detailed write-up on [metrics collection optimization in production at AutoTrader](https://karlstoney.com/2020/02/25/federated-prometheus-to-reduce-metric-cardinality/)
provides a more fleshed out example of aggregating directly to the queries that power dashboards and alerts.
{{< /tip >}}
