---
title: "Simplificando el enrutamiento de tráfico de salida hacia destinos con comodines"
description: "Istio ahora soporta ServiceEntry con comodines y resolución DYNAMIC_DNS, permitiendo a los sidecars enrutar tráfico directamente a destinos HTTPS con comodines y simplificando la configuración de egress."
publishdate: 2026-04-09
attribution: "Rudrakh Panigrahi (Salesforce)"
keywords: [traffic-management,gateway,mesh,egress,wildcard,service-entry,ambient,waypoint]
---

## Descripción general

Controlar el tráfico de salida es un requisito habitual en los despliegues de service mesh. Muchas organizaciones configuran su mesh para permitir solo los servicios externos explícitamente registrados mediante:

{{< text plain >}}
meshConfig.outboundTrafficPolicy.mode = REGISTRY_ONLY
{{< /text >}}

Con esta configuración, cualquier destino externo debe registrarse en la mesh usando recursos como `ServiceEntry` con nombres de dominio completamente cualificados y un tipo de resolución DNS.

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-wikipedia-https
  namespace: istio-system
spec:
  hosts:
  - "www.wikipedia.org"
  ports:
  - name: tls
    number: 443
    protocol: TLS
  location: MESH_EXTERNAL
  resolution: DNS
  exportTo:
  - "*"
{{< /text >}}

Sin embargo, algunos servicios externos exponen muchos subdominios dinámicos donde las aplicaciones pueden necesitar acceder a endpoints como:

{{< text plain >}}
https://en.wikipedia.org
https://de.wikipedia.org
https://upload.wikipedia.org
{{< /text >}}

A medida que crece la lista de nombres de host, registrar cada uno individualmente se vuelve rápidamente impráctico de gestionar y escalar. Para abordar esto, Istio necesita soporte para el registro de nombres de host con comodines.

## Por qué el egress HTTPS con comodines es difícil

Cuando un workload inicia una conexión HTTPS, el nombre de host de destino se transmite en el handshake TLS mediante el campo **Server Name Indication (SNI)**.

Por ejemplo, un cliente que llama a `https://en.wikipedia.org` envía el hostname `en.wikipedia.org` en el campo SNI del ClientHello durante el handshake TLS. Los sidecars de Istio interceptan las conexiones salientes y determinan si el destino está registrado y cómo debe enrutarse.

Sin embargo, el modelo de enrutamiento de Istio normalmente requiere que el destino upstream sea conocido de antemano. Incluso si se usa una coincidencia de comodín en las reglas de enrutamiento, el clúster upstream final aún debe corresponder a un servicio configurado estáticamente. Dado que distintos subdominios pueden resolver a diferentes endpoints, el enrutamiento directo a hosts con comodines históricamente no era sencillo.

## Enrutamiento SNI a través del Egress Gateway

Este problema se abordó anteriormente en la publicación del blog de Istio [Routing egress traffic to wildcard destinations](/blog/2023/egress-sni/). La arquitectura incluía un egress gateway dedicado que funcionaba como proxy de reenvío SNI.

{{< image width="90%" link="./egress-sni-flow.svg" alt="Enrutamiento SNI de egress con nombres de dominio arbitrarios" title="Enrutamiento SNI de egress con nombres de dominio arbitrarios" caption="Aplicación → sidecar → egress gateway → inspección SNI → destino externo" >}}

El diagrama anterior se publicó originalmente en [Routing egress traffic to wildcard destinations](/blog/2023/egress-sni/).

Como se muestra arriba:

1. La aplicación inicia una conexión HTTPS.
1. El proxy sidecar intercepta esta conexión e inicia una conexión mTLS interna al egress gateway.
1. El gateway termina esta conexión mTLS interna.
1. Un listener interno inspecciona el valor SNI del handshake TLS original.
1. El tráfico se reenvía dinámicamente al hostname extraído del SNI.

Implementar esto requería varios recursos personalizados:

