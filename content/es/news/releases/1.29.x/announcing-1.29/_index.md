---
title: Anuncio de Istio 1.29.0
linktitle: 1.29.0
subtitle: Versión Principal
description: Anuncio de la versión Istio 1.29.
publishdate: 2026-02-16
release: 1.29.0
aliases:
    - /news/announcing-1.29
    - /news/announcing-1.29.0
---

Nos complace anunciar el lanzamiento de Istio 1.29. ¡Gracias a todos nuestros contribuidores, testers, usuarios y entusiastas por ayudarnos a publicar la versión 1.29.0!
Queremos agradecer a los Release Managers de esta versión: **Francisco Herrera** de Red Hat, **Darrin Cecil** de Microsoft y **Petr McAllister** de Solo.io.

{{< relnote >}}

{{< tip >}}
Istio 1.29.0 tiene soporte oficial para Kubernetes versiones 1.31 a 1.35.
{{< /tip >}}

## ¿Qué hay de nuevo?

### Mejoras de Ambient Mesh listas para producción

Istio 1.29 añade dos mejoras operativas habilitadas por defecto para el modo ambient: la captura de DNS está ahora habilitada por defecto para los workloads en ambient, mejorando la seguridad y el rendimiento y habilitando funcionalidades avanzadas como mejor descubrimiento de servicios y gestión del tráfico. Esta mejora garantiza que el tráfico DNS de los workloads en modo ambient sea enrutado correctamente a través de la infraestructura de la mesh.

Adicionalmente, la reconciliación de iptables está ahora habilitada por defecto, proporcionando actualizaciones automáticas de reglas de red cuando el `DaemonSet` de istio-cni se actualiza. Esto elimina la intervención manual que antes era necesaria para garantizar que los pods ambient existentes recibieran la configuración de red actualizada, haciendo que las operaciones de ambient mesh sean más fluidas y confiables en entornos de producción.

### Postura de seguridad mejorada

Esta versión añade mejoras de seguridad en múltiples componentes. El soporte para Certificate Revocation List (CRL) está ahora disponible en ztunnel, permitiendo la validación y el rechazo de certificados revocados cuando se usan autoridades de certificación externas. Esto fortalece la postura de seguridad de los despliegues de service mesh que utilizan CAs externas.

La autorización de endpoints de depuración está habilitada por defecto, proporcionando controles de acceso basados en namespace para los endpoints de depuración en el puerto 15014. Los namespaces que no son del sistema ahora están restringidos a endpoints específicos (`config_dump`, `ndsz`, `edsz`) y únicamente a proxies del mismo namespace, mejorando la seguridad sin afectar las operaciones normales. _Agradecemos especialmente a Sergey KANIBOR de Luntry por reportar el problema de autorización en endpoints de depuración._

El despliegue opcional de NetworkPolicy ya está disponible para los componentes istiod, istio-cni y ztunnel, permitiendo a los usuarios desplegar `NetworkPolicies` por defecto con `global.networkPolicy.enabled=true` para una mayor seguridad de red.

### Gestión del tráfico TLS para hosts con comodín

Istio 1.29 introduce soporte alpha para hosts con comodín en recursos `ServiceEntry` con resolución `DYNAMIC_DNS`, específicamente para tráfico TLS. Esto permite el enrutamiento basado en SNI (Server Name Indication) de los handshakes TLS sin necesidad de terminar la conexión TLS para inspeccionar las cabeceras Host.

Si bien esta funcionalidad tiene implicaciones de seguridad importantes debido al potencial de SNI spoofing, ofrece capacidades poderosas para gestionar servicios TLS externos cuando se usa con clientes de confianza. La funcionalidad requiere habilitación explícita mediante el feature flag `ENABLE_WILDCARD_HOST_SERVICE_ENTRIES_FOR_TLS`.

### Mejoras de rendimiento y observabilidad

La compresión HTTP para las métricas de Envoy está ahora habilitada por defecto, proporcionando compresión automática (`brotli`, `gzip` y `zstd`) para el endpoint de estadísticas de Prometheus según los valores de `Accept-Header` del cliente. Esto reduce la sobrecarga de red en la recopilación de métricas y mantiene la compatibilidad con la infraestructura de monitoreo existente.

Se ha añadido soporte de telemetría basado en baggage en alpha para la mesh ambient, beneficiando especialmente los despliegues en múltiples redes. Cuando se habilita mediante la variable de entorno `AMBIENT_ENABLE_BAGGAGE` de pilot, esta funcionalidad garantiza la correcta atribución de origen y destino para las métricas de tráfico entre redes, mejorando la observabilidad en topologías de red complejas.

