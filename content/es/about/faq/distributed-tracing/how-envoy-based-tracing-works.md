---
title: ¿Cómo funciona el seguimiento basado en Envoy?
weight: 11
---

Para las integraciones de seguimiento basadas en Envoy, Envoy (el proxy sidecar) envía información de seguimiento directamente a los backends de seguimiento en nombre de las aplicaciones que se están representando.

Envoy:

- genera ID de solicitud y cabeceras de seguimiento (es decir, `X-B3-TraceId`) para las solicitudes a medida que fluyen a través del proxy
- genera tramos de seguimiento para cada solicitud en función de los metadatos de la solicitud y la respuesta (es decir, el tiempo de respuesta)
- envía los tramos de seguimiento generados a los backends de seguimiento
- reenvía las cabeceras de seguimiento a la aplicación representada

Istio admite [OpenTelemetry](/es/docs/tasks/observability/distributed-tracing/opentelemetry/) y backends compatibles, incluidos [Jaeger](/es/docs/tasks/observability/distributed-tracing/jaeger/). Otras plataformas compatibles incluyen [Zipkin](/es/docs/tasks/observability/distributed-tracing/zipkin/) y [Apache SkyWalking](/es/docs/tasks/observability/distributed-tracing/skywalking/).
