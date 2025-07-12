---
title: HBONE
description: Comprender el protocolo de túnel seguro de Istio.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

**HBONE** (o HTTP-Based Overlay Network Environment) es un protocolo de túnel seguro que se utiliza entre los componentes de Istio. HBONE es un término específico de Istio. Es un mecanismo para multiplexar de forma transparente los flujos TCP relacionados con muchas conexiones de aplicaciones diferentes a través de una única conexión de red cifrada con mTLS: un túnel cifrado.

En su implementación actual dentro de Istio, el protocolo HBONE compone tres estándares abiertos:

- [HTTP/2](https://httpwg.org/specs/rfc7540.html)
- [HTTP CONNECT](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/CONNECT)
- [TLS mutuo (mTLS)](https://datatracker.ietf.org/doc/html/rfc8446)

HTTP CONNECT se utiliza para establecer una conexión de túnel, mTLS se utiliza para proteger y cifrar esa conexión, y HTTP/2 se utiliza para multiplexar los flujos de conexión de la aplicación a través de ese único túnel seguro y cifrado, y para transmitir metadatos adicionales a nivel de flujo.

## Seguridad y tenencia

Según lo exige la especificación mTLS, cada conexión de túnel subyacente debe tener una identidad de origen y destino únicas, y esas identidades deben usarse para establecer el cifrado para esa conexión.

Esto significa que las conexiones de la aplicación a través del protocolo HBONE a la misma identidad de destino se multiplexarán a través de la misma conexión HTTP/2 subyacente compartida, cifrada y segura; en efecto, cada origen y destino únicos deben tener su propia conexión de túnel dedicada y segura, incluso si esa conexión dedicada subyacente está manejando múltiples conexiones a nivel de aplicación.

## Detalles de implementación

Por convención de Istio, ztunnel y otros proxies que entienden el protocolo HBONE exponen escuchas en el puerto TCP 15008.

Como HBONE es simplemente una combinación de HTTP/2, HTTP CONNECT y mTLS, los paquetes del túnel HBONE que fluyen entre los proxies habilitados para HBONE se ven como en la siguiente figura:

{{< image width="100%"
link="hbone-packet.svg"
caption="Formato de paquete L3 de HBONE"
>}}

Una propiedad importante del túnel HBONE es que la solicitud de la aplicación original se puede proxificar de forma transparente sin alterar el flujo de tráfico de la aplicación subyacente de ninguna manera. Esto significa que los metadatos sobre una conexión se pueden transmitir a los proxies de destino sin alterar la solicitud de la aplicación, lo que elimina la necesidad de agregar encabezados específicos de Istio al tráfico de la aplicación, por ejemplo.

En el futuro se investigarán casos de uso adicionales de HBONE y tunelización HTTP (como UDP) a medida que evolucionen el modo ambient y los estándares.
