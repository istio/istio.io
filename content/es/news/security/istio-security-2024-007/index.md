---
title: ISTIO-SECURITY-2024-007
subtitle: Boletín de Seguridad
description: CVEs reportados por Envoy.
cves: [CVE-2024-53269, CVE-2024-53270, CVE-2024-53271]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.22.0 to 1.22.6", "1.23.0 to 1.23.3", "1.24.0 to 1.24.1"]
publishdate: 2024-12-18
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[CVE-2024-53269](https://github.com/envoyproxy/envoy/security/advisories/GHSA-mfqp-7mmj-rm53)__: (CVSS Score 4.5, Moderate): Happy Eyeballs: Se valida que las `additional_address` sean direcciones IP en lugar de causar un crash al ordenarlas.
- __[CVE-2024-53270](https://github.com/envoyproxy/envoy/security/advisories/GHSA-q9qv-8j52-77p3)__: (CVSS Score 7.5, High): HTTP/1: el envío de sobrecarga causa un crash cuando la solicitud se reinicia previamente.
- __[CVE-2024-53271](https://github.com/envoyproxy/envoy/security/advisories/GHSA-rmm5-h2wv-mg4f)__: (CVSS Score 7.1, High): HTTP/1.1: múltiples problemas con `envoy.reloadable_features.http1_balsa_delay_reset`.

## ¿Estoy afectado?

Estás afectado si utilizas Istio 1.22.0 a 1.22.6, 1.23.0 a 1.23.3 o 1.24 a 1.24.1; actualiza de inmediato. Si has creado un `EnvoyFilter` personalizado para habilitar el gestor de sobrecarga, evita usar el punto de sobrecarga `http1_server_abort_dispatch`.
