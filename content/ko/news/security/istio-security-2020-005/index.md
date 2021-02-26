---
title: ISTIO-SECURITY-2020-005
subtitle: Security Bulletin
description: Denial of service affecting telemetry v2.
cves: [CVE-2020-10739]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.4 to 1.4.8", "1.5 to 1.5.3"]
publishdate: 2020-05-12
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Istio 1.4 with telemetry v2 enabled and Istio 1.5 contain the following vulnerability when telemetry v2 is enabled:

* __[CVE-2020-10739](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-10739)__:
By sending a specially crafted packet, an attacker could trigger a Null Pointer Exception resulting in a Denial of Service. This could be sent to the ingress gateway or a sidecar.
    * CVSS Score: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:A/AC:L/PR:L/UI:N/S:C/C:H/I:H/A:N&version=3.1)

## Mitigation

* For Istio 1.4.x deployments: update to [Istio 1.4.9](/news/releases/1.4.x/announcing-1.4.9) or later.
* For Istio 1.5.x deployments: update to [Istio 1.5.4](/news/releases/1.5.x/announcing-1.5.4) or later.
* Workaround: Alternatively, you can disable telemetry v2 by running the following:

{{< text bash >}}
$ istioctl manifest apply --set values.telemetry.v2.enabled=false
{{< /text >}}

## Credit

We'd like to thank `Joren Zandstra` for the original bug report.

{{< boilerplate "security-vulnerability" >}}
