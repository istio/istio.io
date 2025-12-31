---
title: "Istio ha solicitado convertirse en un proyecto de la CNCF"
publishdate: 2022-04-25
attribution: "Comité Directivo de Istio"
keywords: [Istio,CNCF]
---

El proyecto Istio se complace en anunciar su intención de unirse a la [Cloud Native Computing Foundation](https://cncf.io/) (CNCF). Con el apoyo del Comité Directivo de Istio, [Google ha presentado una propuesta de solicitud para que Istio se una a la CNCF](https://github.com/cncf/toc/pull/827), el hogar de proyectos compañeros como Kubernetes y Envoy.

Han pasado casi 5 años desde que [Google, IBM y Lyft lanzaron Istio 0.1 en mayo de 2017](/news/releases/0.x/announcing-0.1/). Aquella primera versión estableció el estándar de lo que debería ser un service mesh: gestión del tráfico, aplicación de políticas y observabilidad, todo ello impulsado por sidecars junto a las cargas de trabajo. Estamos orgullosos de ser el [service mesh más popular](https://www.cncf.io/reports/cncf-annual-survey-2021/) según una encuesta reciente de la CNCF, y esperamos trabajar más de cerca con las comunidades de la CNCF en torno a networking y service mesh.

A medida que profundizamos nuestra integración con Kubernetes mediante la [Gateway API](/docs/tasks/traffic-management/ingress/gateway-api/) y con gRPC mediante [proxyless mesh](/blog/2021/proxyless-grpc/) — sin olvidar Envoy, que ha crecido junto a Istio — creemos que es el momento de unir el stack Cloud Native de referencia bajo un mismo paraguas.

## ¿Qué sigue?

Hoy es solo el comienzo de un camino. El Comité de Supervisión Técnica (TOC) de la CNCF estudiará cuidadosamente nuestra solicitud y realizará la debida diligencia. Después, abrirán una votación y, si tiene éxito, el proyecto será transferido.

El trabajo que realizamos para establecer directrices de la marca registrada de Istio a través de Open Usage Commons (OUC) garantizará que todo el ecosistema pueda seguir utilizando las marcas de Istio de manera libre y justa. Las marcas pasarán a la Linux Foundation, pero seguirán gestionándose bajo [las directrices de marca de OUC](https://openusage.org/trademark-guidelines/).

Actualmente, Google financia y gestiona la infraestructura de build/test de Istio. La compañía se ha comprometido a seguir patrocinando esta infraestructura a medida que pase a ser gestionada por la CNCF, y estará respaldada por créditos de Google y de otros contribuidores una vez completada la transición.

Nada de nuestro actual modelo de gobernanza abierta tiene por qué cambiar como resultado de esta transferencia. Seguiremos reconociendo la contribución corporativa, la influencia de la comunidad y el mantenimiento a largo plazo a través de nuestro modelo de [Comité Directivo](https://github.com/istio/community/tree/master/steering) y [Comité de Supervisión Técnica](https://github.com/istio/community/blob/master/TECH-OVERSIGHT-COMMITTEE.md). Istio es clave para el futuro de Google Cloud y Google tiene la intención de seguir invirtiendo fuertemente en el proyecto.

Queremos agradecer al ecosistema de [usuarios de Istio](/about/case-studies/), [proyectos integrados](/about/ecosystem/#integrations) y [proveedores de servicios profesionales](/about/ecosystem/#services). ¡Envíanos un PR si quieres aparecer en nuestra web!

Istio es el bloque de construcción para productos de [más de 20 vendors diferentes](/about/ecosystem/#providers). Ningún otro service mesh tiene una presencia comparable. Queremos dar las gracias a todas las nubes, empresas tecnológicas, startups y a todo el mundo que ha construido un producto basado en Istio, o que ofrece Istio con su servicio gestionado de Kubernetes. Esperamos seguir colaborando.

Por último, queremos agradecer a Google su labor de “stewardship” de la comunidad de Istio hasta la fecha, sus contribuciones inconmensurables a Istio y su apoyo continuo durante esta transición.

{{< image
    link="./istio-has-applied-to-join-the-cncf.jpg"
    alt="Istio ha solicitado unirse a la CNCF"
    >}}

## Ver también

Para más perspectivas sobre la noticia de hoy, por favor lee las entradas de blog de [Google](https://cloud.google.com/blog/products/open-source/submitting-istio-project-to-the-cncf), [IBM](https://developer.ibm.com/blogs/welcoming-istios-submission-to-the-cncf/), [Tetrate](https://www.tetrate.io/blog/istio-has-applied-to-join-the-cncf/), [VMware](https://tanzu.vmware.com/content/blog/istio-mode-tanzu-service-mesh), [Solo.io](https://solo.io/blog/istio-past-present-future), [Aspen Mesh](https://aspenmesh.io/aspen-mesh-supports-istio-joining-cncf-as-open-source-technology/) y [Red Hat](https://www.redhat.com/en/blog/istio-service-mesh-applies-become-cncf-project).
