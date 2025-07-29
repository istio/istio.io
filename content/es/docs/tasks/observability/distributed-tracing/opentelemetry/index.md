---
title: OpenTelemetry
description: Aprenda a configurar los proxies para enviar trazas en formato OpenTelemetry.
weight: 5
keywords: [telemetry,tracing,opentelemetry,span,port-forwarding]
aliases:
 - /docs/tasks/telemetry/distributed-tracing/opentelemetry/
 - /docs/tasks/observability/distributed-tracing/lightstep/
 - /latest/docs/tasks/observability/distributed-tracing/lightstep/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

[OpenTelemetry](https://opentelemetry.io/) (OTel) es un framework de observabilidad de código abierto y neutral para el proveedor para instrumentar, generar, recopilar y exportar datos de telemetría. Las trazas del [OpenTelemetry Protocol](https://opentelemetry.io/docs/specs/otlp/) (OTLP) se pueden enviar a [Jaeger](/es/docs/tasks/observability/distributed-tracing/jaeger/), así como a muchos servicios comerciales.

Para aprender cómo Istio maneja el trazado, visite la [descripción general](../overview/) de esta tarea.

Después de completar esta tarea, comprenderá cómo hacer que su application participe en el trazado con [OpenTelemetry](https://www.opentelemetry.io/), independientemente del lenguaje, framework o plataforma que utilice para construir su application.

Esta tarea utiliza la muestra [Bookinfo](/es/docs/examples/bookinfo/) como la application de ejemplo y el
[OpenTelemetry Collector](https://opentelemetry.io/docs/collector/) como el receptor de las trazas. Para ver un ejemplo de cómo enviar trazas directamente a un backend compatible con OTLP, consulte la [tarea de Jaeger](/es/docs/tasks/observability/distributed-tracing/jaeger/).

## Desplegar el OpenTelemetry Collector

{{< boilerplate start-otel-collector-service >}}

## Instalación

Todas las opciones de trazado se pueden configurar globalmente a través de `MeshConfig`.
Para simplificar la configuración, se recomienda crear un único fichero YAML
que pueda pasar al comando `istioctl install -f`.

## Elegir el exportador

Istio se puede configurar para exportar trazas del [OpenTelemetry Protocol (OTLP)](https://opentelemetry.io/docs/specs/otel/protocol/)
a través de gRPC o HTTP. Solo se puede configurar un exportador a la vez (ya sea gRPC o HTTP).

### Exportar a través de gRPC

En este ejemplo, las trazas se exportarán a través de OTLP/gRPC al OpenTelemetry Collector.
El ejemplo también habilita el [detector de recursos de entorno](https://opentelemetry.io/docs/languages/js/resources/#adding-resources-with-environment-variables). El detector de entorno agrega atributos de la variable de entorno
`OTEL_RESOURCE_ATTRIBUTES` al recurso OpenTelemetry exportado.

{{< text syntax=bash snip_id=none >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4317
        service: opentelemetry-collector.observability.svc.cluster.local
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

### Exportar a través de HTTP

En este ejemplo, las trazas se exportarán a través de OTLP/HTTP al OpenTelemetry Collector.
El ejemplo también habilita el [detector de recursos de entorno](https://opentelemetry.io/docs/languages/js/resources/#adding-resources-with-environment-variables). El detector de entorno agrega atributos de la variable de entorno
`OTEL_RESOURCE_ATTRIBUTES` al recurso OpenTelemetry exportado.

{{< text syntax=bash snip_id=install_otlp_http >}}
$ cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    extensionProviders:
    - name: otel-tracing
      opentelemetry:
        port: 4318
        service: opentelemetry-collector.observability.svc.cluster.local
        http:
          path: "/v1/traces"
          timeout: 5s
          headers:
            - name: "custom-header"
              value: "custom value"
        resource_detectors:
          environment: {}
EOF
{{< /text >}}

## Habilitar el trazado para la malla a través de la API de Telemetría

Habilite el trazado aplicando la siguiente configuración:

{{< text syntax=bash snip_id=enable_telemetry >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: otel-demo
spec:
  tracing:
  - providers:
    - name: otel-tracing
    randomSamplingPercentage: 100
    customTags:
      "my-attribute":
        literal:
          value: "default-value"
EOF
{{< /text >}}

## Desplegar la Application Bookinfo

Despliegue la application de ejemplo [Bookinfo](/es/docs/examples/bookinfo/#deploying-the-application).

## Generar trazas usando la muestra de Bookinfo

1.  Cuando la application Bookinfo esté en funcionamiento, acceda a `http://$GATEWAY_URL/productpage`
    una o más veces para generar información de traza.

    {{< boilerplate trace-generation >}}

1.  El OpenTelemetry Collector utilizado en el ejemplo está configurado para exportar trazas a la consola.
    Si utilizó la configuración del Collector de ejemplo, puede verificar que las trazas están llegando mirando
    los registros del Collector. Debería contener algo como:

    {{< text syntax=yaml snip_id=none >}}
    Resource SchemaURL:
    Resource labels:
          -> service.name: STRING(productpage.default)
    ScopeSpans #0
    ScopeSpans SchemaURL:
    InstrumentationScope
    Span #0
        Trace ID       : 79fb7b59c1c3a518750a5d6dad7cd2d1
        Parent ID      : 0cf792b061f0ad51
        ID             : 2dff26f3b4d6d20f
        Name           : egress reviews:9080
        Kind           : SPAN_KIND_CLIENT
        Start time     : 2024-01-30 15:57:58.588041 +0000 UTC
        End time       : 2024-01-30 15:57:59.451116 +0000 UTC
        Status code    : STATUS_CODE_UNSET
        Status message :
    Attributes:
          -> node_id: STRING(sidecar~10.244.0.8~productpage-v1-564d4686f-t6s4m.default~default.svc.cluster.local)
          -> zone: STRING()
          -> guid:x-request-id: STRING(da543297-0dd6-998b-bd29-fdb184134c8c)
          -> http.url: STRING(http://reviews:9080/reviews/0)
          -> http.method: STRING(GET)
          -> downstream_cluster: STRING(-)
          -> user_agent: STRING(curl/7.74.0)
          -> http.protocol: STRING(HTTP/1.1)
          -> peer.address: STRING(10.244.0.8)
          -> request_size: STRING(0)
          -> response_size: STRING(441)
          -> component: STRING(proxy)
          -> upstream_cluster: STRING(outbound|9080||reviews.default.svc.cluster.local)
          -> upstream_cluster.name: STRING(outbound|9080||reviews.default.svc.cluster.local)
          -> http.status_code: STRING(200)
          -> response_flags: STRING(-)
          -> istio.namespace: STRING(default)
          -> istio.canonical_service: STRING(productpage)
          -> istio.mesh_id: STRING(cluster.local)
          -> istio.canonical_revision: STRING(v1)
          -> istio.cluster_id: STRING(Kubernetes)
          -> my-attribute: STRING(default-value)
    {{< /text >}}

## Limpieza

1.  Elimine el recurso Telemetry:

    {{< text syntax=bash snip_id=cleanup_telemetry >}}
    $ kubectl delete telemetry otel-demo
    {{< /text >}}

1.  Elimine cualquier proceso `istioctl` que aún pueda estar ejecutándose usando control-C o:

    {{< text syntax=bash snip_id=none >}}
    $ killall istioctl
    {{< /text >}}

1.  Desinstale el OpenTelemetry Collector:

    {{< text syntax=bash snip_id=cleanup_collector >}}
    $ kubectl delete -f @samples/open-telemetry/otel.yaml@ -n observability
    $ kubectl delete namespace observability
    {{< /text >}}

1.  Si no planea explorar ninguna tarea de seguimiento, consulte las
    instrucciones de [limpieza de Bookinfo](/es/docs/examples/bookinfo/#cleanup)
    para apagar la application.
