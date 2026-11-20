---
title: ISTIO-SECURITY-2023-001
subtitle: Boletín de seguridad
description: Varias vulnerabilidades reportadas por Envoy.
cves: [CVE-2023-27496, CVE-2023-27488, CVE-2023-27493, CVE-2023-27492, CVE-2023-27491, CVE-2023-27487]
cvss: "8.2"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N"
cvss_version: "3.0"
releases: ["All releases prior to 1.15.0", "1.15.0 to 1.15.6", "1.16.0 to 1.16.3", "1.17.0 to 1.17.1"]
publishdate: 2023-04-04
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE de Envoy

- __[CVE-2023-27487](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5375-pq35-hf2g)__: (Puntuación CVSS: 8.2, gravedad alta):
  Un cliente puede falsificar el encabezado `x-envoy-original-path`.

- __[CVE-2023-27488](https://github.com/envoyproxy/envoy/security/advisories/GHSA-9g5w-hqr3-w2ph)__: (Puntuación CVSS: 5.4, gravedad moderada):
  El cliente gRPC genera datos protobuf inválidos al recibir un encabezado HTTP con un valor que no está codificado en UTF-8.

- __[CVE-2023-27491](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5jmv-cw9p-f9rp)__: (Puntuación CVSS: 5.4, gravedad moderada):
  Envoy reenvía encabezados HTTP/2 y HTTP/3 inválidos recibidos del cliente.

- __[CVE-2023-27492](https://github.com/envoyproxy/envoy/security/advisories/GHSA-wpc2-2jp6-ppg2)__: (Puntuación CVSS: 4.8, gravedad moderada):
  El filtro Lua puede fallar al procesar un cuerpo de solicitud grande.

- __[CVE-2023-27493](https://github.com/envoyproxy/envoy/security/advisories/GHSA-w5w5-487h-qv8q)__: (Puntuación CVSS: 8.1, gravedad alta):
  Envoy omite el escape de los valores de los encabezados HTTP.

- __[CVE-2023-27496](https://github.com/envoyproxy/envoy/security/advisories/GHSA-j79q-2g66-2xv5)__: (Puntuación CVSS: 6.5, gravedad moderada):
  El filtro OAuth puede fallar al recibir una URL de redirección sin el parámetro de estado.

## ¿Estoy afectado?

Podrías estar en riesgo si tienes un gateway de Istio o usas un Istiod externo.
