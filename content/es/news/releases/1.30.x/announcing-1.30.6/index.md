---
title: Anuncio de Istio 1.30.6
linktitle: 1.30.6
subtitle: Versión de Parche
description: Parche de Istio 1.30.6.
publishdate: 2026-10-15
release: 1.30.6
aliases:
    - /news/announcing-1.30.6
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.30.5 e Istio 1.30.6.

{{< relnote >}}

## Actualización de seguridad

Para más información, consulta [ISTIO-SECURITY-2026-007](/news/security/istio-security-2026-007).

### CVEs de Envoy

- __[GHSA-8vc2-jrm4-835w](https://github.com/envoyproxy/envoy/security/advisories/GHSA-8vc2-jrm4-835w)__: (puntuación CVSS 7.5): Corregida una terminación anormal remota sin autenticación en el filtro HTTP de OAuth2 ante una solicitud CONNECT sin cabecera `:path`.
- __[GHSA-47vj-9r25-wv5j](https://github.com/envoyproxy/envoy/security/advisories/GHSA-47vj-9r25-wv5j)__: (puntuación CVSS 6.5): Corregida una terminación anormal en el filtro HTTP `api_key_auth` ante una solicitud CONNECT sin cabecera `:path`.

### CVEs de Istio

- __[GHSA-w44g-8m76-8gc5](https://github.com/istio/istio/security/advisories/GHSA-w44g-8m76-8gc5)__ (puntuación CVSS 7.4, Alta): Las reglas de método de `AuthorizationPolicy` se eluden sobre HTTP/2 al cambiar entre mayúsculas y minúsculas en el método. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [izzy0101010101](https://github.com/izzy0101010101).
- __[GHSA-7p2q-4xvg-vxc6](https://github.com/istio/istio/security/advisories/GHSA-7p2q-4xvg-vxc6)__ (puntuación CVSS 7.7, Alta): istiod termina de forma anormal en modo ambient cuando un `ServiceEntry` u otro servicio reclama la dirección de un waypoint con dirección IP. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [yshch](https://github.com/yshch).

### Otras correcciones de seguridad de Istio

- **Corregido** `istioctl` omitiendo la verificación del certificado de istiod al conectarse a XDS con un token de service account (`istioctl proxy-status`, `istioctl x internal-debug` y `--xds-address` en general). Ahora istioctl verifica el servidor contra el certificado raíz de Istio del configmap `istio-ca-root-cert` y el nombre de servidor esperado: `--authority` si está definido, el host de `--xds-address` si es un nombre DNS, o `istiod.<istio-namespace>.svc` al conectarse a una dirección IP o a localhost. Pasa `--insecure` (o define `ISTIOCTL_INSECURE=true`) para omitir explícitamente la verificación. **Crédito**: Este problema fue reportado por [Leon Zlobecki](https://leonz.is). ([Issue #41937](https://github.com/istio/istio/issues/41937))

- **Corregido** `istioctl manifest translate` escribiendo valores sin comillas de la entrada de IstioOperator (como el namespace y el nombre de la release) en los scripts de shell de instalación generados. Valores manipulados podían inyectar comandos de shell adicionales al ejecutar esos scripts. Ahora los argumentos se escapan con `shellescape.Quote`. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por OpenSec Intelligence.

- **Corregido** un panic en istiod cuando el autenticador OIDC/JWT recibía un token con un claim `sub` mal formado. Ahora se valida que el subject tenga exactamente la forma `system:serviceaccount:<namespace>:<serviceaccount>` antes de usarlo. **Crédito**: Este problema fue reportado por Kaizhe Huang.

- **Corregido** `CreateCertificate` devolviendo a los llamadores el texto de error sin procesar de la API de Kubernetes en la ruta experimental de RA de CSR de Kubernetes (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`), lo que filtraba nombres de CSR, nombres de firmantes y la identidad de istiod. Ahora el error completo se registra solo en el servidor. Reportado por Juno Im.

- **Corregido** el bucle de observación de CSR de Kubernetes que usaba un temporizador `time.After` abandonado, el cual podía dejar una goroutine en ejecución tras completarse la solicitud en la ruta experimental de RA de CSR de Kubernetes (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`). Ahora el bucle está acotado por un `context.WithTimeout` con el ámbito adecuado y se detiene de forma fiable ante un timeout o una cancelación. Reportado por Juno Im.

- **Corregido** que el `ValidityDuration` solicitado por el cliente se aceptara hasta `MAX_WORKLOAD_CERT_TTL` (por defecto `90d`) en la ruta experimental de RA de CSR de Kubernetes (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`). Ahora una nueva variable de entorno `MAX_RA_WORKLOAD_CERT_TTL` (por defecto `48h`) limita el TTL, reduciendo el impacto del robo de un istio-token. Los despliegues que solicitaban legítimamente certificados con un TTL superior a `48h` por esta ruta deben aumentar `MAX_RA_WORKLOAD_CERT_TTL` tras la actualización. Reportado por Juno Im.

- **Corregido** que el cliente de imágenes OCI de Wasm decidiera reintentar por HTTP en texto plano una obtención HTTPS fallida en función del error devuelto por el registro. Dado que el registro es una entrada no confiable, un MITM o un registro malicioso podía activar este fallback a demanda para forzar el transporte en texto plano y, sin un digest de módulo opcional fijado, servir un binario Wasm arbitrario. Ahora el reintento en texto plano solo se intenta para los registros que el operador haya incluido explícitamente en la lista de permitidos mediante `WASM_INSECURE_REGISTRIES`. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por Adam Korczynski.

- **Corregidos** los endpoints de depuración de istiod (`/debug/config_dump`, `/debug/edsz` y el tipo XDS `istio.io/debug/config_dump`) que hacían coincidir `proxyID` como subcadena, lo que permitía a un llamador leer la configuración de otros proxies de su propio namespace pasando un ID parcial. Ahora `proxyID` debe ser exactamente `<pod>.<namespace>` (o el ID de conexión completo); formas abreviadas como `proxyID=istio-ingressgateway` ya no coinciden. **Crédito**: Este problema fue reportado por 박현범.

- **Mejorado** Añadido `PILOT_ENABLE_STRICT_GATEWAY_MERGING` para evitar la fusión entre namespaces de Gateways de Istio con Gateways de `GatewayAPI` gestionados. Cuando está habilitado, los CRDs de Gateway de Istio de distintos namespaces no se fusionarán con los proxies de Gateway de `GatewayAPI` gestionados. Los Gateways de `GatewayAPI` no gestionados (despliegue manual) no se ven afectados. Deshabilitado por defecto; define `PILOT_ENABLE_STRICT_GATEWAY_MERGING` como `true` para habilitarlo. Habilitado por defecto a partir de la 1.31.

## Cambios

- **Corregida** una regla de `HTTPRoute` con varios `backendRefs` de `InferencePool` que configuraba un único endpoint picker. El picker del último `backendRef` listado puntuaba todas las solicitudes de la regla, por lo que los pickers de los demás pools nunca se invocaban, y un pool sin endpoints listos hacía fallar la regla completa en lugar de solo su parte ponderada. Ahora cada pool tiene su propio picker, asociado a su propio clúster ponderado. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregido** que dos `HTTPRoute`s con el mismo `rules[].name` en el mismo gateway se sobrescribieran mutuamente el endpoint picker. Los nombres de regla solo tienen que ser únicos dentro de un `HTTPRoute`, pero los pickers se indexaban por nombre entre todos ellos, de modo que una ruta podía ser atendida por el picker de otra. Ahora los pickers se resuelven por `backendRef`, de modo que un nombre compartido ya no traslada el picker de una ruta a otra. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregido** que una regla de ruta perdiera su endpoint picker de `InferencePool` cuando también tenía un filtro CORS. Ambos se escriben en la misma configuración por filtro, y la ruta de CORS reemplazaba el mapa en lugar de añadirle entradas. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregida** la resolución de UID/GID del proxy sidecar en OpenShift para workloads vinculados a un `SecurityContextConstraint` personalizado con un rango de UID estrecho o configurado explícitamente, que la anotación del rango de UID preasignado del namespace no anuncia. ([Issue #61791](https://github.com/istio/istio/issues/61791))

- **Corregido** un problema donde, con `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` habilitado, los push incrementales de CDS eliminaban los clústeres de gateway de los Services listados en la anotación `envoyfilter.istio.io/referenced-services` de un `EnvoyFilter`. Estos clústeres solo se restauraban en el siguiente push completo. ([Issue #62067](https://github.com/istio/istio/issues/62067))

- **Añadida** una advertencia de validación para las direcciones de `ServiceEntry` que son catch-all (`0.0.0.0`, `::`), tienen una red no especificada (`0.0.0.0/N`, `::/N`) o son un CIDR con un prefijo menor que `/8`. Un `ServiceEntry` así con `resolution: NONE` y el `exportTo` por defecto puede hacer que todos los sidecars de la mesh dejen pasar el tráfico en sus puertos, eludiendo `outboundTrafficPolicy` `REGISTRY_ONLY`. Usa un CIDR más estrecho y `exportTo: ["."]`. Para forzar el cumplimiento del egress, usa un egress gateway con una NetworkPolicy. ([Issue #62124](https://github.com/istio/istio/issues/62124))

- **Corregido** un problema donde el workload preserializado usado para la detección de cambios y el versionado en ambient no era estable cuando un workload tenía más de un servicio, lo que hacía que workloads sin cambios parecieran modificados en cada recálculo e impedía omitir los workloads sin cambios cuando un cliente se reconectaba.

- **Corregido** un error donde se creaba incorrectamente un listener interno cuando el listener es de tipo HTTPS o TLS pero sin una sección TLS definida. Una versión posterior de la Gateway API [impedirá](https://github.com/kubernetes-sigs/gateway-api/pull/4788) que esta combinación de entradas llegue a un controlador. ([Issue #60562](https://github.com/istio/istio/issues/60562))

- **Corregido** que eliminar un único manejador de eventos de un informer respaldado por un CRD eliminara todos los manejadores de ese informer. En modo ambient multiclúster, esto ocurría en cada rotación de credenciales de un clúster remoto, dejando a istiod esperando indefinidamente a que se sincronizaran las colecciones del nuevo clúster, de modo que los network gateways remotos desaparecían y el índice de workloads podía dejar de actualizarse hasta un reinicio. ([Issue #61827](https://github.com/istio/istio/issues/61827))

- **Corregido** que los componentes de Istio se quedaran bloqueados indefinidamente cuando una solicitud a la API de Kubernetes no recibe respuesta, por ejemplo cuando un balanceador de carga o un proxy descarta silenciosamente la ruta de retorno. Anteriormente, una solicitud así podía permanecer abierta para siempre, bloqueando al controlador que la emitió hasta que el proceso se reiniciara. Ahora las solicitudes caducan en el lado del cliente, de modo que una solicitud atascada se cancela y el componente se recupera por sí solo. Cada timeout se registra como advertencia y se contabiliza en la métrica `kube_client_deadline_fired_total`. Los timeouts se pueden ajustar con `ISTIO_KUBE_HEADER_TIMEOUT` (por defecto `90s`) e `ISTIO_KUBE_REQUEST_TIMEOUT` (por defecto `15m`); define cualquiera de ellos como `0` para restaurar el comportamiento anterior sin límite.

- **Corregido** un problema donde las actualizaciones de configuración irrelevantes para EDS, combinadas con una actualización de endpoints, provocaban una generación completa de EDS en lugar de actualizar solo las asignaciones de endpoints afectadas.

- **Corregido** ztunnel entrando en un bucle de fallos con código de salida 133 (`SIGTRAP`) en nodos arm64 cuyas CPUs proporcionan la instrucción `RNDR`, como GKE Axion, cuando el generador de números aleatorios por hardware reportaba un fallo transitorio. Se actualiza `aws-lc-rs` a 1.18.2, que reintenta la lectura en lugar de abortar. ([Issue #2072](https://github.com/istio/ztunnel/issues/2072))
