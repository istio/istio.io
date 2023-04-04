---
title: ISTIO-SECURITY-2023-001
subtitle: Security Bulletin
description: Multiple CVEs reported by Envoy.
cves: [CVE-2023-27496, CVE-2023-27488, CVE-2023-27493, CVE-2023-27492, CVE-2023-27491, CVE-2023-27487]
cvss: "8.2"
vector: "CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:L/A:N"
releases: ["All releases prior to 1.15.0", "1.15.0 to 1.15.6", "1.16.0 to 1.16.3", "1.17.0 to 1.17.1"]
publishdate: 2023-04-04
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### Envoy CVEs

- __CVE-2023-27487__: (CVSS Score 8.2, High):
Client may fake the header `x-envoy-original-path`.

- __CVE-2023-27488__: (CVSS Score 5.4, Moderate):
gRPC client produces invalid protobuf when an HTTP header with non-UTF8 value is received.

- __CVE-2023-27491__: (CVSS Score 5.4, Moderate):
Envoy forwards invalid HTTP/2 and HTTP/3 downstream headers.

- __CVE-2023-27492__: (CVSS Score 4.8, Moderate):
Crash when a large request body is processed in Lua filter.

- __CVE-2023-27493__: (CVSS Score 8.1, High):
Envoy doesn't escape HTTP header values.

- __CVE-2023-27496__: (CVSS Score 6.5, Moderate):
Crash when a redirect url without a state parameter is received in the OAuth filter.

## Am I Impacted?

You may be at risk if you have an Istio gateway or if you use external istiod.
