---
title: ISTIO-SECURITY-2023-002
subtitle: Boletín de seguridad
description: Vulnerabilidad reportada por Envoy.
cves: [CVE-2023-35945]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.16.0", "1.16.0 to 1.16.5", "1.17.0 to 1.17.3", "1.18.0"]
publishdate: 2023-07-14
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE de Envoy

- __[CVE-2023-35945](https://github.com/envoyproxy/envoy/security/advisories/GHSA-jfxv-29pc-x22r)__: (Puntuación CVSS: 7.5, gravedad alta):
  Fuga de memoria en el códec HTTP/2 `nghttp2`.

## ¿Estoy afectado?

Te afecta si aceptas tráfico HTTP/2 de fuentes no confiables. Esta situación es común, sobre todo si usas un `Gateway` expuesto a Internet.
