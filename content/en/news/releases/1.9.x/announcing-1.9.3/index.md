---
title: Announcing Istio 1.9.3
linktitle: 1.9.3
subtitle: Patch Release
description: Istio 1.9.3 patch release.
publishdate: 2021-04-15
release: 1.9.3
aliases:
    - /news/announcing-1.9.3
---

This release fixes the security vulnerability described in [our April 15th post](/news/security/istio-security-2021-003).

{{< relnote >}}

## Security update

- __[CVE-2021-28683](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-28683)__:
Envoy contains a remotely exploitable NULL pointer dereference and crash in TLS when an unknown TLS alert code is received.
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)
- __[CVE-2021-28682](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-28682)__:
Envoy contains a remotely exploitable integer overflow in which a very large grpc-timeout value leads to unexpected timeout calculations.
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)
- __[CVE-2021-29258](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-29258)__:
Envoy contains a remotely exploitable vulnerability where an HTTP2 request with an empty metadata map can cause Envoy to crash.
    - __CVSS Score__: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H&version=3.1)
