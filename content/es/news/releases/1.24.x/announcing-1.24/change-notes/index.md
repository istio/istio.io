---
title: Notas de Cambios de Istio 1.24.0
linktitle: 1.24.0
subtitle: Versión Principal
description: Notas de versión de Istio 1.24.0.
publishdate: 2024-11-07
release: 1.24.0
weight: 10
aliases:
    - /news/announcing-1.24.0
---

## Modo Ambient

- **Añadido** soporte para adjuntar políticas a `ServiceEntry` para waypoints.

- **Añadida** una nueva anotación, `ambient.istio.io/bypass-inbound-capture`, que se puede aplicar para que ztunnel solo capture tráfico de salida.
  Resulta útil para omitir un salto innecesario en workloads que solo aceptan tráfico de clientes fuera del mesh (como pods accesibles desde internet).

- **Añadida** una nueva anotación, `networking.istio.io/traffic-distribution`, que se puede aplicar para que ztunnel prefiera enviar tráfico a pods locales.
  Se comporta igual que el campo [`spec.trafficDistribution`](https://kubernetes.io/docs/concepts/services-networking/service/#traffic-distribution) en `Service`, pero permite su uso en versiones más antiguas de Kubernetes (ya que el campo se añadió como beta en Kubernetes 1.31).
  Nota: los waypoints establecen esto automáticamente.

- **Corregido** un problema que impedía que los [protocolos server-first](/docs/ops/deployment/application-requirements/#server-first-protocols) funcionaran con waypoints.

- **Mejorados** los logs de Envoy cuando se producen fallos de conexión en modo ambient para mostrar más detalles del error.

- **Añadido** soporte para la personalización de `Telemetry` en el proxy waypoint.

- **Añadida** la escritura de una condición de estado al vincular AuthorizationPolicy a un proxy waypoint.
  El formato de las condiciones es **experimental** y cambiará.
  Las políticas con múltiples `targetRefs` reciben actualmente una sola condición.
  Una vez que Kubernetes Gateway API adopte un patrón para condiciones con múltiples referencias, Istio adoptará esa convención para ofrecer mayor detalle cuando se usen múltiples `targetRefs`.
  ([Issue #52699](https://github.com/istio/istio/issues/52699))

- **Corregido** un problema que causaba que los pods con `hostNetwork` funcionaran incorrectamente en modo ambient.

- **Mejorada** la forma en que ztunnel determina qué Pod representa. Anteriormente esto dependía de direcciones IP, lo que era poco fiable en algunos escenarios.

- **Corregido** un problema que causaba que cualquier `portLevelSettings` fuera ignorado en `DestinationRule` en waypoints.  ([Issue #52532](https://github.com/istio/istio/issues/52532))

- **Corregido** un problema al usar políticas de mirroring con waypoints.
  ([Issue #52713](https://github.com/istio/istio/issues/52713))

- **Añadido** soporte para la regla `connection.sni` en `AuthorizationPolicy` aplicada a un waypoint.
  ([Issue #52752](https://github.com/istio/istio/issues/52752))

- **Actualizado** el método de redirección usado en Ambient de `TPROXY` a `REDIRECT`.
  Para la mayoría de los usuarios esto no tiene impacto, pero corrige algunos problemas de compatibilidad con `TPROXY`.  ([Issue #52260](https://github.com/istio/istio/issues/52260)), ([Issue #52576](https://github.com/istio/istio/issues/52576))

## Gestión de Tráfico

- **Promovido** el soporte dual-stack de Istio a Alpha.
  ([Issue #47998](https://github.com/istio/istio/issues/47998))

- **Añadidos** los parámetros `warmup.aggression`, `warmup.duration`, `warmup.minimumPercent` a `DestinationRule` para mayor control sobre el comportamiento de warmup.
  ([Issue #3215](https://github.com/istio/api/issues/3215))

- **Añadida** una política de reintentos para solicitudes entrantes que restablece automáticamente las solicitudes que el servicio no ha visto o procesado.
  Se puede revertir estableciendo `ENABLE_INBOUND_RETRY_POLICY` en false.
  ([Issue #51704](https://github.com/istio/istio/issues/51704))

- **Corregida** la política de reintentos predeterminada para excluir reintentos en 503, que es potencialmente inseguro para solicitudes idempotentes.
  Este comportamiento se puede revertir temporalmente con `EXCLUDE_UNSAFE_503_FROM_DEFAULT_RETRY=false`.
  ([Issue #50506](https://github.com/istio/istio/issues/50506))

- **Actualizado** el comportamiento de la generación de XDS para que sea coherente tanto cuando el usuario tiene un `Sidecar` configurado como cuando no. Consulta las notas de actualización para más información.

- **Mejorado** el webhook de validación de Istiod para aceptar versiones que no conoce.
  Esto garantiza que una versión más antigua de Istio pueda validar recursos creados por CRDs más nuevos.

- **Mejorado** el soporte para servicios dual-stack asociando múltiples IPs con un único endpoint, en lugar de tratarlos como dos endpoints distintos.
  ([Issue #40394](https://github.com/istio/istio/issues/40394))

- **Añadido** soporte para hacer coincidir múltiples IPs (para servicios dual-stack) en rutas HTTP.

- **Añadido** el campo `sourceNamespaces` de `VirtualService` se tendrá en cuenta al filtrar configuración innecesaria.

- **Añadido** soporte para omitir el overload manager en listeners estáticos. Se puede revertir estableciendo
  `BYPASS_OVERLOAD_MANAGER_FOR_STATIC_LISTENERS` en false en el Deployment del agente.  ([Issue #41859](https://github.com/istio/istio/issues/41859)), ([Issue #52663](https://github.com/istio/istio/issues/52663))

- **Añadida** la variable de entorno de istiod `ENVOY_DNS_JITTER_DURATION`, con un valor predeterminado de `100ms`, que establece el jitter para la resolución DNS periódica.
  Consulta `dns_jitter` en `https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto`.
  Esto puede ayudar a reducir la carga en el servidor DNS del clúster.
  ([Issue #52877](https://github.com/istio/istio/issues/52877))

- **Añadido** soporte para configurar detalles del certificado al rellenar el encabezado XFCC mediante el nuevo campo `proxyHeaders.setCurrentClientCertDetails` de `ProxyConfig`.

- **Añadido** permiso para incluir espacios en blanco adicionales entre namespaces en la anotación `networking.istio.io/exportTo`.
  ([Issue #53429](https://github.com/istio/istio/issues/53429))

- **Añadida** una característica experimental para habilitar la creación diferida de un subconjunto de estadísticas de Envoy.
  Esto ahorra memoria y ciclos de CPU al crear los objetos que poseen estas estadísticas, si nunca se referencian durante la vida del proceso.
  Se puede deshabilitar estableciendo `ENABLE_DEFERRED_STATS_CREATION` en false en el Deployment del agente.

- **Corregida** la coincidencia de múltiples VIPs de servicio en ServiceEntry. Consulta las notas de actualización para más información.
  ([Issue #51747](https://github.com/istio/istio/issues/51747)), ([Issue #30282](https://github.com/istio/istio/issues/30282))

- **Corregido** `MeshConfig`'s `serviceSettings.settings.clusterLocal` para favorecer hostnames más precisos, permitiendo exclusiones de host.

- **Corregido** que los `DestinationRules` sobre el mismo host no se fusionen si tienen diferentes valores de `exportTo`.
  El comportamiento anterior se puede restaurar temporalmente con `ENABLE_ENHANCED_DESTINATIONRULE_MERGE=false`.
  ([Issue #52519](https://github.com/istio/istio/issues/52519))

- **Corregido** un problema donde las IPs asignadas por el controlador no respetaban la captura DNS por proxy de la misma forma que las IPs auto-asignadas efímeras.
  ([Issue #52609](https://github.com/istio/istio/issues/52609))

- **Corregido** un problema que causaba que los Waypoints ignoraran las IPs auto-asignadas para `ServiceEntry` en algunos casos.
  ([Issue #52746](https://github.com/istio/istio/issues/52746))

- **Corregido** un problema donde la cadena `iptables` `ISTIO_OUTPUT` no se eliminaba con el comando `pilot-agent istio-clean-iptables`.  ([Issue #52835](https://github.com/istio/istio/issues/52835))

- **Corregido** un problema donde el uso de HTTPS en escenarios de solicitudes lentas, como redes con alta pérdida de paquetes, podía provocar una fuga de memoria en Envoy.
  ([Issue #52850](https://github.com/istio/istio/issues/52850))

- **Corregido** un error donde el proxy DNS contenía endpoints no listos para servicios headless.

- **Eliminada** la etiqueta obsoleta `istio.io/gateway-name`; usa en su lugar la etiqueta `gateway.networking.k8s.io/gateway-name`.

- **Eliminada** la escritura de `kubeconfig` en el directorio de red de CNI.
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

- **Eliminado** `CNI_NET_DIR` del configmap de `istio-cni`, ya que no tiene ningún efecto.
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

## Telemetría

- **Actualizado** el vocabulario CEL utilizado en las APIs de telemetría y extensiones. Consulta las notas de actualización para más información.

- **Añadida** una nueva variable de patrón (`%SERVICE_NAME%`) para el prefijo de estadísticas.
  ([Issue #52177](https://github.com/istio/istio/issues/52177))

- **Añadido** el valor `logAsJson` al chart Helm de ztunnel.
  ([Issue #52631](https://github.com/istio/istio/issues/52631))

- **Añadida** configuración de etiquetas de estadísticas para métricas del watchdog.
  ([Issue #52731](https://github.com/istio/istio/issues/52731))

- **Añadido** soporte para cabeceras y configuraciones de timeout en solicitudes gRPC al exportar trazas al OpenTelemetry Collector.  ([Issue #52873](https://github.com/istio/istio/issues/52873))

- **Añadido** soporte para un endpoint personalizado del colector Zipkin mediante `meshConfig.extensionProviders.zipkin.path`.  ([Issue #53086](https://github.com/istio/istio/issues/53086))

- **Corregida** la adición del puerto de métricas a los pods creados por los [despliegues automatizados de `Gateway`](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment).

- **Corregida** la actualización de `citadel_server_root_cert_expiry_timestamp`, `citadel_server_root_cert_expiry_seconds`, `citadel_server_cert_chain_expiry_timestamp` y `citadel_server_cert_chain_expiry_seconds` cuando se cargan nuevos certificados.

- **Añadido** `SECRET_GRACE_PERIOD_RATIO_JITTER` con un valor predeterminado de `0.01` para introducir un offset aleatorizado en `SECRET_GRACE_PERIOD_RATIO`.
  Sin esta configuración, los proxies desplegados al mismo tiempo solicitan certificados renovados simultáneamente, lo que puede causar una carga excesiva en el servidor CA.
  El nuevo comportamiento predeterminado de renovar certificados cada 12 horas se complementa con este valor para ser +/- aproximadamente 15 minutos.
  ([Issue #52102](https://github.com/istio/istio/issues/52102))

## Instalación

- **Actualizado** `securityContext.privileged` a false para istio-cni, en favor de permisos específicos por característica.
  istio-cni sigue siendo un [contenedor "privilegiado" según los Pod Security Standards de Kubernetes](https://kubernetes.io/docs/concepts/security/pod-security-standards/#privileged), ya que incluso sin este flag tiene capacidades privilegiadas, concretamente `CAP_SYS_ADMIN`.
  ([Issue #52558](https://github.com/istio/istio/issues/52558))

- **Mejorado**: los `resources` del Waypoint ahora son configurables mediante `global.waypoint.resources`.
  ([Issue #51496](https://github.com/istio/istio/issues/51496))

- **Mejorado**: la `affinity` del pod Waypoint ahora es configurable mediante `waypoint.affinity`.
  ([Issue #52883](https://github.com/istio/istio/issues/52883))

- **Mejorado**: los `topologySpreadConstraints` del pod Waypoint ahora son configurables mediante `global.waypoint.topologySpreadConstraints`.
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **Mejorado**: los `tolerations` del pod Waypoint ahora son configurables mediante `global.waypoint.tolerations`.
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **Mejorado**: el `nodeSelector` del pod Waypoint ahora es configurable mediante `global.waypoint.nodeSelector`.
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **Mejorada** la huella de memoria del DaemonSet `istio-cni-node`. En muchos casos puede resultar en una reducción de memoria de hasta el 80%.
  ([Issue #53493](https://github.com/istio/istio/issues/53493))

- **Actualizado** el addon de muestra Kiali a la [versión v2.0](https://medium.com/kialiproject/kiali-2-0-for-istio-2087810f337e).

- **Actualizados** todos los componentes de Istio para leer CRDs `v1` donde corresponda. Esto no debería tener impacto, salvo que el clúster use CRDs de Istio de la versión 1.21 o anterior (que no es un salto de versión soportado).

- **Añadidas** las etiquetas `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/part-of`, `app.kubernetes.io/version`, `app.kubernetes.io/managed-by` y `helm.sh/chart` a casi todos los recursos.
  ([Issue #52034](https://github.com/istio/istio/issues/52034))

- **Añadidas** configuraciones específicas de plataforma para instalaciones con Helm. Ejemplo:
  `helm install istio-cni --set profile=ambient --set global.platform=k3s`
  `helm install istiod --set profile=ambient --set global.platform=k3s`

  Para la lista de overrides de plataforma soportados actualmente, consulta los archivos `manifests/charts/platform-xxx.yaml`.

**Eliminados** los variantes de perfil `openshift`, reemplazados por overrides de `global.platform`. Ejemplo:
`helm install istio-cni --set profile=ambient-openshift` ahora es
`helm install istio-cni --set profile=ambient --set global.platform=openshift`

- **Añadida** la posibilidad de configurar `initContainers` para Istiod.
  ([Issue #53120](https://github.com/istio/istio/issues/53120))

- **Añadida** configuración de opciones (`strategy`, `minReadySeconds` y `terminationGracePeriodSeconds`) para estabilizar gateways con tráfico elevado.
  ([Issue #53121](https://github.com/istio/istio/issues/53121))

- **Añadido** el valor `seLinuxOptions` al chart `istio-cni`. En algunas plataformas (por ejemplo, OpenShift) es necesario establecer
  `seLinuxOptions.type` a `spc_t` para evitar ciertas restricciones de SELinux relacionadas con volúmenes `hostPath`.
  Sin esta configuración, los pods `istio-cni-node` pueden fallar al iniciarse.  ([Issue #53558](https://github.com/istio/istio/issues/53558))

- **Añadido** soporte para proporcionar variables de entorno arbitrarias al chart `istio-cni`.

- **Añadida** una nueva anotación `sidecar.istio.io/nativeSidecar` para que los usuarios puedan controlar la inyección nativa de sidecar por pod.
  Esta anotación se puede establecer en `true` o `false` para habilitar o deshabilitar la inyección nativa de sidecar en un pod.
  Esta anotación tiene prioridad sobre la variable de entorno global `ENABLE_NATIVE_SIDECARS`.
  ([Issue #53452](https://github.com/istio/istio/issues/53452))

- **Añadida** la posibilidad de agregar anotaciones personalizadas a `MutatingWebhookConfiguration` para revision-tags mediante el chart Helm.

- **Corregida** la eliminación de las reglas `kube-virt-interfaces` por la herramienta `istio-clean-iptables`.
  ([Issue #48368](https://github.com/istio/istio/issues/48368))

- **Corregida** la posibilidad de re-ejecutar istio-iptables omitiendo el paso de aplicación si las reglas existentes son compatibles.

- **Corregido** un problema donde algunas líneas de estado de la instalación no se finalizaban correctamente, lo que podía causar un renderizado extraño al redimensionar la ventana del terminal.
  ([Issue #52525](https://github.com/istio/istio/issues/52525))

- **Corregido**: se establece `allowPrivilegeEscalation` a `true` en ztunnel — siempre fue forzado a `true` en la práctica pero Kubernetes no lo valida correctamente: <https://github.com/kubernetes/kubernetes/issues/119568>.

- **Corregida** la eliminación de componentes no críticos del chart `base` y de `pilot.enabled` de los charts `istiod-remote` e `istio-discovery`.

- **Corregida** la instalación de CRDs mediante plantillas en el chart `base` por defecto. Anteriormente esto solo funcionaba bajo ciertas condiciones, y al usar ciertos flags de instalación, podía generar CRDs que solo podían actualizarse mediante intervención manual con `kubectl`.
  Consulta las notas de actualización para más información.

- **Obsoleto** `Values.base.enableCRDTemplates`. Esta opción ahora tiene el valor predeterminado `true` y se eliminará en una versión futura. Hasta entonces, el comportamiento heredado se puede habilitar estableciéndolo en `false`.
  ([Issue #43204](https://github.com/istio/istio/issues/43204))

- **Eliminados** algunos campos de la API de values de Helm que no tenían efecto y en algunos casos llevaban tiempo obsoletos.
  Los campos eliminados son: `pilot.configNamespace`, `pilot.configSource`, `pilot.enableProtocolSniffingForOutbound`, `pilot.enableProtocolSniffingForInbound`, `pilot.useMCP`,
  `global.autoscalingV2API`, `global.configRootNamespace`, `global.defaultConfigVisibilitySettings`, `global.useMCP`, `sidecarInjectorWebhook.objectSelector` y `sidecarInjectorWebhook.useLegacySelectors`.
  ([Issue #51987](https://github.com/istio/istio/issues/51987))

- **Eliminados** los valores de `istio_cni` no utilizados del chart `istiod` que estaban marcados como obsoletos (#49290) hace 2 versiones.
  ([Issue #52645](https://github.com/istio/istio/issues/52645))

- **Eliminado** el chart `istiod-remote` en favor de `helm install istio-discovery --set profile=remote`.

- **Eliminado** el soporte para el `compatibilityProfile` `1.20`. Esto configuraba los siguientes ajustes: `ENABLE_EXTERNAL_NAME_ALIAS`,
  `PERSIST_OLDEST_FIRST_HEURISTIC_FOR_VIRTUAL_SERVICE_HOST_MATCHING`, `VERIFY_CERTIFICATE_AT_CLIENT` y `ENABLE_AUTO_SNI`.
  Todos estos flags, excepto `ENABLE_AUTO_SNI`, también han sido eliminados de Istio por completo.

- **Eliminada** la anotación `sidecar.istio.io/enableCoreDump`. Consulta el ejemplo en `samples/proxy-coredump` para métodos preferibles de habilitar volcados de núcleo.

- **Eliminadas** las opciones de flag heredadas `--log_rotate_*`. Los usuarios que deseen usar rotación de logs deben utilizar herramientas externas de rotación.

## istioctl

- **Añadida** la detección automática de una variedad de incompatibilidades específicas de plataforma durante la instalación.

- **Añadido** un nuevo comando, `istioctl manifest translate`, para ayudar a migrar de `istioctl install` a `helm`.

- **Añadido** un nuevo flag `remote-contexts` al comando `istioctl analyze` para especificar contextos de clústeres remotos durante el análisis multiclúster.
  ([Issue #51934](https://github.com/istio/istio/issues/51934))

- **Añadido** soporte para filtrar Pods por selector de etiquetas en `istioctl x envoy-stats`.

- **Añadido** soporte para filtrar recursos por namespace en `istioctl experimental injector list`.

- **Añadido** soporte para los flags `--impersonate` en istioctl.
  ([Issue #52285](https://github.com/istio/istio/issues/52285))

- **Corregido** que istioctl analyze reportara el error IST0145 con host comodín y subdominio específico.
  ([Issue #52413](https://github.com/istio/istio/issues/52413))

- **Corregido** que `istioctl experimental injector list` mostrara webhooks no relacionados con Istio.

- **Eliminados** los comandos `istioctl manifest diff` e `istioctl manifest profile diff`. Los usuarios que quieran comparar manifiestos pueden usar herramientas genéricas de comparación de YAML.

- **Eliminado** el comando `istioctl profile`. La misma información se puede encontrar en la documentación de Istio.

## Cambios en la documentación

- **Mejorada** la legibilidad de la documentación de Istio al renombrar el ejemplo `sleep` a `curl`.
  ([Issue #15725](https://github.com/istio/istio.io/issues/15725))
