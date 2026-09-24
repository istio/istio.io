---
title: Anuncio de Istio 1.29.7
linktitle: 1.29.7
subtitle: Versión de Parche
description: Parche de Istio 1.29.7.
publishdate: 2026-08-27
release: 1.29.7
aliases:
    - /news/announcing-1.29.7
---

Esta versión contiene correcciones de seguridad. Estas notas de versión describen las diferencias entre Istio 1.29.6 e Istio 1.29.7.

{{< relnote >}}

## Actualización de seguridad

Para más información, consulta [ISTIO-SECURITY-2026-006](/news/security/istio-security-2026-006).

### CVEs de Envoy

- __[CVE-2026-73513](https://nvd.nist.gov/vuln/detail/CVE-2026-73513)__: (puntuación CVSS 7.5): Corregido un heap use-after-free en `oghttp2` cuando se reciben trailers HTTP/2 sin el flag `END_STREAM`.
- __[CVE-2026-73552](https://nvd.nist.gov/vuln/detail/CVE-2026-73552)__: (puntuación CVSS 7.5): Corregido un error donde `safe_regex` fallaba en modo fail-open ante bytes de cabecera que no son UTF-8 en políticas RBAC de coincidencia negativa.
- __[CVE-2026-73512](https://nvd.nist.gov/vuln/detail/CVE-2026-73512)__: (puntuación CVSS 7.5): Corregido un use-after-free en el manejador de datagramas HTTP de QUIC.
- __[CVE-2026-73547](https://nvd.nist.gov/vuln/detail/CVE-2026-73547)__: (puntuación CVSS 7.5): Corregida una terminación anormal en `ext_authz` al manejar solicitudes CONNECT sin una cabecera `:path`.
- __[CVE-2026-73549](https://nvd.nist.gov/vuln/detail/CVE-2026-73549)__: (puntuación CVSS 5.3): Corregida una terminación anormal para direcciones de cliente IPv6 con ámbito con HTTP/3.
- __[CVE-2026-50572](https://nvd.nist.gov/vuln/detail/CVE-2026-50572)__: (puntuación CVSS 5.9): Corregido un use-after-free en el cliente HTTP raw de `ext_authz`.
- __[CVE-2026-73546](https://nvd.nist.gov/vuln/detail/CVE-2026-73546)__: (puntuación CVSS 7.4): Corregida una vulnerabilidad de cross-site scripting almacenado en la interfaz de estadísticas HTML.
- __[CVE-2026-48521](https://nvd.nist.gov/vuln/detail/CVE-2026-48521)__: (puntuación CVSS 5.9): Corregida una desreferencia de puntero nulo durante la selección de pool de conexiones HTTP/3 basada en ALPN.
- __[CVE-2026-73551](https://nvd.nist.gov/vuln/detail/CVE-2026-73551)__: (puntuación CVSS 5.3): Corregida la normalización de URL de segmentos de ruta punto y punto-punto con parámetros.
- __[CVE-2026-73511](https://nvd.nist.gov/vuln/detail/CVE-2026-73511)__: (puntuación CVSS 5.3): Corregida la coincidencia de rutas para parámetros por segmento.
- __[CVE-2026-73548](https://nvd.nist.gov/vuln/detail/CVE-2026-73548)__: (puntuación CVSS 7.5): Corregido el envenenamiento de respuesta entre usuarios en actualizaciones HTTP genéricas.
- __[CVE-2026-73550](https://nvd.nist.gov/vuln/detail/CVE-2026-73550)__: (puntuación CVSS 7.5): Corregido el agotamiento de memoria HTTP/2 mediante cabeceras Host duplicadas descartadas.
- __[CVE-2026-73553](https://nvd.nist.gov/vuln/detail/CVE-2026-73553)__: (puntuación CVSS 7.5): Corregido un bypass de RBAC mediante `ignore_path_parameters_in_path_matching`.

### CVEs de Istio

- [GHSA-qm8v-g4f9-qhjx](https://github.com/istio/istio/security/advisories/GHSA-qm8v-g4f9-qhjx) (puntuación CVSS 6.8, Moderada): `BackendTLSPolicy` falla en modo fail-open a texto plano en los sidecars cuando su referencia de CA no está resuelta.

### Correcciones de seguridad de Istio

- **Corregida** una brecha de validación en `EnvoyFilter` donde una expresión de coincidencia `proxyVersion` sin límite superior podía provocar un uso excesivo de memoria y CPU en istiod durante la compilación de expresiones regulares. La expresión de coincidencia ahora está limitada a 1024 caracteres. **Crédito**: Este problema fue reportado por [`Artem Cherezov`](https://github.com/cherez0ff).

## Cambios

- **Actualizada** la versión de `nftables` utilizada por las imágenes distroless de Istio. La versión de `nftables` estaba anteriormente fijada a 1.1.1 para evitar un error que podía hacer que versiones antiguas de `nftables` en los nodos K8s fallaran después de que Istio usara una versión más nueva empaquetada en sus imágenes en el mismo nodo. Las principales distribuciones de Linux han sido informadas del problema y han publicado correcciones. Como resultado, Istio elimina el fijado de la versión de `nftables`. Se recomienda a los usuarios actualizar el paquete `nftables` en sus nodos a la última versión disponible para asegurarse de que la versión corregida esté instalada. Si continúas experimentando fallos de `nftables` en tus nodos, vuelve a una versión anterior de Istio y contacta con tu proveedor de SO del nodo para solicitar que la corrección se aplique a tu versión del SO. ([Issue #58492](https://github.com/istio/istio/issues/58492))

- **Corregida** una condición de carrera al inicio de istiod donde el probe de preparación podía reportar como listo antes de que el servidor dedicado de webhooks de inyección y validación (`--httpsAddr`, por defecto `:15017`) aceptara conexiones, causando timeouts intermitentes de `failed calling webhook` al crear recursos inmediatamente después de que istiod estuviera listo. Esto no afecta a los despliegues donde los webhooks comparten el servidor HTTP principal (`--httpsAddr` vacío). ([Issue #61049](https://github.com/istio/istio/issues/61049))

- **Corregido** un problema donde los ingress gateways eludían los waypoints para servicios multiclúster cuando los workloads remotos estaban en una red diferente, lo que causaba que las políticas de autorización no se aplicaran. ([Issue #61092](https://github.com/istio/istio/issues/61092))

- **Corregido** un problema donde los recursos `Deployment` del proxy del gateway podían fallar permanentemente al crearse durante el inicio de istiod. ([Issue #61095](https://github.com/istio/istio/issues/61095))

- **Corregido** un problema donde `istio-cni` consideraba los pods `hostNetwork` elegibles para la inscripción en ambient. ([Issue #61168](https://github.com/istio/istio/issues/61168))

- **Corregida** una fuga de descriptores de archivo en el agente de nodo `istio-cni`: cuando el escaneo de `procfs` encontraba más de un namespace de red para el mismo pod, el descriptor de archivo del netns candidato perdedor se descartaba sin cerrarse, fijando el namespace en el kernel hasta la recolección de basura.

- **Corregido** un error donde el agente de nodo `istio-cni` podía emparejar un pod ambient con el namespace de red de otro pod cuando un proceso de terceros estaba dentro de ese namespace durante un escaneo, lo que podía causar que el tráfico se enrutara a través del proxy con una identidad incorrecta. El agente de nodo ahora verifica que un namespace contiene una de las IPs del pod antes de inscribirlo. ([Issue #61211](https://github.com/istio/istio/issues/61211))

- **Corregido** un problema donde istiod retenía permanentemente una copia del nombre de cada recurso de workload para cada conexión MDS (WDS, usado para búsquedas de metadatos de telemetría) de Envoy que enviaba `initial_resource_versions`.

- **Corregido** un error donde una reconexión de ztunnel (como el reciclado periódico de conexiones de `keepaliveMaxServerConnectionAge`) desencadenaba un push completo de workload (WDS). Istiod ahora asigna a cada recurso WDS una versión basada en contenido y, cuando un cliente que se reconecta informa las versiones que ya tiene mediante `initial_resource_versions`, reenvía únicamente los recursos que cambiaron mientras el cliente estaba desconectado. Las versiones antiguas de ztunnel que no informan versiones siguen recibiendo el conjunto completo. ([Issue #1966](https://github.com/istio/ztunnel/issues/1966))

- **Corregido** un problema de la Gateway API donde una `certificateRef` o `caCertificateRef` TLS entre namespaces se resolvía antes de la verificación de autorización de `ReferenceGrant`, por lo que el estado `ResolvedRefs` de un listener podía revelar si el `Secret` o `ConfigMap` referenciado existía incluso cuando ningún grant permitía la referencia. La autorización ahora se ejecuta primero, devolviendo `RefNotPermitted` para cualquier referencia entre namespaces no permitida por un grant. **Crédito**: Este problema fue reportado por Darryl Jaskolski.

- **Corregida** una brecha de SSRF en la obtención de `jwksUri` de `RequestAuthentication` en istiod. Istiod ahora bloquea las direcciones de metadatos de nube y link-local conocidas (como `169.254.169.254`) a nivel de conexión por defecto y rechaza las respuestas obtenidas que no sean un JWKS válido. Los rangos privados y de loopback siguen siendo accesibles y pueden bloquearse con `BLOCKED_CIDRS_IN_JWKS_URIS`.

- **Corregido** el generador XDS `api` (servicio de configuración MCP) para requerir una identidad de control plane verificada. Anteriormente, cualquier cliente que pudiera alcanzar el puerto XDS de Istiod podía leer la configuración de Istio en todos los namespaces. Por defecto `ENABLE_XDS_API_GENERATOR_AUTH=true`; deshabilítalo con `ENABLE_XDS_API_GENERATOR_AUTH=false` si es necesario por compatibilidad.

- **Corregidas** varias anotaciones `sidecar.istio.io/*` (`proxyImage`, `bootstrapOverride`, `logLevel`, `componentLogLevel`, `agentLogLevel`) que se interpolaban en las plantillas de inyección de sidecar/gateway sin escapado de salida, lo que podía permitir que un valor de anotación diseñado inyectara campos adicionales en el pod o spec de despliegue generado. Estas anotaciones ahora se escapan de forma consistente en cada sink de plantilla. **Crédito**: Esta vulnerabilidad fue descubierta y reportada por `localhost-detect`.

- **Corregidas** fugas de goroutines y memoria en istiod en modo multiclúster ambient cuando se eliminan o actualizan clústeres remotos. Las colecciones internas construidas para cada clúster remoto no liberaban los manejadores de eventos que habían registrado en sus entradas al ser destruidas, lo que causaba que goroutines y memoria se acumularan con el tiempo a medida que se eliminaban o reconfiguraban clústeres. ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **Corregida** una fuga de goroutine en la elección de liderazgo de istiod donde cada ciclo de elección (liderazgo perdido y readquirido) filtraba una goroutine hasta la salida del proceso. ([Issue #60843](https://github.com/istio/istio/issues/60843))

- **Corregido** un problema donde el uso de CPU de istiod aumentaba a medida que crecía el número de recursos `AuthorizationPolicy`. ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **Corregido** que los `Service`s de Gateway generados fueran rechazados cuando dos nombres de listener se saneaban al mismo nombre de puerto de Service (nombres que difieren solo por puntos versus guiones, o solo más allá del límite de 63 caracteres), lo que bloqueaba cada puerto no publicado en el Gateway. Los nombres de puerto que colisionan ahora se disambiguan con el número de puerto del listener.

- **Mejorado** el rendimiento al obtener recursos `PeerAuthentication` para un workload determinado.
