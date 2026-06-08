---
title: Notas de Cambios
linktitle: 1.28.0
subtitle: Versión Menor
description: Notas de versión de Istio 1.28.0.
publishdate: 2025-11-05
release: 1.28.0
weight: 10
aliases:
    - /news/announcing-1.28.0
---

## Gestión de Tráfico

- **Promovido** el soporte dual-stack de Istio a beta.
  ([Issue #54127](https://github.com/istio/istio/issues/54127))

- **Actualizado** el valor predeterminado para el máximo de conexiones aceptadas por evento de socket. El
  valor predeterminado ahora es 1 para los listeners entrantes y salientes que enlazan explícitamente a puertos
  en sidecars. Los listeners sin intercepción de iptables se beneficiarán de un mejor rendimiento
  en escenarios de alta rotación de conexiones. Para obtener el comportamiento anterior, puedes configurar `MAX_CONNECTIONS_PER_SOCKET_EVENT_LOOP`
  a cero.

- **Añadido** soporte para atributos de cookies en el balanceo de carga con hash consistente. Ahora puedes especificar atributos adicionales, como `SameSite`, `Secure` y `HttpOnly`. Esto permite un manejo de cookies más seguro y conforme en escenarios de balanceo de carga.
  ([Issue #56468](https://github.com/istio/istio/issues/56468)), ([Issue #49870](https://github.com/istio/istio/issues/49870))

- **Añadida** la variable de entorno `DISABLE_SHADOW_HOST_SUFFIX` para controlar el comportamiento del sufijo de host shadow en las políticas de mirroring. Cuando se establece en `true` (predeterminado), se añaden sufijos de host shadow a los nombres de host de las solicitudes reflejadas. Cuando se establece en `false`, no se añaden sufijos de host shadow. Esto proporciona compatibilidad con versiones anteriores para los usuarios que actualizan desde versiones anteriores de Istio donde los sufijos de host shadow se añadían por defecto a través de perfiles de compatibilidad.
  ([Issue #57530](https://github.com/istio/istio/issues/57530))

- **Añadido** soporte para `sectionName` en `BackendTLSPolicy` de la Gateway API para habilitar la configuración TLS específica por puerto. Esto permite seleccionar puertos específicos de un Service por nombre, habilitando diferentes configuraciones TLS por puerto.

- **Añadido** soporte para `ServiceEntry` como `targetRef` en `BackendTLSPolicy`. Esto permite a los usuarios aplicar configuraciones TLS a servicios externos definidos por recursos `ServiceEntry`.
  ([Issue #57521](https://github.com/istio/istio/issues/57521))

- **Añadido** soporte para nftables nativo al usar el modo ambient de Istio. Esta actualización hace posible usar nftables
  en lugar de iptables para gestionar las reglas de red. Para habilitar el modo nftables, usa `--set values.global.nativeNftables=true` al instalar Istio.
  ([Issue #57324](https://github.com/istio/istio/issues/57324))

- **Añadido** soporte para hosts comodín en recursos `ServiceEntry` con resolución `DYNAMIC_DNS`.
  Esto solo se admite para el tráfico HTTP por ahora. Requiere modo ambient y un waypoint configurado como
  gateway de salida.
  ([Issue #54540](https://github.com/istio/istio/issues/54540))

- **Añadido** soporte para cabeceras `X-Forwarded` en `ProxyConfig.ProxyHeaders`.

- **Habilitados** los waypoints para enrutar tráfico a redes remotas en multiclúster ambient.
  ([Issue #57537](https://github.com/istio/istio/issues/57537))

- **Corregido** un error donde ztunnel no usaba correctamente el mapa de puertos de `WorkloadEntry` al referenciar un nombre de puerto de `Service`.
  ([Issue #56251](https://github.com/istio/istio/issues/56251))

- **Corregido** un problema donde el observador de etiquetas no consideraba que la revisión predeterminada era la misma que la etiqueta predeterminada. Esto causaba problemas donde los gateways de Kubernetes no se programaban.
  ([Issue #56767](https://github.com/istio/istio/issues/56767))

- **Corregido** un error donde el número de puerto de `Service` shadow para un `InferencePool` comenzaba con 543210 en lugar de 54321.
  ([Issue #57472](https://github.com/istio/istio/issues/57472))

- **Corregido** un problema donde el data plane de ambient no manejaba correctamente los `ServiceEntries` con resolución configurada como `NONE`. Anteriormente, la configuración tendría un VIP pero sin endpoints, lo que resultaría en un error "no healthy upstream". Este escenario ahora se configura como un servicio `PASSTHROUGH`, lo que significa que las direcciones llamadas por el cliente se usarán como backend.
  ([Issue #57656](https://github.com/istio/istio/issues/57656))

- **Corregido** un problema donde la configuración del pool de conexiones HTTP/2 no se aplicaba al habilitar las actualizaciones HTTP/2.
  ([Issue #57583](https://github.com/istio/istio/issues/57583))

- **Corregidos** los despliegues de waypoint para usar el `terminationGracePeriodSeconds` predeterminado de Kubernetes (30 segundos) en lugar de un valor codificado de 2 segundos.

- **Añadido** soporte para `InferencePool` v1.
  ([Issue #57219](https://github.com/istio/istio/issues/57219))

- **Eliminado** el soporte para las versiones alpha y release candidate de `InferencePool`.

## Seguridad

- **Mejorado** el análisis de certificados raíz cuando algunos certificados son inválidos. Istio ahora filtra los certificados mal formados en lugar de rechazar el bundle completo.

- **Añadido** el campo `caCertCredentialName` en `ServerTLSSettings` para referenciar un `Secret`/`ConfigMap` que contiene certificados CA para mTLS.
  Consulta [uso](/docs/tasks/traffic-management/ingress/secure-ingress/#key-formats) o [referencia](/docs/reference/config/networking/gateway/#ServerTLSSettings-ca_cert_credential_name) para más información.
  ([Issue #43966](https://github.com/istio/istio/issues/43966))

- **Añadido** el despliegue opcional de `NetworkPolicy` para istiod. Puedes establecer `global.networkPolicy.enabled=true` para desplegar una `NetworkPolicy` predeterminada para istiod y gateways.
  ([Issue #56877](https://github.com/istio/api/issues/56877))

- **Añadido** soporte para configurar `seccompProfile` en los contenedores `istio-validation` e `istio-proxy` dentro de la plantilla de inyección sidecar. Los usuarios ahora pueden establecer `seccompProfile.type` a `RuntimeDefault` para mejorar el cumplimiento de seguridad.
  ([Issue #57004](https://github.com/istio/istio/issues/57004))

- **Añadido** soporte para `FrontendTLSValidation` (GEP-91) en la Gateway API.
  Consulta [uso](/docs/tasks/traffic-management/ingress/secure-ingress/#configure-a-mutual-tls-ingress-gateway) y [referencia](https://gateway-api.sigs.k8s.io/reference/spec/#frontendtlsvalidation) para más información.
  ([Issue #43966](https://github.com/istio/istio/issues/43966))

- **Corregida** la configuración del filtro JWT para soportar claims personalizados delimitados por espacios. La configuración del filtro JWT ahora incluye correctamente los claims personalizados delimitados por espacios especificados por el usuario además de los claims predeterminados ("scope" y "permission"). Para configurar claims personalizados delimitados por espacios, usa el campo `spaceDelimitedClaims` en la configuración de la regla JWT dentro del recurso `RequestAuthentication`.
  ([Issue #56873](https://github.com/istio/istio/issues/56873))

- **Eliminado** el uso de MD5 para optimizar comparaciones. Istio no ha usado MD5 para propósitos criptográficos. El cambio es simplemente para hacer el código más fácil de auditar y ejecutar en [modo FIPS 140-3](https://go.dev/doc/security/fips140).

## Telemetría

- **Actualizado** el valor predeterminado de la variable de entorno `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY` a `true`, habilitando la generación de spans ascendentes para solicitudes de gateway por defecto.

- **Añadido** soporte para las anotaciones `sidecar.istio.io/statsFlushInterval` y `sidecar.istio.io/statsEvictionInterval`.

- **Añadido** soporte para la configuración `TraceContextOption` de Zipkin para habilitar la propagación dual de cabeceras B3/W3C.
  Configura con `trace_context_option: USE_B3_WITH_W3C_PROPAGATION` en `extensionProviders` de MeshConfig para
  extraer cabeceras B3 preferentemente, recurrir a cabeceras W3C `traceparent` como alternativa, e inyectar ambos tipos de cabeceras
  en el upstream para una mejor interoperabilidad de trazado.

- **Eliminado** el soporte de vencimiento de métricas. Usa `StatsEviction` en la configuración de bootstrap en su lugar.

## Extensibilidad

- **Corregido** un problema donde `EnvoyFilter` usando `targetRef` con tipo `GatewayClass` y grupo `gateway.networking.k8s.io` en el namespace raíz no se propagaba correctamente.

## Instalación

- **Actualizado** el chart de Helm de istiod para crear recursos `EndpointSlice` en lugar de `Endpoints` para instalaciones remotas de istiod debido a la deprecación de `Endpoints` a partir de Kubernetes 1.33.
  ([Issue #57037](https://github.com/istio/istio/issues/57037))

- **Actualizado** el addon Kiali a la versión v2.17.0.

- **Añadida** la posibilidad de establecer completamente a null los límites o solicitudes de recursos en el chart de gateway.

- **Añadido** soporte para instalaciones "basadas en persona" a nuestros charts de Helm basado en el alcance de los recursos generados/aplicados.
    - Si no se establece `resourceScope`, se instalarán todos los recursos. Este es el mismo comportamiento que un usuario esperaría de los charts de 1.27.
    - Si `resourceScope` se establece en `namespace`, solo se instalarán los recursos con alcance de namespace.
    - Si `resourceScope` se establece en `cluster`, solo se instalarán los recursos con alcance de clúster.
  Para el chart de ztunnel, `resourceScope` es un campo de nivel superior. Para todos los demás charts, es un campo bajo `global`.
  ([Issue #57530](https://github.com/istio/istio/issues/57530))

- **Añadido** soporte para la variable de entorno `FORCE_IPTABLES_BINARY` para anular la detección del backend de iptables y usar un binario específico.
  ([Issue #57827](https://github.com/istio/istio/issues/57827))

- **Añadidos** `.Values.podLabels` y `.Values.daemonSetLabels` al chart de Helm de istio-cni.

- **Añadida** la configuración `service.clusterIP` al chart de Gateway para soportar la anulación del `spec.clusterIP` del recurso `Service`.

- **Añadida** una nueva representación de las etiquetas de revisión usando servicios de IP de clúster, diseñada para dejar de usar webhooks mutantes en modo ambient.

- **Añadida** la opción `internalTrafficPolicy` para el servicio de gateway.

- **Corregido** un problema donde el PDB creado por una instalación predeterminada bloqueaba el drenado de nodos de Kubernetes.
  ([Issue #12602](https://github.com/istio/istio/issues/12602))

- **Actualizado** el soporte de la Gateway API a v1.4. Esto introduce soporte para `BackendTLSPolicy` v1.

## istioctl

- **Añadida** la detección automática de la revisión predeterminada en los comandos de `istioctl`. Cuando `--revision` no se especifica explícitamente, se usará automáticamente la revisión predeterminada (según lo configurado por `istioctl tag set default`).
  ([Issue #54518](https://github.com/istio/istio/issues/54518))

- **Añadido** soporte para especificar tanto `--level` como `--stack-trace-level` para `istioctl admin log`.
  ([Issue #57007](https://github.com/istio/istio/issues/57007))

- **Añadido** soporte para especificar el puerto de administración del proxy para `istioctl experimental authz`, `istioctl proxystatus`, `istioctl bug-report` e `istioctl experimental describe` con el flag `--proxy-admin-port`.

- **Añadidos** flags para soportar la lista de tipos de depuración para `istioctl experimental internal-debug`.
  ([Issue #57372](https://github.com/istio/istio/issues/57372))

- **Añadido** soporte para mostrar información de conexión para `istioctl ztunnel-config all`.

- **Corregido** el analizador IST0173 (`DestinationRuleSubsetNotSelectPods`) que marcaba incorrectamente los subconjuntos de `DestinationRule` como no seleccionando ningún pod cuando los subconjuntos usaban etiquetas de topología.
