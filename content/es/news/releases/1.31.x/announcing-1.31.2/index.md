---
title: Anuncio de Istio 1.31.2
linktitle: 1.31.2
subtitle: Versión de Parche
description: Parche de Istio 1.31.2.
publishdate: 2026-10-15
release: 1.31.2
aliases:
    - /news/announcing-1.31.2
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.31.1 e Istio 1.31.2.

{{< relnote >}}

## Actualización de seguridad

Para más información, consulta [ISTIO-SECURITY-2026-007](/news/security/istio-security-2026-007).

### CVEs de Envoy

- __[GHSA-8vc2-jrm4-835w](https://github.com/envoyproxy/envoy/security/advisories/GHSA-8vc2-jrm4-835w)__: (puntuación CVSS 7.5): Corregida una terminación anormal remota sin autenticación en el filtro HTTP OAuth2 ante una solicitud CONNECT sin cabecera `:path`.
- __[GHSA-47vj-9r25-wv5j](https://github.com/envoyproxy/envoy/security/advisories/GHSA-47vj-9r25-wv5j)__: (puntuación CVSS 6.5): Corregida una terminación anormal en el filtro HTTP `api_key_auth` ante una solicitud CONNECT sin cabecera `:path`.

### CVEs de Istio

- __[GHSA-w44g-8m76-8gc5](https://github.com/istio/istio/security/advisories/GHSA-w44g-8m76-8gc5)__ (puntuación CVSS 7.4, Alta): las reglas de método de `AuthorizationPolicy` se eluden sobre HTTP/2 al cambiar entre mayúsculas y minúsculas en el método. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [izzy0101010101](https://github.com/izzy0101010101).
- __[GHSA-7p2q-4xvg-vxc6](https://github.com/istio/istio/security/advisories/GHSA-7p2q-4xvg-vxc6)__ (puntuación CVSS 7.7, Alta): istiod termina de forma anormal en modo ambient cuando un `ServiceEntry` u otro servicio reclama la dirección de un waypoint con dirección IP. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [yshch](https://github.com/yshch).

### Otras correcciones de seguridad de Istio

- **Corregido** `istioctl` omitiendo la verificación del certificado de istiod al conectarse a XDS con un token de service account (`istioctl proxy-status`, `istioctl x internal-debug` y `--xds-address` en general). Ahora istioctl verifica el servidor contra el certificado raíz de Istio del configmap `istio-ca-root-cert` y el nombre de servidor esperado: `--authority` si está definido, el host de `--xds-address` si es un nombre DNS, o `istiod.<istio-namespace>.svc` al conectarse a una dirección IP o a localhost. Pasa `--insecure` (o define `ISTIOCTL_INSECURE=true`) para omitir explícitamente la verificación. **Crédito**: Este problema fue reportado por [Leon Zlobecki](https://leonz.is). ([Issue #41937](https://github.com/istio/istio/issues/41937))

- **Corregido** `istioctl manifest translate` escribiendo valores sin comillas de la entrada de IstioOperator (como el namespace y el nombre de la versión) en los scripts de shell de instalación generados. Unos valores manipulados podían inyectar comandos de shell adicionales al ejecutar esos scripts. Ahora los argumentos se escapan con `shellescape.Quote`. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por OpenSec Intelligence.

- **Corregido** un panic en istiod cuando el autenticador OIDC/JWT recibía un token con un claim `sub` malformado. Ahora se valida que el sujeto tenga exactamente la forma `system:serviceaccount:<namespace>:<serviceaccount>` antes de usarlo. **Crédito**: Este problema fue reportado por Kaizhe Huang.

- **Corregido** `CreateCertificate` devolviendo a los llamantes el texto sin procesar de los errores de la API de Kubernetes en la ruta experimental de Kubernetes CSR RA (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`), lo que filtraba nombres de CSR, nombres de firmantes y la identidad de istiod. Ahora el error completo se registra solo en el lado del servidor. Reportado por Juno Im.

- **Corregido** el bucle de observación de CSR de Kubernetes que usaba un temporizador `time.After` abandonado, el cual podía dejar una goroutine ejecutándose tras finalizar la solicitud en la ruta experimental de Kubernetes CSR RA (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`). Ahora el bucle está acotado por un `context.WithTimeout` con el alcance adecuado y se libera de forma fiable ante un timeout o una cancelación. Reportado por Juno Im.

- **Corregido** que se aceptara un `ValidityDuration` solicitado por el cliente de hasta `MAX_WORKLOAD_CERT_TTL` (por defecto `90d`) en la ruta experimental de Kubernetes CSR RA (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`). Una nueva variable de entorno `MAX_RA_WORKLOAD_CERT_TTL` (por defecto `48h`) ahora limita el TTL, reduciendo el radio de impacto de un istio-token robado. Los despliegues que solicitaban legítimamente certificados con un TTL > `48h` por esta ruta deben aumentar `MAX_RA_WORKLOAD_CERT_TTL` tras la actualización. Reportado por Juno Im.

- **Corregido** que el cargador de imágenes OCI de Wasm decidiera reintentar una obtención HTTPS fallida mediante HTTP en texto plano según el error devuelto por el registro. Dado que el registro es una entrada no confiable, un MITM o un registro malicioso podía desencadenar este fallback a demanda para forzar el transporte en texto plano y, sin un digest de módulo opcional fijado, servir un binario Wasm arbitrario. Ahora el reintento en texto plano solo se intenta para los registros que el operador ha permitido explícitamente mediante `WASM_INSECURE_REGISTRIES`. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por Adam Korczynski.

- **Corregido** que los endpoints de depuración de istiod (`/debug/config_dump`, `/debug/edsz` y el tipo XDS `istio.io/debug/config_dump`) hicieran coincidir `proxyID` como una subcadena, lo que permitía a un llamante leer la configuración de otros proxies de su propio namespace pasando un ID parcial. Ahora `proxyID` debe ser exactamente `<pod>.<namespace>` (o el ID de conexión completo); las formas cortas como `proxyID=istio-ingressgateway` ya no coinciden. **Crédito**: Este problema fue reportado por 박현범.

## Cambios

- **Añadido** soporte para límites de búfer de conexión a nivel de clúster (`clusterPerConnectionBufferLimitBytes`) mediante `connectionSettings` en `ProxyConfig`, incluidos los valores por defecto del perfil `EDGE` para los proxies de gateway.

- **Añadido** soporte para `globalDownstreamConnectionLimit` en `ProxyConfig.connectionSettings`, que ofrece un campo de API de primera clase para configurar el límite global de conexiones downstream. Tiene prioridad sobre los metadatos existentes `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS` y sobre el flag de runtime obsoleto `overload.global_downstream_max_connections`. ([Issue #57973](https://github.com/istio/istio/issues/57973))

- **Mejorado** el procesamiento incremental de EDS para los cambios en `DestinationRule`, de modo que identifica los servicios afectados mediante el alcance del sidecar, alineándolo con CDS y evitando búsquedas de `DestinationRule` por clúster.

- **Corregido** un problema donde una regla de `HTTPRoute` con varios `backendRefs` de `InferencePool` configuraba un solo endpoint picker. El picker del último `backendRef` listado puntuaba todas las solicitudes de la regla, por lo que los pickers de los demás pools nunca se invocaban, y un pool sin endpoints listos hacía fallar toda la regla en lugar de solo su parte ponderada. Ahora cada pool tiene su propio picker, asociado a su propio clúster ponderado. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregido** un problema donde dos `HTTPRoute`s que compartían un `rules[].name` en el mismo gateway sobrescribían el endpoint picker del otro. Los nombres de regla solo tienen que ser únicos dentro de un mismo `HTTPRoute`, pero los pickers se indexaban por nombre entre todos ellos, por lo que una ruta podía ser atendida por el picker de otra. Ahora los pickers se resuelven por `backendRef`, de modo que un nombre compartido ya no traslada el picker de una ruta a otra. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregido** un problema donde una regla de ruta perdía su endpoint picker de `InferencePool` cuando también incluía un filtro CORS. Ambos se escriben en la misma configuración por filtro, y la ruta de CORS reemplazaba el mapa en lugar de añadirle entradas. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregida** la resolución de UID/GID del proxy sidecar en OpenShift para workloads vinculados a una `SecurityContextConstraint` personalizada con un rango de UID estrecho o configurado explícitamente, que la anotación del rango de UID preasignado del namespace no anuncia. ([Issue #61791](https://github.com/istio/istio/issues/61791))

- **Corregida** la inicialización concurrente del contexto de push cuando el debouncing de EDS está deshabilitado. ([Issue #61924](https://github.com/istio/istio/issues/61924))

- **Corregido** un problema donde, con `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` habilitado, los pushes incrementales de CDS eliminaban los clústeres de gateway de los Services listados en la anotación `envoyfilter.istio.io/referenced-services` de un `EnvoyFilter`. Estos clústeres solo se restauraban en el siguiente push completo. ([Issue #62067](https://github.com/istio/istio/issues/62067))

- **Añadida** una advertencia de validación para las direcciones de `ServiceEntry` que sean catch-all (`0.0.0.0`, `::`), tengan una red no especificada (`0.0.0.0/N`, `::/N`) o sean un CIDR con un prefijo menor que `/8`. Un `ServiceEntry` así con `resolution: NONE` y el `exportTo` por defecto puede hacer que todos los sidecars de la mesh dejen pasar el tráfico en sus puertos, eludiendo `outboundTrafficPolicy` `REGISTRY_ONLY`. Usa un CIDR más estrecho y `exportTo: ["."]`. Para el control del tráfico de salida, usa un egress gateway con una NetworkPolicy. ([Issue #62124](https://github.com/istio/istio/issues/62124))

- **Corregido** un problema donde el workload pre-serializado usado para la detección de cambios y el versionado en ambient no era estable cuando un workload tenía más de un servicio, lo que hacía que los workloads sin cambios parecieran modificados en cada recálculo e impedía omitirlos cuando un cliente se reconectaba.

- **Corregido** un problema donde el gateway de red seleccionado para un workload se elegía en orden aleatorio cuando una red tenía más de una entrada de gateway, lo que provocaba pushes de workload (WDS) innecesarios en cada recálculo y podía alternar la dirección del gateway que usa un workload.

- **Corregido** el filtrado de dependencias de configuración para los gateways, de modo que excluya las actualizaciones de configuración no relacionadas. Además, la construcción del alcance del gateway omite la recopilación de `VirtualServices` de la mesh usados únicamente para el enrutamiento de waypoint.

- **Corregido** que eliminar un único manejador de eventos de un informer respaldado por CRD eliminara todos los manejadores de ese informer. En modo multiclúster ambient esto ocurría en cada rotación de credenciales de un clúster remoto, dejando a istiod esperando indefinidamente a que las colecciones del nuevo clúster se sincronizaran, por lo que desaparecían los gateways de red remotos y el índice de workloads podía dejar de actualizarse hasta un reinicio. ([Issue #61827](https://github.com/istio/istio/issues/61827))

- **Corregido** que los componentes de Istio se quedaran colgados indefinidamente cuando una solicitud a la API de Kubernetes no recibe respuesta, por ejemplo cuando un balanceador de carga o un proxy descarta silenciosamente la ruta de retorno. Antes, una solicitud así podía permanecer abierta para siempre, bloqueando al controlador que la emitió hasta que el proceso se reiniciara. Ahora las solicitudes expiran en el lado del cliente, de modo que una solicitud atascada se cancela y el componente se recupera por sí solo. Cada timeout se registra como advertencia y se contabiliza en la métrica `kube_client_deadline_fired_total`. Los timeouts se pueden ajustar con `ISTIO_KUBE_HEADER_TIMEOUT` (por defecto `90s`) y `ISTIO_KUBE_REQUEST_TIMEOUT` (por defecto `15m`); establece cualquiera de ellos en `0` para restaurar el comportamiento anterior sin límite.

- **Corregido** un problema donde las actualizaciones de configuración irrelevantes para EDS, combinadas con una actualización de endpoints, causaban una generación completa de EDS en lugar de actualizar solo las asignaciones de endpoints afectadas.

- **Corregida** una regresión que impedía que los pushes de WDS omitieran el debouncing, mediante la adición de la variable de entorno `PILOT_ENABLE_WDS_DEBOUNCE`, habilitada por defecto. Establécela en `false` para permitir que los pushes de WDS omitan el debouncing de forma independiente de los pushes de EDS. ([Issue #62125](https://github.com/istio/istio/issues/62125))

- **Corregido** el crash-looping de ztunnel con el código de salida 133 (`SIGTRAP`) en nodos arm64 cuyas CPUs proporcionan la instrucción `RNDR`, como GKE Axion, cuando el generador de números aleatorios por hardware reportaba un fallo transitorio. Se actualiza `aws-lc-rs` a la versión 1.18.2, que reintenta la lectura en lugar de abortar. ([Issue #2072](https://github.com/istio/ztunnel/issues/2072))