* `ServiceEntry` y `VirtualService` para reenviar el tráfico de dominio con comodines al egress gateway.
* `DestinationRule` para mTLS entre sidecars y el gateway.
* Configuración de `EnvoyFilter` que permite al egress gateway realizar el reenvío SNI dinámico, con diferencia la parte más compleja de esta solución. El filtro extiende el gateway usando capacidades de Envoy de bajo nivel introduciendo tres componentes: un **parche al TCP proxy del gateway** que enruta el tráfico a un listener interno, un **inspector SNI en el listener** para extraer el SNI del ClientHello TLS, y un **clúster de proxy de reenvío dinámico** para realizar la resolución DNS dinámica del SNI.

Aunque este enfoque funciona, introduce un salto de red adicional y una capa extra de mTLS interno para ese salto. También añade complejidad operativa debido a la cantidad de configuración personalizada requerida, lo que puede ser difícil de gestionar y propenso a errores. Pero las mejoras recientes permiten lograr el mismo resultado con una configuración mucho más sencilla.

## `ServiceEntry` con comodines y resolución `DYNAMIC_DNS`

Istio ahora soporta nombres de host con comodines y resolución `DYNAMIC_DNS` en `ServiceEntry`, lo que permite a los proxies sidecar enrutar tráfico TLS saliente con comodines directamente sin necesidad de un egress gateway.

Por ejemplo, la siguiente configuración permite el acceso a todos los endpoints `*.wikipedia.org`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: external-wildcard-https
  namespace: istio-system
spec:
  hosts:
  - "*.wikipedia.org"
  ports:
  - name: tls
    number: 443
    protocol: TLS
  location: MESH_EXTERNAL
  resolution: DYNAMIC_DNS
  exportTo:
  - "*"
{{< /text >}}

Una vez aplicado este recurso, los workloads de la mesh pueden conectarse a cualquier subdominio coincidente a través de este ServiceEntry.

{{< text bash >}}
$ kubectl exec $POD_NAME -n default -c ratings -- curl -sS -o /dev/null -w "HTTP %{http_code}\n" https://de.wikipedia.org && echo "Checking stats after request..." && kubectl exec $POD_NAME -c istio-proxy -- curl -s localhost:15000/clusters | grep "outbound|443||\*\.wikipedia\.org" | grep -E "rq|cx"

HTTP 200
Checking stats after request...
outbound|443||*.wikipedia.org::142.251.223.228:443::cx_active::0
outbound|443||*.wikipedia.org::142.251.223.228:443::cx_connect_fail::0
outbound|443||*.wikipedia.org::142.251.223.228:443::cx_total::3
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_active::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_error::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_success::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_timeout::0
outbound|443||*.wikipedia.org::142.251.223.228:443::rq_total::3
{{< /text >}}

### Cómo funciona la configuración

{{< image width="90%" link="./egress-dynamic-dns.svg" alt="ServiceEntry con comodines y resolución DYNAMIC_DNS" title="ServiceEntry con comodines y resolución DYNAMIC_DNS" caption="Aplicación → sidecar → destino externo" >}}

