---
title: Anuncio de Istio 1.30.2
linktitle: 1.30.2
subtitle: Versión de Parche
description: Parche de Istio 1.30.2.
publishdate: 2026-06-24
release: 1.30.2
aliases:
    - /news/announcing-1.30.2
---

Esta versión contiene correcciones de errores para mejorar la robustez. Estas notas de versión describen las diferencias entre Istio 1.30.1 e Istio 1.30.2.

{{< relnote >}}

## Cambios

- **Mejorado** el registro cuando un CRD de la Gateway API instalado en el clúster está por debajo de la versión mínima
  requerida por esta versión de Istio. El mensaje ahora se registra a nivel `warn` y explica que
  los recursos de ese tipo no serán procesados hasta que los CRDs se actualicen. Anteriormente, esto se
  registraba a nivel `info` y era fácil de pasar por alto, lo que dificultaba diagnosticar la rotura del TLS passthrough al actualizar a
  1.30 con CRDs desactualizados.

- **Añadidos** los campos `trustDomains` y `notTrustDomains` al `Source` en `AuthorizationPolicy`,
  permitiendo a los usuarios hacer coincidir o excluir solicitudes basándose en el dominio de confianza derivado del certificado de par.

- **Añadida** una nueva variable de entorno `PILOT_AGENT_MERGE_ENVOY_STATS` para controlar si pilot-agent fusiona las estadísticas de Envoy
  en su endpoint de estadísticas. Establece a `false` para deshabilitar la fusión de estadísticas de Envoy con las estadísticas del agente.

