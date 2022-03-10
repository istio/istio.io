---
title: Announcing Istio 1.13.2
linktitle: 1.13.2
subtitle: Patch Release
description: Istio 1.13.2 patch release.
publishdate: 2022-03-09
release: 1.13.2
aliases:
    - /news/announcing-1.13.2
---

This release fixes the security vulnerabilities described in our March 9th post, [ISTIO-SECURITY-2022-004](/news/security/istio-security-2022-004).
This release note describes what’s different between Istio 1.13.1 and 1.13.2.

{{< relnote >}}

## Security update

- __[CVE-2022-24726](https://github.com/istio/istio/security/advisories/GHSA-8w5h-qr4r-2h6g)__:
  (CVSS Score 7.5, High): Unauthenticated control plane denial of service attack due to stack exhaustion.

## Changes

- **Added** an OpenTelemetry access log provider.
([Issue #36637](https://github.com/istio/istio/issues/36637))

- **Added** support for using default JSON access logs format with Telemetry API.
  ([Issue #37663](https://github.com/istio/istio/issues/37663))

- **Fixed** `describe pod` not showing the VirtualService info if the gateway is set to TLS ingress gateway.
  ([Issue #35301](https://github.com/istio/istio/issues/35301))

- **Fixed** an issue where `traffic.sidecar.istio.io/includeOutboundPorts` annotation does not take effect when using CNI.
  ([Issue #37637](https://github.com/istio/istio/pull/37637))

- **Fixed** an issue where when enabling Stackdriver metrics collection with the Telemetry API, logging was incorrectly enabled in certain scenarios.
  ([Issue #37667](https://github.com/istio/istio/issues/37667))

### Envoy CVEs

At this time it is not believed that Istio is vulnerable to these CVEs in Envoy. They are listed, however,
to be transparent.

- __[CVE-2022-21656](https://github.com/envoyproxy/envoy/security/advisories/GHSA-c9g7-xwcv-pjx2)__
  (CVSS Score 3.1, Low):X.509 `subjectAltName` matching (and `nameConstraints`) bypass.

- __[CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g)__
  (CVSS Score 3.1, Low): X.509 Extended Key Usage and Trust Purposes bypass.
