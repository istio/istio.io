---
title: Notas de Cambios de Istio 1.25.0
linktitle: 1.25.0
subtitle: Versión Principal
description: Notas de versión de Istio 1.25.0.
publishdate: 2025-03-03
release: 1.25.0
weight: 10
aliases:
    - /news/announcing-1.25.0
---

## Avisos de Obsolescencia

Estos avisos describen funcionalidades que se eliminarán en una versión futura según la [política de obsolescencia de Istio](/docs/releases/feature-stages/#feature-phase-definition). Considera actualizar tu entorno para eliminar las funcionalidades obsoletas.

- **Obsoleto** el uso de `ISTIO_META_DNS_AUTO_ALLOCATE` en `proxyMetadata` en favor de una versión más reciente de [auto-asignación de DNS](/docs/ops/configuration/traffic-management/dns-proxy#address-auto-allocation). Los nuevos usuarios de la auto-asignación de IPs de Istio deben adoptar el nuevo controlador basado en estado. Los usuarios existentes pueden continuar usando la implementación anterior.
  ([Issue #53596](https://github.com/istio/istio/issues/53596))

- **Obsoleta** la anotación `traffic.sidecar.istio.io/kubevirtInterfaces`, en favor de `istio.io/reroute-virtual-interfaces`.
  ([Issue #49829](https://github.com/istio/istio/issues/49829))

## Gestión de Tráfico

- **Promovido** el valor `cni.ambient.dnsCapture` para que sea `true` por defecto.
  Esto habilita el DNS proxying para los workloads en modo ambient mesh de forma predeterminada, mejorando la seguridad, el rendimiento y habilitando varias características. Se puede deshabilitar explícitamente o con `compatibilityVersion=1.24`.
  Nota: solo los pods nuevos tendrán DNS habilitado. Para habilitarlo en pods existentes, deben reiniciarse manualmente o habilitar la reconciliación de iptables con `--set cni.ambient.reconcileIptablesOnStartup=true`.

- **Promovido** el valor `PILOT_ENABLE_IP_AUTOALLOCATE` para que sea `true` por defecto.
  Esto habilita la nueva iteración de la [auto-asignación de IPs](/docs/ops/configuration/traffic-management/dns-proxy/#address-auto-allocation),
  resolviendo problemas de larga data relacionados con la inestabilidad de la asignación, el soporte en modo ambient y mayor visibilidad.
  Los objetos `ServiceEntry` sin `spec.address` definido verán ahora el nuevo campo `status.addresses` configurado automáticamente.
  Nota: estos no se usarán a menos que los proxies estén configurados para hacer DNS proxying, que sigue desactivado por defecto.

- **Actualizado** la característica `PILOT_SEND_UNHEALTHY_ENDPOINTS` (desactivada por defecto) para excluir endpoints en proceso de terminación.
  Esto asegura que un servicio no se considere no saludable durante eventos de reducción de escala o despliegues.

- **Actualizado** el algoritmo de DNS proxying para seleccionar aleatoriamente a qué upstream reenviar las solicitudes DNS.
  ([Issue #53414](https://github.com/istio/istio/issues/53414))

- **Añadida** la variable de entorno de istiod `PILOT_DNS_JITTER_DURATION` que establece el jitter para la resolución DNS periódica.
  Ver `dns_jitter` en `https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto`.
  ([Issue #52877](https://github.com/istio/istio/issues/52877))

- **Añadido** `ObservedGeneration` a las condiciones de estado en modo ambient. Este campo mostrará la generación del objeto que el controlador observó cuando se generó la condición.
  ([Issue #53331](https://github.com/istio/istio/issues/53331))

- **Añadida** la variable de entorno de istiod `PILOT_DNS_CARES_UDP_MAX_QUERIES` que controla el campo `udp_max_queries` del resolvedor DNS Cares predeterminado de Envoy. Este valor toma 100 por defecto cuando no está configurado.
  Para más información, consulta la [documentación de Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/network/dns_resolver/cares/v3/cares_dns_resolver.proto#envoy-v3-api-field-extensions-network-dns-resolver-cares-v3-caresdnsresolverconfig-udp-max-queries).
  ([Issue #53577](https://github.com/istio/istio/issues/53577))

- **Añadido** soporte para reconciliar las reglas de iptables dentro de pods ambient existentes de la versión anterior al actualizar `istio-cni`. La característica se puede activar con `--set cni.ambient.reconcileIptablesOnStartup=true` y se habilitará por defecto en versiones futuras.
  ([Issue #1360](https://github.com/istio/istio/issues/1360))

- **Añadida** la anotación `istio.io/reroute-virtual-interfaces`, una lista separada por comas de interfaces virtuales cuyo tráfico entrante se tratará incondicionalmente como saliente. Esto permite que los workloads que usan redes virtuales (KubeVirt, VMs, docker-in-docker, etc.) funcionen correctamente con la captura de tráfico en modo sidecar y ambient mesh.

- **Añadido** soporte para adjuntar políticas predeterminadas a istio-waypoint apuntando al `GatewayClass`.
  ([Issue #54696](https://github.com/istio/istio/issues/54696))

- **Añadida** la anotación `ambient.istio.io/dns-capture`, que puede estar sin definir o configurarse como `true` o `false`.
  Cuando se especifica en un `Pod` inscrito en ambient mesh, controla si el tráfico DNS (TCP y UDP en el puerto 53) será capturado y enviado por proxy en modo ambient.
  Esta anotación a nivel de pod, si está presente, sobreescribe el ajuste global `AMBIENT_DNS_CAPTURE` de `istio-cni`, que a partir de la versión 1.25 toma el valor `true` por defecto.
  Nota: establecerla como `false` desactivará algunas características de Istio, como `ServiceEntries` y waypoints de salida, aunque puede ser deseable para workloads que no se llevan bien con los DNS proxies.
  ([Issue #49829](https://github.com/istio/istio/issues/49829))

- **Añadido** soporte para configurar la etiqueta `istio.io/ingress-use-waypoint` a nivel de namespace.

- **Añadido** soporte para preservar las mayúsculas y minúsculas originales de las cabeceras HTTP/1.x. ([Issue #53680](https://github.com/istio/istio/issues/53680))

- **Añadido** soporte para el campo `Service.spec.trafficDistribution` y la anotación `networking.istio.io/traffic-distribution`, que ofrecen un mecanismo más sencillo para que el tráfico prefiera endpoints geográficamente cercanos.
  Nota: esta característica existía anteriormente solo para ztunnel, pero ahora está soportada en todos los data planes.

- **Corregido** un error con Hosts en mayúsculas y minúsculas mixtas en Gateway y redirección TLS que provocaba un RDS obsoleto. ([Issue #49638](https://github.com/istio/istio/issues/49638))

- **Corregido** un problema donde un `HTTPRoute` en un `VirtualService` con un matcher que especificaba `sourceLabels` se aplicaba a un waypoint.
  ([Issue #51565](https://github.com/istio/istio/issues/51565))

- **Corregido** un problema donde si la obtención de una imagen WASM fallaba, se usaba un filtro RBAC de permiso total. Ahora, si `failStrategy` está configurado como `FAIL_CLOSE`, se usará un filtro RBAC de denegación total. ([Issue #53279](https://github.com/istio/istio/issues/53279)), ([Issue #23624](https://github.com/istio/istio/issues/23624))

- **Corregido** el waypoint proxy para respetar el dominio de confianza.

- **Corregido** un problema donde la fusión de `Duration` en un `EnvoyFilter` podía modificar inesperadamente los atributos de todos los listeners asociados porque todos compartían el mismo puntero (`listener_filters_timeout`).

- **Corregido** un problema donde se producían errores durante la limpieza de reglas de iptables que eran condicionales.

- **Corregida** una configuración para que el tráfico DNS (UDP y TCP) sea ahora afectado por anotaciones de tráfico como `traffic.sidecar.istio.io/excludeOutboundIPRanges` y `traffic.sidecar.istio.io/excludeOutboundPorts`. Anteriormente, el tráfico UDP/DNS ignoraba estas anotaciones de forma única, incluso si se especificaba un puerto DNS, debido a la estructura de las reglas. El cambio de comportamiento ocurrió realmente en la serie 1.23, pero se omitió en las notas de la versión 1.23.
  ([Issue #53949](https://github.com/istio/istio/issues/53949))

- **Corregido** un problema donde istiod no gestionaba correctamente `RequestAuthentication` para waypoint proxies en namespaces cruzados. ([Issue #54051](https://github.com/istio/istio/issues/54051))

- **Corregido** un problema que causaba fallos al aplicar parches a un deployment de gateway/waypoint gestionado durante la actualización a la versión 1.24.
  ([Issue #54145](https://github.com/istio/istio/issues/54145))

- **Corregido** un problema donde las revisiones no predeterminadas que controlan gateways carecían de etiquetas `istio.io/rev`.
  ([Issue #54280](https://github.com/istio/istio/issues/54280))

- **Corregido** el texto del mensaje de estado cuando hay reglas L7 presentes en una `AuthorizationPolicy` vinculada a ztunnel para que sea más claro.
  ([Issue #54334](https://github.com/istio/istio/issues/54334))

- **Corregido** un error donde el filtro de espejo de solicitudes calculaba incorrectamente el porcentaje.
  ([Issue #54357](https://github.com/istio/istio/issues/54357))

- **Corregido** un problema donde usar una etiqueta en la label `istio.io/rev` de un gateway provocaba que el gateway se programara incorrectamente y careciera de estado.
  ([Issue #54458](https://github.com/istio/istio/issues/54458))

- **Corregido** un problema donde desconexiones de ztunnel fuera de orden podían dejar `istio-cni` en un estado en el que cree que no tiene conexiones.
  ([Issue #54544](https://github.com/istio/istio/issues/54544)), ([Issue #53843](https://github.com/istio/istio/issues/53843))

- **Corregidas** las entradas excesivas de log a nivel info de iptables para comprobaciones y eliminaciones de reglas.
  Se pueden volver a habilitar los logs detallados cambiando al nivel debug si es necesario.
  ([Issue #54644](https://github.com/istio/istio/issues/54644))

- **Corregido** un problema que causaba que los servicios `ExternalName` fallaran al resolver cuando se usaba el modo ambient y el DNS proxying.

- **Corregido** un problema que causaba que la configuración fuera rechazada cuando había una superposición parcial entre las direcciones IP de múltiples servicios.
  Por ejemplo, un Service con `[IP-A]` y otro con `[IP-B, IP-A]`.
  ([Issue #52847](https://github.com/istio/istio/issues/52847))

- **Corregido** un problema donde la validación de nombres de cabeceras de `VirtualService` rechazaba nombres de cabeceras válidos.

- **Corregido** un problema al actualizar waypoint proxies de Istio 1.23.x a Istio 1.24.x.
  ([Issue #53883](https://github.com/istio/istio/issues/53883))

## Seguridad

- **Añadida** la capacidad `DAC_OVERRIDE` al DaemonSet `istio-cni-node`. Esto resuelve problemas al ejecutarse en entornos donde ciertos archivos son propiedad de usuarios no root.
  Nota: antes de Istio 1.24, `istio-cni-node` se ejecutaba como `privileged`. Istio 1.24 eliminó esto, pero quitó algunos privilegios necesarios que ahora se vuelven a añadir. En relación a Istio 1.23, `istio-cni-node` sigue teniendo menos privilegios que con este cambio.

- **Añadida** la anotación AppArmor unconfined al DaemonSet `istio-cni-node` para evitar conflictos con perfiles AppArmor que bloquean ciertas capacidades de pods privilegiados. Anteriormente, AppArmor (cuando estaba habilitado) se ignoraba para el DaemonSet `istio-cni-node` porque `privileged` estaba configurado como `true` en el `SecurityContext`. Este cambio garantiza que el perfil AppArmor se establezca como unconfined para el DaemonSet `istio-cni-node`.

- **Corregido** un problema donde las políticas `PeerAuthentication` en modo ambient eran demasiado estrictas.
  ([Issue #53884](https://github.com/istio/istio/issues/53884))

- **Corregidas** posibles condiciones de carrera en la caché de resolución JWK para políticas JWT que, al activarse, causaban fallos de caché y errores al actualizar las claves de firma cuando se rotaban.
  ([Issue #52121](https://github.com/istio/istio/issues/52121))

- **Corregido** un error en modo ambient (únicamente) donde múltiples reglas mTLS `STRICT` a nivel de puerto en una política `PeerAuthentication` resultaban efectivamente en una política permisiva debido a una lógica de evaluación incorrecta (`AND` en lugar de `OR`).
  ([Issue #54146](https://github.com/istio/istio/issues/54146))

- **Corregido** un problema donde los ingress gateways no usaban el descubrimiento WDS para recuperar metadatos de destinos en modo ambient.

## Telemetría

- **Añadido** soporte para el intercambio adicional de etiquetas para telemetría en modo sidecar.
  ([Issue #54000](https://github.com/istio/istio/issues/54000))

- **Añadida** una nueva etiqueta `service.istio.io/workload-name` que se puede añadir a un `Pod` o `WorkloadEntry` para sobreescribir el "nombre del workload" reportado en la telemetría.

- **Añadido** un fallback para usar el nombre del `WorkloadGroup` como "nombre del workload" (reportado en telemetría) para los `WorkloadEntry`s creados por un `WorkloadGroup`.

- **Corregida** la interpolación de `$(HOST_IP)` que causaba fallos en istio-proxy cuando el tracing de Datadog estaba habilitado en clústeres IPv6.
  ([Issue #54267](https://github.com/istio/istio/issues/54267))

- **Corregido** un problema donde la inestabilidad en el orden de los logs de acceso causaba drenado de conexiones.
  ([Issue #54672](https://github.com/istio/istio/issues/54672))

- **Corregido** un problema donde muchos paneles de los dashboards de Grafana mostraban **Sin datos** si Prometheus tenía un intervalo de scraping configurado superior a `15s`.
  ([Información adicional](https://grafana.com/blog/2020/09/28/new-in-grafana-7.2-__rate_interval-for-prometheus-rate-queries-that-just-work/) y [uso](/docs/tasks/observability/metrics/using-istio-dashboard/))

- **Eliminado** el soporte de OpenCensus.

## Instalación

- **Mejorado** los valores `platform` y `profile` de Helm ahora admiten equivalentemente formas de sobreescritura global o local, por ejemplo:
    - `--set global.platform=foo`
    - `--set global.profile=bar`
    - `--set platform=foo`
    - `--set profile=bar`

- **Mejorado** el chart Helm de ztunnel para establecer los nombres de recursos en `.Release.Name` en lugar de estar fijados a ztunnel.

- **Añadidos** nuevos mensajes a la condición `WaypointBound` para representar un servicio vinculado a un waypoint proxy para ingress.

- **Añadido** un problema donde `istioctl install` no funcionaba en Windows.

- **Añadida** una `dnsPolicy` de pod con valor `ClusterFirstWithHostNet` a `istio-cni` cuando se ejecuta con `hostNetwork=true` (es decir, en modo ambient).

- **Añadido** el perfil de plataforma GKE para modo ambient. Al instalar en GKE, usa `--set global.platform=gke` (Helm) o `--set values.global.platform=gke` (istioctl) para aplicar sobreescrituras de valores específicas de GKE. Esto reemplaza la detección automática de GKE anterior basada en la versión de Kubernetes usada en el chart `istio-cni`.

- **Añadido** soporte para el parámetro de configuración de Envoy que omite los logs obsoletos, con el valor predeterminado configurado como `true`. Establecer la variable de entorno `ENVOY_SKIP_DEPRECATED_LOGS` a `false` habilitará los logs obsoletos.

- **Añadidas** etiquetas de exclusión del data plane ambient a los gateways incluidos con Istio por defecto, para evitar comportamientos confusos al instalar gateways fuera de `istio-system`.
  ([Issue #54824](https://github.com/istio/istio/issues/54824))

- **Corregido** un problema donde la creación de entradas `ipset` fallaba en ciertos tipos de nodos de Kubernetes basados en Docker.
  ([Issue #53512](https://github.com/istio/istio/issues/53512))

- **Corregido** el render de Helm para aplicar correctamente las anotaciones en el `serviceAccount` del pilot.
  ([Issue #51289](https://github.com/istio/istio/issues/51289))

- **Corregido** un problema donde `includeInboundPorts: ""` no funcionaba cuando `istio-cni` estaba habilitado.
  ([Issue #54288](https://github.com/istio/istio/issues/54288))

- **Corregido** un problema donde la instalación de CNI dejaba archivos temporales cuando un contenedor era eliminado repetidamente durante la copia del binario, lo que podía llenar el espacio de almacenamiento.
  ([Issue #54311](https://github.com/istio/istio/issues/54311))

- **Corregido** un problema en el chart del gateway donde `--set platform` funcionaba pero `--set global.platform` no.

- **Corregido** un problema donde la plantilla de inyección de `gateway` no respetaba las anotaciones `kubectl.kubernetes.io/default-logs-container` y `kubectl.kubernetes.io/default-container`.

- **Corregido** un problema que causaba que el comando `istio-iptables` fallara cuando una tabla no integrada estaba presente en el sistema.

- **Corregido** un problema que impedía personalizar el campo `maxUnavailable` del `PodDisruptionBudget`.
  ([Issue #54087](https://github.com/istio/istio/issues/54087))

- **Corregido** un problema donde los errores de configuración de inyección se silenciaban (es decir, se registraban pero no se devolvían) cuando el inyector de sidecar no podía procesar la configuración del sidecar. Este cambio propagará ahora el error al usuario en lugar de continuar procesando una configuración defectuosa.
  ([Issue #53357](https://github.com/istio/istio/issues/53357))

## istioctl

- **Mejorada** la salida de `istioctl proxy-config secret` para mostrar los trust bundles proporcionados por Spire.

- **Añadido** el alias `-r` para las flags `--revision` en `istioctl analyze`.

- **Añadido** soporte para `AuthorizationPolicies` con acción `CUSTOM` en el comando `istioctl x authz check`.

- **Añadido** soporte para el parámetro `--network` en el comando `istioctl experimental workload group create`.
  ([Issue #54022](https://github.com/istio/istio/issues/54022))

- **Añadida** la posibilidad de reiniciar o actualizar de forma segura el DaemonSet `istio-cni` de tipo `system-node-critical` in situ. Esto funciona evitando que nuevos pods se inicien en el nodo mientras `istio-cni` se reinicia o actualiza. Esta característica está habilitada por defecto y puede deshabilitarse configurando la variable de entorno `AMBIENT_DISABLE_SAFE_UPGRADE=true` en `istio-cni`.
  ([Issue #49009](https://github.com/istio/istio/issues/49009))

- **Añadidos** cambios en el comando `rootca-compare` para manejar el caso en que un pod tiene múltiples CA raíz. ([Issue #54545](https://github.com/istio/istio/issues/54545))

- **Añadido** soporte para que `istioctl waypoint delete` elimine waypoints de revisiones específicas.

- **Añadido** soporte para que el analizador reporte condiciones de estado negativas en recursos seleccionados de Istio y de Gateway API de Kubernetes.
  ([Issue #55055](https://github.com/istio/istio/issues/55055))

- **Mejorado** el rendimiento de `istioctl proxy-config secret` y `istioctl proxy-config`.
  ([Issue #53931](https://github.com/istio/istio/issues/53931))

- **Corregido** un problema en el comando `rootca-compare` para manejar el caso en que un pod tiene múltiples CA raíz. ([Issue #54545](https://github.com/istio/istio/issues/54545))

- **Corregido** un problema donde `istioctl install` se bloquea si se especifican múltiples ingress gateways en el archivo `IstioOperator`.
  ([Issue #53875](https://github.com/istio/istio/issues/53875))

- **Corregido** un problema donde `istioctl waypoint delete --all` eliminaba todos los recursos de gateway, incluso los que no eran waypoints.
  ([Issue #54056](https://github.com/istio/istio/issues/54056))

- **Corregido** el comando `istioctl experimental injector list` para que no imprima namespaces redundantes para los webhooks del inyector.

- **Corregido** `istioctl analyze` que reportaba errores `IST0145` al usar el mismo host con diferentes puertos y múltiples gateways.
  ([Issue #54643](https://github.com/istio/istio/issues/54643))

- **Corregido** un problema donde `istioctl --as` establecía implícitamente `--as-group=""` cuando se usaba `--as` sin `--as-group`.

- **Eliminadas** las flags `--recursive` y configurada la recursión como `true` por defecto en `istioctl analyze`.

- **Eliminada** la flag experimental `--xds-via-agents` del comando `istioctl proxy-status`.
