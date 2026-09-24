---
title: Anuncio de Istio 1.27.0
linktitle: 1.27.0
subtitle: Versión Principal
description: Anuncio de la versión Istio 1.27.
publishdate: 2025-08-11
release: 1.27.0
aliases:
    - /news/announcing-1.27
    - /news/announcing-1.27.0
---

Nos complace anunciar el lanzamiento de Istio 1.27. ¡Gracias a todos nuestros contribuidores, testers, usuarios y entusiastas por ayudarnos a publicar la versión 1.27.0!
Queremos agradecer a los Release Managers de esta versión: **Jianpeng He** de Tetrate, **Faseela K** de Ericsson Software Technology y **Gustavo Meira** de Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.27.0 tiene soporte oficial para Kubernetes versiones 1.29 a 1.33.
{{< /tip >}}

## ¿Qué hay de nuevo?

### Soporte para Inference Extension

[Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/) es un proyecto oficial de Kubernetes diseñado para optimizar el autoalojamiento de modelos de IA generativa en Kubernetes. Ofrece un enfoque estandarizado y neutro respecto al proveedor para la gestión inteligente del tráfico de IA.

Istio 1.27 incluye una [implementación totalmente compatible](https://gateway-api-inference-extension.sigs.k8s.io/implementations/gateways/#istio) de la extensión cuando se usa la Gateway API para controlar el tráfico de entrada al clúster.

[Conoce más sobre la extensión y la implementación de Istio](/blog/2025/inference-extension-support/).

### Ambient multiclúster

El soporte para despliegues en múltiples clústeres en modo ambient ya está disponible en Alpha. Esto permite conectar varios clústeres en modo ambient al mismo mesh, ampliando el alcance de la red sin sidecar a entornos más grandes y distribuidos.

En esta versión inicial, las pruebas se han centrado en topologías multi-red y multi-primario, donde cada clúster ejecuta su propio control plane. El soporte para topologías más complejas llegará a medida que la funcionalidad base madure.

### Soporte CRL para CAs conectadas

El soporte para listas de revocación de certificados (CRL) ya está disponible para los usuarios que han conectado su propia autoridad de certificación, en lugar de usar la predeterminada de Istio. Esto permite a los proxies validar y rechazar certificados revocados, mejorando la postura de seguridad de los despliegues de mesh que usan CAs conectadas.

### Soporte para ListenerSets

La nueva API [ListenerSets](https://gateway-api.sigs.k8s.io/geps/gep-1713) te permite definir un conjunto reutilizable de listeners que se pueden adjuntar a un recurso `Gateway`. Esto promueve la consistencia y reduce la duplicación al gestionar múltiples Gateways que comparten configuraciones comunes de listeners.

### Soporte nativo de nftables en modo sidecar

Istio ahora admite el backend [nativo de nftables](https://github.com/istio/istio/issues/47821) en modo sidecar. nftables es el sucesor moderno de iptables y ofrece mejor rendimiento, mayor facilidad de mantenimiento y una gestión más flexible de reglas para la redirección transparente del tráfico hacia y desde el proxy sidecar de Envoy.

Muchas distribuciones de Linux importantes están adoptando nftables como framework predeterminado de filtrado de paquetes, y el soporte nativo de Istio garantiza la compatibilidad con este cambio.

El soporte para nftables en modo ambient está en desarrollo activo y llegará en una versión futura.

## Actualización a 1.27

Nos gustaría conocer tu experiencia al actualizar a Istio 1.27. Puedes enviarnos tus comentarios en el canal `#release-1.27` de nuestro [espacio de trabajo de Slack](https://slack.istio.io/).

¿Te gustaría contribuir directamente a Istio? Encuentra y únete a uno de nuestros [Grupos de Trabajo](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) y ayúdanos a mejorar.
