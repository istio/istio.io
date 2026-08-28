---
title: Anuncio de Istio 1.28.0
linktitle: 1.28.0
subtitle: Versión Mayor
description: Anuncio de la versión Istio 1.28.
publishdate: 2025-11-05
release: 1.28.0
aliases:
    - /news/announcing-1.28
    - /news/announcing-1.28.0
---

Nos complace anunciar el lanzamiento de Istio 1.28. ¡Gracias a todos nuestros colaboradores, testers, usuarios y entusiastas por ayudarnos a publicar la versión 1.28.0!
Nos gustaría agradecer a los Release Managers de esta versión, **Gustavo Meira** de Microsoft, **Francisco Herrera** de Red Hat, y **Darrin Cecil** de Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.28.0 tiene soporte oficial en las versiones de Kubernetes 1.29 a 1.34.
{{< /tip >}}

## ¿Qué hay de nuevo?

### Soporte para Inference Extension

Istio 1.28 continúa construyendo sobre el soporte de la Gateway API Inference Extension con la introducción de `InferencePool` v1. Esta mejora proporciona una mejor gestión y enrutamiento de cargas de trabajo de inferencia de IA, facilitando el despliegue y escalado de modelos de IA generativa en Kubernetes con gestión inteligente del tráfico.

La API `InferencePool` v1 ofrece mayor estabilidad y funcionalidad para gestionar pools de endpoints de inferencia, habilitando estrategias más sofisticadas de balanceo de carga y failover para cargas de trabajo de IA.

### Multiclúster en modo Ambient

Istio 1.28 trae mejoras significativas para los despliegues multiclúster en modo ambient. Los waypoints ahora pueden enrutar tráfico a redes remotas en configuraciones multiclúster ambient, expandiendo las capacidades ambient. Esta mejora habilita la detección de anomalías y otras políticas L7 para solicitudes que cruzan redes, facilitando la gestión de despliegues de service mesh multi-red.

El multiclúster ambient sigue siendo una característica alpha y hay varios problemas conocidos que se abordarán en versiones futuras. Si los cambios recientes afectaron negativamente a tu despliegue multiclúster ambient, es posible deshabilitar el cambio de comportamiento reciente del waypoint configurando la variable de entorno pilot `AMBIENT_ENABLE_MULTI_NETWORK_WAYPOINT` a `false`.

Agradecemos los comentarios y reportes de errores de los primeros adoptantes del multiclúster ambient.

### Soporte nativo de nftables en modo Ambient

Istio 1.28 introduce soporte para nftables nativo en modo ambient. Esta mejora significativa te permite usar nftables en lugar de iptables para gestionar las reglas de red, proporcionando una gestión de reglas más flexible. Para habilitar el modo nftables, usa `--set values.global.nativeNftables=true` al instalar Istio.

Esta adición complementa el soporte de nftables existente en modo sidecar, asegurando que Istio se mantenga actualizado con los marcos de red modernos de Linux.

### Soporte Dual-stack promovido a Beta

El soporte de red dual-stack de Istio ha sido promovido a beta en esta versión. Este avance proporciona capacidades robustas de red IPv4/IPv6, permitiendo a las organizaciones desplegar Istio en entornos de red modernos que requieren ambas versiones del protocolo IP.

### Mejoras de Seguridad

Esta versión incluye varias mejoras de seguridad importantes:

- **Autenticación JWT mejorada**: La configuración mejorada del filtro JWT ahora soporta claims personalizados delimitados por espacios además de los claims predeterminados como "scope" y "permission". Esta mejora garantiza la validación correcta de tokens JWT con claims personalizados usando el campo `spaceDelimitedClaims` en los recursos `RequestAuthentication`
- **Soporte de `NetworkPolicy`**: Despliegue opcional de `NetworkPolicy` para istiod con `global.networkPolicy.enabled=true`
- **Seguridad de contenedor mejorada**: Soporte para configurar `seccompProfile` en los contenedores istio-validation e istio-proxy para un mejor cumplimiento de seguridad
- **Seguridad de la Gateway API**: Soporte para `FrontendTLSValidation` (GEP-91) habilitando configuraciones de gateway de ingreso mTLS mutuo
- **Manejo de certificados mejorado**: Mejor análisis de certificados raíz que filtra los certificados mal formados en lugar de rechazar el bundle completo

### Mejoras en Gateway API y Gestión de Tráfico

- **`BackendTLSPolicy` v1**: Soporte completo de Gateway API v1.4 con opciones de configuración TLS mejoradas
- **Integración de `ServiceEntry`**: Soporte para `ServiceEntry` como `targetRef` en `BackendTLSPolicy` para la configuración TLS de servicios externos
- **Soporte de host comodín**: Los recursos `ServiceEntry` ahora soportan hosts comodín con resolución `DYNAMIC_DNS` (solo tráfico HTTP, requiere modo ambient y waypoint)

### Y mucho más

- **Instalaciones basadas en persona**: Nueva opción `resourceScope` en los charts de Helm para la gestión de recursos con alcance de namespace o clúster
- **Balanceo de carga mejorado**: Soporte de atributos de cookies en el balanceo de carga con hash consistente con opciones de seguridad como `SameSite`, `Secure` y `HttpOnly`
- **Telemetría mejorada**: Soporte de propagación dual de cabeceras B3/W3C para una mejor interoperabilidad de trazado
- **Mejoras de istioctl**: Detección automática de revisión predeterminada y capacidades de depuración mejoradas

Lee sobre estos y más en las [notas de versión](change-notes/) completas.

## Actualización a 1.28

Nos gustaría saber tu experiencia al actualizar a Istio 1.28. Puedes proporcionar comentarios en el canal `#release-1.28` de nuestro [espacio de trabajo de Slack](https://slack.istio.io/).

¿Te gustaría contribuir directamente a Istio? Encuentra y únete a uno de nuestros [Grupos de Trabajo](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) y ayúdanos a mejorar.
