---
title: Notas de Cambios de Istio 1.29.0
linktitle: 1.29.0
subtitle: Versión Menor
description: Notas de versión de Istio 1.29.0.
publishdate: 2026-02-16
release: 1.29.0
weight: 10
aliases:
    - /news/announcing-1.29.0
---

## Gestión de tráfico

- **Promovido** el valor `cni.ambient.dnsCapture` para que sea `true` por defecto.
  Esta configuración habilita el proxy DNS para los workloads en la mesh ambient por defecto, mejorando la seguridad y el rendimiento a la vez que habilita una serie de funciones. Puede desactivarse explícitamente o con `compatibilityVersion=1.24`.
  Nota: solo los pods nuevos tendrán DNS habilitado. Para habilitar DNS en los pods existentes, los pods deben reiniciarse manualmente, o la función de reconciliación de iptables debe habilitarse con `--set cni.ambient.reconcileIptablesOnStartup=true`.

- **Promovida** `cni.ambient.reconcileIptablesOnStartup` para que sea `true` por defecto.
  Esta configuración habilita la reconciliación automática de las reglas de iptables/nftables para los pods ambient existentes cuando el `DaemonSet` de `istio-cni` se actualiza,
  eliminando la necesidad de reiniciar los pods manualmente para recibir la configuración de red actualizada.
  Puede desactivarse explícitamente o utilizando `compatibilityVersion=1.28`.

