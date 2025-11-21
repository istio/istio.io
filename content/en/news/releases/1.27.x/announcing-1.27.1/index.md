---
title: Announcing Istio 1.27.1
linktitle: 1.27.1
subtitle: Patch Release
description: Istio 1.27.1 patch release.
publishdate: 2025-09-03
release: 1.27.1
aliases:
    - /news/announcing-1.27.1
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.27.0 and 1.27.1.

This release implements the security updates described in our 3rd of September post, [`ISTIO-SECURITY-2025-001`](/news/security/istio-security-2025-001).

{{< relnote >}}

## Changes

- **Fixed** an issue where `istio-iptables` would sometimes ignore the IPv4 state in favor of the IPv6 state when deciding whether new iptables rules needed to be applied.
  ([Issue #56587](https://github.com/istio/istio/issues/56587))

- **Fixed** a bug where our tag watcher code didn't consider the default revision to be the same as the default tag. This would cause issues where Kubernetes gateways wouldn't be programmed.
  ([Issue #56767](https://github.com/istio/istio/issues/56767))

- **Fixed** an issue causing Gateway chart installation failures with Helm v3.18.5 due to a stricter JSON schema validator. The chart's schema has been updated to be compatible.
  ([Issue #57354](https://github.com/istio/istio/issues/57354))

- **Fixed** an issue where the `PreserveHeaderCase` option was overriding other HTTP/1.x protocol options, such as HTTP/1.0.
  ([Issue #57528](https://github.com/istio/istio/issues/57528))

- **Fixed** a change in output of `istioctl proxy-status` to be more consistent with previous versions.
  ([Issue #57339](https://github.com/istio/istio/issues/57339))

- **Fixed** iptables detection logic to fall back to `iptables-nft` when the `iptable_nat` module is missing.
  ([Issue #57380](https://github.com/istio/istio/issues/57380))

- **Fixed** a bug that incorrectly rejected traffic policies when only `retry_budget` was set.
