---
title: Entendiendo DNS
linktitle: DNS
description: Cómo el DNS interactúa con Istio.
weight: 31
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers
test: n/a
---

Istio interactúa con DNS de diferentes maneras que pueden ser confusas de entender.
Este documento proporciona una inmersión profunda en cómo Istio y DNS trabajan juntos.

{{< warning >}}
Este documento describe detalles de implementación de bajo nivel. Para una visión general de más alto nivel, consulta las páginas de [Conceptos](/es/docs/concepts/traffic-management/) o [Tareas](/es/docs/tasks/traffic-management/) de gestión de tráfico.
{{< /warning >}}

## Vida de una solicitud

En estos ejemplos, veremos lo que sucede cuando una aplicación ejecuta `curl example.com`.
Aunque se usa `curl` aquí, lo mismo aplica a casi todos los clientes.

Cuando envías una solicitud a un dominio, un cliente hará resolución DNS para resolver eso a una dirección IP.
Esto sucede independientemente de cualquier configuración de Istio, ya que Istio solo intercepta tráfico de red; no puede cambiar el comportamiento de tu aplicación o decisión de enviar una solicitud DNS.
En el ejemplo a continuación, `example.com` se resolvió a `192.0.2.0`.

{{< text bash >}}
$ curl example.com -v
*   Trying 192.0.2.0:80...
{{< /text >}}

Después, la solicitud será interceptada por Istio.
En este punto, Istio verá tanto el hostname (de un header `Host: example.com`), como la dirección de destino (`192.0.2.0:80`).
Istio usa esta información para determinar el destino previsto.
[Entendiendo el enruramiento de tráfico](/es/docs/ops/configuration/traffic-management/traffic-routing/) proporciona una inmersión profunda en cómo funciona este comportamiento.

Si el cliente no pudo resolver la solicitud DNS, la solicitud terminaría antes de que Istio la reciba.
Esto significa que si se envía una solicitud a un hostname que es conocido por Istio (por ejemplo, por un `ServiceEntry`) pero no por el servidor DNS, la solicitud fallará.
El [proxy DNS](#dns-proxying) de Istio puede cambiar este comportamiento.

Una vez que Istio ha identificado el destino previsto, debe elegir a qué dirección enviar.
Debido a las [capacidades avanzadas de balanceamiento de carga](/es/docs/concepts/traffic-management/#load-balancing-options) de Istio, esto a menudo no es la dirección IP original que el cliente envió.
Dependiendo de la configuración del servicio, hay algunas maneras diferentes en que Istio hace esto.

* Usar la dirección IP original del cliente (`192.0.2.0`, en el ejemplo anterior).
  Este es el caso para `ServiceEntry` de tipo `resolution: NONE` (el predeterminado) y [Services `headless`](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services).
* Balancear la carga sobre un conjunto de direcciones IP estáticas.
  Este es el caso para `ServiceEntry` de tipo `resolution: STATIC`, donde se usarán todos los `spec.endpoints`, o para Services estándar, donde se usarán todos los `Endpoints`.
* Resolver periódicamente una dirección usando DNS, y balancear la carga a través de todos los resultados.
  Este es el caso para `ServiceEntry` de tipo `resolution: DNS`.

Nota que en todos los casos, la resolución DNS dentro del proxy de Istio es ortogonal a la resolución DNS en una aplicación de usuario.
Incluso cuando el cliente hace resolución DNS, el proxy puede ignorar la dirección IP resuelta y usar la suya propia, que podría ser de
una lista estática de IPs o haciendo su propia resolución DNS (potencialmente del mismo hostname o uno diferente).

## Resolución DNS del proxy

A diferencia de la mayoría de los clientes, que harán solicitudes DNS bajo demanda en el momento de las solicitudes (y luego típicamente cachear los resultados),
el proxy de Istio nunca hace solicitudes DNS síncronas.
Cuando se configura un `ServiceEntry` de tipo `resolution: DNS`, el proxy resolverá periódicamente los hostnames configurados y usará esos para todas las solicitudes.
Este intervalo está fijado en 30 segundos y no puede cambiarse en este momento.
Esto sucede incluso si el proxy nunca envía ninguna solicitud a estas aplicaciones.

Para meshes con muchos proxies o muchos `ServiceEntries` de tipo `resolution: DNS`, especialmente cuando se usan `TTL`s bajos, esto puede causar una alta carga en los servidores DNS.
En estos casos, lo siguiente puede ayudar a reducir la carga:

* Cambiar a `resolution: NONE` para evitar lookups DNS del proxy completamente. Esto es adecuado para muchos casos de uso.
* Si controlas los dominios que están siendo resueltos, aumenta su TTL.
* Si tu `ServiceEntry` solo es necesario por algunos workloads, limita su alcance con `exportTo` o un [`Sidecar`](/es/docs/reference/config/networking/sidecar/).

## DNS Proxying

Istio ofrece una característica para [solicitudes DNS proxy](/es/docs/ops/configuration/traffic-management/dns-proxy/).
Esto permite a Istio capturar solicitudes DNS enviadas por el cliente y retornar una respuesta directamente.
Esto puede mejorar la latencia DNS, reducir la carga, y permitir que `ServiceEntries`, que de otra manera no serían conocidos por `kube-dns`, sean resueltos.

Nota que este proxying solo aplica a solicitudes DNS enviadas por aplicaciones de usuario; cuando se usan `ServiceEntries` de tipo `resolution: DNS`,
el proxy no tiene impacto en la resolución DNS del proxy de Istio.
