---
title: Announcing Istio 1.17.2
linktitle: 1.17.2
subtitle: Patch Release
description: Istio 1.17.2 patch release.
publishdate: 2023-04-04T07:00:00-06:00
release: 1.17.2
---

This release fixes the security vulnerabilities described in our April 4th post, [ISTIO-SECURITY-2023-001](/news/security/istio-security-2023-001).
This release note describes what’s different between Istio 1.17.1 and 1.17.2.

{{< relnote >}}

## Security update

- __[CVE-2023-27487](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5375-pq35-hf2g)__: (CVSS Score 8.2, High):
Client may fake the header `x-envoy-original-path`.

- __[CVE-2023-27488](https://github.com/envoyproxy/envoy/security/advisories/GHSA-9g5w-hqr3-w2ph)__: (CVSS Score 5.4, Moderate):
gRPC client produces invalid protobuf when an HTTP header with non-UTF8 value is received.

- __[CVE-2023-27491](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5jmv-cw9p-f9rp)__: (CVSS Score 5.4, Moderate):
Envoy forwards invalid HTTP/2 and HTTP/3 downstream headers.

- __[CVE-2023-27492](https://github.com/envoyproxy/envoy/security/advisories/GHSA-wpc2-2jp6-ppg2)__: (CVSS Score 4.8, Moderate):
Crash when a large request body is processed in Lua filter.

- __[CVE-2023-27493](https://github.com/envoyproxy/envoy/security/advisories/GHSA-w5w5-487h-qv8q)__: (CVSS Score 8.1, High):
Envoy doesn't escape HTTP header values.

- __[CVE-2023-27496](https://github.com/envoyproxy/envoy/security/advisories/GHSA-j79q-2g66-2xv5)__: (CVSS Score 6.5, Moderate):
Crash when a redirect url without a state parameter is received in the OAuth filter.

## Changes

- **Added** support for pushing additional federated trust domains from `caCertificates` to the peer SAN validator.
  ([Issue #41666](https://github.com/istio/istio/issues/41666))

- **Fixed** overwriting label `istio.io/rev` in injected gateways when `istio.io/rev=<tag>`.
  ([Issue #33237](https://github.com/istio/istio/issues/33237))

- **Fixed** an issue where you could not disable tracing in `ProxyConfig`.
  ([Issue #31809](https://github.com/istio/istio/issues/31809))

- **Fixed** admission webhook fails with custom header value format.
  ([Issue #42749](https://github.com/istio/istio/issues/42749))

- **Fixed** a bug that would cause unexpected behavior when applying access logging configuration based on the direction of traffic. With this fix, access logging configuration for `CLIENT` or `SERVER` will not affect each other.
  ([Issue #43371](https://github.com/istio/istio/issues/43371))

- **Fixed** an issue where `EnvoyFilter` for `Cluster.ConnectTimeout` was affecting unrelated `Clusters`.
  ([Issue #43435](https://github.com/istio/istio/issues/43435))

- **Fixed** a bug in `istioctl analyze` where some messages are missed when there are services with no selector in the analyzed namespace.
  ([PR #43678](https://github.com/istio/istio/pull/43678))

- **Fixed** resource namespace resolution for `istioctl` commands.
  ([Issue #43691](https://github.com/istio/istio/issues/43691))

- **Fixed** an issue where auto allocated service entry IPs change on host reuse.
  ([Issue #43858](https://github.com/istio/istio/issues/43858))

- **Fixed** an issue where RBAC updates were not sent to older proxies after upgrading istiod to 1.17.
  ([Issue #43785](https://github.com/istio/istio/issues/43785))

- **Fixed** reconciliation logic in the validation webhook controller to rate-limit the retries in the loop. This should drastically reduce churn (and generated logs) in cases of misconfiguration.
  ([Issue #32210](https://github.com/istio/istio/issues/32210))

- **Fixed** an issue causing VMs using auto-registration to ignore labels other than those defined in a `WorkloadGroup`.
  ([PR #44012](https://github.com/istio/istio/pull/44012))

- **Fixed** `istioctl experimental wait` has undecipherable message when `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING` is not enabled.
  ([Issue #42967](https://github.com/istio/istio/issues/42967))
