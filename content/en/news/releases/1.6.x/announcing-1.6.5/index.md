---
title: Announcing Istio 1.6.5
linktitle: 1.6.5
subtitle: Patch Release
description: Istio 1.6.5 patch release.
publishdate: 2020-07-09
release: 1.6.5
aliases:
    - /news/announcing-1.6.5
---

This release fixes the security vulnerability described in [our July 9th, 2020 news post](/news/security/istio-security-2020-008).

This release contains bug fixes to improve robustness. This release note describes
what’s different between Istio 1.6.5 and Istio 1.6.4.

{{< relnote >}}

## Security update

- __[`CVE-2020-15104`](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-15104)__:
When validating TLS certificates, Envoy incorrectly allows a wildcard DNS Subject Alternative Name apply to multiple subdomains. For example, with a SAN of `*.example.com`, Envoy incorrectly allows `nested.subdomain.example.com`, when it should only allow `subdomain.example.com`.
    - CVSS Score: 6.6 [AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C&version=3.1)

## Changes

- **Fixed** return the proper source name when mixer performing lookup by IP when multiple pods had the same IP.
- **Improved** Support to control sidecar injection based on revision at a per-pod level ([Issue 24801](https://github.com/istio/istio/issues/24801))
- **Improved** `istioctl validate` to disallow unknown field from spec ([Issue 24860](https://github.com/istio/istio/issues/24860))
- **Fixed** changed `stsPort` to `sts_port` in envoy bootstrap file.
- **Fixed** keep existing WASM state schema since it can be referenced by state objects later.
- **Improved** added `targetUri` in `stackdriver_grpc_service`.
- **Improved** updated WASM state to log for Access Log Service.
- **Updated** raised default protocol detection timeout from 100 Milliseconds to 5 seconds ([Issue 24379](https://github.com/istio/istio/issues/24379))
- **Updated** removed UDP port 53 from Istiod service.
- **Fixed** allow setting `status.sidecar.istio.io/port` to zero ([Issue 24722](https://github.com/istio/istio/issues/24722))
- **Fixed**  support eds endpoint selection for subsets with no or empty label selector. ([Issue 24969](https://github.com/istio/istio/issues/24969))
- **Fixed** fix wrong error log in operator.
- **Fixed** allow `k8s.overlays` on `BaseComponentSpec`. ([Issue 24476](https://github.com/istio/istio/issues/24476))
- **Fixed** istio-agent to create `eliptical` curve CSRs when `ECC_SIGNATURE_ALGORITHM` is set.
- **Improved** map grpc status codes into http domain for metrics.
- **Fixed** fix `scaleTargetRef` naming in `HorizontalPodAutoscaler` for istiod ([Issue 24809](https://github.com/istio/istio/issues/24809))
