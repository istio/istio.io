---
title: 可观测性最佳实践
description: 使用 Istio 观测应用时的最佳实践。
force_inline_toc: true
weight: 50
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

## 使用 Prometheus 进行生产规模的监控{#using-Prometheus-for-production-scale-monitoring}

使用 Istio 以及 Prometheus 进行生产规模的监控时推荐的方式是使用[分层联邦](https://prometheus.io/docs/prometheus/latest/federation/#hierarchical-federation)并且结合一组[记录规则](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/)。

尽管安装 Istio 不会默认部署 [Prometheus](http://prometheus.io)，[入门](/zh/docs/setup/getting-started/)指导中
`Option 1: Quick Start` 的部署按照 [Prometheus 集成指导](/zh/docs/ops/integrations/prometheus/)安装了 Prometheus。
此 Prometheus 部署刻意地配置了很短的保留窗口（6 小时）。此快速入门 Prometheus 部署同时也配置为从网格上运行的每一个 Envoy
代理上收集指标，同时通过一组有关它们的源的标签（`instance`、`pod` 和 `namespace`）来扩充指标。

{{< image width="80%"
    link="./production-prometheus.svg"
    alt="使用 Prometheus 对 Istio 生产监控的架构。"
    caption="生产规模 Istio 监控"
    >}}

### 通过记录规则进行负载等级的聚合{#workload-level-aggregation-via-recording-rules}

为了聚合统计实例以及 Pod 级别的指标，需要用以下的记录规则更新默认 Prometheus 配置：

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
以上的记录规则只是同聚合得到 pods 以及实例级别的指标。这仍然完整的保留了
[Istio 标准指标](/zh/docs/reference/config/metrics/)中的全部项，包括全部的 Istio 维度。
尽管这有助于通过联邦控制指标维度，您可能仍想进一步优化记录规则来匹配您现有的仪表盘、告警以及特定的引用。

如需要更多关于如何配置您的记录规则。请参考[使用记录规则优化指标收集](#optimizing-metrics-collection-with-recording-rules)。
{{< /tip >}}

### 使用负载级别的聚合指标进行联邦{#federation-using-workload-level-aggregated-metrics}

为了建立 Prometheus 联邦，请修改您的 Prometheus 生产部署配置来抓取 Istio Prometheus 联邦终端的指标数据。

将以下的 Job 添加到配置中：

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

如果您使用的是 [Prometheus Operator](https://github.com/coreos/prometheus-operator)，请使用以下的配置：

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
联邦配置的关键是首先匹配通过 Istio 部署的 Prometheus 中收集 [Istio 标准指标](/zh/docs/reference/config/metrics/)的
job。并且将收集到的指标重命名，方法为去除负载等级记录规则命名前缀 (`workload:`)。
这使得现有的仪表盘以及引用能够无缝地针对生产用 Prometheus 继续工作（并且不在指向 Istio 实例）。

您可以在设置联邦时包含额外的指标（例如 envoy、go 等）。

控制面指标也被生产用 Prometheus 收集并联邦。
{{< /tip >}}

### 使用记录的规则优化指标收集 {#optimizing-metrics-collection-with-recording-rules}

除了使用记录规则[在 Pod 和实例等级聚合](#workload-level-aggregation-via-recording-rules)，
您也许想要使用记录规则为您现有的仪表盘以及告警专门生成聚合指标。这方面针对收集的优化可以很大的节约您
Prometheus 生产实例的资源消耗，同时加速了引用性能。

例如，假设一个监控仪表盘使用以下 Prometheus 引用：

* 请求速率在过去 1 分钟的平均值，并按照目的服务以及命名空间聚合

    {{< text plain >}}
    sum(irate(istio_requests_total{reporter="source"}[1m]))
    by (
        destination_canonical_service,
        destination_workload_namespace
    )
    {{< /text >}}

* P95 客户端延迟在过去 1 分钟的平均值，并按照来源、目的服务以及命名空间聚合

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

以下记录规则可以加至 Istio Prometheus 配置中，使用 `istio` 前缀来使得联邦更容易识别这些指标。

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

Prometheus 生产实例可以从 Istio 实例那里得到的信息更新联邦：

* 匹配字句 `{__name__=~"istio:(.*)"}`

* 重新将指标标签为： `regex: "istio:(.*)"`

原始引用被替代为：

* `istio_requests:by_destination_service:rate1m`

* `avg(istio_request_duration_milliseconds_bucket:p95:rate1m)`

{{< tip >}}
更详细的关于 [AutoTrader 上生产环境指标收集优化](https://karlstoney.com/2020/02/25/federated-prometheus-to-reduce-metric-cardinality/)的文章提供了更丰富的例子来描述如何直接对引用聚合从而赋能仪表盘以及告警。
{{< /tip >}}
