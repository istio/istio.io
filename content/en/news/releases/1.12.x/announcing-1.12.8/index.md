---
title: Announcing Istio 1.12.8
linktitle: 1.12.8
subtitle: Patch Release
description: Istio 1.12.8 patch release.
publishdate: 2022-06-09
release: 1.12.8
aliases:
    - /news/announcing-1.12.8
---

This release fixes the security vulnerabilities described in our June 9th post, [ISTIO-SECURITY-2022-005](/news/security/istio-security-2022-005). This release note describes what’s different between Istio 1.12.7 and 1.12.8.

{{< relnote >}}

## Changes

- **Fixed** an issue where setting `PILOT_ENABLE_METADATA_EXCHANGE` to `false` does not remove the TCP MX filter.
  ([Issue #38520](https://github.com/istio/istio/issues/38520))

- **Fixed** an issue where cluster VIPs are not correct and a stale IP address exists after a multi-cluster service is deleted in one cluster. This would cause the DNS Proxy to return a stale IP for service resolution and thus cause a traffic outage.
  ([Issue #39039](https://github.com/istio/istio/issues/39039))

- **Fixed** an issue where `WorkloadEntry.Annotations` being `nil` would lead to an abnormal exit of istiod.
  ([Issue #39201](https://github.com/istio/istio/issues/39201))
