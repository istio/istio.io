---
title: "Ampliamos el soporte de Gateway API en Istio"
description: "Una API estándar para service mesh, en Istio y en la comunidad en general."
publishdate: 2022-07-13
attribution: "Craig Box (Google)"
keywords: [traffic-management,gateway,gateway-api,api,gamma,sig-network]
---

Hoy queremos [felicitar a la comunidad de Kubernetes SIG Network por la publicación en beta de la especificación de Gateway API](https://kubernetes.io/blog/2022/07/13/gateway-api-graduates-to-beta/). Junto a este hito, nos complace anunciar que el soporte para usar Gateway API en el ingreso (ingress) de Istio se promociona a Beta, y que nuestra intención es que Gateway API se convierta en la API por defecto para toda la gestión de tráfico de Istio en el futuro. También nos alegra dar la bienvenida a nuestros amigos de la comunidad de Service Mesh Interface (SMI), que se unen a nosotros en un nuevo esfuerzo por estandarizar casos de uso de service mesh usando Gateway API.

## La historia de las APIs de gestión de tráfico de Istio

El diseño de APIs es más un arte que una ciencia, ¡y a menudo Istio se usa como una API para configurar la publicación de otras APIs! Solo en el enrutamiento de tráfico debemos considerar productor vs. consumidor, enrutamiento vs. post‑enrutamiento, y cómo expresar un conjunto de funcionalidades complejo con el número correcto de objetos, teniendo en cuenta que pueden ser propiedad de equipos distintos.

Cuando lanzamos Istio en 2017, aportamos muchos años de experiencia de la infraestructura de serving de APIs en producción de Google y del proyecto Amalgam8 de IBM, y lo mapeamos sobre Kubernetes. Pronto nos topamos con las limitaciones de la API Ingress de Kubernetes. El deseo de soportar todas las implementaciones de proxy hizo que Ingress solo soportase lo más básico del enrutamiento HTTP, y que otras capacidades se implementasen a menudo como anotaciones específicas de cada vendor. La API Ingress se compartía entre administradores de infraestructura (“crear y configurar un balanceador”), operadores del clúster (“gestionar un certificado TLS para todo mi dominio”) y usuarios de aplicaciones (“úsalo para enrutar /foo al servicio foo”).

[Reescribimos nuestras APIs de tráfico a principios de 2018](/blog/2018/v1alpha3-routing/) para responder al feedback de usuarios y abordar estas preocupaciones de forma más adecuada.

Una característica principal del nuevo modelo de Istio fue disponer de APIs separadas que describen la infraestructura (el balanceador, representado por el [Gateway](/docs/concepts/traffic-management/#gateways)) y la aplicación (enrutamiento y post‑enrutamiento, representados por [VirtualService](/docs/concepts/traffic-management/#virtual-services) y [DestinationRule](/docs/concepts/traffic-management/#destination-rules)).

Ingress funcionaba bien como mínimo común denominador entre distintas implementaciones, pero sus carencias llevaron a SIG Network a investigar el diseño de una “versión 2”. A una [encuesta de usuarios en 2018](https://github.com/bowei/k8s-ingress-survey-2018/blob/master/survey.pdf) le siguió [una propuesta de nuevas APIs en 2019](https://www.youtube.com/watch?v=Ne9UJL6irXY), basada en gran medida en las APIs de tráfico de Istio. Ese esfuerzo pasó a conocerse como “Gateway API”.

Gateway API se diseñó para poder modelar muchos más casos de uso, con puntos de extensión para habilitar funcionalidades que difieren entre implementaciones. Además, adoptar Gateway API abre un service mesh a la compatibilidad con todo el ecosistema de software escrito para soportarla. No necesitas pedirle a tu vendor que soporte el enrutamiento de Istio directamente: basta con crear objetos de Gateway API e Istio hará lo necesario, listo para usar.

## Soporte de Gateway API en Istio

Istio añadió [soporte para Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/) en noviembre de 2020, con soporte marcado como Alpha junto con la implementación de la API. Con la publicación en beta de la especificación, nos complace anunciar que el soporte para uso en ingress en Istio se promociona a Beta. También animamos a los early adopters a empezar a experimentar con Gateway API para uso “mesh” (servicio a servicio), y moveremos ese soporte a Beta cuando SIG Network haya estandarizado la semántica requerida.

En torno al momento del lanzamiento v1 de la API, pretendemos hacer que Gateway API sea el método por defecto para configurar todo el enrutamiento de tráfico en Istio: para ingress (north‑south) y servicio a servicio (east‑west). En ese momento, cambiaremos nuestra documentación y ejemplos para reflejar esta recomendación.

Igual que Kubernetes pretende soportar la API Ingress durante muchos años después de que Gateway API sea estable, las APIs de Istio (Gateway, VirtualService y DestinationRule) seguirán soportadas en el futuro previsible.

Además, puedes continuar usando las APIs de tráfico existentes de Istio junto con Gateway API; por ejemplo, usando un [HTTPRoute](https://gateway-api.sigs.k8s.io/v1beta1/api-types/httproute/) con un [VirtualService](/docs/reference/config/networking/virtual-service/) de Istio.

La similitud entre las APIs significa que podremos ofrecer una herramienta para convertir fácilmente objetos de la API de Istio a objetos de Gateway API, y la publicaremos junto con la versión v1 de la API.

Otras partes de la funcionalidad de Istio, incluyendo policy y telemetry, seguirán configurándose con APIs específicas de Istio mientras trabajamos con SIG Network en la estandarización de estos casos de uso.

## Damos la bienvenida a la comunidad SMI al proyecto Gateway API

A lo largo de su diseño e implementación, miembros del equipo de Istio han estado trabajando con miembros de SIG Network en la implementación de Gateway API, asegurando que fuera adecuada para su uso en casos de “mesh”.

Nos alegra que miembros de la comunidad de Service Mesh Interface (SMI), incluidos líderes de Linkerd, Consul y Open Service Mesh, se [unan formalmente a este esfuerzo](https://smi-spec.io/blog/announcing-smi-gateway-api-gamma) tras decidir colectivamente estandarizar sus esfuerzos de API sobre Gateway API. Con ese fin, hemos creado un workstream de [Gateway API Mesh Management and Administration (GAMMA)](https://gateway-api.sigs.k8s.io/contributing/gamma/) dentro del proyecto Gateway API. John Howard, miembro del Comité de Supervisión Técnica de Istio y líder de nuestro WG de Networking, será uno de los líderes de este grupo.

Nuestros próximos pasos combinados son proporcionar [propuestas de mejora](https://gateway-api.sigs.k8s.io/v1alpha2/contributing/gep/) al proyecto Gateway API para soportar casos de uso de mesh. Hemos [empezado a analizar la semántica de la API](https://docs.google.com/document/d/1T_DtMQoq2tccLAtJTpo3c0ohjm25vRS35MsestSL9QU/edit) para la gestión de tráfico en mesh, y trabajaremos con vendors y comunidades que implementen Gateway API en sus proyectos para construir sobre una implementación estándar. Después, pretendemos construir una representación para políticas de autorización y autenticación.

Con SIG Network como un foro neutral respecto a vendors para asegurar que la comunidad de service mesh implemente Gateway API usando la misma semántica, esperamos disponer de una API estándar que funcione con todos los proyectos, independientemente de su stack tecnológico o proxy.
