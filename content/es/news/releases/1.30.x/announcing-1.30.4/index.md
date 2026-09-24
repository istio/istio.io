---
title: Anuncio de Istio 1.30.4
linktitle: 1.30.4
subtitle: Versión de Parche
description: Parche de Istio 1.30.4.
publishdate: 2026-08-27
release: 1.30.4
aliases:
    - /news/announcing-1.30.4
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.30.3 e Istio 1.30.4.

{{< relnote >}}

## Actualización de seguridad

Para más información, consulta [ISTIO-SECURITY-2026-006](/news/security/istio-security-2026-006).

### CVEs de Envoy

- __[CVE-2026-73513](https://nvd.nist.gov/vuln/detail/CVE-2026-73513)__: (puntuación CVSS 7.5): Corregido un heap use-after-free en `oghttp2` cuando se reciben trailers HTTP/2 sin el flag `END_STREAM`.
- __[CVE-2026-73552](https://nvd.nist.gov/vuln/detail/CVE-2026-73552)__: (puntuación CVSS 7.5): Corregido un error donde `safe_regex` fallaba en modo fail-open ante bytes de cabecera no UTF-8 en políticas RBAC de coincidencia negativa.
- __[CVE-2026-73512](https://nvd.nist.gov/vuln/detail/CVE-2026-73512)__: (puntuación CVSS 7.5): Corregido un use-after-free en el gestor de datagramas HTTP QUIC.
- __[CVE-2026-73547](https://nvd.nist.gov/vuln/detail/CVE-2026-73547)__: (puntuación CVSS 7.5): Corregida la terminación anormal en `ext_authz` al gestionar solicitudes CONNECT sin cabecera `:path`.
- __[CVE-2026-73549](https://nvd.nist.gov/vuln/detail/CVE-2026-73549)__: (puntuación CVSS 5.3): Corregida la terminación anormal para direcciones de cliente IPv6 con ámbito con HTTP/3.
- __[CVE-2026-50572](https://nvd.nist.gov/vuln/detail/CVE-2026-50572)__: (puntuación CVSS 5.9): Corregido un use-after-free en el cliente HTTP raw de `ext_authz`.
- __[CVE-2026-73546](https://nvd.nist.gov/vuln/detail/CVE-2026-73546)__: (puntuación CVSS 7.4): Corregida una vulnerabilidad de cross-site scripting almacenado en la interfaz de estadísticas HTML.
- __[CVE-2026-48521](https://nvd.nist.gov/vuln/detail/CVE-2026-48521)__: (puntuación CVSS 5.9): Corregida una desreferencia de puntero nulo durante la selección del pool de conexiones HTTP/3 basada en ALPN.
- __[CVE-2026-73551](https://nvd.nist.gov/vuln/detail/CVE-2026-73551)__: (puntuación CVSS 5.3): Corregida la normalización de URL de segmentos de ruta punto y punto-punto con parámetros.
- __[CVE-2026-73511](https://nvd.nist.gov/vuln/detail/CVE-2026-73511)__: (puntuación CVSS 5.3): Corregida la coincidencia de rutas para parámetros por segmento.
- __[CVE-2026-73548](https://nvd.nist.gov/vuln/detail/CVE-2026-73548)__: (puntuación CVSS 7.5): Corregido el envenenamiento de respuestas entre usuarios en actualizaciones HTTP genéricas.
- __[CVE-2026-73550](https://nvd.nist.gov/vuln/detail/CVE-2026-73550)__: (puntuación CVSS 7.5): Corregido el agotamiento de memoria HTTP/2 mediante cabeceras Host duplicadas descartadas.
- __[CVE-2026-73553](https://nvd.nist.gov/vuln/detail/CVE-2026-73553)__: (puntuación CVSS 7.5): Corregido un bypass de RBAC mediante `ignore_path_parameters_in_path_matching`.

### CVEs de Istio

- [GHSA-qm8v-g4f9-qhjx](https://github.com/istio/istio/security/advisories/GHSA-qm8v-g4f9-qhjx) (puntuación CVSS 6.8, Moderada): `BackendTLSPolicy` falla en modo fail-open a texto plano en proxies sidecar cuando su referencia CA no está resuelta.

### Otras correcciones de seguridad de Istio

- **Corregido** un vacío de validación en `EnvoyFilter` donde una expresión de coincidencia `proxyVersion` sin límite podía provocar un uso excesivo de memoria y CPU en istiod durante la compilación de expresiones regulares. La expresión de coincidencia ahora está limitada a 1024 caracteres. **Crédito**: Este problema fue reportado por [`Artem Cherezov`](https://github.com/cherez0ff).

## Cambios

- **Corregido** un deadlock donde el pod del agente de nodo istio-cni podía no arrancar (por ejemplo, tras un reinicio del nodo) porque el plugin CNI solo omitía la creación del cliente de Kubernetes para su propio pod agente cuando el modo ambient estaba habilitado. La verificación preventiva ahora también se ejecuta en modo sidecar, de modo que el pod del agente ya no se bloquea en un kubeconfig que aún no ha escrito. ([Issue #60668](https://github.com/istio/istio/issues/60668))

- **Corregido** un error donde el gateway de red de un clúster remoto podía desaparecer del enrutamiento cross-network tras la rotación de credenciales y no recuperarse hasta que istiod se reiniciara. El intercambio de registro en su lugar ahora vuelve a conectar el nuevo registro a los manejadores del controlador agregado para que sus futuros eventos de gateway y servicio se propaguen, y recarga los gateways una vez para recoger los descubiertos durante la sincronización previa al intercambio. ([Issue #60920](https://github.com/istio/istio/issues/60920))

- **Corregido** un problema en despliegues multiclúster donde rotar el `istio-remote-secret` de un clúster remoto podía borrar permanentemente los shards de endpoints para servicios con endpoints estables en ese clúster, haciéndolos inalcanzables entre clústeres hasta que istiod se reiniciara. ([Issue #61043](https://github.com/istio/istio/issues/61043))

- **Corregida** una condición de carrera al inicio de istiod donde la sonda de disponibilidad podía reportar listo antes de que el servidor webhook HTTPS dedicado de inyección y validación (`--httpsAddr`, por defecto `:15017`) estuviera aceptando conexiones, causando timeouts intermitentes de `failed calling webhook` al crear recursos inmediatamente después de que istiod estuviera listo. Esto no afecta a los despliegues donde los webhooks comparten el servidor HTTP principal (`--httpsAddr` vacío). ([Issue #61049](https://github.com/istio/istio/issues/61049))

- **Corregido** un problema donde los gateways de ingreso omitían los proxies waypoint para servicios multiclúster cuando los workloads remotos estaban en una red diferente, causando que las políticas de autorización no se aplicaran. ([Issue #61092](https://github.com/istio/istio/issues/61092))

- **Corregido** un problema donde los recursos `Deployment` del proxy gateway podían fallar permanentemente al crearse durante el inicio de istiod. ([Issue #61095](https://github.com/istio/istio/issues/61095))

- **Corregido** un problema donde un pod seleccionado por un `workloadSelector` de `ServiceEntry` podía arrancar sin ese servicio en la configuración entrante de su sidecar. El tráfico al puerto no se gestionaba como el protocolo declarado en el `ServiceEntry`, y la `PeerAuthentication` a nivel de puerto no se aplicaba. El pod no se recuperaba por sí solo; solo reiniciar istiod lo reparaba. ([Issue #61157](https://github.com/istio/istio/issues/61157))

- **Corregido** un problema donde `istio-cni` consideraba los pods `hostNetwork` elegibles para la inscripción en ambient. ([Issue #61168](https://github.com/istio/istio/issues/61168))

- **Corregida** una fuga de descriptores de archivo en el agente de nodo `istio-cni`: cuando el escaneo de `procfs` encontraba más de un namespace de red para el mismo pod, el descriptor de archivo netns del candidato perdedor se descartaba sin cerrarlo, anclando el namespace en el kernel hasta la recolección de basura.

- **Corregidos** los proveedores SDS externos configurados mediante `extensionProviders` para usar el nombre de host de servicio configurado como autoridad gRPC.

- **Corregida** una fuga de goroutine en la elección de líder de istiod donde cada ciclo de elección (liderazgo perdido y readquirido) filtraba una goroutine hasta la salida del proceso. ([Issue #60843](https://github.com/istio/istio/issues/60843))

- **Corregido** un problema donde el uso de CPU de istiod aumentaba a medida que aumentaba el número de recursos `AuthorizationPolicy`. ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **Corregida** la resolución de conflictos de `ListenerSet` para conflictos de nombre de host y protocolo. Los listeners en conflicto ahora se rechazan correctamente y las condiciones de estado de `ListenerSet` se reportan en conformidad con la Gateway API 1.5. ([PR #60775](https://github.com/istio/istio/pull/60775))

- **Corregido** un error donde una reconexión de ztunnel (como el reciclado periódico de conexiones de `keepaliveMaxServerConnectionAge`) desencadenaba un push completo de workload (WDS). Istiod ahora asigna a cada recurso WDS una versión basada en contenido y, cuando un cliente que se reconecta reporta las versiones que ya tiene mediante `initial_resource_versions`, reenvía únicamente los recursos que cambiaron mientras el cliente estaba desconectado. Las versiones antiguas de ztunnel que no reportan versiones continúan recibiendo el conjunto completo. ([Issue #1966](https://github.com/istio/ztunnel/issues/1966))

- **Corregido** el generador `api` de XDS (servicio de configuración MCP) para requerir una identidad de control plane verificada. Anteriormente, cualquier cliente que pudiera llegar al puerto XDS de Istiod podía leer la configuración de Istio en todos los namespaces. `ENABLE_XDS_API_GENERATOR_AUTH=true` por defecto; deshabilita con `ENABLE_XDS_API_GENERATOR_AUTH=false` si es necesario para compatibilidad.

- **Corregido** un problema de la Gateway API donde un `certificateRef` o `caCertificateRef` TLS cross-namespace se resolvía antes de la verificación de autorización de `ReferenceGrant`, de modo que el estado `ResolvedRefs` de un listener podía revelar si el `Secret` o `ConfigMap` referenciado existía incluso cuando ningún grant permitía la referencia. La autorización ahora se ejecuta primero, devolviendo `RefNotPermitted` para cualquier referencia cross-namespace no permitida por un grant. **Crédito**: Este problema fue reportado por Darryl Jaskolski.

- **Corregida** una brecha de SSRF en la obtención de `jwksUri` de `RequestAuthentication` de istiod. istiod ahora bloquea las direcciones de enlace local y de metadatos de nube conocidas (como `169.254.169.254`) a nivel de dial de forma predeterminada y rechaza las respuestas obtenidas que no son un JWKS válido. Los rangos privados y de loopback siguen siendo accesibles y pueden bloquearse con `BLOCKED_CIDRS_IN_JWKS_URIS`.

- **Corregidas** varias anotaciones `sidecar.istio.io/*` (`proxyImage`, `bootstrapOverride`, `logLevel`, `componentLogLevel`, `agentLogLevel`) que se interpolaban en las plantillas de inyección de sidecar/gateway sin escapar la salida, lo que podía permitir que un valor de anotación diseñado maliciosamente inyectara campos adicionales en el spec del pod o despliegue generado. Estas anotaciones ahora se escapan de forma consistente en cada punto de inserción de la plantilla. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por `localhost-detect`.
