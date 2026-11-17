---
title: Notas de cambios de Istio 1.32.0
linktitle: 1.32.0
subtitle: Versión Menor
description: Notas de la versión Istio 1.32.0.
publishdate: 2026-11-09
release: 1.32.0
weight: 10
aliases:
    - /news/announcing-1.32.0
---

## Gestión del tráfico

- **Mejorado** el uso de memoria de delta xDS: las suscripciones WDS comodín ya no acumulan nombres de recursos
  de solicitudes posteriores, y el mapa `initial_resource_versions` enviado al reconectar se libera
  antes de generar la respuesta para los tipos que no lo usan.

- **Mejorado** el procesamiento incremental de EDS ante cambios en `DestinationRule` para identificar los servicios afectados
  a través del scope del sidecar, alineándolo con CDS y evitando búsquedas de `DestinationRule` por clúster.

- **Mejorado** el rendimiento al obtener los recursos `PeerAuthentication` de un workload determinado.

- **Mejorado** el rendimiento de la generación de RDS en sidecars al consultar la caché de RDS antes de construir los
  protos `VirtualHostWrapper`/route, de modo que un acierto de caché ya no paga el coste de generar las rutas.
  Para hacerlo posible, la clave de la caché de RDS ahora se calcula a partir de un superconjunto conservador de los
  `DestinationRule` que podrían influir en la ruta (en lugar de solo el conjunto exacto usado por la
  construcción final filtrada). Como resultado, algunos cambios no relacionados en `DestinationRule` —en particular
  los que tienen hosts comodín— pueden provocar ahora una invalidación de la caché de RDS (y un push adicional) que
  antes se habría evitado. Esto no afecta a la corrección, solo a la frecuencia de invalidaciones de caché
  que de otro modo serían innecesarias.

- **Actualizado** el perfil de plataforma OpenShift para que `global.nativeNftables` sea `true` por defecto tanto en instalaciones
  con sidecar como en modo ambient. Aún puede sobrescribirse estableciendo explícitamente `global.nativeNftables=false`.

