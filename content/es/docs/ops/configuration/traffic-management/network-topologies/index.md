---
title: Configurar la topología de red de los gateways
description: Cómo configurar la topología de red de los gateways.
weight: 60
keywords: [traffic-management,ingress,gateway]
owner: istio/wg-networking-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

{{< boilerplate gateway-api-support >}}

## Reenviar atributos del cliente externo (dirección IP, información del certificado) a los workloads de destino {#forwarding-external-client-attributes-ip-address-certificate-info-to-destination-workloads}

Muchas aplicaciones necesitan conocer la dirección IP del cliente y la información del certificado de la solicitud original para funcionar
correctamente. Entre los casos más destacados están las herramientas de registro y auditoría, que necesitan que se complete la IP del cliente, y las herramientas de seguridad,
como los firewalls de aplicaciones web (WAF), que necesitan esta información para aplicar correctamente sus conjuntos de reglas. La capacidad de
proporcionar atributos del cliente a los servicios es desde hace tiempo una función básica de los proxies inversos. Para reenviar estos atributos
del cliente a los workloads de destino, los proxies usan los encabezados `X-Forwarded-For` (XFF) y `X-Forwarded-Client-Cert` (XFCC).

Las redes actuales son muy diversas, pero el soporte de estos atributos es un requisito sea cual sea la topología de red.
Esta información debe conservarse
y reenviarse tanto si la red usa balanceadores de carga en la nube como balanceadores de carga locales (on-premise), gateways
expuestos directamente a internet, gateways que atienden a muchos proxies intermedios u otras topologías de despliegue no
especificadas.

Aunque Istio proporciona un [ingress gateway](/es/docs/tasks/traffic-management/ingress/ingress-control/), dada la variedad
de arquitecturas mencionadas, no es posible incluir valores predeterminados razonables que permitan reenviar correctamente
los atributos del cliente a los workloads de destino.
Esto es cada vez más importante a medida que los modelos de despliegue multiclúster de Istio se vuelven más comunes.

Para más información sobre `X-Forwarded-For`, consulta el [RFC](https://tools.ietf.org/html/rfc7239) del IETF.

## Configurar topologías de red {#configuring-network-topologies}

Los encabezados XFF y XFCC se pueden configurar de forma global para todos los workloads de gateway mediante `MeshConfig`, o por gateway mediante
una anotación del pod. Por ejemplo, para configurarlos de forma global durante la instalación o la actualización con un recurso personalizado `IstioOperator`:

{{< text syntax=yaml snip_id=none >}}
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        numTrustedProxies: <VALUE>
        forwardClientCertDetails: <ENUM_VALUE>
{{< /text >}}

También puedes configurar ambos ajustes agregando la anotación `proxy.istio.io/config` a la especificación del Pod
de tu Istio ingress gateway.

{{< text syntax=yaml snip_id=none >}}
...
  metadata:
    annotations:
      "proxy.istio.io/config": '{"gatewayTopology" : { "numTrustedProxies": <VALUE>, "forwardClientCertDetails": <ENUM_VALUE> } }'
{{< /text >}}

### Configurar los encabezados X-Forwarded-For {#configuring-x-forwarded-for-headers}

Las aplicaciones dependen de los proxies inversos para reenviar los atributos del cliente en una solicitud, como el encabezado `X-Forward-For`. Sin embargo, debido a la variedad de topologías
de red en las que se puede desplegar Istio, debes configurar `numTrustedProxies` con el número de proxies de confianza desplegados delante
del proxy del gateway de Istio, para que la dirección del cliente se pueda extraer correctamente.
Esto controla el valor que el ingress gateway coloca en el encabezado `X-Envoy-External-Address`,
que los servicios upstream pueden usar de forma fiable para obtener la dirección IP original del cliente.

Por ejemplo, si tienes un balanceador de carga en la nube y un proxy inverso delante de tu gateway de Istio, configura `numTrustedProxies` en `2`.

{{< idea >}}
Ten en cuenta que todos los proxies que estén delante del proxy del gateway de Istio deben analizar el tráfico HTTP y agregar datos al encabezado `X-Forwarded-For`
en cada salto. Si el número de entradas del encabezado `X-Forwarded-For` es menor que el número de
saltos de confianza configurados, Envoy recurre a la dirección downstream inmediata como dirección de cliente
de confianza. Consulta la [documentación de Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-for)
para entender cómo se determinan los encabezados `X-Forwarded-For` y las direcciones de cliente de confianza.
{{< /idea >}}

#### Ejemplo de uso de la funcionalidad X-Forwarded-For con httpbin {#example-using-x-forwarded-for-capability-with-httpbin}

1. Ejecuta el siguiente comando para crear un archivo llamado `topology.yaml` con `numTrustedProxies` configurado en `2` e instalar Istio:

    {{< text syntax=bash snip_id=install_num_trusted_proxies_two >}}
    $ cat <<EOF > topology.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        defaultConfig:
          gatewayTopology:
            numTrustedProxies: 2
    EOF
    $ istioctl install -f topology.yaml
    {{< /text >}}

    {{< idea >}}
    Si ya habías instalado un Istio ingress gateway, reinicia todos los pods del ingress gateway después del paso 1.
    {{</ idea >}}

1. Crea un namespace `httpbin`:

    {{< text syntax=bash snip_id=create_httpbin_namespace >}}
    $ kubectl create namespace httpbin
    namespace/httpbin created
    {{< /text >}}

1. Configura la etiqueta `istio-injection` con el valor `enabled` para la inyección de sidecars:

    {{< text syntax=bash snip_id=label_httpbin_namespace >}}
    $ kubectl label --overwrite namespace httpbin istio-injection=enabled
    namespace/httpbin labeled
    {{< /text >}}

1. Despliega `httpbin` en el namespace `httpbin`:

    {{< text syntax=bash snip_id=apply_httpbin >}}
    $ kubectl apply -n httpbin -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

1. Despliega un gateway asociado a `httpbin`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=deploy_httpbin_gateway >}}
$ kubectl apply -n httpbin -f @samples/httpbin/httpbin-gateway.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=deploy_httpbin_k8s_gateway >}}
$ kubectl apply -n httpbin -f @samples/httpbin/gateway-api/httpbin-gateway.yaml@
$ kubectl wait --for=condition=programmed gtw -n httpbin httpbin-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

