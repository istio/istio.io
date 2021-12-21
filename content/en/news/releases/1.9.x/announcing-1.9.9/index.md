---
title: Announcing Istio 1.9.9
linktitle: 1.9.9
subtitle: Patch Release
description: Istio 1.9.9 patch release.
publishdate: 2021-10-08
release: 1.9.9
aliases:
    - /news/announcing-1.9.9
---

This is the final release of Istio 1.9. We urge you to upgrade to the latest Istio supported version, Istio ({{<istio_release_name>}}).

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.9.8 and Istio 1.9.9.

{{< relnote >}}

## Changes

- **Fixed** JWT unauthorized responses to now include a `www-authenticate` header, according to the [RFC 6750](https://datatracker.ietf.org/doc/html/rfc6750#section-3) specification.
- **Fixed** Istiod memory leak after proxies have disconnected.
- **Fixed** `DestinationRule` updates not triggering an update for `AUTO_PASSTHROUGH` listeners on gateways.