- **Añadida** una optimización opcional para la generación de listeners de servicios TCP headless: en lugar de crear un
  listener por IP de pod, Istio puede generar un único listener comodín `0.0.0.0:Port` con cadenas de filtros
  CIDR `/32` por pod. Esto reduce el número de listeners xDS y el tamaño de la carga para servicios headless grandes (p. ej.,
  recursos `StatefulSet`). Está deshabilitada por defecto; habilítala estableciendo la variable de entorno
  `PILOT_ENABLE_HEADLESS_FILTER_CHAIN_LISTENER` en `true` en istiod.
  ([Issue #60552](https://github.com/istio/istio/issues/60552))

- **Añadido** el campo `outlierDetectionHttpErrorCodes` a `DestinationRule.OutlierDetection`,
  que permite especificar qué códigos de estado HTTP se tratan como errores en la detección
  de valores atípicos. Si se especifica, solo las respuestas con uno de estos códigos se cuentan como errores
  para los umbrales de expulsión `consecutive5xxErrors` y `consecutiveGatewayErrors`.
  Si no se especifica, solo se cuentan como errores las respuestas 5xx.
  ([Issue #60828](https://github.com/istio/istio/issues/60828))

- **Añadido** soporte experimental para el recurso `XBackend` de Gateway API, usado
  para describir el comportamiento que deben seguir los clientes al conectarse a destinos específicos.
  El soporte para el modo TLS de Backend `ClientAndServer` está deshabilitado actualmente.
  ([Issue #60747](https://github.com/istio/istio/issues/60747))

- **Añadida** una advertencia de validación para direcciones de `ServiceEntry` que sean catch-all (`0.0.0.0`, `::`), tengan una red no especificada (`0.0.0.0/N`, `::/N`)
  o sean un CIDR con un prefijo menor que `/8`. Un `ServiceEntry` así con `resolution: NONE` y el `exportTo` por defecto puede hacer que todos los sidecars
  de la mesh dejen pasar el tráfico en sus puertos, eludiendo `outboundTrafficPolicy` `REGISTRY_ONLY`. Usa un CIDR más estrecho y `exportTo: ["."]`.
  Para imponer el control de egress, usa un egress gateway con una `NetworkPolicy`.

- **Añadido** un resumen de watch por tipo (cantidad de nombres de recursos e indicador de comodín) al endpoint
  `/debug/adsz`, y un parámetro `?brief` que omite las listas de nombres de recursos observados, que pueden ser muy
  grandes en meshes grandes.

- **Añadido** soporte para la configuración TLS de certificados de cliente de Gateway API al usar `agentgateway`. Los recursos `Gateway` ahora respetan
  la validación de certificados de cliente del frontend (`spec.tls.frontend`, incluido el modo `AllowInsecureFallback`) y los certificados
  de cliente del backend (`spec.tls.backend.clientCertificateRef`), y reportan las condiciones correspondientes `ResolvedRefs` y
  `InsecureFrontendValidationMode` en el estado.

- **Añadida** una nueva política de balanceo de carga `backendUtilization` a `DestinationRule`. Usa la
  utilización que los backends reportan mediante reportes de carga ORCA para ponderar dinámicamente los endpoints, de modo
  que los endpoints que reportan mayor utilización reciben proporcionalmente menos solicitudes. Se
  implementa con la política de balanceo de carga `client_side_weighted_round_robin` de Envoy.
  ([Issue #60814](https://github.com/istio/istio/issues/60814))

- **Añadido** soporte para límites de buffer de conexión a nivel de clúster (`clusterPerConnectionBufferLimitBytes`)
  mediante `connectionSettings` en `ProxyConfig`, incluidos valores por defecto del perfil `EDGE` para los proxies de gateway.

- **Añadido** un campo `defaultInboundHttpRetryPolicy` a la configuración de la mesh para configurar la política de reintentos por defecto
  aplicada a las rutas de entrada en los sidecars. Anteriormente esta política estaba fijada en 2 intentos con
  `reset-before-request` y no podía ajustarse ni desactivarse. Solo se aplican `attempts`, `retryOn` y
  `backoff`; establecer `defaultInboundHttpRetryPolicy: {}` deshabilita los reintentos de entrada en toda la mesh.

- **Añadida** una nueva operación de parche `MERGE_AND_REPLACE_LIST` a `EnvoyFilter`. Se comporta como
  `MERGE`, salvo que los campos repetidos (listas) presentes en el parche reemplazan por completo la
  lista correspondiente de la configuración generada en lugar de añadirse a ella. Esto
  se aplica a los destinos de parche `CLUSTER`, `LISTENER`, `FILTER_CHAIN`, `ROUTE_CONFIGURATION`, `VIRTUAL_HOST`,
  `HTTP_ROUTE`, `NETWORK_FILTER`, `HTTP_FILTER` y `LISTENER_FILTER`, incluidas las
  listas anidadas dentro de configuraciones de tipo `Any`, como el `typed_config` de los filtros.

- **Añadido** soporte para el campo `transportSocket` en la coincidencia de cadenas de filtros de `EnvoyFilter`, permitiendo que los parches
  seleccionen cadenas de filtros por el transport socket con el que están configuradas, como
  `envoy.transport_sockets.tls` para las cadenas de filtros que terminan TLS. A diferencia de `transportProtocol`, que coincide con
  el tráfico que acepta una cadena de filtros, esto coincide con la extensión que procesa los bytes de la conexión.

- **Añadido** soporte para listeners `AUTO_PASSTHROUGH` en los gateways east-west de ambient (`GatewayClass`
  `istio-east-west`). Un listener TLS passthrough en el puerto 15443 (o en cualquier puerto que use la
  opción `gateway.istio.io/listener-protocol: auto-passthrough`) ahora sirve el tráfico multired de sidecars
  junto con el listener HBONE, de modo que una mesh mixta con ambient y sidecars ya no necesita dos
  gateways east-west por clúster. Requiere habilitar `AMBIENT_ENABLE_MULTI_NETWORK`.
  ([Issue #60887](https://github.com/istio/istio/issues/60887))

- **Añadido** el campo `failurePercentageThreshold` a `DestinationRule.OutlierDetection`, que permite
  expulsar hosts según su tasa de fallos durante el `interval` de análisis en lugar de
  exigir fallos consecutivos. A diferencia de `consecutive5xxErrors` y `consecutiveGatewayErrors`,
  los errores de un host no tienen que ocurrir de forma consecutiva, por lo que un host con una tasa de fallos alta
  se expulsa aunque sus fallos estén intercalados con solicitudes exitosas.

- **Añadido** soporte para sobrescribir los protocolos ALPN anunciados por los gateways que terminan TLS mediante el campo `alpnProtocols`
  del recurso `Gateway`.

- **Añadido** soporte para `globalDownstreamConnectionLimit` en `ProxyConfig.connectionSettings`,
  que ofrece un campo de API de primera clase para configurar el límite global de conexiones downstream.
  Tiene prioridad sobre los metadatos existentes `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS`
  y el flag de runtime obsoleto `overload.global_downstream_max_connections`.
  ([Issue #57973](https://github.com/istio/istio/issues/57973))

- **Añadido** soporte para aplicar recursos `ProxyConfig` con selectores de workload en el namespace raíz de la mesh
  a los workloads coincidentes en todos los namespaces. Un `ProxyConfig` con ámbito de workload que coincida en el
  propio namespace del workload tiene prioridad sobre la configuración del namespace raíz.

- **Añadida** la síntesis de `x-forwarded-client-cert` en los sidecars para el tráfico que llega por HBONE.

- **Corregido** el controlador de eliminación de taints de nodo de ambient, que quitaba el taint `cni.istio.io/not-ready` cuando
  solo `istio-cni` estaba listo. Ahora también espera a que ztunnel esté listo en el nodo, para que los pods no se
  programen en un nodo cuyo ztunnel sigue atascado. Puede deshabilitarse con
  `PILOT_NODE_UNTAINT_CHECK_ZTUNNEL=false`, y solo se aplica cuando ambient está habilitado.
  ([Issue #52073](https://github.com/istio/istio/issues/52073))

- **Corregido** un problema por el que habilitar ambient multired para los ingress gateways
  rompía el enrutamiento del ingress gateway hacia los pods con sidecar; el problema impedía que sidecar
  y ambient coexistieran en el mismo despliegue multired de Istio.
  ([Issue #60609](https://github.com/istio/istio/issues/60609))

- **Corregido** un error por el que los listeners de Gateway API que usan el modo de terminación TLS `OPTIONAL_MUTUAL`
  no autorizaban el secret de la CA de cliente para SDS, dejando el
  contexto de validación atascado en estado WARMING. La referencia al certificado de la CA ahora se
  autoriza para `OPTIONAL_MUTUAL` igual que ya se hacía para `MUTUAL`.
  ([Issue #60618](https://github.com/istio/istio/issues/60618))

- **Corregido** un error por el que un `ServiceEntry` cuya dirección es un CIDR generaba un listener
  de salida en el comodín 0.0.0.0 para un puerto de proxy reservado (por ejemplo, el
  puerto de captura de salida 15001). El listener comodín colisionaba con el listener
  `virtualOutbound`, se rechazaba toda la actualización de listeners y el sidecar
  no arrancaba. Estos puertos ahora se omiten, igual que ocurre con los servicios
  con una dirección concreta.
  ([Issue #60666](https://github.com/istio/istio/issues/60666))

- **Corregido** un problema en modo ambient por el que el backend de `iptables` autodetectado por el agente de nodo CNI
  (`legacy` vs `nft`) podía cambiar entre reinicios del agente, provocando que se escribieran reglas
  de redirección duplicadas en pods ya inscritos.
  ([Issue #61020](https://github.com/istio/istio/issues/61020))

- **Corregida** la generación de la tabla de nombres NDS para servicios headless para incluir los endpoints de todos los puertos del servicio,
  no solo del primero. Anteriormente, cuando Kubernetes dividía los recursos `EndpointSlice` por subconjunto de puertos (p. ej., nombres
  de `targetPort` heterogéneos entre grupos de pods), solo los pods presentes en el slice del primer puerto se incluían en la
  tabla de nombres DNS, lo que causaba `NXDOMAIN` para los nombres de host por pod de otros pods en clústeres remotos.
  ([Issue #61038](https://github.com/istio/istio/issues/61038))

- **Corregido** un problema por el que el uso de CPU de istiod aumentaba a medida que crecía el número de recursos `AuthorizationPolicy`.
  ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **Corregido** el fallo del tráfico `ALLOW_ANY_DYNAMIC_DNS` en clústeres solo IPv6 porque Envoy usaba la
  dirección loopback IPv4 para llegar al proxy DNS.
  ([Issue #61330](https://github.com/istio/istio/issues/61330))

- **Corregido** un panic cuando `outlierDetection` se aplica a un clúster comodín de proxy DNS (DFP).
  `CommonLbConfig` era nil en los clústeres construidos por `buildDFPCluster`, por lo que establecer
  `HealthyPanicThreshold` desreferenciaba un puntero nil. Ahora se inicializa tanto para los clústeres DFP como para los
  DFP allow-any, con una guarda de nil antes de la asignación.
  ([Issue #61450](https://github.com/istio/istio/issues/61450))

- **Corregido** un problema por el que istiod serializaba repetidamente el mismo workload al
  enviar metadatos de workload a los proxies Envoy.
  ([Issue #61502](https://github.com/istio/istio/issues/61502))

- **Corregida** una regla de `HTTPRoute` con varios `backendRefs` de `InferencePool` que configuraba solo un
  endpoint picker. El picker del último `backendRef` listado puntuaba todas las solicitudes de la regla,
  por lo que los pickers de los demás pools nunca se invocaban, y un pool sin endpoints listos hacía fallar
  toda la regla en lugar de solo su parte ponderada. Ahora cada pool tiene su propio picker,
  asociado a su propio clúster ponderado.
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregido** que dos `HTTPRoute` que comparten un `rules[].name` en el mismo gateway se sobrescribieran
  mutuamente el endpoint picker. Los nombres de regla solo tienen que ser únicos dentro de un mismo `HTTPRoute`, pero los
  pickers se indexaban por nombre entre todos ellos, por lo que una ruta podía ser atendida por el picker
  de otra ruta. Ahora los pickers se resuelven por `backendRef`, de modo que un nombre compartido ya no traslada
  el picker de una ruta a otra.
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregido** que una regla de ruta perdiera su endpoint picker de `InferencePool` cuando además incluía un
  filtro CORS. Ambos se escriben en la misma configuración por filtro, y la ruta de CORS
  reemplazaba el mapa en lugar de añadirle elementos.
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregido** el panic del agente Istio CNI cuando el estado de un pod contenía una dirección IP no válida.
  Las direcciones no válidas ahora se registran y se omiten.

- **Corregido** que un recurso `Gateway` con un listener HBONE se enviara a los sidecars como un
  gateway mTLS.
  ([Issue #61618](https://github.com/istio/istio/issues/61618))

- **Corregido** un problema por el que los proxies Envoy suscritos al descubrimiento de metadatos de workload (MDS) no
  recibían actualizaciones incrementales de workload para cambios solo de Address cuando
  `AMBIENT_SCOPED_ADDRESS_PUSHES` estaba habilitado (el valor por defecto).

- **Corregido** un `panic` en istiod al generar un clúster `STRICT_DNS`/`LOGICAL_DNS` para un
  `ServiceEntry` con `resolution: DNS` cuyos `endpoints` abarcan más de una `locality`, combinado
  con un `DestinationRule` que establece `trafficPolicy.loadBalancer.localityLbSetting.failoverPriority`.
  Anteriormente, istiod fallaba y entraba en un bucle de reinicios en cuanto se conectaba un proxy afectado,
  impidiendo que se enviara cualquier configuración.
  ([Issue #61857](https://github.com/istio/istio/issues/61857))

- **Corregidos** varios problemas en el chart de Helm `istio-cni`. No respetaba el valor `istioOwnedCNIConfigFileName`,
  no reiniciaba `istio-cni` cuando cambiaba su configuración, no eliminaba la configuración CNI propia ni el plugin `istio-cni`
  de la configuración CNI primaria al desinstalar, no limpiaba la configuración CNI primaria cuando la configuración propia estaba habilitada
  y no eliminaba el archivo anterior cuando cambiaba el nombre del archivo de la configuración propia.
  ([Issue #61890](https://github.com/istio/istio/issues/61890))

- **Corregida** la inicialización concurrente del contexto de push cuando el debouncing de EDS está deshabilitado.
  ([Issue #61924](https://github.com/istio/istio/issues/61924))

- **Corregido** un problema por el que, con `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` habilitado, los pushes incrementales de CDS eliminaban los clústeres de gateway
  de los recursos `Service` listados en la anotación `envoyfilter.istio.io/referenced-services` de un `EnvoyFilter`. Estos clústeres solo
  se restauraban en el siguiente push completo.
  ([Issue #62067](https://github.com/istio/istio/issues/62067))

- **Corregida** una situación en la que la obtención del JWKS podía bloquear la generación de xDS.
  ([PR #62486](https://github.com/istio/istio/pull/62486))

- **Corregido** un problema por el que un waypoint `agentgateway` que un servicio referenciaba solo como su canary,
  mediante la etiqueta `istio.io/use-waypoint-canary`, no se programaba con las rutas y políticas
  asociadas a ese servicio. Las conexiones desviadas al waypoint canary eran rechazadas, porque el
  waypoint no tenía configuración para el servicio al que daba servicio.
  ([Issue #61036](https://github.com/istio/istio/issues/61036))

- **Corregida** la selección no determinista de rutas cuando varios `TCPRoute` o `TLSRoute` se asocian al mismo listener de `Gateway` de `agentgateway`.
  Ahora se selecciona siempre la ruta más antigua (por marca de tiempo de creación, luego namespace/nombre),
  siguiendo las reglas de resolución de conflictos de Gateway API. Anteriormente la ruta asociada al
  listener no era determinista, por lo que el tráfico podía llegar al backend equivocado.

- **Corregido** un problema por el que el workload pre-serializado usado para la detección de cambios y el versionado
  en ambient no era estable cuando un workload tenía más de un servicio, lo que hacía que workloads sin cambios
  parecieran modificados en cada recálculo e impedía omitir los workloads sin cambios cuando un
  cliente se reconectaba.

- **Corregido** un problema por el que el CNI no eliminaba las entradas de ipset de un pod que había tenido fallos durante su creación. Ahora se eliminan todas las entradas de ipset asociadas al pod.

- **Corregido** un problema en el modo ambient multired por el que el servicio `kubernetes.default` podía
  marcarse como de alcance global mediante `serviceScopeConfigs`, haciendo que el servicio del servidor de API se compartiera
  entre clústeres. El servicio `kubernetes.default` ahora se trata siempre como local al clúster.

- **Corregido** un problema por el que el gateway de red seleccionado para un workload se elegía en orden
  aleatorio cuando una red tenía más de una entrada de gateway, lo que provocaba pushes innecesarios de workload
  (WDS) en cada recálculo y podía alternar la dirección del gateway que usa un workload.

- **Corregida** una fuga de memoria que afectaba al modo multiclúster ambient de istiod, en la que rotar las
  credenciales de un clúster remoto filtraba todo el estado en caché de ese clúster.
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Corregido** que la etiqueta `istio.io/use-waypoint-canary` eludiera el aislamiento NAMESPACE de
  `serviceEntryVisibility`: un `ServiceEntry` con visibilidad NAMESPACE podía enrutar su porción canary del
  tráfico a través de un waypoint de otro namespace. El waypoint canary ahora está sujeto al mismo
  rechazo entre namespaces que el principal.

  Este problema fue reportado por Raphael Zanarelli.

- **Corregido** un problema por el que `istio-cni` omitía la limpieza de un pod ambient eliminado junto con su namespace, dejando atrás su proxy ztunnel y la entrada de ipset de la sonda del host.

- **Corregido** un problema introducido en Istio 1.31 por el que un cambio en un `ConfigMap` que contiene certificados de CA, como el
  `ConfigMap` `kube-root-ca.crt` que Kubernetes crea en cada namespace, desencadenaba pushes de CDS, LDS, RDS y NDS a
  todos los proxies. Los clústeres se reconstruían por completo en lugar de forma incremental. Igual que las actualizaciones de `Secret`, estos cambios ahora solo
  desencadenan pushes de SDS. EDS también se omite ahora para estas actualizaciones.
  ([Issue #62523](https://github.com/istio/istio/issues/62523))

- **Corregido** un problema por el que istiod retenía de forma permanente una copia de cada nombre de recurso de workload por cada
  conexión MDS de Envoy (WDS, usada para consultas de metadatos de telemetría) que enviaba `initial_resource_versions`.

- **Corregido** un problema por el que una actualización de solo metadatos de un `EndpointSlice`, como una herramienta GitOps que escribe una anotación,
  desencadenaba un push de EDS, y para los recursos `Service` headless con puertos no HTTP un push a todos los proxies, aunque los
  endpoints no habían cambiado.

- **Corregido** un parche `MERGE` de `LISTENER_FILTER` de `EnvoyFilter` que corrompía los filtros de listener
  compartidos por todos los proxies y se aplicaba a filtros de listener que no coincidían con
  `match.listener.listenerFilter`.

- **Corregido** el filtrado de dependencias de configuración para los gateways, para excluir actualizaciones de configuración no relacionadas.
  La construcción del scope del gateway también omite la recopilación de recursos `VirtualService` de la mesh usados solo para el enrutamiento de waypoints.

- **Corregido** un problema de Gateway API por el que un `certificateRef` o
  `caCertificateRef` TLS entre namespaces se resolvía antes de la comprobación de autorización
  de `ReferenceGrant`, de modo que el estado `ResolvedRefs` de un listener podía revelar si el
  `Secret` o `ConfigMap` referenciado existía incluso cuando ningún grant permitía la
  referencia. Ahora la autorización se ejecuta primero y devuelve `RefNotPermitted` para cualquier
  referencia entre namespaces sin grant.

  Este problema fue reportado por Darryl Jaskolski.

- **Corregida** una fuga de streams HBONE en modo ambient en la que los streams `connect_originate`
  podían quedar abiertos para siempre después de que un peer cerrara por completo la conexión, mediante la
  actualización de Envoy incluida en esta versión.
  ([Issue #60074](https://github.com/istio/istio/issues/60074))

  Este problema fue reportado por Torben Strüver.

- **Corregido** que eliminar un único event handler de un informer respaldado por CRD eliminara todos los handlers de
  ese informer. En el modo multiclúster ambient esto ocurría en cada rotación de credenciales de un clúster
  remoto, dejando a istiod esperando indefinidamente a que se sincronizaran las colecciones del nuevo clúster, de modo que los
  network gateways remotos desaparecían y el índice de workloads podía dejar de actualizarse hasta reiniciar.
  ([Issue #61827](https://github.com/istio/istio/issues/61827))

- **Corregida** una fuga de memoria en el modo multiclúster ambient en la que las colecciones se registraban en el
  depurador de krt pero nunca se desregistraban cuando se eliminaba un clúster remoto o cambiaba su configuración,
  provocando que los registros del depurador se acumularan con el tiempo.
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Corregido** que el modo multiclúster ambient descartara la configuración de un clúster remoto mientras sus
  colecciones por clúster se intercambiaban, por ejemplo cuando se rotaban sus credenciales. El intercambio se interpretaba como
  la eliminación de un clúster y la adición de otro no relacionado, de modo que los servicios, waypoints y workloads
  de ese clúster podían desaparecer brevemente de la configuración servida a los proxies, y los eventos ocurridos
  durante el intercambio podían perderse por completo.
  ([Issue #61348](https://github.com/istio/istio/issues/61348))

- **Corregido** que los componentes de Istio se quedaran colgados indefinidamente cuando una solicitud a la API de Kubernetes no recibía
  respuesta, por ejemplo cuando un balanceador de carga o proxy descarta silenciosamente la ruta de retorno.
  Anteriormente una solicitud así podía permanecer abierta para siempre, bloqueando al controlador que la emitió
  hasta que el proceso se reiniciaba. Ahora las solicitudes expiran en el lado del cliente, de modo que una solicitud
  atascada se cancela y el componente se recupera por sí solo. Cada timeout se registra como una
  advertencia y se contabiliza en la métrica `kube_client_deadline_fired_total`.

- **Corregido** el seguimiento de conflictos de listeners que trataba un `Gateway` y un `ListenerSet` con el mismo
  namespace y nombre como el mismo objeto, lo que hacía que un conflicto registrado para uno marcara el
  listener ganador del otro como `Conflicted` e impidiera su programación.

- **Corregida** la resolución de conflictos de `ListenerSet` para conflictos de hostname y protocolo.
  Los listeners en conflicto ahora se rechazan correctamente y las condiciones de estado de `ListenerSet`
  se reportan conforme a Gateway API 1.5.
  ([PR #60775](https://github.com/istio/istio/pull/60775))

- **Corregido** un problema por el que una actualización de solo metadatos de un recurso de configuración de Istio, como una herramienta GitOps que escribe una
  anotación, desencadenaba un push siempre que el recurso tuviera cualquier etiqueta o anotación `istio.io`, por ejemplo
  `istio.io/rev`. Ahora solo se desencadena un push cuando cambia el spec o el valor de una etiqueta o anotación `istio.io`.

- **Corregido** un problema por el que las actualizaciones de configuración irrelevantes para EDS combinadas con una actualización de endpoints
  provocaban una generación completa de EDS en lugar de actualizar solo las asignaciones de endpoints afectadas.

- **Corregido** que los recursos `ServiceEntry` con un selector de workload presente pero vacío coincidieran incorrectamente con todos los workloads de su namespace.

- **Corregido** que un pod de un clúster remoto seleccionado por un `ServiceEntry` no se recalculara
  cuando se convertía en endpoint de ese servicio. El recálculo se dirigía al clúster en el que se ejecuta istiod
  en lugar de al clúster al que pertenece el pod.

- **Corregido** que un `WorkloadEntry` seleccionado por un `Service` no tuviera su proxy correspondiente recalculado
  cuando se convertía en endpoint de ese servicio.

- **Corregido** que `observedGeneration` se quedara atascado en un valor obsoleto cuando un recurso se modifica de nuevo
  mientras una escritura de estado anterior sigue en cola.

- **Corregido** un fallo en istiod cuando la dirección de un waypoint con dirección IP era reclamada también por otro servicio
  (por ejemplo, un `ServiceEntry` de otro namespace). Las direcciones en colisión ahora se omiten con una advertencia
  en lugar de provocar un panic, lo que anteriormente permitía a un tenant con pocos privilegios hacer caer el control plane.
  Consulta [GHSA-7p2q-4xvg-vxc6](https://github.com/istio/istio/security/advisories/GHSA-7p2q-4xvg-vxc6).
  Reportado por [@yshch](https://github.com/yshch).

- **Corregida** la propagación de endpoints no saludables cuando `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` o
  `PILOT_SEND_UNHEALTHY_ENDPOINTS` están habilitados. Los pods no listos seleccionados por recursos `ServiceEntry`
  y los recursos `WorkloadEntry` no saludables con health checks seleccionados por recursos `Service` de Kubernetes o
  recursos `ServiceEntry` ahora se conservan con su estado de salud en lugar de omitirse.

- **Corregido** que la validación de `VirtualService` omitiera los nombres de gateway restantes después de una entrada sin namespace
  en `gateways` y en los `gateways` de las coincidencias HTTP/TLS/TCP. Los nombres de gateway no válidos listados después de
  una entrada así ahora se rechazan.

- **Corregido** que la validación de `VirtualService` aceptara el estado HTTP `600` en `fault.abort.httpStatus` y `directResponse.status`.
  Envoy solo permite códigos de estado en el rango 200-599 para estos campos, por lo que ahora la validación rechaza esos valores.

- **Corregida** una regresión que impedía que los pushes de WDS omitieran el debouncing. La nueva
  variable de entorno `PILOT_ENABLE_WDS_DEBOUNCE` controla esto y está habilitada por defecto.
  Establécela en `false` para permitir que los pushes de WDS omitan el debouncing independientemente de los pushes de EDS.
  ([Issue #62125](https://github.com/istio/istio/issues/62125))

- **Optimizado** el procesamiento de parches merge de `EnvoyFilter` mediante el cacheo de las configuraciones tipadas decodificadas,
  evitando la deserialización repetida durante la generación de configuración xDS.

- **Optimizados** los pushes de configuración a los gateways. Istiod ahora rastrea los recursos `VirtualService`
  asociados a los recursos `Gateway` que sirve cada ingress gateway o gateway east-west de ambient, y
  solo envía un cambio de `VirtualService` a los gateways a los que está asociado, en lugar de a todos los gateways de
  la mesh. Esto también optimiza la generación de CDS y RDS para los gateways.

- **Optimizada** la generación de rutas de gRPC sin proxy omitiendo las reconstrucciones para actualizaciones que no afectan a
  las rutas, como los cambios de solo endpoints.

## Seguridad

- **Mejorada** la evaluación de las políticas `ALLOW` en las rutas a las que apunta una `AuthorizationPolicy`.
  Una política `ALLOW` con ámbito de ruta se evalúa junto con las políticas `ALLOW` propias del gateway, de modo que
  una solicitud se permite si coincide con cualquiera de ellas. Por tanto, una política `ALLOW` con ámbito de ruta amplía
  el acceso en esa ruta en lugar de restringirlo, de forma coherente con cómo ya se combinan las políticas `ALLOW` del
  namespace raíz y del workload. Las políticas `DENY` con ámbito de ruta son aditivas y
  no pueden anular una política `DENY` definida para el gateway o en el namespace raíz.
  ([Issue #60964](https://github.com/istio/istio/issues/60964))

- **Actualizadas** las imágenes `distroless` a una base `cgr.dev/chainguard/static` con el último bundle de CA, que elimina `emSign ECC Root CA - G3` tras el compromiso de las claves de la CA intermedia de eMudhra.

- **Añadido** soporte experimental para apuntar a recursos `HTTPRoute` de Gateway API desde una
  `AuthorizationPolicy` mediante `targetRefs`, lo que permite acotar las reglas `ALLOW` y `DENY` a una
  ruta individual en lugar de a todo el gateway. Está deshabilitado por defecto y se habilita
  estableciendo `ENABLE_GATEWAY_API_HTTPROUTE_AUTH=true` en `istiod`. La política debe residir en el mismo
  namespace que el `HTTPRoute` al que apunta, y solo se admiten los ingress gateways; los waypoints y
  los sidecars ignoran estas políticas. Las acciones `CUSTOM` y `AUDIT` no pueden dirigirse a un
  `HTTPRoute`, y una referencia de destino a un `HTTPRoute` no puede combinarse con referencias de destino de
  otros tipos en la misma política.
  ([Issue #60964](https://github.com/istio/istio/issues/60964))

- **Añadido** el mensaje del analizador `IST0178`, que advierte cuando un `EnvoyFilter` inserta un filtro HTTP
  mientras existe una `AuthorizationPolicy` que apunta a un `HTTPRoute`. Los recursos `EnvoyFilter` que limpian la
  caché de enrutamiento después de que se haya ejecutado un filtro dependiente de la ruta pueden hacer que una solicitud se enrute
  de forma distinta a como se enrutó cuando se evaluó el filtro.
  ([Issue #60964](https://github.com/istio/istio/issues/60964))

- **Añadida** una variable de entorno `WORKLOAD_IDENTITY_SOCKET_TIMEOUT` a
  `pilot-agent`, que configura cuánto tiempo esperar al inicio a que un proveedor
  SDS externo, como SPIRE, cree el socket de identidad de workload y empiece a servir en él. Sin configurar el timeout, el socket se comprueba
  solo una vez al inicio, de modo que un proveedor que enlaza su socket después de que
  `pilot-agent` arranque podía hacer que el proxy solicitara la CA raíz del sistema
  al proveedor SDS externo, fallando la validación TLS upstream. El valor por defecto
  es `0s`, que conserva el comportamiento actual de comprobación única.
  ([Issue #61343](https://github.com/istio/istio/issues/61343))

- **Añadida** la variable de entorno `PILOT_DISABLE_SELF_SIGNED_CA` a istiod. Cuando se establece en `true`, istiod falla al iniciar su CA
  en lugar de generar o reutilizar una CA raíz autofirmada (`istio-ca-secret`) cuando no hay un bundle `cacerts` conectado.
  Esto permite que los despliegues que solo deben usar una CA conectada fallen de forma segura en lugar de recurrir a
  una raíz autofirmada no deseada. El valor por defecto es `false`.

- **Añadido** soporte para configurar las curvas ECDH de los gateways que terminan TLS con el campo `ecdhCurves` del recurso `Gateway`.

- **Añadido** un campo `presence` a `JWTRule` en `RequestAuthentication`. Cuando se establece en `REQUIRED`, el token JWT de esa regla debe estar presente y ser válido; las solicitudes sin él se rechazan con `401 Unauthorized`.
  Anteriormente, configurar varias `jwtRules` validaba cada token de forma independiente pero permitía pasar solicitudes con un solo token válido. Establecer `presence: REQUIRED` en cada regla exige que todos los tokens configurados estén presentes y sean criptográficamente válidos.
  Esto es útil cuando los workloads deben recibir tokens de varios emisores en cabeceras distintas, por ejemplo un token de identidad en `Authorization` y un token de scope en una cabecera personalizada.
  El campo tiene por defecto `OPTIONAL`, conservando el comportamiento actual de los recursos `RequestAuthentication` existentes.
  Cuando se configuran varias reglas `REQUIRED`, los claims de todos los tokens validados son accesibles en `AuthorizationPolicy` mediante `request.auth.claims`. El payload de cada proveedor se almacena bajo su propia clave de metadatos, de modo que las reglas de autorización pueden referenciar claims de cualquiera de los tokens requeridos.
  ([Issue #60823](https://github.com/istio/istio/issues/60823))

- **Corregida** la capacidad de borrar la Lista de Revocación de Certificados (CRL), ya sea especificando la cadena vacía como `ca-crl.pem` o eliminándolo.
  ([Issue #61073](https://github.com/istio/istio/issues/61073))

- **Corregido** un mensaje de estado incorrecto para los recursos `AuthorizationPolicy` `DENY` con
  solo atributos HTTP en modo ambient. ztunnel no aplica estas políticas
  (las coincidencias vacías se omiten), por lo que ahora el estado reporta que
  no tienen efecto y recomienda desplegar un waypoint proxy con un `targetRef`.
  ([Issue #61126](https://github.com/istio/istio/issues/61126))

- **Corregido** que el resolutor de JWKS forzara todas las obtenciones de claves públicas a HTTP/1.1. El
  `TLSClientConfig` y el `DialContext` personalizados usados para el TLS pinning y el bloqueo de CIDR hacían que `net/http` de Go
  deshabilitara HTTP/2 automático, por lo que ALPN nunca negociaba h2. HTTP/2 ahora está
  rehabilitado (igual que `http.DefaultTransport`), lo que corrige las obtenciones de JWKS que fallan por HTTP/1.1
  a través de algunos proxies HTTP CONNECT.
  ([Issue #61250](https://github.com/istio/istio/issues/61250))

- **Corregido** que `ipBlocks` y `notIpBlocks` de `AuthorizationPolicy` en
  los listeners internos HBONE de waypoints y sidecars coincidieran con la dirección IP remota directa
  del cliente downstream en lugar de la dirección interna de Envoy.
  ([Issue #62522](https://github.com/istio/istio/issues/62522))

- **Corregido** un fallo en istiod en modo ambient cuando una `AuthorizationPolicy` tenía una entrada `to` o `from` vacía.
  Estas entradas ahora se tratan como una `operation` o `source` vacía, igual que en el comportamiento de los sidecars.

- **Corregida** una elusión de mTLS en modo ambient en la que un `PeerAuthentication` `STRICT` a nivel de puerto no se
  aplicaba cuando el modo a nivel de workload era `PERMISSIVE` o `DISABLE` y el modo de toda la mesh era `STRICT`.
  El tráfico en texto plano podía llegar a ese puerto.

- **Corregida** la elusión de las condiciones de `AuthorizationPolicy` sobre `request.headers[:authority]` y `request.headers[host]`
  cambiando las mayúsculas/minúsculas del host. Ahora estas condiciones se comparan sin distinguir mayúsculas de minúsculas,
  igual que `hosts`.

- **Corregida** la elusión de las reglas de método de `AuthorizationPolicy` sobre HTTP/2 cambiando
  las mayúsculas/minúsculas del método (p. ej., `post` en lugar de `POST`). Ahora la coincidencia de métodos no distingue mayúsculas de minúsculas.
  Consulta [GHSA-w44g-8m76-8gc5](https://github.com/istio/istio/security/advisories/GHSA-w44g-8m76-8gc5).
  Reportado por [@izzysec](https://github.com/izzysec).

- **Corregido** un fail-open en `BackendTLSPolicy` por el que los proxies sidecar enviaban tráfico upstream en texto plano en lugar de fallar de forma segura cuando los `caCertificateRefs` de una política no podían resolverse.

- **Corregido** que la actualización periódica en segundo plano del resolutor de JWKS almacenara en caché una respuesta obtenida sin
  validar que parezca un JWKS. La ruta de obtención síncrona ya rechazaba una respuesta
  que no tuviera la forma de un JWKS (`{"keys": [...]}`), pero la actualización en segundo plano no, de modo que el
  `jwksUri` de un `RequestAuthentication` apuntando a un endpoint interno no previsto podía tener su
  respuesta almacenada en caché y servida como si fuera un JWKS. Ahora la ruta de actualización en segundo plano aplica la misma comprobación.

  Esta vulnerabilidad fue descubierta y reportada por Anthropic y Ada Logics.

- **Corregida** una brecha de SSRF en la obtención de `jwksUri` de `RequestAuthentication` de istiod. Ahora `istiod`
  bloquea por defecto, a nivel de dial, las direcciones link-local y de metadatos de nube conocidas (como `169.254.169.254`)
  y rechaza las respuestas obtenidas que no sean un JWKS válido. Los rangos privados y loopback
  siguen siendo accesibles y pueden bloquearse con `BLOCKED_CIDRS_IN_JWKS_URIS`.

- **Corregido** un panic en istiod cuando el autenticador OIDC/JWT recibía un token con un claim
  `sub` mal formado. Ahora se valida que el subject tenga exactamente la
  forma `system:serviceaccount:<namespace>:<serviceaccount>` antes de usarlo.

  Este problema fue reportado por Kaizhe Huang.

- **Corregido** que `CreateCertificate` devolviera a los llamantes el texto de error sin procesar de la API de Kubernetes en la
  ruta experimental de RA de CSR de Kubernetes (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`), lo que filtraba
  nombres de CSR, nombres de firmantes y la identidad de istiod. Ahora el error completo se registra solo en el servidor.
  Reportado por Juno Im.

- **Corregido** que el bucle de watch de CSR de Kubernetes usara un temporizador `time.After` abandonado que podía
  dejar una goroutine ejecutándose después de completarse la solicitud en la ruta experimental de RA de CSR de Kubernetes
  (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`). Ahora el bucle está acotado por un
  `context.WithTimeout` con el scope adecuado y se desmonta de forma fiable al expirar o cancelarse.
  Reportado por Juno Im.

- **Corregido** que se aceptara el `ValidityDuration` solicitado por el cliente hasta `MAX_WORKLOAD_CERT_TTL`
  (`90d` por defecto) en la ruta experimental de RA de CSR de Kubernetes (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`).
  Una nueva variable de entorno `MAX_RA_WORKLOAD_CERT_TTL` (`48h` por defecto) ahora limita el TTL,
  reduciendo el alcance del daño de un `istio-token` robado. Los despliegues que solicitaban legítimamente
  certificados con TTL > `48h` por esta vía deben aumentar `MAX_RA_WORKLOAD_CERT_TTL` tras la actualización.
  Reportado por Juno Im.

- **Corregido** que istiod fallara al iniciar cuando el certificado de la CA autofirmada de `istio-ca-secret` había expirado,
  lo que puede ocurrir cuando el despliegue se escala a cero durante más tiempo que el TTL del certificado.
  Ahora el certificado expirado se renueva automáticamente usando la clave privada existente.

- **Corregido** un error por el que la comprobación de autorización para el acceso a secrets del gateway no incluía los
  grupos de Kubernetes de la service account. Como resultado, las reglas `RoleBinding` y `ClusterRoleBinding` que
  concedían acceso a secrets a grupos como `system:serviceaccounts:<namespace>` se ignoraban,
  y se denegaba a los gateways el acceso a credenciales que se les habían concedido.
  ([Issue #58120](https://github.com/istio/istio/issues/58120))

- **Corregido** que varias anotaciones `sidecar.istio.io/*` (`proxyImage`, `bootstrapOverride`,
  `logLevel`, `componentLogLevel`, `agentLogLevel`) se interpolaran en las plantillas de inyección de
  sidecars/gateways sin escape de salida, lo que podía permitir que un valor de anotación manipulado
  inyectara campos adicionales en el spec de pod o deployment generado. Ahora estas anotaciones se
  escapan de forma coherente en cada punto de salida de las plantillas.

  Esta vulnerabilidad fue descubierta y reportada por localhost-detect.

- **Corregido** un problema por el que una nueva conexión entrante que reutilizaba la 4-tupla de una conexión desmontada
  podía eludir el proxy sidecar al coincidir con una entrada `ESTABLISHED` obsoleta de `conntrack`. Ahora una regla que coincide solo con paquetes `SYN`
  se evalúa antes de la regla de desvío `ESTABLISHED` tanto en modo `iptables` como `nftables`.

- **Corregidas** las brechas de protección contra SSRF en la obtención de módulos Wasm (`pkg/wasm`). El fetcher HTTP
  anteriormente no tenía ninguna restricción sobre la IP de destino, y la protección SSRF del fetcher de imágenes OCI
  solo inspeccionaba las respuestas `401` de bearer-realm, no las redirecciones `3xx` en la obtención real del
  manifest/blob. Ahora ambos fetchers bloquean las conexiones a direcciones link-local (lo que
  incluye endpoints de metadatos de instancias en la nube como `169.254.169.254`) a nivel de dial,
  de modo que el bloqueo se aplica a la solicitud original y a cada salto de redirección, tanto si
  el destino de la redirección es una IP literal como un hostname que resuelve a una. Una nueva
  variable de entorno `BLOCKED_CIDRS_IN_WASM_FETCH` permite a los operadores bloquear además
  rangos privados o direcciones específicas del clúster si lo desean.

  La elusión mediante redirección del fetcher de imágenes fue reportada por 박현범 e independientemente por Svpernova. El fetcher HTTP sin restricciones fue reportado por Aser Ahmed.

- **Corregido** que los waypoint proxies no recibieran los clústeres JWKS remotos cuando una política `RequestAuthentication` usa un `targetRef` de servicio.

- **Corregido** que istiod aceptara un `CLUSTER_ID` de metadatos de nodo que difiere del clúster contra el que se validó el token del proxy.

- **Corregidos** los endpoints de depuración de istiod (`/debug/config_dump`, `/debug/edsz` y el tipo xDS `istio.io/debug/config_dump`) que hacían coincidir `proxyID` como subcadena, lo que permitía a un llamante leer la configuración de otros proxies de su propio namespace pasando un ID parcial. Ahora `proxyID` debe ser exactamente `<pod>.<namespace>` (o el ID de conexión completo); las formas cortas como `proxyID=istio-ingressgateway` ya no coinciden.

  Este problema fue reportado por 박현범.

- **Corregido** un fallo en istiod por el que una solicitud xDS `istio.io/debug` con un nombre de recurso mal formado provocaba una
  desreferencia de puntero nil. Ahora la solicitud se rechaza con `InvalidArgument`.

- **Corregido** un fallo en ztunnel por el que una solicitud HBONE entrante con una cabecera `traceparent` mal formada provocaba un
  panic de índice fuera de rango, descartando todos los streams de esa conexión. Ahora las cabeceras `traceparent` no válidas se
  ignoran y se genera un nuevo ID de traza.

## Telemetría

- **Mejorado** el reporte de fallos de carga de la configuración de la mesh con registro de errores y de fallback específicos de cada origen y un nuevo contador `istiod_mesh_config_load_errors_total`.
  ([Issue #61563](https://github.com/istio/istio/issues/61563))

- **Añadido** el passthrough nativo de protobuf de Prometheus a través del fusionador de métricas de `pilot-agent`. Cuando un scraper de Prometheus envía `Accept: application/vnd.google.protobuf; proto=io.prometheus.client.MetricFamily; encoding=delimited`, los histogramas nativos (sparse) de Envoy ahora llegan al scraper sin cambios en lugar de degradarse silenciosamente por la recodificación en formato texto. La ruta de scrape existente de texto/OpenMetrics permanece idéntica byte a byte.
  ([Issue #49950](https://github.com/istio/istio/issues/49950))

- **Añadido** un nuevo contador `istio_agent_scrape_format_total{format,downgrade}` a `pilot-agent` que reporta el resultado de la negociación de formato por scrape (`text` / `openmetrics` / `protobuf`, con un indicador de degradación cuando los upstreams no coinciden).
  ([Issue #49950](https://github.com/istio/istio/issues/49950))

- **Añadido** soporte para que los waypoints registren métricas HTTP del tráfico entre clústeres que usa protocolos como TLS o PROXY cuando
  `AMBIENT_ENABLE_MULTI_NETWORK` y `AMBIENT_ENABLE_TLS_PROXY_HTTP_METRICS` están habilitados.

- **Corregidas** las etiquetas de métricas `source_app` y `destination_app` para usar la etiqueta de pod `app` cuando un pod
  también tiene `app.kubernetes.io/name`. Desde la 1.29.1 usaban `app.kubernetes.io/name`, lo que es una
  regresión respecto al comportamiento previsto.
  ([Issue #62280](https://github.com/istio/istio/issues/62280))

- **Corregida** la anotación `sidecar.istio.io/statsFlushInterval`, que producía un bootstrap de Envoy
  no válido para valores de un minuto o más, y para valores inferiores a un segundo, lo que impedía que el
  proxy arrancara.

- **Corregida** la anotación `sidecar.istio.io/statsEvictionInterval`, que truncaba silenciosamente
  la precisión inferior al segundo.

- **Corregida** una regresión por la que un recurso `Telemetry` en el propio namespace de un waypoint, seleccionado por
  `targetRefs` o `selector`, no se aplicaba cuando el waypoint servía un `Service` de un namespace distinto.
  El registro de acceso, las métricas y el trazado configurados de este modo se descartaban silenciosamente para
  cada `Service` de otro namespace que el waypoint gestionaba.
  ([Issue #61538](https://github.com/istio/istio/issues/61538))

## Extensibilidad

- **Corregido** que el fetcher de imágenes OCI de Wasm decidiera reintentar una obtención HTTPS fallida por
  HTTP en texto plano basándose en el error devuelto por el registro. Como el registro es
  una entrada no confiable, un MITM o un registro malicioso podía provocar este fallback bajo demanda
  para forzar el transporte en texto plano y, sin un digest de módulo opcional fijado, servir un
  binario Wasm arbitrario. Ahora el reintento en texto plano solo se intenta para los registros que el
  operador haya incluido explícitamente en la lista de permitidos mediante `WASM_INSECURE_REGISTRIES`.

  Esta vulnerabilidad fue descubierta y reportada por Adam Korczynski.

## Instalación

- **Actualizado** el addon de Kiali a la versión v2.34.1.

- **Añadido** un campo `terminationGracePeriodSeconds` a los valores de Helm de istiod (Pilot), que permite
  configurar el período de gracia de terminación de pods del `Deployment` de istiod. El valor por defecto es 30 segundos,
  igual que el comportamiento anterior.

- **Añadido** un valor `daemonSetAnnotations` al chart `istio-cni`, para establecer anotaciones en
  el propio objeto `DaemonSet` del CNI. El chart ya admitía `daemonSetLabels` para etiquetas
  y `podAnnotations` para los pods, pero las anotaciones propias del `DaemonSet` no podían establecerse.

- **Añadido** soporte para especificar un `nodePort` personalizado para cada puerto en la configuración del gateway de red.
  ([Issue #61569](https://github.com/istio/istio/issues/61569))

- **Añadido** `values.sidecarInjectorWebhook.revisionLabelPrecedence` para configurar la precedencia de la etiqueta de revisión
  en la inyección de sidecars.

  El valor por defecto es `namespace`, que conserva el comportamiento actual. Establecerlo en `pod` permite que la etiqueta
  `istio.io/rev` de un pod sobrescriba la etiqueta `istio.io/rev` de un namespace.
  ([Issue #48316](https://github.com/istio/istio/issues/48316)), ([Issue #48317](https://github.com/istio/istio/issues/48317))

- **Corregido** que istiod prefiriera el certificado de CA del `ConfigMap` `istio-ca-root-cert`, montado por separado y siempre presente
  (`/var/run/secrets/istiod/ca/root-cert.pem`), sobre el certificado de CA
  ubicado junto al certificado de servicio DNS (`/var/run/secrets/istiod/tls/ca.crt`) cuando ambos existen.
  Esto podía hacer que el `caBundle` de `MutatingWebhookConfiguration`/`ValidatingWebhookConfiguration`
  no coincidiera con la CA después de aprovisionar externamente el certificado de servicio DNS (p. ej., con cert-manager
  istio-csr o un `Secret` creado manualmente), aunque el propio istiod sirviera TLS correctamente
  con el nuevo certificado.
  ([Issue #60774](https://github.com/istio/istio/issues/60774))

- **Corregido** que el nombre del recurso `NetworkPolicy` del chart de Helm del gateway incluyera la revisión, lo que hacía que
  la `NetworkPolicy` se eliminara y recreara cuando cambiaba la revisión del gateway en lugar de
  actualizarse in situ.
  ([Issue #61016](https://github.com/istio/istio/issues/61016))

- **Corregida** la resolución de UID/GID del proxy sidecar en OpenShift para workloads asociados a una
  `SecurityContextConstraint` personalizada con un rango de UID estrecho o configurado explícitamente, que la
  anotación del rango de UID preasignado del namespace no anuncia.
  ([Issue #61791](https://github.com/istio/istio/issues/61791))

- **Corregido** que `istioctl install` e `istioctl manifest generate` rechazaran los valores `cni.ambient.enablementSelectors`,
  `cni.ambient.shareHostNetworkNamespace` y `cni.ambient.enableAmbientDetectionRetry`. El chart `istio-cni`
  los admite, pero faltaban en el esquema de valores de `IstioOperator`, por lo que solo podían establecerse instalando
  el chart directamente con Helm.
  ([Issue #61180](https://github.com/istio/istio/issues/61180))

- **Corregido** que el `ValidatingWebhookConfiguration` del chart `default` siguiera fijando `failurePolicy: Ignore`,
  lo que causaba el mismo conflicto de field manager en `helm upgrade` con server-side apply que se había
  corregido anteriormente para los charts `base` e `istiod`.
  ([Issue #61613](https://github.com/istio/istio/issues/61613))

- **Corregido** que el inyector de sidecars no validara la anotación
  `traffic.sidecar.istio.io/includeOutboundPorts`. Ahora un valor
  mal formado se rechaza en la admisión, de forma coherente con las anotaciones hermanas de puertos de tráfico
  y la ruta de redirección del CNI.

- **Corregido** que istiod solo tolerara el taint por defecto `cni.istio.io/not-ready`. Cuando `taint.name` se establece en un
  taint personalizado, el `Deployment` de istiod ahora tolera ese taint, de modo que istiod puede programarse en nodos que
  aún lo tengan.
  ([Issue #52073](https://github.com/istio/istio/issues/52073))

- **Eliminada** la variable de entorno `GOMAXPROCS` de todos los charts de Istio.
  Go 1.25 establece automáticamente `GOMAXPROCS` para que coincida con los límites de CPU.
  ([Issue #60235](https://github.com/istio/istio/issues/60235))

## istioctl

- **Mejorado** el reporte de errores de `istioctl analyze` cuando un `--meshConfigFile` especificado explícitamente no puede leerse o analizarse.

- **Actualizada** la versión mínima de Kubernetes soportada a 1.33.x.

- **Corregido** que `istioctl` omitiera la verificación del certificado de istiod al conectarse a xDS con un token de service account (`istioctl proxy-status`, `istioctl x internal-debug` y `--xds-address` en general). Ahora `istioctl` verifica el servidor contra el certificado raíz de Istio del `ConfigMap` `istio-ca-root-cert` y el nombre de servidor esperado: `--authority` si está establecido, el host de `--xds-address` si es un nombre DNS, o `istiod.<istio-namespace>.svc` al conectarse a una dirección IP o a localhost. Pasa `--insecure` (o establece `ISTIOCTL_INSECURE=true`) para omitir explícitamente la verificación.
  ([Issue #41937](https://github.com/istio/istio/issues/41937))

  Este problema fue reportado por [Leon Zlobecki](https://leonz.is).

- **Corregido** que `istioctl analyze` construyera clientes de Kubernetes directamente a partir de los secrets multiclúster de `istio-system`
  sin sanear el kubeconfig, lo que podía permitir que un
  secret manipulado ejecutara un plugin de credenciales `exec` (o leyera archivos locales mediante otros campos de
  autenticación inseguros) en la máquina que ejecuta `istioctl`. Ahora el kubeconfig se sanea de la misma
  forma en que istiod ya sanea estos secrets.

  Esta vulnerabilidad fue descubierta y reportada por Adam Korczynski.

- **Corregido** que `istioctl install --set values.base.validationFailurePolicy` se rechazara como
  campo desconocido. El valor ya era admitido por los charts `base` e `istiod`, pero
  faltaba en el esquema `values_types.proto` del operador.

- **Corregido** el fallo de `istioctl bug-report` cuando un filtro de inclusión o exclusión tiene demasiados campos.

- **Corregido** que `istioctl bug-report --duration` no filtrara los logs cuando se usa sin `--end-time`.

- **Corregido** que `istioctl install --set` no admitiera varios valores de charts de Helm que
  faltaban en el esquema `values_types.proto` del operador. Ahora pueden establecerse los siguientes valores:
  `cni.terminationGracePeriodSeconds`, `cni.updateStrategy`,
  `cni.seLinuxOptions`, `cni.tolerations`, `pilot.initContainers`, `pilot.pdb`,
  `pilot.deploymentAnnotations`, `pilot.sidecarInjectorWebhookAnnotations`,
  `pilot.trustedZtunnelName`, `global.proxy_init.forceApplyIptables` y
  `global.waypoint.tolerations`.

- **Corregido** que `istioctl manifest translate` escribiera valores sin comillas de la entrada de `IstioOperator`
  (como el namespace y el nombre de la release) en los scripts de shell de instalación generados.
  Los valores manipulados podían inyectar comandos de shell adicionales al ejecutar esos scripts.
  Ahora los argumentos se escapan con `shellescape.Quote`.

  Esta vulnerabilidad fue descubierta y reportada por OpenSec Intelligence.

- **Corregido** que `istioctl analyze` produjera falsos errores `ReferencedResourceNotFound` en las referencias de `VirtualService` a recursos `Gateway` de Kubernetes Gateway API.
  ([Issue #60708](https://github.com/istio/istio/issues/60708))
