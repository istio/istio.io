---
title: Anuncio de Istio 1.25.0
linktitle: 1.25.0
subtitle: Versión Principal
description: Anuncio de la versión Istio 1.25.
publishdate: 2025-03-03
release: 1.25.0
aliases:
- /news/announcing-1.25
- /news/announcing-1.25.0
---

Nos complace anunciar el lanzamiento de Istio 1.25. ¡Gracias a todos nuestros contribuidores, testers, usuarios y entusiastas por ayudarnos a publicar la versión 1.25.0!
Nos gustaría agradecer a los Release Managers de esta versión, **Mike Morris** de Microsoft, **Faseela K** de Ericsson Software Technology y **Daniel Hawton** de Solo.io.

{{< relnote >}}

{{< tip >}}
Istio 1.25.0 tiene soporte oficial en las versiones de Kubernetes `1.29` a `1.32`.
{{< /tip >}}

## ¿Qué hay de nuevo?

### DNS proxying activado por defecto en modo ambient

Istio enruta el tráfico principalmente basándose en cabeceras HTTP. En modo ambient, ztunnel solo ve el tráfico en la Capa 4 y no tiene acceso a las cabeceras HTTP. Por eso, el DNS proxying es necesario para habilitar la resolución de direcciones de `ServiceEntry`, especialmente al [enviar tráfico de salida a waypoints](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient#scenario-ztunnel-is-not-sending-egress-traffic-to-waypoints).

Para simplificar esto en el caso por defecto, el DNS proxying está habilitado de forma predeterminada en las instalaciones de Istio 1.25 con modo ambient. Se ha añadido una anotación para que los workloads puedan optar por no usar el DNS proxying. Consulta las [notas de actualización](upgrade-notes/#ambient-mode-dns-capture-on-by-default) para más información.

### Política de denegación por defecto disponible para waypoints

En modo sidecar, la política de autorización se vincula a los workloads mediante un selector. En modo ambient, las políticas dirigidas por selector solo las aplica ztunnel. Los waypoint proxies usan el enlace al estilo de Gateway API con el campo `targetRef`. Esto generaba una configuración donde un workload tenía denegación por defecto para comunicarse con un endpoint, pero podía esquivar esa configuración conectándose a un waypoint que _sí_ tenía permiso, alcanzando así el endpoint de todas formas.

En esta versión, hemos añadido la posibilidad de dirigir políticas a un `GatewayClass` o a un `Gateway` concretos. Esto permite establecer una política sobre la clase `istio-waypoint`, que se aplica a todas las instancias de un waypoint.

### Mejoras en el enrutamiento zonal

Controlar el tráfico entre zonas y regiones es a menudo una operación crítica del "día 2" para los usuarios, ya sea por fiabilidad, rendimiento o coste. Con Istio 1.25, esto se vuelve aún más sencillo.

La característica de [distribución de tráfico de Kubernetes](https://kubernetes.io/docs/concepts/services-networking/service/#traffic-distribution) está ahora totalmente soportada, ofreciendo una interfaz simplificada para mantener el tráfico local. Los ajustes de [balanceo de carga por localidad](/docs/tasks/traffic-management/locality-load-balancing/) existentes en Istio siguen disponibles para casos de uso más complejos.

En modo ambient, ztunnel reportará ahora las etiquetas adicionales `source_zone`, `source_region`, `destination_zone` y `destination_region` en todas las métricas, ofreciendo una visión clara del tráfico entre zonas.

### Otras novedades

- Se ha añadido la posibilidad de proporcionar una lista de interfaces virtuales cuyo tráfico entrante se tratará incondicionalmente como saliente. Esto permite que los workloads que usan redes virtuales (KubeVirt, VMs, docker-in-docker, etc.) funcionen correctamente con la captura de tráfico tanto en modo sidecar como en modo ambient.
- El DaemonSet `istio-cni` puede ahora actualizarse de forma segura in situ en un clúster activo, sin necesidad de acordonar nodos para evitar que los pods creados durante la actualización escapen de la captura de tráfico ambient.

Consulta las [notas de cambios completas](change-notes/) para ver todo lo demás que hay de nuevo.

## Actualización a 1.25

Nos gustaría saber tu experiencia al actualizar a Istio 1.25. Puedes enviar tus comentarios en el canal `#release-1.25` de nuestro [espacio de trabajo de Slack](https://slack.istio.io/).

¿Te gustaría contribuir directamente a Istio? Encuentra y únete a uno de nuestros [Grupos de Trabajo](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) y ayúdanos a mejorar.

¿Vas a KubeCon Europe 2025? No te pierdas el evento co-ubicado [Istio Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/istio-day/) para ver charlas increíbles, o pásate por el [stand del proyecto Istio](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/features-add-ons/project-engagement/#project-kiosk-directory/) para conversar.
