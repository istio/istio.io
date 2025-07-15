---
title: ¿Cómo funciona el seguimiento distribuido con Istio?
weight: 0
---

Istio se integra con sistemas de seguimiento distribuido utilizando el seguimiento [basado en Envoy](#how-envoy-based-tracing-works). Con la integración de seguimiento basada en Envoy, [las aplicaciones son responsables de reenviar las cabeceras de seguimiento](#istio-copy-headers) para las solicitudes salientes posteriores.

Puede encontrar información adicional en la [descripción general del seguimiento distribuido](/es/docs/tasks/observability/distributed-tracing/overview/) y
en los [documentos de seguimiento de Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing).
