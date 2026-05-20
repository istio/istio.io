---
title: Anuncio de Istio 1.30.0
linktitle: 1.30.0
subtitle: Versión Mayor
description: Anuncio de la versión Istio 1.30.
publishdate: 2026-05-18
release: 1.30.0
aliases:
    - /news/announcing-1.30
    - /news/announcing-1.30.0
---

Nos complace anunciar el lanzamiento de Istio 1.30. ¡Gracias a todos nuestros colaboradores, testers, usuarios y entusiastas por ayudarnos a publicar la versión 1.30.0!
Nos gustaría agradecer a los Release Managers de esta versión, **Petr McAllister** de Solo.io, **Jacek Ewertowski** de Red Hat, y **Jackson Greer** de Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.30.0 tiene soporte oficial en las versiones de Kubernetes 1.32 a 1.36.
{{< /tip >}}

## ¿Qué hay de nuevo?

### Agentgateway: nueva implementación experimental de gateway

Istio 1.30 incluye soporte experimental para [agentgateway](https://agentgateway.dev) como implementación de la Gateway API. Agentgateway es un nuevo proxy del data plane construido para el tráfico de agentes de IA y servidores MCP; cuando está habilitado, reemplaza a Envoy en el pod de gateway. En esta versión está integrado como un único `GatewayClass` (`istio-agentgateway`) y solo es compatible como gateway de la Gateway API, no como sidecar o waypoint. Actívalo configurando `PILOT_ENABLE_AGENTGATEWAY=true` en istiod. Consulta la [documentación de Kubernetes de agentgateway](https://agentgateway.dev/docs/kubernetes/latest/) para detalles de instalación y configuración. Esta es funcionalidad de acceso anticipado. Se esperan asperezas; los comentarios son bienvenidos.

### Mejoras en Gateway API y TLSRoute

Esta versión añade soporte para la terminación y modo mixto de [`TLSRoute`](https://gateway-api.sigs.k8s.io/api-types/tlsroute/), soporte para listeners TLS passthrough en gateways east-west, y reporta `ListenerSets` y rutas adjuntas en el estado del `Gateway`. Combinados, estos cambios acercan la implementación de la Gateway API de Istio a la paridad de características con la especificación integrada y mejoran la operabilidad para los escenarios de gateway multi-tenant.

### Mejoras en el modo Ambient

Varias características ambient llegan en 1.30:

- **Soporte de direcciones CIDR en `ServiceEntry`**. Los recursos `ServiceEntry` ahora pueden usar direcciones CIDR para endpoints, habilitando el enrutamiento ambient para rangos de IPs sin enumerar workloads individuales.
- **Síntesis opcional de XFCC en waypoints**. Con la anotación `ambient.istio.io/xfcc-include-client-identity: "true"` en un `Gateway` de waypoint, el waypoint sintetiza `x-forwarded-client-cert` a partir de la identidad SPIFFE del workload fuente proporcionada por ztunnel, para que las aplicaciones upstream puedan ver el cliente de origen.
- **Configuración del tamaño de ventana HBONE** mediante `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE` y `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`, útil para ajustar los clústeres HBONE CONNECT para workloads ambient de alto rendimiento.
- **Métricas del runtime Tokio en ztunnel** para una visibilidad más clara de los recursos por instancia.
- **Nueva [guía de migración de sidecar a ambient](/docs/ambient/migrate/)**. Una guía paso a paso para migrar un mesh existente basado en sidecar a modo ambient, que cubre la instalación de componentes ambient, la migración de políticas y la habilitación por namespace. La migración está diseñada para ser gradual y reversible; los workloads sidecar y ambient pueden coexistir durante el proceso.

### Adiciones a la Gestión de Tráfico

- **Anotación de distribución de tráfico a nivel de namespace**. Los servicios heredan la distribución de tráfico de la anotación del namespace cuando no está explícitamente configurada en el servicio, reduciendo la configuración por servicio.
- **Anotación `istio.io/connect-strategy` en `ServiceEntry`** con modo `RACE_FIRST_TCP_CONNECT`, útil cuando DNS devuelve múltiples registros A y el cliente debe elegir el primer endpoint que complete con éxito la conexión TCP.
- **Tiempo de espera de DNS upstream** ahora configurable mediante `DNS_FORWARD_TIMEOUT`, con el valor predeterminado existente de `5s` preservado.
- **Soporte de prioridad de failover DNS** para clústeres DNS.
- **Múltiples proveedores de autorización CUSTOM por workload**, habilitando diferentes esquemas de autenticación (OAuth, LDAP, claves API) en diferentes rutas API.
- **[API `TrafficExtension`](/blog/2026/traffic-extension-api/)**, una única API unificada para configurar extensiones Wasm y Lua en sidecars, gateways y waypoints basados en Envoy, reemplazando a `WasmPlugin` como el mecanismo principal de extensibilidad de proxy.

### Soporte de Helm v4

Istio 1.30 añade soporte para Helm v4 (apply del lado del servidor). También se ha abordado un problema duradero con la propiedad del campo `failurePolicy` del webhook durante las actualizaciones. Los usuarios que ejecutan Helm v4 deberían actualizar sin problemas sin las soluciones previas.

### Seguridad

- **Autenticación de endpoints de depuración reforzada.** Los endpoints de depuración XDS (`syncz`, `config_dump`) en el puerto 15010 ahora requieren autenticación cuando `ENABLE_DEBUG_ENDPOINT_AUTH=true` (predeterminado). Una nueva configuración `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` permite a los operadores autorizar namespaces específicos más allá del namespace del sistema. Consulta las [notas de actualización](upgrade-notes/) para los detalles del cambio disruptivo.
- **Flag de versión TLS mínima** para `pilot-discovery` (`--tls-min-version`), permitiendo a los operadores establecer el mínimo para TLS del plano de control.
- **Registro predeterminado** para imágenes de Istio ahora es `registry.istio.io`. El registro anterior sigue siendo accesible, pero las nuevas instalaciones tienen como predeterminado la nueva ubicación.

### Instalación y Operabilidad

- **Anulaciones de puertos configurables** para el servicio de gateway de red mediante los valores de Helm `networkGatewayPorts`, más validación de plantillas para fallar temprano cuando `service.ports` está vacío y `networkGateway` no está configurado.
- **Condición de estado `WaypointBound`** en recursos `WorkloadEntry`, reportando si cada workload está actualmente vinculado a un waypoint.
- **Campos `dnsPolicy` y `dnsConfig`** en el chart de Helm de ztunnel para entornos con DNS no estándar.
- **`useAppArmorAnnotation`** en el chart de Helm de istio-cni, predeterminado `true`.
- **`global.enableReaderRBAC`** (predeterminado `true`) controla la instalación del RBAC de lector.

### Telemetría

- El enriquecimiento de atributos de servicio ahora sigue las convenciones semánticas de OpenTelemetry, incluido el soporte para `app.kubernetes.io/name` y `service.istio.io/canonical-name`.
- Nuevo campo `disableContextPropagation` en la API de Tracing de Telemetría, útil para entornos donde Istio no debe propagar el contexto de trazado.
- El dashboard Grafana de Ztunnel añade un panel de Uso de Recursos para conexiones TCP activas, descriptores de archivo abiertos y sockets abiertos por instancia.

### Y mucho más

- Mejoras de **istioctl** incluyendo `--tls-min-version` integrado, correcciones de ordenamiento para la salida de conexiones, imagen distroless de istioctl y refinamientos del comando `ztunnel-config`
- Mejoras de **CNI**: corrección de sondeo de kubelet para pods ambient en AWS EKS usando Security Groups for Pods (branch ENI), controlado por `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` (activado por defecto); validación de entrada para `excludeInterfaces`; ajustes de reconciliación
- **Wasm**: límite de tamaño de binario configurable, límite de descompresión gzip configurable, protección SSRF en obtención de Wasm
- **Multiclúster**: soporte para cargar recursos `Secret` remotos desde una ruta del sistema de archivos local

Lee sobre estos y más en las [notas de versión](change-notes/) completas.

## Actualización a 1.30

Nos gustaría saber tu experiencia al actualizar a Istio 1.30. Puedes proporcionar comentarios en el canal `#release-1_30` de nuestro [espacio de trabajo de Slack](https://slack.istio.io/).

¿Te gustaría contribuir directamente a Istio? Encuentra y únete a uno de nuestros [Grupos de Trabajo](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) y ayúdanos a mejorar.
