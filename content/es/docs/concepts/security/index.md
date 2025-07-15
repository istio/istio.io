---
title: Seguridad
description: Describe la funcionalidad de autorización y autenticación de Istio.
weight: 30
keywords: [security,policy,policies,authentication,authorization,rbac,access-control]
aliases:
    - /docs/concepts/network-and-auth/auth.html
    - /docs/concepts/security/authn-policy/
    - /docs/concepts/security/mutual-tls/
    - /docs/concepts/security/rbac/
    - /docs/concepts/security/mutual-tls.html
    - /docs/concepts/policies/
owner: istio/wg-security-maintainers
test: n/a
---

Descomponer una aplicación monolítica en services atómicos ofrece varios
beneficios, incluyendo mayor agilidad, mejor escalabilidad y mayor capacidad de
reutilizar services. Sin embargo, los microservices también tienen necesidades de seguridad particulares:

- Para defenderse de ataques de intermediario, necesitan cifrado de tráfico.
- Para proporcionar un control de acceso flexible a los services, necesitan mTLS y
   políticas de acceso de grano fino.
- Para determinar quién hizo qué en qué momento, necesitan herramientas de auditoría.

Istio Security proporciona una solución de seguridad integral para resolver estos problemas.
Esta página ofrece una visión general de cómo puede usar las features de seguridad de Istio para proteger
sus services, dondequiera que los ejecute. En particular, la seguridad de Istio mitiga
tanto las amenazas internas como externas contra sus datos, endpoints, comunicación
y plataforma.

{{< image width="75%"
    link="./overview.svg"
    caption="Visión general de la seguridad"
    >}}

Las features de seguridad de Istio proporcionan una identidad fuerte, una política potente,
cifrado TLS transparente y herramientas de autenticación, autorización y auditoría (AAA)
para proteger sus services y datos. Los objetivos de la seguridad de Istio son:

- Seguridad por defecto: no se necesitan cambios en el código de la aplicación y
    la infraestructura
- Defensa en profundidad: integración con sistemas de seguridad existentes para proporcionar
    múltiples capas de defensa
- Red de confianza cero: construcción de soluciones de seguridad en redes no confiables

Visite nuestra
[documentación de migración de mTLS](/es/docs/tasks/security/authentication/mtls-migration/)
para comenzar a usar las features de seguridad de Istio con sus services desplegados. Visite nuestras
[Tareas de Seguridad](/es/docs/tasks/security/) para obtener instrucciones detalladas
sobre cómo usar las features de seguridad.

## Arquitectura de alto nivel

La seguridad en Istio involucra múltiples componentes:

