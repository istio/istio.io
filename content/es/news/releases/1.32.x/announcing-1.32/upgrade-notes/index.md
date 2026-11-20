---
title: Notas de Actualización
description: Cambios importantes a considerar al actualizar a Istio 1.32.0.
weight: 20
---

Al actualizar de Istio 1.31.0 a Istio 1.32.0, debes tener en cuenta los cambios de esta página.
Estas notas detallan los cambios que rompen intencionalmente la compatibilidad con versiones anteriores de Istio 1.31.x.
Las notas también mencionan cambios que preservan la compatibilidad con versiones anteriores e introducen nuevo comportamiento.
Solo se incluyen los cambios cuyo nuevo comportamiento resultaría inesperado para un usuario de Istio 1.31.x.

## Parches de EnvoyFilter que coinciden con el filtro RBAC del gateway por nombre

Cuando `ENABLE_GATEWAY_API_HTTPROUTE_AUTH=true`, el filtro HTTP de la acción `ALLOW` en los ingress
gateways se emite como `istio.authorization.allow` en lugar de `envoy.filters.http.rbac`. Se requiere un
nombre distinto para que la configuración con alcance de ruta pueda dirigirse al filtro `ALLOW`
sin afectar también a los filtros `DENY` y `AUDIT`, que siguen usando
`envoy.filters.http.rbac`.

Esto afecta a cualquier `EnvoyFilter` que coincida con el filtro RBAC por nombre, por ejemplo:

{{< text yaml >}}
match:
  context: GATEWAY
  listener:
    filterChain:
      filter:
        name: envoy.filters.http.http_connection_manager
        subFilter:
          name: envoy.filters.http.rbac
{{< /text >}}

Un parche así ya no coincide con el filtro `ALLOW`. Las operaciones `MERGE`, `REPLACE` y `REMOVE`
dejan de aplicarse silenciosamente, mientras que `INSERT_BEFORE` e `INSERT_AFTER` descartan por completo el filtro
suministrado de la cadena en lugar de recurrir a otra posición. Los recursos `Gateway` cuyas únicas
políticas de autorización usan la acción `ALLOW` no tienen ningún filtro llamado
`envoy.filters.http.rbac`.

No se emite ninguna advertencia cuando un parche no coincide, a menos que se establezca
`PILOT_ENVOY_FILTER_STATS=true` en `istiod`, lo que expone la métrica `pilot_envoy_filter_status`.

Si dependes de un parche así, añade un segundo `EnvoyFilter` que coincida con
`istio.authorization.allow`, o deja `ENABLE_GATEWAY_API_HTTPROUTE_AUTH` deshabilitado. Las
estadísticas de Envoy no se ven afectadas, ya que las métricas del filtro RBAC se derivan del prefijo de
estadísticas del connection manager y no del nombre del filtro.

## Las solicitudes a la API de Kubernetes ahora tienen timeouts del lado del cliente

Los valores por defecto son adecuados para la mayoría de los clústeres. Los entornos con un servidor de API lento o muy cargado
pueden aumentarlos, o establecer cualquiera de ellos en `0` para restaurar el comportamiento anterior sin límite,
con estas variables de entorno en el componente afectado.

| Variable | Valor por defecto | Se aplica a |
| --- | --- | --- |
| `ISTIO_KUBE_HEADER_TIMEOUT` | `90s` | Cuánto tiempo puede esperar cualquier solicitud los encabezados de su respuesta. Debe mantenerse por encima del `--request-timeout` del servidor de API (`60s` por defecto). |
| `ISTIO_KUBE_REQUEST_TIMEOUT` | `15m` | Duración total de una solicitud que no establece su propio plazo, incluida la lectura de la respuesta. |

Las sesiones exec, attach y port-forward no se ven afectadas. Un timeout incrementa
`kube_client_deadline_fired_total` y registra una advertencia con el método y la ruta.

## Endpoints no saludables de pods y recursos WorkloadEntry

Con `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` habilitado (el valor por defecto), los pods no listos seleccionados por
recursos `ServiceEntry` y los recursos `WorkloadEntry` no saludables con health checks ahora pueden aparecer en las
respuestas de descubrimiento de endpoints con estado no saludable.
