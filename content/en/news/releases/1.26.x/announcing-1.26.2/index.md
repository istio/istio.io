---
title: Announcing Istio 1.26.2
linktitle: 1.26.2
subtitle: Patch Release
description: Istio 1.26.2 patch release.
publishdate: 2025-06-20
release: 1.26.2
aliases:
    - /news/announcing-1.26.2
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.26.1 and 1.26.2.

{{< relnote >}}

## Changes

- **Fixed** incorrect UID and GID assignment for `istio-proxy` and `istio-validation` containers on OpenShift when TPROXY mode is enabled.

- **Fixed** an issue where changing a `HTTPRoute` object could cause `istiod` to crash.
  ([Issue #56456](https://github.com/istio/istio/issues/56456))

- **Fixed** a race condition where status updates for Kubernetes objects could be missed by `istiod`.
  ([Issue #56401](https://github.com/istio/istio/issues/56401))
