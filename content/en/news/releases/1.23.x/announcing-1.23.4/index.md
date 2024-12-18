---
title: Announcing Istio 1.23.4
linktitle: 1.23.4
subtitle: Patch Release
description: Istio 1.23.4 patch release.
publishdate: 2024-12-18
release: 1.23.4
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.23.3 and Istio 1.23.4.

This release implements the security updates described in our 18th of December post, [`ISTIO-SECURITY-2024-007`](/news/security/istio-security-2024-007).

{{< relnote >}}

## Changes

- **Added** support for providing arbitrary environment variables to `istio-cni` chart.

- **Fixed** an issue where merging `Duration` with an `EnvoyFilter` could lead to all listener associated attributes unexpectedly being modified because all listeners shared the same pointer typed `listener_filters_timeout`.

- **Fixed** Helm rendering to properly apply annotations on Pilot's `ServiceAccount`.
  ([Issue #51289](https://github.com/istio/istio/issues/51289))

- **Fixed** an issue where injection config errors were being silenced (i.e. logged and not returned) when the sidecar injector was unable to process the sidecar config. This change will now propagate the error to the user instead of continuing to process a faulty config.  ([Issue #53357](https://github.com/istio/istio/issues/53357))