- Una Autoridad de Certificación (CA) para la gestión de claves y certificados
- El servidor API de configuración distribuye a los proxies:

    - [políticas de autenticación](/es/docs/concepts/security/#authentication-policies)
    - [políticas de autorización](/es/docs/concepts/security/#authorization-policies)
    - [información de nombres seguros](/es/docs/concepts/security/#secure-naming)

- Los proxies sidecar y perimetrales funcionan como [Puntos de Aplicación de Políticas](https://csrc.nist.gov/glossary/term/policy_enforcement_point)
    (PEPs) para asegurar la comunicación entre clientes y servidores.
- Un conjunto de extensiones de proxy Envoy para gestionar la telemetría y la auditoría

El control plane maneja la configuración del servidor API y
configura los PEP en el data plane. Los PEP se implementan usando Envoy. El
siguiente diagrama muestra la arquitectura.

{{< image width="75%"
    link="./arch-sec.svg"
    caption="Arquitectura de Seguridad"
    >}}

En las siguientes secciones, introducimos las features de seguridad de Istio en detalle.

## Identidad de Istio

La identidad es un concepto fundamental de cualquier infraestructura de seguridad. Al
comienzo de una comunicación workload-to-workload, las dos partes deben intercambiar
credenciales con su información de identidad para fines de autenticación mutua.
En el lado del cliente, la identidad del servidor se verifica con la
información de [nombres seguros](/es/docs/concepts/security/#secure-naming)
para ver si es un ejecutor autorizado del workload. En el lado del servidor,
el servidor puede determinar a qué información puede acceder el cliente basándose en
las
[políticas de autorización](/es/docs/concepts/security/#authorization-policies),
auditar quién accedió a qué en qué momento, cobrar a los clientes en función de los workloads que
utilizaron y rechazar a cualquier cliente que no haya pagado su factura para acceder a los
workloads.

El modelo de identidad de Istio utiliza la `identidad de service` de primera clase para
determinar la identidad del origen de una solicitud. Este modelo permite una gran
flexibilidad y granularidad para que las identidades de service representen un usuario humano, un
workload individual o un grupo de workloads. En plataformas sin una identidad de service,
Istio puede usar otras identidades que pueden agrupar instancias de workload,
como nombres de service.

La siguiente lista muestra ejemplos de identidades de service que puede usar en diferentes
plataformas:

- Kubernetes: cuenta de service de Kubernetes
- GCE: cuenta de service de GCP
- On-premises (no Kubernetes): cuenta de usuario, cuenta de service personalizada,
   nombre de service, cuenta de service de Istio o cuenta de service de GCP. La cuenta de service
   personalizada se refiere a la cuenta de service existente al igual que las
   identidades que gestiona el Directorio de Identidades del cliente.

## Gestión de identidad y certificados {#pki}

Istio aprovisiona de forma segura identidades fuertes
a cada workload con certificados X.509. Los agentes de Istio, que se ejecutan junto a cada proxy Envoy,
trabajan junto con `istiod` para automatizar la rotación de claves y certificados
a escala. El siguiente diagrama muestra el flujo de aprovisionamiento de identidad.

{{< image width="40%"
    link="./id-prov.svg"
    caption="Flujo de Aprovisionamiento de Identidad"
    >}}

Istio aprovisiona claves y certificados a través del siguiente flujo:

1. `istiod` ofrece un service gRPC para tomar [solicitudes de firma de certificados](https://en.wikipedia.org/wiki/Certificate_signing_request) (CSRs).
1. Al iniciarse, el agente de Istio crea la clave privada
   y el CSR, y luego envía el CSR con sus credenciales a `istiod` para su firma.
1. La CA en `istiod` valida las credenciales contenidas en el CSR.
   Tras una validación exitosa, firma el CSR para generar el certificado.
1. Cuando se inicia un workload, Envoy solicita el certificado y la clave al agente de Istio en el
   mismo contenedor a través de la
   [API de service de descubrimiento de secretos (SDS) de Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#secret-discovery-service-sds).
1. El agente de Istio envía los certificados recibidos de `istiod` y la
   clave privada a Envoy a través de la API SDS de Envoy.
1. El agente de Istio monitorea la expiración del certificado del workload.
   El proceso anterior se repite periódicamente para la rotación de certificados y claves.

## Autenticación

Istio proporciona dos tipos de autenticación:

- Autenticación de pares: utilizada para la autenticación service-to-service para verificar
   el cliente que realiza la conexión. Istio ofrece [mTLS](https://en.wikipedia.org/wiki/Mutual_authentication)
   como una solución completa para la autenticación de transporte, que se puede habilitar sin
   requerir cambios en el código del service. Esta solución:
    - Proporciona a cada service una identidad fuerte que representa su rol
      para permitir la interoperabilidad entre clusters y nubes.
    - Asegura la comunicación service-to-service.
    - Proporciona un sistema de gestión de claves para automatizar la generación, distribución y rotación de claves y certificados.

- Autenticación de solicitudes: utilizada para la autenticación de usuario final para verificar la
   credencial adjunta a la solicitud. Istio habilita la autenticación a nivel de solicitud
   con validación de JSON Web Token (JWT) y una experiencia de desarrollador simplificada
   utilizando un proveedor de autenticación personalizado o cualquier proveedor de OpenID
   Connect, por ejemplo:
    - [ORY Hydra](https://www.ory.sh/)
    - [Keycloak](https://www.keycloak.org/)
    - [Auth0](https://auth0.com/)
    - [Firebase Auth](https://firebase.google.com/docs/auth/)
    - [Google Auth](https://developers.google.com/identity/protocols/OpenIDConnect)

En todos los casos, Istio almacena las políticas de autenticación en el `almacén de configuración de Istio`
a través de una API de Kubernetes personalizada. {{< gloss >}}Istiod{{< /gloss >}} las mantiene actualizadas para cada proxy,
junto con las claves cuando corresponda. Además, Istio admite
la autenticación en modo permisivo para ayudarle a comprender cómo un cambio de política puede
afectar su postura de seguridad antes de que se aplique.

### Autenticación mTLS

Istio tuneliza la comunicación service-to-service a través de los PEP del lado del cliente y del servidor,
que se implementan como [proxies Envoy](https://www.envoyproxy.io/). Cuando un workload envía una solicitud
a otro workload utilizando la autenticación mTLS, la solicitud se maneja de la siguiente manera:

1. Istio reenvía el tráfico saliente de un cliente al sidecar Envoy local del cliente.
1. El Envoy del lado del cliente inicia un handshake mTLS con el Envoy del lado del servidor.
   Durante el handshake, el Envoy del lado del cliente también realiza una
   comprobación de [nombres seguros](/es/docs/concepts/security/#secure-naming)
   para verificar que la cuenta de service presentada en el certificado del servidor
   está autorizada para ejecutar el service de destino.
1. El Envoy del lado del cliente y el Envoy del lado del servidor establecen una conexión mTLS,
   e Istio reenvía el tráfico del Envoy del lado del cliente al Envoy del lado del servidor.
1. El Envoy del lado del servidor autoriza la solicitud. Si está autorizado, reenvía el tráfico al
   service de backend a través de conexiones TCP locales.

Istio configura `TLSv1_2` como la versión mínima de TLS para el cliente y el servidor con
las siguientes suites de cifrado:

- `ECDHE-ECDSA-AES256-GCM-SHA384`

- `ECDHE-RSA-AES256-GCM-SHA384`

- `ECDHE-ECDSA-AES128-GCM-SHA256`

- `ECDHE-RSA-AES128-GCM-SHA256`

- `AES256-GCM-SHA384`

- `AES128-GCM-SHA256`

#### Modo permisivo

Istio mTLS tiene un modo permisivo, que permite que un service acepte tanto
tráfico de texto plano como tráfico mTLS al mismo tiempo. Esta feature mejora en gran medida
la experiencia de incorporación de mTLS.

Muchos clientes que no son de Istio que se comunican con un servidor que no es de Istio presentan un problema
para un operador que desea migrar ese servidor a Istio con mTLS
habilitado. Comúnmente, el operador no puede instalar un sidecar de Istio para todos los clientes
al mismo tiempo o ni siquiera tiene los permisos para hacerlo en algunos clientes.
Incluso después de instalar el sidecar de Istio en el servidor, el operador no puede
habilitar mTLS sin romper las comunicaciones existentes.

Con el modo permisivo habilitado, el servidor acepta tanto tráfico de texto plano como mTLS.
El modo proporciona mayor flexibilidad para el proceso de incorporación.
El sidecar de Istio instalado en el servidor toma el tráfico mTLS inmediatamente
sin romper el tráfico de texto plano existente. Como resultado, el operador puede
instalar y configurar gradualmente los sidecars de Istio del cliente para enviar tráfico mTLS.
Una vez que la configuración de los clientes esté completa, el operador puede
configurar el servidor en modo solo mTLS. Para obtener más información, visite el
[tutorial de migración de mTLS](/es/docs/tasks/security/authentication/mtls-migration).

#### Nombres seguros

Las identidades del servidor se codifican en certificados, pero los nombres de service se recuperan
a través del service de descubrimiento o DNS. La información de nombres seguros mapea las
identidades del servidor a los nombres de service. Un mapeo de identidad `A` a nombre de service
`B` significa "`A` está autorizado para ejecutar el service `B`". El control plane observa
el `apiserver`, genera los mapeos de nombres seguros y los distribuye
de forma segura a los PEP. El siguiente ejemplo explica por qué los nombres seguros son
críticos en la autenticación.

Supongamos que los servidores legítimos que ejecutan el service `datastore` solo usan la
identidad `infra-team`. Un usuario malicioso tiene el certificado y la clave para la
identidad `test-team`. El usuario malicioso intenta suplantar el service para
inspeccionar los datos enviados desde los clientes. El usuario malicioso despliega un servidor
falsificado con el certificado y la clave para la identidad `test-team`. Supongamos que el
usuario malicioso secuestró con éxito (a través de suplantación de DNS, secuestro de BGP/ruta,
suplantación de ARP, etc.) el tráfico enviado al `datastore` y lo redirigió al
servidor falsificado.

Cuando un cliente llama al service `datastore`, extrae la identidad `test-team`
del certificado del servidor y verifica si `test-team` está
autorizado para ejecutar `datastore` con la información de nombres seguros. El cliente
detecta que `test-team` no está autorizado para ejecutar el service `datastore` y la
autenticación falla.

Tenga en cuenta que, para el tráfico que no es HTTP/HTTPS, el nombre seguro no protege contra la suplantación de DNS,
en cuyo caso el atacante modifica las IPs de destino para el service.
Dado que el tráfico TCP no contiene información de `Host` y Envoy solo puede
confiar en la IP de destino para el enrutamiento, Envoy puede enrutar el tráfico a
services en las IPs secuestradas. Esta suplantación de DNS puede ocurrir incluso
antes de que el Envoy del lado del cliente reciba el tráfico.

### Arquitectura de autenticación

Puede especificar los requisitos de autenticación para los workloads que reciben solicitudes en
una malla de Istio utilizando políticas de autenticación de pares y de solicitudes. El operador de la malla
utiliza ficheros `.yaml` para especificar las políticas. Las políticas se guardan en el
almacén de configuración de Istio una vez desplegadas. El controlador de Istio observa el
almacén de configuración.

Ante cualquier cambio de política, la nueva política se traduce a la configuración
apropiada que le indica al PEP cómo realizar los mecanismos de autenticación
requeridos. El control plane puede obtener la clave pública y adjuntarla a la
configuración para la validación de JWT. Alternativamente, Istiod proporciona la ruta a las
claves y certificados que el sistema Istio gestiona y los instala en el
pod de la aplicación para mTLS. Puede encontrar más información en la sección [Gestión de identidad y certificados](#pki).

Istio envía las configuraciones a los endpoints de destino de forma asíncrona. Una vez que el
proxy recibe la configuración, el nuevo requisito de autenticación surte
efecto inmediatamente en ese pod.

Los services cliente, aquellos que envían solicitudes, son responsables de seguir el
mecanismo de autenticación necesario. Para la autenticación de solicitudes, la aplicación es
responsable de adquirir y adjuntar la credencial JWT a la solicitud. Para
la autenticación de pares, Istio actualiza automáticamente todo el tráfico entre dos PEP a mTLS.
Si las políticas de autenticación deshabilitan el modo mTLS, Istio continúa usando
texto plano entre los PEP. Para anular este comportamiento, deshabilite explícitamente el modo mTLS
con
[reglas de destino](/es/docs/concepts/traffic-management/#destination-rules).
Puede encontrar más información sobre cómo funciona mTLS en la
sección [Autenticación mTLS](/es/docs/concepts/security/#mutual-tls-authentication).

{{< image width="50%"
    link="./authn.svg"
    caption="Arquitectura de Autenticación"
    >}}

Istio genera identidades con ambos tipos de autenticación, así como otros
claims en la credencial si corresponde, a la siguiente capa:
[autorización](/es/docs/concepts/security/#authorization).

### Políticas de autenticación

Esta sección proporciona más detalles sobre cómo funcionan las políticas de autenticación de Istio.
Como recordará de la
[sección Arquitectura](/es/docs/concepts/security/#authentication-architecture),
las políticas de autenticación se aplican a las solicitudes que recibe un service. Para especificar
reglas de autenticación del lado del cliente en mTLS, debe especificar la
`TLSSettings` en la `DestinationRule`. Puede encontrar más información en nuestra
[documentación de referencia de configuración de TLS](/es/docs/reference/config/networking/destination-rule#ClientTLSSettings).

Al igual que otras configuraciones de Istio, puede especificar políticas de autenticación en
ficheros `.yaml`. Despliega políticas usando `kubectl`.
La siguiente política de autenticación de ejemplo especifica que la autenticación de transporte
para los workloads con la etiqueta `app:reviews` debe usar mTLS:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "example-peer-policy"
  namespace: "foo"
spec:
  selector:
    matchLabels:
      app: reviews
  mtls:
    mode: STRICT
EOF
{{< /text >}}

#### Almacenamiento de políticas

Istio almacena las políticas con alcance de malla en el namespace raíz. Estas políticas tienen un
selector vacío que se aplica a todos los workloads de la malla. Las políticas que tienen un
alcance de namespace se almacenan en el namespace correspondiente. Solo se aplican a
los workloads dentro de su namespace. Si configura un campo `selector`, la
política de autenticación solo se aplica a los workloads que coinciden con las condiciones que
configuró.

Las políticas de autenticación de pares y de solicitudes se almacenan por separado por tipo,
`PeerAuthentication` y `RequestAuthentication` respectivamente.

#### Campo selector

Las políticas de autenticación de pares y de solicitudes utilizan campos `selector` para especificar la
etiqueta de los workloads a los que se aplica la política. El siguiente ejemplo muestra
el campo selector de una política que se aplica a los workloads con la
etiqueta `app:product-page`:

{{< text yaml >}}
selector:
  matchLabels:
    app: product-page
{{< /text >}}

Si no proporciona un valor para el campo `selector`, Istio hace coincidir la política
con todos los workloads en el ámbito de almacenamiento de la política. Por lo tanto, los campos `selector`
le ayudan a especificar el ámbito de las políticas:

- Política a nivel de malla: una política especificada para el namespace raíz sin o
   con un campo `selector` vacío.
- Política a nivel de namespace: una política especificada para un namespace no raíz sin
   o con un campo `selector` vacío.
- Política específica del workload: una política definida en el namespace regular, con
   campo selector no vacío.

Las políticas de autenticación de pares y de solicitudes siguen los mismos principios de jerarquía
para los campos `selector`, pero Istio los combina y aplica de formas ligeramente
diferentes.

Solo puede haber una política de autenticación de pares a nivel de malla y solo una
política de autenticación de pares a nivel de namespace por namespace. Cuando configura
múltiples políticas de autenticación de pares a nivel de malla o de namespace para la misma malla
o namespace, Istio ignora las políticas más nuevas. Cuando más de una
política de autenticación de pares específica del workload coincide, Istio elige la más antigua.

Istio aplica la política de coincidencia más restrictiva para cada workload utilizando el
siguiente orden:

1. específica del workload
1. a nivel de namespace
1. a nivel de malla

Istio puede combinar todas las políticas de autenticación de solicitudes coincidentes para que funcionen como si
provinieran de una única política de autenticación de solicitudes. Por lo tanto, puede tener
múltiples políticas de autenticación de solicitudes a nivel de malla o de namespace en una malla o namespace. Sin embargo,
sigue siendo una buena práctica evitar tener múltiples políticas de autenticación de solicitudes a nivel de malla o de namespace.

#### Autenticación de pares

Las políticas de autenticación de pares especifican el modo mTLS que Istio aplica a
los workloads de destino. Se admiten los siguientes modos:

- PERMISIVO: Los workloads aceptan tanto tráfico mTLS como tráfico de texto plano. Este
    modo es más útil durante las migraciones cuando los workloads sin sidecar no pueden
    usar mTLS. Una vez que los workloads se migran con inyección de sidecar, debe
    cambiar el modo a ESTRICTO.
- ESTRICTO: Los workloads solo aceptan tráfico mTLS.
- DESHABILITAR: mTLS está deshabilitado. Desde una perspectiva de seguridad,
    no debe usar este modo a menos que proporcione su propia solución de seguridad.

Cuando el modo no está establecido, se hereda el modo del ámbito padre. Las políticas de autenticación de pares
a nivel de malla con un modo no establecido usan el modo `PERMISIVO` por
defecto.

La siguiente política de autenticación de pares requiere que todos los workloads en el namespace
`foo` usen mTLS:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "example-policy"
  namespace: "foo"
spec:
  mtls:
    mode: STRICT
{{< /text >}}

Con las políticas de autenticación de pares específicas del workload, puede especificar diferentes
modos mTLS para diferentes puertos. Solo puede usar puertos que los workloads hayan
reclamado para la configuración mTLS a nivel de puerto. El siguiente ejemplo deshabilita
mTLS en el puerto `80` para el workload `app:example-app`, y usa la configuración mTLS
de la política de autenticación de pares a nivel de namespace para todos los demás puertos:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "example-workload-policy"
  namespace: "foo"
spec:
  selector:
     matchLabels:
       app: example-app
  portLevelMtls:
    80:
      mode: DISABLE
{{< /text >}}

La política de autenticación de pares anterior funciona solo porque la configuración del service
a continuación vinculó las solicitudes del workload `example-app` al puerto
`80` del service `example-service`:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: example-service
  namespace: foo
spec:
  ports:
  - name: http
    port: 8000
    protocol: TCP
    targetPort: 80
  selector:
    app: example-app
{{< /text >}}

#### Autenticación de solicitudes

Las políticas de autenticación de solicitudes especifican los valores necesarios para validar un JSON Web
Token (JWT). Estos valores incluyen, entre otros, los siguientes:

- La ubicación del token en la solicitud
- El emisor o la solicitud
- El conjunto de claves públicas de JSON Web (JWKS)

Istio verifica el token presentado, si se presenta, con las reglas de la política de autenticación de solicitudes,
y rechaza las solicitudes con tokens inválidos. Cuando las solicitudes no llevan token, se aceptan por defecto.
Para rechazar solicitudes sin tokens, proporcione reglas de autorización que especifiquen las restricciones para
operaciones específicas, por ejemplo, rutas o acciones.

Las políticas de autenticación de solicitudes pueden especificar más de un JWT si cada uno utiliza una
ubicación única. Cuando más de una política coincide con un workload, Istio combina
todas las reglas como si se hubieran especificado como una única política. Este comportamiento es útil
para programar workloads para que acepten JWT de diferentes proveedores. Sin embargo, las solicitudes
con más de un JWT válido no son compatibles porque el principal de salida de
dichas solicitudes no está definido.

#### Principales

Cuando utiliza políticas de autenticación de pares y mTLS, Istio extrae la
identidad de la autenticación de pares en `source.principal`. De manera similar,
cuando utiliza políticas de autenticación de solicitudes, Istio asigna la identidad del
JWT a `request.auth.principal`. Utilice estos principales para establecer
políticas de autorización y como salida de telemetría.

### Actualización de políticas de autenticación

Puede cambiar una política de autenticación en cualquier momento e Istio envía las nuevas
políticas a los workloads casi en tiempo real. Sin embargo, Istio no puede garantizar
que todos los workloads reciban la nueva política al mismo tiempo. Las siguientes
recomendaciones ayudan a evitar interrupciones al actualizar sus políticas de autenticación:

- Utilice políticas de autenticación de pares intermedias utilizando el modo `PERMISIVO`
  al cambiar el modo de `DISABLE` a `STRICT` y viceversa. Cuando todos
  los workloads cambien con éxito al modo deseado, puede aplicar la política
  con el modo final. Puede usar la telemetría de Istio para verificar que los workloads
  hayan cambiado con éxito.
- Al migrar políticas de autenticación de solicitudes de un JWT a otro, agregue
  la regla para el nuevo JWT a la política sin eliminar la regla antigua.
  Los workloads aceptarán ambos tipos de JWT, y puede eliminar la regla antigua
  cuando todo el tráfico cambie al nuevo JWT. Sin embargo, cada JWT debe usar una
  ubicación diferente.

## Autorización

Las features de autorización de Istio proporcionan control de acceso a nivel de malla, namespace y workload
para sus workloads en la malla. Este nivel de control proporciona
los siguientes beneficios:

- Autorización de workload a workload y de usuario final a workload.
- Una API simple: incluye un único [CRD `AuthorizationPolicy`](/es/docs/reference/config/security/authorization-policy/),
  que es fácil de usar y mantener.
- Semántica flexible: los operadores pueden definir condiciones personalizadas en los atributos de Istio, y usar acciones CUSTOM, DENY y ALLOW.
- Alto rendimiento: la autorización de Istio (`ALLOW` y `DENY`) se aplica de forma nativa en Envoy.
- Alta compatibilidad: admite gRPC, HTTP, HTTPS y HTTP/2 de forma nativa, así como cualquier protocolo TCP simple.

### Arquitectura de autorización

La política de autorización aplica el control de acceso al tráfico entrante en el
proxy Envoy del lado del servidor. Cada proxy Envoy ejecuta un motor de autorización que autoriza las solicitudes en
tiempo de ejecución. Cuando una solicitud llega al proxy, el motor de autorización evalúa
el contexto de la solicitud con las políticas de autorización actuales y devuelve el
resultado de la autorización, ya sea `ALLOW` o `DENY`. Los operadores especifican las políticas de
autorización de Istio utilizando ficheros `.yaml`.

{{< image width="50%"
    link="./authz.svg"
    caption="Arquitectura de Autorización"
    >}}

### Habilitación implícita

No necesita habilitar explícitamente las features de autorización de Istio; están disponibles después de la instalación.
Para aplicar el control de acceso a sus workloads, aplique una política de autorización.

Para los workloads sin políticas de autorización aplicadas, Istio permite todas las solicitudes.

Las políticas de autorización admiten las acciones `ALLOW`, `DENY` y `CUSTOM`. Puede aplicar múltiples políticas, cada una con una
acción diferente, según sea necesario para asegurar el acceso a sus workloads.

Istio verifica las políticas coincidentes en capas, en este orden: `CUSTOM`, `DENY` y luego `ALLOW`. Para cada tipo de acción,
Istio primero verifica si hay una política con la acción aplicada, y luego verifica si la solicitud coincide con la
especificación de la política. Si una solicitud no coincide con una política en una de las capas, la verificación continúa a la siguiente capa.

El siguiente gráfico muestra la precedencia de las políticas en detalle:

{{< image width="50%" link="./authz-eval.svg" caption="Precedencia de la Política de Autorización">}}

Cuando aplica múltiples políticas de autorización al mismo workload, Istio las aplica de forma aditiva.

### Políticas de autorización

Para configurar una política de autorización, cree un
[recurso personalizado `AuthorizationPolicy`](/es/docs/reference/config/security/authorization-policy/).
Una política de autorización incluye un selector, una acción y una lista de reglas:

- El campo `selector` especifica el destino de la política
- El campo `action` especifica si se permite o se deniega la solicitud
- Las `rules` especifican cuándo activar la acción
    - El campo `from` en las `rules` especifica los orígenes de la solicitud
    - El campo `to` en las `rules` especifica las operaciones de la solicitud
    - El campo `when` especifica las condiciones necesarias para aplicar la regla

El siguiente ejemplo muestra una política de autorización que permite a dos orígenes,
la cuenta de service `cluster.local/ns/default/sa/curl` y el namespace `dev`,
acceder a los workloads con las etiquetas `app: httpbin` y `version: v1` en el
namespace `foo` cuando las solicitudes enviadas tienen un token JWT válido.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/curl"]
   - source:
       namespaces: ["dev"]
   to:
   - operation:
       methods: ["GET"]
   when:
   - key: request.auth.claims[iss]
     values: ["https://accounts.google.com"]
{{< /text >}}

El siguiente ejemplo muestra una política de autorización que deniega las solicitudes si el
origen no es el namespace `foo`:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: httpbin-deny
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: DENY
 rules:
 - from:
   - source:
       notNamespaces: ["foo"]
{{< /text >}}

La política de denegación tiene precedencia sobre la política de permiso. Las solicitudes que coinciden con las políticas de permiso
pueden ser denegadas si coinciden con una política de denegación. Istio evalúa las políticas de denegación
primero para asegurar que una política de permiso no pueda eludir una política de denegación.

#### Destino de la política

Puede especificar el ámbito o destino de una política con el
campo `metadata/namespace` y un campo `selector` opcional.
Una política se aplica al namespace en el campo `metadata/namespace`. Si
se establece su valor en el namespace raíz, la política se aplica a todos los namespaces de una
malla. El valor del namespace raíz es configurable, y el predeterminado es
`istio-system`. Si se establece en cualquier otro namespace, la política solo se aplica al
namespace especificado.

Puede usar un campo `selector` para restringir aún más las políticas para que se apliquen a workloads
específicos. El `selector` usa etiquetas para seleccionar el workload de destino. El
selector contiene una lista de pares `{clave: valor}`, donde la `clave` es el nombre de
la etiqueta. Si no se establece, la política de autorización se aplica a todos los workloads en el
mismo namespace que la política de autorización.

Por ejemplo, la política `allow-read` permite el acceso `"GET"` y `"HEAD"` al
workload con la etiqueta `app: products` en el namespace `default`.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-read
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  action: ALLOW
  rules:
  - to:
    - operation:
         methods: ["GET", "HEAD"]
{{< /text >}}

#### Coincidencia de valores

La mayoría de los campos en las políticas de autorización admiten todos los siguientes esquemas de coincidencia:

- Coincidencia exacta: coincidencia de cadena exacta.
- Coincidencia de prefijo: una cadena que termina en `"*"`. Por ejemplo, `"test.abc.*"`
   coincide con `"test.abc.com"`, `"test.abc.com.cn"`, `"test.abc.org"`, etc.
- Coincidencia de sufijo: una cadena que comienza con `"*"`. Por ejemplo, `"*.abc.com"`
   coincide con `"eng.abc.com"`, `"test.eng.abc.com"`, etc.
- Coincidencia de presencia: `*` se usa para especificar cualquier cosa excepto vacío. Para especificar
   que un campo debe estar presente, use el formato `nombre_campo: ["*"]`. Esto es
   diferente de dejar un campo sin especificar, lo que significa que coincide con cualquier cosa,
   incluido vacío.

Hay algunas excepciones. Por ejemplo, los siguientes campos solo admiten coincidencia exacta:

- El campo `key` en la sección `when`
- Los `ipBlocks` en la sección `source`
- El campo `ports` en la sección `to`

La siguiente política de ejemplo permite el acceso a rutas con el prefijo `/test/*`
o el sufijo `*/info`.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: tester
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  action: ALLOW
  rules:
  - to:
    - operation:
        paths: ["/test/*", "*/info"]
{{< /text >}}

#### Coincidencia de exclusión

Para hacer coincidir condiciones negativas como `notValues` en el campo `when`, `notIpBlocks`
en el campo `source`, `notPorts` en el campo `to`, Istio admite la coincidencia de exclusión.
El siguiente ejemplo requiere un principal de solicitud válido, que se deriva de
la autenticación JWT, si la ruta de la solicitud no es `/healthz`. Por lo tanto, la política
excluye las solicitudes a la ruta `/healthz` de la autenticación JWT:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: disable-jwt-for-healthz
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  action: ALLOW
  rules:
  - to:
    - operation:
        notPaths: ["/healthz"]
    from:
    - source:
        requestPrincipals: ["*"]
{{< /text >}}

El siguiente ejemplo deniega la solicitud a la ruta `/admin` para solicitudes
sin principales de solicitud:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: enable-jwt-for-admin
  namespace: default
spec:
  selector:
    matchLabels:
      app: products
  action: DENY
  rules:
  - to:
    - operation:
        paths: ["/admin"]
    from:
    - source:
        notRequestPrincipals: ["*"]
{{< /text >}}

#### Política `allow-nothing`, `deny-all` y `allow-all`

El siguiente ejemplo muestra una política `ALLOW` que no coincide con nada. Si no hay otras políticas `ALLOW`, las solicitudes
siempre serán denegadas debido al comportamiento de "denegar por defecto".

Tenga en cuenta que el comportamiento de "denegar por defecto" solo se aplica si el workload tiene al menos una política de autorización con la acción `ALLOW`.

{{< tip >}}
Es una buena práctica de seguridad comenzar con la política `allow-nothing` y agregar incrementalmente más políticas `ALLOW` para abrir más
acceso al workload.
{{< /tip >}}

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-nothing
spec:
  action: ALLOW
  # el campo rules no está especificado, y la política nunca coincidirá.
{{< /text >}}

El siguiente ejemplo muestra una política `DENY` que deniega explícitamente todo el acceso. Siempre denegará la solicitud incluso si
hay otra política `ALLOW` que permite la solicitud porque la política `DENY` tiene precedencia sobre la política `ALLOW`.
Esto es útil si desea deshabilitar temporalmente todo el acceso al workload.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: deny-all
spec:
  action: DENY
  # el campo rules tiene una regla vacía, y la política siempre coincidirá.
  rules:
  - {}
{{< /text >}}

El siguiente ejemplo muestra una política `ALLOW` que permite el acceso completo al workload. Hará que otras políticas `ALLOW`
sean inútiles ya que siempre permitirá la solicitud. Podría ser útil si desea exponer temporalmente el acceso completo al
workload. Tenga en cuenta que la solicitud aún podría ser denegada debido a las políticas `CUSTOM` y `DENY`.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: allow-all
spec:
  action: ALLOW
  # Esto coincide con todo.
  rules:
  - {}
{{< /text >}}

#### Condiciones personalizadas

También puede usar la sección `when` para especificar condiciones adicionales. Por
ejemplo, la siguiente definición de `AuthorizationPolicy` incluye una condición
de que `request.headers[version]` sea `"v1"` o `"v2"`. En este caso, la
clave es `request.headers[version]`, que es una entrada en el atributo de Istio
`request.headers`, que es un mapa.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/curl"]
   to:
   - operation:
       methods: ["GET"]
   when:
   - key: request.auth.claims[iss]
     values: ["https://accounts.google.com"]
{{< /text >}}

Los valores `key` admitidos de una condición se enumeran en la [página de condiciones](/es/docs/reference/config/security/conditions/).

#### Identidad autenticada y no autenticada

Si desea que un workload sea accesible públicamente, debe dejar la
sección `source` vacía. Esto permite orígenes de todos (tanto autenticados como
no autenticados) usuarios y workloads, por ejemplo:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: ALLOW
 rules:
 - to:
   - operation:
       methods: ["GET", "POST"]
{{< /text >}}

Para permitir solo usuarios autenticados, establezca `principals` en `"*"` en su lugar, por
ejemplo:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["*"]
   to:
   - operation:
       methods: ["GET", "POST"]
{{< /text >}}

### Uso de la autorización de Istio en protocolos TCP simples

La autorización de Istio admite workloads que utilizan cualquier protocolo TCP simple, como
MongoDB. En este caso, se configura la política de autorización de la misma manera
que para los workloads HTTP. La diferencia es que ciertos campos y
condiciones solo son aplicables a los workloads HTTP. Estos campos incluyen:

- El campo `request_principals` en la sección de origen del objeto de política de autorización
- Los campos `hosts`, `methods` y `paths` en la sección de operación del objeto de política de autorización

Las condiciones admitidas se enumeran en la
[página de condiciones](/es/docs/reference/config/security/conditions/).
Si utiliza algún campo solo HTTP para un workload TCP, Istio ignorará los campos solo HTTP
en la política de autorización.

Suponiendo que tiene un service MongoDB en el puerto `27017`, el siguiente ejemplo
configura una política de autorización para permitir que solo el service `bookinfo-ratings-v2`
en la malla de Istio acceda al workload MongoDB.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: mongodb-policy
  namespace: default
spec:
 selector:
   matchLabels:
     app: mongodb
 action: ALLOW
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/bookinfo-ratings-v2"]
   to:
   - operation:
       ports: ["27017"]
{{< /text >}}

### Dependencia de mTLS

Istio utiliza mTLS para pasar de forma segura cierta información del cliente al servidor. mTLS debe estar habilitado antes de
utilizar cualquiera de los siguientes campos en la política de autorización:

- los campos `principals` y `notPrincipals` en la sección `source`
- los campos `namespaces` y `notNamespaces` en la sección `source`
- la condición personalizada `source.principal`
- la condición personalizada `source.namespace`

Tenga en cuenta que se recomienda encarecidamente utilizar siempre estos campos con el modo mTLS **estricto** en `PeerAuthentication` para evitar
posibles rechazos de solicitudes inesperados o elusión de políticas cuando se utiliza tráfico de texto plano con el modo mTLS permisivo.

Consulte el [aviso de seguridad](/news/security/istio-security-2021-004) para obtener más detalles y alternativas si no puede habilitar
el modo mTLS estricto.

## Más información

Después de aprender los conceptos básicos, hay más recursos para revisar:

- Pruebe la política de seguridad siguiendo las tareas de [autenticación](/es/docs/tasks/security/authentication)
  y [autorización](/es/docs/tasks/security/authorization).

- Aprenda algunos [ejemplos de políticas](/es/docs/ops/configuration/security/security-policy-examples) de seguridad que podrían
  utilizarse para mejorar la seguridad en su malla.

- Lea [problemas comunes](/es/docs/ops/common-problems/security-issues/) para solucionar mejor los problemas de políticas de seguridad
  cuando algo sale mal.
