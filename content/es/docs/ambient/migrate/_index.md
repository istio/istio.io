---
title: Migrar de Sidecar a Ambient
description: Migra un despliegue existente de Istio basado en sidecar al modo ambient.
weight: 12
owner: istio/wg-networking-maintainers
test: no
skip_list: true
next: /docs/ambient/migrate/before-you-begin
---

Esta guía te lleva a través del proceso de migración de un despliegue de Istio existente desde el modo
{{< gloss >}}sidecar{{< /gloss >}} al {{< gloss "ambient" >}}modo ambient{{< /gloss >}}.
La migración está diseñada para ser gradual y reversible: los workloads en modo sidecar y en modo ambient pueden
coexistir en la misma mesh durante el proceso, lo que te permite migrar un namespace a la vez.

{{< warning >}}
**Si tienes políticas L7, actualmente no es posible hacer una migración sin tiempo de inactividad.** Durante
la transición, hay una ventana en la que las políticas L7 no se aplican: las antiguas
políticas basadas en selector deben eliminarse del lado del sidecar, y los nuevos equivalentes basados en
waypoint deben tomar su lugar. Entre esas dos operaciones, las reglas L7 no se aplican.
Esta es una brecha conocida. Planifica una ventana de mantenimiento si la aplicación de políticas L7 debe ser
continua. La comunidad de Istio está trabajando actualmente para hacer posible la migración sin tiempo de inactividad;
consulta los issues y discusiones actuales al respecto en nuestro Slack.
{{< /warning >}}

## Estrategia de migración

La migración sigue un enfoque paso a paso:

1. **Instalar los componentes ambient:** Agrega ztunnel y actualiza el CNI para soportar el modo ambient,
   sin modificar los workloads con sidecar existentes.
1. **Migrar las políticas:** Convierte los recursos `VirtualService` a `HTTPRoute`, actualiza
   los recursos `AuthorizationPolicy` para apuntar a waypoints donde sea necesario, y adjunta
   los recursos `RequestAuthentication` y `WasmPlugin` a los waypoints. **Omite este paso si
   solo usas políticas L4.** Si tienes políticas L7, ten en cuenta que hay una breve
   brecha de aplicación durante la migración; consulta la advertencia anterior.
1. **Habilitar el modo ambient por namespace:** Etiqueta los namespaces para unirse a la mesh ambient,
   activa los waypoints, elimina la inyección de sidecar y reinicia los pods.

Cada paso es reversible de forma independiente. No es necesario migrar todos
los namespaces a la vez.

## Descripción general de la migración de recursos

La siguiente tabla resume cómo se mapean los recursos en modo sidecar con sus equivalentes en modo ambient:

| Recurso en modo sidecar | Acción en modo ambient |
|---|---|
| `VirtualService` | Migrar a `HTTPRoute` (el soporte de `VirtualService` es Alpha en ambient) |
| `DestinationRule` (políticas de tráfico: connection pool, detección de anomalías, TLS) | Sin cambios; los waypoints aplican las políticas de tráfico |
| `DestinationRule` (subsets de enrutamiento usados con `HTTPRoute`) | Crear Services de Kubernetes específicos por versión como `backendRefs` para `HTTPRoute` |
| `AuthorizationPolicy` con reglas L4 | Sin cambios; ztunnel aplica las políticas L4 directamente |
| `AuthorizationPolicy` con reglas L7 | Adjuntar al waypoint usando `targetRefs` |
| `RequestAuthentication` | Adjuntar al waypoint usando `targetRefs` |
| `EnvoyFilter` | No soportado en waypoints |
| `WasmPlugin` | Adjuntar al waypoint usando `targetRefs` |
| `Gateway` (networking.istio.io/v1) | No requiere cambios; los recursos Istio Gateway siguen funcionando en modo ambient. Agrega `istio.io/ingress-use-waypoint` para enrutar el tráfico de ingress a través de un waypoint. |

## ¿Necesitas waypoint proxies?

{{< tip >}}
Los waypoint proxies son **opcionales**. Si solo necesitas mTLS y políticas de autorización L4,
puedes migrar a ztunnel sin desplegar waypoints y sin cambiar ninguna política existente.
{{< /tip >}}

Necesitas waypoint proxies si tus workloads usan alguno de los siguientes:

- Reglas L7 de `AuthorizationPolicy` (que coincidan con métodos HTTP, paths o headers).
- Enrutamiento de tráfico L7 (reintentos, inyección de fallos, manipulación de headers, división de tráfico) mediante `HTTPRoute`. Si actualmente usas `VirtualService` para esto, necesitarás migrar a `HTTPRoute`; el soporte de `VirtualService` en ambient es Alpha.
- `RequestAuthentication` (validación JWT).
- Enriquecimiento de telemetría L7.

Si no estás seguro, la página [migrar políticas](/docs/ambient/migrate/migrate-policies/)
te ayuda a auditar tus recursos existentes.

## Qué no está soportado

{{< tip >}}
Las limitaciones listadas a continuación reflejan la versión estable actual de Istio. El modo ambient continúa evolucionando y algunas de estas restricciones pueden eliminarse en versiones posteriores. Consulta las [notas de la versión](/news/releases/) para actualizaciones específicas a tu versión de Istio.
{{< /tip >}}

Los siguientes son bloqueadores críticos; la migración no es posible hasta que se resuelvan:

- **Workloads en VM** en la mesh. Los workloads basados en VM no pueden unirse a la mesh ambient.
- **SPIRE** como proveedor de certificados. El modo ambient no soporta la integración con SPIRE.
- **`PeerAuthentication` con `mode: DISABLE`**. Ambient siempre aplica mTLS entre
  workloads de la mesh. Las políticas con modo `DISABLE` serán ignoradas y no se pueden migrar.
- **Configuraciones multiclúster primary-remote**. Solo se soportan múltiples clústeres primary.
  Los despliegues con uno o más clústeres remote no funcionarán correctamente.

Las siguientes son limitaciones conocidas que afectan el comportamiento durante o después de la migración:

- **Los recursos `EnvoyFilter` apuntando a waypoints no están soportados**. Si dependes de
  `EnvoyFilter` para configuración avanzada de Envoy en tus proxies sidecar, esas
  configuraciones no pueden trasladarse a los waypoints. Esta API podría soportarse en
  una versión futura.
- **El tráfico de workloads en modo sidecar omite los waypoint proxies**. Durante una migración incremental,
  si un workload en modo sidecar llama a un workload en modo ambient que tiene un waypoint,
  el tráfico omite el waypoint completamente. Las políticas L7 del waypoint no se aplican
  a ese tráfico hasta que el workload de origen también se migre al modo ambient.
- **Los ingress gateways omiten los waypoints por defecto**, pero se pueden configurar para enrutar el tráfico
  a través de un waypoint agregando la etiqueta `istio.io/ingress-use-waypoint` al recurso Gateway.
- **No se soporta mezclar `VirtualService` y `HTTPRoute` para el mismo workload** y
  lleva a comportamiento indefinido. Migra cada workload completamente a una API antes de continuar.

## Próximos pasos

Comienza con [Antes de comenzar](/docs/ambient/migrate/before-you-begin/) para verificar
tu entorno y hacer una copia de seguridad de tu configuración.
