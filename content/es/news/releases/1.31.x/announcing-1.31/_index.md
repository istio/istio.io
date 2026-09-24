---
title: Anuncio de Istio 1.31.0
linktitle: 1.31.0
subtitle: Versión Principal
description: Anuncio de la versión Istio 1.31.
publishdate: 2026-08-31
release: 1.31.0
aliases:
    - /news/announcing-1.31
    - /news/announcing-1.31.0
---

Nos complace anunciar el lanzamiento de Istio 1.31. ¡Gracias a todos nuestros contribuidores, testers, usuarios y entusiastas por ayudarnos a publicar la versión 1.31.0!
Queremos agradecer a los Release Managers de esta versión: **Jacek Ewertowski** de Red Hat, **Jackson Greer** de Microsoft y **Jianpeng He** de Tetrate.

{{< relnote >}}

{{< tip >}}
Istio 1.31.0 tiene soporte oficial para Kubernetes versiones 1.32 a 1.36.
{{< /tip >}}

## Obsolescencia de la infraestructura y el alojamiento en GCP

A partir de Istio 1.31, ya no publicaremos artefactos en `gcr.io/istio-release`, `registry.istio.io` ni `istio-release.storage.googleapis.com`.

- Las imágenes Docker seguirán disponibles en Docker Hub.
- Los charts de Helm estarán disponibles en `blob.istio.io/istio-release/charts`.
- Otros artefactos estarán disponibles en `blob.istio.io/istio-release`.
- Los charts OCI de Helm estarán disponibles en `ghcr.io/istio/release/charts`.

Realizaremos pruebas de eliminación en las que deshabilitaremos todos los artefactos alojados en GCP durante períodos breves.

La primera prueba será el 15 de septiembre de 2026, de 15:00 a 16:00 UTC.
La segunda prueba será el 13 de octubre de 2026, de 15:00 a 18:00 UTC.
La tercera prueba será el 17 de noviembre de 2026, de 15:00 a 21:00 UTC.
La cuarta y última prueba será del 8 de diciembre de 2026 a las 15:00 UTC al 9 de diciembre de 2026 a las 15:00 UTC.

Para más detalles, consulta [esta entrada de blog](/blog/2026/retirement-of-gcp/).

## ¿Qué hay de nuevo?

### Agentgateway como waypoint

