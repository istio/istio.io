---
title: ISTIO-SECURITY-2024-002
subtitle: Boletín de Seguridad
description: CVEs reportados por Envoy y Go.
cves: [CVE-2024-27919, CVE-2024-30255, CVE-2023-45288]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.19.0", "1.19.0 to 1.19.8", "1.20.0 to 1.20.4", "1.21.0"]
publishdate: 2024-04-08
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[CVE-2024-27919](https://github.com/envoyproxy/envoy/security/advisories/GHSA-gghf-vfxp-799r)__: (CVSS Score 7.5, High): HTTP/2: agotamiento de memoria debido a una inundación de frames CONTINUATION.
- __[CVE-2024-30255](https://github.com/envoyproxy/envoy/security/advisories/GHSA-j654-3ccm-vfmm)__: (CVSS Score 5.3, Moderate): HTTP/2: agotamiento de CPU debido a una inundación de frames CONTINUATION.

### CVEs de Go

*NOTA*: En el momento de la publicación, el CVE aún no tenía puntuación ni vector asignados.

- __[CVE-2023-45288](https://nvd.nist.gov/vuln/detail/CVE-2023-45288)__: (CVSS Score no publicado): Los frames HTTP/2 CONTINUATION pueden utilizarse para ataques DoS.

## ¿Estoy afectado?

Estás afectado si aceptas tráfico HTTP/2 de fuentes no confiables, lo que aplica a la mayoría de los usuarios. Esto aplica especialmente si utilizas un Gateway expuesto en Internet público.
