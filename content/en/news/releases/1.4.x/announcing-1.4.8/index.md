---
title: Announcing Istio 1.4.8
linktitle: 1.4.8
subtitle: Patch Release
description: Istio 1.4.8 patch release.
publishdate: 2020-04-23
release: 1.4.8
aliases:
    - /news/announcing-1.4.8
---

This release includes bug fixes to improve robustness. This release note describes what’s different
between Istio 1.4.7 and Istio 1.4.8.

The fixes below focus on various issues related to installing Istio on OpenShift with CNI. Instructions
for installing Istio on OpenShift with CNI can be found [here](/docs/setup/additional-setup/cni/#instructions-for-istio-1-4-x-and-openshift).

{{< relnote >}}

## Bug fixes

- **Fixed** Fixed CNI installation on OpenShift ([Issue 21421](https://github.com/istio/istio/pull/21421)) ([Issue 22449](https://github.com/istio/istio/issues/22449)).
- **Fixed** Not all inbound ports are redirected when CNI is enabled ([Issue 22448](https://github.com/istio/istio/issues/22498)).
- **Fixed** Syntax errors in gateway templates with Go 1.14 ([Issue 22366](https://github.com/istio/istio/issues/22366)).
- **Fixed** Remove namespace from `clusterrole` and `clusterrolebinding` ([PR 297](https://github.com/istio/cni/pull/297)).
