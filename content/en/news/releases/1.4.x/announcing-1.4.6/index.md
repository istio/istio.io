---
title: Announcing Istio 1.4.6
linktitle: 1.4.6
subtitle: Patch Release
description: Istio 1.4.6 patch release.
publishdate: 2020-03-03
release: 1.4.6
aliases:
    - /news/announcing-1.4.6
---

This release contains fixes for the security vulnerabilities described in [our March 3rd, 2020 news post](/news/security/istio-security-2020-003). This release note describes what’s different between Istio 1.4.5 and Istio 1.4.6.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2020-003** Two Uncontrolled Resource Consumption and Two Incorrect Access Control Vulnerabilities in Envoy.

__[CVE-2020-8659](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8659)__: The Envoy proxy may consume excessive memory when proxying HTTP/1.1 requests or responses with many small (i.e. 1 byte) chunks. Envoy allocates a separate buffer fragment for each incoming or outgoing chunk with the size rounded to the nearest 4Kb and does not release empty chunks after committing data. Processing requests or responses with a lot of small chunks may result in extremely high memory overhead if the peer is slow or unable to read proxied data. The memory overhead could be two to three orders of magnitude more than configured buffer limits.

__[CVE-2020-8660](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8660)__: The Envoy proxy contains a TLS inspector that can be bypassed (not recognized as a TLS client) by a client using only TLS 1.3. Because TLS extensions (SNI, ALPN) are not inspected, those connections may be matched to a wrong filter chain, possibly bypassing some security restrictions.

__[CVE-2020-8661](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8661)__: The Envoy proxy may consume excessive amounts of memory when responding to pipelined HTTP/1.1 requests. In the case of illegally formed requests, Envoy sends an internally generated 400 error, which is sent to the `Network::Connection` buffer. If the client reads these responses slowly, it is possible to build up a large number of responses, and consume functionally unlimited memory. This bypasses Envoy’s overload manager, which will itself send an internally generated response when Envoy approaches configured memory thresholds, exacerbating the problem.

__[CVE-2020-8664](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8664)__: For the SDS TLS validation context in the Envoy proxy, the update callback is called only when the secret is received for the first time or when its value changes. This leads to a race condition where other resources referencing the same secret (e.g,. trusted CA) remain unconfigured until the secret's value changes, creating a potentially sizable window where a complete bypass of security checks from the static ("default") section can occur.

    This vulnerability only affects the SDS implementation of Istio's certificate rotation mechanism for Istio 1.4.5 and earlier which is only when SDS and mutual TLS are enabled. SDS is off by default and must be explicitly enabled by the operator in all versions of Istio prior to Istio 1.5. Istio's default secret distribution implementation based on Kubernetes secret mounts is not affected by this vulnerability.
