---
title: ¿Por qué elegir Istio?
description: Compara Istio con otras soluciones de service mesh.
weight: 20
keywords: [comparison]
owner: istio/wg-docs-maintainers-english
test: n/a
---

Istio fue pionero en el concepto de service mesh basado en sidecar cuando se lanzó en 2017. Desde el inicio, el proyecto incluyó las características que llegarían a definir un service mesh, incluyendo mutual TLS basado en estándares para redes zero-trust, enrutamiento inteligente de tráfico y observabilidad a través de métricas, logs y trazas.

Desde entonces, el proyecto ha impulsado avances en el espacio mesh incluyendo [topologías multi-cluster y multi-red](/es/docs/ops/deployment/deployment-models/), [extensibilidad vía WebAssembly](/es/docs/concepts/wasm/), el [desarrollo del API Gateway de Kubernetes](/blog/2022/gateway-api-beta/), y alejando la infraestructura de mesh de los desarrolladores de aplicaciones con el [modo ambient](/es/docs/ambient/overview/).

Aquí hay algunas razones por las que creemos que deberías usar Istio como tu service mesh.

## Simple y poderoso

Kubernetes tiene cientos de características y docenas de APIs, pero puedes comenzar con él con solo un comando. Hemos construido Istio para que sea de la misma manera. La revelación progresiva significa que puedes usar un pequeño conjunto de APIs, y solo activar las perillas más poderosas si tienes la necesidad. Otros service meshes "simples" pasaron años poniéndose al día con el conjunto de características que Istio tenía el día 1.

¡Es mejor tener una característica y no necesitarla, que necesitarla y no tenerla!

## El proxy Envoy {#envoy}

Desde el principio, Istio ha sido impulsado por el proxy {{< gloss >}}Envoy{{< /gloss >}}, un proxy de servicio de alto rendimiento construido inicialmente por Lyft. Istio fue el primer proyecto en adoptar Envoy, y [el equipo de Istio fueron los primeros committers externos](https://eng.lyft.com/envoy-7-months-later-41986c2fd443). Envoy llegaría a convertirse en [el balanceador de carga que impulsa Google Cloud](https://cloud.google.com/load-balancing/docs/https) así como el proxy para casi todas las demás plataformas de service mesh.

Istio hereda todo el poder y flexibilidad de Envoy, incluyendo extensibilidad de clase mundial usando WebAssembly que fue [desarrollado en Envoy por el equipo de Istio](/blog/2020/wasm-announce/).

## Comunidad

Istio es un verdadero proyecto comunitario. En 2023, hubo 10 empresas que hicieron más de 1,000 contribuciones cada una a Istio, sin que ninguna empresa excediera el 25%. ([Ver los números aquí](https://istio.devstats.cncf.io/d/5/companies-table?var-period_name=Last%20year&var-metric=contributions&orgId=1)).

Ningún otro proyecto de service mesh tiene la amplitud de soporte de la industria como Istio.

## Paquetes

Hacemos releases binarios estables disponibles para todos, con cada release, y nos comprometemos a continuar haciéndolo. Publicamos parches de seguridad gratuitos y regulares para [nuestro release más reciente y varios releases anteriores](/es/docs/releases/supported-releases/). Muchos de nuestros proveedores soportarán versiones más antiguas, pero creemos que contratar un proveedor no debería ser un requisito para estar seguro en un proyecto de código abierto estable.

## Alternativas consideradas

Un buen documento de diseño incluye una sección sobre alternativas que fueron consideradas, y finalmente rechazadas.

### ¿Por qué no "usar eBPF"?

¡Lo hacemos - donde es apropiado! Istio puede ser configurado para usar {{< gloss >}}eBPF{{< /gloss >}} [para enrutar tráfico desde pods a proxies](/blog/2022/merbridge/). Esto muestra un pequeño aumento de rendimiento sobre usar `iptables`.

¿Por qué no usarlo para todo? Nadie lo hace, porque nadie realmente puede.

eBPF es una máquina virtual que se ejecuta dentro del kernel de Linux. Fue diseñado para funciones garantizadas para completarse en un entorno de computación limitado para evitar desestabilizar el comportamiento del kernel, como aquellas que realizan enrutamiento de tráfico L3 simple u observabilidad de aplicaciones. No fue diseñado para funciones de larga duración o complejas como las que se encuentran en Envoy: ¡por eso los sistemas operativos tienen [espacio de usuario](https://en.wikipedia.org/wiki/User_space_and_kernel_space)! Los mantenedores de eBPF han teorizado que eventualmente podría ser extendido para soportar ejecutar un programa tan complejo como Envoy, pero esto es un proyecto científico y es improbable que tenga practicidad en el mundo real.

Otras mesh que afirman "usar eBPF" en realidad usan un proxy Envoy por nodo, u otras herramientas de espacio de usuario, para mucha de su funcionalidad.

### ¿Por qué no usar un proxy por nodo?

Envoy no es inherentemente multi-tenant. Como resultado, tenemos grandes preocupaciones de seguridad y estabilidad con el procesamiento de reglas complejas para el tráfico L7 de múltiples tenants no restringidos en una instancia compartida. Desde Kubernetes, por defecto, puede programar un pod desde cualquier namespace en cualquier nodo, por lo que el nodo no es una frontera de tenant apropiada. La presupuestación y la asignación de costos también son grandes problemas, ya que el procesamiento L7 cuesta mucho más que L4.

En modo ambiente, estrictamente limitamos nuestro proxy ztunnel a L4, [exactamente como el kernel de Linux](https://blog.howardjohn.info/posts/ambient-spof/). Esto reduce significativamente el área de superficie de vulnerabilidad, y nos permite operar un componente compartido de forma segura. El tráfico se reenvía entonces a proxies Envoy que operan por namespace, por lo que ningún proxy Envoy es multi-tenant.

## Tengo un CNI. ¿Por qué necesito Istio?

Hoy en día, algunos plugins CNI están comenzando a ofrecer funcionalidad de service mesh como un complemento que se coloca encima de su propia implementación CNI. Por ejemplo, pueden implementar sus propios esquemas de cifrado para el tráfico entre nodos o pods, identidad de carga de trabajo, o soportar alguna política de nivel de transporte redireccionando el tráfico a un proxy L7. Estos complementos de service mesh son no estándar, y por lo tanto solo pueden funcionar encima del CNI que los incluye. También ofrecen conjuntos de características variables. Por ejemplo, las soluciones construidas sobre Wireguard no pueden ser FIPS-compliant.

Por esta razón, Istio ha implementado su componente de túnel cero-confianza (ztunnel), que proporciona transparentemente y eficientemente esta funcionalidad usando protocolos de cifrado probados, estándar de la industria. [Aprende más sobre ztunnel](/es/docs/ambient/overview).

Istio está diseñado para ser un service mesh que proporciona una implementación consistente, altamente segura, eficiente y cumpliente con estándares de service mesh, ofreciendo un [conjunto poderoso de políticas L7](/es/docs/concepts/security/#authorization), [identidad de workload agnóstica de la plataforma](/es/docs/concepts/security/#istio-identity), usando [protocolos mTLS probados de la industria](/es/docs/concepts/security/#mutual-tls-authentication) - en cualquier entorno, con cualquier CNI, o incluso entre clusters con diferentes CNIs.
