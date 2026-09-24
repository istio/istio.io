---
title: Notas de cambios de Istio 1.31.0
linktitle: 1.31.0
subtitle: Versión Principal
description: Notas de la versión Istio 1.31.0.
publishdate: 2026-08-31
release: 1.31.0
weight: 10
aliases:
    - /news/announcing-1.31.0
---

## Gestión del tráfico

- **Mejorado** el registro cuando un CRD de Gateway API instalado en el clúster está por debajo de la versión mínima
  requerida por esta versión de Istio. El mensaje ahora se registra al nivel `warn` y explica que los recursos de ese
  tipo no serán procesados hasta que los CRDs se actualicen. Anteriormente, se registraba al nivel `info` y era fácil
  de perder, lo que dificultaba el diagnóstico de fallos en TLS passthrough tras actualizar a 1.30 con CRDs obsoletos.

- **Mejorada** la escalabilidad de istiod en modo ambient al limitar los pushes XDS por cambios en `Address` de
  workload/servicio solo a los waypoints afectados, en lugar de enviarlos a todos los waypoints y proxies.
  Se puede deshabilitar con `AMBIENT_SCOPED_ADDRESS_PUSHES=false`.

- **Añadido** soporte para un nombre de taint personalizado para el controlador pilot de eliminación de taints de nodo
  mediante la variable de entorno `PILOT_NODE_UNTAINT_CONTROLLERS_TAINT_NAME`. El valor por defecto es
  `cni.istio.io/not-ready`.
  ([Issue #57844](https://github.com/istio/istio/issues/57844))

- **Añadido** soporte para excluir la configuración de política de Istio cuando la anotación
  `istio.io/ignore-policy-attachment` se establece en `true` en un objeto `BackendTLSPolicy` o
  `XBackendTrafficPolicy`. Esto permite evitar que políticas específicas se traduzcan a configuración de Istio cuando
  la política está destinada a un controlador de gateway diferente.

  Ejemplo de uso:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: BackendTLSPolicy
metadata:
annotations:
  istio.io/ignore-policy-attachment: "true"
{{< /text >}}

  ([Issue #60122](https://github.com/istio/istio/issues/60122))

- **Añadido** soporte para excluir namespaces y hosts del campo `hosts` de un listener de egress de `Sidecar` usando
  un prefijo `~` en el namespace. Las entradas sin prefijo se importan como antes, y las entradas con prefijo `~` se
  sustraen de ellas: `~ns1/*` excluye todos los hosts en `ns1`, y `~/foo.com` excluye `foo.com` de todos los
  namespaces. Esto permite que las meshes grandes importen todo excepto unos pocos namespaces (p.ej. `*/*` más
  `~ns1/*`) sin enumerar una larga lista de permisos.
  ([Issue #60139](https://github.com/istio/istio/issues/60139))

- **Añadida** una verificación de inicialización que comprueba que el binario `nft` incluido admite salida JSON. El
  backend nftables nativo requiere JSON para leer la configuración durante la eliminación de pods. En hosts cuyo
  binario `nft` no admite JSON, esas llamadas fallan con `Error: JSON support not compiled-in` en cada eliminación, y
  el agente CNI reintenta indefinidamente. La nueva verificación detecta este error al inicio y vuelve al backend
  `iptables`.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Añadido** el campo `prefix_rewrite` a `HTTPRedirect`, que habilita la reescritura de rutas con conciencia de
  prefijo en reglas de redirección. Esto permite eliminar o reemplazar el prefijo de ruta coincidente al redirigir,
  p.ej. redirigir `example.com/foo/bar` a `foo.example.com/bar`.
  ([Issue #47500](https://github.com/istio/istio/issues/47500)),([Issue #47777](https://github.com/istio/istio/issues/47777)),([Issue #52521](https://github.com/istio/istio/issues/52521))

- **Añadido** el campo `budget_interval` a la API `RetryBudget` de `TrafficPolicy` para configurar el intervalo con
  el que se consideran las solicitudes al calcular el presupuesto de reintento. El valor por defecto, 0ms, conserva el
  comportamiento existente de considerar solo las solicitudes en vuelo.
  ([Issue #60389](https://github.com/istio/istio/issues/60389))

- **Añadido** soporte para canaries de waypoint con peso en modo ambient. Un servicio (o namespace) ahora puede
  referenciar un waypoint primario y uno canary mediante las etiquetas `istio.io/use-waypoint-canary` y
  `istio.io/use-waypoint-canary-namespace`, con la anotación `istio.io/use-waypoint-canary-weight` dirigiendo un
  porcentaje configurable de las conexiones en la mesh del servicio (y, con `istio.io/ingress-use-waypoint`, las
  solicitudes de ingress) al waypoint canary sin cambios en el cliente.
  ([Issue #60801](https://github.com/istio/istio/issues/60801))

- **Añadida** la opción `meshConfig.serviceEntryVisibility`, que permite a un administrador de la mesh controlar la
  visibilidad de los recursos `ServiceEntry`. El modo ambient (ztunnel y waypoints) impone la visibilidad por defecto;
  los sidecars clásicos también la respetan cuando se establece `applyToSidecars`. La funcionalidad es inactiva si no
  se configura, por lo que las meshes existentes no se ven afectadas por defecto.
  ([Issue #60870](https://github.com/istio/istio/issues/60870))

- **Añadida** la `GatewayClass` `istio-agentgateway-waypoint` para desplegar agentgateway como waypoint.

- **Añadido** el modo de política de tráfico de salida `ALLOW_ANY_DYNAMIC_DNS`. Cuando se establece en
  `meshConfig.outboundTrafficPolicy.mode`, las solicitudes HTTP en texto plano a destinos desconocidos se reenvían
  mediante el Dynamic Forward Proxy de Envoy, resolviendo nombres de host del encabezado `Host` en tiempo de
  solicitud. El tráfico no HTTP (TLS y TCP) sigue usando `PassthroughCluster`. Solo aplica a proxies sidecar. No
  compatible con el CRD `Sidecar`. La originación TLS upstream opcional se puede configurar mediante
  `meshConfig.outboundTrafficPolicy.tls`.

- **Añadido** soporte para `connectionSettings` en `ProxyConfig`, que permite configurar límites de buffer de
  listener, timeouts HTTP, ajustes HTTP/2 y normalización de rutas/cabeceras. El nuevo perfil `EDGE` aplica valores
  predeterminados de proxy de borde de Envoy orientados a los proxies gateway.

- **Añadida** la nueva operación de parche `MERGE_AND_REPLACE_LIST` a `EnvoyFilter`. Se comporta como `MERGE`,
  excepto que los campos repetidos (de lista) presentes en el parche reemplazan completamente la lista
  correspondiente en la configuración generada en lugar de añadirse. Aplica a los destinos de parche `CLUSTER`,
  `LISTENER`, `FILTER_CHAIN`, `ROUTE_CONFIGURATION`, `VIRTUAL_HOST` y `HTTP_ROUTE`. Las listas anidadas dentro de
  configuraciones de filtros tipadas como `Any` (filtros HTTP, de red, de listener y sockets de transporte) no se
  ven afectadas y siguen la semántica `MERGE`.

- **Añadida** la implementación de la funcionalidad `AllowInsecureFallback` de Gateway API en la lógica de validación
  de certificados de cliente. Esta funcionalidad permite que un gateway solicite un certificado de cliente e intente
  validarlo, pero si el cliente no presenta un certificado o no es válido, el gateway permite igualmente la conexión.
  Por defecto, Istio rellena la cabecera HTTP `x-forwarded-client-cert`, por lo que cuando `AllowInsecureFallback`
  está habilitado, el backend puede verificar el certificado en lugar del gateway.
  ([Issue #60018](https://github.com/istio/istio/issues/60018))

- **Añadido** soporte para configurar los ajustes de keepalive PING de HTTP/2 en conexiones upstream mediante
  `DestinationRule`.
  ([Issue #55640](https://github.com/istio/istio/issues/55640))

- **Añadida** la opción `defaultTrafficPolicy` a `MeshConfig`, un `connectionPool` y `outlierDetection` base a nivel
  de mesh que los clústeres de salida heredan. Una `DestinationRule` que establezca uno de estos bloques anula la
  base para ese bloque; un bloque que `DestinationRule` deja sin establecer ahora hereda la base de la mesh en lugar
  de los valores predeterminados integrados de Istio. Cuando no se configura ninguna base, el comportamiento no
  cambia. El `connectionPool` base también se aplica a los clústeres entrantes y al clúster de passthrough.

- **Añadido** soporte para el balanceo de carga por zona de Envoy mediante el nuevo campo `zoneAwareLbSetting` en
  `DestinationRule.TrafficPolicy.LoadBalancerSettings` y `MeshConfig`. Cuando está habilitado, Envoy enruta
  automáticamente el tráfico a endpoints en la misma zona de disponibilidad que el proxy downstream, derivando a
  otras zonas solo cuando la capacidad local es insuficiente. Esto difiere del `localityLbSetting` existente en que
  el enrutamiento por zona es gestionado automáticamente por Envoy usando la distribución de zona del proxy, en lugar
  de porcentajes estáticos. El orden de failover entre regiones se puede configurar mediante el campo `failover`, y
  los niveles de prioridad basados en etiquetas se pueden añadir encima mediante `failoverPriority`. El balanceo de
  carga por zona requiere `ISTIO_META_ENABLE_SELF_DISCOVERY: "true"` en
  `meshConfig.defaultConfig.proxyMetadata` para inyectar el `local_cluster` de auto-descubrimiento en los bootstraps
  del sidecar. Solo se admite en modo sidecar, no en modo ambient.
  ([referencia](/docs/reference/config/networking/destination-rule/#ZoneAwareLoadBalancerSetting))([referencia](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig))

- **Habilitado** el envío de endpoints no saludables por defecto a menos que `OutlierDetection.minHealthPercent` esté
  configurado. Se puede deshabilitar estableciendo `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` en `false`.

- **Corregido** el manejo de Gateway API para implementar la resolución de conflictos de `BackendTLSPolicy`.
  ([Issue #57817](https://github.com/istio/istio/issues/57817))

- **Corregido** un error donde los clústeres entrantes no aparecían para proxies que se reconectaban a una nueva
  instancia de istiod (p.ej. durante reinicios continuos) cuando el pod aún no estaba presente en la caché del kube
  informer. Las etiquetas del workload ahora se rellenan antes de calcular los destinos de servicio, por lo que la
  ruta de fallback de metadatos en `GetProxyServiceTargets` coincide correctamente con los servicios en lugar de
  devolver una lista vacía.
  ([Issue #58125](https://github.com/istio/istio/issues/58125))

- **Corregido** un problema donde, cuando `PILOT_ENABLE_QUIC_LISTENERS` está habilitado, los recursos `Service` de
  Gateway API generados no escuchaban en el puerto UDP correspondiente para cada listener HTTPS.
  ([Issue #58247](https://github.com/istio/istio/issues/58247))

- **Corregido** un problema donde los listeners HTTPS definidos mediante `ListenerSet` no entregaban certificados TLS
  cuando el Gateway padre usaba despliegue manual.
  ([Issue #59535](https://github.com/istio/istio/issues/59535))

- **Corregido** un problema donde los filtros de `HTTPRoute` y `GRPCRoute` con valores de cabecera no válidos se
  eliminaban silenciosamente de la configuración de Envoy en lugar de reportar un estado `InvalidFilter`.
  ([Issue #59933](https://github.com/istio/istio/issues/59933))

- **Corregido** un breve corte de tráfico al cambiar la etiqueta `istio.io/rev` en un Kubernetes Gateway (o
  `ListenerSet`). El control plane propietario anterior ya no descarta el recurso ni envía configuración xDS vacía a
  los pods de gateway que siguen ejecutándose en la revisión anterior. Las escrituras de estado para revisiones no
  propietarias siguen suprimidas, por lo que las revisiones no alternan el estado de las demás.
  ([Issue #59959](https://github.com/istio/istio/issues/59959))

- **Corregido** el modo ambient multi-red para que ahora enrute al waypoint cuando el ingress de una red llama a un
  servicio en una red diferente, y solo si el `Service` está configurado con `istio.io/ingress-use-waypoint`.

- **Corregido** un problema donde la configuración del listener del waypoint en clústeres IPv6 contenía un
  `IPMatcher.RangeMatcher` con el campo `ranges` vacío cuando había un Service headless (`spec.clusterIP: None`) en
  el alcance del waypoint. Esto ocurría porque el marcador `constants.UnspecifiedIP` (codificado en IPv4) usado para
  la `DefaultAddress` de los servicios headless es filtrado para proxies solo-IPv6 por
  `FilterAddressesByIPFamily`. Envoy 1.38 valida estrictamente la regla `repeated.min_items=1` del proto en
  `IPMatcher.RangeMatcher.ranges` y rechaza el push LDS. El constructor del listener del waypoint ahora omite la
  entrada `IPRangeMatcher` cuando no hay direcciones que incluir. Los clústeres IPv4 no se ven afectados.
  ([Issue #60310](https://github.com/istio/istio/issues/60310))

- **Corregido** un problema donde el balanceo de carga `consistentHash` en `DestinationRule` no enviaba tráfico a
  los nuevos endpoints tras escalar, debido a una regresión de Envoy (`envoyproxy/envoy#45212`) donde el anillo
  RING_HASH no se reconstruía al cambiar endpoints durante actualizaciones por lotes.
  ([Issue #60312](https://github.com/istio/istio/issues/60312))

- **Corregido** un panic fatal de `concurrent map writes` en el agente `istio-cni` cuando dos pods se añadían a la
  ambient mesh en el mismo nodo al mismo tiempo.
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **Corregido** el caso donde una `DestinationRule` y una política de backend de Gateway API (`BackendTLSPolicy` o
  `XBackendTrafficPolicy`) apuntan al mismo host: ahora los campos de `DestinationRule` tienen precedencia y la
  política de backend solo rellena los campos que `DestinationRule` deja sin establecer, independientemente de cuál
  se creó primero.
  ([Issue #60358](https://github.com/istio/istio/issues/60358))

- **Corregido** un error en modo ambient donde un Service que combinaba `publishNotReadyAddresses: true` con una
  distribución de tráfico `PreferSameZone` o `PreferSameNode` hacía que ztunnel recibiera
  `healthPolicy: AllowAll` para todos los demás Services que usaban el mismo preset de distribución de tráfico, lo
  que provocaba que el tráfico se enrutara a endpoints no listos en todo el clúster.
  ([Issue #60422](https://github.com/istio/istio/issues/60422))

- **Corregido** un problema donde el vaciado del proxy podía causar un panic en lugar de devolver un error cuando el
  endpoint de administración de Envoy no estaba disponible.

- **Corregido** un problema donde los namespaces adicionales en `meshConfig.defaultServiceExportTo` y
  `meshConfig.defaultVirtualServiceExportTo` no se respetaban cuando el valor predeterminado incluía el namespace
  actual como `.`.
  ([Issue #60560](https://github.com/istio/istio/issues/60560))

- **Corregido** un error donde eliminar un listener de un `ListenerSet` dejaba una entrada huérfana en
  `status.listeners` del recurso indefinidamente. La entrada obsoleta hacía que `status.listeners` fuera más largo
  que `spec.listeners` y, tras varios ciclos de añadir/eliminar listeners, bloqueaba el `observedGeneration` del
  `ListenerSet` de forma que los cambios posteriores en la spec ya no se reflejaban en su estado.
  `reportListenerSetStatus` ahora elimina las entradas de estado de listeners que ya no están presentes en la spec,
  igualando el comportamiento existente para los recursos `Gateway`.
  ([Issue #60578](https://github.com/istio/istio/issues/60578))

- **Corregido** que la validación de `DestinationRule` rechazara incorrectamente valores de agresividad de
  calentamiento entre 0 y 1.
  ([Issue #3395](https://github.com/istio/api/issues/3395)),([Issue #55153](https://github.com/istio/istio/issues/55153))

- **Corregido** un error donde istiod no detectaba los secrets actualizados de clústeres remotos (p.ej. durante la
  rotación de credenciales/tokens) hasta reiniciarse. El nuevo registro de clústeres podía quedarse bloqueado
  esperando sincronizarse, dejando el registro de servicios obsoleto para el clúster remoto afectado.
  ([Issue #60612](https://github.com/istio/istio/issues/60612))

- **Corregido** un problema introducido en Istio 1.30 donde los cambios solo en metadatos de recursos
  `VirtualService` (p.ej. anotaciones de Helm, etiquetas de Argo CD o
  `kubectl.kubernetes.io/last-applied-configuration`) disparaban pushes XDS innecesarios a todos los proxies. Esto
  podía causar un aumento significativo en el uso de CPU del control plane y la latencia de push en clústeres con
  muchos recursos `VirtualService` gestionados por herramientas GitOps. La corrección restaura el comportamiento
  anterior a 1.30, donde solo los cambios en la spec o en etiquetas/anotaciones de `istio.io` disparan un push.
  ([Issue #60629](https://github.com/istio/istio/issues/60629))

- **Corregidos** los pushes duplicados y excesivos al usar recursos `WasmPlugin` debido a las conversiones de
  `TrafficExtension`.

- **Corregido** un deadlock donde el pod del agente de nodo `istio-cni` podía fallar al iniciar (por ejemplo tras un
  reinicio del nodo) porque el plugin CNI solo omitía la creación del cliente kube para su propio pod de agente
  cuando el modo ambient estaba habilitado. La verificación preventiva ahora también se ejecuta en modo sidecar, por
  lo que el pod de agente ya no se bloquea en un kubeconfig que aún no ha escrito.
  ([Issue #60668](https://github.com/istio/istio/issues/60668))

- **Corregidos** los reintentos HTTP predeterminados para rutas entrantes de waypoints. El ajuste
  `meshConfig.defaultHttpRetryPolicy` ahora se aplica a los servicios locales asociados a waypoints.
  ([Issue #60682](https://github.com/istio/istio/issues/60682))

- **Corregido** un problema donde `EXIT_ON_ZERO_ACTIVE_CONNECTIONS` nunca se activaba en los ambient ingress
  gateways y waypoints porque el bucle de vaciado del pilot-agent contaba conexiones en proceso en los listeners
  internos HBONE de Envoy (`connect_originate`, `connect_terminate`, `main_internal`, etc.), impidiendo que el
  recuento de conexiones activas llegara a cero y obligando al proxy a esperar hasta
  `terminationGracePeriodSeconds`.
  ([Issue #60728](https://github.com/istio/istio/issues/60728))

- **Corregido** un problema donde la etiqueta `service.istio.io/canonical-name` podía terminar con un `.` o `_` no
  válido al truncarse a 63 caracteres en la plantilla de inyección.

- **Corregido** un problema donde un `HTTPRoute` con `backendRefs` vacío u omitido devolvía un código de estado HTTP
  404 en lugar de 500. Esto coincide con el comportamiento impuesto por la prueba de conformidad
  `HTTPRouteNoBackendRefs` de Gateway API, introducida en v1.6.0.

- **Corregido** un problema donde la capacidad HBONE anunciada no se propagaba a los recursos `WorkloadEntry`
  auto-registrados para workloads que no son de Kubernetes.

- **Corregido** un problema donde la condición `Accepted` en un `Gateway` no se establecía en `False` al referenciar
  un `parametersRef` no válido o inexistente. Esto coincide con el comportamiento impuesto por la prueba de
  conformidad `GatewayInvalidParametersRef` de Gateway API, introducida en v1.6.0.

- **Corregido** el tráfico entre redes a través del gateway east-west que era bloqueado por un filtro RBAC de
  denegación total espurio cuando el servicio destino tenía recursos `AuthorizationPolicy` de capa 7.
  ([Issue #60806](https://github.com/istio/istio/issues/60806))

- **Corregido** un error donde el gateway de red de un clúster remoto podía desaparecer del enrutamiento entre redes
  tras la rotación de credenciales y no recuperarse hasta reiniciar istiod. El intercambio de registro en caliente
  ahora reconecta el nuevo registro a los controladores del controlador agregado para que sus futuros eventos de
  gateway y servicio se propaguen, y recarga los gateways una vez para detectar los descubiertos durante la
  sincronización previa al intercambio.
  ([Issue #60920](https://github.com/istio/istio/issues/60920))

- **Corregido** un problema en despliegues multiclúster donde la rotación del `istio-remote-secret` de un clúster
  remoto podía eliminar permanentemente los fragmentos de endpoints para servicios con endpoints estables en ese
  clúster, haciéndolos inalcanzables entre clústeres hasta reiniciar istiod.
  ([Issue #61043](https://github.com/istio/istio/issues/61043))

- **Corregido** un problema donde el balanceo de carga `consistentHash` en una `DestinationRule` no funcionaba para
  servicios enrutados a través de un proxy waypoint en modo ambient cuando no había ningún `VirtualService`. El
  clúster de Envoy recibía correctamente `lb_policy: RING_HASH` pero la ruta entrante no tenía `hash_policy`, lo
  que hacía que Envoy volviera a la selección aleatoria de backend y rompía las sesiones sticky. Anteriormente se
  requería un `VirtualService` de passthrough sin operación como solución.
  ([Issue #61045](https://github.com/istio/istio/issues/61045))

- **Corregida** una condición de carrera en el inicio de istiod donde el probe de disponibilidad podía reportar
  listo antes de que el servidor dedicado de webhooks de inyección y validación (`--httpsAddr`, por defecto `:15017`)
  estuviera aceptando conexiones, causando timeouts intermitentes de `failed calling webhook` al crear recursos
  inmediatamente después de que istiod estuviera listo. No afecta a los despliegues donde los webhooks comparten el
  servidor HTTP principal (con `--httpsAddr` vacío).
  ([Issue #61049](https://github.com/istio/istio/issues/61049))

- **Corregido** un problema donde los ingress gateways evitaban los proxies waypoint para servicios multi-clúster
  cuando los workloads remotos estaban en una red diferente, lo que provocaba que las políticas de autorización no
  se aplicaran.
  ([Issue #61092](https://github.com/istio/istio/issues/61092))

- **Corregido** un problema donde los Deployments de proxy gateway podían fallar permanentemente al crearse durante
  el inicio de istiod.
  ([Issue #61095](https://github.com/istio/istio/issues/61095))

- **Corregido** un problema donde un pod seleccionado por un `workloadSelector` de `ServiceEntry` podía iniciar sin
  ese servicio en la configuración entrante de su sidecar. El tráfico al puerto no se manejaba con el protocolo
  declarado en `ServiceEntry`, y `PeerAuthentication` a nivel de puerto no se aplicaba. El pod no se recuperaba
  solo; solo reiniciando istiod se corregía.
  ([Issue #61157](https://github.com/istio/istio/issues/61157))

- **Corregido** un problema donde `istio-cni` consideraba los pods `hostNetwork` elegibles para la incorporación al
  modo ambient.
  ([Issue #61168](https://github.com/istio/istio/issues/61168))

- **Corregido** un problema donde, debido a varios fallos, pilot ignoraba los recursos `ListenerSet` y las rutas
  asociadas a ellos al generar la configuración para agentgateway. Pilot ya no filtra los recursos `ListenerSet` ni
  sus rutas asociadas, permitiendo que agentgateway en Istio maneje correctamente los recursos `ListenerSet`.

- **Corregido** el reporte de estado de `ListenerSet` cuando un `ListenerSet` no está permitido por el recurso
  `Gateway` padre para agentgateway. Cuando un `ListenerSet` no está permitido por el `Gateway` padre, el estado de
  la condición `Accepted` ahora se reporta como `False`, lo que antes no ocurría. Además, como la funcionalidad
  `ListenerSet` ya no es experimental desde Gateway API v1.5.0, ya no está protegida por el feature flag
  `PILOT_ENABLE_ALPHA_GATEWAY_API`.

- **Corregido** un problema donde un `Gateway` de agentgateway se conectaba a backends sidecar-inyectados (mesh)
  usando texto plano en lugar de mTLS de Istio. Anteriormente, el TCP crudo enrutado a un backend de la mesh
  (mediante `TCPRoute`, o `TLSRoute` en modo Terminate) podía bloquearse en protocolos server-first —donde el
  backend habla primero, como SMTP o MySQL— y los backends que imponían mTLS `STRICT` eran inalcanzables.

- **Corregida** una fuga de memoria y goroutines en el modo ambient multi-clúster de Istiod donde las colecciones de
  localidad de nodo por clúster tenían el alcance de la vida útil del proceso en lugar de la del clúster, por lo
  que nunca se destruían al eliminar un clúster remoto.
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Corregido** un error en el modo ambient multi-clúster de Istiod donde las colecciones agregadas (local + remoto)
  podían reportarse como sincronizadas antes de que los clústeres remotos hubieran sido descubiertos y
  sincronizados. Como resultado, Istiod podía comenzar a servir solo con datos del clúster local, omitiendo
  temporalmente workloads, servicios y endpoints de clústeres remotos al inicio. Las colecciones agregadas ahora
  esperan a que el controlador multi-clúster y las colecciones de cada clúster remoto se sincronicen antes de
  marcarse como listas.

- **Corregido** un problema donde un pod incorporado al modo ambient podía quedar fuera del ipset de sondas de salud
  del host tras un reinicio del nodo o del kubelet, haciendo que las sondas del kubelet fueran redirigidas a ztunnel
  y rechazadas hasta que el agente de nodo `istio-cni` se reiniciara. Al inicio, el agente de nodo podía expulsar
  del ipset pods que seguían incorporados cuando su IP aún no era observable, y ahora reafirma la pertenencia al
  ipset de sondas para los pods incorporados durante la reconciliación.

- **Corregida** una fuga de descriptores de archivo en el agente de nodo `istio-cni`: cuando el análisis del procfs
  encontraba más de un network namespace para el mismo pod, el descriptor de archivo netns del candidato descartado
  se abandonaba sin cerrarse, fijando el namespace en el kernel hasta la recolección de basura.

- **Corregido** un deadlock en el agente de nodo CNI de ambient donde un evento de eliminación de pod concurrente
  con una (re)conexión de ztunnel podía bloquear permanentemente el servidor ZDS.
  ([Issue #1674](https://github.com/istio/ztunnel/issues/1674))

- **Corregido** un problema donde el modo mTLS del endpoint no se derivaba de la política de tráfico de nivel
  superior de `DestinationRule` cuando un subset de destino no especificaba un modo TLS para el puerto. La política
  de tráfico del subset ahora vuelve correctamente al ajuste TLS del nivel de `DestinationRule`.

- **Corregido** el reporte de estado de referencias de certificados en recursos `Gateway` para cumplir con la
  especificación de Gateway API v1.5.0. Cambia el estado del `Gateway` para reportar condiciones de tipo
  `ResolvedRefs`, y añade detalles adicionales a la condición `Accepted` cuando falla por certificados no válidos o
  inexistentes.

- **Corregida** la condición `Accepted` en un Kubernetes `Gateway` para reflejar la validez de sus listeners.
  Cuando uno o más listeners no son aceptados (por ejemplo, un protocolo de listener no compatible), el `Gateway`
  ahora reporta el motivo `ListenersNotValid`, y solo se establece en `Accepted=False` cuando ninguno de sus
  listeners es aceptado. Anteriormente el `Gateway` siempre se reportaba como `Accepted` independientemente de sus
  listeners.

- **Corregido** un problema donde los clientes xDS de gRPC sin proxy podían recibir respuestas
  `RouteConfiguration` de RDS demasiado amplias de Istiod.

- **Corregido** un error donde se creaba incorrectamente un listener interno cuando el listener era de tipo HTTPS o
  TLS pero no tenía sección TLS definida. Una versión posterior de Gateway API
  [evitará](https://github.com/kubernetes-sigs/gateway-api/pull/4788) que esta combinación de entradas llegue a un
  controlador.
  ([Issue #60562](https://github.com/istio/istio/issues/60562))

- **Corregida** la generación de configuración para sidecars anteriores a 1.29.2.

- **Corregido** un panic de istiod al procesar un `VirtualService` con rutas TCP o TLS sin destinos, lo que podía
  ocurrir cuando el webhook de validación no está instalado (p.ej. despliegues sin revisión por defecto).
  ([Issue #60110](https://github.com/istio/istio/issues/60110))

- **Corregidas** fugas de goroutines y memoria en istiod en modo ambient multi-clúster cuando se eliminan o
  actualizan clústeres remotos. Las colecciones internas construidas para cada clúster remoto no liberaban los
  controladores de eventos registrados en sus entradas al destruirse, causando que goroutines y memoria se
  acumularan con el tiempo al eliminar o reconfigurar clústeres.
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Corregida** una fuga de memoria en el framework del controlador `krt` donde cambiar la clave usada en un filtro
  `Fetch` (por ejemplo, reetiquetando un pod para apuntar a un waypoint diferente) dejaba entradas de índice
  inverso obsoletas que nunca se limpiaban. Con el tiempo esto podía aumentar el uso de memoria y causar
  recomputaciones innecesarias.

- **Corregida** una fuga de goroutine en la elección de líder de istiod donde cada ciclo de elección (liderazgo
  perdido y readquirido) filtraba un goroutine hasta la salida del proceso.
  ([Issue #60843](https://github.com/istio/istio/issues/60843))

- **Corregido** el reporte de estado de ListenerSet para que un ListenerSet sin listeners válidos ahora reporte las
  condiciones `Accepted` y `Programmed` como `False` con motivo `ListenersNotValid`. Anteriormente las condiciones
  a nivel de ListenerSet podían permanecer en `True` incluso cuando ninguno de sus listeners era utilizable.

- **Corregido** un deadlock en el `ClusterStore` multiclúster donde `AllReady` podía adquirir recursivamente el
  `RWMutex` del almacén para lectura mediante `triggerRecomputeOnSync` -> `GetByID` mientras un escritor esperaba,
  bloqueando lecturas y escrituras posteriores contra el almacén.

- **Corregido** que el modo ambient multi-clúster sirviera un snapshot obsoleto de un clúster remoto tras rotar sus
  credenciales. Las colecciones por clúster se almacenaban en caché solo por ID de clúster, por lo que una
  actualización de secret con un nuevo kubeconfig seguía reutilizando las colecciones construidas para la generación
  anterior, cuyo cliente e informers se apagan una vez que la nueva sincroniza. Ahora se almacenan en caché por
  generación y se reconstruyen con el nuevo cliente.
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Corregida** una fuga de memoria en Istiod donde las entradas `needResync` para IPs de pods fallidos nunca se
  limpiaban.

- **Corregido** el enrutamiento de failover cuando la red está incluida. La red se considera preferida, pero no
  obligatoria, al determinar la prioridad de failover. Por ejemplo, `PreferSameZone` tiene el siguiente orden de
  prioridad: Network+Region+Zone, Network+Region, Network, Region+Zone, Zone y sin coincidencia.

- **Corregido** que los recursos `Service` de `Gateway` generados se rechazaran cuando dos nombres de listener se
  saneaban al mismo nombre de puerto de `Service` (nombres que difieren solo en puntos frente a guiones, o solo más
  allá del límite de 63 caracteres), lo que bloqueaba todos los puertos no publicados del `Gateway`. Los nombres de
  puerto que colisionan ahora se desambiguan con el número de puerto del listener.

- **Corregido** un error donde el agente de nodo `istio-cni` podía asociar un pod ambient con el network namespace
  de otro pod cuando un proceso de terceros estaba dentro de ese namespace durante un análisis, lo que podía causar
  que el tráfico se enrutara a través del proxy con la identidad incorrecta. El agente de nodo ahora verifica que un namespace tenga
  una de las IPs del pod antes de incorporarlo.
  ([Issue #61211](https://github.com/istio/istio/issues/61211))

- **Corregido** un error donde una reconexión de ztunnel (como el reciclaje periódico de conexión por
  `keepaliveMaxServerConnectionAge`) disparaba un push completo de workloads (WDS). Istiod ahora asigna a cada
  recurso WDS una versión basada en contenido y, cuando un cliente en reconexión reporta las versiones que ya tiene
  mediante `initial_resource_versions`, solo reenvía los recursos que cambiaron mientras el cliente estaba
  desconectado. Las versiones anteriores de ztunnel que no reportan versiones siguen recibiendo el conjunto
  completo.
  ([Issue #1966](https://github.com/istio/ztunnel/issues/1966))

- **Corregido** `zoneAwareLbSetting.enabled: false` para deshabilitar explícitamente el enrutamiento por zona
  intrínseco de Envoy emitiendo `routing_enabled: 0%`. Anteriormente, `enabled: false` no tenía efecto: Istio no
  emitía ningún `ZoneAwareLbConfig`, lo que hacía que Envoy volviera a su `routing_enabled: 100%` predeterminado,
  activando el enrutamiento por zona automáticamente cuando había un clúster local de auto-descubrimiento. Esto
  hacía que el despliegue gradual fuera inseguro, ya que los pods en un estado mixto (algunos con
  auto-descubrimiento, otros sin él) distribuían el tráfico de forma desigual.

- **Actualizada** la versión de `nftables` usada por las imágenes distroless de Istio. La versión de `nftables`
  estaba anclada anteriormente en 1.1.1 para evitar un error que podía causar el fallo de versiones más antiguas de
  `nftables` en nodos de K8s cuando Istio usaba una versión más nueva empaquetada en sus imágenes en el mismo nodo.

  Las principales distribuciones de Linux han sido informadas del problema y han publicado correcciones. Como
  resultado, Istio elimina el anclaje de versión de `nftables`. Se aconseja a los usuarios que actualicen el paquete
  `nftables` en sus nodos a la versión más reciente disponible para asegurarse de que la versión corregida está
  instalada.

  Si sigues experimentando fallos de `nftables` en tus nodos, vuelve a una versión más antigua de Istio y contacta
  con el proveedor del SO de tu nodo para solicitar que la corrección sea portada a tu versión del SO.
  ([Issue #58492](https://github.com/istio/istio/issues/58492))

- **Optimizada** la resolución de servicios de egress del sidecar: los listeners que importan solo hosts exactos
  (sin comodines) con namespace explícito ahora resuelven servicios mediante búsquedas directas en el índice de
  servicios en lugar de analizar todos los servicios visibles para el namespace, reduciendo el coste por listener de
  `O(services)` a `O(imported hosts)` y eliminando la asignación de la lista completa.
  ([Issue #60473](https://github.com/istio/istio/issues/60473))

## Seguridad

- **Añadida** la variable `PILOT_ENABLE_STRICT_GATEWAY_MERGING` para evitar la fusión entre namespaces de recursos
  `Gateway` de Istio con recursos `Gateway` de Gateway API administrados. Cuando está habilitada (el valor
  predeterminado), los CRDs `Gateway` de Istio de diferentes namespaces no se fusionan con los proxies `Gateway` de
  Gateway API administrados. Los recursos `Gateway` de Gateway API no administrados (despliegue manual) no se ven
  afectados. Establece `PILOT_ENABLE_STRICT_GATEWAY_MERGING` en `false` para deshabilitar.

- **Añadidos** los campos `trustDomains` y `notTrustDomains` al `Source` en `AuthorizationPolicy`, que permiten
  coincidir o excluir solicitudes basándose en el dominio de confianza derivado del certificado de par.

- **Añadido** soporte para `fips-140-3` como nuevo valor de la variable de entorno `COMPLIANCE_POLICY`. Esto impone
  TLS 1.2 o 1.3 con suites de cifrado conformes con FIPS (ECDHE_[RSA|ECDSA]_WITH_AES_*_GCM_SHA* para TLS 1.2,
  AES-GCM para TLS 1.3) y restringe el acuerdo de clave a curvas P-256 o P-384. En el proxy Envoy, usa la política
  de cumplimiento nativa `FIPS_202205`. Los componentes Go (istiod, istio-agent) deben compilarse con Go 1.24+
  usando `GOFIPS140=v1.0.0` (o una versión validada posterior) para habilitar el módulo criptográfico nativo
  FIPS 140-3 de Go. La variable de entorno `GODEBUG=fips140=only` se inyecta automáticamente en tiempo de ejecución
  para sidecars, gateways y el control plane de istiod cuando `COMPLIANCE_POLICY` se configura mediante el valor
  Helm `env` (p.ej. `--set pilot.env.COMPLIANCE_POLICY=fips-140-3`). Nota: `GOEXPERIMENT=boringcrypto` (usado para
  FIPS 140-2) es incompatible con esta política y no debe usarse. BoringCrypto solo apunta a FIPS 140-2 y entra en
  conflicto con el módulo FIPS 140-3 nativo de Go.

- **Añadida** una nueva variable de entorno `PILOT_ENABLE_REMOTE_CREDENTIALS_CONTROLLER` (valor predeterminado
  `true`) que activa o desactiva los controladores de credenciales para clústeres remotos.

- **Corregida** la falta de recarga de certificados en el pilot-agent en la segunda y posteriores rotaciones de
  secrets de Kubernetes para certificados montados en archivos.
  ([Issue #59912](https://github.com/istio/istio/issues/59912))

- **Corregido** un problema donde `caCertificateRefs[].kind: Secret` en el mTLS frontend de Gateway API
  (`spec.tls.frontend.default.validation.caCertificateRefs`) era rechazado por SDS en tiempo de ejecución a pesar
  de una configuración `Gateway` válida, incluyendo referencias del mismo namespace y referencias entre namespaces
  permitidas por `ReferenceGrant`.
  ([Issue #60277](https://github.com/istio/istio/issues/60277))

- **Corregida** una brecha de validación en `EnvoyFilter` donde una expresión de coincidencia `proxyVersion` sin
  límite podía consumir excesiva memoria y CPU de istiod durante la compilación de expresiones regulares. La
  expresión de coincidencia está ahora limitada a 1024 caracteres.

  **Crédito**: Este problema fue reportado por Artem Cherezov ([cherez0ff](https://github.com/cherez0ff)).

- **Corregidos** los proveedores SDS externos configurados mediante `extensionProviders` para usar el hostname del
  servicio configurado como autoridad gRPC.

- **Corregido** el proveedor SDS externo para gateways para usar el nombre de credencial (tras eliminar el prefijo
  `sds://`) como nombre de recurso SDS en lugar del nombre del proveedor. Esto permite que múltiples gateways que
  usan el mismo proveedor SDS soliciten certificados diferentes. Para TLS `MUTUAL`, el nombre del recurso del
  certificado CA se deriva correctamente como `<credential-name>-cacert`. Cuando no se configura ni un socket UDS
  ni un proveedor de extensión SDS, el gateway ahora vuelve a obtener certificados mediante ADS (Kubernetes
  Secrets) en lugar de fallar silenciosamente.
  ([Issue #57080](https://github.com/istio/istio/issues/57080))

- **Corregido** un error donde istiod no recargaba su certificado raíz CA al rotar si el certificado se proporciona
  mediante archivos (por ejemplo, cuando se usa una CA externa como istio-csr).

- **Corregido** el generador XDS `api` (servicio de configuración MCP) para requerir una identidad de control plane
  verificada. Anteriormente, cualquier cliente que pudiera alcanzar el puerto XDS de istiod podía leer la
  configuración de Istio en todos los namespaces. Deshabilitar con `ENABLE_XDS_API_GENERATOR_AUTH=false` si es
  necesario por compatibilidad.

## Telemetría

- **Mejorado** el endpoint `/stats/prometheus` del pilot-agent para recopilar de forma concurrente múltiples
  destinos declarados por la anotación `prometheus.istio.io/scrape-targets` y fusionar la salida en el orden
  declarado. Los pods con un solo destino conservan la ruta de código de streaming existente byte a byte. Para pods
  con múltiples destinos, las respuestas OpenMetrics se reescriben para que la salida fusionada contenga
  exactamente un terminador `# EOF`. Las respuestas de métricas de cada destino están limitadas a 10 MiB para
  controlar la memoria del agente; las respuestas que superan este límite se descartan y se cuentan como fallos de
  scraping. Los fallos de scraping por destino no son bloqueantes e incrementan
  `istio_agent_scrape_failures_total{type="application"}`.
  ([Issue #59567](https://github.com/istio/istio/issues/59567))

- **Añadida** una nueva variable de entorno `PILOT_AGENT_MERGE_ENVOY_STATS` para controlar si el pilot-agent fusiona
  las estadísticas de Envoy en su endpoint de estadísticas. Establécela en `false` para deshabilitar la fusión de
  estadísticas de Envoy con las del agente.

- **Añadida** una nueva métrica, `istio_cni_plugin_requests_total`, al agente de nodo `istio-cni`. Cuenta las
  solicitudes de eventos de adición del plugin CNI manejadas por el agente de nodo, etiquetadas por `response_code`.
  ([Issue #60878](https://github.com/istio/istio/pull/60878))

- **Añadida** una nueva anotación de pod `prometheus.istio.io/scrape-targets` que permite declarar múltiples
  endpoints de métricas de aplicación por pod como una lista `port:path` separada por comas. Los destinos que
  colisionan con el puerto de estado del agente o cualquier puerto del data plane reservado por Istio se rechazan en
  el momento de la inyección con un error legible.
  ([Issue #59567](https://github.com/istio/istio/issues/59567))

- **Añadidas** dos nuevas variables de entorno opcionales, `ENVOY_SECURE_METRICS_PORT` y
  `ENVOY_SECURE_MERGED_METRICS_PORT`, que exponen endpoints de scraping de Prometheus protegidos con mTLS en cada
  proxy sidecar de Envoy. Cuando se establecen, el sidecar añade listeners de bootstrap estáticos en los puertos
  configurados que requieren mTLS, permitiendo a Prometheus recopilar métricas de forma segura sin depender de los
  controles de acceso a nivel de red del pod. Consulta el
  [RFC](https://docs.google.com/document/d/1BiBOrYU06x5xdsnU0YDlMGOV-iHjZ2m9UVcZ62wKAn8/edit?usp=sharing) para
  más detalles.
  ([Issue #50114](https://github.com/istio/istio/issues/50114))

- **Corregido** un problema donde la fusión de métricas del pilot-agent producía un resultado incorrecto cuando
  Envoy reportaba métricas usando el tipo de contenido protobuf. La lógica implementada en pilot-agent no puede
  manejar correctamente el tipo de contenido protobuf, por lo que este cambio restringe los tipos de contenido
  permitidos solo a `text/plain` y `application/openmetrics-text`.
  ([Issue #60322](https://github.com/istio/istio/issues/60322))

- **Eliminado** el feature flag `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY`. El comportamiento de generar spans
  upstream para solicitudes de gateway ahora siempre está habilitado. Los usuarios que antes lo establecían en
  `false` deben eliminar esa configuración, ya que ya no tendrá ningún efecto.

## Extensibilidad

- **Corregido** un error donde un `Service` que referenciaba un waypoint en un namespace diferente no tenía el
  recurso `Telemetry` de todo el namespace incluido en su configuración.
  ([Issue #60665](https://github.com/istio/istio/issues/60665))

- **Corregido** un error donde un `WasmPlugin` en un namespace de aplicación que apuntaba a un `Service` mediante
  `targetRefs` causaba que un proxy waypoint entrara en bucle de fallos al inicio. La ruta LDS incluía correctamente
  el plugin para el waypoint, pero la ruta de búsqueda ECDS lo rechazaba como entre namespaces, dejando a Envoy
  esperando un recurso que nunca llegaría.
  ([Issue #60530](https://github.com/istio/istio/issues/60530))

## Instalación

- **Actualizado** el addon Kiali a la versión v2.26.0.

- **Añadidas** las variables de entorno `ZTUNNEL_RESOURCE_CPU_LIMIT` y `ZTUNNEL_RESOURCE_CPU_REQUEST` al
  `DaemonSet` de ztunnel, que se rellenan con los valores configurados de `resources.limits.cpu` /
  `resources.requests.cpu` cuando están establecidos. ztunnel las usa para derivar el número de hilos de trabajo con
  conciencia de CPU.

- **Añadido** el campo Helm `terminationMessagePolicy` para el contenedor de istiod (pilot), que permite configurar
  cómo se rellenan los mensajes de terminación.

- **Añadidos** los campos `dnsPolicy` y `dnsConfig` al chart Helm del gateway para configuración DNS personalizada
  en entornos con requisitos DNS no estándar.

- **Añadido** un flag `-o/--output` a `istioctl manifest generate` que escribe el manifiesto generado en un archivo
  en lugar de stdout. Esto evita depender de la redirección del shell, lo que es conveniente para la automatización
  y necesario en entornos donde no hay shell disponible (por ejemplo, imágenes `istioctl` reforzadas que no lo
  incluyen).

- **Añadido** `values.global.readerServiceAccount` con campos `name` y `namespace` para vincular el `ClusterRole`
  `istio-reader` a una cuenta de servicio personalizada. Cuando se establece, la `istio-reader-service-account`
  predeterminada no se crea, y el `ClusterRoleBinding` referencia la cuenta de servicio especificada. Establecer
  `global.enableReaderRBAC` en `false` suprime el `ClusterRole` `istio-reader` y el `ClusterRoleBinding`
  independientemente de la configuración de `readerServiceAccount`.

- **Corregido** un problema donde el contenedor `istio-init` usaba la imagen incorrecta cuando
  `global.proxy_init.image` y `global.proxy.image` se configuraban de forma diferente.
  ([Issue #59066](https://github.com/istio/istio/issues/59066))

- **Corregido** que el volumen de socket de workload del waypoint y kube-gateway fuera incompatible con la
  configuración del driver CSI de SPIRE.
  ([Issue #60108](https://github.com/istio/istio/issues/60108))

- **Corregida** la representación del chart Helm cuando `global.istioNamespace` o el namespace del release es solo
  numérico (por ejemplo, `1234`). Los campos de namespace en los manifiestos representados ahora se citan para que
  los parsers YAML los traten como cadenas en lugar de números.
  ([Issue #60239](https://github.com/istio/istio/issues/60239))

## istioctl

- **Añadido** soporte para que `istioctl remote-clusters` muestre revisiones.

- **Añadida** una advertencia de `istioctl analyze` (`IST0177`) para cuando múltiples recursos `ServiceEntry`
  definen el mismo host y puerto con protocolos conflictivos.
  ([Issue #60447](https://github.com/istio/istio/issues/60447))

- **Añadida** una verificación de `istioctl analyze`, `IST0176`, que marca los CRDs de Gateway API instalados en
  una versión inferior a la mínima requerida por la versión actual de Istio. Los recursos respaldados por dichos
  CRDs son filtrados silenciosamente por istiod, lo que antes hacía difícil descubrir fallos de TLS passthrough
  tras actualizar a Istio 1.30 con CRDs de Gateway API obsoletos.

- **Corregido** que `istioctl` fallara al descubrir istiod cuando Istio está instalado en un namespace no
  predeterminado (distinto de `istio-system`) con una etiqueta de revisión. El `DefaultWatcher` ahora construye el
  nombre de webhook esperado basándose en el namespace de Istio pasado mediante el flag `-i`.
  ([Issue #60232](https://github.com/istio/istio/issues/60232))

- **Corregido** que `istioctl tag remove` no eliminara la `ValidatingWebhookConfiguration`
  `istiod-default-validator` al eliminar la etiqueta de revisión predeterminada.
  ([Issue #60537](https://github.com/istio/istio/issues/60537))

- **Corregido** un problema donde los valores `--set` del manifiesto de `istioctl` que contenían `=` se analizaban
  como entrada malformada.
