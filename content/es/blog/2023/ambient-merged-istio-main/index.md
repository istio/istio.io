---
title: "El Service Mesh Ambient de Istio se fusiona con la rama principal de Istio"
description: Un hito significativo para ambient mesh.
publishdate: 2023-02-28
attribution: "John Howard (Google), Lin Sun (Solo.io)"
keywords: [istio,ambient]
---

Ambient mesh de Istio fue [lanzado en septiembre de 2022](/blog/2022/introducing-ambient-mesh/) en una rama experimental, introduciendo un nuevo modo de data plane para Istio sin sidecars. A través de la colaboración con la comunidad de Istio, entre Google, Solo.io, Microsoft, Intel, Aviatrix, Huawei, IBM y otros, nos complace anunciar que Istio ambient mesh se ha graduado de la rama experimental y se ha fusionado con la rama principal de Istio. Este es un hito significativo para ambient mesh, allanando el camino para lanzar ambient en Istio 1.18 e instalarlo por defecto en las futuras versiones de Istio.

## Cambios principales desde el lanzamiento inicial

Ambient mesh está diseñado para operaciones simplificadas, mayor compatibilidad de aplicaciones y menor costo de infraestructura. El objetivo final de ambient es ser transparente para sus aplicaciones y hemos realizado algunos cambios para hacer que los componentes ztunnel y waypoint sean más simples y livianos.

* El componente ztunnel ha sido reescrito desde cero para ser rápido, seguro y liviano. Consulte [Introducción al Ztunnel basado en Rust para Istio Ambient Service Mesh](/blog/2023/rust-based-ztunnel/) para obtener más información.
* Realizamos cambios significativos para simplificar la configuración del proxy waypoint para mejorar su capacidad de depuración y rendimiento. Consulte [El Proxy Waypoint de Istio Ambient simplificado](/blog/2023/waypoint-proxy-made-simple/) para obtener más información.
* Agregamos el comando `istioctl x waypoint` para ayudarlo a implementar proxies waypoint de manera conveniente, junto con `istioctl pc workload` para ayudarlo a ver información de la carga de trabajo.
* Otorgamos a los usuarios la capacidad de vincular explícitamente las políticas de Istio como AuthorizationPolicy a los proxies waypoint en lugar de seleccionar la carga de trabajo de destino.

## Participe

Siga nuestra [guía de inicio](/docs/ambient/getting-started/) para probar la compilación pre-alfa de ambient hoy. ¡Nos encantaría saber de usted! Para obtener más información sobre ambient:

* Únase a nosotros en los canales #ambient y #ambient-dev en el [slack](https://slack.istio.io) de Istio.
* Asista a la [reunión](https://github.com/istio/community/blob/master/WORKING-GROUPS.md#working-group-meetings) semanal de contribuyentes de ambient los miércoles.
* ¡Visite los repositorios de [Istio](http://github.com/istio/istio) y [ztunnel](http://github.com/istio/ztunnel), envíe issues o PRs!


