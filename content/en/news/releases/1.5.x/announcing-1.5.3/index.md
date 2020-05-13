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

DO NOT USE this release. USE release 1.5.4 instead.

Due to a publishing error, the 1.5.3 images do not contain the fix for the CVE.


This release contains bug fixes to improve robustness and fixes for the security vulnerabilities described in [our May 12th, 2020 news post](/news/security/istio-security-2020-005). This release note describes what's different between Istio 1.5.3 and Istio 1.5.2.

{{< relnote >}}

## Security update

- **ISTIO-SECURITY-2020-005** Denial of Service with Telemetry V2 enabled.

__[CVE-2020-10739](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-10739)__: By sending a specially crafted packet, an attacker could trigger a Null Pointer Exception resulting in a Denial of Service. This could be sent to the ingress gateway or a sidecar.

## Changes

- **Fixed** the Helm installer to install Kiali using a dynamically generated signing key.
- **Fixed** overlaying the generated Kubernetes resources for addon components with user-defined overlays
 [(Issue 23048)](https://github.com/istio/istio/issues/23048)
- **Fixed** `istio-sidecar.deb` failing to start on Debian buster with `iptables` default `nftables` setting  [(Issue 23279)](https://github.com/istio/istio/issues/23279)
- **Fixed** the corresponding hash policy not being updated after the header name specified in `DestinationRule.trafficPolicy.loadBalancer.consistentHash.httpHeaderName` is changed  [(Issue 23434)](https://github.com/istio/istio/issues/23434)
- **Fixed** traffic routing when deployed in a namespace other than istio-system  [(Issue 23401)](https://github.com/istio/istio/issues/23401)
