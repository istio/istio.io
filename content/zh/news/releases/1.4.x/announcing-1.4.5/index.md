---
title: Announcing Istio 1.4.5
linktitle: 1.4.5
subtitle: Patch Release
description: Istio 1.4.5 patch release.
publishdate: 2020-02-18
release: 1.4.5
aliases:
    - /zh/news/announcing-1.4.5
---

This release includes bug fixes to improve robustness. This release note describes what’s different between Istio 1.4.4 and Istio 1.4.5.

The fixes below focus on various bugs occurring during node restarts. If you use Istio CNI, or have nodes that restart, you are highly encouraged to upgrade.

{{< relnote >}}

## Improvements

- **Fixed** a bug triggered by node restart causing Pods to receive incorrect configuration ([Issue 20676](https://github.com/istio/istio/issues/20676)).
- **Improved** [Istio CNI](/zh/docs/setup/additional-setup/cni/) robustness. Previously, when a node restarted, new pods may be created before the CNI was setup, causing pods to be created without `iptables` rules configured ([Issue 14327](https://github.com/istio/istio/issues/14327)).
- **Fixed** MCP metrics to include the size of the MCP responses, rather than just requests ([Issue 21049](https://github.com/istio/istio/issues/21049)).
