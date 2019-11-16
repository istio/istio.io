---
title: Announcing Istio 1.0.2
description: Istio 1.0.2 patch release.
publishdate: 2018-09-06
attribution: The Istio Team
release: 1.0.2
aliases:
    - /zh/about/notes/1.0.1
    - /zh/blog/2018/announcing-1.0.2
    - /zh/news/announcing-1.0.2
---

We're pleased to announce the availability of Istio 1.0.2. Please see below for what's changed.

{{< relnote >}}

## General

- Fixed bug in Envoy where the sidecar would crash if receiving normal traffic on the mutual TLS port.

- Fixed bug with Pilot propagating incomplete updates to Envoy in a multicluster environment.

- Added a few more Helm options for Grafana.

- Improved Kubernetes service registry queue performance.

- Fixed bug where `istioctl proxy-status` was not showing the patch version.

- Add validation of virtual service SNI hosts.
