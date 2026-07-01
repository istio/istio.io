---
title: Habilitar el modo ambient
description: Etiqueta namespaces, activa waypoints, elimina la inyección de sidecar y valida la migración.
weight: 4
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate/migrate-policies
---

Habilita el modo ambient un namespace a la vez. Esto te permite validar cada namespace antes de
continuar, y revertir un solo namespace si algo sale mal.

{{< warning >}}
**Si tienes políticas L7, actualmente no hay un path de migración sin tiempo de inactividad.** Durante
la transición, los clientes sidecar omiten los waypoints completamente, por lo que las políticas L7 adjuntas al
waypoint no se aplican para el tráfico proveniente de fuentes sidecar. Además, las antiguas
políticas L7 basadas en selector deben eliminarse al reiniciar el pod y ser reemplazadas por equivalentes
basados en waypoint — hay una breve ventana entre estas dos operaciones donde las reglas L7 no se
aplican. Esta es una brecha conocida. Planifica una ventana de mantenimiento si se requiere la aplicación
continua de políticas L7. Esta brecha es una limitación conocida y se está siguiendo para su mejora en versiones futuras.
{{< /warning >}}

## Migración de un namespace

### Requisitos de orden

{{< warning >}}
El orden de las operaciones en este paso es crítico. Sigue la secuencia a continuación exactamente:

1. Activa los waypoints **antes** de habilitar el modo ambient.
1. Habilita el modo ambient (etiqueta el namespace).
1. Elimina la inyección de sidecar **después** de confirmar que el modo ambient funciona.
1. Reinicia los pods **al final**.
{{< /warning >}}

No seguir esta secuencia puede resultar en que el tráfico no sea procesado ni por el sidecar ni por
ztunnel, causando interrupciones en tus workloads.

### Paso 1: Activar waypoints

{{< tip >}}
Omite este paso si no estás usando waypoints.
{{< /tip >}}

Activa los waypoints desplegados en el [paso anterior](/docs/ambient/migrate/install-ambient-components/)
agregando la etiqueta `istio.io/use-waypoint`.

Para activar un waypoint para todo un namespace:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/use-waypoint=waypoint
{{< /text >}}

Para activar un waypoint para un Service específico únicamente:

{{< text syntax=bash snip_id=none >}}
$ kubectl label service <service-name> -n <namespace> istio.io/use-waypoint=waypoint
{{< /text >}}

Verifica que el waypoint está listo:

{{< text syntax=bash snip_id=none >}}
$ kubectl get gateway waypoint -n <namespace>
{{< /text >}}

La columna `READY` debería mostrar `True`.

### Paso 2: Habilitar el modo ambient para el namespace

Agrega la etiqueta `istio.io/dataplane-mode=ambient` al namespace. Esto indica al plugin CNI
que los pods nuevos y reiniciados en este namespace deben usar ztunnel en lugar de
(o junto a) un sidecar:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/dataplane-mode=ambient
{{< /text >}}

Verifica que el namespace ahora está incorporado a la mesh ambient:

{{< text syntax=bash snip_id=none >}}
$ istioctl ztunnel-config workloads -n istio-system | grep <namespace>
{{< /text >}}

Los workloads del namespace aparecerán con `HBONE` como su protocolo. Los pods aún
tienen sus sidecars en este punto. El sidecar tiene prioridad sobre ztunnel para pods
que tienen ambos.

### Paso 3: Eliminar la inyección de sidecar

Elimina la etiqueta de inyección de sidecar del namespace:

Si usas la etiqueta de inyección por defecto:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio-injection-
{{< /text >}}

Si usas una etiqueta de revisión:

{{< text syntax=bash snip_id=none >}}
$ kubectl label namespace <namespace> istio.io/rev-
{{< /text >}}

{{< warning >}}
Eliminar la etiqueta de inyección por sí sola no elimina los sidecars existentes. Los pods deben
reiniciarse para que el cambio surta efecto. No reinicies los pods hasta que hayas confirmado
que el modo ambient está activo (Paso 2 anterior).
{{< /warning >}}

### Paso 4: Reiniciar pods

Reinicia los workloads del namespace. Al reiniciarse, los pods se activarán sin contenedores sidecar
y usarán ztunnel (y el waypoint, si está configurado) en su lugar:

{{< text syntax=bash snip_id=none >}}
$ kubectl rollout restart deployment -n <namespace>
$ kubectl rollout status deployment -n <namespace>
{{< /text >}}

### Paso 5: Eliminar las antiguas políticas de sidecar

{{< warning >}}
Haz esto inmediatamente después del reinicio del pod, antes de ejecutar cualquier validación. Una vez que se
eliminan los sidecars, ztunnel toma el control de la aplicación de políticas. ztunnel solo comprende atributos L4
y descarta silenciosamente cualquier condición L7 (métodos HTTP, paths, headers, request principals)
de las reglas de `AuthorizationPolicy`. El efecto depende de la acción de la política:

- **Política `ALLOW` con reglas L7**: ztunnel descarta las condiciones L7. Si cada regla de la
  política dependía únicamente de atributos L7, la política resultante no tiene reglas y no coincide con
  nada, lo que hace que ztunnel **deniegue todo el tráfico** a ese workload (una política `ALLOW`
  sin reglas coincidentes no permite nada).
- **Política `DENY` con reglas L7**: ztunnel descarta las condiciones L7. Si una regla no tenía
  condiciones L4 para empezar (por ejemplo, solo coincidía con request principals o paths HTTP),
  eliminar las partes L7 deja una coincidencia vacía que se aplica a todo el tráfico,
  efectivamente **denegando todo el tráfico** a ese workload.

