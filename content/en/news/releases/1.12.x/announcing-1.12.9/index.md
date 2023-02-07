---
title: Announcing Istio 1.12.9
linktitle: 1.12.9
subtitle: Patch Release
description: Istio 1.12.9 patch release.
publishdate: 2022-07-12
release: 1.12.9
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.12.8 and Istio 1.12.9.

{{< relnote >}}

## Changes

- **Fixed** building routes order where a catch-all route no longer short circuits other routes declared after it.  ([Issue #39188](https://github.com/istio/istio/issues/39188))

- **Fixed** a bug where the previous cluster was not stopping when updating a multicluster secret. The previous cluster did not stop even when the secret was deleted.  ([Issue #39366](https://github.com/istio/istio/issues/39366))
