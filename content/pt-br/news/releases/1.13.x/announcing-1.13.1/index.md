---
title: Announcing Istio 1.13.1
linktitle: 1.13.1
subtitle: Patch Release
description: Istio 1.13.1 patch release.
publishdate: 2022-02-22
release: 1.13.1
aliases:
    - /news/announcing-1.13.1
---

This release fixes the security vulnerabilities described in our February 22nd post, [ISTIO-SECURITY-2022-003](/news/security/istio-security-2022-003). This release note describes what’s different between Istio 1.13.0 and 1.13.1.

{{< relnote >}}

## Security update

- __[CVE-2022-23635](https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=CVE-2022-23635)__:
  CVE-2022-23635 (CVSS Score 7.5, High):  Unauthenticated control plane denial of service attack.

### Envoy CVEs

At this time it is not believed that Istio is vulnerable to these CVEs in Envoy. They are listed, however,
to be transparent.

- __[CVE-2021-43824](https://github.com/envoyproxy/envoy/security/advisories/GHSA-vj5m-rch8-5r2p)__:
  (CVSS Score 6.5, Medium): Potential null pointer dereference when using JWT filter `safe_regex` match.

- __[CVE-2021-43825](https://github.com/envoyproxy/envoy/security/advisories/GHSA-h69p-g6xg-mhhh)__:
  (CVSS Score 6.1, Medium):  Use-after-free when response filters increase response data, and increased data exceeds downstream buffer limits.

- __[CVE-2021-43826](https://github.com/envoyproxy/envoy/security/advisories/GHSA-cmx3-fvgf-83mf)__:
  (CVSS Score 6.1, Medium): Use-after-free when tunneling TCP over HTTP, if downstream disconnects during upstream connection establishment.

- __[CVE-2022-21654](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5j4x-g36v-m283)__:
  (CVSS Score 7.3, High): Incorrect configuration handling allows mTLS session re-use without re-validation after validation settings have changed.

- __[CVE-2022-21655](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7r5p-7fmh-jxpg)__:
  (CVSS Score 7.5, High): Incorrect handling of internal redirects to routes with a direct response entry.

- __[CVE-2022-23606](https://github.com/envoyproxy/envoy/security/advisories/GHSA-9vp2-4cp7-vvxf)__:
  (CVSS Score 4.4, Moderate): Stack exhaustion when a cluster is deleted via Cluster Discovery Service.

# Changes

- **Fixed** `istioctl x describe svc` not evaluating port `appProtocol` properly.
  ([Issue #37159](https://github.com/istio/istio/issues/37159))

- **Fixed** an issue where service update does not trigger route update.
  ([Issue #37356](https://github.com/istio/istio/pull/37356))
