---
title: Notas de Cambios de Istio 1.27.0
linktitle: 1.27.0
subtitle: Versión Principal
description: Notas de versión de Istio 1.27.0.
publishdate: 2025-08-11
release: 1.27.0
weight: 10
aliases:
    - /news/announcing-1.27.0
    - /news/announcing-1.27.x
---

## Gestión de tráfico

- **Actualizada** la distribución del tráfico para ignorar la subzona cuando el campo `trafficDistribution` del Kubernetes Service está configurado como `PreferClose`. ([Issue #55848](https://github.com/istio/istio/issues/55848))

- **Añadido** soporte para múltiples certificados de servidor en gateway (istio y Gateway API). ([Issue #36181](https://github.com/istio/istio/issues/36181))

- **Añadido** soporte alfa para especificar `ServiceScope` en MeshConfig en configuraciones de ambient multiclúster.
  `ServiceScope` permite seleccionar servicios individuales o servicios en un namespace para que sean globales o locales.
  Un servicio con ámbito local solo es descubrible por el data plane en el mismo clúster que el servicio. Un servicio
  local no es descubrible por los data planes de otros clústeres. Un servicio con ámbito global es descubrible
  por los data planes de todos los clústeres. Definir selectores para `serviceScopeConfigs` determina qué servicios
  y workloads se comparten con el data plane y qué clústeres y listeners se configuran para los waypoints
  (incluidos los gateways e/w) en la mesh.

- **Añadido** el feature flag `EnableGatewayAPICopyLabelsAnnotations` para permitir a los usuarios elegir si los recursos de despliegue heredarán atributos del recurso padre de Gateway API. Esta función está habilitada por defecto.

- **Añadido** soporte para `PreferSameNode` y `PreferSameZone` en el campo `trafficDistribution` del Kubernetes Service. ([Issue #55848](https://github.com/istio/istio/issues/55848))

- **Añadidas** las variables de entorno de Pilot `PILOT_IP_AUTOALLOCATE_IPV4_PREFIX` y `PILOT_IP_AUTOALLOCATE_IPV6_PREFIX` para configurar el prefijo CIDR de IP para las IPs autoasignadas. Esto permite a los usuarios establecer un rango específico de IPs para la autoasignación, proporcionando más control sobre el espacio de IPs usado para VIPs por el controlador ipallocate.

- **Añadido** el registro del namespace y nombre de un secreto cuando un certificado no es válido.
  ([Issue #56651](https://github.com/istio/istio/issues/56651))

- **Añadido** soporte para [Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/).
  Esta función está desactivada por defecto y puede habilitarse con la variable de entorno `SUPPORT_GATEWAY_API_INFERENCE_EXTENSION`.
  ([Issue #55768](https://github.com/istio/istio/issues/55768))

- **Añadido** soporte para operaciones de fusión al aplicar a `LISTENER_FILTER` en EnvoyFilter.

- **Añadido** el feature `ENABLE_LAZY_SIDECAR_EVALUATION` que permite la inicialización diferida de recursos de sidecar,
  calculando los índices internos solo cuando los `SidecarScopes` son efectivamente usados por un proxy. Este feature
  reemplaza al anterior `PILOT_CONVERT_SIDECAR_SCOPE_CONCURRENCY`, que permitía la conversión concurrente con una
  concurrencia específica; en cambio, `ENABLE_LAZY_SIDECAR_EVALUATION` usará la misma concurrencia que `PILOT_PUSH_THROTTLE`.

- **Añadido** soporte para `nftables` nativo cuando se usa el modo sidecar de Istio. Esta actualización permite usar `nftables`
  en lugar de iptables para gestionar reglas de red, ofreciendo un enfoque más eficiente para la redirección del tráfico de pods y
  servicios. Para habilitar el modo `nftables`, usa `--set values.global.nativeNftables=true` durante la instalación.  ([Issue #56487](https://github.com/istio/istio/issues/56487))

- **Añadido** soporte para especificar el modo de distribución del tráfico para los servicios. ([Issue #53354](https://github.com/istio/istio/issues/53354))

- **Añadido** el feature `ENABLE_PROXY_FIND_POD_BY_IP` que permite la asociación de Pods a Proxies por dirección IP si la asociación por nombre y namespace falla.

- **Añadido** soporte para el presupuesto de reintentos en los recursos `DestinationRule`.

- **Corregido** un problema donde el leader election del controlador de estado de gateway no se ejecutaba por revisión, lo que podía causar problemas en configuraciones con múltiples revisiones.
  El leader election ahora está correctamente limitado a cada revisión, garantizando que el controlador de estado del gateway opere de forma independiente para cada revisión.
  ([Issue #55717](https://github.com/istio/istio/issues/55717))

- **Corregido** un problema donde las rutas de virtual service eran ignoradas cuando el virtual service estaba configurado con hosts que contenían letras en mayúsculas y minúsculas mezcladas.
  ([Issue #55767](https://github.com/istio/istio/issues/55767))

- **Corregida** una regresión en Istio 1.26.0 que causaba un panic en istiod al procesar nombres de host de Gateway API.
  ([Issue #56300](https://github.com/istio/istio/issues/56300))

- **Corregido** un problema donde mTLS se deshabilitaba inesperadamente cuando `PILOT_ENABLE_TELEMETRY_LABEL` o `PILOT_ENDPOINT_TELEMETRY_LABEL` se establecían en `false`.
  ([Issue #56352](https://github.com/istio/istio/issues/56352))

- **Corregido** un problema donde las reglas de iptables de la red de host de ambient eran omitidas debido a reglas CNI de mayor prioridad en algunos despliegues.
  ([Issue #56414](https://github.com/istio/istio/issues/56414))

- **Corregido** un problema donde `EnvoyFilter` con `targetRefs` coincidía con recursos incorrectos.
  ([Issue #56417](https://github.com/istio/istio/issues/56417))

- **Corregido** el índice de ambient para filtrar configuraciones por su revisión.
  ([Issue #56477](https://github.com/istio/istio/issues/56477))

- **Corregido** un problema donde la etiqueta `topology.istio.io/network` no se omitía correctamente en el namespace del sistema cuando se usaban `discoverySelectors`.
  ([Issue #56687](https://github.com/istio/istio/issues/56687))

- **Corregido** un problema donde el plugin CNI manejaba incorrectamente la eliminación de pods cuando el pod aún no estaba marcado como inscrito en la mesh. En algunos casos, esto podía causar que un pod eliminado se incluyera en el snapshot ZDS y nunca se limpiara. Si esto ocurría, ztunnel no podía estar listo.  ([Issue #56738](https://github.com/istio/istio/issues/56738))

- **Corregido** un problema donde la configuración de rutas de salida de Istio no incluía el nombre de dominio absoluto (nombre de dominio completamente calificado con punto final) en la lista de dominios para las entradas `VirtualHost`. Este cambio garantiza que las solicitudes que usan nombres de dominio absolutos (que terminan con un punto, p. ej., `my-service.my-ns.svc.cluster.local.`) se enruten correctamente al servicio previsto en lugar de recaer en `PassthroughCluster`.
  ([Issue #56007](https://github.com/istio/istio/issues/56007))

## Seguridad

- **Añadido** soporte para omitir la claim del emisor en los tokens JWT. Se requiere la claim del emisor o un `JWKSUri`,
  pero no ambos. Esto permite configuraciones más flexibles al usar tokens JWT para autenticación, especialmente
  en escenarios donde la claim del emisor puede ser dinámica. ([Issue #14400](https://github.com/istio/istio/issues/14400))

- **Añadida** una función opt-in al usar istio-cni en modo ambient, para crear un archivo de configuración CNI propiedad de Istio
  que contiene el contenido del archivo de configuración CNI principal y el plugin de Istio CNI. Esta
  función opt-in es una solución al problema del tráfico que evita la mesh al reiniciar el nodo cuando el
  `DaemonSet` de Istio CNI no está listo, el plugin de Istio CNI no está instalado o el plugin no
  se invoca para configurar la redirección del tráfico desde los pods hacia sus ztunnels de nodo. Esta función se habilita
  estableciendo `cni.istioOwnedCNIConfig` en true en los valores del chart Helm de istio-cni. Si no se establece ningún valor para
  `cni.istioOwnedCNIConfigFilename`, el archivo de configuración CNI propiedad de Istio se llamará `02-istio-cni.conflist`.
  El valor de `istioOwnedCNIConfigFilename` debe tener una prioridad lexicográfica mayor que el CNI principal.
  Los plugins CNI encadenados y ambient deben estar habilitados para que esta función funcione.

- **Añadida** validación para el argumento de comando `--clusterAliases` de istioctl. No debe tener más de un alias por clúster.  ([Issue #56022](https://github.com/istio/istio/issues/56022))

- **Añadido** soporte para `ClusterTrustBundle` mediante la migración de `certificates.k8s.io/v1alpha1` a la API estable `v1beta1` en Kubernetes 1.33+. Esto mejora la compatibilidad y garantiza la vigencia del mecanismo de distribución de certificados de Istio en el futuro.
  ([Issue #56306](https://github.com/istio/istio/issues/56306))

- **Añadido** soporte para proveedores externos de Secret Discovery Service (SDS) en la configuración TLS del Gateway. Istio ahora ofrece
  una integración mejorada con proveedores SDS externos para la gestión de certificados TLS en el Gateway.
  ([Issue #56522](https://github.com/istio/istio/issues/56522))

- **Añadido** soporte para listas de revocación de certificados (CRL) para CAs conectadas, habilitando a Istio para monitorear archivos `ca-crl.pem` y
  distribuir automáticamente las CRL en todos los namespaces del clúster. Esta mejora permite
  a los proxies validar y rechazar certificados revocados, mejorando la postura de seguridad de los despliegues de service mesh
  que usan CAs conectadas.  ([Issue #56529](https://github.com/istio/istio/issues/56529))

- **Añadida** la opción de criptografía post-cuántica (PQC) a `COMPLIANCE_POLICY`.
  Esta política aplica TLS `v1.3`, los cipher suites `TLS_AES_128_GCM_SHA256` y `TLS_AES_256_GCM_SHA384`,
  y el intercambio de claves post-cuántico seguro `X25519MLKEM768`.
  Para habilitar esta política de conformidad en modo ambient, debe establecerse en los contenedores pilot y ztunnel.
  Esta política aplica a los siguientes flujos de datos:
    - comunicación mTLS entre proxies Envoy y ztunnels;
    - TLS regular en el upstream y downstream de los proxies Envoy (p. ej., gateway);
    - servidor xDS de Istio.
  ([Issue #56330](https://github.com/istio/istio/issues/56330))

- **Corregido** un problema donde los sidecars con la configuración antigua de `CLUSTER_ID` no podían conectarse a istiod con la nueva configuración de `CLUSTER_ID` cuando se usaba el argumento de comando `--clusterAliases`.
  ([Issue #56022](https://github.com/istio/istio/issues/56022))

- **Corregido** un problema en el feature `pluginca` donde `istiod` regresaba silenciosamente a la CA auto-firmada si el bundle `cacerts` proporcionado estaba incompleto.
  El sistema ahora valida correctamente la presencia de todos los archivos CA requeridos y falla con un error si el bundle está incompleto.

## Telemetría

- **Corregido** un problema donde el dashboard de Grafana enlazaba al Istio Mesh Dashboard usando enlaces basados en rutas que ya no funcionan. Los enlaces de workload y servicio ahora usan UIDs de dashboard.
  ([Issue #50124](https://github.com/istio/istio/issues/50124))

- **Corregido** un problema donde los access logs no se actualizaban cuando el servicio referenciado se creaba después del recurso Telemetry.
  ([Issue #56825](https://github.com/istio/istio/issues/56825))

- **Eliminado** el soporte del proveedor de trazado `Lightstep`.
  ([Issue #54002](https://github.com/istio/istio/issues/54002))

## Extensibilidad

- **Añadida** una opción para recargar la VM de Wasm en nuevas solicitudes si la VM ha fallado.

## Instalación

- **Promovida** la variable de entorno `ENABLE_NATIVE_SIDECARS` para que sea `true` por defecto. Esto significa que los native sidecars se inyectarán en todos los pods elegibles a menos que se deshabiliten explícitamente.
  Se puede deshabilitar explícitamente o para workloads específicos añadiendo la anotación `sidecar.istio.io/native-side: "false"` a pods individuales o a plantillas de pod.
  ([Issue #48794](https://github.com/istio/istio/issues/48794))

- **Añadido** el ajuste `values.global.trustBundleName` que permite configurar el nombre del ConfigMap que istiod usa para propagar su certificado CA raíz en el clúster. Esto permite ejecutar múltiples control planes con namespaces superpuestos en el mismo clúster.

- **Añadido** soporte para personalizar las etiquetas de habilitación de ambient.
  ([Issue #53578](https://github.com/istio/istio/issues/53578))

- **Añadido** soporte para configurar `additionalContainers` e `initContainers` en el chart Helm de Gateway.

- **Añadido** soporte para configurar toleraciones de ztunnel mediante los valores del chart Helm.
  ([Issue #56086](https://github.com/istio/istio/issues/56086))

- **Añadido** soporte para configurar toleraciones de istio-cni mediante los valores del chart Helm.
  ([Issue #56087](https://github.com/istio/istio/issues/56087))

- **Añadidos** valores predeterminados definidos para los divisores de `GOMEMLIMIT` y `GOMAXPROCS` para corregir un problema de desfase perpetuo de Argo.

- **Añadida** la configuración de override de bootstrap para `gateway-injection-template`.
  ([Issue #28302](https://github.com/istio/istio/issues/28302))

- **Añadido** el valor Helm `ENABLE_NATIVE_SIDECARS` en los perfiles de compatibilidad de Istio 1.24, 1.25 y 1.26, permitiendo a los usuarios deshabilitar la habilitación predeterminada de native sidecars.

- **Añadido** soporte para el protocolo proxy en el puerto de estado. ([referencia](/docs/reference/commands/pilot-agent/#envvars))
  ([Issue #39868](https://github.com/istio/istio/issues/39868))

- **Añadido** el valor Helm `.Values.istiodRemote.enabledLocalInjectorIstiod` para dar soporte a la inyección de sidecar en clústeres remotos.
  Cuando `profile=remote`, `.Values.istiodRemote.enabledLocalInjectorIstiod=true` y `.Values.global.remotePilotAddress="${DISCOVERY_ADDRESS}"`,
  el clúster worker remoto instala `istiod` para la inyección local de sidecar, mientras que XDS sigue siendo servido por el clúster primario remoto.
  ([Issue #56328](https://github.com/istio/istio/issues/56328))

- **Añadida** la etiqueta `istio.io/rev` al servicio remoto de istio cuando se habilita `istiodRemote`.
  ([Issue #56142](https://github.com/istio/istio/issues/56142))

- **Añadido** soporte para `deploymentAnnotations` en el chart Helm de istiod. Los usuarios ahora pueden especificar anotaciones personalizadas para aplicar al objeto Deployment de istiod, además del soporte existente de `podAnnotations`. Esto es útil para la integración con herramientas de monitorización, flujos de trabajo de GitOps y sistemas de aplicación de políticas que operan a nivel de despliegue.

- **Corregido** un problema donde la variable de entorno `ISTIO_KUBE_APP_PROBERS` no se establecía para las reescrituras de sondas cuando el webhook de Istio se reinvocaba.
  ([Issue #56102](https://github.com/istio/istio/issues/56102))

- **Corregido** un problema donde las referencias a secretos en el env del chart Helm `istio/gateway` se renderizaban incorrectamente como cadena de texto.
  ([Issue #55141](https://github.com/istio/istio/issues/55141))

- **Corregido** un fallo de inyección que ocurría cuando la plantilla `gateway` se combinaba con otra plantilla, como `spire`,
que sobreescribe `workload-socket`, resultando en que Kubernetes no creara otros volúmenes, como los con configuración `emptyDir` y `csi`.

- **Corregido** un panic en `istioctl manifest translate` cuando la configuración `IstioOperator` contenía múltiples gateways.
  ([Issue #56223](https://github.com/istio/istio/issues/56223))

- **Corregida** la asignación de UIDs y GIDs incorrectos para los contenedores `istio-proxy` e `istio-validation` en clústeres OpenShift cuando el modo TPROXY estaba habilitado.

- **Corregido** un problema donde `ClusterTrustBundle` no se configuraba correctamente cuando `ENABLE_CLUSTER_TRUST_BUNDLE_API` estaba habilitado.

- **Eliminados** los valores Helm de multiclúster no utilizados.

## istioctl

- **Añadido** el flag `--kubeclient-timeout` a los flags raíz de `istioctl`. Puede no establecerse o establecerse en una cadena `time.Duration` válida.
  Cuando se especifica, sobreescribe el timeout predeterminado de `15s` para todos los comandos de `istioctl` que usan el cliente de Kubernetes.
  Esto es útil en entornos con servidores de API de Kubernetes lentos, como los que tienen alta latencia o bajo ancho de banda.
  Ten en cuenta que este flag solo se usa para el cliente de Kubernetes y no afecta a otros timeouts en `istioctl`, como los de instalación. ([Issue #54962](https://github.com/istio/istio/issues/54962))

- **Añadidos** los flags `--revision` para `istioctl dashboard controlz` e `istioctl dashboard istiod-debug`.

- **Añadido** soporte en el comando `istioctl proxy-status` para mostrar dinámicamente todos los tipos xDS/CRD como columnas en la tabla de salida.
  ([Issue #56005](https://github.com/istio/istio/issues/56005))

- **Añadido** soporte para personalizar el timeout de `istioctl waypoint status` e `istioctl waypoint apply`.
  ([Issue #56453](https://github.com/istio/istio/issues/56453))

- **Añadido** soporte para mostrar `stack-trace-level` en el comando `istioctl admin log`.
  ([Issue #56465](https://github.com/istio/istio/issues/56465))

- **Añadido** soporte para mostrar `traffic type` en el comando `istioctl waypoint list`.

- **Añadido** soporte para el parámetro `--weight` en el comando `istioctl experimental workload group create`.

- **Añadido** soporte para configurar el nivel de log de `ip-autoallocate` en `istioctl admin log`.
  ([Issue #55741](https://github.com/istio/istio/issues/55741))

- **Corregido** un problema donde, durante la instalación, `istio-revision-tag-default` y `MutatingWebhookConfiguration` no se creaban cuando la revisión no era la predeterminada.
  ([Issue #55980](https://github.com/istio/istio/issues/55980))

- **Corregido** un problema donde se generaban falsos positivos de IST0134 en `istioctl analyze` cuando `PILOT_ENABLE_IP_AUTOALLOCATE` estaba establecido en `true`.
  ([Issue #56083](https://github.com/istio/istio/issues/56083))

- **Corregido** un problema donde el análisis incluía los namespaces del sistema de Kubernetes (p. ej., `kube-system`, `kube-node-lease`).
  ([Issue #55022](https://github.com/istio/istio/issues/55022))

- **Corregido** un problema donde `create-remote-secret` creaba recursos RBAC redundantes.
  ([Issue #56558](https://github.com/istio/istio/issues/56558))
