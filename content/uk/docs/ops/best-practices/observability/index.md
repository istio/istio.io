---
title: Поради щодо спостережуваності
description: Поради щодо спостереження за застосунками за допомогою Istio.
force_inline_toc: true
weight: 50
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

## Використання Prometheus для моніторингу у промисловому масштабі {#using-prometheus-for-production-scale-monitoring}

Рекомендований підхід для моніторингу Istio mesh у промисловому масштабі за допомогою Prometheus — це використання [ієрархічної федерації](https://prometheus.io/docs/prometheus/latest/federation/#hierarchical-federation) у поєднанні з набором [правил запису](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/).

Хоча встановлення Istio стандартно не розгортає [Prometheus](http://prometheus.io), інструкції з [Початку роботи](/docs/setup/getting-started/) `Опція 1: Швидкий старт` встановлюють розгортання Prometheus, про що йдеться в [керівництві з інтеграції Prometheus](/docs/ops/integrations/prometheus/). Це розгортання Prometheus спеціально налаштоване з дуже коротким вікном зберігання (6 годин). Розгортання Prometheus для швидкого старту також налаштоване для збору метрик від кожного проксі Envoy, що працює в mesh, додаючи до кожної метрики набір міток про їхнє походження (`instance`, `pod` і `namespace`).

{{< image width="80%"
    link="./production-prometheus.svg"
    alt="Архітектура моніторингу Istio у промисловому масштабі з використанням Prometheus."
    caption="Моніторинг Istio у промисловому масштабі за допомогою Istio"
    >}}

### Агрегація на рівні робочого навантаження через правила запису {#workload-level-aggregation-via-recording-rules}

Щоб агрегувати метрики між екземплярами та контейнерами, оновіть стандартну конфігурацію Prometheus за допомогою наступних правил запису:

{{< tabset category-name="workload-metrics-aggregation" >}}

{{< tab name="Звичайні правила Prometheus" category-value="prom-rules" >}}

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

{{< tab name="CRD правил Prometheus Operator" category-value="prom-operator-rules" >}}

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
Правила запису, наведені вище, агрегують лише між контейнерами та екземплярами. Вони все ще зберігають повний набір [Стандартних метрик Istio](/docs/reference/config/metrics/), включаючи всі виміри Istio. Хоча це допоможе контролювати кардинальність метрик через федерацію, можливо, ви захочете додатково оптимізувати правила запису для відповідності вашим наявним дашбордам, сповіщенням та ad-hoc запитам.

Для отримання додаткової інформації про налаштування ваших правил запису дивіться розділ [Оптимізація збору метрик за допомогою правил запису](/docs/ops/best-practices/observability/#optimizing-metrics-collection-with-recording-rules).
{{< /tip >}}

### Федерація з використанням агрегованих метрик на рівні робочого навантаження {#federation-using-workload-level-aggregated-metrics}

Щоб встановити федерацію Prometheus, змініть конфігурацію вашого розгортання Prometheus у промисловому масштабі, щоб збирати метрики з федераційної точки доступу Istio Prometheus.

Додайте наступне завдання (job) до вашої конфігурації:

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

Якщо ви використовуєте [Prometheus Operator](https://github.com/coreos/prometheus-operator), натомість використовуйте наступну конфігурацію:

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
Ключем до конфігурації федерації є відповідність задачі в Prometheus, розгорнутому з Istio, яка збирає [Стандартні метрики Istio](/docs/reference/config/metrics/) і перейменування будь-яких зібраних метрик шляхом видалення префіксу, використаного в правилах запису на рівні робочого навантаження (`workload:`). Це дозволить наявним дашбордам та запитам безперешкодно продовжувати роботу при перемиканні на екземпляр Prometheus у промисловому середовищі (і відключенні від екземпляра Istio).

Також можна включити додаткові метрики (наприклад, envoy, go тощо) при налаштуванні федерації.

Метрики панелі управління також збираються і федеративно передаються до промислового екземпляра Prometheus.
{{< /tip >}}

### Оптимізація збору метрик за допомогою правил запису {#optimizing-metrics-collection-with-recording-rules}

Крім використання правил запису для [агрегації між контейнерами та екземплярами](#workload-level-aggregation-via-recording-rules), ви можете
використовувати правила запису для створення агрегованих метрик, спеціально налаштованих для ваших існуючих інформаційних панелей та сповіщень. Оптимізація
збору даних таким чином може значно зменшити споживання ресурсів у вашому виробничому екземплярі Prometheus, а також покращити швидкість виконання запитів.

Наприклад, уявімо власну інформаційну панель моніторингу, яка використовує такі запити Prometheus:

- Загальна кількість запитів, усереднена за останню хвилину за назвою сервісу призначення та простором імен

    {{< text plain >}}
    sum(irate(istio_requests_total{reporter="source"}[1m]))
    by (
        destination_canonical_service,
        destination_workload_namespace
    )
    {{< /text >}}

- P95 клієнтська затримка, усереднена за останню хвилину, за іменами та простором імен сервісів джерела та призначення

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

До конфігурації Istio Prometheus можна додати наступний набір правил запису, використовуючи префікс `istio` щоб спростити ідентифікацію цих метрик для федерації.

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

Виробничий екземпляр Prometheus буде оновлений для федерації з екземпляром Istio за допомогою:

- умови `match` з `{__name__=~"istio:(.*)"}`

- конфігурації relabeling метрик з: `regex: "istio:(.*)"`

Оригінальні запити будуть замінені на:

- `istio_requests:by_destination_service:rate1m`

- `avg(istio_request_duration_milliseconds_bucket:p95:rate1m)`

{{< tip >}}
Детальний опис [оптимізації збору метрик у промисловому середовищі з AutoTrader](https://karlstoney.com/2020/02/25/federated-prometheus-to-reduce-metric-cardinality/) наводить більш розгорнутий приклад агрегації безпосередньо до запитів, які використовуються в дашбордах та сповіщеннях.
{{< /tip >}}
