---
title: ISTIO-SECURITY-2025-003
subtitle: Security Bulletin
description: CVEs reportados por Envoy.
cves: [CVE-2025-66220, CVE-2025-64527, CVE-2025-64763]
cvss: "8.1"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N"
releases: ["1.28.0", "1.27.0 to 1.27.3", "1.26.0 to 1.26.6"]
publishdate: 2025-12-03
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[CVE-2025-66220](https://nvd.nist.gov/vuln/detail/CVE-2025-66220)__: (CVSS score 8.1, High): El comparador de certificados TLS para `match_typed_subject_alt_names`
puede tratar incorrectamente como válidos los certificados con SANs `OTHERNAME` que contienen un byte nulo incrustado.
- __[CVE-2025-64527](https://nvd.nist.gov/vuln/detail/CVE-2025-64527)__: (CVSS score 6.5, Medium): Envoy falla cuando la autenticación JWT está configurada con
la obtención remota de JWKS.
- __[CVE-2025-64763](https://nvd.nist.gov/vuln/detail/CVE-2025-64763)__: (CVSS score 5.3, Medium): Posible contrabando de solicitudes desde datos anticipados después de la
actualización CONNECT.

## ¿Estoy afectado?

Si estás usando Istio para aceptar tráfico WebSocket, eres potencialmente vulnerable al contrabando de solicitudes desde datos anticipados después de la actualización CONNECT. También puedes ser vulnerable si estás usando certificados personalizados con SANs OTHERNAME o autenticación JWT personalizada con obtención remota de JWKS usando `EnvoyFilter`.
