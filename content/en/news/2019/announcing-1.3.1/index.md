---
title: Announcing Istio 1.3.1
description: Istio 1.3.1 release announcement.
publishdate: 2019-10-27
attribution: The Istio Team
subtitle: Minor Update
release: 1.3.1
aliases:
    - /about/notes/1.3.1
    - /blog/2019/announcing-1.3.1
---

This release includes bug fixes to improve robustness. This release note describes what’s different between Istio 1.3.0 and Istio 1.3.1.

{{< relnote >}}

## Bug Fixes

- **Fixed** an issue which caused the secret cleanup job to erroneously run during upgrades ([Issue 16873](https://github.com/istio/istio/issues/16873)).
- **Fixed** an issue where the default configuration disabled Kubernetes Ingress support ([Issue 17148](https://github.com/istio/istio/issues/17148))
- **Fixed** an issue with handling invalid `UTF-8` characters in the Stackdriver logging adapter ([Issue 16966](https://github.com/istio/istio/issues/16966)).
- **Fixed** an issue which caused the `destination_service` label in HTTP metrics not to be set for `BlackHoleCluster` and `PassThroughCluster` ([Issue 16629](https://github.com/istio/istio/issues/16629)).
- **Fixed** an issue with the `destination_service` label in the `istio_tcp_connections_closed_total` and `istio_tcp_connections_opened_total` metrics which caused them to not be set correctly ([Issue 17234](https://github.com/istio/istio/issues/17234)).
- **Fixed** an Envoy crash introduced in Istio 1.2.4 ([Issue 16357](https://github.com/istio/istio/issues/16357)).
- **Fixed** Istio CNI sidecar initialization when IPv6 is disabled on the node ([Issue 15895](https://github.com/istio/istio/issues/15895)).
- **Fixed** a regression affecting support of RS384 and RS512 algorithms in JWTs ([Issue 15380](https://github.com/istio/istio/issues/15380)).

## Minor Enhancements

- **Added** support for `.Values.global.priorityClassName` to the telemetry deployment ([Issue 16204](https://github.com/istio/istio/pull/16204)).
- **Added** annotations for Datadog tracing that controls extra features in sidecars ([Issue 16594](https://github.com/istio/istio/pull/16594/files)).
- **Added** the `pilot_xds_push_time` metric to report Pilot xDS push time ([Issue 17011](https://github.com/istio/istio/pull/17011)).
- **Added** `istioctl experimental analyze` to support multi-resource analysis and validation ([Issue 17280](https://github.com/istio/istio/pull/17280)).
- **Removed** time diff info in the proxy-status command ([Issue 16477](https://github.com/istio/istio/pull/16920)).
