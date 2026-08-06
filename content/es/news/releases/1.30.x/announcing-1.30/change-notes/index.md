---
title: Notas de Cambios de Istio 1.30.0
linktitle: 1.30.0
subtitle: Versión Menor
description: Notas de versión de Istio 1.30.0.
publishdate: 2026-05-18
release: 1.30.0
weight: 10
aliases:
    - /news/announcing-1.30.0
---

## Gestión de Tráfico

- **Mejorada** la selección de endpoints para entornos multi-red para usar el gateway para endpoints específicos de red cuando la red del proxy local no está configurada.

- **Mejorada** la selección del namespace de servicio del proxy sidecar. Al configurar proxies sidecar, si un nombre de host existe en múltiples namespaces, Istio ahora prefiere los servicios de Kubernetes y recurre al servicio no-Kubernetes más antiguo (p.ej., `ServiceEntry`) por tiempo de creación. Anteriormente, se elegía el primer namespace visible alfabéticamente.

- **Añadida** la síntesis opcional de `x-forwarded-client-cert` en waypoints ambient. Configurar la
  anotación `ambient.istio.io/xfcc-include-client-identity: "true"` en un `Gateway` de waypoint
  (o su `GatewayClass`) hace que el waypoint sobreescriba XFCC en las solicitudes reenviadas con una
  entrada poblada a partir de la identidad SPIFFE del workload fuente proporcionada por ztunnel, para que las aplicaciones upstream
  puedan ver el cliente de origen. Cualquier valor XFCC entrante es reemplazado. Los waypoints sin la
  anotación no se ven afectados.
  ([Issue #54995](https://github.com/istio/istio/issues/54995))

- **Añadido** soporte para la terminación y modo mixto de `TLSRoute`.
  ([Issue #55728](https://github.com/istio/istio/issues/55728))

- **Añadida** la variable de entorno `PILOT_GATEWAY_TRANSPORT_SOCKET_CONNECT_TIMEOUT` para configurar el
  tiempo de espera de conexión del socket de transporte en los listeners del gateway. El valor predeterminado sigue siendo 15 segundos. Establece a `0s`
  para deshabilitar el tiempo de espera para workloads que requieren tiempos de negociación TLS más largos.
  ([Issue #56320](https://github.com/istio/istio/issues/56320))

- **Añadida** la capacidad de compresión HTTP (`gzip`, `zstd`) al servidor HTTP de pilot-agent.
  ([Issue #58697](https://github.com/istio/istio/issues/58697))

- **Añadida** la validación de entrada para la anotación `traffic.sidecar.istio.io/excludeInterfaces`
  para asegurar que solo se aceptan nombres de interfaz Linux válidos, previniendo la inyección de parámetros de `iptables`.
  ([Issue #58781](https://github.com/istio/istio/issues/58781))

- **Añadido** soporte para cargar secrets remotos multiclúster desde una ruta del sistema de archivos local especificada por
  `PILOT_MULTICLUSTER_KUBECONFIG_PATH`. Cuando se establece, Istiod monitorea el directorio montado (para
  claves `.yaml` o `.yml`) y actualiza dinámicamente los registros de clústeres remotos.
  ([Issue #58927](https://github.com/istio/istio/issues/58927))

- **Añadido** soporte experimental para agentgateway en Istio. La configuración de agentgateway
  puede habilitarse mediante el flag de características `PILOT_ENABLE_AGENTGATEWAY`.
  Istio soporta la configuración de agentgateway a través de los recursos de la Gateway API.
  ([Issue #59209](https://github.com/istio/istio/issues/59209))

- **Añadido** soporte de dirección CIDR para `ServiceEntry` en modo ambient. Los `ServiceEntries` con direcciones
  CIDR (p.ej., `10.0.0.0/24`) ahora se propagan a ztunnel, habilitando el enrutamiento por prefijo más largo
  para el tráfico destinado a rangos de IP.
  ([Issue #59797](https://github.com/istio/istio/issues/59797))

- **Añadida** la posibilidad de configurar los tamaños iniciales de la ventana de flujo y conexión HTTP/2 para los clústeres HBONE CONNECT upstream
  (generados para waypoints y gateways east-west) mediante los flags de características
  `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE` y `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`.
  ([Issue #59961](https://github.com/istio/istio/issues/59961))

- **Añadida** una anotación `istio.io/connect-strategy` a los `ServiceEntries` para permitir diferentes semánticas de conexión DNS. Los usuarios pueden establecer esto a `RACE_FIRST_TCP_CONNECT` cuando los servidores DNS devuelven múltiples registros A y el cliente debe probar cada endpoint y elegir el primero que resulte en una conexión TCP exitosa.
  ([Issue #59083](https://github.com/istio/istio/issues/59083))

- **Añadido** soporte de prioridad de failover para clústeres DNS.
  ([Issue #58674](https://github.com/istio/istio/issues/58674))

- **Añadido** el tiempo de espera de DNS upstream configurable mediante la variable de entorno `DNS_FORWARD_TIMEOUT`. El tiempo de espera predeterminado sigue siendo 5 segundos.
  ([Issue #59813](https://github.com/istio/istio/issues/59813))

- **Añadido** soporte para listeners TLS passthrough en gateways east-west, permitiendo que
  los puertos que no son HBONE se expongan a través de la Gateway API.
  ([Issue #59223](https://github.com/istio/istio/issues/59223))

- **Añadida** la anotación de distribución de tráfico a nivel de namespace. Los servicios heredan la distribución de tráfico de la anotación del namespace cuando no está explícitamente configurada en el servicio.
  ([Issue #58701](https://github.com/istio/istio/issues/58701))

- **Añadido** soporte de `ServiceEntry` con `DYNAMIC_DNS` comodín para proxies sidecar tanto para ubicaciones `MESH_INTERNAL` como `MESH_EXTERNAL`.
  ([Issue #58244](https://github.com/istio/istio/issues/58244))

- **Añadida** la [API `TrafficExtension`](/blog/2026/traffic-extension-api/) al paquete de extensiones, habilitando el soporte de primera clase para la extensibilidad con Lua.

- **Habilitados** los listeners de Gateway con `protocol: TLS` por defecto. Los listeners de Gateway con `protocol:
  TLS` (usados para TLS passthrough a través de `TLSRoute`) ahora se aceptan sin requerir
  `PILOT_ENABLE_ALPHA_GATEWAY_API=true`, ya que `TLSRoute` se graduó a GA en la Gateway API `v1.5.0`.

- **Corregido** un problema que impedía el uso de pods de Namespaces de Usuario de Kubernetes (`hostUsers: false`) junto con istio-cni.
  ([Issue #58750](https://github.com/istio/istio/issues/58750))

- **Corregido** el manejo de CORS de la Gateway API: análisis correcto del encabezado `Origin` cuando se usan orígenes comodín, ignorar solicitudes preflight no coincidentes, y aplicar un análisis más estricto del encabezado `Origin` en general.
  ([Issue #59018](https://github.com/istio/istio/issues/59018), [Issue #59026](https://github.com/istio/istio/issues/59026))

- **Corregido** un problema donde los waypoints no podían añadir el filtro de escucha del inspector TLS cuando solo existían puertos TLS, lo que causaba que el enrutamiento basado en SNI fallara para recursos `ServiceEntry` comodín con `resolution: DYNAMIC_DNS`.
  ([Issue #59024](https://github.com/istio/istio/issues/59024))

- **Corregido** el error de envoltura en el almacén de configuración basado en archivos para usar el verbo `%w`, habilitando la propagación adecuada de la cadena de errores con `errors.Is()` y `errors.As()`.
  ([Issue #59078](https://github.com/istio/istio/issues/59078))

- **Corregido** el `tls.Options[gateway.istio.io/tls-terminate-mode]` de la Gateway API para anular correctamente el modo TLS después del procesamiento de `CACertificateRefs`.
  ([Issue #59098](https://github.com/istio/istio/issues/59098))

- **Corregida** una referencia nula en la validación de `ServiceEntry` para la resolución `DYNAMIC_DNS` que podía hacer que istiod fallara.
  ([Issue #59171](https://github.com/istio/istio/issues/59171))

- **Corregido** el comportamiento del agente `cni` para respetar la configuración `excludeNamespaces` de modo que el comportamiento sea consistente entre el plugin y el agente.
  ([Issue #59295](https://github.com/istio/istio/issues/59295))

- **Corregido** que istiod fallara cuando `PILOT_ENABLE_AMBIENT=true` pero
  `AMBIENT_ENABLE_MULTI_NETWORK` no está configurado y existe un recurso `WorkloadEntry`
  con una red diferente a la del clúster local.
  ([Issue #59321](https://github.com/istio/istio/issues/59321))

- **Corregido** un problema que impedía el enrutamiento waypoint multiclúster con red única (sin gateway east-west).
  ([Issue #58133](https://github.com/istio/istio/issues/58133))

- **Corregido** un problema donde un `HTTPRoute` sin `backendRefs` devolvía un código de estado HTTP 500
  en lugar del 404 esperado. Según la especificación de la Gateway API, las rutas sin referencias de backend
  deben devolver 404, mientras que las rutas con referencias de backend con peso cero deben devolver 500.
  ([Issue #59356](https://github.com/istio/istio/issues/59356))

- **Corregidas** las instalaciones multi-clúster que intentaban validar el dominio de confianza incorrecto cuando el
  plano de control no tiene un `ClusterRole` `istio-reader` actualizado.
  ([Issue #59474](https://github.com/istio/istio/issues/59474))

- **Corregida** la aplicación de múltiples recursos `VirtualService` para el mismo nombre de host a los waypoints.
  ([Issue #59483](https://github.com/istio/istio/issues/59483))

- **Corregido** un error donde el gateway E/W ocasionalmente enrutaba conexiones HBONE a un servicio incorrecto debido a un pool de conexiones incorrecto en Envoy.
  ([Issue #58630](https://github.com/istio/istio/issues/58630))

- **Corregido** el controlador de despliegue del gateway que rechazaba el tipo `DaemonSet` durante la reconciliación.
  ([Issue #59498](https://github.com/istio/istio/issues/59498))

- **Corregido** un problema donde todos los `Gateways` se reiniciaban después de que istiod se reiniciara.
  ([Issue #59709](https://github.com/istio/istio/issues/59709))

- **Corregidos** los fallos de sondeo de salud de kubelet para los pods de mesh ambient en AWS EKS al usar
  Security Groups for Pods (branch ENI). istio-cni ahora detecta los pods branch ENI y
  añade reglas IP para enrutar el tráfico de sondeo a través del par veth en lugar del tejido VPC.
  Controlado por `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` (activado por defecto).

- **Corregido** que istiod empujara endpoints de gateway IPv6 inalcanzables a proxies solo IPv4 (y viceversa)
  en meshes multi-red con balanceadores de carga de gateway east-west dual-stack.

- **Corregida** una condición de carrera que causaba un pánico cuando se añadían y eliminaban inmediatamente `HTTPRoutes`.

- **Corregido** un problema que impedía que `HTTPRoute` y `GRPCRoute` coexistieran en el mismo nombre de host del gateway sin conflictos.
  ([Issue #59222](https://github.com/istio/istio/issues/59222))

- **Corregida** la devolución de `GetAllAddressesForProxy` de direcciones de servicio inalcanzables a los proxies cuando la
  familia IP de `DefaultAddress` no coincide con la familia IP compatible del proxy.

- **Corregido** el campo `to` de `ReferenceGrant` para manejar múltiples entradas; anteriormente solo era efectiva la última entrada.

- **Corregido** el reporte de estado para los recursos `Gateway` y `ListenerSet` para cumplir con la especificación de la Gateway API `v1.5.0`.

- **Corregido** un error donde el `percent` predeterminado para `retryBudget` en `DestinationRule` se establecía incorrectamente en 0.2% en lugar del 20% previsto.
  ([Issue #59504](https://github.com/istio/istio/issues/59504))

- **Corregido** un error donde el `retryBudget` configurado en la `trafficPolicy` de nivel superior de una `DestinationRule` se descartaba silenciosamente cuando el destino también tenía un subconjunto con su propia `trafficPolicy`.
  ([Issue #59667](https://github.com/istio/istio/issues/59667))

- **Corregidas** las `status.addresses` obsoletas que no se borraban cuando se actualizaba un `ServiceEntry`
  de tal manera que ya no calificaba para la auto-asignación de IP.
  ([Issue #58974](https://github.com/istio/istio/issues/58974))

- **Corregida** una condición de carrera que causaba registros de error intermitentes "proxy::h2 ping error: broken pipe".
  ([Issue #59192](https://github.com/istio/istio/issues/59192)), ([Issue #1346](https://github.com/istio/ztunnel/issues/1346))

## Seguridad

- **Añadido** soporte para múltiples proveedores de autorización CUSTOM por workload, habilitando diferentes esquemas de autenticación (OAuth, LDAP, claves API) para diferentes rutas API.
  ([Issue #57933](https://github.com/istio/istio/issues/57933)), ([Issue #55142](https://github.com/istio/istio/issues/55142)), ([Issue #34041](https://github.com/istio/istio/issues/34041))

- **Añadida** la posibilidad de especificar namespaces autorizados para los endpoints de depuración cuando `ENABLE_DEBUG_ENDPOINT_AUTH=true`. Se habilita configurando `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` con una lista separada por comas de namespaces autorizados. El namespace del sistema (normalmente `istio-system`) siempre está autorizado.

- **Corregido** el mapeo incorrecto de `meshConfig.tlsDefaults.minProtocolVersion` a `tls_minimum_protocol_version` en el contexto TLS descendente.
  ([Issue #58912](https://github.com/istio/istio/issues/58912))

- **Corregida** la expresión regular del comparador `serviceAccount` en `AuthorizationPolicy` para citar correctamente el nombre de la cuenta de servicio. ([CVE-2026-39350](https://nvd.nist.gov/vuln/detail/CVE-2026-39350))
  ([Issue #59700](https://github.com/istio/istio/issues/59700))

  **Crédito**: Esta vulnerabilidad fue descubierta y reportada por Wernerina (<https://github.com/Wernerina>).

- **Corregido** un problema donde Istiod podía emitir certificados de hoja con un tiempo `NotAfter` más allá del vencimiento del certificado de firma.
  ([Issue #59768](https://github.com/istio/istio/issues/59768))

- **Corregido** un bypass de autorización en la coincidencia de `AuthorizationPolicy` para identidades SPIFFE y namespaces.
  ([Issue #59992](https://github.com/istio/istio/issues/59992))

  **Crédito**: Esta vulnerabilidad fue descubierta y reportada por Alex (<https://github.com/Alex0Young>).

- **Corregido** un error donde la rotación del bundle CA no ocurría cuando los certificados aparecían en diferentes órdenes.
  ([Issue #59909](https://github.com/istio/istio/issues/59909))

- **Corregida** una vulnerabilidad de seguridad crítica donde el mecanismo de fallback de JWKS de Istio filtraba una clave privada RSA. Ver [CVE-2026-31837](https://nvd.nist.gov/vuln/detail/CVE-2026-31837) para detalles.
  ([Advisory GHSA-v75c-crr9-733c](https://github.com/istio/istio/security/advisories/GHSA-v75c-crr9-733c))

  **Crédito**: Esta vulnerabilidad fue descubierta y reportada por 1seal (<https://github.com/1seal>).

- **Corregido** el bloqueo de CIDR en URI de JWKS mediante el uso de una función de control personalizada en un `DialContext` personalizado. ([CVE-2026-41413](https://nvd.nist.gov/vuln/detail/CVE-2026-41413))

  **Crédito**: Esta vulnerabilidad fue descubierta y reportada por KoreaSecurity (<https://github.com/KoreaSecurity>), 1seal (<https://github.com/1seal>), y AKiileX (<https://github.com/AKiileX>).

- **Corregidos** los endpoints de depuración XDS (`syncz`, `config_dump`) para requerir autenticación.
  Anteriormente accesibles sin autenticación en el puerto XDS de texto plano 15010.
  Controlado por `ENABLE_DEBUG_ENDPOINT_AUTH` (mismo flag que los endpoints de depuración HTTP). ([CVE-2026-31838](https://nvd.nist.gov/vuln/detail/CVE-2026-31838))

  **Crédito**: Esta vulnerabilidad fue descubierta y reportada por 1seal (<https://github.com/1seal>).

- **Corregidos** los endpoints de depuración XDS (`istio.io/debug/syncz`, `istio.io/debug/config_dump`) servidos por `StatusGen` para aplicar autorización del mismo namespace a los llamantes que no son del sistema.

  **Crédito**: Esta vulnerabilidad fue descubierta y reportada por 1seal (<https://github.com/1seal>).

- **Corregido** el SSRF potencial en la obtención de imágenes de `WasmPlugin` mediante la validación de las URLs de realm del token bearer.

  **Crédito**: Esta vulnerabilidad fue descubierta y reportada por Sergey Kanibor en Luntry (<https://github.com/r0binak>).

- **Corregidos** los `ReadHeaderTimeout` e `IdleTimeout` faltantes en el servidor HTTPS del webhook de istiod (puerto 15017).

- **Corregido** el endpoint de depuración XDS para pasar el namespace del llamante para las comprobaciones de autorización adecuadas.

## Telemetría

- **Añadido** soporte para las etiquetas `app.kubernetes.io/name` y `service.istio.io/canonical-name`
  al poblar las etiquetas de métricas `source_app` y `destination_app`. El orden de prioridad es:
  `app` (para compatibilidad con versiones anteriores), luego `app.kubernetes.io/name`, luego `service.istio.io/canonical-name`.
  ([Issue #58436](https://github.com/istio/istio/issues/58436))

- **Añadido** el campo `disableContextPropagation` a la API de Tracing de Telemetría, permitiendo a los usuarios deshabilitar
  la propagación de cabeceras de contexto de trazado (p.ej., `X-B3-*`, `traceparent`) independientemente del reporte de spans.
  ([Issue #58871](https://github.com/istio/istio/issues/58871))

- **Añadido** soporte para el enriquecimiento de atributos de servicio alineado con las convenciones semánticas de OpenTelemetry
  para spans de trazado.
  ([Issue #55026](https://github.com/istio/istio/issues/55026))

- **Añadido** un panel de Uso de Recursos al dashboard Grafana de Ztunnel que superpone conexiones TCP activas, descriptores de archivo abiertos y sockets abiertos por instancia.

- **Corregido** un problema donde el descubrimiento de metadatos de peers basado en baggage interfería con las políticas de tráfico TLS o
  PROXY. Como solución a corto plazo, se deshabilita el descubrimiento de metadatos basado en baggage
  para las rutas con políticas de tráfico TLS o PROXY configuradas, lo que puede resultar en telemetría incompleta en despliegues multiclúster.
  ([Issue #59117](https://github.com/istio/istio/issues/59117))

## Extensibilidad

- **Añadido** soporte para configurar el límite de tamaño del binario Wasm mediante la
  variable de entorno `ISTIO_WASM_MAX_BINARY_SIZE_BYTES`.
  ([Issue #59322](https://github.com/istio/istio/issues/59322))

- **Corregido** un límite de tamaño faltante en binarios WASM descomprimidos con gzip obtenidos a través de HTTP, de forma consistente con los límites ya aplicados a otras rutas de obtención.

## Instalación

- **Añadido** el valor `useAppArmorAnnotation` al chart de Helm de istio-cni. Predeterminado en `true`.
  ([Issue #54721](https://github.com/istio/istio/issues/54721))

- **Añadido** `values.global.enableReaderRBAC` (predeterminado: `true`) para controlar la instalación de
  `istio-reader-service-account` y su `ClusterRole`/`ClusterRoleBinding` `istio-reader` relacionados.
  ([Issue #56326](https://github.com/istio/istio/issues/56326))

- **Añadido** soporte de Helm v4 (apply del lado del servidor). Corregido un conflicto de propiedad del campo `failurePolicy` del webhook que causaba que `helm upgrade` con SSA fallara.
  ([Issue #58302](https://github.com/istio/istio/issues/58302)), ([Issue #59367](https://github.com/istio/istio/issues/59367))

- **Añadidas** anulaciones de puertos configurables para el servicio de gateway de red mediante los valores `networkGatewayPorts`.
  ([Issue #59072](https://github.com/istio/istio/issues/59072))

- **Añadida** la validación de plantillas para fallar temprano cuando `service.ports` está vacío y `networkGateway` no está configurado.
  ([Issue #59072](https://github.com/istio/istio/issues/59072))

- **Añadido** el registro de advertencias y errores de análisis de configuración en los registros de istiod
  para todos los tipos de recursos de Istio (`DestinationRule`, `EnvoyFilter`, `Sidecar`, etc.).
  ([Issue #59105](https://github.com/istio/istio/issues/59105))

- **Añadida** la condición de estado `WaypointBound` a los recursos `WorkloadEntry`, reportando si el workload está
  correctamente adjunto a su proxy waypoint o si hubo un error al vincularlo.
  ([Issue #59993](https://github.com/istio/istio/issues/59993))

- **Añadido** el flag `--tls-min-version` a `pilot-discovery` para configurar la versión TLS mínima
  para el servidor y webhook de istiod. Los valores admitidos son `1.2` (predeterminado) y `1.3`.
  ([Issue #58789](https://github.com/istio/istio/issues/58789))

- **Añadido** `registry.istio.io` como el registro predeterminado para las imágenes de Istio.

- **Añadidos** los campos `dnsPolicy` y `dnsConfig` al chart de Helm de ztunnel para la configuración DNS personalizada en entornos con requisitos DNS no estándar.

- **Corregidos** los permisos de archivo de configuración CNI al predeterminado 0600 en lugar de 0644 para el cumplimiento del benchmark de Kubernetes CIS `v1.12`.
  ([Issue #59071](https://github.com/istio/istio/issues/59071))

- **Corregida** una referencia nula que ocurría durante el proceso de actualización en un despliegue multi-primary.
  ([Issue #59153](https://github.com/istio/istio/issues/59153))

- **Corregido** un problema donde establecer los límites o solicitudes de recursos a `null` causaba errores de validación.
  ([Issue #58805](https://github.com/istio/istio/issues/58805))

- **Corregida** la variable de entorno `PILOT_ENABLE_NODE_UNTAINT_CONTROLLERS` faltante en el despliegue `istiod` al habilitar el controlador de descontaminación.
  ([Issue #52050](https://github.com/istio/istio/issues/52050))

- **Corregidas** las reconciliaciones innecesarias de Helm causadas por `from: []` en las reglas de entrada de `NetworkPolicy`.

- **Corregido** un conflicto del gestor de campos en `ValidatingWebhookConfiguration` durante `helm upgrade` con
  apply del lado del servidor en herramientas que respetan `.Release.IsUpgrade` (Helm 4, Flux).

## istioctl

- **Mejorado** el rendimiento del comando `istioctl bug-report`.

- **Añadidos** los flags `--skip-cluster-dump`, `--skip-analyze`, `--skip-proxy-debug`, `--skip-netstat` y `--skip-coredumps` al comando `istioctl bug-report` para permitir omitir secciones costosas del reporte.

- **Corregida** la obtención de registros con soporte para filtrado de inclusión y exclusión para la selección de pods.

- **Añadido** el flag `--tail` para establecer el número máximo de líneas de registro a obtener por contenedor. El valor predeterminado sigue siendo ilimitado.

- **Actualizada** la versión mínima de Kubernetes compatible a `1.32.x`.

- **Añadida** la validación de puertos a los comandos de `istioctl` para prevenir valores inválidos fuera del rango 1-65535.
  ([Issue #58584](https://github.com/istio/istio/issues/58584))

- **Añadido** soporte para `istioctl proxy-status -oyaml/json` para listar el estado del proxy de un namespace único.
  ([Issue #59377](https://github.com/istio/istio/issues/59377))

- **Añadida** una advertencia de `istioctl analyze` (IST0175) cuando existen recursos `RequestAuthentication` pero `BLOCKED_CIDRS_IN_JWKS_URIS` no está configurado en istiod.
  ([Issue #59523](https://github.com/istio/istio/issues/59523))

- **Añadidas** opciones de salida JSON y YAML al subcomando `istioctl proxy-status`.
  ([Issue #56880](https://github.com/istio/istio/issues/56880))

- **Añadido** soporte para filtrar la salida de `istioctl ztunnel-config workload` e `istioctl ztunnel-config connections` por nombre de pod de workload.

- **Corregido** un problema donde `istioctl` reportaba falsamente un error en `EnvoyFilter` con operación `REPLACE` en `VIRTUAL_HOST`.
  ([Issue #59495](https://github.com/istio/istio/issues/59495))

- **Corregido** un error de ordenamiento en `istioctl ztunnel-config connections` que causaba que el ordenamiento de la salida fuera no determinístico.
  ([Issue #59775](https://github.com/istio/istio/pull/59775))

- **Corregido** un problema donde la salida JSON y YAML de `istioctl ztunnel-config service` no incluía el campo `canonical` del volcado de configuración de ztunnel.
  ([Issue #59962](https://github.com/istio/istio/issues/59962))

- **Corregido** un problema donde la salida JSON y YAML de `istioctl ztunnel-config service` no incluía `cidrVips` del volcado de configuración de ztunnel.
  ([Issue #59962](https://github.com/istio/istio/issues/59962))

- **Corregido** un problema donde los contenedores distroless de `istioctl` se estaban construyendo con la imagen base incorrecta.

## Cambios de Documentación

- **Actualizada** la ubicación de la documentación de la Gateway API Inference Extension; ahora está en la sección de arquitectura.
  ([Issue #56948](https://github.com/istio/istio/issues/56948))
