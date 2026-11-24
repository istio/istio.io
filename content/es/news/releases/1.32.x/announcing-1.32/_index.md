---
title: Anuncio de Istio 1.32.0
linktitle: 1.32.0
subtitle: Versión Principal
description: Anuncio de la versión Istio 1.32.
publishdate: 2026-11-09
release: 1.32.0
aliases:
    - /news/announcing-1.32
    - /news/announcing-1.32.0
---

Nos complace anunciar el lanzamiento de Istio 1.32. ¡Gracias a todos nuestros contribuidores, testers, usuarios y entusiastas por ayudarnos a publicar la versión 1.32.0!
Queremos agradecer a los Release Managers de esta versión: **Jackson Greer** de Microsoft, **Jianpeng He** de Tetrate y **Jack Kawell** de Solo.io.

{{< relnote >}}

{{< tip >}}
Istio 1.32.0 tiene soporte oficial para Kubernetes versiones 1.33 a 1.37.
{{< /tip >}}

## ¿Qué hay de nuevo?

### Gateway API

- **`AuthorizationPolicy` dirigida a `HTTPRoute`.** Como función experimental, `AuthorizationPolicy` ahora puede apuntar a recursos `HTTPRoute` de Gateway API mediante `targetRefs`, de modo que las reglas `ALLOW` y `DENY` se apliquen solo al tráfico que coincida con esa ruta.
- **Ajuste de TLS en gateways.** Los gateways que terminan TLS pueden sobrescribir los protocolos ALPN anunciados con `alpnProtocols` y configurar las curvas ECDH con `ecdhCurves`.
- **Soporte experimental de `XBackend`** para describir cómo deben conectarse los clientes a destinos específicos.
- **`agentgateway`** ahora respeta la validación de certificados de cliente del frontend de Gateway API.

### Modo ambient

- **Un único gateway east-west para meshes mixtas.** Un gateway `istio-east-west` ahora también puede servir tráfico multired de sidecars mediante un listener `AUTO_PASSTHROUGH` en el puerto 15443, de modo que una mesh con workloads ambient y sidecar ya no necesita un gateway east-west independiente para los sidecars de cada clúster. Requiere `AMBIENT_ENABLE_MULTI_NETWORK`.

### Gestión del tráfico

- **Balanceo de carga basado en utilización.** Una nueva política `backendUtilization` en `DestinationRule` usa los reportes de carga ORCA enviados por los backends para dirigir menos solicitudes a los endpoints más ocupados.
- **Detección de valores atípicos más completa.** `DestinationRule.OutlierDetection` añade `outlierDetectionHttpErrorCodes`, para elegir qué códigos de estado HTTP cuentan como errores, y `failurePercentageThreshold`, para expulsar hosts según la tasa de fallos.
- **Reintentos de entrada configurables.** El nuevo campo `defaultInboundHttpRetryPolicy` de la configuración de la mesh configura la política de reintentos por defecto en las rutas de entrada de los sidecars, o la deshabilita con `{}`.
- **Coincidencia de transport socket en `EnvoyFilter`.** Las coincidencias de cadenas de filtros ahora pueden seleccionar por `transportSocket`, de modo que los parches apunten con precisión a las cadenas que terminan TLS.
- **`ProxyConfig` con selectores para toda la mesh.** Los recursos `ProxyConfig` con selectores de workload en el namespace raíz ahora se aplican a los workloads coincidentes en todos los namespaces.

### Seguridad

- **`presence` para reglas JWT.** Las `jwtRules` de `RequestAuthentication` pueden marcarse como `REQUIRED`, rechazando las solicitudes que carezcan de ese token incluso cuando se cumplan otras reglas.
- **`PILOT_DISABLE_SELF_SIGNED_CA`** hace que istiod falle al iniciar su CA en lugar de generar o reutilizar una raíz autofirmada.

### Telemetría

- **Histogramas nativos de Prometheus.** El fusionador de métricas de `pilot-agent` pasa el formato protobuf de Prometheus cuando los scrapers lo solicitan, con un nuevo contador `istio_agent_scrape_format_total` que reporta el formato negociado.

### Y mucho más

- **Los servicios TCP headless** pueden optar por un único listener comodín en lugar de un listener por IP de pod
- Advertencia del analizador **`IST0178`** cuando un `EnvoyFilter` inserta un filtro HTTP junto a una `AuthorizationPolicy` que apunta a un `HTTPRoute`
- Advertencias de validación de **`ServiceEntry`** para direcciones catch-all y muy amplias
- **Timeouts del cliente de la API de Kubernetes** en los componentes de Istio, configurables mediante `ISTIO_KUBE_HEADER_TIMEOUT` y `ISTIO_KUBE_REQUEST_TIMEOUT`
- **`GOMAXPROCS`** eliminado de todos los charts, ya que Go ahora lo establece automáticamente a partir de los límites de CPU

Lee sobre estas y otras novedades en las [notas de la versión](change-notes/) completas.

## Actualizar a 1.32

Nos gustaría conocer tu experiencia al actualizar a Istio 1.32. Puedes enviarnos tus comentarios en el canal `#release-1_32` de nuestro [espacio de trabajo de Slack](https://slack.istio.io/).

¿Te gustaría contribuir directamente a Istio? Encuentra y únete a uno de nuestros [Grupos de Trabajo](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) y ayúdanos a mejorar.
