---
title: ISTIO-SECURITY-2024-003
subtitle: Boletín de Seguridad
description: CVEs reportados por Envoy.
cves: [CVE-2024-32475]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.19.0", "1.19.0 to 1.19.9", "1.20.0 to 1.20.5", "1.21.0 to 1.21.1"]
publishdate: 2024-04-22
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[CVE-2024-32475](https://github.com/envoyproxy/envoy/security/advisories/GHSA-3mh5-6q8v-25wj)__: (CVSS Score 7.5, High): Terminación anormal al usar `auto_sni` con una cabecera `:authority` de más de 255 caracteres.

## ¿Estoy afectado?

Estás afectado si habilitaste la funcionalidad `auto_sni` de Envoy, utilizas versiones de Istio 1.21.0 o superiores donde estaba habilitada por defecto, o
utilizas un Egress Gateway.
