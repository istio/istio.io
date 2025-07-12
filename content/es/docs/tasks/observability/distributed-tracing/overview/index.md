---
title: Descripción General
description: Descripción general del trazado distribuido en Istio.
weight: 1
keywords: [telemetry,tracing]
aliases:
 - /docs/tasks/telemetry/distributed-tracing/overview/
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

El trazado distribuido permite a los usuarios rastrear una solicitud a través de la malla que se distribuye entre múltiples services.
Esto permite una comprensión más profunda sobre la latencia de la solicitud, la serialización y el paralelismo a través de la visualización.

Istio aprovecha la feature de [trazado distribuido de Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing) para proporcionar una integración de trazado lista para usar.

La mayoría de los backends de trazado ahora aceptan el protocolo [OpenTelemetry](/es/docs/tasks/observability/distributed-tracing/opentelemetry/) para recibir trazas, aunque Istio también admite protocolos heredados para proyectos como [Zipkin](/es/docs/tasks/observability/distributed-tracing/zipkin/) y [Apache SkyWalking](/es/docs/tasks/observability/distributed-tracing/skywalking/).

## Configuración del trazado

Istio proporciona una [API de Telemetría](/es/docs/tasks/observability/distributed-tracing/telemetry-api/) que se puede utilizar para configurar el trazado distribuido, incluida la selección de un proveedor, el establecimiento de la [tasa de muestreo](/es/docs/tasks/observability/distributed-tracing/sampling/) y la modificación de la cabecera.

## Proveedores de extensión

Los [proveedores de extensión](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider) se definen en `MeshConfig` y permiten definir la configuración para un backend de trazas. Los proveedores admitidos son OpenTelemetry, Zipkin, SkyWalking, Datadog y Stackdriver.

## Creación de applications para admitir la propagación del contexto de traza

Aunque los proxies de Istio pueden enviar spans automáticamente, se necesita información adicional para unir esos spans en una sola traza. Las applications deben propagar esta información en las cabeceras HTTP, de modo que cuando los proxies envíen spans, el backend pueda unirlos en una sola traza.

Para hacer esto, cada application debe recopilar las cabeceras de cada solicitud entrante y reenviar las cabeceras a todas las solicitudes salientes activadas por esa solicitud entrante. La elección de las cabeceras a reenviar depende del backend de trazas configurado. El conjunto de cabeceras a reenviar se describe en cada página de tarea específica del backend de trazas. El siguiente es un resumen:

Todas las applications deben reenviar las siguientes cabeceras:

* `x-request-id`: una cabecera específica de Envoy que se utiliza para muestrear de forma coherente los registros y las trazas.
* `traceparent` y `tracestate`: [cabeceras estándar de W3C](https://www.w3.org/TR/trace-context/)

Para Zipkin, se debe reenviar el [formato de cabecera múltiple B3](https://github.com/openzipkin/b3-propagation):

* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`

Para las herramientas de observabilidad comerciales, consulte su documentación.

Si observa el [servicio de ejemplo de Python `productpage`]({{< github_blob >}}/samples/bookinfo/src/productpage/productpage.py#L125), por ejemplo, verá que la application extrae las cabeceras necesarias para todos los trazadores de una solicitud HTTP utilizando las bibliotecas de OpenTelemetry:

{{< text python >}}
def getForwardHeaders(request):
    headers = {}

    # x-b3-*** headers can be populated using the OpenTelemetry span
    ctx = propagator.extract(carrier={k.lower(): v for k, v in request.headers})
    propagator.inject(headers, ctx)

    # ...

        incoming_headers = ['x-request-id',
        'x-ot-span-context',
        'x-datadog-trace-id',
        'x-datadog-parent-id',
        'x-datadog-sampling-priority',
        'traceparent',
        'tracestate',
        'x-cloud-trace-context',
        'grpc-trace-bin',
        'user-agent',
        'cookie',
        'authorization',
        'jwt',
    ]

    # ...

    for ihdr in incoming_headers:
        val = request.headers.get(ihdr)
        if val is not None:
            headers[ihdr] = val

    return headers
{{< /text >}}

La [application de reviews]({{< github_blob >}}/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java#L186) (Java) hace algo similar usando `requestHeaders`:

{{< text java >}}
@GET
@Path("/reviews/{productId}")
public Response bookReviewsById(@PathParam("productId") int productId, @Context HttpHeaders requestHeaders) {

  // ...

  if (ratings_enabled) {
    JsonObject ratingsResponse = getRatings(Integer.toString(productId), requestHeaders);
{{< /text >}}

Cuando realice llamadas descendentes en sus applications, asegúrese de incluir estas cabeceras.