### Operaciones simplificadas y gestión de recursos

Istio 1.29 introduce capacidades de filtrado de recursos para pilot mediante la variable de entorno `PILOT_IGNORE_RESOURCES`, permitiendo a los administradores desplegar Istio como un controlador solo de Gateway API o con subconjuntos específicos de recursos. Esto es especialmente valioso para despliegues GAMMA (Gateway API for Mesh Management and Administration).

La gestión de memoria ha mejorado con `istiod` configurando automáticamente `GOMEMLIMIT` al 90% de los límites de memoria (mediante la librería `automemlimit`), reduciendo el riesgo de OOM kills mientras se mantiene un rendimiento óptimo. El seguimiento de métricas del circuit breaker está ahora deshabilitado por defecto, mejorando el uso de memoria del proxy y manteniendo la opción de habilitar el comportamiento heredado cuando sea necesario.

### Soporte para Inference Extension promovido a Beta

El soporte para la [Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/) ha sido promovido a beta en Istio 1.29. La Inference Extension es un proyecto oficial de Kubernetes que utiliza un nuevo objeto CRD `InferencePool`, junto con objetos existentes de gestión de tráfico de Kubernetes Gateway API (`Gateway`, `HTTPRoute`), para optimizar el servicio de modelos de IA generativa auto-hospedados en Kubernetes.

Istio 1.29 es conforme con la versión `v1.0.1` de la Inference Extension, y está disponible para probar habilitando la variable de entorno de pilot `ENABLE_GATEWAY_API_INFERENCE_EXTENSION`. Las versiones futuras de Gateway API Inference Extension serán soportadas en próximas versiones de Istio.

Consulta [nuestra guía](/docs/tasks/traffic-management/ingress/gateway-api-inference-extension/) y el [artículo de blog original](/blog/2025/inference-extension-support/) para comenzar.

### Multi-network multicluster en ambient pasa a Beta

Esta versión también promueve el soporte multi-network multicluster en ambient al estado beta. Se realizaron muchas mejoras en robustez y completitud. El área principal de enfoque para esta transición fue la telemetría, donde se abordaron brechas importantes, incluida la implementación de un intercambio de metadatos de pares más avanzado en el data plane de ambient.

Esto significa que se abordaron algunos casos confusos en la telemetría de múltiples redes. En escenarios donde los waypoints no se reportaban correctamente en las métricas L4, hasta casos donde la información de los pares no estaba completamente disponible para solicitudes que atravesaban diferentes redes a través de un gateway E/W.

Además, ahora contamos con [una guía rápida](/docs/ambient/install/multicluster/observability) que muestra cómo desplegar Prometheus y Kiali para multi-network multicluster en modo ambient.

Ten en cuenta que algunas de estas mejoras también pueden estar detrás del feature flag `AMBIENT_ENABLE_BAGGAGE` mencionado en las secciones anteriores, así que asegúrate de habilitarlo si quieres probarlas. Si necesitas más información sobre cómo desplegar multi-network multicluster utilizando el data plane de ambient, sigue [esta guía](/docs/ambient/install/multicluster/multi-primary_multi-network/). Encontrarás más detalles sobre la funcionalidad en las [notas de versión](change-notes/).

¡No olvides compartir tus comentarios con nosotros!

### Y mucho más

- **Capacidades mejoradas de istioctl**: nuevo flag `--wait` para `istioctl waypoint status`, soporte para el flag `--all-namespaces` y especificación mejorada del puerto de administración del proxy
- **Mejoras de instalación**: `terminationGracePeriodSeconds` configurable para pods de istio-cni, protecciones para el controlador de despliegue del gateway y soporte para intervalos de vaciado de ficheros Envoy personalizados
- **Mejoras de gestión del tráfico**: soporte para balanceo de carga `LEAST_REQUEST` y circuit breaking en clientes gRPC sin proxy, enrutamiento mejorado de ingress en multicluster ambient
- **Avances en telemetría**: identificación de workload de origen y destino en trazas del waypoint proxy, soporte de timeout y cabeceras para el proveedor de trazado Zipkin

Lee sobre estas y más mejoras en las [notas de versión](change-notes/) completas.

## Actualización a 1.29

Nos gustaría conocer tu experiencia al actualizar a Istio 1.29. Puedes enviarnos tus comentarios en el canal `#release-1.29` de nuestro [espacio de trabajo de Slack](https://slack.istio.io/).

¿Te gustaría contribuir directamente a Istio? Encuentra y únete a uno de nuestros [Grupos de Trabajo](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) y ayúdanos a mejorar.
