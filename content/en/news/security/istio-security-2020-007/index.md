---
title: ISTIO-SECURITY-2020-007
subtitle: Security Bulletin
description: Multiple denial of service vulnerabilities in Envoy.
cves: [CVE-2020-12603, CVE-2020-12605, CVE-2020-8663, CVE-2020-12604]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.5 to 1.5.6", "1.6 to 1.6.3"]
publishdate: 2020-06-30
keywords: [CVE]
skip_seealso: true
---

CVE-2020-8663 is addressed in Envoy by adding a configurable limit on [downstream connections](https://www.envoyproxy.io/docs/envoy/v1.14.3/configuration/operations/overload_manager/overload_manager#limiting-active-connections). The limit must be configured to mitigate this vulnerability. Perform the following steps to configure limits at the ingress gateway.

{{< security_bulletin >}}

Envoy, and subsequently Istio, are vulnerable to four newly discovered vulnerabilities:

* __[CVE-2020-12603](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-12603)__:
By sending a specially crafted packet, an attacker could cause Envoy to consume excessive amounts of memory when proxying HTTP/2 requests or responses.
    * CVSS Score: 7.0 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

* __[CVE-2020-12605](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-12605)__:
An attacker could cause Envoy to consume excessive amounts of memory when processing specially crafted HTTP/1.1 packets.
    * CVSS Score: 7.0 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

* __[CVE-2020-8663](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8663)__:
An attacker could cause Envoy to exhaust file descriptors when accepting too many connections.
    * CVSS Score: 7.0 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

* __[CVE-2020-12604](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-12604)__:
An attacker could cause increased memory usage when processing specially crafted packets.
    * CVSS Score: 5.3 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:L](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

## Mitigation

* For Istio 1.5.x deployments: update to [Istio 1.5.7](/news/releases/1.5.x/announcing-1.5.7) or later.
* For Istio 1.6.x deployments: update to [Istio 1.6.4](/news/releases/1.6.x/announcing-1.6.4) or later.

{{< warning >}}
You must take the following additional steps to mitigate CVE-2020-8663.
{{< /warning >}}

{{< boilerplate cve-2020-007-configmap >}}

{{< boilerplate "security-vulnerability" >}}
