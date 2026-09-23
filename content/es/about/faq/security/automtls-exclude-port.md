---
title: ¿El TLS mutuo automático excluye los puertos establecidos con la anotación "excludeInboundPorts"?
weight: 80
---

No. Cuando se utiliza `traffic.sidecar.istio.io/excludeInboundPorts` en los workloads del servidor, Istio sigue
configurando el Envoy del cliente para que envíe TLS mutuo de forma predeterminada. Para cambiar eso, debe configurar
una regla de destino con el modo TLS mutuo establecido en `DISABLE` para que los clientes envíen texto sin formato a esos
puertos.
