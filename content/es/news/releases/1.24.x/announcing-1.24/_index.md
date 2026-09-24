---
title: Anuncio de Istio 1.24.0
linktitle: 1.24.0
subtitle: Versión Principal
description: Anuncio de la versión Istio 1.24.
publishdate: 2024-11-07
release: 1.24.0
aliases:
- /news/announcing-1.24
- /news/announcing-1.24.0
---

Nos complace anunciar el lanzamiento de Istio 1.24. ¡Gracias a todos nuestros contribuidores, testers, usuarios y entusiastas por ayudarnos a publicar la versión 1.24.0!
Nos gustaría agradecer a los Release Managers de esta versión, **Zhonghu Xu** de Huawei, **Mike Morris** de Microsoft, y **Daniel Hawton** de Solo.io.

{{< relnote >}}

{{< tip >}}
Istio 1.24.0 tiene soporte oficial en las versiones de Kubernetes `1.28` a `1.31`.
{{< /tip >}}

## ¿Qué hay de nuevo?

### El modo Ambient alcanza disponibilidad general

¡Nos entusiasma anunciar la [Disponibilidad General del modo ambient de Istio](/blog/2024/ambient-reaches-ga/)! Las características principales (ztunnel, waypoints y las APIs) han sido marcadas como Estables por el TOC de Istio. Esto marca la etapa final en la [progresión de fases de características](/docs/releases/feature-stages/) de Istio, señalando que las características están completamente listas para uso en producción.

Desde su [anuncio en 2022](/blog/2022/introducing-ambient-mesh/), la comunidad ha trabajado intensamente en [innovaciones](/blog/2024/inpod-traffic-redirection-ambient/), [escalado](/blog/2024/ambient-vs-cilium/), [estabilización](/blog/2024/ambient-reaches-beta/) y ajuste del modo ambient para estar listo para producción.

Además de [innumerables cambios desde la versión Beta](/news/releases/1.23.x/announcing-1.23/#ambient-ambient-ambient), Istio 1.24 incluye varias mejoras al modo ambient:

* Se escriben nuevos mensajes de `status` en una variedad de recursos, incluyendo `Services` y `AuthorizationPolicies`, para ayudar a entender el estado actual del objeto.
* Ahora se pueden adjuntar políticas directamente a `ServiceEntry`s. ¡Pruébalo con un [egress gateway](https://www.solo.io/blog/egress-gateways-made-easy/) simplificado!
* Una nueva [guía de resolución de problemas](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient) exhaustiva. Afortunadamente, varias correcciones de errores en Istio 1.24 hacen que muchos de estos pasos ya no sean necesarios.
* Numerosas correcciones de errores. En particular, se han resuelto casos extremos relacionados con pods con múltiples interfaces, visibilidad intranode en GKE, clústeres solo IPv4, y muchos otros problemas.

### Reintentos mejorados

Los [reintentos](/docs/concepts/traffic-management/#retries) automáticos han sido una parte central de la gestión de tráfico de Istio. En Istio 1.24 mejoran aún más.

Anteriormente, los reintentos se implementaban exclusivamente en el *sidecar del cliente*. Sin embargo, una fuente común de fallos de conexión proviene de la comunicación entre el *sidecar del servidor* y la aplicación del servidor, típicamente al intentar reutilizar una conexión que el backend está cerrando. Con esta mejora, podemos detectar este caso y reintentar automáticamente en el sidecar del servidor.

Además, se ha eliminado la política predeterminada de reintentar errores `503`, que se añadió inicialmente para manejar los tipos de fallos descritos anteriormente, pero que tenía efectos negativos en algunas aplicaciones.

## Actualización a 1.24

Nos gustaría saber tu experiencia al actualizar a Istio 1.24. Puedes proporcionar comentarios en el canal `#release-1.24` de nuestro [espacio de trabajo de Slack](https://slack.istio.io/).

¿Te gustaría contribuir directamente a Istio? Encuentra y únete a uno de nuestros [Grupos de Trabajo](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) y ayúdanos a mejorar.

¿Vas a KubeCon North America 2024? Pasa por el evento co-ubicado [Istio Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/) para ver [charlas increíbles](/blog/2024/kubecon-na/), o visita el [stand del proyecto Istio](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/venue-travel/#venue-maps) para conversar.
