---
title: ISTIO-SECURITY-2026-009
subtitle: Boletín de Seguridad
description: Correcciones de seguridad de Istio para omisiones de autorización y mTLS en modo ambient, omisión de la interceptación de tráfico del sidecar, y problemas de denegación de servicio en istiod y ztunnel.
cves: []
cvss: "8.2"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N"
releases: ["1.31.0 to 1.31.3", "1.30.0 to 1.30.7"]
publishdate: 2026-11-06
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE de Istio

- __[GHSA-rr2c-p22p-6r9r](https://github.com/istio/istio/security/advisories/GHSA-rr2c-p22p-6r9r)__ (puntuación CVSS 8.2, Alta): En modo ambient, un error de precedencia de operadores permitía omitir una `PeerAuthentication` `STRICT` a nivel de puerto cuando el modo del workload era `PERMISSIVE` o `DISABLE` bajo una política `STRICT` a nivel de toda la mesh, lo que permitía que tráfico en texto plano llegara a un puerto que requería mTLS.
  Reportado por Ravikanth Reddy.
- __[GHSA-7m6f-j3gp-2r53](https://github.com/istio/istio/security/advisories/GHSA-7m6f-j3gp-2r53)__ (puntuación CVSS 6.5, Moderada): Una condición `when` de `AuthorizationPolicy` sobre `request.headers[:authority]` o `request.headers[host]` se evaluaba distinguiendo mayúsculas de minúsculas, por lo que una solicitud con un host escrito con distinta capitalización podía eludirla.
  Reportado por [@akoul](https://github.com/akoul).
- __[GHSA-cxwg-46mx-q8hf](https://github.com/istio/istio/security/advisories/GHSA-cxwg-46mx-q8hf)__ (puntuación CVSS 7.4, Alta): Una nueva conexión entrante que reutilizaba la 4-tupla de una conexión ya cerrada podía eludir el proxy sidecar al coincidir con una entrada `ESTABLISHED` obsoleta de conntrack.
  Reportado por [@ramaraochavali](https://github.com/ramaraochavali), [@akshayreddyb](https://github.com/akshayreddyb), [@Pawan-Bishnoi](https://github.com/Pawan-Bishnoi) y [@deveshkandpal1224](https://github.com/deveshkandpal1224).
- __[GHSA-635j-qv98-9275](https://github.com/istio/istio/security/advisories/GHSA-635j-qv98-9275)__ (puntuación CVSS 7.7, Alta): Cualquier workload con una identidad de la mesh podía hacer fallar istiod enviando una solicitud xDS `istio.io/debug` cuyo nombre de recurso no superaba el análisis de URL, dejando el control plane en un bucle de fallos para toda la mesh.
  Reportado por Alon Lerner de Checkmarx Research.
- __[GHSA-8jw7-82jp-wr2c](https://github.com/istio/istio/security/advisories/GHSA-8jw7-82jp-wr2c)__ (puntuación CVSS 6.3, Moderada): En modo ambient, una `AuthorizationPolicy` con una entrada `to` o `from` vacía que el webhook de validación no rechazaba hacía que istiod fallara y entrara en un bucle de fallos hasta que se eliminaba la política.
  Reportado por [@r0binak](https://github.com/r0binak).
- __[GHSA-gf6w-6mxv-5fj4](https://github.com/istio/istio/security/advisories/GHSA-gf6w-6mxv-5fj4)__ (puntuación CVSS 6.3, Moderada): En instalaciones multiclúster, un proxy podía reclamar el `CLUSTER_ID` de otro clúster y recibir por SDS los secretos `kubernetes://` de ese clúster.
  Reportado por Yonghwa Lee (Xint by Theori).
- __[GHSA-77vw-rg85-wx5x](https://github.com/istio/istio/security/advisories/GHSA-77vw-rg85-wx5x)__ (puntuación CVSS 6.5, Moderada): ztunnel entraba en pánico al analizar un encabezado `traceparent` de 55 bytes que no contenía cuatro campos separados por guiones, descartando todos los streams multiplexados en esa conexión HBONE entrante.
  Reportado por [@RaphaelFakhri](https://github.com/RaphaelFakhri).
- __[GHSA-9gqj-583v-mpqp](https://github.com/istio/istio/security/advisories/GHSA-9gqj-583v-mpqp)__ (puntuación CVSS 5.6, Moderada): `ipBlocks`, `notIpBlocks` y la condición `source.ip` de `AuthorizationPolicy` en waypoints de ambient, y en sidecars que reciben tráfico HBONE, se evaluaban contra la dirección del listener interno de Envoy en lugar de la IP del cliente, por lo que las reglas `DENY` sobre estos campos podían fallar de forma permisiva.
  Reportado por [@adilfulara](https://github.com/adilfulara).

### Otras correcciones de seguridad de Istio

- La actualización periódica en segundo plano del resolutor de JWKS almacenaba en caché una respuesta obtenida sin validar que tuviera aspecto de JWKS. Ahora la actualización en segundo plano aplica la misma comprobación que la ruta de obtención síncrona.
  Reportado por Anthropic y Ada Logics.

## ¿Estoy afectado?

- **Modo ambient:** Estás potencialmente afectado por `GHSA-rr2c-p22p-6r9r` y `GHSA-8jw7-82jp-wr2c` si usas el modo ambient con recursos `PeerAuthentication` o `AuthorizationPolicy`, respectivamente.
- **Autorización:** Estás potencialmente afectado por `GHSA-7m6f-j3gp-2r53` si usas condiciones de `AuthorizationPolicy` sobre `request.headers[:authority]` o `request.headers[host]`. Estás potencialmente afectado por `GHSA-9gqj-583v-mpqp` si usas `ipBlocks`, `notIpBlocks` o `source.ip` en políticas que se aplican a waypoints de ambient o a sidecars que reciben tráfico HBONE. Como workaround, usa en su lugar `remoteIpBlocks`, `notRemoteIpBlocks` y `remote.ip`.
- **Interceptación del sidecar:** Estás potencialmente afectado por `GHSA-cxwg-46mx-q8hf` si usas la interceptación de tráfico del sidecar con iptables o nftables.
- **Multiclúster:** Estás potencialmente afectado por `GHSA-gf6w-6mxv-5fj4` si ejecutas instalaciones multiclúster.
- **Denegación de servicio:** Todas las instalaciones están potencialmente afectadas por `GHSA-635j-qv98-9275`, y las instalaciones en modo ambient por `GHSA-77vw-rg85-wx5x`.

## Mitigación

- Para usuarios de Istio 1.31: actualiza a **1.31.4** o posterior.
- Para usuarios de Istio 1.30: actualiza a **1.30.8** o posterior.
- Consulta la información del aviso de cada GHSA indicado arriba para obtener más detalles sobre las vulnerabilidades y sus mitigaciones.
