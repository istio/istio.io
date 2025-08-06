---
title: Observabilidad
description: Describe las características de telemetría y monitoreo proporcionadas por Istio.
weight: 40
keywords: [telemetry,metrics,logs,tracing]
aliases:
    - /docs/concepts/policy-and-control/mixer.html
    - /docs/concepts/policy-and-control/mixer-config.html
    - /docs/concepts/policy-and-control/attributes.html
    - /docs/concepts/policies-and-telemetry/overview/
    - /docs/concepts/policies-and-telemetry/config/
    - /docs/concepts/policies-and-telemetry/
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

Istio genera telemetría detallada para todas las comunicaciones de servicios dentro de un mesh. Esta telemetría proporciona *observabilidad* del comportamiento del servicio,
lo que permite a los operadores solucionar problemas, mantener y optimizar sus aplicaciones, sin imponer ninguna carga adicional a los desarrolladores de servicios. A través de
Istio, los operadores obtienen una comprensión profunda de cómo interactúan los servicios monitoreados, tanto con otros servicios como con los propios componentes de Istio.

Istio genera los siguientes tipos de telemetría para proporcionar observabilidad general de la service mesh:

- [**Métricas**](#metrics). Istio genera un conjunto de métricas de servicio basadas en las cuatro "señales doradas" de monitoreo (latencia, tráfico, errores y
  saturación). Istio también proporciona métricas detalladas para el [control plane de la mesh](/es/docs/ops/deployment/architecture/).
  También se proporciona un conjunto predeterminado de paneles de monitoreo de mesh creados sobre estas métricas.
