---
title: Announcing Istio 1.26.7
linktitle: 1.26.7
subtitle: Patch Release
description: Istio 1.26.7 patch release.
publishdate: 2025-12-03
release: 1.26.7
aliases:
    - /news/announcing-1.26.7
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.26.6 and 1.26.7.

This release implements the security updates described in our 3rd of December post, [`ISTIO-SECURITY-2025-001`](/news/security/istio-security-2025-003).

{{< relnote >}}

## Changes

- **Fixed** a goroutine leak in multicluster where krt collections with data from remote clusters would stay in memory even after that cluster was removed.
  ([Issue #57269](https://github.com/istio/istio/issues/57269))

- **Fixed** an issue where Envoy Secret resources could get stuck in `WARMING` state when the same Kubernetes Secret is referenced from Istio Gateway objects using both `secret-name` and `namespace/secret-name` formats.
  ([Issue #58146](https://github.com/istio/istio/issues/58146))
