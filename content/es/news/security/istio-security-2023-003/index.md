---
title: ISTIO-SECURITY-2023-003
subtitle: Boletín de seguridad
description: Vulnerabilidades reportadas por Envoy.
cves: [CVE-2023-35941,CVE-2023-35942,CVE-2023-35943,CVE-2023-35944]
cvss: "8.6"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:L"
releases: ["Todas las versiones anteriores a 1.16.0", "1.16.0 a 1.16.6", "1.17.0 a 1.17.4", "1.18.0 a 1.18.1"]
publishdate: 2023-07-25
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE de Envoy

- __[CVE-2023-35941](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7mhv-gr67-hq55)__: (Puntuación CVSS: 8.6, gravedad alta): Vulnerabilidad que permite el uso indebido de credenciales OAuth2 con validez indefinida.
- __[CVE-2023-35942](https://github.com/envoyproxy/envoy/security/advisories/GHSA-69vr-g55c-v2v4)__: (Puntuación CVSS: 6.5, gravedad moderada): Fallo en el registro de acceso gRPC durante el drenaje del listener.
- __[CVE-2023-35943](https://github.com/envoyproxy/envoy/security/advisories/GHSA-mc6h-6j9x-v3gq)__: (Puntuación CVSS: 6.3, gravedad moderada): Fallo de segmentación en el filtro CORS al eliminar el encabezado `Origin`.
- __[CVE-2023-35944](https://github.com/envoyproxy/envoy/security/advisories/GHSA-pvgm-7jpg-pw5g)__: (Puntuación CVSS: 8.2, gravedad alta): Envoy procesa incorrectamente las solicitudes y respuestas HTTP cuando el esquema combina mayúsculas y minúsculas.

## ¿Estoy afectado?

Te afecta si aceptas tráfico HTTP/2 de fuentes no confiables, algo que aplica a la mayoría de los usuarios. Esto es especialmente relevante si usas un `Gateway` expuesto a Internet.
