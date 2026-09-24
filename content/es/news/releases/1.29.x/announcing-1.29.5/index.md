---
title: Anuncio de Istio 1.29.5
linktitle: 1.29.5
subtitle: Versión de Parche
description: Parche de Istio 1.29.5.
publishdate: 2026-06-24
release: 1.29.5
aliases:
    - /news/announcing-1.29.5
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.29.4 e Istio 1.29.5.

{{< relnote >}}

## Cambios

- **Corregida** una breve interrupción del tráfico al cambiar la etiqueta `istio.io/rev` en un `Gateway` (o `ListenerSet`) de Kubernetes. El control plane que era propietario anteriormente ya no descarta el recurso y envía configuración xDS vacía a los pods del gateway que aún se ejecutan en la revisión antigua. Las escrituras de estado para revisiones no propietarias siguen suprimiéndose, por lo que las revisiones no alternan entre sí en el estado.
  ([Issue #59959](https://github.com/istio/istio/issues/59959))

- **Corregido** un problema donde un pod inscrito en el mesh ambient podía quedar fuera del ipset de health-probe del host tras un reinicio del nodo o de kubelet, lo que hacía que los probes de kubelet fueran redirigidos a ztunnel y rechazados hasta que el agente de nodo `istio-cni` se reiniciara. Al inicio, el agente de nodo podía expulsar pods aún inscritos del ipset cuando su IP aún no era observable, y ahora reafirma la membresía en el ipset de probes para los pods inscritos durante la reconciliación.

- **Corregida** la generación de configuración para sidecars anteriores a 1.29.2.

- **Corregida** una fuga de memoria en el framework del controlador `krt` donde el cambio de la clave usada en un filtro `Fetch` (por ejemplo, reetiquetando un pod para apuntar a un waypoint diferente) dejaba entradas de índice inverso obsoletas que nunca se limpiaban. Con el tiempo, esto podía aumentar el uso de memoria y causar recomputaciones innecesarias.

- **Corregido** un pánico (`close of closed channel`) en el controlador de secretos multiclúster que podía ocurrir cuando el secreto de kubeconfig de un clúster remoto se actualizaba dos veces en rápida sucesión.
  ([Issue #60520](https://github.com/istio/istio/issues/60520))

## Actualización de seguridad

Para más información, consulta [ISTIO-SECURITY-2026-005](/news/security/istio-security-2026-005).

### CVEs de Envoy

- __[GHSA-p7c7-7c47-pwch](https://github.com/envoyproxy/envoy/security/advisories/GHSA-p7c7-7c47-pwch)__: (CVSS score 7.5): Corrección de una vulnerabilidad de denegación de servicio en la pila HTTP/3 mediante decodificación bloqueada de QPACK. Cuando un bloque de cabecera QPACK estaba bloqueado esperando actualizaciones de la tabla dinámica, los bytes del payload HEADERS se liberaban de la contabilización del control de flujo de recepción de QUIC mientras aún se retenían en un buffer del heap del decodificador interno, lo que permitía a un atacante remoto provocar un crecimiento de memoria ilimitado y desencadenar una condición de falta de memoria.
- __[CVE-2026-47692](https://nvd.nist.gov/vuln/detail/CVE-2026-47692)__: (CVSS score 4.8): Corrección de un error donde los TLVs de passthrough combinados con TLVs añadidos podían superar la longitud máxima, lo que resultaba en una discrepancia entre el tamaño informado en la cabecera y el número de bytes escritos. Esto podía permitir una solicitud de contrabando desde el host que escribía la cabecera del protocolo PROXY al host upstream.
- __[CVE-2026-47207](https://nvd.nist.gov/vuln/detail/CVE-2026-47207)__: (CVSS score 6.5): Corrección de un error donde el servidor `ext_proc` enviaba `ProcessingResponses` inesperados a Envoy.
- __[CVE-2026-47205](https://nvd.nist.gov/vuln/detail/CVE-2026-47205)__: (CVSS score 5.9): Corrección de un crash por use-after-free en el filtro ext_authz cuando las anulaciones de servicio por ruta están activas y la conexión descendente se restablece durante una verificación de autorización en vuelo.
- __[CVE-2026-47220](https://nvd.nist.gov/vuln/detail/CVE-2026-47220)__: (CVSS score 7.5): Corrección de un bug de crash en el formateador `%REQUESTED_SERVER_NAME%` donde el host o el host original no está configurado correctamente pero el formateador está configurado para acceder al valor del host.
- __[CVE-2026-47221](https://nvd.nist.gov/vuln/detail/CVE-2026-47221)__: (CVSS score 5.9): Corrección de un problema al manejar redireccionamientos internos HTTP 303 para solicitudes sin cuerpo. El código de manejo de redireccionamientos intentaba vaciar un buffer del cuerpo de la solicitud que nunca fue asignado, causando un fallo de segmentación.
- __[CVE-2026-48044](https://nvd.nist.gov/vuln/detail/CVE-2026-48044)__: (CVSS score 7.5): Corrección de una vulnerabilidad de agotamiento de memoria en el descompresor Zstd donde el límite `MaxInflateRatio` solo se verificaba después de que cada fragmento de entrada fuera completamente procesado, lo que permitía a un payload comprimido malicioso expandirse a cientos de MB dentro de una sola llamada a `process()`. El límite de la relación de inflado ahora se aplica dentro del bucle de descompresión interno, similar a los descompresores gzip y brotli, abortando la descompresión tan pronto como se supera el umbral.
- __[CVE-2026-48090](https://nvd.nist.gov/vuln/detail/CVE-2026-48090)__: (CVSS score 5.9): Corrección de un error donde el callback de cambio de token asíncrono podía dispararse después de que el filtro hubiera sido destruido (se había llamado a `onDestroy()`), lo que podía llevar a acceder a punteros colgantes y resultar en UAF/crash.
- __[CVE-2026-47778](https://nvd.nist.gov/vuln/detail/CVE-2026-47778)__: (CVSS score 4.4): Corrección de un problema donde Envoy podía no validar el Subject Alternative Name (SAN) de un certificado de par si el SAN contenía un byte NUL incrustado. Anteriormente, el análisis del SAN era vulnerable al truncamiento por byte NUL en algunas configuraciones, lo que podía llevar a decisiones de confianza incorrectas.
- __[CVE-2026-47204](https://nvd.nist.gov/vuln/detail/CVE-2026-47204)__: (CVSS score 6.5): Corrección de un crash o use-after-free cuando el filtro de estadísticas gRPC realiza seguimiento de estadísticas en una ruta de respuesta directa.
- __[CVE-2026-48497](https://nvd.nist.gov/vuln/detail/CVE-2026-48497)__: (CVSS score 5.9): Corrección de la verificación de integridad de la longitud del nombre de la consulta para evitar la terminación anormal del proceso. Se usa `ENVOY_BUG` en caso de que la verificación de integridad falle.
- __[CVE-2026-48706](https://nvd.nist.gov/vuln/detail/CVE-2026-48706)__: (CVSS score 5.9): Corrección de un problema de desbordamiento de buffer en `TcpStatsdSink` con un nombre de estadística largo.
- __[CVE-2026-48743](https://nvd.nist.gov/vuln/detail/CVE-2026-48743)__: (CVSS score 7.5): Corrección de la validación de content-length para solicitudes y respuestas HTTP/3 sin cuerpo, y restablecimiento del stream si es inconsistente. El cambio está protegido por la guardia de runtime `envoy.reloadable_features.quic_validate_headers_only_content_length`.
- __[CVE-2026-47775](https://nvd.nist.gov/vuln/detail/CVE-2026-47775)__: (CVSS score 6.8): Corrección de un oráculo de relleno en el descifrado de cookies AES-256-CBC del filtro OAuth2. El filtro ahora admite cifrado AES-256-GCM con un marcador de algoritmo `gcm.`, que autentica el texto cifrado y elimina el oráculo.
- __[CVE-2026-48042](https://nvd.nist.gov/vuln/detail/CVE-2026-48042)__: (CVSS score 7.5): Limitación de la profundidad de anidamiento JSON a 1000. El límite podría relajarse a 10K configurando `envoy.reloadable_features.limit_json_parser_nesting_depth` a `false`.
