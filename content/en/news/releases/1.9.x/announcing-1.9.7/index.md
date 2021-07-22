---
title: Announcing Istio 1.9.7
linktitle: 1.9.7
subtitle: Patch Release
description: Istio 1.9.7 patch release.
publishdate: 2021-07-22
release: 1.9.7
aliases:
    - /news/announcing-1.9.7
---

This release note describes what’s different between Istio 1.9.6 and Istio 1.9.7.

{{< relnote >}}

## Changes

- **Added** validator for empty regex match. ([Issue 34065](https://github.com/istio/istio/issues/34065))

- **Fixed** `EndpointSlice` races leading to error state. ([Issue 33672](https://github.com/istio/istio/issues/33672))

- **Fixed** `EndpointSlice` creating duplicate IPs on service update.
