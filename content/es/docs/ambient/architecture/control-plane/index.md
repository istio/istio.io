---
title: Ambient y el control plane de Istio
description: Comprende cómo ambient interactúa con el control plane de Istio.
weight: 2
owner: istio/wg-networking-maintainers
test: no
---

Al igual que todos los modos de {{< gloss >}}data plane{{< /gloss >}} de Istio, Ambient utiliza el {{< gloss >}}control plane{{< /gloss>}} de Istio. En ambient, el control plane se comunica con el proxy {{< gloss >}}ztunnel{{< /gloss >}} en cada nodo de Kubernetes.

La figura muestra una descripción general de los componentes relacionados con el control plane y los flujos entre el proxy ztunnel y el control plane `istiod`.

{{< image width="100%"
link="ztunnel-architecture.svg"
caption="Arquitectura de Ztunnel"
>}}

El proxy ztunnel utiliza las API de xDS para comunicarse con el control plane de Istio (`istiod`). Esto permite las actualizaciones de configuración rápidas y dinámicas que se requieren en los sistemas distribuidos modernos. El proxy ztunnel también obtiene certificados de {{< gloss "mutual tls authentication" >}}mTLS{{< /gloss >}} para las Cuentas de Servicio de todos los pods que están programados en su nodo de Kubernetes usando xDS. Un único proxy ztunnel puede implementar la funcionalidad del data plane L4 en nombre de cualquier pod que comparta su nodo, lo que requiere la obtención eficiente de la configuración y los certificados relevantes. Esta arquitectura multi-inquilino contrasta marcadamente con el modelo de sidecar donde cada pod de aplicación tiene su propio proxy.

También vale la pena señalar que en el modo ambient, se utiliza un conjunto simplificado de recursos en las API de xDS para la configuración del proxy ztunnel. Esto da como resultado un rendimiento mejorado (tener que transmitir y procesar un conjunto mucho más pequeño de información que se envía desde istiod a los proxies ztunnel) y una mejor resolución de problemas.
