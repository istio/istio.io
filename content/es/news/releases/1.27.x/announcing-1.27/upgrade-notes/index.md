---
title: Notas de Actualización de Istio 1.27
description: Cambios importantes a considerar al actualizar a Istio 1.27.0.
weight: 20
publishdate: 2025-08-11
---

Al actualizar de Istio 1.26.x a Istio 1.27.x, debes tener en cuenta los cambios de esta página.
Estas notas detallan los cambios que rompen la compatibilidad con versiones anteriores de Istio 1.26.x de forma intencionada.
Las notas también mencionan cambios que preservan la compatibilidad con versiones anteriores a la vez que introducen un nuevo comportamiento.
Solo se incluyen cambios cuando el nuevo comportamiento podría ser inesperado para un usuario de Istio 1.27.x.

## Soporte para múltiples tipos de certificados en Gateway

Istio ahora permite configurar múltiples tipos de certificados (como RSA y ECDSA) simultáneamente en recursos Gateway tanto de Istio como de Kubernetes.
Esto permite a los clientes elegir el tipo de certificado más adecuado según sus capacidades.

## Regenera los dashboards de Grafana tras la actualización

Si usas los dashboards de Grafana incluidos con Istio, deberás regenerarlos después de actualizar para obtener los enlaces de dashboard corregidos. Los UIDs de los dashboards ahora están definidos explícitamente para habilitar enlaces estables entre dashboards.

## Eliminación de proveedores de telemetría

Los proveedores de telemetría Lightstep y OpenCensus han sido eliminados. Usa el proveedor OpenTelemetry en su lugar.

## Native sidecar habilitado por defecto

Los native sidecars están ahora habilitados por defecto para los pods elegibles. Esto cambia `istio-proxy` de un contenedor a un init container.
Esto puede causar problemas de compatibilidad con otros webhooks mutantes o controladores en tu clúster que esperan modificar `istio-proxy` como un contenedor normal.
Comprueba que tus workloads y controladores son compatibles con este cambio.
