---
title: Announcing Istio 1.7.6
linktitle: 1.7.6
subtitle: Patch Release
description: Istio 1.7.6 patch release.
publishdate: 2020-12-10
release: 1.7.6
aliases:
- /news/announcing-1.7.6
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.7.5 and Istio 1.7.6

{{< relnote >}}

## Changes

- **Fixed** an issue causing telemetry HPA settings to be overridden by the inline replicas. ([Issue #28916](https://github.com/istio/istio/issues/28916))

- **Fixed** an issue where a delegate `VirtualService` change would not trigger an xDS push. ([Issue #29123](https://github.com/istio/istio/issues/29123))

- **Fixed** an issue that caused a very high memory usage with a large number of `ServiceEntry`s. ([Issue #25531](https://github.com/istio/istio/issues/25531))
