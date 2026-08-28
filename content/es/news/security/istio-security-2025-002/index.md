---
title: ISTIO-SECURITY-2025-002
subtitle: Security Bulletin
description: CVEs reportados por Envoy.
cves: [CVE-2025-55162, CVE-2025-54588]
cvss: "6.6"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.27.0 to 1.27.1", "1.26.0 to 1.26.5"]
publishdate: 2025-10-20
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[CVE-2025-62504](https://nvd.nist.gov/vuln/detail/CVE-2025-62504)__: (CVSS score 6.5, Medium): Un cuerpo de respuesta demasiado grande modificado por Lua hará que Envoy falle.
- __[CVE-2025-62409](https://nvd.nist.gov/vuln/detail/CVE-2025-62409)__: (CVSS score 6.6, Medium): Las solicitudes y respuestas grandes pueden causar el fallo del pool de conexiones TCP.

## ¿Estoy afectado?

Estás afectado si usas Lua a través de `EnvoyFilter` que devuelve un cuerpo de respuesta de tamaño excesivo que supera el `per_connection_buffer_limit_bytes` (1MB por defecto) o donde tienes solicitudes y respuestas grandes donde una conexión puede cerrarse pero aún se están enviando datos desde el upstream.
