---
title: Announcing Istio 1.27.9
linktitle: 1.27.9
subtitle: Patch Release
description: Istio 1.27.9 patch release.
publishdate: 2026-04-07
release: 1.27.9
aliases:
    - /news/announcing-1.27.9
---

This release contains bug fixes to improve robustness. This release note describes what's different between Istio 1.27.8 and 1.27.9.

{{< relnote >}}

## Changes

- **Fixed** istiod errors on startup when a CRD version greater than the maximum supported version is installed on a cluster. TLS route versions v1.4 and below are supported; v1.5 and above will be ignored.
  ([Issue #59443](https://github.com/istio/istio/issues/59443))

- **Fixed** `serviceAccount` matcher regex in `AuthorizationPolicy` to properly quote the service account name, allowing for correct matching of service accounts with special characters in their names.
  ([Issue #59700](https://github.com/istio/istio/issues/59700))

- **Fixed** an issue where all Gateways were restarted after istiod was restarted.
  ([Issue #59709](https://github.com/istio/istio/issues/59709))

- **Fixed** `TLSRoute` hostnames not being constrained to the intersection with the `Gateway` listener hostname.
  Previously, a `TLSRoute` with a broad hostname (e.g. `*.com`) attached to a listener with a narrower hostname
  (e.g. `*.example.com`) would incorrectly match the full route hostname instead of only the intersection
  (`*.example.com`), as required by the Gateway API spec.
  ([Issue #59229](https://github.com/istio/istio/issues/59229))

- **Fixed** a race condition that caused intermittent `proxy::h2 ping error: broken pipe` error logs.
  ([Issue #59192](https://github.com/istio/istio/issues/59192)),([Issue #1346](https://github.com/istio/ztunnel/issues/1346))
