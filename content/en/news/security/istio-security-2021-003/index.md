---
title: ISTIO-SECURITY-2021-003
subtitle: Security Bulletin
description:
cves: [CVE-2021-28683, CVE-2021-28682, CVE-2021-29258]
cvss: "7.5"
vector: "AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.8.5", "1.9.0 to 1.9.2"]
publishdate: 2021-04-15
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy, and subsequently Istio, is vulnerable to several newly discovered vulnerabilities:

- __[CVE-2021-28683](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-28683)__:
Envoy contains a remotely exploitable NULL pointer dereference and crash in TLS when an unknown TLS alert code is received.
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)
- __[CVE-2021-28682](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-28682)__:
Envoy contains a remotely exploitable integer overflow in which a very large grpc-timeout value leads to unexpected timeout calculations.
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)
- __[CVE-2021-29258](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-29258)__:
Envoy contains a remotely exploitable vulnerability where an HTTP2 request with an empty metadata map can cause Envoy to crash.
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)

{{< boilerplate "security-vulnerability" >}}
