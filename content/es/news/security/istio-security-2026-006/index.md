---
title: ISTIO-SECURITY-2026-006
subtitle: Boletín de Seguridad
description: CVEs reportados por Envoy, una denegación de servicio en el control plane mediante EnvoyFilter y un fallo abierto de BackendTLSPolicy en sidecars.
cves: [CVE-2026-73513, CVE-2026-73552, CVE-2026-73512, CVE-2026-73547, CVE-2026-73549, CVE-2026-50572, CVE-2026-73546, CVE-2026-48521, CVE-2026-73551, CVE-2026-73511, CVE-2026-73548, CVE-2026-73550, CVE-2026-73553]
cvss: "7.7"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:N/I:N/A:H"
releases: ["1.29.0 to 1.29.6", "1.30.0 to 1.30.3"]
publishdate: 2026-08-27
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[CVE-2026-73513](https://nvd.nist.gov/vuln/detail/CVE-2026-73513)__: (CVSS score 7.5): Se corrigió un heap use-after-free donde un upstream no confiable podía enviar trailers de respuesta HTTP/2 sin el flag `END_STREAM` a una instancia de Envoy que utiliza `oghttp2`, corrompiendo el estado del stream y terminando el proceso.
- __[CVE-2026-73552](https://nvd.nist.gov/vuln/detail/CVE-2026-73552)__: (CVSS score 7.5): Se corrigió un problema donde la coincidencia con `safe_regex` trataba los bytes de cabeceras HTTP no UTF-8 aceptados como una no-coincidencia; en políticas RBAC que usan coincidencia negativa, esto podía fallar abierto y permitir acceso a un recurso protegido.
- __[CVE-2026-73512](https://nvd.nist.gov/vuln/detail/CVE-2026-73512)__: (CVSS score 7.5): Se corrigió un use-after-free en el manejador de datagramas HTTP QUIC donde los datagramas HTTP/3 tardíos podían referenciar un decodificador de stream que ya había sido destruido o reemplazado.
- __[CVE-2026-73547](https://nvd.nist.gov/vuln/detail/CVE-2026-73547)__: (CVSS score 7.5): Se corrigió una terminación anormal del proceso en el filtro `ext_authz` al procesar solicitudes CONNECT sin un pseudo-header `:path`.
- __[CVE-2026-73549](https://nvd.nist.gov/vuln/detail/CVE-2026-73549)__: (CVSS score 5.3): Se corrigió una terminación anormal del proceso para direcciones de cliente IPv6 con ámbito en clústeres de DST original con HTTP/3.
- __[CVE-2026-50572](https://nvd.nist.gov/vuln/detail/CVE-2026-50572)__: (CVSS score 5.9): Se corrigió un use-after-free en el cliente HTTP sin procesar de `ext_authz` donde completar una solicitud de autorización podía destruir el cliente mientras su manejador de finalización aún se estaba ejecutando.
- __[CVE-2026-73546](https://nvd.nist.gov/vuln/detail/CVE-2026-73546)__: (CVSS score 7.4): Se corrigió un problema de cross-site scripting almacenado en la interfaz de estadísticas HTML (`/stats?format=html`) donde las estadísticas con nombres dinámicos podían introducir contenido controlado por el atacante.
- __[CVE-2026-48521](https://nvd.nist.gov/vuln/detail/CVE-2026-48521)__: (CVSS score 5.9): Se corrigió una terminación anormal del proceso donde Envoy podía desreferenciar opciones de socket de transporte nulas durante la selección del pool de conexiones HTTP/3 basada en ALPN.
- __[CVE-2026-73551](https://nvd.nist.gov/vuln/detail/CVE-2026-73551)__: (CVSS score 5.3): Se corrigió la normalización de URL de segmentos de ruta punto y punto-punto que contenían parámetros, lo que podía causar que los componentes de control de acceso y las aplicaciones upstream interpretaran una ruta de solicitud de forma diferente.
- __[CVE-2026-73511](https://nvd.nist.gov/vuln/detail/CVE-2026-73511)__: (CVSS score 5.3): Se corrigió la coincidencia de rutas para rutas que contenían parámetros por segmento, donde Envoy y los backends podían seleccionar recursos diferentes para la misma solicitud y eludir la selección basada en rutas o la autenticación.
- __[CVE-2026-73548](https://nvd.nist.gov/vuln/detail/CVE-2026-73548)__: (CVSS score 7.5): Se corrigió el envenenamiento de respuestas entre usuarios que involucraba actualizaciones HTTP genéricas sin WebSocket, donde el payload de solicitud enviado antes de que se aceptara una actualización podía contaminar una conexión upstream compartida.
- __[CVE-2026-73550](https://nvd.nist.gov/vuln/detail/CVE-2026-73550)__: (CVSS score 7.5): Se corrigió un problema de agotamiento de memoria en HTTP/2 donde las cabeceras Host duplicadas descartadas no se contabilizaban en los límites de tamaño y número de cabeceras de solicitud.
- __[CVE-2026-73553](https://nvd.nist.gov/vuln/detail/CVE-2026-73553)__: (CVSS score 7.5): Se corrigió un bypass de autorización cuando `ignore_path_parameters_in_path_matching` estaba habilitado, donde una ruta como `/admin;x` podía eludir una política RBAC para `/admin` mientras seguía alcanzando la ruta protegida.

### CVEs de Istio

- [GHSA-qm8v-g4f9-qhjx](https://github.com/istio/istio/security/advisories/GHSA-qm8v-g4f9-qhjx) (CVSS score 6.8, Moderate): `BackendTLSPolicy` falla abierto hacia texto plano en proxies sidecar cuando su referencia de CA no está resuelta.
  Reportado por [@thc1006](https://github.com/thc1006).

## Denegación de servicio en el control plane mediante `EnvoyFilter` `proxyVersion`

La expresión de coincidencia `proxyVersion` en el recurso `EnvoyFilter` (`spec.configPatches[].match.proxy.proxyVersion`) aceptaba una expresión regular de longitud ilimitada. Istiod compila esta expresión durante la validación de admisión y nuevamente durante la distribución de configuración. Un usuario con permiso para crear recursos `EnvoyFilter` en un único namespace podía enviar expresiones muy largas que provocaban un uso excesivo de memoria y CPU en istiod, pudiendo colapsar el control plane. Dado que el webhook de validación está configurado para fallar cerrado, los cambios de configuración para todos los namespaces de la mesh se rechazan mientras istiod no está disponible, extendiendo el impacto más allá del propio namespace del atacante.

Las versiones anteriores de Istio sin soporte también están afectadas.

La expresión de coincidencia `proxyVersion` ahora está limitada a 1024 caracteres.

## ¿Estoy afectado?

- **CVEs de Envoy:** Estás potencialmente afectado si ejecutas una versión afectada de Istio, que incluye el proxy Envoy afectado. La exposición específica depende de las funcionalidades en uso (por ejemplo, HTTP/3, `ext_authz`, RBAC o la interfaz de estadísticas de administración); consulta cada CVE anterior.

- **Denegación de servicio en EnvoyFilter:** Estás afectado si se permite a usuarios que no son administradores de la mesh crear o actualizar recursos `EnvoyFilter`, por ejemplo en entornos multi-tenant basados en namespaces. Las meshes donde solo los administradores pueden gestionar recursos `EnvoyFilter` no están expuestas a entradas no confiables, pero de todos modos deben actualizar.

- **Fallo abierto de `BackendTLSPolicy`:** Estás afectado si utilizas un `BackendTLSPolicy` para tráfico upstream de la mesh (sidecar) y el `caCertificateRefs` de la política puede volverse irresoluble (por ejemplo, el `ConfigMap` referenciado se elimina, renombra o está ausente). En ese caso, el sidecar envía el tráfico upstream en texto plano en lugar de bloquearlo, perdiendo el cifrado y la validación de CA que requería la política. Los proxies Gateway (ingress) no están afectados; fallan cerrado.

## Mitigación

- Para usuarios de Istio 1.30: actualiza a **1.30.4** o posterior.
- Para usuarios de Istio 1.29: actualiza a **1.29.7** o posterior.
- Como medida provisional para la denegación de servicio en `EnvoyFilter`, restringe los permisos de creación y actualización de `EnvoyFilter` a administradores de confianza usando RBAC de Kubernetes.

El Comité de Seguridad de Istio agradece a [Artem Cherezov](https://github.com/cherez0ff) y [@thc1006](https://github.com/thc1006) por divulgar responsablemente estos problemas.
