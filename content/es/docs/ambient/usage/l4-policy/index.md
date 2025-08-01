---
title: Usar la política de seguridad de capa 4
description: Características de seguridad compatibles cuando solo se utiliza la superposición segura L4.
weight: 20
owner: istio/wg-networking-maintainers
test: no
---

Las características de capa 4 (L4) de las [políticas de seguridad](/es/docs/concepts/security) de Istio son compatibles con {{< gloss >}}ztunnel{{< /gloss >}}, y están disponibles en el {{< gloss "ambient" >}}modo ambient{{< /gloss >}}. Las [Políticas de Red de Kubernetes](https://kubernetes.io/docs/concepts/services-networking/network-policies/) también continúan funcionando si tu cluster tiene un complemento {{< gloss >}}CNI{{< /gloss >}} que las admita, y se pueden usar para proporcionar defensa en profundidad.

La superposición de ztunnel y los {{< gloss "waypoint" >}}waypoint proxies{{< /gloss >}} te da la opción de habilitar o no el procesamiento de capa 7 (L7) para una carga de trabajo determinada. Para usar las políticas L7 y las características de enrutamiento de tráfico de Istio, puedes [desplegar un waypoint](/es/docs/ambient/usage/waypoint) para tus cargas de trabajo. Debido a que la política ahora se puede aplicar en dos lugares, hay [consideraciones](#considerations) que deben entenderse.

## Aplicación de políticas usando ztunnel

El proxy ztunnel puede realizar la aplicación de políticas de autorización cuando una carga de trabajo está inscrita en el modo de {{< gloss "Secure L4 Overlay" >}}superposición segura{{< /gloss >}}. El punto de aplicación es el proxy ztunnel receptor (del lado del servidor) en la ruta de una conexión.

Una política de autorización L4 básica se ve así:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: allow-curl-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/curl
{{< /text >}}

Esta política se puede usar tanto en el modo {{< gloss "sidecar" >}}sidecar{{< /gloss >}} como en el modo ambient.

Las características L4 (TCP) de la API `AuthorizationPolicy` de Istio tienen el mismo comportamiento funcional en el modo ambient que en el modo sidecar. Cuando no hay una política de autorización aprovisionada, la acción predeterminada es `ALLOW`. Una vez que se aprovisiona una política, los pods a los que se dirige la política solo permiten el tráfico que se permite explícitamente. En el ejemplo anterior, los pods con la etiqueta `app: httpbin` solo permiten el tráfico de fuentes con una identidad principal de `cluster.local/ns/ambient-demo/sa/curl`. El tráfico de todas las demás fuentes será denegado.

## Políticas de segmentación

El modo sidecar y las políticas L4 en ambient se *segmentan* de la misma manera: están delimitadas por el namespace en el que reside el objeto de la política y un `selector` opcional en la `spec`. Si la política está en el namespace raíz de Istio (tradicionalmente `istio-system`), entonces se dirigirá a todos los namespaces. Si está en cualquier otro namespace, se dirigirá solo a ese namespace.

Las políticas L7 en modo ambient son aplicadas por los waypoints, que se configuran con la {{< gloss "gateway api" >}}API de Gateway de Kubernetes{{< /gloss >}}. Se *adjuntan* usando el campo `targetRef`.

## Atributos de política permitidos

Las reglas de la política de autorización pueden contener cláusulas de [origen](/es/docs/reference/config/security/authorization-policy/#Source) (`from`), [operación](/es/docs/reference/config/security/authorization-policy/#Operation) (`to`) y [condición](/es/docs/reference/config/security/authorization-policy/#Condition) (`when`).

Esta lista de atributos determina si una política se considera solo L4:

| Tipo | Atributo | Coincidencia positiva | Coincidencia negativa |
| --- | --- | --- | --- |
| Origen | Identidad del par | `principals` | `notPrincipals` |
| Origen | namespace | `namespaces` | `notNamespaces` |
| Origen | Bloque de IP | `ipBlocks` | `notIpBlocks` |
| Operación | Puerto de destino | `ports` | `notPorts` |
| Condición | IP de origen | `source.ip` | n/a |
| Condición | namespace de origen | `source.namespace` | n/a |
| Condición | Identidad de origen | `source.principal` | n/a |
| Condición | IP remota | `destination.ip` | n/a |
| Condición | Puerto remoto | `destination.port` | n/a |

### Políticas con condiciones de capa 7

El ztunnel no puede aplicar políticas L7. Si una política con reglas que coinciden con los atributos L7 (es decir, los que no se enumeran en la tabla anterior) se dirige de tal manera que será aplicada por un ztunnel receptor, fallará de forma segura al convertirse en una política de `DENEGACIÓN`.

Este ejemplo agrega una verificación para el método HTTP GET:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
 name: allow-curl-to-httpbin
spec:
 selector:
   matchLabels:
     app: httpbin
 action: ALLOW
 rules:
 - from:
   - source:
       principals:
       - cluster.local/ns/ambient-demo/sa/curl
   to:
   - operation:
       methods: ["GET"]
{{< /text >}}

Incluso si la identidad del pod cliente es correcta, la presencia de un atributo L7 hace que el ztunnel deniegue la conexión:

{{< text plain >}}
command terminated with exit code 56
{{< /text >}}

## Elección de puntos de aplicación cuando se introducen waypoints {#considerations}

Cuando se agrega un proxy de waypoint a una carga de trabajo, ahora tienes dos lugares posibles donde puedes aplicar la política L4. (La política L7 solo se puede aplicar en el proxy de waypoint).

Con solo la superposición segura, el tráfico aparece en el ztunnel de destino con la identidad de la carga de trabajo de *origen*.

Los proxies de waypoint no se hacen pasar por la identidad de la carga de trabajo de origen. Una vez que has introducido un waypoint en la ruta del tráfico, el ztunnel de destino verá el tráfico con la identidad del *waypoint*, no con la identidad de origen.

Esto significa que cuando tienes un waypoint instalado, **el lugar ideal para aplicar la política cambia**. Incluso si solo deseas aplicar la política contra los atributos L4, si dependes de la identidad de origen, debes adjuntar tu política a tu proxy de waypoint. Se puede dirigir una segunda política a tu carga de trabajo para que su ztunnel aplique políticas como "el tráfico dentro de la mesh debe provenir de mi waypoint para llegar a mi aplicación".

## Autenticación de pares

Las [políticas de autenticación de pares](/es/docs/concepts/security/#peer-authentication) de Istio, que configuran los modos de TLS mutuo (mTLS), son compatibles con ztunnel.

La política predeterminada para el modo ambient es `PERMISSIVE`, que permite que los pods acepten tanto el tráfico cifrado con mTLS (desde dentro de la mesh) como el tráfico de texto sin formato (desde fuera). Habilitar el modo `STRICT` significa que los pods solo aceptarán tráfico cifrado con mTLS.

Como ztunnel y {{< gloss >}}HBONE{{< /gloss >}} implican el uso de mTLS, no es posible usar el modo `DISABLE` en una política. Dichas políticas serán ignoradas.
