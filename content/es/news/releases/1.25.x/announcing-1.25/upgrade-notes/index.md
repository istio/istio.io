---
title: Notas de Actualización de Istio 1.25
description: Cambios importantes a tener en cuenta al actualizar a Istio 1.25.0.
weight: 20
publishdate: 2025-03-03
---

Al actualizar de Istio 1.24.x a Istio 1.25.x, ten en cuenta los cambios de esta página.
Estas notas detallan los cambios que rompen intencionalmente la compatibilidad con versiones anteriores a Istio 1.24.x.
También se mencionan cambios que preservan la compatibilidad con versiones anteriores pero introducen un nuevo comportamiento.
Solo se incluyen cambios cuyo nuevo comportamiento podría sorprender a un usuario de Istio 1.24.x.

## Reconciliación de pods en modo ambient durante la actualización

Cuando un nuevo pod del DaemonSet `istio-cni` arranca, inspeccionará los pods previamente inscritos en el ambient mesh y actualizará sus reglas de iptables internas al estado actual si hay diferencias. Esta opción está desactivada por defecto en la versión 1.25.0, pero eventualmente se habilitará por defecto. Se puede activar con `helm install cni --set ambient.reconcileIptablesOnStartup=true` (Helm) o `istioctl install --set values.cni.ambient.reconcileIptablesOnStartup=true` (istioctl).

## El tráfico DNS (TCP y UDP) ahora respeta las anotaciones de exclusión de tráfico

El tráfico DNS (UDP y TCP) ahora respeta las anotaciones de tráfico a nivel de pod como `traffic.sidecar.istio.io/excludeOutboundIPRanges` y `traffic.sidecar.istio.io/excludeOutboundPorts`. Anteriormente, el tráfico UDP/DNS ignoraba estas anotaciones de forma única, incluso si se especificaba un puerto DNS, debido a la estructura de las reglas. Este cambio de comportamiento ocurrió realmente en la serie de versiones 1.23, pero se omitió en las notas de la versión 1.23.

## Captura DNS activada por defecto en modo ambient

El DNS proxying está habilitado por defecto para los workloads en modo ambient en esta versión. Ten en cuenta que solo los pods nuevos tendrán DNS habilitado: los pods existentes no tendrán capturado su tráfico DNS. Para habilitar esta característica en pods existentes, deben reiniciarse manualmente o, como alternativa, habilitar la característica de reconciliación de iptables al actualizar `istio-cni` mediante `--set cni.ambient.reconcileIptablesOnStartup=true`. Esto reconciliará los pods existentes automáticamente durante la actualización.

Los pods individuales pueden optar por no usar la captura DNS global en modo ambient aplicando la anotación `ambient.istio.io/dns-capture=false`.

## Cambios en los dashboards de Grafana

Los dashboards incluidos con Istio 1.25 requieren la versión 7.2 o posterior de Grafana.

## Se ha eliminado el soporte de OpenCensus

Dado que Envoy ha [eliminado la extensión de tracing OpenCensus](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.33/v1.33.0.html#incompatible-behavior-changes), hemos eliminado el soporte de OpenCensus de Istio. Si estás usando OpenCensus, debes migrar a OpenTelemetry. [Más información sobre la obsolescencia de OpenCensus](https://opentelemetry.io/blog/2023/sunsetting-opencensus/).

## Cambios en el chart Helm de ztunnel

En versiones anteriores, los recursos del chart Helm de ztunnel siempre se llamaban `ztunnel`.
En esta versión, ahora se denominan `.Resource.Name`.

Si estás instalando el chart con un nombre de release distinto de `ztunnel`, los nombres de los recursos cambiarán, lo que provocará tiempo de inactividad.
En ese caso, se recomienda establecer `--set resourceName=ztunnel` para volver al valor predeterminado anterior.
