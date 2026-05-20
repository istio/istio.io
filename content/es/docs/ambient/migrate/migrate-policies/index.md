---
title: Migrar políticas
description: Convierte las políticas de tráfico y autorización de sidecar para uso en modo ambient.
weight: 3
owner: istio/wg-networking-maintainers
test: no
prev: /docs/ambient/migrate/install-ambient-components
next: /docs/ambient/migrate/enable-ambient-mode
---

{{< tip >}}
**Es posible que puedas omitir esta página.** Si solo usas reglas L4 de `AuthorizationPolicy`
(sin coincidencia de `methods`, `paths` ni `headers`), no tienes recursos `VirtualService` o
`DestinationRule`, y no tienes recursos `EnvoyFilter`, `WasmPlugin` ni
`RequestAuthentication`, tus políticas existentes funcionarán en modo ambient sin
cambios. Ve directamente a [Habilitar el modo ambient](/docs/ambient/migrate/enable-ambient-mode/).
{{< /tip >}}

En modo ambient, la gestión de tráfico L7 la manejan los proxies {{< gloss >}}waypoint{{< /gloss >}}
en lugar de los proxies sidecar. Esto cambia cómo se expresan y aplican las políticas:

- El soporte de **`VirtualService`** con waypoints es **Alpha**. Aunque puede funcionar en casos limitados,
  se recomienda fuertemente migrar a `HTTPRoute`. Mezclar `VirtualService` y
  `HTTPRoute` para el mismo workload no está soportado y lleva a comportamiento indefinido.
- Las políticas de tráfico de **`DestinationRule`** (configuración del connection pool, detección de anomalías, TLS)
  son soportadas por los waypoints y no requieren cambios. Sin embargo, `HTTPRoute` usa Services de Kubernetes
  como `backendRefs` para el enrutamiento en lugar de subsets de DestinationRule, por lo que
  la división de tráfico basada en versiones en `HTTPRoute` requiere Services separados por versión.
