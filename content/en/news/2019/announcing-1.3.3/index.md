---
title: Announcing Istio 1.3.3
description: Istio 1.3.3 release announcement.
publishdate: 2019-10-14
attribution: The Istio Team
subtitle: Minor Update
release: 1.3.3
---

This release includes bug fixes to improve robustness. This release note describes what's different between Istio 1.3.2 and Istio 1.3.3.

{{< relnote >}}

## Bug fixes

- **Fixed** an issue which caused Prometheus to install improperly when using `istioctl x manifest apply`. ([Issue 16970](https://github.com/istio/istio/issues/16970))
- **Fixed** a bug where locality load balancing can not read locality information from the node. ([Issue 17337](https://github.com/istio/istio/issues/17337))
- **Fixed** a bug where long-lived connections were getting dropped by the Envoy proxy as the listeners were getting reconfigured without any user configuration changes. This was due to an underlying issue related to unstable configuration serialization between Envoy and Pilot. ([Issue 17383](https://github.com/istio/istio/issues/17383), [Issue 17139](https://github.com/istio/istio/issues/17139))
- **Fixed** a crash in the experimental `analyze` command. ([Issue 17449](https://github.com/istio/istio/issues/17449))
- **Fixed** `istioctl x manifest diff` to diff text blocks in ConfigMaps. ([Issue 16828](https://github.com/istio/istio/issues/16828))

## Minor enhancements

- **Added** a daily performance benchmark
