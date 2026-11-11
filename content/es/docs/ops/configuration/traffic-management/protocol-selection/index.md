---
title: Selección de protocolo
description: Información sobre cómo especificar protocolos.
weight: 10
keywords: [protocol,protocol sniffing,protocol selection,protocol detection]
aliases:
  - /help/ops/traffic-management/protocol-selection
  - /help/ops/protocol-selection
  - /help/tasks/traffic-management/protocol-selection
  - /docs/ops/traffic-management/protocol-selection
owner: istio/wg-networking-maintainers
test: n/a
---

Istio puede hacer de proxy para cualquier tráfico TCP. Esto incluye HTTP, HTTPS y gRPC, así como protocolos TCP sin procesar.
Para ofrecer funcionalidades adicionales, como el enrutamiento y métricas detalladas, es necesario determinar el protocolo. Esto se puede hacer automáticamente o especificarlo de forma explícita.

Los protocolos que no se basan en TCP, como UDP, no pasan por el proxy. Estos protocolos siguen funcionando con normalidad, sin
que el proxy de Istio los intercepte, pero no se pueden usar en componentes que solo funcionan como proxy, como los ingress o egress gateways.

## Selección automática de protocolo {#automatic-protocol-selection}

Istio puede detectar automáticamente el tráfico HTTP y HTTP/2. Si el protocolo no se puede determinar automáticamente, el tráfico se trata como tráfico TCP simple.

{{< tip >}}
Los protocolos en los que el servidor habla primero (server first), como MySQL, no son compatibles con la selección automática de protocolo. Consulta [Protocolos server first](/es/docs/ops/deployment/application-requirements#server-first-protocols) para más información.
{{< /tip >}}

## Selección explícita de protocolo {#explicit-protocol-selection}

Los protocolos se pueden especificar manualmente en la definición del Service.

Esto se puede configurar de dos maneras:

- Mediante el nombre del puerto: `name: <protocol>[-<suffix>]`.
- En Kubernetes 1.18+, mediante el campo `appProtocol`: `appProtocol: <protocol>`.

Si se definen ambos, `appProtocol` tiene prioridad sobre el nombre del puerto.

Ten en cuenta que el comportamiento en el Gateway difiere en algunos casos, ya que el gateway puede terminar TLS y el protocolo se puede negociar.

Se admiten los siguientes protocolos:

| Protocolo                             | Propósito en el sidecar                                                                                                                                                 | Propósito en el gateway                                                                                                                                                 |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `http`                                | Tráfico HTTP/1.1 en texto plano                                                                                                                                         | Tráfico HTTP (1.1 o 2) en texto plano                                                                                                                                   |
| `http2`                               | Tráfico HTTP/2 en texto plano                                                                                                                                           | Tráfico HTTP (1.1 o 2) en texto plano                                                                                                                                   |
| `https`                               | Datos cifrados con TLS. Como el sidecar no descifra el tráfico TLS, equivale a `tls`                                                                                    | Tráfico HTTP (1.1 o 2) cifrado con TLS                                                                                                                                  |
| `tcp`                                 | Flujo de datos TCP opaco                                                                                                                                                | Flujo de datos TCP opaco                                                                                                                                                |
| `tls`                                 | Datos cifrados con TLS                                                                                                                                                  | Datos cifrados con TLS                                                                                                                                                  |
| `grpc`, `grpc-web`                                | Igual que `http2`                                                                                                                                                       | Igual que `http2`                                                                                                                                                       |  |
| `mongo`, `mysql`, `redis` | Soporte experimental para protocolos de aplicación. Para habilitarlos, configura las [variables de entorno](/es/docs/reference/commands/pilot-discovery/#envvars) correspondientes. Si no están habilitados, se tratan como un flujo de datos TCP opaco | Soporte experimental para protocolos de aplicación. Para habilitarlos, configura las [variables de entorno](/es/docs/reference/commands/pilot-discovery/#envvars) correspondientes. Si no están habilitados, se tratan como un flujo de datos TCP opaco |

A continuación se muestra un ejemplo de un Service que define un puerto `https` mediante `appProtocol` y un puerto `http` mediante su nombre:

{{< text yaml >}}
kind: Service
metadata:
  name: myservice
spec:
  ports:
  - port: 3306
    name: database
    appProtocol: https
  - port: 80
    name: http-web
{{< /text >}}

## Selección de protocolo HTTP en gateways {#http-gateway-protocol-selection}

A diferencia de los sidecars, por defecto los gateways no pueden detectar automáticamente qué protocolo HTTP específico deben usar al reenviar solicitudes a los servicios de backend. Por eso, a menos que se use la selección explícita de protocolo para especificar HTTP/1.1 (`http`) o HTTP/2 (`http2` o `grpc`), los gateways reenvían todas las solicitudes HTTP entrantes con HTTP/1.1.

En lugar de usar la selección explícita de protocolo, puedes indicar a los gateways que reenvíen las solicitudes con el mismo protocolo que la solicitud entrante configurando la opción [`useClientProtocol`](/es/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings-HTTPSettings) para un Service. Sin embargo, ten en cuenta que usar esta opción con servicios que no admiten HTTP/2 puede ser arriesgado, porque los gateways HTTPS siempre [anuncian](https://en.wikipedia.org/wiki/Application-Layer_Protocol_Negotiation) soporte para HTTP/1.1 y HTTP/2. Así que, aunque un servicio de backend no admita HTTP/2, los clientes modernos creerán que sí lo admite y a menudo elegirán usarlo.
