---
title: Notas de Actualización
description: Cambios importantes a considerar al actualizar a Istio 1.28.0.
weight: 20
---

Al actualizar de Istio 1.27.x a Istio 1.28.0, debes considerar los cambios en esta página.
Estas notas detallan los cambios que rompen intencionalmente la compatibilidad con versiones anteriores de Istio 1.27.x.
Las notas también mencionan cambios que preservan la compatibilidad con versiones anteriores al mismo tiempo que introducen nuevos comportamientos.
Solo se incluyen cambios si el nuevo comportamiento sería inesperado para un usuario de Istio 1.27.x.

## Habilitación de `seccompProfile` para contenedores Sidecar

Para habilitar el perfil de computación segura en modo `RuntimeDefault`, `seccompProfile`, para los contenedores `istio-validation` e `istio-proxy`, configura lo siguiente en tu configuración de Istio:

{{< text yaml >}}
global:
  proxy:
    seccompProfile:
      type: RuntimeDefault
{{< /text >}}

Este cambio permite mejores prácticas de seguridad al usar el `seccompProfile` predeterminado proporcionado por el runtime de contenedores.

## InferencePool

La API InferencePool ahora está en v1.0.0. Si estás usando versiones inestables anteriores de la API, usa el tipo de API InferencePool v1 en su lugar. Ten en cuenta que el soporte para las versiones alpha y release candidate ha sido eliminado.

**Si estás migrando desde v1.0.0-rc.1**, ten en cuenta que el campo `inferencePool.spec.endpointPickerRef.portNumber`
ha sido reemplazado por `inferencePool.spec.endpointPickerRef.port.number`. El campo `inferencePool.spec.endpointPickerRef.port` no es un puntero y es obligatorio cuando `inferencePool.spec.endpointPickerRef.kind` no está configurado o es `Service`. El número de puerto 9002 ya no se infiere automáticamente.

## Cambios de comportamiento del data plane de Ambient para ServiceEntries con resolución establecida en `NONE`

Durante una actualización de una versión anterior a una que soporte servicios "PASSTHROUGH", las imágenes antiguas de ztunnel reportarán un NACK en XDS porque no soportan este nuevo tipo de servicio. Esto es esperado y no debería ser excesivamente problemático; sin embargo, puede representar un cambio de comportamiento del data plane cuando veas el NACK. Durante la actualización, un NACK podría resultar en:

1. La configuración del data plane no fue actualizada porque no podía manejar el nuevo tipo de servicio. En la práctica, se trata de una actualización que no produce ningún cambio.
1. El servicio es nuevo y la configuración no fue aceptada por el data plane. Esto resultará en un comportamiento donde el data plane actúa como si el ServiceEntry no existiera. Esto resulta en un comportamiento passthrough donde ztunnel no reconoce el servicio y no puede determinar si se requiere un waypoint.

En ambos casos, el comportamiento de NACK se resolverá una vez que ztunnel sea actualizado a una versión que soporte el nuevo tipo de servicio.

## Eliminación de `BackendTLSPolicy` alpha

Se ha eliminado el soporte para la versión v1alpha3 de `BackendTLSPolicy`. Solo se admite `BackendTLSPolicy` v1.

Ten en cuenta que, antes de esta versión, `BackendTLSPolicy` era ignorado por Istio a menos que la opción `PILOT_ENABLE_ALPHA_GATEWAY_API=true` estuviera explícitamente habilitada. Como la política ahora está en `v1`, esta configuración ya no es necesaria.

## Migración al nuevo mecanismo de evicción de métricas

Los flags de entorno de Pilot `METRIC_ROTATION_INTERVAL` y `METRIC_GRACEFUL_DELETION_INTERVAL` han sido eliminados.
Usa la anotación de pod `sidecar.istio.io/statsEvictionInterval` con la nueva API de evicción de estadísticas en su lugar.
