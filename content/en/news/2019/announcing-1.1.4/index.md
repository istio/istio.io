---
title: Announcing Istio 1.1.4
subtitle: Patch Release
description: Istio 1.1.4 patch release.
publishdate: 2019-04-24
release: 1.1.4
aliases:
    - /about/notes/1.1.4
    - /blog/2019/announcing-1.1.4
    - /news/announcing-1.1.4
---

We're pleased to announce the availability of Istio 1.1.4. Please see below for what's changed.

{{< relnote >}}

## Behavior change

- Changed the default behavior for Pilot to allow traffic to outside the mesh, even if it is on the same port as an internal service.
This behavior can be controlled by the `PILOT_ENABLE_FALLTHROUGH_ROUTE` environment variable.

## Bug fixes

- Fixed egress route generation for services of type `ExternalName`.

- Added support for configuring Envoy's idle connection timeout, which prevents running out of
memory or IP ports over time ([Issue 13355](https://github.com/istio/istio/issues/13355)).

- Fixed a crashing bug in Pilot in failover handling of locality-based load balancing.

- Fixed a crashing bug in Pilot when it was given custom certificate paths.

- Fixed a bug in Pilot where it was ignoring short names used as service entry hosts ([Issue 13436](https://github.com/istio/istio/issues/13436)).

- Added missing `https_protocol_options` to the envoy-metrics-service cluster configuration.

- Fixed a bug in Pilot where it didn't handle https traffic correctly in the fall through route case ([Issue 13386](https://github.com/istio/istio/issues/13386)).

- Fixed a bug where Pilot didn't remove endpoints from Envoy after they were removed from Kubernetes ([Issue 13402](https://github.com/istio/istio/issues/13402)).

- Fixed a crashing bug in the node agent ([Issue 13325](https://github.com/istio/istio/issues/13325)).

- Added missing validation to prevent gateway names from containing dots ([Issue 13211](https://github.com/istio/istio/issues/13211)).

- Fixed bug where [`ConsistentHashLB.minimumRingSize`](/docs/reference/config/networking/destination-rule#LoadBalancerSettings-ConsistentHashLB)
was defaulting to 0 instead of the documented 1024 ([Issue 13261](https://github.com/istio/istio/issues/13261)).

## Small enhancements

- Updated to the latest version of the [Kiali](https://www.kiali.io) add-on.

- Updated to the latest version of [Grafana](https://grafana.com).

- Added validation to ensure Citadel is only deployed with a single replica ([Issue 13383](https://github.com/istio/istio/issues/13383)).

- Added support to configure the logging level of the proxy and Istio control plane (([Issue 11847](https://github.com/istio/istio/issues/11847)).

- Allow sidecars to bind to any loopback address and not just 127.0.0.1 ([Issue 13201](https://github.com/istio/istio/issues/13201)).
