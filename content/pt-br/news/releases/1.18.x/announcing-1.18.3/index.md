---
title: Announcing Istio 1.18.3
linktitle: 1.18.3
subtitle: Patch Release
description: Istio 1.18.3 patch release.
publishdate: 2023-09-12
release: 1.18.3
---

This release contains bug fixes to improve robustness.

This release note describes what’s different between Istio 1.18.2 and 1.18.3.

{{< relnote >}}

## Changes

- **Added** ability to install gateway helm chart with a dual-stack service definition.

- **Fixed** an issue where HTTP probe’s `request.host` was not well propagated.
  ([Issue #46087](https://github.com/istio/istio/issues/46087))

- **Fixed** `health_checkers` EnvoyFilter extensions not being compiled into the proxy.
  ([Issue #46277](https://github.com/istio/istio/issues/46277))

- **Fixed** an issue that Istio should prefer `IMDSv2` on AWS.
  ([Issue #45825](https://github.com/istio/istio/issues/45825))

- **Fixed** an issue where the creation of a Telemetry object without any providers throws the IST0157 error.
  ([Issue #46510](https://github.com/istio/istio/issues/46510))

- **Fixed** `meshConfig.defaultConfig.sampling` is ignored when there are only default providers.  ([Issue #46653](https://github.com/istio/istio/issues/46653))

- **Fixed** an issue causing mesh configuration to not be properly synced, typically resulting in a misconfigured trust domain.
  ([Issue #45739](https://github.com/istio/istio/issues/45739))