6) Configura una variable de entorno local `GATEWAY_URL` basada en la dirección IP de tu Istio ingress gateway:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=export_gateway_url >}}
$ export GATEWAY_URL=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=export_k8s_gateway_url >}}
$ export GATEWAY_URL=$(kubectl get gateways.gateway.networking.k8s.io httpbin-gateway -n httpbin -ojsonpath='{.status.addresses[0].value}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7) Ejecuta el siguiente comando `curl` para simular una solicitud con direcciones de proxies en el encabezado `X-Forwarded-For`:

    {{< text syntax=bash snip_id=curl_xff_headers >}}
    $ curl -s -H 'X-Forwarded-For: 56.5.6.7, 72.9.5.6, 98.1.2.3' "$GATEWAY_URL/get?show_env=true" | jq '.headers["X-Forwarded-For"][0]'
      "56.5.6.7, 72.9.5.6, 98.1.2.3,10.244.0.1"
    {{< /text >}}

{{< tip >}}
En el ejemplo anterior, `$GATEWAY_URL` se resolvió como 10.244.0.1. En tu entorno no será así.
{{< /tip >}}

La salida anterior muestra los encabezados de la solicitud que recibió el workload `httpbin`. Cuando el gateway de Istio recibió esta
solicitud, configuró el encabezado `X-Envoy-External-Address` con la penúltima dirección (`numTrustedProxies: 2`) del
encabezado `X-Forwarded-For` de tu comando curl. Además, el gateway agrega su propia IP al encabezado `X-Forwarded-For`
antes de reenviar la solicitud al workload httpbin.

### Configurar los encabezados X-Forwarded-Client-Cert {#configuring-x-forwarded-client-cert-headers}

Según la [documentación de Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-client-cert)
sobre XFCC:

{{< quote >}}
x-forwarded-client-cert (XFCC) es un encabezado de proxy que indica la información de certificado de una parte o de todos los clientes
o proxies por los que ha pasado una solicitud en su camino del cliente al servidor. Un proxy puede optar por
sanear/agregar/reenviar el encabezado XFCC antes de enviar la solicitud a través del proxy.
{{< /quote >}}

Para configurar cómo se gestionan los encabezados XFCC, establece `forwardClientCertDetails` en tu `IstioOperator`

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        forwardClientCertDetails: <ENUM_VALUE>
{{< /text >}}

donde `ENUM_VALUE` puede tomar uno de los siguientes valores.

| `ENUM_VALUE`          |                                                                                                                                                                         |
|-----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `UNDEFINED`           | El campo no está configurado.                                                                                                                                           |
| `SANITIZE`            | No envía el encabezado XFCC al siguiente salto.                                                                                                                         |
| `FORWARD_ONLY`        | Cuando la conexión del cliente usa mTLS (TLS mutuo), reenvía el encabezado XFCC de la solicitud.                                                                        |
| `APPEND_FORWARD`      | Cuando la conexión del cliente usa mTLS, agrega la información del certificado del cliente al encabezado XFCC de la solicitud y la reenvía.                             |
| `SANITIZE_SET`        | Cuando la conexión del cliente usa mTLS, restablece el encabezado XFCC con la información del certificado del cliente y lo envía al siguiente salto. Este es el valor predeterminado para un gateway. |
| `ALWAYS_FORWARD_ONLY` | Siempre reenvía el encabezado XFCC de la solicitud, independientemente de si la conexión del cliente usa mTLS.                                                          |

Consulta la [documentación de Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-forwarded-client-cert)
para ver ejemplos de uso de esta funcionalidad.

## Protocolo PROXY {#proxy-protocol}

El [protocolo PROXY](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt) permite intercambiar y conservar los atributos del cliente entre proxies TCP,
sin depender de protocolos L7 como HTTP ni de los encabezados `X-Forwarded-For` y `X-Envoy-External-Address`. Está pensado para escenarios en los que un balanceador de carga TCP externo necesita enviar tráfico TCP a través de un gateway de Istio hacia un servicio TCP de backend y, aun así, exponer atributos del cliente, como la IP de origen, a los endpoints upstream del servicio TCP. El protocolo PROXY se puede habilitar mediante `EnvoyFilter`.

{{< warning >}}
Envoy solo admite el protocolo PROXY para el reenvío de tráfico TCP. Consulta la [documentación de Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/ip_transparency#proxy-protocol) para más detalles, junto con algunas advertencias importantes sobre el rendimiento.

El protocolo PROXY no debe usarse para tráfico L7 ni para gateways de Istio situados detrás de balanceadores de carga L7.
{{< /warning >}}

Si tu balanceador de carga TCP externo está configurado para reenviar tráfico TCP y usar el protocolo PROXY, el listener TCP del Gateway de Istio también debe configurarse para aceptar el protocolo PROXY.
Para habilitar el protocolo PROXY en todos los listeners TCP de los gateways, configura `proxyProtocol` en tu `IstioOperator`. Por ejemplo:

{{< text syntax=yaml snip_id=none >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultConfig:
      gatewayTopology:
        proxyProtocol: {}
{{< /text >}}

Como alternativa, despliega un gateway con la siguiente anotación de pod:

{{< text yaml >}}
metadata:
  annotations:
    "proxy.istio.io/config": '{"gatewayTopology" : { "proxyProtocol": {} }}'
{{< /text >}}

El gateway obtiene la IP del cliente a partir del protocolo PROXY y la establece (o la agrega) en los encabezados `X-Forwarded-For` y `X-Envoy-External-Address`. Ten en cuenta que el protocolo PROXY es mutuamente excluyente con encabezados L7 como `X-Forwarded-For` y `X-Envoy-External-Address`. Cuando el protocolo PROXY se usa junto con la configuración `gatewayTopology`, `numTrustedProxies` y el encabezado `X-Forwarded-For` recibido tienen prioridad para determinar las direcciones de cliente de confianza, y se ignora la información del cliente que proporciona el protocolo PROXY.

Ten en cuenta que el ejemplo anterior solo configura el Gateway para aceptar tráfico TCP entrante con el protocolo PROXY. Consulta la [documentación de Envoy](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/ip_transparency#proxy-protocol) para ver ejemplos de cómo configurar el propio Envoy para que se comunique con servicios upstream mediante el protocolo PROXY.
