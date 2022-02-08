---
title: Announcing Istio 1.13
linktitle: 1.13
subtitle: Major Update
description: Istio 1.13 release announcement.
publishdate: 2022-02-08
release: 1.13.0
skip_list: true
aliases:
    - /news/announcing-1.13
    - /news/announcing-1.13.0
---

We are pleased to announce the release of Istio 1.13!

{{< tip >}}
Istio 1.13.0 is officially supported on Kubernetes versions `1.20` to `1.23`.
{{< /tip >}}


Here are some of the highlights of the release:



- **Added** support for hostname-based multi-network gateways for east-west traffic. The hostname will be resolved in
the control plane and each of the IPs will be used as an endpoint. This behaviour can be disabled by setting
`RESOLVE_HOSTNAME_GATEWAYS=false` for istiod.  ([Issue #29359](https://github.com/istio/istio/issues/29359))
  - Context: This issue prevented most AWS/EKS users from setting up multi-network meshes.

