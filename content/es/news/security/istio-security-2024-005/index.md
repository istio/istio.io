---
title: ISTIO-SECURITY-2024-005
subtitle: Boletín de Seguridad
description: CVEs reportados por Envoy.
cves: []
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.21.0 to 1.21.3", "1.22.0 to 1.22.1"]
publishdate: 2024-06-27
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Envoy

- __[GHSA-8mq4-c2v5-3h39](https://github.com/envoyproxy/envoy/security/advisories/GHSA-8mq4-c2v5-3h39)__: (CVSS Score 7.5, Moderate): Datadog: el tracer de Datadog no gestiona las cabeceras de traza con caracteres Unicode.

## ¿Estoy afectado?

Estás afectado si utilizas Istio 1.21.0 a 1.21.3 o 1.22.0 a 1.22.1 y has habilitado el tracer de Datadog.