En ambos casos, dejar activas las antiguas políticas L7 basadas en selector después de eliminar los sidecars
bloqueará el tráfico. Elimínalas inmediatamente.
{{< /warning >}}

Elimina cualquier recurso `AuthorizationPolicy` que usara un `selector` de workload con reglas L7,
ahora que han sido reemplazados por equivalentes basados en `targetRefs`:

{{< text syntax=bash snip_id=none >}}
$ kubectl delete authorizationpolicy <sidecar-policy-name> -n <namespace>
{{< /text >}}

También elimina los recursos `VirtualService` y `DestinationRule` reemplazados por `HTTPRoute`:

{{< text syntax=bash snip_id=none >}}
$ kubectl delete virtualservice <name> -n <namespace>
$ kubectl delete destinationrule <name> -n <namespace>
{{< /text >}}

Los recursos L4 de `AuthorizationPolicy` que usan `selector` (sin reglas L7) son seguros de mantener;
ztunnel los aplica correctamente.

### Paso 6: Validar

Verifica que los pods estén ejecutándose sin contenedores sidecar:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pods -n <namespace>
{{< /text >}}

Confirma que ztunnel está gestionando los workloads:

{{< text syntax=bash snip_id=none >}}
$ istioctl ztunnel-config workloads -n istio-system | grep <namespace>
{{< /text >}}

Si desplegaste waypoints, verifica que las políticas L7 y las reglas de enrutamiento se están aplicando
probando los comportamientos específicos (enrutamiento basado en headers, restricciones de método HTTP, etc.) que
definen tus recursos `HTTPRoute` y `AuthorizationPolicy`.

## Repetir para cada namespace

Repite los pasos de [Migración de un namespace](#migrating-a-namespace) para cada namespace que
quieras migrar. Los namespaces no etiquetados con `istio.io/dataplane-mode=ambient` continúan
usando sus sidecars y no se ven afectados.

## Reversión

Cada paso es reversible de forma independiente. Usa el procedimiento de reversión que corresponda a cuánto has avanzado:

| Paso | Acción de reversión |
|---|---|
| Después del Paso 1 (waypoints activados) | `kubectl label namespace <ns> istio.io/use-waypoint-` |
| Después del Paso 2 (ambient habilitado) | `kubectl label namespace <ns> istio.io/dataplane-mode-` |
| Después del Paso 3 (inyección eliminada) | Vuelve a agregar la etiqueta de inyección: `kubectl label namespace <ns> istio-injection=enabled` |
| Después del Paso 4 (pods reiniciados) | Vuelve a agregar la etiqueta de inyección, luego `kubectl rollout restart deployment -n <ns>` |
| Después del Paso 5 (antiguas políticas eliminadas) | `kubectl apply -f istio-config-backup.yaml` para restaurar desde la copia de seguridad |

Después de cualquier reversión que implique reinicios de pods, verifica que los pods muestren 2/2 contenedores
(lo que indica que el sidecar ha sido reinyectado) y confirma que el tráfico fluye antes de
continuar.

{{< warning >}}
Revertir después del Paso 5 usando `kubectl apply -f istio-config-backup.yaml` restaura los
recursos de estilo sidecar originales, pero también **sobreescribe cualquier recurso ambient nuevo** creado
durante la migración (como las reglas `HTTPRoute` y los recursos `AuthorizationPolicy` basados en `targetRefs`)
que compartan el mismo nombre. Antes de aplicar la copia de seguridad, elimina primero los recursos ambient,
o usa `kubectl apply` selectivo en recursos individuales en lugar del archivo de copia de seguridad completo.
{{< /warning >}}

## Cambios en la observabilidad post-migración

Después de migrar al modo ambient, ten en cuenta los siguientes cambios en la telemetría:

**Métricas**: En modo sidecar, las métricas se reportan con `reporter="source"` y
`reporter="destination"`. En modo ambient, las métricas de ztunnel usan `reporter="source"`,
mientras que las métricas de los waypoint proxies usan `reporter="waypoint"`. Actualiza cualquier panel de control o
regla de alertas que dependa de la etiqueta `reporter`.

**Fusión de métricas**: En modo sidecar, el agente proxy soporta la
[fusión de métricas](/docs/ops/integrations/prometheus/#option-1-metrics-merging), que
combina las métricas de Istio y las de la aplicación en un único destino de scrape usando las anotaciones estándar
`prometheus.io`. Esta característica no está disponible en modo ambient. Después de
la migración, debes configurar Prometheus para hacer scrape de los componentes de Istio (pods de ztunnel y waypoint)
y de tus pods de aplicación como destinos separados. Actualiza cualquier recurso `PodMonitor` o
`ServiceMonitor` que dependía de un único endpoint fusionado.

**Trazado**: En modo sidecar, cada salto genera dos spans (uno del sidecar de origen,
otro del sidecar de destino). En modo ambient con waypoints, se genera un span
por waypoint. Actualiza los SLOs basados en trazas en consecuencia.

**`istioctl proxy-status`**: Este comando no muestra los workloads de ztunnel. Usa
`istioctl ztunnel-config workloads` en su lugar para inspeccionar el estado del proxy ambient.

Para más información, consulta:

- [Solución de problemas de ztunnel](/docs/ambient/usage/troubleshoot-ztunnel/)
- [Solución de problemas de waypoints](/docs/ambient/usage/troubleshoot-waypoint/)
