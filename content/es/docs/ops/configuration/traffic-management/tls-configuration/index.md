---
title: Entender la configuración de TLS
linktitle: Configuración de TLS
description: Cómo configurar los ajustes de TLS para proteger el tráfico de red.
weight: 30
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers
test: n/a
---

Una de las funcionalidades más importantes de Istio es la capacidad de restringir y proteger el tráfico de red que entra en la mesh, que sale de ella
y que circula dentro de ella. Sin embargo, configurar los ajustes de TLS puede resultar confuso y es una fuente habitual de errores de configuración.
Este documento intenta explicar las distintas conexiones que intervienen al enviar solicitudes en Istio y cómo
se configuran sus ajustes de TLS asociados.
Consulta [Errores de configuración de TLS](/es/docs/ops/common-problems/network-issues/#tls-configuration-mistakes)
para ver un resumen de algunos de los problemas de configuración de TLS más comunes.

## Sidecars

El tráfico de los sidecars implica varias conexiones. Veámoslas una por una.

{{< image width="100%"
    link="sidecar-connections.svg"
    alt="Sidecar proxy network connections"
    title="Sidecar connections"
    caption="Sidecar proxy network connections"
    >}}

1. **Tráfico entrante externo**
    Es el tráfico que llega desde un cliente externo y que el sidecar captura.
    Si el cliente está dentro de la mesh, este tráfico puede estar cifrado con TLS mutuo de Istio.
    Por defecto, el sidecar se configura para aceptar tanto tráfico mTLS como tráfico sin mTLS, lo que se conoce como modo `PERMISSIVE`.
    Como alternativa, el modo se puede configurar como `STRICT`, en el que el tráfico debe ser mTLS, o como `DISABLE`, en el que el tráfico debe ir en texto plano.
    El modo mTLS se configura con un [recurso `PeerAuthentication`](/es/docs/reference/config/security/peer_authentication/).

1. **Tráfico entrante local**
    Es el tráfico que va desde el sidecar hacia el servicio de tu aplicación. Este tráfico siempre se reenvía tal cual.
    Ten en cuenta que esto no significa que siempre vaya en texto plano; el sidecar puede dejar pasar una conexión TLS.
    Solo significa que el sidecar nunca originará una nueva conexión TLS.

1. **Tráfico saliente local**
    Es el tráfico saliente del servicio de tu aplicación que intercepta el sidecar.
    Tu aplicación puede estar enviando tráfico en texto plano o TLS.
    Si la [selección automática de protocolo](/es/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection)
    está habilitada, Istio detecta automáticamente el protocolo. De lo contrario, debes usar el nombre del puerto en el servicio de destino para
    [especificar el protocolo manualmente](/es/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection).

1. **Tráfico saliente externo**
    Es el tráfico que sale del sidecar hacia algún destino externo. El tráfico se puede reenviar tal cual, o se puede
    iniciar una conexión TLS (mTLS o TLS estándar). Esto se controla con el ajuste de modo TLS en la `trafficPolicy` de un
    [recurso `DestinationRule`](/es/docs/reference/config/networking/destination-rule/).
    El modo `DISABLE` envía texto plano, mientras que `SIMPLE`, `MUTUAL` e `ISTIO_MUTUAL` originan una conexión TLS.

Las ideas clave son:

- `PeerAuthentication` se usa para configurar qué tipo de tráfico mTLS acepta el sidecar.
- `DestinationRule` se usa para configurar qué tipo de tráfico TLS envía el sidecar.
- Los nombres de los puertos, o la selección automática de protocolo, determinan con qué protocolo interpreta el sidecar el tráfico.

## mTLS automático {#auto-mtls}

Como se describió anteriormente, un `DestinationRule` controla si el tráfico saliente usa mTLS o no.
Sin embargo, configurarlo para cada workload puede ser tedioso. Normalmente, quieres que Istio use mTLS
en todos los casos posibles y que solo envíe texto plano a los workloads que no forman parte de la mesh (es decir, los que no tienen sidecars).

Istio lo facilita con una funcionalidad llamada "mTLS automático" (Auto mTLS), que hace exactamente eso. Si los ajustes de TLS
no se configuran explícitamente en un `DestinationRule`, el sidecar determina automáticamente si
se debe enviar [TLS mutuo de Istio](/about/faq/#difference-between-mutual-and-istio-mutual).
Esto significa que, sin ninguna configuración, todo el tráfico dentro de la mesh se cifra con mTLS.

## Gateways

Toda solicitud a un gateway tiene dos conexiones.

{{< image width="100%"
    link="gateway-connections.svg"
    alt="Gateway network connections"
    title="Gateway connections"
    caption="Gateway network connections"
    >}}

1. La solicitud entrante, iniciada por algún cliente, como `curl` o un navegador web. A menudo se la denomina conexión "downstream".

1. La solicitud saliente, iniciada por el gateway hacia algún backend. A menudo se la denomina conexión "upstream".

Ambas conexiones tienen configuraciones de TLS independientes.

Ten en cuenta que la configuración de los ingress y egress gateways es idéntica.
Los gateways `istio-ingress-gateway` e `istio-egress-gateway` son solo dos despliegues especializados de gateway.
La diferencia es que el cliente de un ingress gateway se ejecuta fuera de la mesh, mientras que, en el caso de un egress gateway,
el destino está fuera de la mesh.

### Entrada {#inbound}

Como parte de la solicitud entrante, el gateway debe decodificar el tráfico para aplicar las reglas de enrutamiento.
Esto se hace según la configuración del servidor en un [recurso `Gateway`](/es/docs/reference/config/networking/gateway/).
Por ejemplo, si una conexión entrante es HTTP en texto plano, el protocolo del puerto se configura como `HTTP`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1
kind: Gateway
...
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
{{< /text >}}

De forma similar, para tráfico TCP sin procesar, el protocolo se establece como `TCP`.

Para las conexiones TLS, hay algunas opciones más:

1. ¿Qué protocolo se encapsula?
    Si la conexión es HTTPS, el protocolo del servidor debe configurarse como `HTTPS`.
    En cambio, para una conexión TCP sin procesar encapsulada con TLS, el protocolo debe establecerse como `TLS`.

1. ¿La conexión TLS se termina o se deja pasar?
    Para el tráfico passthrough, configura el campo de modo TLS como `PASSTHROUGH`:

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1
    kind: Gateway
    ...
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: PASSTHROUGH
    {{< /text >}}

    En este modo, Istio enruta según la información de SNI y reenvía la conexión tal cual al destino.

1. ¿Se debe usar TLS mutuo?
    El TLS mutuo se puede configurar mediante el modo TLS `MUTUAL`. Con esta configuración, se solicita un certificado de cliente
    que se verifica con los `caCertificates` o el `credentialName` configurados:

    {{< text yaml >}}
    apiVersion: networking.istio.io/v1
    kind: Gateway
    ...
      servers:
      - port:
          number: 443
          name: https
          protocol: HTTPS
        tls:
          mode: MUTUAL
          caCertificates: ...
    {{< /text >}}

### Salida {#outbound}

Mientras que el lado de entrada configura qué tipo de tráfico esperar y cómo procesarlo, la configuración de salida controla
qué tipo de tráfico envía el gateway. Esto se configura con los ajustes de TLS de un `DestinationRule`,
igual que el tráfico saliente externo de los [sidecars](#sidecars), o con [mTLS automático](#auto-mtls) por defecto.

La única diferencia es que debes tener en cuenta la configuración del `Gateway` al configurar esto.
Por ejemplo, si el `Gateway` está configurado con TLS `PASSTHROUGH` mientras que el `DestinationRule` configura la originación de TLS,
acabarás con un [doble cifrado](/es/docs/ops/common-problems/network-issues/#double-tls).
Esto funciona, pero a menudo no es el comportamiento deseado.

Un `VirtualService` vinculado al gateway también requiere atención para
[garantizar que sea coherente](/es/docs/ops/common-problems/network-issues/#gateway-mismatch)
con la definición del `Gateway`.