- **Promovido** el soporte para la [Gateway API Inference Extension](https://gateway-api-inference-extension.sigs.k8s.io/) a beta.
  Esta función permanece desactivada por defecto y puede activarse con la variable de entorno `ENABLE_GATEWAY_API_INFERENCE_EXTENSION`.
  ([uso](/docs/tasks/traffic-management/ingress/gateway-api-inference-extension/)) ([Issue #58533](https://github.com/istio/istio/issues/58533))

- **Promovido** el soporte multiclúster multi-red a Beta en modo ambient. Consulta los [anuncios](/news/releases/1.29.x/announcing-1.29/#multi-network-multicluster-ambient-goes-beta) para más detalles.

- **Añadido** soporte para la etiqueta de localidad de Istio `topology.istio.io/locality`, que tiene precedencia sobre `istio-locality`.

- **Añadida** una opción, `gateway.istio.io/tls-cipher-suites`, para especificar los cipher suites personalizados en un Gateway. El valor es una lista separada por comas de cipher suites.
  ([Issue #58366](https://github.com/istio/istio/issues/58366))

- **Añadido** soporte alfa para un sistema de telemetría basado en baggage para la mesh ambient. Los usuarios de ambient multi-red querrán habilitar esta función mediante la variable de entorno de pilot `AMBIENT_ENABLE_BAGGAGE` para que las métricas del tráfico entre redes se atribuyan correctamente con etiquetas de origen y destino. Ten en cuenta que ztunnel ya envía baggage en las solicitudes; esta función complementa esa funcionalidad con baggage generado también por el waypoint. Por ello, esta función está desactivada por defecto para los waypoints y activada por defecto en los ztunnels (configurable mediante la variable de entorno `ENABLE_RESPONSE_BAGGAGE` en ztunnel).

- **Añadida** lógica para designar un Servicio de Workload Discovery (WDS) como canónico.
  Un Servicio WDS canónico es utilizado por ztunnel durante la resolución de nombres, a menos que exista otro Servicio WDS en el mismo namespace que el cliente para sobreescribirlo. Un servicio canónico se configurará desde (1) un recurso `Service` de Kubernetes o (2) el recurso `ServiceEntry` de Istio más antiguo que especifique ese hostname.
  ([Issue #58576](https://github.com/istio/istio/pull/58576))

- **Añadido** un nuevo feature flag `DISABLE_TRACK_REMAINING_CB_METRICS` para controlar el seguimiento de las métricas restantes del circuit breaker.
  Cuando se establece en `false` (por defecto), las métricas restantes del circuit breaker no se rastrearán, mejorando el rendimiento.
  Cuando se establece en `true`, las métricas restantes del circuit breaker se rastrearán (comportamiento heredado).
  Este feature flag se eliminará en una versión futura.

- **Añadido** soporte para la política de balanceo de carga `LEAST_REQUEST` en clientes gRPC proxyless.

- **Añadido** soporte para circuit breaking (`http2MaxRequests`) en clientes gRPC proxyless.

- **Añadido** soporte para hosts con comodines en recursos `ServiceEntry` con resolución `DYNAMIC_DNS`
  para hosts TLS. El protocolo TLS implica que las conexiones se enrutarán en función del
  SNI de la solicitud (del handshake TLS) sin terminar la conexión TLS para
  inspeccionar la cabecera Host para el enrutamiento. La implementación se basa en una API alfa
  y tiene implicaciones de seguridad significativas (es decir, suplantación de SNI). Por lo tanto, esta
  función está desactivada por defecto y puede habilitarse configurando el feature flag
  `ENABLE_WILDCARD_HOST_SERVICE_ENTRIES_FOR_TLS` a `true`. Por favor, considera usar
  esta función con cuidado y solo con clientes de confianza.
  ([Issue #54540](https://github.com/istio/istio/issues/54540))

- **Corregido** un problema donde los sidecars intentaban enrutar solicitudes hacia los east-west gateways de ambient de forma incorrecta.
  ([Issue #57878](https://github.com/istio/istio/issues/57878))

- **Corregido** un fallo de inicio del agente de nodo CNI de Istio en entornos MicroK8s cuando se usa modo ambient con backend nftables.
  ([Issue #58185](https://github.com/istio/istio/issues/58185))

- **Corregido** un problema donde las configuraciones de `InferencePool` se perdían durante la fusión de `VirtualService` cuando múltiples `HTTPRoute` que hacían referencia a diferentes `InferencePool`s estaban vinculados al mismo Gateway.
  ([Issue #58392](https://github.com/istio/istio/issues/58392))

- **Corregido** un problema donde establecer `ambient.istio.io/bypass-inbound-capture: "true"` causaba que el tráfico HBONE entrante se agotara porque la regla de iptables para rastrear la marca de ztunnel en las conexiones no se aplicaba. Este cambio permite que las conexiones HBONE entrantes funcionen normalmente mientras se preserva el comportamiento de bypass esperado para las conexiones de "passthrough" entrantes.
  ([Issue #58546](https://github.com/istio/istio/issues/58546))

- **Corregido** un error donde el estado de `BackendTLSPolicy` podía perder el seguimiento del Gateway `ancestorRef` debido a corrupción del índice interno.
  ([Issue #58731](https://github.com/istio/istio/pull/58731))

- **Corregido** un problema donde la agresividad de warmup no estaba alineada con la configuración de Envoy.
  ([Issue #3395](https://github.com/istio/api/issues/3395))

- **Corregido** un problema donde los ingress gateways en el multiclúster ambient no enrutaban las solicitudes a los backends remotos expuestos. Esta corrección está detrás de un nuevo feature flag `AMBIENT_ENABLE_MULTI_NETWORK_INGRESS`, que es `false` por defecto. Si el usuario quiere usar esta funcionalidad, debe configurarlo a `true`.

- **Corregido** un problema que causaba que el registro de clústeres del multiclúster ambient se volviera inestable periódicamente, lo que llevaba a que se enviara configuración incorrecta a los proxies.

- **Corregido** un problema donde el monitor de recursos del gestor de sobrecarga para las conexiones descendentes máximas globales
  estaba configurado al valor máximo entero y no podía configurarse mediante Runtime Flags.
  Los usuarios ahora pueden configurar el límite de conexiones descendentes máximas globales mediante los metadatos del proxy `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS`.
  El runtime flag `overload.global_downstream_max_connections` sigue siendo respetado si se especifica por compatibilidad con versiones anteriores, pero está obsoleto en favor
  de este nuevo enfoque mediante metadatos del proxy.

  Si se especifica `overload.global_downstream_max_connections`, aparecerán advertencias de deprecación de Envoy.

  Si se especifican tanto `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS` como `overload.global_downstream_max_connections`,
  los metadatos del proxy tendrán precedencia sobre el runtime flag.
  ([Issue #58594](https://github.com/istio/istio/issues/58594))

- **Corregida** la advertencia sobre la política de balanceo de carga `CONSISTENT_HASH` en clientes gRPC proxyless.

- **Corregido** el Listener xDS de gRPC para enviar tanto los campos actuales como los obsoletos del proveedor de certificados TLS,
  habilitando la compatibilidad entre clientes gRPC antiguos y nuevos (`pre-1.66` y `1.66+`).

- **Corregido** un problema donde la inicialización de CNI podía fallar al crear reglas de host iptables/nftables para las sondas de health check. La inicialización ahora reintenta hasta 10 veces con un retraso de 2 segundos entre intentos para gestionar fallos transitorios.

## Seguridad

- **Mejorado** el manejo del trust domain del clúster remoto implementando la observación del `meshConfig` remoto.
  Istiod ahora observa y actualiza automáticamente la información del trust domain de los clústeres remotos,
  garantizando la coincidencia precisa de SAN para los servicios que pertenecen a más de un trust domain.

- **Añadida** una función de participación opcional cuando se usa istio-cni en modo ambient para crear un archivo de configuración CNI propiedad de Istio que contiene los contenidos del archivo de configuración CNI primario y el complemento CNI de Istio. Esta función es una solución al problema del tráfico que omite la mesh al reiniciar el nodo cuando el `DaemonSet` de istio-cni no está listo, el complemento CNI de Istio no está instalado, o el complemento no se invoca para configurar la redirección de tráfico de los pods a sus ztunnels de nodo. Esta función se habilita configurando `cni.istioOwnedCNIConfig` a `true` en los valores del chart Helm de istio-cni. Si no se establece ningún valor para `cni.istioOwnedCNIConfigFilename`, el archivo de configuración CNI propiedad de Istio se llamará `02-istio-cni.conflist`. El `istioOwnedCNIConfigFilename` debe tener una prioridad lexicográfica mayor que la del CNI primario. Los complementos CNI ambient y encadenado deben estar habilitados para que esta función funcione.

- **Añadido** despliegue opcional de `NetworkPolicy` para istiod e istio-cni.

  Puedes configurar `global.networkPolicy.enabled=true` para desplegar una `NetworkPolicy` predeterminada para istiod,
  istio-cni y los gateways.
  ([Issue #56877](https://github.com/istio/api/issues/56877))

- **Añadido** soporte para observar secretos con symlinks en el agente de nodo de Istio.

- **Añadido** soporte de Lista de Revocación de Certificados (CRL) en ztunnel. Cuando se proporciona un archivo `ca-crl.pem` mediante CA conectada, istiod distribuye automáticamente las CRLs a todos los namespaces participantes en el clúster.
  ([Issue #58733](https://github.com/istio/istio/issues/58733))

- **Añadida** una función experimental para permitir el dry-run de recursos `AuthorizationPolicy` en ztunnel. Esta función estará desactivada por defecto. Consulta las Notas de Actualización para más detalles.
 ([uso](/docs/tasks/security/authorization/authz-dry-run/)) ([Issue #1933](https://github.com/istio/api/pull/1933))

- **Añadido** soporte para bloquear CIDRs en URIs JWKS al obtener claves públicas para la validación JWT.
  Si alguna IP resuelta de una URI JWKS coincide con un CIDR bloqueado, Istio omitirá la obtención de la clave pública
  y usará un JWKS falso para rechazar las solicitudes con tokens JWT.

- **Añadido** un mecanismo de reintentos al comprobar si un pod tiene ambient habilitado en istio-cni.
  Esto es para abordar posibles fallos transitorios que resulten en una posible omisión de la mesh. Esta función
  está desactivada por defecto y puede habilitarse configurando `ambient.enableAmbientDetectionRetry` en el chart de `istio-cni`.

- **Añadida** autorización basada en namespace para los endpoints de depuración en el puerto 15014.
  Los namespaces que no son del sistema quedan restringidos a los endpoints `config_dump`/`ndsz`/`edsz` y solo a proxies del mismo namespace.
  Se puede deshabilitar con `ENABLE_DEBUG_ENDPOINT_AUTH=false` si es necesario por compatibilidad.

- **Corregida** la validación de anotaciones de recursos para rechazar caracteres de nueva línea y de control que podrían inyectar contenedores en las especificaciones de pods mediante la representación de plantillas.
  ([Issue #58889](https://github.com/istio/istio/issues/58889))

## Telemetría

- **Obsoleta** la anotación `sidecar.istio.io/statsCompression`, que es reemplazada por la opción `statsCompression` de `proxyConfig`. Las sobreescrituras por pod siguen siendo posibles mediante la anotación `proxy.istio.io/config`.
  ([Issue #48051](https://github.com/istio/istio/issues/48051))

- **Añadida** la opción `statsCompression` en `proxyConfig` para permitir la configuración global de la compresión HTTP para el endpoint de estadísticas de Envoy que expone sus métricas. Está habilitada por defecto, ofreciendo `brotli`, `gzip` y `zstd` según el `Accept-Header` enviado por el cliente.
  ([Issue #48051](https://github.com/istio/istio/issues/48051))

- **Añadida** la identificación de workload de origen y destino a las trazas del waypoint proxy.
  Los waypoint proxies ahora incluyen `istio.source_workload`, `istio.source_namespace`, `istio.destination_workload`, `istio.destination_namespace` y
  otras etiquetas del peer de origen en los spans de traza, equiparando las capacidades de observabilidad de los proxies sidecar.
  ([Issue #58348](https://github.com/istio/istio/issues/58348))

- **Añadido** soporte para la etiqueta personalizada de tipo `Formatter` en la API de Telemetría.

- **Añadida** la métrica gauge `istiod_remote_cluster_sync_status` a Pilot para rastrear el estado de sincronización de los clústeres remotos.

- **Añadidas** las etiquetas de span de waypoint `istio.downstream.workload`, `istio.downstream.namespace`, `istio.upstream.workload`
  e `istio.upstream.namespace` para el workload y namespace upstream y downstream.

- **Añadidos** los campos `timeout` y `headers` a `ZipkinTracingProvider` en los `extensionProviders` de `MeshConfig`.
  El campo `timeout` configura el tiempo de espera de la solicitud HTTP al enviar spans al colector Zipkin,
  proporcionando un mejor control sobre la fiabilidad de la exportación de trazas. El campo `headers` permite incluir cabeceras HTTP personalizadas para casos de uso de autenticación, autorización y metadatos personalizados. Las cabeceras admiten tanto valores directos como referencias a variables de entorno para la gestión segura de credenciales.
 ([Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/v3/zipkin.proto)) ([referencia](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider-ZipkinTracingProvider)) ([uso](/docs/tasks/observability/distributed-tracing/))

- **Corregido** un problema que causaba que las métricas se reportaran con etiquetas desconocidas en despliegues ambient multi-red incluso
  cuando el descubrimiento de metadatos de peers basado en baggage estaba habilitado configurando la variable de entorno `AMBIENT_ENABLE_BAGGAGE`
  a `true` para pilot.
  ([Issue #58794](https://github.com/istio/istio/issues/58794)),([Issue #58476](https://github.com/istio/istio/issues/58476))

## Instalación

- **Actualizado** `istiod` para establecer `GOMEMLIMIT` al 90% del límite de memoria (anteriormente 100%) para reducir el riesgo de fallos por OOM.
  Esto ahora se gestiona automáticamente mediante la librería `automemlimit`. Los usuarios pueden sobreescribir esto configurando la variable de entorno `GOMEMLIMIT`
  directamente, o ajustar la proporción usando la variable de entorno `AUTOMEMLIMIT` (por ejemplo, `AUTOMEMLIMIT=0.85` para 85%).

- **Actualizado** el complemento de Kiali a la versión `v2.21.0`.

- **Añadido** soporte para filtrar los recursos que Pilot observará, basándose en la variable de entorno `PILOT_IGNORE_RESOURCES`.

  Esta variable es una lista separada por comas de recursos y prefijos que el observador de CRDs de Istio debe ignorar.
  Si hay necesidad de incluir explícitamente un recurso, incluso cuando está en la lista de ignorados, esto se puede hacer
  usando la variable `PILOT_INCLUDE_RESOURCES`.

  Esta función permite a los administradores desplegar Istio como un controlador solo de Gateway API, ignorando los recursos de la mesh,
  o desplegar Istio con soporte únicamente para `HTTPRoute` de Gateway API (por ejemplo, soporte GAMMA).
  ([Issue #58425](https://github.com/istio/istio/issues/58425))

- **Añadido** soporte para personalizar el intervalo de vaciado de archivos de Envoy y las configuraciones de búfer en `ProxyConfig`.
  ([Issue #58545](https://github.com/istio/istio/issues/58545))

- **Añadidos** mecanismos de seguridad al controlador de despliegue de gateway para validar tipos de objetos, nombres y namespaces,
  para evitar la creación de recursos de Kubernetes arbitrarios mediante inyección de plantillas.
  ([Issue #58891](https://github.com/istio/istio/issues/58891))

- **Añadida** una configuración `values.pilot.crlConfigMapName` que permite configurar el nombre del `ConfigMap` que istiod usa para propagar su Lista de Revocación de Certificados (CRL) en el clúster. Esto permite ejecutar múltiples control planes con namespaces solapados en el mismo clúster.

- **Añadido** soporte para configurar `terminationGracePeriodSeconds` en el pod de istio-cni, y actualizado el valor predeterminado de 5 segundos a 30 segundos.
  ([Issue #58572](https://github.com/istio/istio/issues/58572))

- **Corregido** un problema donde el comando `iptables` no esperaba a adquirir un bloqueo en `/run/xtables.lock`,
  causando algunos errores engañosos en los logs.
  ([Issue #58507](https://github.com/istio/istio/issues/58507))

- **Corregido** un problema donde el `DaemonSet` de istio-cni trataba los cambios de `nodeAffinity` como actualizaciones,
  haciendo que la configuración CNI quedara incorrectamente en su lugar cuando un nodo ya no coincidía con las reglas de `nodeAffinity` del `DaemonSet`.
  ([Issue #58768](https://github.com/istio/istio/issues/58768))

- **Corregido** el esquema de valores del chart Helm de `istio-gateway` para permitir el campo `enabled` de nivel superior.
  ([Issue #58277](https://github.com/istio/istio/issues/58277))

- **Eliminados** manifiestos obsoletos del chart Helm `base`. Consulta las Notas de Actualización para más información.

## istioctl

- **Añadido** un flag `--wait` al comando `istioctl waypoint status` para especificar si se debe esperar a que el waypoint esté listo (el valor predeterminado es `true`).

  Especificar este flag con `--wait=false` no esperará a que el waypoint esté listo, y mostrará directamente el estado del waypoint.
  ([Issue #57075](https://github.com/istio/istio/issues/57075))

- **Añadida** la impresión de cabeceras a los comandos `istioctl ztunnel-config all` e `istioctl proxy-config all`.

- **Añadido** el flag `--all-namespaces` al comando `istioctl waypoint status` para mostrar el estado de los waypoints en todos los namespaces.

- **Añadido** soporte para especificar el puerto de administración del proxy en `istioctl ztunnel-config`.

- **Corregidos** errores de búsqueda de funciones de traducción para MeshConfig y MeshNetworks en istioctl.
  ([Issue #57967](https://github.com/istio/istio/issues/57967))
