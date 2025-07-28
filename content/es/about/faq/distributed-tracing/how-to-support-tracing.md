---
title: ¿Qué se requiere para el seguimiento distribuido con Istio?
weight: 10
---

Istio permite la notificación de tramos de seguimiento para las comunicaciones de workload a workload dentro de una malla. Sin embargo, para que los diversos tramos de seguimiento se unan para obtener una vista completa del flujo de tráfico, las aplicaciones deben propagar el contexto de seguimiento entre las solicitudes entrantes y salientes.

En particular, Istio se basa en que las aplicaciones reenvíen el ID de solicitud generado por Envoy y las cabeceras estándar. Estas cabeceras incluyen:

- `x-request-id`
- `traceparent`
- `tracestate`

 Los usuarios de Zipkin deben asegurarse de que [propagan las cabeceras de seguimiento B3](https://github.com/openzipkin/b3-propagation).

- `x-b3-traceid`
- `x-b3-spanid`
- `x-b3-parentspanid`
- `x-b3-sampled`
- `x-b3-flags`
- `b3`

La propagación de cabeceras se puede lograr a través de bibliotecas de cliente, como [OpenTelemetry](https://opentelemetry.io/docs/concepts/context-propagation/). También se puede lograr manualmente, como se documenta en la [tarea de seguimiento distribuido](/es/docs/tasks/observability/distributed-tracing/overview/#trace-context-propagation).
