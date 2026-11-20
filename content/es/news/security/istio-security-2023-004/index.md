---
title: ISTIO-SECURITY-2023-004
subtitle: Boletín de seguridad
description: Vulnerabilidades reportadas por Envoy y Go.
cves: [CVE-2023-44487, CVE-2023-39325]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.17.0", "1.17.0 to 1.17.6", "1.18.0 to 1.18.3", "1.19.0 to 1.19.1"]
publishdate: 2023-10-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE de Envoy

- __[`CVE-2023-44487`](https://nvd.nist.gov/vuln/detail/CVE-2023-44487)__: (Puntuación CVSS: 7.5, gravedad alta): Denegación de servicio en HTTP/2.

### CVE de Go

- __[`CVE-2023-39325`](https://github.com/golang/go/issues/63417)__: (Puntuación CVSS: 7.5, gravedad alta): Denegación de servicio en HTTP/2.

## ¿Estoy afectado?

Te afecta si aceptas tráfico HTTP/2 de fuentes no confiables. Esta situación es común, sobre todo si usas un `Gateway` expuesto a Internet.
