---
title: Descripción general
description: Una descripción general del modo de data plane ambient de Istio.
weight: 1
owner: istio/wg-docs-maintainers-english
test: no
---

En el **modo ambient**, Istio implementa sus [características](/es/docs/concepts) utilizando un proxy de capa 4 (L4) por nodo y, opcionalmente, un proxy de capa 7 (L7) por namespaces.

Este enfoque por capas te permite adoptar Istio de una manera más incremental, pasando sin problemas de ninguna malla, a una superposición L4 segura, a un procesamiento y políticas L7 completos, por namespaces, según sea necesario. Además, los workloads que se ejecutan en diferentes modos de {{< gloss >}}data plane{{< /gloss >}} de Istio interoperan sin problemas, lo que permite a los usuarios mezclar y combinar capacidades en función de sus necesidades particulares a medida que cambian con el tiempo.

Dado que los pods de workload ya no requieren que los proxies se ejecuten en sidecars para participar en la malla, el modo ambient a menudo se conoce informalmente como "malla sin sidecar".

## Cómo funciona

El modo ambient divide la funcionalidad de Istio en dos capas distintas. En la base, la superposición segura **ztunnel** se encarga del enrutamiento y la seguridad de zero-trust para el tráfico. Por encima de eso, cuando sea necesario, los usuarios pueden habilitar los **waypoint proxies** L7 para obtener acceso a la gama completa de características de Istio. Los proxies de waypoint, aunque más pesados que la superposición de ztunnel sola, todavía se ejecutan como un componente ambient de la infraestructura, sin requerir modificaciones en los pods de la aplicación.

{{< tip >}}
Los pods y los workloads que usan el modo sidecar pueden coexistir dentro de la misma malla que los pods que usan el modo ambient. El término "malla ambient" se refiere a una malla de Istio que se instaló con soporte para el modo ambient y, por lo tanto, puede admitir pods de malla que usan cualquier tipo de data plane.
{{< /tip >}}

Para obtener detalles sobre el diseño del modo ambient y cómo interactúa con el {{< gloss >}}control plane{{< /gloss >}} de Istio, consulta la documentación de arquitectura del [data plane](/es/docs/ambient/architecture/data-plane) y del [control plane](/es/docs/ambient/architecture/control-plane).

## ztunnel

El componente ztunnel (túnel de Zero Trust) es un proxy por nodo especialmente diseñado que impulsa el modo de data plane ambient de Istio.

Ztunnel es responsable de conectar y autenticar de forma segura los workloads dentro de la malla. El proxy ztunnel está escrito en Rust y tiene un alcance intencional para manejar funciones L3 y L4 como mTLS, autenticación, autorización L4 y telemetría. Ztunnel no termina el tráfico HTTP de el workload ni analiza los encabezados HTTP de el workload. El ztunnel garantiza que el tráfico L3 y L4 se transporte de manera eficiente y segura directamente a los workloads, a otros proxies ztunnel o a los proxies de waypoint.

El término "superposición segura" se utiliza para describir colectivamente el conjunto de funciones de red L4 implementadas en una malla ambient a través del proxy ztunnel. En la capa de transporte, esto se implementa a través de un protocolo de tunelización de tráfico basado en HTTP CONNECT llamado [HBONE](/es/docs/ambient/architecture/hbone).

## Waypoint proxies

El proxy de waypoint es una implementación del proxy {{< gloss >}}Envoy{{</ gloss >}}; el mismo motor que Istio utiliza para su modo de data plane de sidecar.

Los proxies de waypoint se ejecutan fuera de los pods de la aplicación. Se instalan, actualizan y escalan independientemente de las aplicaciones.

Algunos casos de uso de Istio en modo ambient pueden abordarse únicamente a través de las características de superposición segura L4 y no necesitarán características L7, por lo que no requerirán la implementación de un proxy de waypoint. Los casos de uso que requieren una gestión avanzada del tráfico y características de red L7 requerirán la implementación de un waypoint.

| Caso de uso de implementación de la aplicación | Configuración del modo ambient |
| ------------------------------- | -------------------------- |
| Redes de Zero Trust a través de TLS mutuo, transporte de datos cifrado y tunelizado del tráfico de la aplicación del cliente, autorización L4, telemetría L4 | Solo ztunnel (predeterminado) |
| Como arriba, más características avanzadas de gestión de tráfico de Istio (incluida la autorización L7, la telemetría y el enrutamiento de VirtualService) | ztunnel y proxies de waypoint |
