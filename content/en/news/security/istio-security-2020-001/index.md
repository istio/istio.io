---
title: ISTIO-SECURITY-2020-001
subtitle: Security Bulletin
description: Authentication Policy bypass.
cves: [CVE-2020-8595]
cvss: "9.0"
vector: "AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:H/A:H"
releases: ["1.3 to 1.3.7", "1.4 to 1.4.3"]
publishdate: 2020-02-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Istio 1.3 to 1.3.7 and 1.4 to 1.4.3 are vulnerable to a newly discovered vulnerability affecting [Authentication Policy](/docs/reference/config/security/istio.authentication.v1alpha1/#Policy):

* __[CVE-2020-8595](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8595)__: A bug in Istio's Authentication Policy exact path matching logic allows unauthorized access to resources without a valid JWT token. This bug affects all versions of Istio that support JWT Authentication Policy with path based trigger rules. The logic for the exact path match in the Istio JWT filter includes query strings or fragments instead of stripping them off before matching. This means attackers can bypass the JWT validation by appending `?` or `#` characters after the protected paths.
    * CVSS Score: 9.0 [AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:H/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:H/A:H&version=3.1)

## Mitigation

* For Istio 1.3.x deployments: update to [Istio 1.3.8](/news/releases/1.3.x/announcing-1.3.8) or later.
* For Istio 1.4.x deployments: update to [Istio 1.4.4](/news/releases/1.4.x/announcing-1.4.4) or later.

## Credit

The Istio team would like to thank [Aspen Mesh](https://aspenmesh.com/2H8qf3r) for the original bug report and code fix of [CVE-2020-8595](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8595).

{{< boilerplate "security-vulnerability" >}}
