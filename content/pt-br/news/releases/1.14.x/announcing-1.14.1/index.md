---
title: Announcing Istio 1.14.1
linktitle: 1.14.1
subtitle: Patch Release
description: Istio 1.14.1 patch release.
publishdate: 2022-06-09
release: 1.14.1
aliases:
    - /news/announcing-1.14.1
---

This release fixes the security vulnerabilities described in our June 9th post, [ISTIO-SECURITY-2022-005](/news/security/istio-security-2022-005). This release note describes what’s different between Istio 1.14.0 and 1.14.1.

{{< relnote >}}

## Changes

- **Fixed** improper filtering of endpoints from East-West Gateway caused by `DestinationRule` TLS settings.
  ([Issue #38704](https://github.com/istio/istio/issues/38704))

- **Fixed**  that running `istioctl verify-install` would fail with the `demo` profile.

- **Fixed** an issue where cluster VIPs are not correct and a stale IP address exists after a multi-cluster service is deleted in one cluster. This would cause the DNS Proxy to return a stale IP for service resolution and thus cause a traffic outage.
  ([Issue #39039](https://github.com/istio/istio/issues/39039))

- **Fixed** an issue where `WorkloadEntry.Annotations` being `nil` would lead to an abnormal exit of istiod.
  ([Issue #39201](https://github.com/istio/istio/issues/39201))
