---
title: Announcing Istio 1.19.5
linktitle: 1.19.5
subtitle: Patch Release
description: Istio 1.19.5 patch release.
publishdate: 2023-12-12
release: 1.19.5
---

This release implements the security updates described in our Dec 12th post, [`ISTIO-SECURITY-2023-005`](/news/security/istio-security-2023-005) along with bug fixes to improve robustness.

This release note describes what’s different between Istio 1.19.4 and 1.19.5.

{{< relnote >}}

## Changes

- **Fixed** an issue where the webhook generated with `istioctl tag set` is unexpectedly being removed by the installer.
  ([Issue #47423](https://github.com/istio/istio/issues/47423))

- **Fixed** an issue where multi-cluster leader election cannot prioritize local over remote leaders.
  ([Issue #47901](https://github.com/istio/istio/issues/47901))

- **Fixed** a memory leak when `hostNetwork` pods scale up and down.
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **Fixed** a memory leak when `WorkloadEntries` change their IP address.
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **Fixed** a memory leak when a `ServiceEntry` is removed.
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

## Security update

- Changes to Istio CNI Permissions as described in [`ISTIO-SECURITY-2023-005`](/news/security/istio-security-2023-005).