Un `ServiceEntry` con comodines y `resolution: DYNAMIC_DNS` hace que Istio cree un clúster de [proxy de reenvío dinámico (DFP)](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/clusters/dynamic_forward_proxy/v3/cluster.proto#envoy-v3-api-msg-extensions-clusters-dynamic-forward-proxy-v3-clusterconfig) que reenvía las conexiones TLS basándose en el hostname del campo SNI. El host con comodines (por ejemplo, `*.wikipedia.org`) se registra primero en el registro de servicios de la mesh, lo que permite al sidecar enrutar las solicitudes salientes con hostnames que coincidan con el patrón. Cuando un workload inicia una conexión TLS, el Inspector SNI en el listener se configura para leer el valor SNI del handshake. El clúster DFP lo usa entonces como hostname upstream para reenviar la conexión. Esto habilita eficazmente el egress HTTPS con comodines al permitir que el proxy resuelva y reenvíe dinámicamente conexiones a subdominios coincidentes sin necesidad de configuración estática de endpoints. Al mismo tiempo, preserva la sesión TLS iniciada por el cliente, reenviando el tráfico cifrado sin modificar.

## Otros casos de uso

Este enfoque es apropiado para casos de uso donde las aplicaciones necesitan conectividad a dominios con comodines mientras mantienen las características de observabilidad y resiliencia de la mesh.

### Tráfico de egress en modo Ambient

En la [mesh en modo ambient](/docs/ambient/overview/), el ztunnel a nivel de nodo maneja el tráfico L4, y un [waypoint proxy](/docs/ambient/usage/waypoint/) opcional puede aplicar políticas L7 y telemetría cuando se adjunta explícitamente. Para manejar el egress a través de un waypoint, por ejemplo para mantener un path de política consistente para llamadas a muchos endpoints de servicios de AWS, el `ServiceEntry` puede etiquetarse con `istio.io/use-waypoint` para que el control plane dirija el tráfico coincidente a través del Gateway `waypoint` nombrado.

El ejemplo siguiente registra `*.amazonaws.com` como un ServiceEntry TLS externo (en el puerto `443`) y lo asocia a un waypoint gateway llamado `waypoint`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: amazonaws-wildcard
  namespace: istio-system
  labels:
    istio.io/use-waypoint: waypoint # asociado a un waypoint gateway
spec:
  exportTo:
  - .
  hosts:
  - '*.amazonaws.com'
  location: MESH_EXTERNAL
  ports:
  - name: tls
    number: 443
    protocol: TLS
  resolution: DYNAMIC_DNS
{{< /text >}}

### Tráfico hacia destinos internos desconocidos

Un cliente puede tener solo un número limitado de servicios en su configuración pero aún necesitar conectividad mTLS a otros servicios internos. La configuración es:

* Un recurso `Sidecar` que limita los hosts de egress del servicio ratings al namespace `istio-system`, es decir, no puede llamar directamente al servicio details:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Sidecar
metadata:
  name: restrict-default
  namespace: default
spec:
  workloadSelector:
    labels:
      app: ratings
  egress:
  - hosts:
    - "istio-system/*"
{{< /text >}}

* `ServiceEntry` que define un servicio con comodines para otros servicios internos:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: internal-wildcard-http
  namespace: istio-system
spec:
  hosts:
  - "*.svc.cluster.local"
  ports:
  - name: http
    number: 9080
    protocol: HTTP
  location: MESH_INTERNAL
  resolution: DYNAMIC_DNS
  exportTo:
  - "*"
{{< /text >}}

* `DestinationRule` que define la configuración mTLS para este `ServiceEntry`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: internal-wildcard-dr
  namespace: istio-system
spec:
  host: "*.svc.cluster.local"
  trafficPolicy:
    tls:
      mode: MUTUAL_TLS # requiere SAN DNS en el certificado
  exportTo:
  - "*"
{{< /text >}}

El servicio ratings puede ahora llamar a otros servicios de la mesh, aunque no los tenga en su configuración, resolviendo el hostname dinámicamente usando DNS:

{{< text bash >}}
$ kubectl exec $POD_NAME -n default -c ratings -- curl -sS -o /dev/null -w "HTTP %{http_code}\n" details.default.svc.cluster.local:9080/details/0 && echo "Checking stats after request..." && kubectl exec $POD_NAME -c istio-proxy -- curl -s localhost:15000/clusters | grep "outbound|9080||\*\.svc\.cluster\.local" | grep -E "rq_total|rq_success"

Making test request...
HTTP 200
Checking stats after request...
outbound|9080||*.svc.cluster.local::10.96.35.238:9080::rq_success::1
outbound|9080||*.svc.cluster.local::10.96.35.238:9080::rq_total::1
{{< /text >}}

Nota: mTLS en este caso de uso necesita que los certificados tengan SANs DNS, ya que el proxy de reenvío dinámico de Envoy aprovecha el hostname para realizar la validación automática de SAN.

## Conclusión

Los proxies sidecar de Istio ahora pueden manejar directamente el tráfico de egress HTTP y TLS hacia dominios con comodines gracias a la introducción del soporte de `ServiceEntry` con comodines y resolución `DYNAMIC_DNS`. Esto permite una configuración más sencilla y un path de solicitud más directo, reduciendo la latencia al eliminar la necesidad de un salto intermedio por el egress gateway, mientras se preservan los controles de seguridad y políticas existentes.

## Referencias

* [Routing egress traffic to wildcard destinations](/blog/2023/egress-sni/)
* [SNI dynamic forward proxy - Documentación de Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/listeners/network_filters/sni_dynamic_forward_proxy_filter)
* [HTTP dynamic forward proxy - Documentación de Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http/http_proxy#arch-overview-http-dynamic-forward-proxy)
