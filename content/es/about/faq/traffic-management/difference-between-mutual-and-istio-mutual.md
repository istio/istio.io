---
title: ¿Cuál es la diferencia entre los modos TLS MUTUAL e ISTIO_MUTUAL?
weight: 30
---

Ambas configuraciones de `DestinationRule` enviarán tráfico TLS mutuo.
Con `ISTIO_MUTUAL`, los certificados de Istio se utilizarán automáticamente.
Para `MUTUAL`, se deben configurar la clave, el certificado y la CA de confianza.
Esto permite iniciar TLS mutuo con aplicaciones que no son de Istio.