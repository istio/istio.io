---
title: Usar características de capa 7
description: Características compatibles al usar un proxy de waypoint L7.
weight: 50
owner: istio/wg-networking-maintainers
test: no
---

Al agregar un proxy de waypoint a tu flujo de tráfico, puedes habilitar más [características de Istio](/es/docs/concepts). Los waypoints se configuran usando la {{< gloss "gateway api" >}}API de Gateway de Kubernetes{{< /gloss >}}.

{{< warning >}}
El uso de VirtualService con el modo de data plane ambient se considera Alfa. No se admite la mezcla con la configuración de la API de Gateway y dará lugar a un comportamiento indefinido.
{{< /warning >}}

{{< warning >}}
`EnvoyFilter` es la API de emergencia de Istio para la configuración avanzada de los proxies de Envoy. Ten en cuenta que *`EnvoyFilter` no es compatible actualmente con ninguna versión de Istio existente con proxies de waypoint*. Si bien es posible usar `EnvoyFilter` con waypoints en escenarios limitados, su uso no es compatible y los mantenedores lo desaconsejan activamente. La API alfa puede romperse en futuras versiones a medida que evoluciona. Esperamos que se proporcione soporte oficial en una fecha posterior.
{{< /warning >}}

## Enrutamiento y adjunto de políticas

La API de Gateway define la relación entre los objetos (como rutas y gateways) en términos de *adjunto*.

* Los objetos de ruta (como [HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/)) incluyen una forma de hacer referencia a los recursos **padre** a los que se quieren adjuntar.
* Los objetos de política se consideran [*metarrecursos*](https://gateway-api.sigs.k8s.io/geps/gep-713/): objetos que aumentan el comportamiento de un objeto **destino** de una manera estándar.

Las tablas a continuación muestran el tipo de adjunto que se configura para cada objeto.

## Enrutamiento de tráfico

Con un proxy de waypoint desplegado, puedes usar los siguientes tipos de enrutamiento de tráfico:

|  Nombre  | Estado de la característica | Adjunto |
| --- | --- | --- |
| [`HTTPRoute`](https://gateway-api.sigs.k8s.io/guides/http-routing/) | Beta | `parentRefs` |
| [`TLSRoute`](https://gateway-api.sigs.k8s.io/guides/tls) | Alfa | `parentRefs` |
| [`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/) | Alfa | `parentRefs` |

Consulta la documentación de [gestión del tráfico](/es/docs/tasks/traffic-management/) para ver la gama de características que se pueden implementar usando estas rutas.

## Seguridad

Sin un waypoint instalado, solo puedes usar [políticas de seguridad de capa 4](/es/docs/ambient/usage/l4-policy/). Al agregar un waypoint, obtienes acceso a las siguientes políticas:

|  Nombre  | Estado de la característica | Adjunto |
| --- | --- | --- |
| [`AuthorizationPolicy`](/es/docs/reference/config/security/authorization-policy/) (incluidas las características L7) | Beta | `targetRefs` |
| [`RequestAuthentication`](/es/docs/reference/config/security/request_authentication/) | Beta | `targetRefs` |

### Consideraciones para las políticas de autorización {#considerations}

En el modo ambient, las políticas de autorización pueden ser *dirigidas* (para la aplicación de ztunnel) o *adjuntas* (para la aplicación de waypoint). Para que una política de autorización se adjunte a un waypoint, debe tener un `targetRef` que haga referencia al waypoint, o a un Servicio que use ese waypoint.

El ztunnel no puede aplicar políticas L7. Si una política con reglas que coinciden con los atributos L7 se dirige con un selector de carga de trabajo (en lugar de adjuntarse con un `targetRef`), de modo que la aplique un ztunnel, fallará de forma segura al convertirse en una política de `DENEGACIÓN`.

Consulta [la guía de políticas L4](/es/docs/ambient/usage/l4-policy/) para obtener más información, incluido cuándo adjuntar políticas a los waypoints para casos de uso de solo TCP.

## Observabilidad

El [conjunto completo de métricas de tráfico de Istio](/es/docs/reference/config/metrics/) es exportado por un proxy de waypoint.

## Extensión

Como el proxy de waypoint es una implementación de {{< gloss >}}Envoy{{< /gloss >}}, algunos de los mecanismos de extensión que están disponibles para Envoy en el modo {{< gloss "sidecar">}}sidecar{{< /gloss >}} también están disponibles para los proxies de waypoint.

|  Nombre  | Estado de la característica | Adjunto |
| --- | --- | --- |
| `WasmPlugin` † | Alfa | `targetRefs` |

† [Lee más sobre cómo extender los waypoints con plugins de WebAssembly](/es/docs/ambient/usage/extend-waypoint-wasm/).

Las configuraciones de extensión se consideran políticas según la definición de la API de Gateway.

## Alcance de rutas o políticas

Una ruta o política puede tener un alcance para aplicarse a todo el tráfico que atraviesa un proxy de waypoint, o solo a servicios específicos.

### Adjuntar a todo el proxy de waypoint

Para adjuntar una ruta o una política a todo el waypoint, de modo que se aplique a todo el tráfico inscrito para usarlo, establece `Gateway` como el valor de `parentRefs` o `targetRefs`, según el tipo.

Para limitar una política `AuthorizationPolicy` para que se aplique al waypoint llamado `default` para el namespace `default`:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: view-only
  namespace: default
spec:
  targetRefs:
  - kind: Gateway
    group: gateway.networking.k8s.io
    name: default
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["default", "istio-system"]
    to:
    - operation:
        methods: ["GET"]
{{< /text >}}

### Adjuntar a un servicio específico

También puedes adjuntar una ruta a uno o más servicios específicos dentro del waypoint. Establece `Service` como el valor de `parentRefs` o `targetRefs`, según corresponda.

Para aplicar la `HTTPRoute` de `reviews` al servicio `reviews` en el namespace `default`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: default
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v1
      port: 9080
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
{{< /text >}}
