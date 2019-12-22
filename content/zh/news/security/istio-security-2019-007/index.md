---
title: ISTIO-SECURITY-2019-007
subtitle: Security Bulletin
description: Heap overflow and improper input validation in Envoy.
cves: [CVE-2019-18801,CVE-2019-18802]
cvss: "9.0"
vector: "CVSS:3.0/AV:N/AC:H/PR:N/UI:N/S:C/C:H/I:H/A:H"
releases: ["1.2 to 1.2.9", "1.3 to 1.3.5", "1.4 to 1.4.1"]
publishdate: 2019-12-10
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy, and subsequently Istio are vulnerable to two newly discovered vulnerabilities:

* __[CVE-2019-18801](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18801)__: This vulnerability affects Envoy’s HTTP/1 codec in its way it processes downstream's requests with large HTTP/2 headers. A successful exploitation of this vulnerability could lead to a denial of Service, escalation of privileges, or information disclosure.

* __[CVE-2019-18802](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18802)__: HTTP/1 codec incorrectly fails to trim whitespace after header values. This could allow an attacker to bypass Istio's policy either for information disclosure or escalation of privileges.

## Impact and detection

Both Istio gateways and sidecars are vulnerable to this issue. If you are running one of the affected releases where downstream's requests are HTTP/2 while upstream's are HTTP/1, then your cluster is vulnerable.  We expect this to be true of most clusters.

## Mitigation

* For Istio 1.2.x deployments: update to a [Istio 1.2.10](/zh/news/releases/1.2.x/announcing-1.2.10) or later.
* For Istio 1.3.x deployments: update to a [Istio 1.3.6](/zh/news/releases/1.3.x/announcing-1.3.6) or later.
* For Istio 1.4.x deployments: update to a [Istio 1.4.2](/zh/news/releases/1.4.x/announcing-1.4.2) or later.

{{< boilerplate "security-vulnerability" >}}
