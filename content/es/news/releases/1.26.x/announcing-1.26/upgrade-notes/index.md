---
title: Notas de Actualización de Istio 1.26
description: Cambios importantes a considerar al actualizar a Istio 1.26.0.
weight: 20
publishdate: 2025-05-08
---

Al actualizar de Istio 1.25.x a Istio 1.26.x, debes tener en cuenta los cambios de esta página.
Estas notas detallan los cambios que rompen la compatibilidad con versiones anteriores de Istio 1.25.x de forma intencionada.
Las notas también mencionan cambios que preservan la compatibilidad con versiones anteriores a la vez que introducen un nuevo comportamiento.
Solo se incluyen cambios cuando el nuevo comportamiento podría ser inesperado para un usuario de Istio 1.26.x.

## Próxima eliminación de proveedores de telemetría

Los proveedores de telemetría de Lightstep y OpenCensus están obsoletos (desde la versión 1.22 y 1.25 respectivamente), ya que ambos han sido reemplazados por el proveedor OpenTelemetry. Se eliminarán en Istio 1.27. Si usas alguno de ellos, cambia al proveedor OpenTelemetry ahora.

## Cambios en el chart Helm de Ztunnel

En Istio 1.25, los recursos del chart Helm de ztunnel se cambiaron para llamarse `.Resource.Name`.
Esto generaba problemas frecuentes, ya que el nombre debía mantenerse sincronizado con el chart Helm de Istiod.

En esta versión, hemos revertido para usar nuevamente el nombre estático `ztunnel` por defecto.
Como antes, esto puede reemplazarse con `--set resourceName=my-custom-name`.
