---
title: ISTIO-SECURITY-2025-001
subtitle: Security Bulletin
description: CVEs reportados por Envoy.
cves: [CVE-2025-55162, CVE-2025-54588]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.27.0", "1.26.0 to 1.26.3", "1.25.0 to 1.25.4"]
publishdate: 2025-09-03
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[CVE-2025-55162](https://github.com/envoyproxy/envoy/security/advisories/GHSA-95j4-hw7f-v2rh)__: (CVSS score 6.3, Moderate): La ruta de cierre de sesión del filtro OAuth2 no borrará las cookies debido a la falta de la bandera "secure;"
- __[CVE-2025-54588](https://github.com/envoyproxy/envoy/security/advisories/GHSA-g9vw-6pvx-7gmw)__: (CVSS score 7.5, High): Uso después de liberar en la caché DNS

## ¿Estoy afectado?

Estás afectado si estás usando Istio 1.27.0, 1.26.0 a 1.26.3, o 1.25.0 a 1.25.4, y usas cookies con el prefijo `__Secure-` o `__Host-`, o si estás usando `EnvoyFilter` con `dynamic_forward_proxy`.