- [**Trazas distribuidas**](#distributed-traces). Istio genera tramos de traza distribuidos para cada servicio, lo que proporciona a los operadores una comprensión detallada
  de los flujos de llamadas y las dependencias de los servicios dentro de un mesh.
- [**Registros de acceso**](#access-logs). A medida que el tráfico fluye hacia un servicio dentro de un mesh, Istio puede generar un registro completo de cada solicitud, incluidos los metadatos de origen y
  destino. Esta información permite a los operadores auditar el comportamiento del servicio hasta el nivel de
  [workload instance](/es/docs/reference/glossary/#workload-instance) individual.

## Métricas

Las métricas proporcionan una forma de monitorear y comprender el comportamiento en conjunto.

Para monitorear el comportamiento del servicio, Istio genera métricas para todo el tráfico del servicio dentro, fuera y dentro de una service mesh de Istio. Estas métricas proporcionan información sobre
comportamientos como el volumen general de tráfico, las tasas de error dentro del tráfico y los tiempos de respuesta para las solicitudes.

Además de monitorear el comportamiento de los services dentro de un mesh, también es importante monitorear el comportamiento de la mesh misma. Los componentes de Istio exportan
métricas sobre sus propios comportamientos internos para proporcionar información sobre la salud y el funcionamiento del control plane de la mesh.

### Métricas a nivel de proxy

La recopilación de métricas de Istio comienza con los proxies sidecar (Envoy). Cada proxy genera un amplio conjunto de métricas sobre todo el tráfico que pasa a través del proxy (tanto
de entrada como de salida). Los proxies también proporcionan estadísticas detalladas sobre las funciones administrativas del propio proxy, incluida la información de configuración y salud.

Las métricas generadas por Envoy proporcionan un monitoreo de la mesh con la granularidad de los recursos de Envoy (como listeners y clusters). Como resultado, se requiere comprender la
conexión entre los services de la mesh y los recursos de Envoy para monitorear las métricas de Envoy.

Istio permite a los operadores seleccionar cuáles de las métricas de Envoy se generan y recopilan en cada workload instance. De forma predeterminada, Istio habilita solo un pequeño
subconjunto de las estadísticas generadas por Envoy para evitar sobrecargar los backends de métricas y reducir la sobrecarga de CPU asociada con la recopilación de métricas. Sin embargo,
los operadores pueden ampliar fácilmente el conjunto de métricas de proxy recopiladas cuando sea necesario. Esto permite la depuración dirigida del comportamiento de la red, al tiempo que reduce el
costo general del monitoreo en toda la mesh.

El [sitio de documentación de Envoy](httpshttps://www.envoyproxy.io/docs/envoy/latest/) incluye una descripción detallada de la [recopilación de estadísticas de Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/statistics.html?highlight=statistics).
La guía de operaciones sobre [Estadísticas de Envoy](/es/docs/ops/configuration/telemetry/envoy-stats/) proporciona más información sobre cómo controlar la generación de métricas a nivel de proxy.

Métricas de ejemplo a nivel de proxy:

{{< text json >}}
envoy_cluster_internal_upstream_rq{response_code_class="2xx",cluster_name="xds-grpc"} 7163

envoy_cluster_upstream_rq_completed{cluster_name="xds-grpc"} 7164

envoy_cluster_ssl_connection_error{cluster_name="xds-grpc"} 0

envoy_cluster_lb_subsets_removed{cluster_name="xds-grpc"} 0

envoy_cluster_internal_upstream_rq{response_code="503",cluster_name="xds-grpc"} 1
{{< /text >}}

### Métricas a nivel de servicio

Además de las métricas a nivel de proxy, Istio proporciona un conjunto de métricas orientadas al servicio para monitorear las comunicaciones del servicio. Estas métricas cubren las cuatro
necesidades básicas de monitoreo de servicios: latencia, tráfico, errores y saturación. Istio se envía con un conjunto predeterminado de
[paneles](/es/docs/tasks/observability/metrics/using-istio-dashboard/) para monitorear los comportamientos del servicio basados en estas métricas.

Las [métricas estándar de Istio](/es/docs/reference/config/metrics/) se
exportan a [Prometheus](/es/docs/ops/integrations/prometheus/) de forma predeterminada.

El uso de las métricas a nivel de servicio es totalmente opcional. Los operadores pueden optar por desactivar la generación y recopilación de estas métricas para satisfacer sus
necesidades individuales.

Métrica de ejemplo a nivel de servicio:

{{< text json >}}
istio_requests_total{
  connection_security_policy="mutual_tls",
  destination_app="details",
  destination_canonical_service="details",
  destination_canonical_revision="v1",
  destination_principal="cluster.local/ns/default/sa/default",
  destination_service="details.default.svc.cluster.local",
  destination_service_name="details",
  destination_service_namespace="default",
  destination_version="v1",
  destination_workload="details-v1",
  destination_workload_namespace="default",
  reporter="destination",
  request_protocol="http",
  response_code="200",
  response_flags="-",
  source_app="productpage",
  source_canonical_service="productpage",
  source_canonical_revision="v1",
  source_principal="cluster.local/ns/default/sa/default",
  source_version="v1",
  source_workload="productpage-v1",
  source_workload_namespace="default"
} 214
{{< /text >}}

### Métricas del control plane

El control plane de Istio también proporciona una colección de métricas de autocontrol. Estas métricas permiten monitorear el comportamiento
de Istio mismo (a diferencia del de los services dentro de la mesh).

Para obtener más información sobre qué métricas se mantienen, consulte la [documentación de referencia](/es/docs/reference/commands/pilot-discovery/#metrics).

## Trazas distribuidas

El rastreo distribuido proporciona una forma de monitorear y comprender el comportamiento al monitorear solicitudes individuales a medida que fluyen a través de un mesh.
Las trazas permiten a los operadores de la mesh comprender las dependencias del servicio y las fuentes de latencia dentro de su service mesh.

Istio admite el rastreo distribuido a través de los proxies de Envoy. Los proxies generan automáticamente tramos de traza en nombre de las aplicaciones que representan,
requiriendo solo que las aplicaciones reenvíen el contexto de solicitud apropiado.

Istio admite una serie de backends de rastreo, incluidos [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/),
[Jaeger](/docs/tasks/observability/distributed-tracing/jaeger/) y muchas herramientas y servicios que admiten [OpenTelemetry](/docs/tasks/observability/distributed-tracing/opentelemetry/). Los operadores controlan la frecuencia de muestreo para la generación de trazas (es decir, la frecuencia con la
que se generan los datos de rastreo por solicitud). Esto permite a los operadores controlar la cantidad y la velocidad de los datos de rastreo que se producen para su malla.

Se puede encontrar más información sobre el rastreo distribuido con Istio en nuestras [Preguntas frecuentes sobre el rastreo distribuido](/es/about/faq/#distributed-tracing).

Traza distribuida generada por Istio de ejemplo para una sola solicitud:

{{< image link="/es/docs/tasks/observability/distributed-tracing/zipkin/istio-tracing-details-zipkin.png" caption="Traza distribuida para una sola solicitud" >}}

## Registros de acceso

Los registros de acceso proporcionan una forma de monitorear y comprender el comportamiento desde la perspectiva de una workload instance individual.

Istio puede generar registros de acceso para el tráfico de servicios en un conjunto configurable de formatos, lo que brinda a los operadores un control total sobre cómo, qué, cuándo y dónde se
registra. Para obtener más información, consulte [Obtención de los registros de acceso de Envoy](/es/docs/tasks/observability/logs/access-log/).

Registro de acceso de Istio de ejemplo:

{{< text plain >}}
[2019-03-06T09:31:27.360Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 5 2 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "127.0.0.1:80" inbound|8000|http|httpbin.default.svc.cluster.local - 172.30.146.73:80 172.30.146.82:38618 outbound_.8000_._.httpbin.default.svc.cluster.local
{{< /text >}}

