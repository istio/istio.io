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

This release contains bug fixes to improve robustness. These release notes describe
what’s different between Istio 1.6.5 and Istio 1.6.4.

{{< relnote >}}

## Security update

- __[CVE-2020-15104](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-15104)__:
When validating TLS certificates, Envoy incorrectly allows a wildcard DNS Subject Alternative Name to apply to multiple subdomains. For example, with a SAN of `*.example.com`, Envoy incorrectly allows `nested.subdomain.example.com`, when it should only allow `subdomain.example.com`.
    - CVSS Score: 6.6 [AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=AV:N/AC:H/PR:H/UI:N/S:C/C:H/I:L/A:N/E:F/RL:O/RC:C&version=3.1)

## Changes

- **Fixed** return the proper source name after Mixer does a lookup by IP if multiple pods have the same IP.
- **Improved** the sidecar injection control based on revision at a per-pod level ([Issue 24801](https://github.com/istio/istio/issues/24801))
- **Improved** `istioctl validate` to disallow unknown fields not included in the Open API specification ([Issue 24860](https://github.com/istio/istio/issues/24860))
- **Changed** `stsPort` to `sts_port` in Envoy's bootstrap file.
- **Preserved** existing WASM state schema for state objects to reference it later as needed.
- **Added** `targetUri` to `stackdriver_grpc_service`.
- **Updated** WASM state to log for Access Log Service.
- **Increased** default protocol detection timeout from 100 ms to 5 s ([Issue 24379](https://github.com/istio/istio/issues/24379))
- **Removed** UDP port 53 from Istiod.
- **Allowed** setting `status.sidecar.istio.io/port` to zero ([Issue 24722](https://github.com/istio/istio/issues/24722))
- **Fixed**  EDS endpoint selection for subsets with no or empty label selector. ([Issue 24969](https://github.com/istio/istio/issues/24969))
- **Allowed** `k8s.overlays` on `BaseComponentSpec`. ([Issue 24476](https://github.com/istio/istio/issues/24476))
- **Fixed** `istio-agent` to create _elliptical_ curve CSRs when `ECC_SIGNATURE_ALGORITHM` is set.
- **Improved** mapping of gRPC status codes into HTTP domain for telemetry.
- **Fixed** `scaleTargetRef` naming in `HorizontalPodAutoscaler` for Istiod ([Issue 24809](https://github.com/istio/istio/issues/24809))
