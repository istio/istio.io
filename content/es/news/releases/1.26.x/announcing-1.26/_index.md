---
title: Anuncio de Istio 1.26.0
linktitle: 1.26.0
subtitle: Versión Principal
description: Anuncio de la versión Istio 1.26.
publishdate: 2025-05-08
release: 1.26.0
aliases:
    - /news/announcing-1.26
    - /news/announcing-1.26.0
---

Nos complace anunciar el lanzamiento de Istio 1.26. ¡Gracias a todos nuestros contribuidores, testers, usuarios y entusiastas por ayudarnos a publicar la versión 1.26.0!
Queremos agradecer a los Release Managers de esta versión: **Daniel Hawton** de Solo.io, **Faseela K** de Ericsson Software Technology y **Gustavo Meira** de Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.26.0 tiene soporte oficial para Kubernetes versiones 1.29 a 1.32. Esperamos que la versión 1.33 también funcione y planeamos agregar pruebas y soporte antes de Istio 1.26.1.
{{< /tip >}}

## Una nota sobre el soporte de `EnvoyFilter` en modo ambient

`EnvoyFilter` es la API de break-glass de Istio para la configuración avanzada de los proxies Envoy. Ten en cuenta que *`EnvoyFilter` no está soportado actualmente en ninguna versión de Istio con waypoint proxies*. Si bien es posible usar `EnvoyFilter` con waypoints en escenarios limitados, su uso no está soportado y los maintainers lo desaconsejan activamente. La API alpha puede cambiar en versiones futuras a medida que evoluciona. Esperamos que el soporte oficial esté disponible en una fecha posterior.

## ¿Qué hay de nuevo?

### Personalización de recursos aprovisionados por el Gateway API

Cuando creas un Gateway o un waypoint con el Gateway API, se crean automáticamente un `Service` y un `Deployment`. Personalizar estos objetos ha sido una solicitud frecuente; ahora es posible en Istio 1.26 mediante un `ConfigMap` de parámetros. Si se proporciona configuración para un `HorizontalPodAutoscaler` o `PodDisruptionBudget`, esos recursos también se crean automáticamente. [Obtén más información sobre cómo personalizar los recursos del Gateway API generados.](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)

### Nuevo soporte de Gateway API

[`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/) ya está disponible en waypoints, lo que permite el desvío de tráfico TCP en modo ambient.

También añadimos soporte para el experimental [`BackendTLSPolicy`](https://gateway-api.sigs.k8s.io/api-types/backendtlspolicy/) e iniciamos la implementación de [`BackendTrafficPolicy`](https://gateway-api.sigs.k8s.io/api-types/backendtrafficpolicy/) en Gateway API 1.3, que eventualmente establecerá restricciones de reintento.

### Soporte para el nuevo `ClusterTrustBundle` de Kubernetes

Añadimos soporte experimental para [el recurso experimental `ClusterTrustBundle` en Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#cluster-trust-bundles), habilitando el nuevo método de agrupar un certificado y su raíz de confianza en un solo objeto.

### Y mucho más

* ¡`istioctl analyze` ahora puede ejecutar comprobaciones específicas!
* ¡El agente de nodo CNI ya no se ejecuta en el namespace `hostNetwork` por defecto, reduciendo la posibilidad de conflictos de puertos con otros servicios del host!
* ¡Los recursos `ResourceQuota` necesarios y los valores de `cniBinDir` se configuran automáticamente al instalar en GKE!
* ¡Un `EnvoyFilter` ahora puede coincidir con un `VirtualHost` por nombre de dominio!

Lee más sobre estos cambios en las [notas de versión](change-notes/) completas.

## Mantente al día con el proyecto Istio

Si solo nos visitas cuando publicamos una nueva versión, puede que te hayas perdido que [publicamos una auditoría de seguridad sobre ztunnel](/blog/2025/ztunnel-security-assessment/), [comparamos el rendimiento del throughput en modo ambient frente a la ejecución en el kernel](/blog/2025/ambient-performance/) o que [tuvimos una gran presencia en KubeCon EU](/blog/2025/istio-at-kubecon-eu/). ¡No te los pierdas!

## Actualización a 1.26

Nos gustaría conocer tu experiencia al actualizar a Istio 1.26. Puedes enviarnos tus comentarios en el canal `#release-1.26` de nuestro [espacio de trabajo de Slack](https://slack.istio.io/).

¿Te gustaría contribuir directamente a Istio? Encuentra y únete a uno de nuestros [Grupos de Trabajo](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) y ayúdanos a mejorar.
