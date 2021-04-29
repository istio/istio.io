---
title: Announcing Istio 1.5.3
linktitle: 1.5.3
subtitle: Patch Release
description: Istio 1.5.3 security release.
publishdate: 2020-05-12
release: 1.5.3
aliases:
    - /news/announcing-1.5.3
---

{{< warning >}}
DO NOT USE this release. USE release 1.5.4 instead.
{{< /warning >}}

Due to a publishing error, the 1.5.3 images do not contain the fix for CVE-2020-10739 as claimed in the original announcement.

This release contains bug fixes to improve robustness.
This release note describes what's different between Istio 1.5.3 and Istio 1.5.2.

{{< relnote >}}

## Changes

- **Fixed** the Helm installer to install Kiali using a dynamically generated signing key.
- **Fixed** overlaying the generated Kubernetes resources for addon components with user-defined overlays
 [(Issue 23048)](https://github.com/istio/istio/issues/23048)
- **Fixed** `istio-sidecar.deb` failing to start on Debian buster with `iptables` default `nftables` setting  [(Issue 23279)](https://github.com/istio/istio/issues/23279)
- **Fixed** the corresponding hash policy not being updated after the header name specified in `DestinationRule.trafficPolicy.loadBalancer.consistentHash.httpHeaderName` is changed  [(Issue 23434)](https://github.com/istio/istio/issues/23434)
- **Fixed** traffic routing when deployed in a namespace other than istio-system  [(Issue 23401)](https://github.com/istio/istio/issues/23401)
