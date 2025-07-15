---
title: ¿En qué puertos captura un proxy sidecar el tráfico entrante?
weight: 20
---

Istio captura el tráfico entrante en todos los puertos de forma predeterminada.
Puede anular este comportamiento utilizando la anotación del pod `traffic.sidecar.istio.io/includeInboundPorts`
para especificar una lista explícita de puertos para capturar, o utilizando `traffic.sidecar.istio.io/excludeOutboundPorts`
para especificar una lista de puertos para omitir.
