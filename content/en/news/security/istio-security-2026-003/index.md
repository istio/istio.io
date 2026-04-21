---
title: ISTIO-SECURITY-2026-003
subtitle: Security Bulletin
description: Istio security fixes for authorization bypass and SSRF.
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

### Istio CVEs

- __[CVE-2026-39350](https://nvd.nist.gov/vuln/detail/CVE-2026-39350)__ / __[GHSA-9gcg-w975-3rjh](https://github.com/istio/istio/security/advisories/GHSA-9gcg-w975-3rjh)__: (CVSS score 5.4, Moderate): `AuthorizationPolicy` `serviceAccounts` regex injection via unescaped dots.
  Reported by [Wernerina](https://github.com/Wernerina).

- __[CVE-2026-41413](https://nvd.nist.gov/vuln/detail/CVE-2026-41413)__ / __[GHSA-fgw5-hp8f-xfhc](https://github.com/istio/istio/security/advisories/GHSA-fgw5-hp8f-xfhc)__: (CVSS score 5.0, Moderate): SSRF via `RequestAuthentication` `jwksUri`.
  Reported by [KoreaSecurity](https://github.com/KoreaSecurity), [1seal](https://github.com/1seal), [AKiileX](https://github.com/AKiileX).

## Am I Impacted?

All users running affected Istio versions are potentially impacted:

- The **Authorization Bypass** impact is relevant if you use `AuthorizationPolicy` resources that specify `serviceAccounts` containing dots. An attacker could bypass an `ALLOW` policy or slip through a `DENY` policy by using a service account with a name that exploits the regex wildcard interpretation.

- The **SSRF** impact is relevant if you allow users or automated systems to create `RequestAuthentication` resources. An attacker could provide a `jwksUri` that points to internal metadata services or local host ports, potentially leaking sensitive internal data to the control plane via xDS configuration.

## Mitigation

- For Istio 1.29 users: Upgrade to **1.29.2** or later.
- For Istio 1.28 users: Upgrade to **1.28.6** or later.
