---
title: ISTIO-SECURITY-2026-003
subtitle: Security Bulletin
description: Correcciones de seguridad de Istio para bypass de autorización y SSRF.
cves: [CVE-2026-39350, CVE-2026-XXXXX]
cvss: "5.4"
vector: "CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:U/C:L/I:L/A:N"
releases: ["1.29.0 to 1.29.1", "1.28.0 to 1.28.5"]
publishdate: 2026-04-20
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVEs de Istio

- __[CVE-2026-39350](https://nvd.nist.gov/vuln/detail/CVE-2026-39350)__ / __[GHSA-9gcg-w975-3rjh](https://github.com/istio/istio/security/advisories/GHSA-9gcg-w975-3rjh)__: (CVSS score 5.4, Moderate): Inyección de regex en `serviceAccounts` de `AuthorizationPolicy` a través de puntos sin escapar.
  Reportado por [Wernerina](https://github.com/Wernerina).

- __[CVE-2026-41413](https://nvd.nist.gov/vuln/detail/CVE-2026-41413)__ / __[GHSA-fgw5-hp8f-xfhc](https://github.com/istio/istio/security/advisories/GHSA-fgw5-hp8f-xfhc)__: (CVSS score 5.0, Moderate): SSRF a través de `jwksUri` en `RequestAuthentication`.
  Reportado por [KoreaSecurity](https://github.com/KoreaSecurity), [1seal](https://github.com/1seal), [AKiileX](https://github.com/AKiileX).

## ¿Estoy afectado?

Todos los usuarios que ejecutan versiones afectadas de Istio son potencialmente afectados:

- El impacto del **Bypass de Autorización** es relevante si usas recursos `AuthorizationPolicy` que especifican `serviceAccounts` que contienen puntos. Un atacante podría eludir una política `ALLOW` o atravesar una política `DENY` utilizando una cuenta de servicio con un nombre que explota la interpretación de comodín de expresión regular.

- El impacto de **SSRF** es relevante si permites que usuarios o sistemas automatizados creen recursos `RequestAuthentication`. Un atacante podría proporcionar un `jwksUri` que apunte a servicios de metadatos internos o puertos del host local, potencialmente filtrando datos internos sensibles al plano de control a través de la configuración xDS.

## Mitigación

- Para usuarios de Istio 1.29: Actualiza a **1.29.2** o posterior.
- Para usuarios de Istio 1.28: Actualiza a **1.28.6** o posterior.
