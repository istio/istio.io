---
title: ISTIO-SECURITY-2019-004
subtitle: Security Bulletin
description: Multiple denial of service vulnerabilities related to HTTP2 support in Envoy.
cves: [CVE-2019-9512, CVE-2019-9513, CVE-2019-9514, CVE-2019-9515, CVE-2019-9518]
cvss: "7.5"
vector: "CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.1 to 1.1.12", "1.2 to 1.2.3"]
publishdate: 2019-08-13
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy, and subsequently Istio are vulnerable to a series of trivial HTTP/2-based DoS attacks:

* HTTP/2 flood using PING frames and queuing of response PING ACK frames that results in unbounded memory growth (which can lead to out of memory conditions).
* HTTP/2 flood using PRIORITY frames that results in excessive CPU usage and starvation of other clients.
* HTTP/2 flood using HEADERS frames with invalid HTTP headers and queuing of response `RST_STREAM` frames that results in unbounded memory growth (which can lead to out of memory conditions).
* HTTP/2 flood using SETTINGS frames and queuing of SETTINGS ACK frames that results in unbounded memory growth (which can lead to out of memory conditions).
* HTTP/2 flood using frames with an empty payload that results in excessive CPU usage and starvation of other clients.

Those vulnerabilities were reported externally and affect multiple proxy implementations.
See [this security bulletin](https://github.com/Netflix/security-bulletins/blob/master/advisories/third-party/2019-002.md) for more information.

## Impact and detection

If Istio terminates externally originated HTTP then it is vulnerable.   If Istio is instead fronted by an intermediary that terminates HTTP (e.g., a HTTP load balancer), then that intermediary would protect Istio, assuming the intermediary is not itself vulnerable to the same HTTP/2 exploits.

## Mitigation

* For Istio 1.1.x deployments: update to a [Istio 1.1.13](/pt-br/news/releases/1.1.x/announcing-1.1.13) or later.
* For Istio 1.2.x deployments: update to a [Istio 1.2.4](/pt-br/news/releases/1.2.x/announcing-1.2.4) or later.

{{< boilerplate "security-vulnerability" >}}
