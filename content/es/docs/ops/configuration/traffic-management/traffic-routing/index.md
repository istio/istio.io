---
title: Entender el enrutamiento de tráfico
linktitle: Enrutamiento de tráfico
description: Cómo enruta Istio el tráfico a través de la mesh.
weight: 30
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers
test: n/a
---

Uno de los objetivos de Istio es actuar como un "proxy transparente" que se puede incorporar a un clúster existente y que permite que el tráfico siga fluyendo como antes.
Sin embargo, gracias a funcionalidades adicionales como el balanceo de carga por solicitud, Istio ofrece formas potentes de gestionar el tráfico de manera distinta a un clúster de Kubernetes típico.
Para entender lo que ocurre en tu mesh, es importante comprender cómo enruta Istio el tráfico.

{{< warning >}}
Este documento describe detalles de implementación de bajo nivel. Para una visión general de más alto nivel, consulta los [Conceptos](/es/docs/concepts/traffic-management/) o las [Tareas](/es/docs/tasks/traffic-management/) de gestión de tráfico.
{{< /warning >}}

## Frontends y backends {#frontends-and-backends}

En el enrutamiento de tráfico de Istio hay dos fases principales:

* El "frontend" se refiere a cómo identificamos el tipo de tráfico que estamos gestionando.
  Esto es necesario para identificar a qué backend enrutar el tráfico y qué políticas aplicar.
  Por ejemplo, podemos leer el encabezado `Host` con el valor `http.ns.svc.cluster.local` e identificar que la solicitud está destinada al Service `http`.
  Más abajo encontrarás más información sobre cómo funciona esta coincidencia.
* El "backend" se refiere a dónde enviamos el tráfico una vez identificado.
  Siguiendo el ejemplo anterior, después de identificar que la solicitud va dirigida al Service `http`, la enviaríamos a un endpoint de ese Service.
  Sin embargo, esta selección no siempre es tan sencilla; Istio permite personalizar esta lógica mediante reglas de enrutamiento de `VirtualService`.

Las redes estándar de Kubernetes también tienen estos mismos conceptos, pero son mucho más simples y, por lo general, quedan ocultos.
Cuando se crea un `Service`, normalmente tiene asociado un frontend: el nombre DNS creado automáticamente (como `http.ns.svc.cluster.local`)
y una dirección IP creada automáticamente para representar el servicio (la `ClusterIP`).
Del mismo modo, también se crea un backend (los `Endpoints` o `EndpointSlice`), que representa todos los pods seleccionados por el servicio.

## Protocolos {#protocols}

