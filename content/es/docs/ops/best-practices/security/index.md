---
title: Mejores Prácticas de Seguridad
description: Mejores prácticas para asegurar aplicaciones usando Istio.
force_inline_toc: true
weight: 30
owner: istio/wg-security-maintainers
test: n/a
---

Las características de seguridad de Istio proporcionan identidad fuerte, política poderosa, cifrado TLS transparente, y herramientas de autenticación, autorización y auditoría (AAA) para proteger tus servicios y datos.
Sin embargo, para aprovechar completamente estas características de manera segura, se debe tener cuidado de seguir las mejores prácticas. Se recomienda revisar la [Visión general de seguridad](/es/docs/concepts/security/) antes de proceder.

## Mutual TLS

Istio [automáticamente](/es/docs/ops/configuration/traffic-management/tls-configuration/#auto-mtls) cifrará el tráfico usando [Mutual TLS](/es/docs/concepts/security/#mutual-tls-authentication) siempre que sea posible.
Sin embargo, los proxies están configurados en [modo permisivo](/es/docs/concepts/security/#permissive-mode) por defecto, lo que significa que aceptarán tanto tráfico mutual TLS como texto plano.

Aunque esto es requerido para adopción incremental o para permitir tráfico de clientes sin un sidecar de Istio, también debilita la postura de seguridad.
Se recomienda [migrar al modo estricto](/es/docs/tasks/security/authentication/mtls-migration/) cuando sea posible, para hacer cumplir que se use mutual TLS.

Mutual TLS por sí solo no siempre es suficiente para asegurar completamente el tráfico, sin embargo, ya que proporciona solo autenticación, no autorización.
Esto significa que cualquiera con un certificado válido aún puede acceder a un servicio.

Para bloquear completamente el tráfico, se recomienda configurar [políticas de autorización](/es/docs/tasks/security/authorization/).
Estas permiten crear políticas de grano fino para permitir o denegar tráfico. Por ejemplo, puedes permitir solo solicitudes del namespace `app` para acceder al Service `hello-world`.

## Políticas de autorización

La [autorización](/es/docs/concepts/security/#authorization) de Istio juega un papel crítico en la seguridad de Istio.
Toma esfuerzo configurar las políticas de autorización correctas para proteger mejor tus clusters.
Es importante entender las implicaciones de estas configuraciones ya que Istio no puede determinar la autorización apropiada para todos los usuarios.
Por favor sigue esta sección en su totalidad.

### Patrones de Política de Autorización Más Seguros

#### Usar patrones de denegación por defecto

Recomendamos que definas tus políticas de autorización de Istio siguiendo el patrón de denegación por defecto para mejorar la postura de seguridad de tu cluster.
El patrón de autorización de denegación por defecto significa que tu sistema deniega todas las solicitudes por defecto, y defines las condiciones en las que se permiten las solicitudes.
En caso de que omitas algunas condiciones, el tráfico será denegado inesperadamente, en lugar de que el tráfico sea permitido inesperadamente.
Lo último típicamente siendo un incidente de seguridad mientras que lo primero puede resultar en una mala experiencia de usuario, una interrupción del servicio o no cumplirá con tu SLO/SLA.

Por ejemplo, en la [tarea de autorización para tráfico HTTP](/es/docs/tasks/security/authorization/authz-http/),
la política de autorización llamada `allow-nothing` se asegura de que todo el tráfico sea denegado por defecto.
Desde ahí, otras políticas de autorización permiten tráfico basado en condiciones específicas.

#### Patrón de denegación por defecto con waypoints

El nuevo modo de data plane ambient de Istio introdujo una nueva arquitectura de data plane dividida.
En esta arquitectura, el Proxy waypoint se configura usando Kubernetes Gateway API que usa vinculación más explícita a gateways usando `parentRef` y `targetRef`.
Porque los waypoints se adhieren más estrechamente a los principios de Kubernetes Gateway API, el patrón de denegación por defecto se habilita de manera ligeramente diferente cuando la política se aplica a waypoints.
Comenzando con Istio 1.25, puedes vincular recursos `AuthorizationPolicy` al `GatewayClass` `istio-waypoint`.
Al vincular `AuthorizationPolicy` al `GatewayClass`, puedes configurar todos los gateways que implementan ese `GatewayClass` con una política por defecto.
Es importante notar que `GatewayClass` es un recurso de alcance de cluster, y vincular políticas de alcance de namespace a él requiere cuidado especial.
Istio requiere que las políticas que están vinculadas a un `GatewayClass` residan en el namespace raíz, típicamente `istio-system`.

{{< tip >}}
Al usar el patrón de denegación por defecto con waypoints, la política vinculada al `GatewayClass` `istio-waypoint` debería usarse además de la política "clásica" de denegación por defecto. La política "clásica" de denegación por defecto será aplicada por ztunnel contra los workloads en tu meshy aún proporciona valor significativo.
{{< /tip >}}

#### Usar patrones `ALLOW-with-positive-matching` y `DENY-with-negative-match`

Usa los patrones `ALLOW-with-positive-matching` o `DENY-with-negative-matching` siempre que sea posible. Estos patrones de política de autorización
son más seguros porque el peor resultado en el caso de un error de coincidencia de política es un rechazo 403 inesperado en lugar de
un bypass de la política de autorización.

El patrón `ALLOW-with-positive-matching` es usar la acción `ALLOW` solo con campos de coincidencia **positivos** (ej. `paths`, `values`)
y no usar ninguno de los campos de coincidencia **negativos** (ej. `notPaths`, `notValues`).

El patrón `DENY-with-negative-matching` es usar la acción `DENY` solo con campos de coincidencia **negativos** (ej. `notPaths`, `notValues`)
y no usar ninguno de los campos de coincidencia **positivos** (ej. `paths`, `values`).

Por ejemplo, la política de autorización a continuación usa el patrón `ALLOW-with-positive-matching` para permitir solicitudes a la ruta `/public`:

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

La política anterior lista explícitamente la ruta permitida (`/public`). Esto significa que la ruta de la solicitud debe ser exactamente la misma que
`/public` para permitir la solicitud. Cualquier otra solicitud será rechazada por defecto eliminando el riesgo
de que el comportamiento de normalización desconocido cause un bypass de política.

El siguiente es un ejemplo usando el patrón `DENY-with-negative-matching` para lograr el mismo resultado:

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

### Entender la normalización de rutas en la política de autorización

El punto de aplicación para las políticas de autorización es el Proxy Envoy en lugar del punto de acceso a recursos usual en la aplicación backend. Un error de coincidencia de política ocurre cuando el Proxy Envoy y la aplicación backend interpretan la solicitud
de manera diferente.

Un error de coincidencia puede llevar a rechazo inesperado o a un bypass de política. Lo último es usualmente un incidente de seguridad que necesita ser
arreglado inmediatamente, y también es por qué necesitamos normalización de rutas en la política de autorización.

Por ejemplo, considera una política de autorización para rechazar solicitudes con ruta `/data/secret`. Una solicitud con ruta `/data//secret` no
será rechazada porque no coincide con la ruta definida en la política de autorización debido a la barra diagonal `/` extra en la ruta.

La solicitud pasa y luego la aplicación backend retorna la misma respuesta que retorna para la ruta `/data/secret`
porque la aplicación backend normaliza la ruta `/data//secret` a `/data/secret` ya que considera las barras diagonales dobles
`//` equivalentes a una sola barra diagonal `/`.

En este ejemplo, el punto de aplicación de política (Proxy Envoy) tuvo un entendimiento diferente de la ruta que el punto de acceso a recursos
(aplicación backend). El entendimiento diferente causó el error de coincidencia y posteriormente el bypass de la política de autorización.

Esto se convierte en un problema complicado debido a los siguientes factores:

* Falta de un estándar claro para la normalización.

* Los backends y frameworks en diferentes capas tienen su propia normalización especial.

* Las aplicaciones pueden incluso tener normalizaciones arbitrarias para sus propios casos de uso.

La política de autorización de Istio implementa soporte incorporado de varias opciones de normalización básicas para ayudarte a abordar mejor
el problema:

* Consulta [Guía sobre configurar la opción de normalización de rutas](/es/docs/ops/best-practices/security/#guideline-on-configuring-the-path-normalization-option)
  para entender qué opciones de normalización podrías querer usar.

* Consulta [Personalizar tu sistema en normalización de rutas](/es/docs/ops/best-practices/security/#customize-your-system-on-path-normalization) para
  entender el detalle de cada opción de normalización.

* Consulta [Mitigación para normalización no soportada](/es/docs/ops/best-practices/security/#mitigation-for-unsupported-normalization) para
  soluciones alternativas en caso de que necesites cualquier opción de normalización no soportada.

### Guía sobre configurar la opción de normalización de rutas

#### Caso 1: No necesitas normalización en absoluto

Antes de sumergirse en los detalles de configurar normalización, primero deberías asegurarte de que las normalizaciones sean necesarias.

No necesitas normalización si no usas políticas de autorización o si tus políticas de autorización no
usan ningún campo `path`.

Podrías no necesitar normalización si todas tus políticas de autorización siguen el [patrón de autorización más seguro](/es/docs/ops/best-practices/security/#safer-authorization-policy-patterns)
que, en el peor caso, resulta en rechazo inesperado en lugar de bypass de política.

#### Caso 2: Necesitas normalización pero no estás seguro de qué opción de normalización usar

Necesitas normalización pero no tienes idea de qué opción usar. La elección más segura es la opción de normalización más estricta
que proporciona el máximo nivel de normalización en la política de autorización.

Este es a menudo el caso debido al hecho de que los sistemas multi-capas complicados hacen prácticamente imposible averiguar
qué normalización está realmente ocurriendo a una solicitud más allá del punto de aplicación.

Podrías usar una opción de normalización menos estricta si ya satisface tus requisitos y estás seguro de sus implicaciones.

Para cualquier opción, asegúrate de escribir tanto pruebas positivas como negativas específicamente para tus requisitos para verificar que la
normalización esté funcionando como se espera. Las pruebas son útiles para detectar problemas de bypass potenciales causados por un malentendido
o conocimiento incompleto de la normalización que está ocurriendo a tu solicitud.

Consulta [Personalizar tu sistema en normalización de rutas](/es/docs/ops/best-practices/security/#customize-your-system-on-path-normalization)
para más detalles sobre configurar la opción de normalización.

#### Caso 3: Necesitas una opción de normalización no soportada

Si necesitas una opción de normalización específica que aún no es soportada por Istio, por favor sigue
[Mitigación para normalización no soportada](/es/docs/ops/best-practices/security/#mitigation-for-unsupported-normalization)
para soporte de normalización personalizada o crea una solicitud de característica para la comunidad de Istio.

### Personalizar tu sistema en normalización de rutas

Las políticas de autorización de Istio pueden basarse en las rutas URL en la solicitud HTTP.
[Normalización de rutas (también conocida como normalización de URI)](https://en.wikipedia.org/wiki/URI_normalization) modifica y estandariza las rutas de solicitudes entrantes,
para que las rutas normalizadas puedan ser procesadas de manera estándar.
Rutas sintácticamente diferentes pueden ser equivalentes después de la normalización de rutas.

Istio soporta los siguientes esquemas de normalización en las rutas de solicitud,
antes de evaluar contra las políticas de autorización y enrutar las solicitudes:

| Opción | Descripción | Ejemplo |
| --- | --- | --- |
| `NONE` | No se hace normalización. Cualquier cosa recibida por Envoy será reenviada exactamente como está a cualquier Service backend. | `../%2Fa../b` es evaluado por las políticas de autorización y enviado a tu servicio. |
| `BASE` | Esta es actualmente la opción usada en la instalación *por defecto* de Istio. Esto aplica la opción [`normalize_path`](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto#envoy-v3-api-field-extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-normalize-path) en los proxies Envoy, que sigue [RFC 3986](https://tools.ietf.org/html/rfc3986) con normalización extra para convertir barras invertidas a barras diagonales. | `/a/../b` se normaliza a `/b`. `\da` se normaliza a `/da`. |
| `MERGE_SLASHES` | Las barras diagonales se fusionan después de la normalización _BASE_. | `/a//b` se normaliza a `/a/b`. |
| `DECODE_AND_MERGE_SLASHES` | La configuración más estricta cuando permites todo el tráfico por defecto. Esta configuración se recomienda, con la advertencia de que necesitarás probar exhaustivamente tus políticas de autorización y rutas. Los caracteres de barra diagonal y barra invertida [codificados en porcentaje](https://tools.ietf.org/html/rfc3986#section-2.1) (`%2F`, `%2f`, `%5C` y `%5c`) se decodifican a `/` o `\`, antes de la normalización `MERGE_SLASHES`. | `/a%2fb` se normaliza a `/a/b`. |

{{< tip >}}
La configuración se especifica a través del campo [`pathNormalization`](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ProxyPathNormalization)
en la [configuración de malla](/es/docs/reference/config/istio.mesh.v1alpha1/).
{{< /tip >}}

Para enfatizar, los algoritmos de normalización se conducen en el siguiente orden:

1. Decodificar en porcentaje `%2F`, `%2f`, `%5C` y `%5c`.
1. La normalización [RFC 3986](https://tools.ietf.org/html/rfc3986) y otra implementada por la opción [`normalize_path`](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/network/http_connection_manager/v3/http_connection_manager.proto#envoy-v3-api-field-extensions-filters-network-http-connection-manager-v3-httpconnectionmanager-normalize-path) en Envoy.
1. Fusionar barras diagonales

{{< warning >}}
Aunque estas opciones de normalización representan recomendaciones de estándares HTTP y prácticas comunes de la industria,
las aplicaciones pueden interpretar una URL de cualquier manera que elijan.
Al usar políticas de denegación, asegúrate de entender cómo se comporta tu aplicación.
{{< /warning >}}

Para una lista completa de normalizaciones soportadas, por favor consulta [normalización de política de autorización](/es/docs/reference/config/security/normalization/).

#### Ejemplos de configuración

Asegurar que Envoy normalice las rutas de solicitud para coincidir con la expectativa de tus servicios backend es crítico para la seguridad de tu sistema.
Los siguientes ejemplos pueden usarse como referencia para configurar tu sistema.
Las rutas URL normalizadas, o las rutas URL originales si se selecciona _NONE_, serán:

1. Usadas para verificar contra las políticas de autorización
1. Reenviadas a la aplicación backend

| Tu aplicación... | Elige... |
| --- | --- |
| Depende del proxy para hacer normalización | `BASE`, `MERGE_SLASHES` o `DECODE_AND_MERGE_SLASHES` |
| Normaliza rutas de solicitud basadas en [RFC 3986](https://tools.ietf.org/html/rfc3986) y no fusiona barras diagonales | `BASE` |
| Normaliza rutas de solicitud basadas en [RFC 3986](https://tools.ietf.org/html/rfc3986), fusiona barras diagonales pero no decodifica barras diagonales [codificadas en porcentaje](https://tools.ietf.org/html/rfc3986#section-2.1) | `MERGE_SLASHES` |
| Normaliza rutas de solicitud basadas en [RFC 3986](https://tools.ietf.org/html/rfc3986), decodifica barras diagonales [codificadas en porcentaje](https://tools.ietf.org/html/rfc3986#section-2.1) y fusiona barras diagonales | `DECODE_AND_MERGE_SLASHES` |
| Procesa rutas de solicitud de una manera que es incompatible con [RFC 3986](https://tools.ietf.org/html/rfc3986) | `NONE` |

#### Cómo configurar

Puedes usar `istioctl` para actualizar la [configuración de malla](/es/docs/reference/config/istio.mesh.v1alpha1/):

{{< text bash >}}
$ istioctl upgrade --set meshConfig.pathNormalization.normalization=DECODE_AND_MERGE_SLASHES
{{< /text >}}

o alterando tu archivo de overrides del operator

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

Alternativamente, si quieres editar directamente la configuración de malla,
puedes agregar el [`pathNormalization`](/es/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ProxyPathNormalization)
a la [configuración de malla](/es/docs/reference/config/istio.mesh.v1alpha1/), que es el configmap `istio-<REVISION_ID>` en el namespace `istio-system`.
Por ejemplo, si eliges la opción `DECODE_AND_MERGE_SLASHES`, modificas la configuración de meshcomo lo siguiente:

{{< text yaml >}}
apiVersion: v1
  data:
    mesh: |-
      ...
      pathNormalization:
        normalization: DECODE_AND_MERGE_SLASHES
      ...
{{< /text >}}

### Mitigación para normalización no soportada

Esta sección describe varias mitigaciones para normalización no soportada. Estas podrían ser útiles cuando necesitas una normalización específica
que no es soportada por Istio.

Por favor asegúrate de entender la mitigación completamente y usarla cuidadosamente ya que algunas mitigaciones dependen de cosas que están
fuera del alcance de Istio y también no son soportadas por Istio.

#### Lógica de normalización personalizada

Puedes aplicar lógica de normalización personalizada usando el filtro WASM o Lua. Se recomienda usar el filtro WASM porque
está oficialmente soportado y también usado por Istio. Podrías usar el filtro Lua para una prueba de concepto DEMO rápida pero no
recomendamos usar el filtro Lua en producción porque no está soportado por Istio.

##### Ejemplo de normalización personalizada (normalización de caso)

En algunos entornos, puede ser útil tener rutas en políticas de autorización comparadas de manera insensible a mayúsculas y minúsculas.
Por ejemplo, tratar `https://myurl/get` y `https://myurl/GeT` como equivalentes.

En esos casos, el `EnvoyFilter` mostrado a continuación puede usarse para insertar un filtro Lua para normalizar la ruta a minúsculas.
Este filtro cambiará tanto la ruta usada para comparación como la ruta presentada a la aplicación.

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

#### Escribir Políticas de Coincidencia de Host

Istio genera hostnames tanto para el hostname mismo como para todos los puertos coincidentes. Por ejemplo, un virtual service o Gateway
para un host de `example.com` genera una configuración que coincide con `example.com` y `example.com:*`. Sin embargo, las políticas de autorización de coincidencia exacta
solo coinciden con la cadena exacta dada para los campos `hosts` o `notHosts`.

[Las reglas de política de autorización](/es/docs/reference/config/security/authorization-policy/#Rule) que coinciden con hosts deben escribirse usando
coincidencias de prefijo en lugar de coincidencias exactas. Por ejemplo, para una `AuthorizationPolicy` que coincida con la configuración de Envoy generada
para un hostname de `example.com`, usarías `hosts: ["example.com", "example.com:*"]` como se muestra en la `AuthorizationPolicy` a continuación.

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

Adicionalmente, los campos `host` y `notHosts` generalmente solo deben usarse en gateway para tráfico externo entrando a la mesh
y no en sidecars para tráfico dentro de la mesh. Esto es porque el sidecar en el lado del servidor (donde se aplica la política de autorización)
no usa el header `Host` al redirigir la solicitud a la aplicación. Esto hace que `host` y `notHost` no tengan sentido
en sidecar porque un cliente podría alcanzar la aplicación usando dirección IP explícita y header `Host` arbitrario en lugar de
el nombre del servicio.

Si realmente necesitas aplicar control de acceso basado en el header `Host` en sidecars por cualquier razón, sigue con los [patrones de denegación por defecto](/es/docs/ops/best-practices/security/#use-default-deny-patterns)
que rechazarían la solicitud si el cliente usa un header `Host` arbitrario.

#### Web Application Firewall (WAF) Especializado

Muchos productos especializados de Web Application Firewall (WAF) proporcionan opciones de normalización adicionales. Pueden desplegarse en
frente del Istio ingress gateway para normalizar solicitudes entrando a la mesh. La política de autorización será entonces aplicada
en las solicitudes normalizadas. Por favor consulta tu producto WAF específico para configurar las opciones de normalización.

#### Solicitud de característica a Istio

Si crees que Istio debería soportar oficialmente una normalización específica, puedes seguir la página [reportar una vulnerabilidad](/es/docs/releases/security-vulnerabilities/#reporting-a-vulnerability)
para enviar una solicitud de característica sobre la normalización específica al Grupo de Trabajo de Seguridad de Producto de Istio para evaluación inicial.

Por favor no abras ningún issue en público sin primero contactar al Grupo de Trabajo de Seguridad de Producto de Istio porque el
issue podría considerarse una vulnerabilidad de seguridad que necesita ser arreglada en privado.

Si el Grupo de Trabajo de Seguridad de Producto de Istio evalúa la solicitud de característica como no una vulnerabilidad de seguridad, se abrirá un issue
en público para más discusiones de la solicitud de característica.

### Limitaciones conocidas

Esta sección lista limitaciones conocidas de la política de autorización.

#### Los protocolos TCP server-first no son soportados

Los protocolos TCP server-first significan que la aplicación del servidor enviará los primeros bytes justo después de aceptar la conexión TCP
antes de recibir cualquier dato del cliente.

Actualmente, la política de autorización solo soporta aplicar control de acceso en tráfico entrante y no en el tráfico saliente.

Tampoco soporta protocolos TCP server-first porque los primeros bytes son enviados por la aplicación del servidor incluso antes
de que reciba cualquier dato del cliente. En este caso, los primeros bytes iniciales enviados por el servidor son retornados al cliente
directamente sin pasar por la verificación de control de acceso de la política de autorización.

No deberías usar la política de autorización si los primeros bytes enviados por los protocolos TCP server-first incluyen cualquier dato sensible
que necesite ser protegido por autorización apropiada.

Podrías aún usar la política de autorización en este caso si los primeros bytes no incluyen cualquier dato sensible, por ejemplo,
los primeros bytes se usan para negociar la conexión con datos que son públicamente accesibles a cualquier cliente. La política de autorización
funcionará como usual para las siguientes solicitudes enviadas por el cliente después de los primeros bytes.

## Entender las limitaciones de captura de tráfico

El sidecar de Istio funciona capturando tanto tráfico entrante como saliente y dirigiéndolos a través del sidecar proxy.

Sin embargo, no *todo* el tráfico es capturado:

* La redirección solo maneja tráfico basado en TCP. Cualquier paquete UDP o ICMP no será capturado o modificado.
* La captura entrante está deshabilitada en muchos [puertos usados por el sidecar](/es/docs/ops/deployment/application-requirements/#ports-used-by-istio) así como el puerto 22. Esta lista puede expandirse con opciones como `traffic.sidecar.istio.io/excludeInboundPorts`.
* La captura saliente puede ser reducida similarmente a través de configuraciones como `traffic.sidecar.istio.io/excludeOutboundPorts` u otros medios.

En general, hay un límite de seguridad mínimo entre una aplicación y su sidecar proxy. La configuración del sidecar está permitida en base por pod, y ambos se ejecutan en el mismo namespace de red/proceso.
Como tal, la aplicación puede tener la habilidad de remover reglas de redirección y remover, alterar, terminar, o reemplazar el sidecar proxy.
Esto permite a un pod bypasear intencionalmente su sidecar para tráfico saliente o intencionalmente permitir que tráfico entrante bypasee su sidecar.

Como resultado, no es seguro depender de que todo el tráfico sea capturado incondicionalmente por Istio.
En su lugar, el límite de seguridad es que un cliente no puede bypasear el sidecar de *otro* pod.

Por ejemplo, si ejecuto la aplicación `reviews` en el puerto `9080`, puedo asumir que todo el tráfico de la aplicación `productpage` será capturado por el sidecar proxy,
donde las políticas de autenticación y autorización de Istio pueden aplicar.

### Defensa en profundidad con `NetworkPolicy`

Para asegurar más el tráfico, las políticas de Istio pueden ser en capas con [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) de Kubernetes.
Esto habilita una estrategia fuerte de [defensa en profundidad](https://en.wikipedia.org/wiki/Defense_in_depth_(computing)) que puede usarse para fortalecer más la seguridad de tu malla.

Por ejemplo, puedes elegir permitir solo tráfico al puerto `9080` de nuestra aplicación `reviews`.
En el evento de un pod comprometido o vulnerabilidad de seguridad en el cluster, esto puede limitar o detener el progreso de un atacante.

Dependiendo de la implementación real, los cambios a la política de red pueden no afectar las conexiones existentes en los proxies de Istio.
Puedes necesitar reiniciar los proxies de Istio después de aplicar la política para que las conexiones existentes sean cerradas y
las nuevas conexiones estén sujetas a la nueva política.

### Asegurar tráfico de egreso

Un concepto erróneo común es que opciones como [`outboundTrafficPolicy: REGISTRY_ONLY`](/es/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services) actúa como una política de seguridad previniendo todo acceso a servicios no declarados.
Sin embargo, esto no es un límite de seguridad fuerte como se mencionó anteriormente, y debería considerarse como mejor esfuerzo.

Aunque esto es útil para prevenir dependencias accidentales, si quieres asegurar tráfico de egreso, y hacer cumplir que todo tráfico saliente pase por un proxy, deberías en su lugar depender de un [Egress Gateway](/es/docs/tasks/traffic-management/egress/egress-gateway/).
Cuando se combina con una [Network Policy](/es/docs/tasks/traffic-management/egress/egress-gateway/#apply-kubernetes-network-policies), puedes hacer cumplir que todo el tráfico, o algún subconjunto, pase por el egress gateway.
Esto asegura que incluso si un cliente accidental o maliciosamente bypasea su sidecar, la solicitud será bloqueada.

## Configurar verificación TLS en Destination Rule cuando se usa originación TLS

Istio ofrece la habilidad de [originar TLS](/es/docs/tasks/traffic-management/egress/egress-tls-origination/) desde un sidecar proxy o gateway.
Esto habilita aplicaciones que envían tráfico HTTP de texto plano para ser transparentemente "actualizadas" a HTTPS.

Se debe tener cuidado al configurar la configuración `tls` del `DestinationRule` para especificar los campos `caCertificates`, `subjectAltNames`, y `sni`.
El `caCertificate` puede establecerse automáticamente desde el certificado CA del almacén de certificados del sistema habilitando la variable de entorno `VERIFY_CERTIFICATE_AT_CLIENT=true` en Istiod.
Si el certificado CA del Sistema Operativo que se está usando automáticamente solo se desea para host(s) seleccionados, la variable de entorno `VERIFY_CERTIFICATE_AT_CLIENT=false` en Istiod, `caCertificates` puede establecerse a `system` en el(los) `DestinationRule`(s) deseado(s).
Especificar los `caCertificates` en un `DestinationRule` tomará prioridad y el Certificado CA del SO no será usado.
Por defecto, el tráfico de egreso no envía SNI durante el handshake TLS.
SNI debe establecerse en el `DestinationRule` para asegurar que el host maneje apropiadamente la solicitud.

{{< warning >}}
Para verificar el certificado del servidor es importante que tanto `caCertificates` como `subjectAltNames` estén establecidos.

La verificación del certificado presentado por el servidor contra un CA no es suficiente, ya que los Nombres Alternativos del Sujeto también deben ser validados.

Si `VERIFY_CERTIFICATE_AT_CLIENT` está establecido, pero `subjectAltNames` no está establecido entonces no estás verificando todas las credenciales.

Si no se está usando ningún certificado CA, `subjectAltNames` no será usado independientemente de si está establecido o no.
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

## Gateways

Al ejecutar un [gateway](/es/docs/tasks/traffic-management/ingress/) de Istio, hay algunos recursos involucrados:

* `Gateway`s, que controlan los puertos y configuraciones TLS para el gateway.
* `VirtualService`s, que controlan la lógica de enrutamiento. Estos están asociados con `Gateway`s por referencia directa en el campo `gateways` y un acuerdo mutuo en el campo `hosts` en el `Gateway` y `VirtualService`.

### Restringir privilegios de creación de `Gateway`

Se recomienda restringir la creación de recursos Gateway a administradores de cluster confiables. Esto puede lograrse por [políticas RBAC de Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) o herramientas como [Open Policy Agent](https://www.openpolicyagent.org/).

### Evitar configuraciones de `hosts` demasiado amplias

Cuando sea posible, evita configuraciones de `hosts` demasiado amplias en `Gateway`.

Por ejemplo, esta configuración permitirá a cualquier `VirtualService` vincularse al `Gateway`, potencialmente exponiendo dominios inesperados:

{{< text yaml >}}
servers:
- port:
    number: 80
    name: http
    protocol: HTTP
  hosts:
  - "*"
{{< /text >}}

Esto debería ser bloqueado para permitir solo dominios específicos o namespaces específicos:

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

### Aislar servicios sensibles

Puede ser deseado hacer cumplir aislamiento físico más estricto para servicios sensibles. Por ejemplo, puedes querer ejecutar una
[instancia de gateway dedicada](/es/docs/setup/install/istioctl/#configure-gateways) para un `payments.example.com` sensible, mientras utilizas una sola
instancia de gateway compartida para dominios menos sensibles como `blog.example.com` y `store.example.com`.
Esto puede ofrecer una defensa en profundidad más fuerte y ayudar a cumplir ciertas pautas de cumplimiento regulatorio.

### Deshabilitar explícitamente todos los hosts http sensibles bajo coincidencia de host SNI relajada

Es razonable usar múltiples `Gateway`s para definir mutual TLS y simple TLS en diferentes hosts.
Por ejemplo, usar mutual TLS para host SNI `admin.example.com` y simple TLS para host SNI `*.example.com`.

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

Si lo anterior es necesario, es altamente recomendado deshabilitar explícitamente el host http `admin.example.com` en el `VirtualService` que se adjunta a `*.example.com`. La razón es que actualmente el [proxy envoy subyacente no requiere](https://github.com/envoyproxy/envoy/issues/6767) que el header http 1 `Host` o el pseudo header http 2 `:authority` sigan las restricciones SNI, un atacante puede reusar la conexión TLS guest-SNI para acceder al `VirtualService` admin. El código de respuesta http 421 está diseñado para este desajuste `Host` SNI y puede usarse para cumplir la deshabilitación.

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
Para evitar detección errónea accidental o intencional, que puede resultar en comportamiento de tráfico inesperado, se recomienda [declarar explícitamente el protocolo](/es/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection) donde sea posible.

## CNI

Para capturar transparentemente todo el tráfico, Istio depende de reglas `iptables` configuradas por el `initContainer` `istio-init`.
Esto agrega un [requisito](/es/docs/ops/deployment/application-requirements/) para que las [capacidades](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-capabilities-for-a-container) `NET_ADMIN` y `NET_RAW` estén disponibles para el pod.

Para reducir los privilegios otorgados a los pods, Istio ofrece un [plugin CNI](/es/docs/setup/additional-setup/cni/) que remueve este requisito.

## Usar imágenes docker endurecidas

Las imágenes docker por defecto de Istio, incluyendo aquellas ejecutadas por el control plane, gateway, y sidecar proxies, están basadas en `ubuntu`.
Esto proporciona varias herramientas como `bash` y `curl`, que intercambia conveniencia por un aumento en la superficie de ataque.

Istio también ofrece una imagen más pequeña basada en [imágenes distroless](/es/docs/ops/configuration/security/harden-docker-images/) que reduce las dependencias en la imagen.

{{< warning >}}
Las imágenes distroless son actualmente una característica alpha.
{{< /warning >}}

## Política de release y seguridad

Para asegurar que tu cluster tenga los últimos parches de seguridad para vulnerabilidades conocidas, es importante mantenerse en el último patch release de Istio y asegurar que estés en un [release soportado](/es/docs/releases/supported-releases) que aún esté recibiendo parches de seguridad.

## Detectar configuraciones inválidas

Aunque Istio proporciona validación de recursos cuando se crean, estas verificaciones no pueden detectar todos los problemas que previenen que la configuración sea distribuida en la mesh.
Esto podría resultar en aplicar una política que es inesperadamente ignorada, llevando a resultados inesperados.

* Ejecuta `istioctl analyze` antes o después de aplicar configuración para asegurar que sea válida.
* Monitorea el control plane para configuraciones rechazadas. Estas están expuestas por la métrica `pilot_total_xds_rejects`, además de logs.
* Prueba tu configuración para asegurar que da los resultados esperados.
  Para una política de seguridad, es útil ejecutar pruebas positivas y negativas para asegurar que no restringes accidentalmente demasiado o muy poco tráfico.

## Evitar características alpha y experimentales

Todas las características y APIs de Istio tienen asignado un [estado de característica](/es/docs/releases/feature-stages/), definiendo su estabilidad, política de deprecación, y política de seguridad.

Porque las características alpha y experimentales no tienen garantías de seguridad tan fuertes, se recomienda evitarlas siempre que sea posible.
Los problemas de seguridad encontrados en estas características pueden no ser arreglados inmediatamente o de otra manera no seguir nuestro proceso estándar de [vulnerabilidad de seguridad](/es/docs/releases/security-vulnerabilities/).

Para determinar el estado de característica de las características en uso en tu cluster, consulta la lista de [características de Istio](/es/docs/releases/feature-stages/#istio-features).

<!-- In the future, we should document the `istioctl` command to check this when available. -->

## Bloquear puertos

Istio configura una [variedad de puertos](/es/docs/ops/deployment/application-requirements/#ports-used-by-istio) que pueden ser bloqueados para mejorar la seguridad.

### Control Plane

Istiod expone algunos puertos de texto plano no autenticados por conveniencia por defecto. Si se desea, estos pueden ser cerrados:

* El puerto `8080` expone la interfaz de debug, que ofrece acceso de lectura a una variedad de detalles sobre el estado del cluster.
  Esto puede deshabilitarse estableciendo la variable de entorno `ENABLE_DEBUG_ON_HTTP=false` en Istiod. Advertencia: muchos comandos `istioctl`
  dependen de esta interfaz y no funcionarán si está deshabilitada.
* El puerto `15010` expone el Service XDS sobre texto plano. Esto puede deshabilitarse agregando la bandera `--grpcAddr=""` al Deployment de Istiod.
  Nota: servicios altamente sensibles, como los servicios de firma y distribución de certificados, nunca se sirven sobre texto plano.

### data plane

El proxy expone una variedad de puertos. Expuestos externamente están el puerto `15090` (telemetría) y el puerto `15021` (verificación de salud).
Los puertos `15020` y `15000` proporcionan endpoints de debugging. Estos están expuestos solo sobre `localhost`.
Como resultado, las aplicaciones ejecutándose en el mismo pod que el proxy tienen acceso; no hay límite de confianza entre el sidecar y la aplicación.

## Configurar tokens de cuenta de servicio de terceros

Para autenticarse con el control plane de Istio, el proxy de Istio usará un token de Service Account. Kubernetes soporta dos formas de estos tokens:

* Tokens de terceros, que tienen una audiencia con alcance y expiración.
* Tokens de primera parte, que no tienen expiración y están montados en todos los pods.

Porque las propiedades del token de primera parte son menos seguras, Istio usará por defecto tokens de terceros. Sin embargo, esta característica no está habilitada en todas las plataformas de Kubernetes.

Si estás usando `istioctl` para instalar, el soporte será detectado automáticamente. Esto puede hacerse manualmente también, y configurarse pasando `--set values.global.jwtPolicy=third-party-jwt` o `--set values.global.jwtPolicy=first-party-jwt`.

Para determinar si tu cluster soporta tokens de terceros, busca la API `TokenRequest`. Si esto no retorna respuesta, entonces la característica no está soportada:

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

Aunque la mayoría de los proveedores de nube soportan esta característica ahora, muchas herramientas de desarrollo local e instalaciones personalizadas pueden no hacerlo antes de Kubernetes 1.20. Para habilitar esta característica, por favor consulta la [documentación de Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#service-account-token-volume-projection).

## Configurar un límite en conexiones downstream

Por defecto, Istio (y Envoy) no tienen límite en el número de conexiones downstream. Esto puede ser explotado por un actor malicioso (ver [boletín de seguridad 2020-007](/news/security/istio-security-2020-007/)). Para solucionar esto, debes configurar un límite de conexión apropiado para tu entorno.

### Configurar valor `global_downstream_max_connections`

La siguiente configuración puede suministrarse durante la instalación:

{{< text yaml >}}
meshConfig:
  defaultConfig:
    runtimeValues:
      "overload.global_downstream_max_connections": "100000"
{{< /text >}}
