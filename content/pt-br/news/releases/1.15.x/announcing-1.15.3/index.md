---
title: Announcing Istio 1.15.3
linktitle: 1.15.3
subtitle: Patch Release
description: Istio 1.15.3 patch release.
publishdate: 2022-10-27
release: 1.15.3
---

This release contains bug fixes to improve robustness. This release note describes what’s different between Istio 1.15.2 and Istio 1.15.3.

{{< relnote >}}

## Changes

- **Updated** the default value for `TRUSTED_GATEWAY_CIDR`. Previously this was empty, which caused the XFCC authenticator to reject non-loopback requests.

- **Added** validation warnings when a `DestinationRule` specifies failover policies but does not provide an outlier detection policy. Previously, istiod was silently ignoring the failover settings.

- **Fixed** an issue causing `kube-inject` to crash when the pod annotation `proxy.istio.io/config` is set.

- **Fixed** an issue with a missing `service_name` in the Telemetry API when configuring a Datadog tracing provider. ([Issue #38573](https://github.com/istio/istio/issues/38573))

- **Fixed** an issue where an incorrect schema configuration caused the Istio Operator to go into an error loop. ([Issue #40876](https://github.com/istio/istio/issues/40876))

- **Fixed** network port forward issue to support IPv4 and IPv6. ([Issue #40605](https://github.com/istio/istio/issues/40605))