Basándose en el soporte experimental solo para gateway introducido en 1.30, Istio 1.31 añade la `GatewayClass` `istio-agentgateway-waypoint` para desplegar [agentgateway](https://agentgateway.dev) como proxy waypoint. Esta versión también corrige varios problemas con el manejo de `ListenerSet` y la conectividad mTLS para backends de agentgateway.

### Gateway API: `AllowInsecureFallback`

Istio implementa ahora la funcionalidad `AllowInsecureFallback` de Gateway API para la validación de certificados de cliente. Cuando está habilitada, el gateway solicita un certificado de cliente e intenta validarlo, pero permite la conexión aunque no se presente ningún certificado o la validación falle. La cabecera `x-forwarded-client-cert` se rellena para que los backends puedan realizar su propia verificación.

### Mejoras del modo ambient

- **Canaries de waypoint con peso.** Un servicio o namespace ahora puede referenciar tanto un waypoint primario como uno canary mediante las etiquetas `istio.io/use-waypoint-canary` y `istio.io/use-waypoint-canary-namespace`. La anotación `istio.io/use-waypoint-canary-weight` dirige un porcentaje configurable de conexiones en la mesh al waypoint canary sin cambios en el cliente, permitiendo el despliegue gradual de cambios en la configuración del waypoint.
- **Estabilidad multi-clúster.** Esta versión incluye numerosas correcciones del modo ambient, especialmente en despliegues multi-clúster: la rotación de credenciales ya no provoca snapshots obsoletos ni pérdida de fragmentos de endpoint, se han resuelto varias fugas de memoria y goroutines en modo multi-clúster, y las correcciones del agente CNI de nodo solucionan un panic por escritura concurrente en un mapa, una fuga de descriptores de archivo y un deadlock durante la eliminación de pods.

### Novedades en la gestión de tráfico

- **Balanceo de carga por zona.** Un nuevo campo `zoneAwareLbSetting` en `DestinationRule.TrafficPolicy.LoadBalancerSettings` y `MeshConfig` permite que Envoy enrute automáticamente el tráfico a endpoints en la misma zona de disponibilidad que el proxy downstream, derivando a otras zonas solo cuando la capacidad local es insuficiente. Esto difiere del `localityLbSetting` existente en que el enrutamiento por zona es gestionado automáticamente por Envoy en lugar de usar porcentajes estáticos. Se puede configurar el orden de failover entre regiones y niveles de prioridad basados en etiquetas.
- **Política de tráfico predeterminada en toda la mesh.** Un nuevo `defaultTrafficPolicy` en `MeshConfig` permite a los administradores de la mesh establecer un `connectionPool` y `outlierDetection` base que heredan todos los clústeres de salida. Una `DestinationRule` que establezca uno de estos bloques anula la base para ese bloque; los campos que no establezca heredan ahora la base de la mesh en lugar de los valores predeterminados integrados de Istio. El `connectionPool` base también se aplica a los clústeres entrantes y al clúster de passthrough.
- **Proxy de reenvío dinámico para hosts desconocidos.** Un nuevo modo de política de tráfico de salida `ALLOW_ANY_DYNAMIC_DNS` resuelve nombres de host del encabezado HTTP `Host` en tiempo de solicitud mediante el Dynamic Forward Proxy de Envoy, eliminando la necesidad de recursos `ServiceEntry` para cada destino externo. El tráfico no HTTP sigue usando `PassthroughCluster`. La originación TLS upstream opcional se puede configurar mediante `meshConfig.outboundTrafficPolicy.tls`.
- **Exclusión de hosts en el egress del sidecar.** Los listeners de egress de `Sidecar` ahora admiten un prefijo `~` en las entradas de namespace y host para sustraer del conjunto importado. Por ejemplo, `*/*` más `~ns1/*` importa todo excepto el namespace `ns1`. Esto permite que las meshes grandes excluyan unos pocos namespaces sin enumerar una larga lista de permisos.

### Seguridad

- **Política de cumplimiento FIPS 140-3.** Un nuevo valor `fips-140-3` para la variable de entorno `COMPLIANCE_POLICY` impone TLS 1.2+ con suites de cifrado conformes con FIPS y curvas P-256/P-384. Los componentes Go deben compilarse con Go 1.24+ usando `GOFIPS140=v1.0.0`.
- **Coincidencia de dominio de confianza en `AuthorizationPolicy`.** Los nuevos campos `trustDomains` y `notTrustDomains` en `Source` permiten coincidir o excluir solicitudes basándose en el dominio de confianza derivado del certificado de par.
- **Fusión estricta de gateways.** `PILOT_ENABLE_STRICT_GATEWAY_MERGING` (habilitado por defecto) evita la fusión entre namespaces de CRDs `Gateway` de Istio con proxies `Gateway` de Gateway API administrados.
- **Autenticación del generador de API XDS.** El endpoint de servicio de configuración MCP ahora requiere una identidad de control plane verificada. El tráfico estándar de sidecar, gateway y ztunnel no se ve afectado.

### Instalación y operatividad

- **Kiali** actualizado a v2.26.0.
- **Hilos de trabajo con conciencia de CPU en ztunnel** mediante las variables de entorno `ZTUNNEL_RESOURCE_CPU_LIMIT` y `ZTUNNEL_RESOURCE_CPU_REQUEST`.
- **El flag `istioctl manifest generate -o`** escribe los manifiestos generados en un archivo en lugar de stdout.
- **`global.readerServiceAccount`** permite vincular el `ClusterRole` `istio-reader` a una cuenta de servicio personalizada.

### Telemetría

- **Scraping de Prometheus con múltiples destinos.** Una nueva anotación de pod `prometheus.istio.io/scrape-targets` permite declarar múltiples endpoints de métricas de aplicación por pod como una lista de `port:path` separada por comas. Pilot-agent los recopila de forma concurrente y fusiona la salida.
- **Puertos de métricas seguros.** Las nuevas variables de entorno `ENVOY_SECURE_METRICS_PORT` y `ENVOY_SECURE_MERGED_METRICS_PORT` exponen endpoints de scraping de Prometheus protegidos con mTLS en cada proxy sidecar.
- **Interruptor de fusión de estadísticas de Envoy.** `PILOT_AGENT_MERGE_ENVOY_STATS` puede establecerse en `false` para deshabilitar la fusión de estadísticas de Envoy en el endpoint de estadísticas del agente.

### Y mucho más

- **`connectionSettings` en `ProxyConfig`** con un perfil `EDGE` orientado a proxies gateway
- **Operación de parche `MERGE_AND_REPLACE_LIST` en `EnvoyFilter`** para reemplazar campos de lista en vez de añadir
- **`prefix_rewrite` en `HTTPRedirect`** para reescritura de ruta con conciencia de prefijo en reglas de redirección
- **Configuración de keepalive PING de HTTP/2** configurable en conexiones upstream mediante `DestinationRule`
- **Control de visibilidad de `ServiceEntry`** mediante `meshConfig.serviceEntryVisibility`
- **Campo `budget_interval`** en la API `RetryBudget` de `TrafficPolicy`
- **Advertencias de `istioctl analyze`** para protocolos conflictivos en `ServiceEntry` y CRDs de Gateway API desactualizados

Lee sobre estas y más mejoras en las [notas de versión](change-notes/) completas.

## Actualización a 1.31

Nos gustaría conocer tu experiencia al actualizar a Istio 1.31. Puedes enviarnos tus comentarios en el canal `#release-1_31` de nuestro [espacio de trabajo de Slack](https://slack.istio.io/).

¿Te gustaría contribuir directamente a Istio? Encuentra y únete a uno de nuestros [Grupos de Trabajo](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) y ayúdanos a mejorar.
