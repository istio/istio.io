---
title: Announcing Istio 1.19.4
linktitle: 1.19.4
subtitle: Patch Release
description: Istio 1.19.4 patch release.
publishdate: 2023-11-13
release: 1.19.4
---

This release note describes what’s different between Istio 1.19.3 and 1.19.4.

{{< relnote >}}

## Changes

- **Improved** `iptables` locking. The new implementation uses `iptables` builtin lock waiting when needed, and disables locking entirely when not needed.

- **Added** gated flag `ISTIO_ENABLE_IPV4_OUTBOUND_LISTENER_FOR_IPV6_CLUSTERS` to manage an additional outbound listener for IPv6-only clusters to deal with IPv4 NAT outbound traffic.
This is useful for IPv6-only cluster environments such as EKS which manages both egress-only IPv4 as well as IPv6 IPs.
  ([Issue #46719](https://github.com/istio/istio/issues/46719))

- **Fixed** an issue where multiple header matches in root virtual service generate incorrect routes.  ([Issue #47148](https://github.com/istio/istio/issues/47148))

- **Fixed** DNS Proxy resolution for wildcard `ServiceEntry` with the search domain suffix for `glibc` based containers.
  ([Issue #47264](https://github.com/istio/istio/issues/47264)),([Issue #31250](https://github.com/istio/istio/issues/31250)),([Issue #33360](https://github.com/istio/istio/issues/33360)),([Issue #30531](https://github.com/istio/istio/issues/30531)),([Issue #38484](https://github.com/istio/istio/issues/38484))

- **Fixed** an issue where using a Sidecar resource using `IstioIngressListener.defaultEndpoint` cannot use [::1]:PORT if the default IP addressing is not IPv6.
  ([Issue #47412](https://github.com/istio/istio/issues/47412))

- **Fixed** an issue where `istioctl proxy-config` fails to process a config dump from file if EDS endpoints were not provided.
  ([Issue #47505](https://github.com/istio/istio/issues/47505))

- **Fixed** an issue where `istioctl tag list` command didn't accept the `--output` flag.
  ([Issue #47696](https://github.com/istio/istio/issues/47696))

- **Fixed** multicluster secret filtering causing Istio to pick up secrets from every namespace.
  ([Issue #47433](https://github.com/istio/istio/issues/47433))

- **Fixed** `VirtualService` HTTP header match not working when `header-name` is set to `{}`.
  ([Issue #47341](https://github.com/istio/istio/issues/47341))

- **Fixed** an issue causing traffic to terminating headless service instances to not function correctly.
  ([Issue #47348](https://github.com/istio/istio/issues/47348))

## Security update

There are no security updates for this release.
