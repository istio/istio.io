---
title: Mejores prácticas de observabilidad
description: Mejores prácticas para observar aplicaciones con Istio.
force_inline_toc: true
weight: 50
owner: istio/wg-policies-and-telemetry-maintainers
test: no
---

## Usar Prometheus para el monitoreo a escala de producción {#using-prometheus-for-production-scale-monitoring}

El enfoque recomendado para el monitoreo a escala de producción de meshes de Istio con Prometheus
es usar la [federación jerárquica](https://prometheus.io/docs/prometheus/latest/federation/#hierarchical-federation)
junto con un conjunto de [reglas de grabación (recording rules)](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/).

Aunque la instalación de Istio no despliega [Prometheus](http://prometheus.io) por defecto, las instrucciones de
[Comenzando](/es/docs/setup/getting-started/) instalan el despliegue `Option 1: Quick Start`
de Prometheus que se describe en la [guía de integración de Prometheus](/es/docs/ops/integrations/prometheus/).
Este despliegue de Prometheus está configurado intencionadamente con un período de retención muy corto (6 horas). El
despliegue de inicio rápido de Prometheus también está configurado para recopilar métricas de cada proxy Envoy
que se ejecuta en la mesh y añade a cada métrica un conjunto de etiquetas sobre su origen (`instance`,
`pod` y `namespace`).

{{< image width="80%"
    link="./production-prometheus.svg"
    alt="Arquitectura para el monitoreo en producción de Istio con Prometheus."
    caption="Monitoreo de Istio a escala de producción con Prometheus"
    >}}

### Agregación a nivel de workload mediante reglas de grabación {#workload-level-aggregation-via-recording-rules}

Para agregar las métricas de todas las instancias y pods, actualiza la configuración por defecto de Prometheus con
las siguientes reglas de grabación:

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

  - record: "workload:istio_request_messages_total"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_messages_total)

  - record: "workload:istio_response_messages_total"
    expr: |
      sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_response_messages_total)

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

    - record: "workload:istio_request_messages_total"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_request_messages_total)"
    - record: "workload:istio_response_messages_total"
      expr: "sum without(instance, kubernetes_namespace, kubernetes_pod_name) (istio_response_messages_total)"

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
Las reglas de grabación anteriores solo agregan entre pods e instancias. Siguen conservando el conjunto completo de
[métricas estándar de Istio](/es/docs/reference/config/metrics/), incluidas todas las dimensiones de Istio. Aunque esto
ayudará a controlar la cardinalidad de las métricas mediante la federación, puede que quieras optimizar aún más las reglas de grabación
para que se ajusten a tus dashboards, alertas y consultas ad hoc existentes.

Para obtener más información sobre cómo adaptar tus reglas de grabación, consulta la sección
[Optimizar la recopilación de métricas con reglas de grabación](/es/docs/ops/best-practices/observability/#optimizing-metrics-collection-with-recording-rules).
{{< /tip >}}

### Federación con métricas agregadas a nivel de workload

Para establecer la federación de Prometheus, modifica la configuración de tu despliegue de Prometheus para producción para que
haga scraping del endpoint de federación del Prometheus de Istio.

Añade el siguiente job a tu configuración:

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

Si usas el [Prometheus Operator](https://github.com/coreos/prometheus-operator), usa en su lugar la siguiente configuración:

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
La clave de la configuración de federación es seleccionar el job del Prometheus desplegado por Istio que recopila las
[métricas estándar de Istio](/es/docs/reference/config/metrics/) y renombrar todas las métricas recopiladas eliminando
el prefijo que usan las reglas de grabación a nivel de workload (`workload:`). Así, los dashboards y
las consultas existentes seguirán funcionando sin cambios cuando apunten a la instancia de Prometheus de producción (y ya no a la instancia de Istio).

También puedes incluir métricas adicionales (por ejemplo, de envoy, go, etc.) al configurar la federación.

Las métricas del control plane también se recopilan y se federan hacia el Prometheus de producción.
{{< /tip >}}

### Optimizar la recopilación de métricas con reglas de grabación {#optimizing-metrics-collection-with-recording-rules}

Además de usar reglas de grabación para [agregar entre pods e instancias](#workload-level-aggregation-via-recording-rules), puede que
quieras usar reglas de grabación para generar métricas agregadas adaptadas específicamente a tus dashboards y alertas existentes. Optimizar
la recopilación de esta forma puede suponer un gran ahorro en el consumo de recursos de tu instancia de Prometheus de producción, además
de un mejor rendimiento de las consultas.

Por ejemplo, imagina un dashboard de monitoreo personalizado que usa las siguientes consultas de Prometheus:

* Tasa total de solicitudes, promediada durante el último minuto, por nombre del servicio de destino y namespace

    {{< text plain >}}
    sum(irate(istio_requests_total{reporter="source"}[1m]))
    by (
        destination_canonical_service,
        destination_workload_namespace
    )
    {{< /text >}}

* Latencia P95 del cliente, promediada durante el último minuto, por nombres de los servicios de origen y destino y namespace

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

El siguiente conjunto de reglas de grabación se podría añadir a la configuración del Prometheus de Istio, con el prefijo `istio`
para que resulte sencillo identificar estas métricas para la federación.

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

Después, la instancia de Prometheus de producción se actualizaría para federar desde la instancia de Istio con:

* la cláusula de coincidencia `{__name__=~"istio:(.*)"}`

* la configuración de reetiquetado de métricas con: `regex: "istio:(.*)"`

Después, las consultas originales se sustituirían por:

* `istio_requests:by_destination_service:rate1m`

* `avg(istio_request_duration_milliseconds_bucket:p95:rate1m)`

{{< tip >}}
Un artículo detallado sobre la [optimización de la recopilación de métricas en producción en AutoTrader](https://karlstoney.com/2020/02/25/federated-prometheus-to-reduce-metric-cardinality/)
ofrece un ejemplo más completo de cómo agregar directamente según las consultas que alimentan los dashboards y las alertas.
{{< /tip >}}
