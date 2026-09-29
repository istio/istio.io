---
title: ISTIO-SECURITY-2026-005
subtitle: Boletín de Seguridad
description: CVEs reportados por Envoy y correcciones de seguridad de Istio.
cves: [CVE-2026-47692, CVE-2026-47207, CVE-2026-47205, CVE-2026-47220, CVE-2026-47221, CVE-2026-48044, CVE-2026-48090, CVE-2026-47778, CVE-2026-47204, CVE-2026-48497, CVE-2026-48706, CVE-2026-48743, CVE-2026-47775, CVE-2026-48042]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:L/A:N"
releases: ["1.30.1 to 1.30.2", "1.29.4 to 1.29.5", "1.28.8 to 1.28.9"]
publishdate: 2026-06-24
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[GHSA-p7c7-7c47-pwch](https://github.com/envoyproxy/envoy/security/advisories/GHSA-p7c7-7c47-pwch)__: (CVSS score 7.5): Se corrigió una vulnerabilidad de denegación de servicio en la pila HTTP/3 mediante decodificación QPACK bloqueada. Cuando un bloque de cabeceras QPACK quedaba bloqueado esperando actualizaciones de la tabla dinámica, los bytes del payload HEADERS se liberaban de la contabilización del control de flujo de recepción QUIC mientras aún se retenían en un buffer del heap interno del decodificador, lo que permitía a un atacante remoto provocar un crecimiento ilimitado de memoria y desencadenar una condición de falta de memoria.
- __[CVE-2026-47692](https://nvd.nist.gov/vuln/detail/CVE-2026-47692)__: (CVSS score 4.8): Se corrigió un error donde los TLVs de passthrough combinados con TLVs añadidos podían superar la longitud máxima, resultando en una discrepancia entre el tamaño reportado en la cabecera y el número de bytes escritos. Esto podía permitir contrabando de solicitudes desde el host que escribe la cabecera del protocolo PROXY hacia el host upstream.
- __[CVE-2026-47207](https://nvd.nist.gov/vuln/detail/CVE-2026-47207)__: (CVSS score 6.5): Se corrigió un error donde el servidor `ext_proc` enviaba `ProcessingResponses` inesperados a Envoy.
- __[CVE-2026-47205](https://nvd.nist.gov/vuln/detail/CVE-2026-47205)__: (CVSS score 5.9): Se corrigió un crash por use-after-free en el filtro ext_authz cuando hay anulaciones de servicio por ruta activas y la conexión downstream se reinicia durante una verificación de autorización en vuelo.
- __[CVE-2026-47220](https://nvd.nist.gov/vuln/detail/CVE-2026-47220)__: (CVSS score 7.5): Se corrigió un crash en el formateador `%REQUESTED_SERVER_NAME%` donde el host o el host original no estaba configurado correctamente pero el formateador estaba configurado para acceder al valor del host.
- __[CVE-2026-47221](https://nvd.nist.gov/vuln/detail/CVE-2026-47221)__: (CVSS score 5.9): Se corrigió un problema al manejar redirecciones internas HTTP 303 para solicitudes sin cuerpo. El código de manejo de redirecciones intentaba vaciar un buffer de cuerpo de solicitud que nunca se había asignado, causando un fallo de segmentación.
- __[CVE-2026-48044](https://nvd.nist.gov/vuln/detail/CVE-2026-48044)__: (CVSS score 7.5): Se corrigió una vulnerabilidad de agotamiento de memoria en el descompresor Zstd donde el límite `MaxInflateRatio` solo se verificaba después de que cada fragmento de entrada se procesaba completamente, permitiendo que un payload comprimido malicioso se expandiera a cientos de MB en una sola llamada a `process()`. El límite de la ratio de inflado ahora se aplica dentro del bucle interno de descompresión, igualando el comportamiento de los descompresores gzip y brotli y abortando la descompresión tan pronto como se supera el umbral.
- __[CVE-2026-48090](https://nvd.nist.gov/vuln/detail/CVE-2026-48090)__: (CVSS score 5.9): Se corrigió un error donde el callback asíncrono de cambio de token podía activarse después de que el filtro había sido destruido (se había llamado a `onDestroy()`), lo que podía llevar a acceder a punteros colgantes y resultar en UAF/crash.
- __[CVE-2026-47778](https://nvd.nist.gov/vuln/detail/CVE-2026-47778)__: (CVSS score 4.4): Se corrigió un problema donde Envoy podía fallar al validar el Subject Alternative Name (SAN) de un certificado de peer si el SAN contenía un byte NUL embebido. Anteriormente, el análisis del SAN era vulnerable a la truncación por bytes NUL en algunas configuraciones, pudiendo llevar a decisiones de confianza incorrectas.
- __[CVE-2026-47204](https://nvd.nist.gov/vuln/detail/CVE-2026-47204)__: (CVSS score 6.5): Se corrigió un crash o use-after-free cuando el filtro de estadísticas gRPC realizaba seguimiento de estadísticas en una ruta de respuesta directa.
- __[CVE-2026-48497](https://nvd.nist.gov/vuln/detail/CVE-2026-48497)__: (CVSS score 5.9): Se corrigió la verificación de sanidad de la longitud del nombre de consulta para evitar la terminación anormal del proceso. Se usa `ENVOY_BUG` en caso de que falle la verificación de sanidad.
- __[CVE-2026-48706](https://nvd.nist.gov/vuln/detail/CVE-2026-48706)__: (CVSS score 5.9): Se corrigió un desbordamiento de buffer en `TcpStatsdSink` con nombres de estadísticas muy largos.
- __[CVE-2026-48743](https://nvd.nist.gov/vuln/detail/CVE-2026-48743)__: (CVSS score 7.5): Se corrigió la validación del content-length de solicitudes y respuestas HTTP/3 solo con cabeceras y se reinicia el stream si es inconsistente. El cambio está controlado por el runtime guard `envoy.reloadable_features.quic_validate_headers_only_content_length`.
- __[CVE-2026-47775](https://nvd.nist.gov/vuln/detail/CVE-2026-47775)__: (CVSS score 6.8): Se corrigió un padding oracle en el descifrado de cookies AES-256-CBC del filtro OAuth2. El filtro ahora admite cifrado AES-256-GCM con un marcador de algoritmo `gcm.`, que autentica el texto cifrado y elimina el oracle.
- __[CVE-2026-48042](https://nvd.nist.gov/vuln/detail/CVE-2026-48042)__: (CVSS score 7.5): Se limitó la profundidad de anidamiento JSON a 1000. El límite puede relajarse a 10K configurando `envoy.reloadable_features.limit_json_parser_nesting_depth` a `false`.