- **Corregida** una breve interrupción del tráfico al cambiar la etiqueta `istio.io/rev` en un `Gateway` de Kubernetes
  (o `ListenerSet`). El control plane que poseía el recurso anteriormente ya no descarta
  el recurso y empuja configuración xDS vacía a los pods de gateway que aún se ejecutan en la revisión antigua. Las escrituras de estado para revisiones que no son propietarias siguen siendo suprimidas, de modo que las revisiones
  no compitan entre sí por el estado.
  ([Issue #59959](https://github.com/istio/istio/issues/59959))

- **Corregidos** los pushes duplicados y excesivos al usar recursos `WasmPlugin` debido a las conversiones de `TrafficExtension`.

- **Corregido** un problema donde un pod inscrito en ambient podía quedar fuera del ipset de sondeo de salud del host tras un
  reinicio del nodo o kubelet, causando que las sondas de kubelet se redirigieran a ztunnel y se rechazaran hasta que el agente de nodo `istio-cni`
  se reiniciara. Al inicio, el agente de nodo podía expulsar pods aún inscritos del ipset cuando su IP
  no era aún observable, y ahora vuelve a establecer la membresía en el ipset de sondeo para los pods inscritos durante la reconciliación.

- **Corregida** la generación de configuración para sidecars anteriores a 1.29.2.

- **Corregida** una fuga de memoria en el framework de controlador `krt` donde cambiar la clave usada en un filtro `Fetch`
  (por ejemplo, retiquetar un pod para que apunte a un waypoint diferente) dejaba entradas de índice inverso obsoletas que nunca
  se limpiaban. Con el tiempo esto podía aumentar el uso de memoria y causar recomputaciones innecesarias.

- **Corregido** un problema donde la fusión de métricas de pilot-agent producía resultados incorrectos cuando Envoy reportaba métricas
  usando el tipo de contenido protobuf. pilot-agent no podía manejar correctamente el tipo de contenido protobuf, por lo que los
  tipos de contenido permitidos ahora están restringidos a `text/plain` y `application/openmetrics-text` únicamente.
  ([Issue #60322](https://github.com/istio/istio/issues/60322))

## Actualización de Seguridad

Para más información, consulta [ISTIO-SECURITY-2026-005](/news/security/istio-security-2026-005).

### CVEs de Envoy

- __[GHSA-p7c7-7c47-pwch](https://github.com/envoyproxy/envoy/security/advisories/GHSA-p7c7-7c47-pwch)__: (puntuación CVSS 7.5): Corregida una vulnerabilidad de denegación de servicio en la pila HTTP/3 mediante decodificación bloqueada de QPACK. Cuando un bloque de cabecera QPACK estaba bloqueado esperando actualizaciones de la tabla dinámica, los bytes del payload HEADERS se liberaban de la contabilidad del control de flujo de recepción de QUIC mientras aún se retenían en un buffer de montón del decodificador interno, permitiendo a un atacante remoto provocar un crecimiento ilimitado de memoria y desencadenar una condición de falta de memoria.
- __[CVE-2026-47692](https://nvd.nist.gov/vuln/detail/CVE-2026-47692)__: (puntuación CVSS 4.8): Corregido un error donde los TLVs passthrough combinados con TLVs añadidos podían exceder la longitud máxima, resultando en una discrepancia entre el tamaño reportado en la cabecera y el número de bytes escritos. Esto podía permitir una solicitud contrabandeada desde el host que escribe la cabecera del protocolo PROXY al host upstream.
- __[CVE-2026-47207](https://nvd.nist.gov/vuln/detail/CVE-2026-47207)__: (puntuación CVSS 6.5): Corregido un error donde el servidor `ext_proc` envía `ProcessingResponses` inesperados a Envoy.
- __[CVE-2026-47205](https://nvd.nist.gov/vuln/detail/CVE-2026-47205)__: (puntuación CVSS 5.9): Corregido un crash de uso después de liberación en el filtro ext_authz cuando hay anulaciones de servicio por ruta activas y la conexión descendente se restablece durante una verificación de autorización en curso.
- __[CVE-2026-47220](https://nvd.nist.gov/vuln/detail/CVE-2026-47220)__: (puntuación CVSS 7.5): Corregido un error de crash en el formateador `%REQUESTED_SERVER_NAME%` donde el host o host original no está configurado correctamente pero el formateador está configurado para acceder al valor del host.
- __[CVE-2026-47221](https://nvd.nist.gov/vuln/detail/CVE-2026-47221)__: (puntuación CVSS 5.9): Corregido un problema al gestionar redirecciones internas HTTP 303 para solicitudes sin cuerpo. El código de gestión de redirecciones intentaba vaciar un buffer de cuerpo de solicitud que nunca fue asignado, causando un fallo de segmentación.
- __[CVE-2026-48044](https://nvd.nist.gov/vuln/detail/CVE-2026-48044)__: (puntuación CVSS 7.5): Corregida una vulnerabilidad de agotamiento de memoria en el descompresor Zstd donde el límite `MaxInflateRatio` solo se verificaba después de que cada segmento de entrada se procesara completamente, permitiendo que un payload comprimido maliciosamente diseñado se expandiera a cientos de MB dentro de una única llamada `process()`. El límite de ratio de inflado ahora se aplica dentro del bucle de descompresión interno, igualando los descompresores gzip y brotli y abortando la descompresión en cuanto se supera el umbral.
- __[CVE-2026-48090](https://nvd.nist.gov/vuln/detail/CVE-2026-48090)__: (puntuación CVSS 5.9): Corregido un error donde el callback de cambio de token asíncrono podía activarse después de que el filtro hubiera sido destruido (`onDestroy()` había sido llamado), lo que podía llevar a acceder a punteros colgantes y resultar en UAF/crash.
- __[CVE-2026-47778](https://nvd.nist.gov/vuln/detail/CVE-2026-47778)__: (puntuación CVSS 4.4): Corregido un problema donde Envoy podía no validar el Nombre Alternativo del Sujeto (SAN) de un certificado de par si el SAN contenía un byte NUL embebido. Anteriormente, el análisis de SAN era vulnerable a la truncación de byte NUL en algunas configuraciones, potencialmente llevando a decisiones de confianza incorrectas.
- __[CVE-2026-47204](https://nvd.nist.gov/vuln/detail/CVE-2026-47204)__: (puntuación CVSS 6.5): Corregido un crash o uso después de liberación cuando el filtro de estadísticas gRPC realiza el seguimiento de estadísticas en una ruta de respuesta directa.
- __[CVE-2026-48497](https://nvd.nist.gov/vuln/detail/CVE-2026-48497)__: (puntuación CVSS 5.9): Corregida la verificación de integridad de la longitud del nombre de consulta para evitar la terminación anormal del proceso.
- __[CVE-2026-48706](https://nvd.nist.gov/vuln/detail/CVE-2026-48706)__: (puntuación CVSS 5.9): Corregido un problema de desbordamiento de buffer en `TcpStatsdSink` con un nombre de estadística grande.
- __[CVE-2026-48743](https://nvd.nist.gov/vuln/detail/CVE-2026-48743)__: (puntuación CVSS 7.5): Corregida la validación de longitud de contenido para solicitudes y respuestas HTTP/3 solo con cabeceras y restablecimiento del flujo si es inconsistente. El cambio está protegido por el guard de runtime `envoy.reloadable_features.quic_validate_headers_only_content_length`.
- __[CVE-2026-47775](https://nvd.nist.gov/vuln/detail/CVE-2026-47775)__: (puntuación CVSS 6.8): Corregido un oráculo de relleno en el descifrado de cookies AES-256-CBC del filtro OAuth2. El filtro ahora soporta cifrado AES-256-GCM con un marcador de algoritmo `gcm.`, que autentifica el texto cifrado y elimina el oráculo.
- __[CVE-2026-48042](https://nvd.nist.gov/vuln/detail/CVE-2026-48042)__: (puntuación CVSS 7.5): Limitada la profundidad de anidamiento JSON a 1000. El límite podría relajarse a 10K estableciendo `envoy.reloadable_features.limit_json_parser_nesting_depth` en `false`.
