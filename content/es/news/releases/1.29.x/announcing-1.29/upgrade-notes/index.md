---
title: Notas de Actualización
description: Cambios importantes a considerar al actualizar a Istio 1.29.0.
weight: 20
---

Al actualizar de Istio 1.28.x a Istio 1.29.0, debes tener en cuenta los cambios de esta página.
Estas notas detallan los cambios que rompen la compatibilidad con versiones anteriores de Istio 1.28.x de forma intencionada.
Las notas también mencionan cambios que preservan la compatibilidad con versiones anteriores a la vez que introducen un nuevo comportamiento.
Solo se incluyen cambios cuando el nuevo comportamiento podría ser inesperado para un usuario de Istio 1.28.x.

## Compresión HTTP de métricas de Envoy (`prometheus_stats`) habilitada por defecto

La anotación `sidecar.istio.io/statsCompression` fue marcada como obsoleta y eliminada.

Ahora existe una opción `statsCompression` en `proxyConfig` para controlar globalmente el soporte de compresión del endpoint de métricas (`prometheus_stats`) de Envoy.
El valor predeterminado es `true`, ofreciendo `brotli`, `gzip` y `zstd` según el `Accept-Header` enviado por el cliente.

La mayoría de los scrapers de métricas permiten la configuración individual de la compresión. Si aún necesitas sobreescribir esto por pod, puedes establecer `statsCompression: false` mediante la anotación `proxy.istio.io/config`.

## Captura DNS de ambient habilitada por defecto

El proxy DNS está habilitado por defecto para los workloads ambient en esta versión. Ten en cuenta que solo los pods nuevos tendrán DNS habilitado; los pods existentes no tendrán su tráfico DNS capturado.
Para habilitar esta función en los pods existentes, los pods deben reiniciarse manualmente, o bien la función de reconciliación de iptables puede habilitarse al actualizar
`istio-cni` mediante `--set cni.ambient.reconcileIptablesOnStartup=true`, lo que reconciliará los pods existentes automáticamente durante la actualización.

## Actualización en modo ambient con dry-run AuthorizationPolicy

Si usas `AuthorizationPolicy` en modo dry-run y deseas habilitar esta nueva función, la actualización a 1.29 incluye algunas consideraciones importantes. Antes de Istio 1.29, ztunnel no tenía ninguna capacidad para gestionar `AuthorizationPolicy` en modo dry-run. Como resultado, istiod no enviaba ninguna política dry-run a ztunnel. Istio 1.29 introduce soporte experimental para `AuthorizationPolicy` en modo dry-run en ztunnel. Configurar `AMBIENT_ENABLE_DRY_RUN_AUTHORIZATION_POLICY=true` hará que istiod comience a enviar políticas dry-run a ztunnel, usando un nuevo campo en xDS. Un ztunnel inferior a la versión 1.29 no admitirá este campo. Como resultado, los ztunnels más antiguos aplicarán completamente estas políticas, lo que probablemente producirá un resultado inesperado. Para garantizar una actualización fluida, es importante asegurarse de que todos los proxies ztunnel que se conectan a un istiod con esta función habilitada sean lo suficientemente nuevos para gestionar correctamente estas políticas.

## Autorización de endpoints de depuración habilitada por defecto

Las herramientas que acceden a los endpoints de depuración desde namespaces que no son del sistema (como Kiali o herramientas de monitorización personalizadas)
pueden verse afectadas. Los namespaces que no son del sistema ahora quedan restringidos a los endpoints `config_dump`, `ndsz` y `edsz`
solo para proxies del mismo namespace. Para restaurar el comportamiento anterior, establece `ENABLE_DEBUG_ENDPOINT_AUTH=false`.

## Cambio de comportamiento en el seguimiento de métricas del circuit breaker

El comportamiento predeterminado para el seguimiento de las métricas restantes del circuit breaker ha cambiado. Anteriormente, estas métricas
se rastreaban por defecto. Ahora, el rastreo está desactivado por defecto para un mejor uso de la memoria del proxy.

Para mantener el comportamiento anterior donde las métricas restantes se rastreaban, puedes:

1. Establecer la variable de entorno `DISABLE_TRACK_REMAINING_CB_METRICS=false` en tu despliegue de istiod
1. Usar la función de versión de compatibilidad para obtener el comportamiento heredado

Este cambio afecta al campo `TrackRemaining` en la configuración del circuit breaker de Envoy.

## Eliminaciones del chart Helm base

Una serie de configuraciones presentes anteriormente en el chart Helm `base` fueron *copiadas* al chart `istiod` en versiones anteriores.

En esta versión, las configuraciones duplicadas se eliminan completamente del chart `base`.

La tabla a continuación muestra una correspondencia de la configuración antigua a la nueva:

| Antigua                                 | Nueva                                   |
| --------------------------------------- | --------------------------------------- |
| `ClusterRole istiod`                    | `ClusterRole istiod-clusterrole`        |
| `ClusterRole istiod-reader`             | `ClusterRole istio-reader-clusterrole`  |
| `ClusterRoleBinding istiod`             | `ClusterRoleBinding istiod-clusterrole` |
| `Role istiod`                           | `Role istiod`                           |
| `RoleBinding istiod`                    | `RoleBinding istiod`                    |
| `ServiceAccount istiod-service-account` | `ServiceAccount istiod`                 |

Nota: la mayoría de los recursos tienen además un sufijo añadido automáticamente.
En el chart antiguo, este era `-{{ .Values.global.istioNamespace }}`.
En el nuevo chart es `{{- if not (eq .Values.revision "") }}-{{ .Values.revision }}{{- end }}` para los recursos con ámbito de namespace, y `{{- if not (eq .Values.revision "")}}-{{ .Values.revision }}{{- end }}-{{ .Release.Namespace }}` para los recursos con ámbito de clúster.

## Reconciliación de iptables en ambient habilitada por defecto

La reconciliación de iptables está habilitada por defecto para los workloads ambient en la versión 1.29.0. Cuando un nuevo pod del `DaemonSet` de istio-cni se inicia,
inspeccionará automáticamente los pods que estaban anteriormente inscritos en la mesh ambient y actualizará sus reglas de iptables/nftables en el pod al estado actual
si hay alguna diferencia. Esta función puede desactivarse explícitamente con `--set cni.ambient.reconcileIptablesOnStartup=false`.