A diferencia de Kubernetes, Istio puede procesar protocolos de nivel de aplicación como HTTP y TLS.
Esto permite tipos de coincidencia de [frontend](#frontends-and-backends) distintos de los disponibles en Kubernetes.

En general, Istio entiende tres clases de protocolos:

* HTTP, que incluye HTTP/1.1, HTTP/2 y gRPC. Ten en cuenta que no incluye el tráfico cifrado con TLS (HTTPS).
* TLS, que incluye HTTPS.
* Bytes TCP sin procesar.

El documento sobre [selección de protocolo](/es/docs/ops/configuration/traffic-management/protocol-selection/) describe cómo decide Istio qué protocolo se usa.

El uso de "TCP" puede resultar confuso, ya que en otros contextos se usa para distinguirlo de otros protocolos L4, como UDP.
Cuando hablamos del protocolo TCP en Istio, normalmente queremos decir que lo tratamos como un flujo de bytes sin procesar
y que no analizamos protocolos de nivel de aplicación como TLS o HTTP.

## Enrutamiento de tráfico {#traffic-routing}

Cuando un proxy Envoy recibe una solicitud, debe decidir adónde reenviarla, si es que debe reenviarla a algún sitio.
Por defecto, la reenvía al servicio original solicitado, a menos que se haya [personalizado](/es/docs/tasks/traffic-management/traffic-shifting/).
Cómo funciona esto depende del protocolo usado.

### TCP

Al procesar tráfico TCP, Istio tiene muy poca información útil para enrutar la conexión: solo la IP y el puerto de destino.
Estos atributos se usan para determinar el Service previsto; el proxy se configura para escuchar en cada par de IP y puerto de servicio (`<Kubernetes ClusterIP>:<Port>`) y reenviar el tráfico al servicio upstream.

Para personalizarlo, se puede configurar un `VirtualService` TCP, que permite [hacer coincidir IPs y puertos específicos](/es/docs/reference/config/networking/virtual-service/#L4MatchAttributes) y enrutar el tráfico a servicios upstream distintos de los solicitados.

### TLS

Al procesar tráfico TLS, Istio tiene algo más de información disponible que con TCP sin procesar: podemos inspeccionar el campo [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) que se presenta durante el handshake de TLS.

Para los Services estándar, se usa la misma coincidencia por IP:puerto que para TCP sin procesar.
Sin embargo, para los servicios que no tienen definida una IP de Service, como los [servicios ExternalName](#externalname-services), se usa el campo SNI para el enrutamiento.

Además, se puede configurar un enrutamiento personalizado con un `VirtualService` TLS para [hacer coincidir el SNI](/es/docs/reference/config/networking/virtual-service/#TLSMatchAttributes) y enrutar las solicitudes a destinos personalizados.

### HTTP

HTTP permite un enrutamiento mucho más completo que TCP y TLS. Con HTTP, puedes enrutar solicitudes HTTP individuales, en lugar de solo conexiones.
Además, hay disponible una [gran variedad de atributos](/es/docs/reference/config/networking/virtual-service/#HTTPMatchRequest), como el host, la ruta, los encabezados, los parámetros de consulta, etc.

Aunque el tráfico TCP y TLS suele comportarse igual con o sin Istio (suponiendo que no se haya aplicado ninguna configuración para personalizar el enrutamiento), HTTP presenta diferencias importantes.

* Istio balancea la carga de las solicitudes individuales. En general, esto es muy deseable, especialmente en escenarios con conexiones de larga duración, como gRPC y HTTP/2, en los que el balanceo de carga a nivel de conexión no es eficaz.
* Las solicitudes se enrutan según el puerto y el *encabezado `Host`*, en lugar de según el puerto y la IP. Esto significa que, en la práctica, se ignora la dirección IP de destino. Por ejemplo, `curl 8.8.8.8 -H "Host: productpage.default.svc.cluster.local"` se enrutaría al Service `productpage`.

## Tráfico sin coincidencia {#unmatched-traffic}

Si el tráfico no se puede identificar con ninguno de los métodos descritos anteriormente, se trata como [tráfico passthrough](/es/docs/tasks/traffic-management/egress/egress-control/#envoy-passthrough-to-external-services).
Por defecto, estas solicitudes se reenvían tal cual, lo que garantiza que el tráfico hacia servicios que Istio no conoce (como servicios externos para los que no se han creado `ServiceEntry`s) siga funcionando.
Ten en cuenta que, cuando se reenvían estas solicitudes, no se usa TLS mutuo y la recopilación de telemetría es limitada.

## Tipos de servicios {#service-types}

Además de los Services `ClusterIP` estándar, Istio admite toda la gama de Services de Kubernetes, con algunas salvedades.

### Services `LoadBalancer` y `NodePort` {#loadbalancer-and-nodeport-services}

Estos Services son superconjuntos de los Services `ClusterIP` y su objetivo principal es permitir el acceso desde clientes externos.
Estos tipos de servicio son compatibles y se comportan exactamente igual que los Services `ClusterIP` estándar.

### Services headless {#headless-services}

Un [Service headless](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services) es un Service que no tiene asignada una `ClusterIP`.
En su lugar, la respuesta DNS contiene las direcciones IP de cada endpoint (es decir, la IP del Pod) que forma parte del Service.

En general, Istio no configura listeners para cada IP de Pod, ya que trabaja a nivel de Service.
Sin embargo, para admitir los servicios headless, se configuran listeners para cada par IP:puerto del servicio headless.
Una excepción son los protocolos declarados como HTTP, que identifican el tráfico por el encabezado `Host`.

{{< warning >}}
Sin Istio, el campo `ports` de un servicio headless no es estrictamente necesario, porque las solicitudes van directamente a las IPs de los pods, que pueden aceptar tráfico en todos los puertos.
Sin embargo, con Istio el puerto debe declararse en el Service; de lo contrario, [no habrá coincidencia](/es/docs/ops/configuration/traffic-management/traffic-routing/#unmatched-traffic).
{{< /warning >}}

### Services ExternalName {#externalname-services}

Un [Service ExternalName](https://kubernetes.io/docs/concepts/services-networking/service/#externalname) es, básicamente, solo un alias de DNS.

Para concretar, considera el siguiente ejemplo:

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: alias
spec:
  type: ExternalName
  externalName: concrete.example.com
{{< /text >}}

Como no hay `ClusterIP` ni IPs de pods con las que hacer coincidir el tráfico, para el tráfico TCP no cambia nada en la forma en que Istio lo identifica.
Cuando Istio recibe la solicitud, ve la IP de `concrete.example.com`.
Si es un servicio que Istio conoce, se enruta como se describe [más arriba](#tcp).
Si no, se gestiona como [tráfico sin coincidencia](#unmatched-traffic)

Para HTTP y TLS, que hacen la coincidencia por nombre de host, las cosas son un poco distintas.
Si el servicio de destino (`concrete.example.com`) es un servicio que Istio conoce, el nombre de host del alias (`alias.default.svc.cluster.local`) se agrega
como una coincidencia _adicional_ a la coincidencia de [TLS](#tls) o [HTTP](#http).
Si no, no hay cambios, por lo que se gestiona como [tráfico sin coincidencia](#unmatched-traffic).

Un servicio `ExternalName` nunca puede ser un [backend](#frontends-and-backends) por sí solo.
En cambio, solo se usa como coincidencia adicional de [frontend](#frontends-and-backends) para Services existentes.
Si se usa explícitamente como backend, por ejemplo como destino de un `VirtualService`, se aplica el mismo alias.
Es decir, si `alias.default.svc.cluster.local` se configura como destino, las solicitudes irán a `concrete.example.com`.
Si Istio no conoce ese nombre de host, las solicitudes fallarán; en ese caso, un `ServiceEntry` para `concrete.example.com` haría que esta configuración funcione.

### ServiceEntry

Además de los Services de Kubernetes, se pueden crear [service entries](/es/docs/reference/config/networking/service-entry/#ServiceEntry) para ampliar el conjunto de servicios que Istio conoce.
Esto puede ser útil para garantizar que el tráfico hacia servicios externos, como `example.com`, obtenga la funcionalidad de Istio.

Un ServiceEntry con `addresses` configurado enruta igual que un Service `ClusterIP`.

Sin embargo, en los service entries sin `addresses`, se hace coincidir el tráfico de todas las IPs en ese puerto.
Esto puede impedir que el [tráfico sin coincidencia](#unmatched-traffic) en el mismo puerto se reenvíe correctamente.
Por eso, es mejor evitarlos siempre que sea posible, o usar puertos dedicados cuando sea necesario.
HTTP y TLS no tienen esta restricción, ya que el enrutamiento se hace según el nombre de host o el SNI.

{{< tip >}}
El campo `addresses` y el campo `endpoints` se confunden a menudo.
`addresses` se refiere a las IPs con las que se hará la coincidencia, mientras que endpoints se refiere al conjunto de IPs a las que enviaremos el tráfico.

Por ejemplo, el service entry siguiente haría coincidir el tráfico para `1.1.1.1` y enviaría la solicitud a `2.2.2.2` y `3.3.3.3` según la política de balanceo de carga configurada:

{{< text yaml >}}
addresses: [1.1.1.1]
resolution: STATIC
endpoints:
- address: 2.2.2.2
- address: 3.3.3.3
{{< /text  >}}

{{< /tip >}}
