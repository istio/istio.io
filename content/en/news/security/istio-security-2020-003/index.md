---
title: ISTIO-SECURITY-2020-003
subtitle: Security Bulletin
description: Two Uncontrolled Resource Consumption and Two Incorrect Access Control Vulnerabilities in Envoy.
cves: [CVE-2020-8659, CVE-2020-8660, CVE-2020-8661, CVE-2020-8664]
cvss: "7.5"
releases: ["1.4 to 1.4.5"]
publishdate: 2020-03-03
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy, and subsequently Istio are vulnerable to four newly discovered vulnerabilities:

* __[CVE-2020-8659](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8659)__: The Envoy proxy may consume excessive memory when proxying HTTP/1.1 requests or responses with many small (i.e. 1 byte) chunks. Envoy allocates a separate buffer fragment for each incoming or outgoing chunk with the size rounded to the nearest 4Kb and does not release empty chunks after committing data. Processing requests or responses with a lot of small chunks may result in extremely high memory overhead if the peer is slow or unable to read proxied data. The memory overhead could be two to three orders of magnitude more than configured buffer limits.
    * CVSS Score: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:F](https://www.first.org/cvss/calculator/3.1#CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:F)

* __[CVE-2020-8660](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8660)__: The Envoy proxy contains a TLS inspector that can be bypassed (not recognized as a TLS client) by a client using only TLS 1.3. Because TLS extensions (SNI, ALPN) are not inspected, those connections may be matched to a wrong filter chain, possibly bypassing some security restrictions.
    * CVSS Score: 5.3 [AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N](https://www.first.org/cvss/calculator/3.0#CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N)

* __[CVE-2020-8661](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8661)__: The Envoy proxy may consume excessive amounts of memory when responding to pipelined HTTP/1.1 requests. In the case of illegally formed requests, Envoy sends an internally generated 400 error, which is sent to the `Network::Connection` buffer. If the client reads these responses slowly, it is possible to build up a large number of responses, and consume functionally unlimited memory. This bypasses Envoy’s overload manager, which will itself send an internally generated response when Envoy approaches configured memory thresholds, exacerbating the problem.
    * CVSS Score: 7.5 [AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:F](https://www.first.org/cvss/calculator/3.1#CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:F)

* __[CVE-2020-8664](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8664)__: For the SDS TLS validation context in the Envoy proxy, the update callback is called only when the secret is received for the first time or when its value changes. This leads to a race condition where other resources referencing the same secret (e.g,. trusted CA) remain unconfigured until the secret's value changes, creating a potentially sizable window where a complete bypass of security checks from the static ("default") section can occur.
    * CVSS Score: 5.3 [AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N](https://www.first.org/cvss/calculator/3.0#CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:N/A:N)

    This vulnerability only affects the SDS implementation of Istio's certificate rotation mechanism for Istio 1.4.5 and earlier which is only when SDS and mutual TLS are enabled. SDS is off by default and must be explicitly enabled by the operator in all versions of Istio prior to Istio 1.5. Istio's default secret distribution implementation based on Kubernetes secret mounts is not affected by this vulnerability.

    **Detection**

    To determine if SDS is enabled in your system, run:

    {{< text bash >}}
    $ kubectl get pod -l app=pilot -o yaml | grep SDS_ENABLED -A 1
    {{< /text >}}

    If the output contains:

    {{< text plain>}}
    -  name: SDS_ENABLED
    value: “true”
    {{< /text >}}

    your system has SDS enabled.

    To determine if mutual TLS is enabled in your system, run:

    {{< text bash >}}
    $ kubectl get destinationrule --all-namespaces -o yaml | grep trafficPolicy -A 2
    {{< /text >}}

    If the output contains:

    {{< text plain>}}
    --
    trafficPolicy:
    tls:
    mode: ISTIO_MUTUAL
    {{< /text >}}

    your system has mutual TLS enabled.

## Mitigation

* For Istio 1.4.x deployments: update to [Istio 1.4.6](/news/releases/1.4.x/announcing-1.4.6) or later.
* For Istio 1.5.x deployments: Istio 1.5.0 will contain the equivalent security fixes.

{{< boilerplate "security-vulnerability" >}}
