---
title: Antes de comenzar
description: Verifica tu entorno y prepárate para la migración.
weight: 1
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate
next: /docs/ambient/migrate/install-ambient-components
---

Antes de migrar de modo sidecar a modo ambient, verifica que tu entorno cumple con los
requisitos y crea una copia de seguridad de tu configuración actual.

{{< warning >}}
**Si tus workloads usan políticas L7, la migración no es sencilla y actualmente tiene
limitaciones conocidas:**

- Durante la migración, hay una ventana en la que las políticas L7 pueden no aplicarse; las antiguas
  políticas basadas en selector deben eliminarse, y los nuevos equivalentes basados en waypoint deben tomar
  su lugar. No hay una transición atómica entre los dos.
- Mientras algunos workloads de origen aún estén en modo sidecar, el tráfico de esos workloads
  omite los waypoints completamente. Las políticas L7 del waypoint no se aplican para ese
  path de tráfico hasta que el origen también se migre.

**La migración sin tiempo de inactividad con políticas L7 no está soportada actualmente.** Planifica una
ventana de mantenimiento. Esta es una limitación conocida que se está siguiendo para su mejora en una versión
futura.

Si tus workloads solo usan reglas L4 de `AuthorizationPolicy` (por principal de origen, namespace,
o coincidencia por IP, sin métodos HTTP, paths ni headers), esto no aplica y la
migración no requiere cambios en las políticas.
{{< /warning >}}

## Contexto: cómo cambia la aplicación de políticas

Comprender las diferencias clave entre la aplicación de políticas en modo sidecar y en modo ambient te ayudará
a entender los pasos de migración y anticipar dónde se necesitan cambios.

**En modo sidecar:**
- Las políticas usan un `selector` para apuntar a pods por etiqueta.
- El proxy sidecar de destino aplica tanto las políticas L4 como las L7.
- Una sola `AuthorizationPolicy` puede coincidir con el principal de origen, método HTTP, path o header
  y aplicarse en el pod de destino.

**En modo ambient:**
- La aplicación L4 la maneja **ztunnel**, que se ejecuta en cada nodo.
- La aplicación L7 requiere un **waypoint proxy** desplegado por namespace o servicio.
- Las políticas aplicadas por un waypoint deben usar `targetRefs` apuntando a un `Service` o
  `Gateway`, no a un `selector` de pod. No puedes reutilizar políticas L7 basadas en selector tal como están.
- `VirtualService` es Alpha en modo ambient. La migración a `HTTPRoute` es necesaria para la
  gestión de tráfico L7 estable.

## Requisitos

- Una [versión de Istio soportada](/docs/releases/supported-releases/)
- [Versión soportada](/docs/releases/supported-releases#support-status-of-istio-releases) de Kubernetes ({{< supported_kubernetes_versions >}})
- CRDs de Gateway API instalados (necesarios para los waypoint proxies)

Si aún no tienes instalados los CRDs de Gateway API, instálalos ahora:

{{< boilerplate gateway-api-install-crds >}}

## Verificar tu instalación actual

Ejecuta los siguientes comandos para confirmar el estado de tu instalación de sidecar existente:

{{< text syntax=bash snip_id=none >}}
$ istioctl version
$ kubectl get pods -n istio-system
$ kubectl get namespaces -l istio-injection=enabled
{{< /text >}}

Verifica si hay instalaciones basadas en revisiones (si usas etiquetas `istio.io/rev` en lugar de
`istio-injection`):

{{< text syntax=bash snip_id=none >}}
$ kubectl get namespaces -l 'istio.io/rev'
{{< /text >}}

## Auditar los recursos existentes

Lista los recursos de Istio en uso en tu clúster:

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule,authorizationpolicy,requestauthentication,peerauthentication,envoyfilter,wasmplugin -A
{{< /text >}}

Verifica qué recursos `AuthorizationPolicy` contienen reglas L7. Estos requerirán waypoint
proxies para funcionar en modo ambient:

{{< text syntax=bash snip_id=none >}}
$ kubectl get authorizationpolicy -A --no-headers | while read ns name rest; do
    if kubectl get authorizationpolicy "$name" -n "$ns" -o yaml | grep -qE "(methods:|paths:|headers:|action: CUSTOM|action: AUDIT)"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

Verifica los recursos `PeerAuthentication` con `mode: DISABLE`, que no son compatibles
con el modo ambient:

{{< text syntax=bash snip_id=none >}}
$ kubectl get peerauthentication -A -o yaml | grep -A2 "mtls:"
{{< /text >}}

Cualquier `PeerAuthentication` con `mode: DISABLE` debe eliminarse o cambiarse antes de la migración,
ya que el modo ambient siempre aplica mTLS entre los workloads de la mesh.

Los recursos `PeerAuthentication` con `mode: STRICT` o `mode: PERMISSIVE` no son bloqueadores,
pero se vuelven redundantes después de la migración: el modo ambient aplica mTLS mediante ztunnel sin importar
estas políticas. Puedes eliminarlos de forma segura una vez completada la migración.

## Hacer una copia de seguridad de tu configuración

Antes de hacer cualquier cambio, exporta tu configuración de Istio actual:

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule,authorizationpolicy,requestauthentication,peerauthentication,gateway,httproute,telemetry -A -o yaml > istio-config-backup.yaml
$ kubectl get namespaces -o yaml > namespace-backup.yaml
{{< /text >}}

Guarda estas copias de seguridad en un lugar seguro fuera del clúster.

## Configurar el monitoreo de tráfico (opcional)

Usa Kiali u otra herramienta de observabilidad para capturar una línea base de tus patrones de tráfico actuales antes de hacer cambios. Consulta [Kiali](/docs/ops/integrations/kiali/) para las instrucciones de configuración.

## Próximos pasos

Continúa con [Instalar componentes ambient](/docs/ambient/migrate/install-ambient-components/).
