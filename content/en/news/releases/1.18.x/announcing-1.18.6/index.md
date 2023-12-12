---
title: Announcing Istio 1.18.6
linktitle: 1.18.6
subtitle: Patch Release
description: Istio 1.18.6 patch release.
publishdate: 2023-12-12
release: 1.18.6
---

This release implements the security updates described in our Dec 12th post, [`ISTIO-SECURITY-2023-005`](/news/security/istio-security-2023-005) along with bug fixes to improve robustness.

This release note describes what’s different between Istio 1.18.5 and 1.18.6. This is the last planned release for Istio 1.18, for more details see our Nov 29th [end of support announcement](/news/support/announcing-1.18-eol/).

{{< relnote >}}

## Changes

- **Improved** `iptables` locking. The new implementation uses `iptables` builtin lock waiting when needed, and disables locking entirely when not needed.

- **Fixed** DNS Proxy resolution for wildcard `ServiceEntry` with the search domain suffix for glibc-based containers.
  ([Issue #47264](https://github.com/istio/istio/issues/47264)),([Issue #31250](https://github.com/istio/istio/issues/31250)),([Issue #33360](https://github.com/istio/istio/issues/33360)),([Issue #30531](https://github.com/istio/istio/issues/30531)),([Issue #38484](https://github.com/istio/istio/issues/38484))

- **Fixed** an issue where using a sidecar resource using `IstioIngressListener.defaultEndpoint` cannot use [::1]:PORT if the default IP addressing is not IPv6.
  ([Issue #47412](https://github.com/istio/istio/issues/47412))

- **Fixed** an issue where `istioctl proxy-config` fails to process a config dump from a file if EDS endpoints were not provided.
  ([Issue #47505](https://github.com/istio/istio/issues/47505))

- **Fixed** an issue where `VirtualService` HTTP header present match was not working when `header-name: {}` was set.
  ([Issue #47341](https://github.com/istio/istio/issues/47341))

- **Fixed** a null traversal issue when using `datadog` or `stackdriver` with no tracing options.
  ([Issue #45855](https://github.com/istio/istio/issues/45855))

- **Fixed** multi-cluster leader election not being able to prioritize local over remote leaders.
  ([Issue #47901](https://github.com/istio/istio/issues/47901))

- **Fixed** clients being able to communicate with hosts defined in ServiceEntries over IPv6 when installed in dual-stack mode.
  ([Issue #46743](https://github.com/istio/istio/issues/46743)),([Issue #47406](https://github.com/istio/istio/issues/47406))

- **Fixed** an issue causing traffic to terminating headless service instances to not function correctly.
  ([Issue #47348](https://github.com/istio/istio/issues/47348))

- **Fixed** a memory leak when `hostNetwork` pods scale up and down.
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **Fixed** a memory leak when `WorkloadEntries` change their IP address.
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **Fixed** a memory leak when a `ServiceEntry` is removed.
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

## Security update

- Changes to Istio CNI Permissions as described in [`ISTIO-SECURITY-2023-005`](/news/security/istio-security-2023-005).
