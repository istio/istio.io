---
title: Mejores prácticas de seguridad
description: Mejores prácticas para proteger aplicaciones con Istio.
force_inline_toc: true
weight: 30
owner: istio/wg-security-maintainers
test: n/a
---

Las funcionalidades de seguridad de Istio proporcionan una identidad sólida, políticas potentes, cifrado TLS transparente y herramientas de autenticación, autorización y auditoría (AAA) para proteger tus servicios y datos.
Sin embargo, para aprovechar al máximo estas funcionalidades de forma segura, es importante seguir las mejores prácticas. Se recomienda revisar la [descripción general de seguridad](/es/docs/concepts/security/) antes de continuar.

## TLS mutuo

Istio cifrará [automáticamente](/es/docs/ops/configuration/traffic-management/tls-configuration/#auto-mtls) el tráfico con [TLS mutuo (mTLS)](/es/docs/concepts/security/#mutual-tls-authentication) siempre que sea posible.
Sin embargo, por defecto los proxies se configuran en [modo permisivo](/es/docs/concepts/security/#permissive-mode), lo que significa que aceptan tanto tráfico mTLS como tráfico en texto plano.

Aunque esto es necesario para la adopción gradual o para permitir el tráfico de clientes sin un sidecar de Istio, también debilita la postura de seguridad.
Se recomienda [migrar al modo estricto](/es/docs/tasks/security/authentication/mtls-migration/) cuando sea posible, para forzar el uso de mTLS.

Sin embargo, mTLS por sí solo no siempre basta para proteger completamente el tráfico, ya que solo proporciona autenticación, no autorización.
Esto significa que cualquiera que tenga un certificado válido puede seguir accediendo a un servicio.

Para restringir por completo el tráfico, se recomienda configurar [políticas de autorización](/es/docs/tasks/security/authorization/).
Estas permiten crear políticas granulares para permitir o denegar el tráfico. Por ejemplo, puedes permitir que solo las solicitudes del namespace `app` accedan al servicio `hello-world`.

## Políticas de autorización {#authorization-policies}

La [autorización](/es/docs/concepts/security/#authorization) de Istio desempeña un papel fundamental en la seguridad de Istio.
Configurar las políticas de autorización correctas para proteger mejor tus clústeres requiere esfuerzo.
Es importante entender las implicaciones de estas configuraciones, ya que Istio no puede determinar la autorización adecuada para todos los usuarios.
Sigue esta sección en su totalidad.

### Patrones de políticas de autorización más seguros {#safer-authorization-policy-patterns}

#### Usa patrones de denegación por defecto {#use-default-deny-patterns}

Te recomendamos definir tus políticas de autorización de Istio siguiendo el patrón de denegación por defecto para mejorar la postura de seguridad de tu clúster.
El patrón de autorización de denegación por defecto significa que tu sistema deniega todas las solicitudes por defecto y que tú defines las condiciones en las que se permiten las solicitudes.
Si se te pasa alguna condición, el tráfico se denegará de forma inesperada, en lugar de permitirse de forma inesperada.
Lo segundo suele constituir un incidente de seguridad, mientras que lo primero puede provocar una mala experiencia de usuario, una interrupción del servicio o el incumplimiento de tu SLO/SLA.

Por ejemplo, en la [tarea de autorización para tráfico HTTP](/es/docs/tasks/security/authorization/authz-http/),
la política de autorización llamada `allow-nothing` garantiza que todo el tráfico se deniegue por defecto.
A partir de ahí, otras políticas de autorización permiten el tráfico en función de condiciones específicas.

#### Patrón de denegación por defecto con waypoints

El nuevo modo de data plane ambient de Istio introdujo una nueva arquitectura de data plane dividida.
En esta arquitectura, el waypoint proxy se configura con la Gateway API de Kubernetes, que usa una vinculación más explícita a los gateways mediante `parentRef` y `targetRef`.
Como los waypoints se ajustan más a los principios de la Gateway API de Kubernetes, el patrón de denegación por defecto se habilita de una forma ligeramente distinta cuando la política se aplica a waypoints.
A partir de Istio 1.25, puedes vincular recursos `AuthorizationPolicy` a la `GatewayClass` `istio-waypoint`.
Al vincular una `AuthorizationPolicy` a la `GatewayClass`, puedes configurar con una política por defecto todos los gateways que implementan esa `GatewayClass`.
Es importante tener en cuenta que `GatewayClass` es un recurso con alcance de clúster, y vincularle políticas con alcance de namespace requiere especial cuidado.
Istio requiere que las políticas vinculadas a una `GatewayClass` residan en el namespace raíz, normalmente `istio-system`.

Para los waypoints, la política allow-nothing estándar sería:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-nothing-istio-waypoint
  namespace: istio-system
spec:
  targetRefs:
  - group: gateway.networking.k8s.io
    kind: GatewayClass
    name: istio-waypoint
{{< /text >}}

{{< tip >}}
Cuando uses el patrón de denegación por defecto con waypoints, la política vinculada a la `GatewayClass` `istio-waypoint` debe usarse además de la política de denegación por defecto "clásica". ztunnel aplica la política de denegación por defecto "clásica" a los workloads de tu mesh, y esta sigue aportando un valor significativo.
{{< /tip >}}

#### Usa los patrones `ALLOW-with-positive-matching` y `DENY-with-negative-match`

Usa los patrones `ALLOW-with-positive-matching` o `DENY-with-negative-matching` siempre que sea posible. Estos patrones de políticas
de autorización son más seguros porque, en caso de discrepancia de la política, el peor resultado es un rechazo 403 inesperado en lugar de
que se eluda la política de autorización.

El patrón `ALLOW-with-positive-matching` consiste en usar la acción `ALLOW` solo con campos de coincidencia **positiva** (p. ej., `paths`, `values`)
y no usar ninguno de los campos de coincidencia **negativa** (p. ej., `notPaths`, `notValues`).

El patrón `DENY-with-negative-matching` consiste en usar la acción `DENY` solo con campos de coincidencia **negativa** (p. ej., `notPaths`, `notValues`)
y no usar ninguno de los campos de coincidencia **positiva** (p. ej., `paths`, `values`).

Por ejemplo, la siguiente política de autorización usa el patrón `ALLOW-with-positive-matching` para permitir las solicitudes a la ruta `/public`:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: foo
spec:
  action: ALLOW
  rules:
  - to:
    - operation:
        paths: ["/public"]
{{< /text >}}

La política anterior indica explícitamente la ruta permitida (`/public`). Esto significa que la ruta de la solicitud debe ser exactamente igual a
`/public` para que se permita la solicitud. Cualquier otra solicitud se rechazará por defecto, lo que elimina el riesgo
de que un comportamiento de normalización desconocido haga que se eluda la política.

El siguiente es un ejemplo que usa el patrón `DENY-with-negative-matching` para conseguir el mismo resultado:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: foo
spec:
  action: DENY
  rules:
  - to:
    - operation:
        notPaths: ["/public"]
{{< /text >}}

### Entiende la normalización de rutas en las políticas de autorización {#understand-path-normalization-in-authorization-policy}

El punto de aplicación de las políticas de autorización es el proxy Envoy, en lugar del punto habitual de acceso a los recursos en la aplicación de backend. Se produce una discrepancia de la política cuando el proxy Envoy y la aplicación de backend interpretan la solicitud
de forma diferente.

Una discrepancia puede provocar un rechazo inesperado o que se eluda la política. Esto último suele ser un incidente de seguridad que hay que
corregir de inmediato, y también es la razón por la que necesitamos la normalización de rutas en las políticas de autorización.

Por ejemplo, considera una política de autorización que rechaza las solicitudes con la ruta `/data/secret`. Una solicitud con la ruta `/data//secret`
no se rechazará porque, debido a la barra `/` adicional en la ruta, no coincide con la ruta definida en la política de autorización.

La solicitud pasa y, después, la aplicación de backend devuelve la misma respuesta que devuelve para la ruta `/data/secret`,
porque la aplicación de backend normaliza la ruta `/data//secret` a `/data/secret`, ya que considera que las dos barras
`//` equivalen a una sola barra `/`.

En este ejemplo, el punto de aplicación de la política (el proxy Envoy) interpretaba la ruta de forma distinta al punto de acceso
a los recursos (la aplicación de backend). Esa diferencia de interpretación provocó la discrepancia y, en consecuencia, que se eludiera la política de autorización.

Esto se convierte en un problema complicado debido a los siguientes factores:

* La falta de un estándar claro para la normalización.

* Los backends y frameworks de distintas capas tienen su propia normalización especial.

* Las aplicaciones pueden incluso tener normalizaciones arbitrarias para sus propios casos de uso.

Las políticas de autorización de Istio incluyen soporte integrado para varias opciones básicas de normalización que te ayudan a abordar mejor
el problema:

* Consulta [Guía para configurar la opción de normalización de rutas](/es/docs/ops/best-practices/security/#guideline-on-configuring-the-path-normalization-option)
  para saber qué opciones de normalización te conviene usar.

* Consulta [Personaliza tu sistema para la normalización de rutas](/es/docs/ops/best-practices/security/#customize-your-system-on-path-normalization) para
  conocer el detalle de cada opción de normalización.

* Consulta [Mitigación para normalizaciones no admitidas](/es/docs/ops/best-practices/security/#mitigation-for-unsupported-normalization) para ver
  soluciones alternativas en caso de que necesites alguna opción de normalización no admitida.

### Guía para configurar la opción de normalización de rutas {#guideline-on-configuring-the-path-normalization-option}

#### Caso 1: No necesitas normalización en absoluto

Antes de entrar en los detalles de configuración de la normalización, primero debes asegurarte de que la necesitas.

No necesitas normalización si no usas políticas de autorización o si tus políticas de autorización no
usan ningún campo `path`.

Puede que no necesites normalización si todas tus políticas de autorización siguen el [patrón de autorización más seguro](/es/docs/ops/best-practices/security/#safer-authorization-policy-patterns),
que, en el peor de los casos, provoca un rechazo inesperado en lugar de que se eluda la política.

#### Caso 2: Necesitas normalización, pero no sabes qué opción de normalización usar

Necesitas normalización, pero no sabes qué opción usar. La elección más segura es la opción de normalización más estricta,
que proporciona el máximo nivel de normalización en la política de autorización.

Esto suele ocurrir porque, en sistemas complejos de varias capas, es prácticamente imposible averiguar
qué normalización se aplica realmente a una solicitud más allá del punto de aplicación.

Puedes usar una opción de normalización menos estricta si ya cumple tus requisitos y estás seguro de sus implicaciones.

Con cualquiera de las dos opciones, asegúrate de escribir pruebas tanto positivas como negativas específicas para tus requisitos, para verificar que la
normalización funciona como se espera. Las pruebas son útiles para detectar posibles problemas de elusión causados por una interpretación errónea
o un conocimiento incompleto de la normalización que se aplica a tu solicitud.

Consulta [Personaliza tu sistema para la normalización de rutas](/es/docs/ops/best-practices/security/#customize-your-system-on-path-normalization)
para obtener más detalles sobre cómo configurar la opción de normalización.

#### Caso 3: Necesitas una opción de normalización no admitida

Si necesitas una opción de normalización concreta que Istio todavía no admite, sigue
[Mitigación para normalizaciones no admitidas](/es/docs/ops/best-practices/security/#mitigation-for-unsupported-normalization)
para obtener soporte de normalización personalizada, o crea una solicitud de funcionalidad para la comunidad de Istio.

### Personaliza tu sistema para la normalización de rutas {#customize-your-system-on-path-normalization}

Las políticas de autorización de Istio pueden basarse en las rutas URL de la solicitud HTTP.
La [normalización de rutas (también llamada normalización de URI)](https://en.wikipedia.org/wiki/URI_normalization) modifica y estandariza las rutas de las solicitudes entrantes,
de modo que las rutas normalizadas se puedan procesar de forma estándar.
Rutas sintácticamente distintas pueden ser equivalentes después de la normalización de rutas.

Istio admite los siguientes esquemas de normalización en las rutas de las solicitudes,
antes de evaluarlas con las políticas de autorización y de enrutar las solicitudes:

| Opción | Descripción | Ejemplo |
| --- | --- | --- |
| `NONE` | No se realiza ninguna normalización. Todo lo que recibe Envoy se reenvía exactamente tal cual a cualquier servicio de backend. | `../%2Fa../b` se evalúa con las políticas de autorización y se envía a tu servicio. |
| `BASE` | Es la opción que se usa actualmente en la instalación *por defecto* de Istio. Aplica la opción [`normalize_path`](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto#envoy-v3-api-field-extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-normalize-path) en los proxies Envoy, que sigue el [RFC 3986](https://tools.ietf.org/html/rfc3986) con una normalización adicional que convierte las barras invertidas en barras. | `/a/../b` se normaliza a `/b`. `\da` se normaliza a `/da`. |
| `MERGE_SLASHES` | Las barras se fusionan después de la normalización _BASE_. | `/a//b` se normaliza a `/a/b`. |
| `DECODE_AND_MERGE_SLASHES` | La configuración más estricta cuando permites todo el tráfico por defecto. Se recomienda esta configuración, con la salvedad de que tendrás que probar a fondo las rutas de tus políticas de autorización. Los caracteres de barra y barra invertida [codificados con porcentaje](https://tools.ietf.org/html/rfc3986#section-2.1) (`%2F`, `%2f`, `%5C` y `%5c`) se decodifican a `/` o `\`, antes de la normalización `MERGE_SLASHES`. | `/a%2fb` se normaliza a `/a/b`. |

{{< tip >}}
La configuración se especifica mediante el campo [`pathNormalization`](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ProxyPathNormalization)
de la [configuración de la mesh](/es/docs/reference/config/istio.mesh.v1alpha1/).
{{< /tip >}}

Para recalcarlo, los algoritmos de normalización se aplican en el siguiente orden:

1. Decodificación de porcentaje de `%2F`, `%2f`, `%5C` y `%5c`.
1. La normalización del [RFC 3986](https://tools.ietf.org/html/rfc3986) y las demás normalizaciones que implementa la opción [`normalize_path`](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto#envoy-v3-api-field-extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-normalize-path) de Envoy.
1. Fusión de barras

{{< warning >}}
Aunque estas opciones de normalización representan recomendaciones de los estándares HTTP y prácticas habituales del sector,
las aplicaciones pueden interpretar una URL de la forma que quieran. Cuando uses políticas de denegación, asegúrate de entender cómo se comporta tu aplicación.
{{< /warning >}}

Para ver la lista completa de normalizaciones admitidas, consulta [normalización de políticas de autorización](/es/docs/reference/config/security/normalization/).

#### Ejemplos de configuración

Asegurarte de que Envoy normaliza las rutas de las solicitudes según lo que esperan tus servicios de backend es fundamental para la seguridad de tu sistema.
Puedes usar los siguientes ejemplos como referencia para configurar tu sistema.
Las rutas URL normalizadas, o las rutas URL originales si se selecciona _NONE_:

1. Se usarán para la comprobación con las políticas de autorización
1. Se reenviarán a la aplicación de backend

| Tu aplicación... | Elige... |
| --- | --- |
| Depende del proxy para la normalización | `BASE`, `MERGE_SLASHES` o `DECODE_AND_MERGE_SLASHES` |
| Normaliza las rutas de las solicitudes según el [RFC 3986](https://tools.ietf.org/html/rfc3986) y no fusiona barras | `BASE` |
| Normaliza las rutas de las solicitudes según el [RFC 3986](https://tools.ietf.org/html/rfc3986) y fusiona barras, pero no decodifica las barras [codificadas con porcentaje](https://tools.ietf.org/html/rfc3986#section-2.1) | `MERGE_SLASHES` |
| Normaliza las rutas de las solicitudes según el [RFC 3986](https://tools.ietf.org/html/rfc3986), decodifica las barras [codificadas con porcentaje](https://tools.ietf.org/html/rfc3986#section-2.1) y fusiona barras | `DECODE_AND_MERGE_SLASHES` |
| Procesa las rutas de las solicitudes de una forma incompatible con el [RFC 3986](https://tools.ietf.org/html/rfc3986) | `NONE` |

#### Cómo configurarlo

Puedes usar `istioctl` para actualizar la [configuración de la mesh](/es/docs/reference/config/istio.mesh.v1alpha1/):

{{< text bash >}}
$ istioctl upgrade --set meshConfig.pathNormalization.normalization=DECODE_AND_MERGE_SLASHES
{{< /text >}}

o modificar tu archivo de sobrescrituras del operator

{{< text bash >}}
$ cat <<EOF > iop.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    pathNormalization:
      normalization: DECODE_AND_MERGE_SLASHES
EOF
$ istioctl install -f iop.yaml
{{< /text >}}

Como alternativa, si quieres editar directamente la configuración de la mesh,
puedes añadir [`pathNormalization`](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ProxyPathNormalization)
a la [configuración de la mesh](/es/docs/reference/config/istio.mesh.v1alpha1/), que es el configmap `istio-<REVISION_ID>` del namespace `istio-system`.
Por ejemplo, si eliges la opción `DECODE_AND_MERGE_SLASHES`, modifica la configuración de la mesh de la siguiente forma:

{{< text yaml >}}
apiVersion: v1
  data:
    mesh: |-
      ...
      pathNormalization:
        normalization: DECODE_AND_MERGE_SLASHES
      ...
{{< /text >}}

### Mitigación para normalizaciones no admitidas {#mitigation-for-unsupported-normalization}

Esta sección describe varias mitigaciones para normalizaciones no admitidas. Pueden ser útiles cuando necesitas una
normalización concreta que Istio no admite.

Asegúrate de entender bien la mitigación y úsala con cuidado, ya que algunas mitigaciones dependen de elementos que
quedan fuera del alcance de Istio y que Istio tampoco admite.

#### Lógica de normalización personalizada

Puedes aplicar una lógica de normalización personalizada con el filtro WASM o Lua. Se recomienda usar el filtro WASM porque
tiene soporte oficial y también lo usa Istio. Puedes usar el filtro Lua para una DEMO rápida de prueba de concepto, pero
no recomendamos usar el filtro Lua en producción porque Istio no le da soporte.

##### Ejemplo de normalización personalizada (normalización de mayúsculas y minúsculas)

En algunos entornos, puede ser útil que las rutas de las políticas de autorización se comparen sin distinguir entre mayúsculas y minúsculas.
Por ejemplo, tratar `https://myurl/get` y `https://myurl/GeT` como equivalentes.

En esos casos, se puede usar el `EnvoyFilter` que se muestra a continuación para insertar un filtro Lua que normalice la ruta a minúsculas.
Este filtro cambiará tanto la ruta que se usa para la comparación como la ruta que se presenta a la aplicación.

{{< text syntax=yaml snip_id=ingress_case_insensitive_envoy_filter >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: ingress-case-insensitive
  namespace: istio-system
spec:
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: GATEWAY
      listener:
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
    patch:
      operation: INSERT_FIRST
      value:
        name: envoy.lua
        typed_config:
            "@type": "type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua"
            inlineCode: |
              function envoy_on_request(request_handle)
                local path = request_handle:headers():get(":path")
                request_handle:headers():replace(":path", string.lower(path))
              end
{{< /text >}}

#### Escribir políticas de coincidencia de hosts {#writing-host-match-policies}

Istio genera nombres de host tanto para el propio nombre de host como para todos los puertos coincidentes. Por ejemplo, un virtual service o un Gateway
para el host `example.com` genera una configuración que coincide con `example.com` y `example.com:*`. Sin embargo, las políticas de autorización
de coincidencia exacta solo coinciden con la cadena exacta indicada en los campos `hosts` o `notHosts`.

Las [reglas de las políticas de autorización](/es/docs/reference/config/security/authorization-policy/#Rule) que comparan hosts deben escribirse con
coincidencias de prefijo en lugar de coincidencias exactas. Por ejemplo, para una `AuthorizationPolicy` que coincida con la configuración de Envoy generada
para el nombre de host `example.com`, usarías `hosts: ["example.com", "example.com:*"]`, como se muestra en la siguiente `AuthorizationPolicy`.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ingress-host
  namespace: istio-system
spec:
  selector:
    matchLabels:
      app: istio-ingressgateway
  action: DENY
  rules:
  - to:
    - operation:
        hosts: ["example.com", "example.com:*"]
{{< /text >}}

Además, en general, los campos `host` y `notHosts` solo deben usarse en el gateway para el tráfico externo que entra en la mesh,
y no en los sidecars para el tráfico dentro de la mesh. Esto se debe a que el sidecar del lado del servidor (donde se aplica la política de autorización)
no usa el encabezado `Host` al redirigir la solicitud a la aplicación. Esto hace que `host` y `notHost` no tengan sentido
en el sidecar, porque un cliente podría llegar a la aplicación usando una dirección IP explícita y un encabezado `Host` arbitrario en lugar del
nombre del servicio.

Si por algún motivo realmente necesitas aplicar control de acceso basado en el encabezado `Host` en los sidecars, sigue los [patrones de denegación por defecto](/es/docs/ops/best-practices/security/#use-default-deny-patterns),
que rechazarían la solicitud si el cliente usa un encabezado `Host` arbitrario.

#### Web Application Firewall (WAF) especializado

Muchos productos especializados de Web Application Firewall (WAF) ofrecen opciones de normalización adicionales. Se pueden desplegar
delante del ingress gateway de Istio para normalizar las solicitudes que entran en la mesh. Así, la política de autorización se aplicará
a las solicitudes normalizadas. Consulta la documentación de tu producto WAF para configurar las opciones de normalización.

#### Solicitud de funcionalidad a Istio

Si crees que Istio debería admitir oficialmente una normalización concreta, puedes seguir la página de [notificación de vulnerabilidades](/es/docs/releases/security-vulnerabilities/#reporting-a-vulnerability)
para enviar al Istio Product Security Work Group una solicitud de funcionalidad sobre esa normalización para una evaluación inicial.

No abras ningún issue público sin ponerte antes en contacto con el Istio Product Security Work Group, porque el
issue podría considerarse una vulnerabilidad de seguridad que debe corregirse en privado.

Si el Istio Product Security Work Group determina que la solicitud de funcionalidad no es una vulnerabilidad de seguridad, se abrirá
un issue público para seguir debatiendo la solicitud de funcionalidad.

### Limitaciones conocidas

Esta sección enumera las limitaciones conocidas de las políticas de autorización.

#### No se admiten los protocolos TCP server-first

En los protocolos TCP server-first, la aplicación servidora envía los primeros bytes justo después de aceptar la conexión TCP,
antes de recibir ningún dato del cliente.

Actualmente, las políticas de autorización solo admiten aplicar control de acceso al tráfico entrante, no al tráfico saliente.

Tampoco admiten protocolos TCP server-first, porque la aplicación servidora envía los primeros bytes incluso antes
de recibir ningún dato del cliente. En este caso, los primeros bytes iniciales que envía el servidor se devuelven al cliente
directamente, sin pasar por la comprobación de control de acceso de la política de autorización.

No debes usar la política de autorización si los primeros bytes que envían los protocolos TCP server-first incluyen datos
sensibles que deban protegerse con una autorización adecuada.

Aun así, puedes usar la política de autorización en este caso si los primeros bytes no incluyen datos sensibles; por ejemplo,
si los primeros bytes se usan para negociar la conexión con datos accesibles públicamente para cualquier cliente. La política
de autorización funcionará con normalidad para las solicitudes posteriores que envíe el cliente después de los primeros bytes.

## Entiende las limitaciones de la captura de tráfico {#understand-traffic-capture-limitations}

El sidecar de Istio funciona capturando tanto el tráfico entrante como el saliente y dirigiéndolo a través del sidecar proxy.

Sin embargo, no se captura *todo* el tráfico:

* La redirección solo gestiona tráfico basado en TCP. Los paquetes UDP o ICMP no se capturan ni se modifican.
* La captura de entrada está deshabilitada en muchos [puertos que usa el sidecar](/es/docs/ops/deployment/application-requirements/#ports-used-by-istio), así como en el puerto 22. Esta lista se puede ampliar con opciones como `traffic.sidecar.istio.io/excludeInboundPorts`.
* La captura de salida también se puede reducir de forma similar con ajustes como `traffic.sidecar.istio.io/excludeOutboundPorts` o por otros medios.

En general, el límite de seguridad entre una aplicación y su sidecar proxy es mínimo. La configuración del sidecar se permite por pod, y ambos se ejecutan en el mismo namespace de red/procesos.
Por ello, la aplicación puede tener la capacidad de eliminar las reglas de redirección y de eliminar, modificar, terminar o sustituir el sidecar proxy.
Esto permite que un pod eluda intencionadamente su sidecar para el tráfico saliente o permita intencionadamente que el tráfico entrante eluda su sidecar.

Por tanto, no es seguro confiar en que Istio capture todo el tráfico de forma incondicional.
En cambio, el límite de seguridad consiste en que un cliente no puede eludir el sidecar de *otro* pod.

Por ejemplo, si ejecuto la aplicación `reviews` en el puerto `9080`, puedo suponer que el sidecar proxy capturará todo el tráfico de la aplicación `productpage`,
donde pueden aplicarse las políticas de autenticación y autorización de Istio.

### Defensa en profundidad con `NetworkPolicy` {#defense-in-depth-with-networkpolicy}

Para proteger aún más el tráfico, las políticas de Istio se pueden combinar en capas con las [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) de Kubernetes.
Esto permite una sólida estrategia de [defensa en profundidad](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) que puedes usar para reforzar aún más la seguridad de tu mesh.

Por ejemplo, puedes optar por permitir solo el tráfico al puerto `9080` de nuestra aplicación `reviews`.
Si un pod se ve comprometido o hay una vulnerabilidad de seguridad en el clúster, esto puede limitar o detener el avance de un atacante.

Según la implementación concreta, puede que los cambios en la política de red no afecten a las conexiones existentes en los proxies de Istio.
Puede que tengas que reiniciar los proxies de Istio después de aplicar la política para que se cierren las conexiones existentes y
las nuevas conexiones queden sujetas a la nueva política.

### Proteger el tráfico de salida {#securing-egress-traffic}

Un error de concepto habitual es pensar que opciones como [`outboundTrafficPolicy: REGISTRY_ONLY`](/es/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services) actúan como una política de seguridad que impide todo acceso a servicios no declarados.
Sin embargo, como se ha mencionado antes, no es un límite de seguridad sólido y debe considerarse un mecanismo de mejor esfuerzo (best-effort).

Aunque esto es útil para evitar dependencias accidentales, si quieres proteger el tráfico de salida y forzar que todo el tráfico saliente pase por un proxy, debes basarte en un [egress gateway](/es/docs/tasks/traffic-management/egress/egress-gateway/).
En combinación con una [Network Policy](/es/docs/tasks/traffic-management/egress/egress-gateway/#apply-kubernetes-network-policies), puedes forzar que todo el tráfico, o un subconjunto de él, pase por el egress gateway.
Esto garantiza que, aunque un cliente eluda su sidecar de forma accidental o maliciosa, la solicitud se bloqueará.

## Configura la verificación de TLS en la destination rule cuando uses originación de TLS {#configure-tls-verification-in-destination-rule-when-using-tls-origination}

Istio ofrece la posibilidad de [originar TLS](/es/docs/tasks/traffic-management/egress/egress-tls-origination/) desde un sidecar proxy o un gateway.
Esto permite que las aplicaciones que envían tráfico HTTP en texto plano se "actualicen" de forma transparente a HTTPS.

Debes tener cuidado al configurar el ajuste `tls` de la `DestinationRule` para especificar los campos `caCertificates`, `subjectAltNames` y `sni`.
El campo `caCertificate` se puede establecer automáticamente con el certificado de CA del almacén de certificados del sistema si habilitas la variable de entorno `VERIFY_CERTIFICATE_AT_CLIENT=true` en Istiod.
Si solo quieres que el certificado de CA del sistema operativo se use automáticamente para determinados hosts, configura la variable de entorno `VERIFY_CERTIFICATE_AT_CLIENT=false` en Istiod y establece `caCertificates` en `system` en las `DestinationRule` correspondientes.
Si especificas `caCertificates` en una `DestinationRule`, ese valor tendrá prioridad y no se usará el certificado de CA del sistema operativo.
Por defecto, el tráfico de salida no envía SNI durante el handshake TLS.
Debes configurar el SNI en la `DestinationRule` para garantizar que el host gestione correctamente la solicitud.

{{< warning >}}
Para verificar el certificado del servidor, es importante configurar tanto `caCertificates` como `subjectAltNames`.

No basta con verificar frente a una CA el certificado que presenta el servidor, ya que también deben validarse los Subject Alternative Names.

Si `VERIFY_CERTIFICATE_AT_CLIENT` está configurada, pero `subjectAltNames` no lo está, no estás verificando todas las credenciales.

Si no se usa ningún certificado de CA, `subjectAltNames` no se usará, independientemente de que esté configurado o no.
{{< /warning >}}

Por ejemplo:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: google-tls
spec:
  host: google.com
  trafficPolicy:
    tls:
      mode: SIMPLE
      caCertificates: /etc/ssl/certs/ca-certificates.crt
      subjectAltNames:
      - "google.com"
      sni: "google.com"
{{< /text >}}

## Gateways {#gateways}

Cuando ejecutas un [gateway](/es/docs/tasks/traffic-management/ingress/) de Istio, intervienen varios recursos:

* Los recursos `Gateway`, que controlan los puertos y los ajustes de TLS del gateway.
* Los recursos `VirtualService`, que controlan la lógica de enrutamiento. Se asocian a los recursos `Gateway` mediante una referencia directa en el campo `gateways` y un acuerdo mutuo en el campo `hosts` del `Gateway` y del `VirtualService`.

### Restringe los privilegios de creación de `Gateway` {#restrict-gateway-creation-privileges}

Se recomienda restringir la creación de recursos Gateway a administradores del clúster de confianza. Esto se puede conseguir con [políticas RBAC de Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) o con herramientas como [Open Policy Agent](https://www.openpolicyagent.org/).

### Evita configuraciones de `hosts` demasiado amplias {#avoid-overly-broad-hosts-configurations}

Siempre que sea posible, evita configuraciones de `hosts` demasiado amplias en el `Gateway`.

Por ejemplo, esta configuración permitirá que cualquier `VirtualService` se vincule al `Gateway`, lo que podría exponer dominios inesperados:

{{< text yaml >}}
servers:
- port:
    number: 80
    name: http
    protocol: HTTP
  hosts:
  - "*"
{{< /text >}}

Esto debería restringirse para permitir solo dominios concretos o namespaces concretos:

{{< text yaml >}}
servers:
- port:
    number: 80
    name: http
    protocol: HTTP
  hosts:
  - "foo.example.com" # Allow only VirtualServices that are for foo.example.com
  - "default/bar.example.com" # Allow only VirtualServices in the default namespace that are for bar.example.com
  - "route-namespace/*" # Allow only VirtualServices in the route-namespace namespace for any host
{{< /text >}}

### Aísla los servicios sensibles

Puede que quieras aplicar un aislamiento físico más estricto a los servicios sensibles. Por ejemplo, puede que quieras ejecutar una
[instancia de gateway dedicada](/es/docs/setup/install/istioctl/#configure-gateways) para un `payments.example.com` sensible, mientras usas una única
instancia de gateway compartida para dominios menos sensibles como `blog.example.com` y `store.example.com`.
Esto puede ofrecer una defensa en profundidad más sólida y ayudar a cumplir determinadas directrices de cumplimiento normativo.

### Credenciales de gateway en meshes multiclúster

En una mesh multiclúster, un gateway que se ejecuta en un clúster remoto puede usar un secreto `credentialName` almacenado en el clúster de configuración.
Si el secreto no se encuentra en el propio clúster del gateway, istiod recurre al clúster de configuración. El acceso se autoriza
mediante el RBAC del clúster en el que se ejecuta el gateway.

Esto se deriva del concepto de {{< gloss "namespace sameness" >}}namespace sameness{{< /gloss >}}: se espera que un namespace
pertenezca al mismo equipo en todos los clústeres. Mantén coherente el RBAC de los secretos entre clústeres para un mismo namespace
y evita compartir un nombre de namespace entre clústeres cuando pertenezca a equipos distintos.

### Deshabilita explícitamente todos los hosts HTTP sensibles cuando la coincidencia de hosts SNI es relajada

Es razonable usar varios recursos `Gateway` para definir TLS mutuo y TLS simple en distintos hosts.
Por ejemplo, usar TLS mutuo para el host SNI `admin.example.com` y TLS simple para el host SNI `*.example.com`.

{{< text yaml >}}
kind: Gateway
metadata:
  name: guestgateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "*.example.com"
    tls:
      mode: SIMPLE
---
kind: Gateway
metadata:
  name: admingateway
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - admin.example.com
    tls:
      mode: MUTUAL
{{< /text >}}

Si lo anterior es necesario, se recomienda encarecidamente deshabilitar explícitamente el host HTTP `admin.example.com` en el `VirtualService` que se vincula a `*.example.com`. El motivo es que actualmente el [proxy Envoy subyacente no requiere](https://github.com/envoyproxy/envoy/issues/6767) que el encabezado `Host` de HTTP/1 ni el pseudoencabezado `:authority` de HTTP/2 cumplan las restricciones de SNI, por lo que un atacante puede reutilizar la conexión TLS establecida con el SNI de invitado para acceder al `VirtualService` de administración. El código de respuesta HTTP 421 está pensado para esta discrepancia entre `Host` y SNI y puede usarse para deshabilitar ese host.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: disable-sensitive
spec:
  hosts:
  - "admin.example.com"
  gateways:
  - guestgateway
  http:
  - match:
    - uri:
        prefix: /
    fault:
      abort:
        percentage:
          value: 100
        httpStatus: 421
    route:
    - destination:
        port:
          number: 8000
        host: dest.default.cluster.local
{{< /text >}}

## Detección de protocolo

Istio [determinará automáticamente el protocolo](/es/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection) del tráfico que ve.
Para evitar una detección errónea, accidental o intencionada, que puede provocar un comportamiento inesperado del tráfico, se recomienda [declarar explícitamente el protocolo](/es/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection) siempre que sea posible.

## CNI

Para capturar todo el tráfico de forma transparente, Istio se basa en reglas de `iptables` configuradas por el `initContainer` `istio-init`.
Esto añade el [requisito](/es/docs/ops/deployment/application-requirements/) de que las [capabilities](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container) `NET_ADMIN` y `NET_RAW` estén disponibles para el pod.

Para reducir los privilegios que se conceden a los pods, Istio ofrece un [plugin de CNI](/es/docs/setup/additional-setup/cni/) que elimina este requisito.

## Usa imágenes de Docker reforzadas

Las imágenes de Docker por defecto de Istio, incluidas las que ejecutan el control plane, el gateway y los sidecar proxies, se basan en `ubuntu`.
Esto proporciona varias herramientas como `bash` y `curl`, lo que aporta comodidad a costa de aumentar la superficie de ataque.

Istio también ofrece una imagen más pequeña basada en [imágenes distroless](/es/docs/ops/configuration/security/harden-docker-images/) que reduce las dependencias de la imagen.

{{< warning >}}
Las imágenes distroless son actualmente una funcionalidad alpha.
{{< /warning >}}

## Política de versiones y de seguridad

Para asegurarte de que tu clúster tiene los parches de seguridad más recientes para las vulnerabilidades conocidas, es importante mantenerte en la última versión de parche de Istio y asegurarte de que usas una [versión soportada](/es/docs/releases/supported-releases) que siga recibiendo parches de seguridad.

## Detecta configuraciones no válidas

Aunque Istio valida los recursos cuando se crean, estas comprobaciones no pueden detectar todos los problemas que impiden que la configuración se distribuya en la mesh.
Esto podría hacer que se aplique una política que se ignora de forma inesperada, con resultados inesperados.

* Ejecuta `istioctl analyze` antes o después de aplicar la configuración para asegurarte de que es válida.
* Monitorea el control plane para detectar configuraciones rechazadas. Se exponen mediante la métrica `pilot_total_xds_rejects`, además de en los registros.
* Prueba tu configuración para asegurarte de que da los resultados esperados.
  En una política de seguridad, es útil ejecutar pruebas positivas y negativas para asegurarte de que no restringes por accidente demasiado tráfico o demasiado poco.

## Evita las funcionalidades alpha y experimentales

A todas las funcionalidades y API de Istio se les asigna un [estado de funcionalidad](/es/docs/releases/feature-stages/), que define su estabilidad, su política de obsolescencia y su política de seguridad.

Como las funcionalidades alpha y experimentales no tienen garantías de seguridad tan sólidas, se recomienda evitarlas siempre que sea posible.
Es posible que los problemas de seguridad que se encuentren en estas funcionalidades no se corrijan de inmediato o que no sigan nuestro proceso estándar de [vulnerabilidades de seguridad](/es/docs/releases/security-vulnerabilities/).

Para determinar el estado de las funcionalidades que se usan en tu clúster, consulta la lista de [funcionalidades de Istio](/es/docs/releases/feature-stages/#istio-features).

<!-- En el futuro, deberíamos documentar el comando `istioctl` para comprobarlo cuando esté disponible. -->

## Restringe los puertos

Istio configura [diversos puertos](/es/docs/ops/deployment/application-requirements/#ports-used-by-istio) que se pueden restringir para mejorar la seguridad.

### Control plane {#control-plane}

Istiod expone varios puertos para depuración y monitoreo. Por defecto, los endpoints de depuración ahora requieren autenticación:

* El puerto `8080` expone la interfaz de depuración, que ofrece acceso de lectura a diversos detalles sobre el estado del clúster.
  Se puede deshabilitar estableciendo la variable de entorno `ENABLE_DEBUG_ON_HTTP=false` en Istiod. Advertencia: muchos comandos de `istioctl`
  dependen de esta interfaz y no funcionarán si está deshabilitada.
* El puerto `15010` expone el servicio XDS sobre gRPC en texto plano. Por defecto, los endpoints de depuración de XDS (`syncz`, `config_dump`) de este puerto requieren autenticación,
  lo que en la práctica bloquea el acceso en texto plano cuando está habilitada. Usa el puerto 15012 (TLS) para el acceso de depuración de XDS autenticado.
  El propio servicio XDS en texto plano se puede deshabilitar añadiendo el flag `--grpcAddr=""` al deployment de istiod.
  Nota: los servicios muy sensibles, como los servicios de firma y distribución de certificados, nunca se sirven en texto plano.
* El puerto `15012` expone el servicio XDS sobre gRPC con TLS/mTLS (recomendado para producción). Los endpoints de depuración de XDS están disponibles a través de este puerto
  con autenticación mTLS automática.
* El puerto `15014` expone endpoints de depuración (`/debug/syncz`, `/debug/registryz`, `/debug/config_dump`, etc.) sobre HTTP (texto plano).
  Por defecto, estos endpoints requieren autenticación mediante tokens de cuenta de servicio con la audiencia `istio-ca`.

La autenticación de los endpoints de depuración se controla con la variable de entorno `ENABLE_DEBUG_ENDPOINT_AUTH` (habilitada por defecto).
Cuando está habilitada, la autorización basada en namespaces restringe los namespaces que no son del sistema a endpoints concretos (`config_dump`, `ndsz`, `edsz`) y solo para proxies del mismo namespace.
Para deshabilitar la autenticación y restaurar el comportamiento heredado, establece `ENABLE_DEBUG_ENDPOINT_AUTH=false` en istiod.

Consulta la [Guía de integración](/es/docs/ops/integrations/integration-guide/debug-endpoints/) para obtener detalles sobre cómo acceder a los endpoints de depuración desde integraciones.

### Data plane

El proxy expone diversos puertos. Se exponen externamente el puerto `15090` (telemetría), el puerto `15021` (comprobación de estado) y el puerto `15020` (telemetría de Prometheus combinada del agente de Istio, Envoy y la aplicación).
El puerto `15000` proporciona endpoints de depuración y solo se expone en `localhost`.
Por tanto, las aplicaciones que se ejecutan en el mismo pod que el proxy tienen acceso; no hay límite de confianza entre el sidecar y la aplicación.

## Configura tokens de cuenta de servicio de terceros {#configure-third-party-service-account-tokens}

Para autenticarse con el control plane de Istio, el proxy de Istio usará un token de cuenta de servicio. Kubernetes admite dos formas de estos tokens:

* Tokens de terceros, que tienen una audiencia acotada y caducidad.
* Tokens de primera parte, que no caducan y se montan en todos los pods.

Como las propiedades del token de primera parte son menos seguras, Istio usará por defecto tokens de terceros. Sin embargo, esta funcionalidad no está habilitada en todas las plataformas de Kubernetes.

Si instalas con `istioctl`, la compatibilidad se detectará automáticamente. También se puede hacer manualmente, configurándolo con `--set values.global.jwtPolicy=third-party-jwt` o `--set values.global.jwtPolicy=first-party-jwt`.

Para determinar si tu clúster admite tokens de terceros, busca la API `TokenRequest`. Si no devuelve ninguna respuesta, la funcionalidad no se admite:

{{< text bash >}}
$ kubectl get --raw /api/v1 | jq '.resources[] | select(.name | index("serviceaccounts/token"))'
{
    "name": "serviceaccounts/token",
    "singularName": "",
    "namespaced": true,
    "group": "authentication.k8s.io",
    "version": "v1",
    "kind": "TokenRequest",
    "verbs": [
        "create"
    ]
}
{{< /text >}}

Aunque la mayoría de los proveedores de nube ya admiten esta funcionalidad, es posible que muchas herramientas de desarrollo local e instalaciones personalizadas no la admitan en versiones anteriores a Kubernetes 1.20. Para habilitar esta funcionalidad, consulta la [documentación de Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection).

## Configura un límite de conexiones downstream

Por defecto, Istio (y Envoy) no tienen límite en el número de conexiones downstream. Un actor malicioso puede aprovecharlo (consulta el [boletín de seguridad 2020-007](/news/security/istio-security-2020-007/)). Para evitarlo, debes configurar un límite de conexiones adecuado para tu entorno.

### Configura el valor de `global_downstream_max_connections`

Se puede proporcionar la siguiente configuración durante la instalación:

{{< text yaml >}}
meshConfig:
  defaultConfig:
    runtimeValues:
      "overload.global_downstream_max_connections": "100000"
{{< /text >}}
