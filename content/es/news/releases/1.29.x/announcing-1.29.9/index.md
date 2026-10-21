---
title: Anuncio de Istio 1.29.9
linktitle: 1.29.9
subtitle: Versión de Parche
description: Parche de Istio 1.29.9.
publishdate: 2026-10-15
release: 1.29.9
aliases:
    - /news/announcing-1.29.9
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.29.8 e Istio 1.29.9. Esta es la última versión de 1.29, ya que [1.29 alcanzó el fin de su vida útil](/news/support/announcing-1.29-eol/) el 15 de octubre de 2026. Te recomendamos actualizar a una versión compatible.

{{< relnote >}}

## Actualización de seguridad

Para más información, consulta [ISTIO-SECURITY-2026-007](/news/security/istio-security-2026-007).

### CVEs de Envoy

- __[GHSA-8vc2-jrm4-835w](https://github.com/envoyproxy/envoy/security/advisories/GHSA-8vc2-jrm4-835w)__: (puntuación CVSS 7.5): Corregida una terminación anormal remota sin autenticación en el filtro HTTP OAuth2 ante una solicitud CONNECT sin cabecera `:path`.
- __[GHSA-47vj-9r25-wv5j](https://github.com/envoyproxy/envoy/security/advisories/GHSA-47vj-9r25-wv5j)__: (puntuación CVSS 6.5): Corregida una terminación anormal en el filtro HTTP `api_key_auth` ante una solicitud CONNECT sin cabecera `:path`.
- __[CVE-2026-111497](https://nvd.nist.gov/vuln/detail/CVE-2026-111497)__: Se corrigió una vulnerabilidad en la biblioteca de compresión Brotli usada por Envoy. Los usuarios que habiliten la descompresión Brotli, por ejemplo con un `EnvoyFilter`, deben actualizar.
### CVEs de Istio

- __[GHSA-w44g-8m76-8gc5](https://github.com/istio/istio/security/advisories/GHSA-w44g-8m76-8gc5)__ (puntuación CVSS 7.4, Alta): Las reglas de método de `AuthorizationPolicy` se eluden sobre HTTP/2 al cambiar entre mayúsculas y minúsculas en el método. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [izzysec](https://github.com/izzysec).
- __[GHSA-7p2q-4xvg-vxc6](https://github.com/istio/istio/security/advisories/GHSA-7p2q-4xvg-vxc6)__ (puntuación CVSS 7.7, Alta): istiod termina de forma anormal en modo ambient cuando un `ServiceEntry` u otro servicio reclama la dirección de un waypoint con dirección IP. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [yshch](https://github.com/yshch).

### Otras correcciones de seguridad de Istio

- **Corregido** que `istioctl` omitiera la verificación del certificado de istiod al conectarse a XDS con un token de service account (`istioctl proxy-status`, `istioctl x internal-debug` y `--xds-address` en general). Ahora istioctl verifica el servidor con el certificado raíz de Istio del configmap `istio-ca-root-cert` y el nombre de servidor esperado: `--authority` si está definido, el host de `--xds-address` si es un nombre DNS, o `istiod.<istio-namespace>.svc` al conectarse a una dirección IP o a localhost. Usa `--insecure` (o define `ISTIOCTL_INSECURE=true`) para omitir la verificación de forma explícita. **Crédito**: Este problema fue reportado por [Leon Zlobecki](https://leonz.is). ([Issue #41937](https://github.com/istio/istio/issues/41937))

- **Corregido** que `istioctl manifest translate` escribiera valores sin comillas de la entrada de IstioOperator (como el namespace y el nombre de la versión) en los scripts de shell de instalación generados. Valores manipulados podían inyectar comandos de shell adicionales al ejecutar esos scripts. Los argumentos ahora se escapan con `shellescape.Quote`. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por OpenSec Intelligence.

- **Corregido** un panic en istiod cuando el autenticador OIDC/JWT recibía un token con un claim `sub` mal formado. Ahora se valida que el sujeto tenga exactamente la forma `system:serviceaccount:<namespace>:<serviceaccount>` antes de usarlo. **Crédito**: Este problema fue reportado por Kaizhe Huang.

- **Corregido** que `CreateCertificate` devolviera a los llamadores el texto sin procesar de los errores de la API de Kubernetes en la ruta experimental de RA de CSR de Kubernetes (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`), lo que filtraba nombres de CSR, nombres de firmantes y la identidad de istiod. Ahora el error completo solo se registra en el lado del servidor. Reportado por Juno Im.

- **Corregido** que el bucle de observación de CSR de Kubernetes usara un temporizador `time.After` abandonado que podía dejar una goroutine en ejecución tras completarse la solicitud en la ruta experimental de RA de CSR de Kubernetes (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`). Ahora el bucle está acotado por un `context.WithTimeout` con el ámbito adecuado y se detiene de forma fiable ante un timeout o una cancelación. Reportado por Juno Im.

- **Corregido** que se aceptara un `ValidityDuration` solicitado por el cliente de hasta `MAX_WORKLOAD_CERT_TTL` (por defecto `90d`) en la ruta experimental de RA de CSR de Kubernetes (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`). Una nueva variable de entorno `MAX_RA_WORKLOAD_CERT_TTL` (por defecto `48h`) ahora limita el TTL, reduciendo el alcance del daño de un istio-token robado. Los despliegues que solicitaban legítimamente certificados con TTL > `48h` por esta ruta deben aumentar `MAX_RA_WORKLOAD_CERT_TTL` tras la actualización. Reportado por Juno Im.

- **Corregido** que el recuperador de imágenes OCI de Wasm decidiera reintentar una descarga HTTPS fallida mediante HTTP en texto plano según el error devuelto por el registro. Dado que el registro es una entrada no confiable, un MITM o un registro malicioso podía activar este fallback a demanda para forzar el transporte en texto plano y, sin un digest de módulo opcional fijado, servir un binario Wasm arbitrario. Ahora el reintento en texto plano solo se intenta para los registros que el operador ha permitido explícitamente mediante `WASM_INSECURE_REGISTRIES`. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por Adam Korczynski.

- **Corregido** que los endpoints de depuración de istiod (`/debug/config_dump`, `/debug/edsz` y el tipo XDS `istio.io/debug/config_dump`) coincidieran con `proxyID` como una subcadena, lo que permitía a un llamador leer la configuración de otros proxies de su propio namespace pasando un ID parcial. Ahora `proxyID` debe ser exactamente `<pod>.<namespace>` (o el ID de conexión completo); las formas cortas como `proxyID=istio-ingressgateway` ya no coinciden. **Crédito**: Este problema fue reportado por 박현범.

- **Mejorado**: Añadido `PILOT_ENABLE_STRICT_GATEWAY_MERGING` para evitar la fusión entre namespaces de los Gateways de Istio con los Gateways de `GatewayAPI` gestionados. Cuando está habilitado, los CRDs de Gateway de Istio de diferentes namespaces no se fusionarán con los proxies de Gateway de `GatewayAPI` gestionados. Los Gateways de `GatewayAPI` no gestionados (despliegue manual) no se ven afectados. Está deshabilitado por defecto en esta versión; define `PILOT_ENABLE_STRICT_GATEWAY_MERGING` como `true` para habilitarlo.

## Cambios

- **Corregido** que una regla de `HTTPRoute` con varios `backendRefs` de `InferencePool` configurara un solo endpoint picker. El picker del último `backendRef` de la lista puntuaba todas las solicitudes de la regla, por lo que los pickers de los demás pools nunca se invocaban, y un pool sin endpoints listos hacía fallar toda la regla en lugar de solo su parte ponderada. Ahora cada pool tiene su propio picker, asociado a su propio clúster ponderado. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregido** que dos `HTTPRoute`s que compartían un `rules[].name` en el mismo gateway se sobrescribieran mutuamente el endpoint picker. Los nombres de regla solo tienen que ser únicos dentro de un mismo `HTTPRoute`, pero los pickers se indexaban por nombre entre todos ellos, de modo que una ruta podía ser atendida por el picker de otra. Ahora los pickers se resuelven por `backendRef`, así que un nombre compartido ya no traslada el picker de una ruta a otra. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregido** que una regla de ruta perdiera su endpoint picker de `InferencePool` cuando también incluía un filtro CORS. Ambos se escriben en la misma configuración por filtro, y la ruta de CORS reemplazaba el mapa en lugar de añadirle elementos. ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **Corregida** la resolución de UID/GID del proxy sidecar en OpenShift para workloads vinculados a una `SecurityContextConstraint` personalizada con un rango de UID estrecho o configurado explícitamente, que la anotación de rango de UID preasignado del namespace no anuncia. ([Issue #61791](https://github.com/istio/istio/issues/61791))

- **Añadida** una advertencia de validación para direcciones de `ServiceEntry` que sean catch-all (`0.0.0.0`, `::`), tengan una red no especificada (`0.0.0.0/N`, `::/N`) o sean un CIDR con un prefijo más corto que `/8`. Un `ServiceEntry` así con `resolution: NONE` y el `exportTo` por defecto puede hacer que todos los sidecars de la mesh dejen pasar el tráfico en sus puertos, eludiendo `outboundTrafficPolicy` `REGISTRY_ONLY`. Usa un CIDR más estrecho y `exportTo: ["."]`. Para aplicar el control de egress, usa un egress gateway con una NetworkPolicy. ([Issue #62124](https://github.com/istio/istio/issues/62124))

- **Corregido** un problema por el cual el workload pre-serializado usado para la detección de cambios y el versionado en ambient no era estable cuando un workload tenía más de un servicio, lo que hacía que workloads sin cambios parecieran modificados en cada recálculo e impedía omitir los workloads sin cambios cuando un cliente se reconectaba.

- **Corregida** una fuga de memoria y de goroutines en el modo multiclúster ambient de Istiod, donde las colecciones de localidad de nodo por clúster tenían el ámbito de la vida del proceso en lugar de la del clúster, por lo que nunca se liberaban al eliminar un clúster remoto. ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Corregido** un error por el cual se creaba incorrectamente un listener interno cuando el listener era HTTPS o TLS pero sin una sección TLS definida. Una versión posterior de la Gateway API [impedirá](https://github.com/kubernetes-sigs/gateway-api/pull/4788) que esta combinación de entradas llegue a un controlador. ([Issue #60562](https://github.com/istio/istio/issues/60562))

- **Corregida** una fuga de memoria en el modo multiclúster ambient, donde las colecciones se registraban en el depurador de krt pero nunca se eliminaban del registro cuando se quitaba un clúster remoto o cambiaba su configuración, causando que los registros del depurador se acumularan con el tiempo. ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Corregido** que los componentes de Istio se quedaran bloqueados indefinidamente cuando una solicitud a la API de Kubernetes no recibía respuesta, por ejemplo cuando un load balancer o proxy descarta silenciosamente la ruta de retorno. Antes, una solicitud así podía permanecer abierta para siempre, bloqueando el controlador que la emitió hasta que se reiniciara el proceso. Ahora las solicitudes expiran en el lado del cliente, de modo que una solicitud atascada se cancela y el componente se recupera por sí solo. Cada timeout se registra como advertencia y se contabiliza en la métrica `kube_client_deadline_fired_total`. Los timeouts se pueden ajustar con `ISTIO_KUBE_HEADER_TIMEOUT` (por defecto `90s`) e `ISTIO_KUBE_REQUEST_TIMEOUT` (por defecto `15m`); define cualquiera de ellos como `0` para restaurar el comportamiento anterior sin límite.

- **Corregido** que ztunnel entrara en crash-loop con código de salida 133 (`SIGTRAP`) en nodos arm64 cuyas CPUs proporcionan la instrucción `RNDR`, como GKE Axion, cuando el generador de números aleatorios por hardware reportaba un fallo transitorio. Se actualiza `aws-lc-rs` a 1.18.2, que reintenta la lectura en lugar de abortar. ([Issue #2072](https://github.com/istio/ztunnel/issues/2072))
