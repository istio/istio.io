---
title: ISTIO-SECURITY-2026-007
subtitle: Boletín de Seguridad
description: CVEs reportados por Envoy, además de correcciones de seguridad de Istio para un bypass de AuthorizationPolicy por mayúsculas/minúsculas en el método sobre HTTP/2 y una denegación de servicio en istiod en modo ambient.
cves: [CVE-2026-111497]
cvss: "7.7"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:N/I:N/A:H"
releases: ["1.31.0 to 1.31.1", "1.30.0 to 1.30.5", "1.29.0 to 1.29.8"]
publishdate: 2026-10-15
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[GHSA-8vc2-jrm4-835w](https://github.com/envoyproxy/envoy/security/advisories/GHSA-8vc2-jrm4-835w)__: (puntuación CVSS 7.5): Se corrigió una terminación anormal remota sin autenticación (desreferencia de puntero nulo) en el filtro HTTP OAuth2 al procesar una solicitud CONNECT sin cabecera `:path`.
- __[GHSA-47vj-9r25-wv5j](https://github.com/envoyproxy/envoy/security/advisories/GHSA-47vj-9r25-wv5j)__: (puntuación CVSS 6.5): Se corrigió una terminación anormal en el filtro HTTP `api_key_auth` al ocultar credenciales en una solicitud CONNECT sin cabecera `:path`.
- __[CVE-2026-111497](https://nvd.nist.gov/vuln/detail/CVE-2026-111497)__: Se corrigió una vulnerabilidad en la biblioteca de compresión Brotli usada por Envoy. Los usuarios que habiliten la descompresión Brotli, por ejemplo con un `EnvoyFilter`, deben actualizar.
### CVEs de Istio

- __[GHSA-w44g-8m76-8gc5](https://github.com/istio/istio/security/advisories/GHSA-w44g-8m76-8gc5)__ (puntuación CVSS 7.4, Alta): las reglas de método de `AuthorizationPolicy` se eluden sobre HTTP/2 cambiando las mayúsculas/minúsculas del método. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [izzy0101010101](https://github.com/izzy0101010101).
- __[GHSA-7p2q-4xvg-vxc6](https://github.com/istio/istio/security/advisories/GHSA-7p2q-4xvg-vxc6)__ (puntuación CVSS 7.7, Alta): istiod se cae (denegación de servicio) en modo ambient cuando un `ServiceEntry` u otro servicio reclama la dirección de un waypoint con dirección IP. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por [yshch](https://github.com/yshch).

## Reglas de método de `AuthorizationPolicy` eludidas sobre HTTP/2

Una regla `DENY` de `AuthorizationPolicy` con `methods` (o una regla `ALLOW` con `notMethods`) se compilaba a un matcher de `:method` sensible a mayúsculas y minúsculas. Sobre HTTP/2, una solicitud cuyo método difería solo en mayúsculas/minúsculas (por ejemplo `post` en lugar de `POST`) no coincidía con la regla y se reenviaba al workload, eludiendo la política. HTTP/1.1 no está afectado porque el códec rechaza los métodos que no estén en mayúsculas antes de la autorización. Ahora la coincidencia de métodos no distingue entre mayúsculas y minúsculas.

## Denegación de servicio en istiod por colisión de direcciones de waypoint

En modo ambient, istiod resuelve el servicio propietario de un waypoint con dirección IP únicamente por red y dirección IP. Cuando un segundo servicio, como un `ServiceEntry` en cualquier namespace, reclamaba la misma dirección, istiod entraba en pánico y se reiniciaba en bucle hasta que se eliminaba el recurso en colisión. Un usuario con permiso para crear recursos `ServiceEntry` en su propio namespace podía detener la distribución de configuración y la rotación de certificados de toda la mesh. Ahora las direcciones en colisión se omiten con una advertencia.

## ¿Estoy afectado?

- **CVEs de Envoy:** Estás potencialmente afectado si ejecutas una versión afectada de Istio y usas los filtros HTTP OAuth2 o `api_key_auth`, or habilitas la descompresión Brotli.

- **Bypass de método en `AuthorizationPolicy`:** Estás afectado si usas reglas `DENY` de `AuthorizationPolicy` con `methods`, o reglas `ALLOW` con `notMethods`, y los clientes pueden alcanzar el workload sobre HTTP/2. Las políticas que solo usan reglas `ALLOW` con una lista `methods` explícita no están afectadas.

- **Denegación de servicio en istiod:** Estás afectado si ejecutas el modo ambient con un waypoint con dirección IP (por ejemplo, un `Gateway` de waypoint con la anotación `networking.istio.io/address-type: IPAddress`) y usuarios que no son administradores de la mesh pueden crear recursos `ServiceEntry`. Los waypoints que reportan un hostname, que es el comportamiento por defecto, no están afectados.

## Mitigación

- Para usuarios de Istio 1.31: actualiza a **1.31.2** o posterior.
- Para usuarios de Istio 1.30: actualiza a **1.30.6** o posterior.
- Para usuarios de Istio 1.29: actualiza a **1.29.9**. Esta es la última versión de 1.29, ya que [1.29 llegó al fin de su vida útil](/news/support/announcing-1.29-eol/) el 15 de octubre de 2026. Planifica una actualización a 1.30 o posterior.
- Como medida provisional para el bypass de `AuthorizationPolicy`, usa políticas `ALLOW` con una lista de permitidos `methods` explícita en lugar de reglas `DENY` o `notMethods`.
- Como medida provisional para la denegación de servicio en istiod, restringe los permisos de creación y actualización de `ServiceEntry` a administradores de confianza usando RBAC de Kubernetes, o usa waypoints con dirección por hostname.

## Otras correcciones de seguridad de Istio

Esta versión también incluye las siguientes correcciones de seguridad a las que no se les asignaron CVEs. Consulta las notas de la versión de cada release para más detalles.

- `istioctl` ahora verifica el certificado de istiod al conectarse a XDS con un token de service account. **Crédito**: Este problema fue reportado por [Leon Zlobecki](https://leonz.is).
- `istioctl manifest translate` ahora escapa los valores escritos en los scripts de shell de instalación generados. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por OpenSec Intelligence.
- Se corrigió un pánico de istiod cuando el autenticador OIDC/JWT recibía un token con un claim `sub` malformado. **Crédito**: Este problema fue reportado por Kaizhe Huang.
- Se reforzó la ruta experimental de RA de CSR de Kubernetes (`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`): errores opacos hacia los llamadores, un bucle de watch acotado y un nuevo límite `MAX_RA_WORKLOAD_CERT_TTL`. **Crédito**: Este problema fue reportado por Juno Im.
- El descargador de imágenes OCI de Wasm ya no recurre a HTTP en texto plano para registries que no están listados en `WASM_INSECURE_REGISTRIES`. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por Adam Korczynski.
- Los endpoints de depuración de istiod ahora requieren una coincidencia exacta de `proxyID`. **Crédito**: Este problema fue reportado por 박현범.
- Se agregó `PILOT_ENABLE_STRICT_GATEWAY_MERGING` a 1.29 y 1.30 para evitar la fusión entre namespaces de recursos `Gateway` de Istio con gateways administrados de Gateway API. Está deshabilitado por defecto en 1.29 y 1.30, y habilitado por defecto a partir de 1.31.
