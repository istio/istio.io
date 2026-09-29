---
title: ISTIO-SECURITY-2024-004
subtitle: Boletín de Seguridad
description: CVEs reportados por Envoy.
cves: [CVE-2024-32976, CVE-2024-32975, CVE-2024-32974, CVE-2024-34363, CVE-2024-34362, CVE-2024-23326, CVE-2024-34364]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.20.0", "1.20.0 to 1.20.6", "1.21.0 to 1.21.2", "1.22.0"]
publishdate: 2024-06-04
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[CVE-2024-23326](https://github.com/envoyproxy/envoy/security/advisories/GHSA-vcf8-7238-v74c)__: (CVSS Score 5.9, Moderate): Manejo incorrecto de respuestas a solicitudes de actualización HTTP/1 que puede provocar contrabando de solicitudes.

- __[CVE-2024-32974](https://github.com/envoyproxy/envoy/security/advisories/GHSA-mgxp-7hhp-8299)__: (CVSS Score 5.9, Moderate): Vulnerabilidad en la pila QUIC que puede provocar la terminación anormal del proceso.

- __[CVE-2024-32975](https://github.com/envoyproxy/envoy/security/advisories/GHSA-g9mq-6v96-cpqc)__: (CVSS Score 5.9, Moderate): Vulnerabilidad en la pila QUIC que puede provocar la terminación anormal del proceso.

- __[CVE-2024-32976](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7wp5-c2vq-4f8m)__: (CVSS Score 7.5, High): Vulnerabilidad en el descompresor `Brotli` que puede provocar un bucle infinito.

- __[CVE-2024-34362](https://github.com/envoyproxy/envoy/security/advisories/GHSA-hww5-43gv-35jv)__: (CVSS Score 5.9, Moderate): Vulnerabilidad en la pila QUIC que puede provocar la terminación anormal del proceso.

- __[CVE-2024-34363](https://github.com/envoyproxy/envoy/security/advisories/GHSA-g979-ph9j-5gg4)__: (CVSS Score 7.5, High): Vulnerabilidad en el formateador JSON de logs de acceso de Envoy que puede provocar la terminación anormal del proceso.

- __[CVE-2024-34364](https://github.com/envoyproxy/envoy/security/advisories/GHSA-xcj3-h7vf-fw26)__: (CVSS Score 5.7, Moderate): Consumo ilimitado de memoria en `ext_proc` y `ext_authz`.

## ¿Estoy afectado?

Si utilizas el formato de log de acceso JSON en Istio 1.22, estás afectado; actualiza lo antes posible. El contrabando de solicitudes también afectará a los usuarios de Websockets.