- Los recursos **`AuthorizationPolicy`** que usan reglas L7 (métodos HTTP, paths o headers),
  o que usan `action: CUSTOM` o `action: AUDIT`, deben usar `targetRefs` (en lugar del
  `selector` de workload) para adjuntar la política a los recursos soportados; para más información consulta la
  [documentación de AuthorizationPolicy](/docs/reference/config/security/authorization-policy/#AuthorizationPolicy-targetRefs).
- Los recursos **`RequestAuthentication`** y **`WasmPlugin`** requieren un waypoint proxy y
  deben apuntarse usando `targetRefs` para apuntar al waypoint.
- Los recursos **`EnvoyFilter`** **no están soportados en los waypoints**. Si tienes recursos `EnvoyFilter`
  que configuran el comportamiento del proxy sidecar, serán ignorados silenciosamente después de
  la migración y deben manejarse antes de continuar:
    - Si el filtro agrega funcionalidad personalizada de Envoy, evalúa si un `WasmPlugin` puede
      proporcionar un comportamiento equivalente en el waypoint.
    - Si el filtro ya no es necesario, elimínalo.
    - Si no hay una alternativa compatible con ambient, esto es un bloqueador de migración. No
      continúes hasta que se resuelva la dependencia.

## Auditar tus políticas existentes

Comienza listando todos los recursos L7 en tu clúster:

{{< text syntax=bash snip_id=none >}}
$ kubectl get virtualservice,destinationrule -A
{{< /text >}}

Identifica los recursos `AuthorizationPolicy` que requerirán un waypoint (reglas L7 o
acciones `CUSTOM`/`AUDIT`):

{{< text syntax=bash snip_id=none >}}
$ kubectl get authorizationpolicy -A --no-headers | while read ns name rest; do
    if kubectl get authorizationpolicy "$name" -n "$ns" -o yaml | grep -qE "(methods:|paths:|headers:|action: CUSTOM|action: AUDIT)"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

Identifica los recursos `DestinationRule` con subsets (estos requieren Services específicos por versión
en modo ambient):

{{< text syntax=bash snip_id=none >}}
$ kubectl get destinationrule -A --no-headers | while read ns name rest; do
    if kubectl get destinationrule "$name" -n "$ns" -o yaml | grep -q "subsets:"; then
      echo "$ns/$name"
    fi
  done
{{< /text >}}

## Migrar VirtualService a HTTPRoute

{{< warning >}}
El soporte de `VirtualService` con waypoints es Alpha y puede fallar en versiones futuras.
Migra tus recursos `VirtualService` a `HTTPRoute` antes de completar la migración.
No dejes tanto recursos `VirtualService` como `HTTPRoute` apuntando al mismo workload, ya que
esto lleva a comportamiento indefinido.
{{< /warning >}}

`HTTPRoute` es la API de enrutamiento L7 estable y soportada para el modo ambient.

{{< tip >}}
La herramienta de la comunidad [ingress2gateway](https://github.com/kubernetes-sigs/ingress2gateway)
puede automatizar parte de esta conversión. Su
[proveedor de Istio](https://github.com/kubernetes-sigs/ingress2gateway/blob/main/pkg/i2gw/providers/istio/README.md)
traduce recursos `VirtualService` a `HTTPRoute`, `TLSRoute` y `TCPRoute`, y
genera recursos `ReferenceGrant` para referencias entre namespaces. Los campos que no se pueden
traducir directamente se registran y omiten, por lo que siempre revisa la salida generada
antes de aplicarla a tu clúster. Ten en cuenta que también se traducen los recursos `IngressGateway` a recursos Gateway de la Gateway API, por lo que esta herramienta puede usarse para la migración tanto de VirtualService como de recursos Gateway.
{{< /tip >}}

### Ejemplo: Enrutamiento basado en headers

El siguiente `VirtualService` enruta las solicitudes con `end-user: jason` a la versión 2 de `reviews`,
y todas las demás solicitudes a la versión 1 usando subsets:

{{< text syntax=yaml snip_id=none >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
{{< /text >}}

Dado que `HTTPRoute` no soporta subsets de DestinationRule, primero debes crear
Services específicos por versión:

{{< text syntax=yaml snip_id=none >}}
apiVersion: v1
kind: Service
metadata:
  name: reviews-v1
  namespace: bookinfo
spec:
  selector:
    app: reviews
    version: v1
  ports:
  - port: 9080
    name: http
---
apiVersion: v1
kind: Service
metadata:
  name: reviews-v2
  namespace: bookinfo
spec:
  selector:
    app: reviews
    version: v2
  ports:
  - port: 9080
    name: http
{{< /text >}}

Luego reemplaza el `VirtualService` con un `HTTPRoute` que se adjunte directamente al Service `reviews`
(usando `kind: Service` como `parentRef`). Este es el modelo de adjunción correcto para el
modo ambient — el waypoint usa el Service como ancla de enrutamiento:

{{< text syntax=yaml snip_id=none >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: bookinfo
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - matches:
    - headers:
      - name: end-user
        value: jason
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
{{< /text >}}

Para una referencia completa sobre las capacidades de `HTTPRoute`, consulta la
[documentación de gestión de tráfico](/docs/tasks/traffic-management/).

## Migrar AuthorizationPolicy para reglas L7

En modo sidecar, los recursos `AuthorizationPolicy` usan un `selector` para apuntar directamente a los pods.
En modo ambient, las políticas de autorización L7 deben ser aplicadas por un waypoint proxy y por tanto
deben usar `targetRefs` para apuntar al `Service` padre del waypoint o al propio recurso `Gateway`.

### Políticas L4 (no requieren cambios)

Los recursos L4 de `AuthorizationPolicy` que solo coinciden con principales de origen, namespaces o rangos
de IP funcionan en modo ambient sin modificaciones. Los aplica ztunnel.

{{< text syntax=yaml snip_id=none >}}
# Esta política L4 no requiere cambios para el modo ambient
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/bookinfo/sa/productpage"]
{{< /text >}}

### Políticas L7

{{< warning >}}
La migración de políticas L7 implica una breve brecha de aplicación. Las antiguas políticas basadas en selector deben
eliminarse antes o al reiniciar el pod, y las nuevas políticas basadas en waypoint surten efecto
inmediatamente una vez creadas. Entre estas dos operaciones, las reglas L7 no se aplican. Si
se requiere la aplicación continua de políticas L7, planifica una ventana de mantenimiento. Esta brecha es una limitación conocida y se está siguiendo para su mejora en versiones futuras.
{{< /warning >}}

Las políticas que coincidan con métodos HTTP, paths o headers, o que usen `action: CUSTOM` o
`action: AUDIT`, deben apuntar a un waypoint proxy. Reemplaza `selector` con `targetRefs`
apuntando al `Service` que el waypoint protege, o directamente al recurso `Gateway` del waypoint:

{{< text syntax=yaml snip_id=none >}}
# Antes: estilo sidecar (basado en selector)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

{{< text syntax=yaml snip_id=none >}}
# Después: estilo ambient (targetRefs al Service)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  targetRefs:
  - kind: Service
    group: ""
    name: reviews
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

Alternativamente, puedes apuntar directamente al recurso `Gateway` del waypoint. Esto aplica la
política a todo el tráfico procesado por el waypoint, independientemente del Service de destino:

{{< text syntax=yaml snip_id=none >}}
# Después: estilo ambient (targetRefs al Gateway del waypoint)
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-get-reviews
  namespace: bookinfo
spec:
  targetRefs:
  - kind: Gateway
    group: gateway.networking.k8s.io
    name: waypoint
  action: ALLOW
  rules:
  - to:
    - operation:
        methods: ["GET"]
{{< /text >}}

Apuntar a un `Service` es la opción más precisa y se recomienda cuando la política
debe aplicarse a un único servicio. Apuntar al `Gateway` es útil cuando la política
debe aplicarse a todos los servicios del namespace.

## Prevenir el bypass del waypoint

Cuando se usa un waypoint, asegúrate de que los workloads no puedan alcanzarse omitiendo el waypoint. Usa una
política DENY con `selector` de workload aplicada por **ztunnel** (en el pod de destino). Dado que
esta política solo verifica el principal de origen (un atributo L4), ztunnel puede aplicarla
correctamente.

{{< warning >}}
No uses `targetRefs` para esta política. Una política DENY basada en `targetRefs` la aplica
el waypoint, que ve la identidad del cliente original, no la identidad propia del waypoint.
Esto haría que el waypoint rechazara todo el tráfico de clientes antes de que la política ALLOW pueda ejecutarse.
{{< /warning >}}

### Decidir cuándo aplicar la prevención de bypass

Durante una migración incremental, algunos workloads de origen aún pueden estar en modo sidecar.
Los workloads en modo sidecar omiten el waypoint y se conectan directamente a ztunnel en el
destino, por lo que ztunnel ve la identidad del sidecar como principal de origen, no la identidad
del waypoint. Una política DENY estricta solo para el waypoint rechazará su tráfico.

Elige una de las siguientes opciones antes de aplicar la política:

**Opción 1: Retrasar la prevención de bypass hasta que todos los orígenes se hayan migrado.**
No apliques la política DENY hasta que cada workload que llame a este servicio haya pasado al
modo ambient. Este es el enfoque más sencillo cuando controlas todos los llamadores.

**Opción 2: Permitir tráfico tanto del waypoint como de los principales del sidecar.**
Aplica la política inmediatamente, pero agrega las cuentas de servicio de los workloads sidecar restantes
a la lista de excepción `notPrincipals` junto con el waypoint. Elimina cada principal del sidecar
de la lista a medida que se migra. Una vez que todos los llamadores estén en modo ambient,
solo necesita quedar el principal del waypoint.

### Aplicar la política de prevención de bypass

Busca la cuenta de servicio que usa tu waypoint:

{{< text syntax=bash snip_id=none >}}
$ kubectl get pod -n <namespace> -l gateway.istio.io/managed=istio.io-mesh-controller \
    -o jsonpath='{.items[0].spec.serviceAccountName}'
{{< /text >}}

Para la Opción 1, aplica la política solo después de que todos los llamadores se hayan migrado:

{{< text syntax=yaml snip_id=none >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-waypoint-bypass
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals:
        - "cluster.local/ns/bookinfo/sa/waypoint"
{{< /text >}}

Para la Opción 2, incluye los principales del sidecar en la lista de excepciones durante la migración:

{{< text syntax=yaml snip_id=none >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-waypoint-bypass
  namespace: bookinfo
spec:
  selector:
    matchLabels:
      app: reviews
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals:
        - "cluster.local/ns/bookinfo/sa/waypoint"
        - "cluster.local/ns/bookinfo/sa/productpage"
{{< /text >}}

{{< warning >}}
Mantén tus recursos `AuthorizationPolicy` de sidecar existentes activos hasta que los pods se hayan
reiniciado sin sidecars. Sin embargo, **elimínalos inmediatamente después del reinicio del pod** —
no esperes a la validación completa. Cualquier `AuthorizationPolicy` que use un `selector` de workload
con reglas L7 (métodos HTTP, paths o headers) que permanezca activo después de eliminar los sidecars
será recogido por ztunnel, que no puede aplicar reglas L7 y lo convertirá en una política `DENY`
para todo el tráfico a ese workload.
{{< /warning >}}

## Próximos pasos

Continúa con [Habilitar el modo ambient](/docs/ambient/migrate/enable-ambient-mode/) para etiquetar
namespaces, activar waypoints y eliminar la inyección de sidecar.
