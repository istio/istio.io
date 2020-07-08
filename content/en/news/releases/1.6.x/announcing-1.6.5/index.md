---
title: Announcing Istio 1.6.5
linktitle: 1.6.5
subtitle: Patch Release
description: Istio 1.6.5 patch release.
publishdate: 2020-07-08
release: 1.6.5
aliases:
    - /news/announcing-1.6.5
---

This release contains bug fixes to improve robustness. This release note describes
what’s different between Istio 1.6.5 and Istio 1.6.4.

{{< relnote >}}

## Changes

- **Fixed** support to sort the pods by `creationTimestamp` during mixer lookup and return the latest pod.
- **Improved** Support to control sidecar injection based on revision at a per-pod level ([Issue 24801](https://github.com/istio/istio/issues/24801)
- **Improved** `istioctl validate` will disallow unknown field from spec ([Issue 24860](https://github.com/istio/istio/issues/24860))
- **Fixed** changed `stsPort` to `sts_port` in envoy bootstrap file. 
- **Fixed** keep existing wasm state schema since it can be referenced by state objects later.
- **Improved** added targetUri in stackdriver_grpc_service.
- **Improved** updated wasm state to log for Access Log Service.
- **Updated** Raised default protocol detection timeout from 100 Milliseconds to 5 seconds ([Issue 24379](https://github.com/istio/istio/issues/24379))
- **Updated** removed UDP port 53 from Istiod service.
- **Fixed** Allow setting status.sidecar.istio.io/port to zero ([Issue 24722](https://github.com/istio/istio/issues/24722))
- **Fixed**  support eds endpoint selection for subsets with no or empty label selector. ([Issue 24969](https://github.com/istio/istio/issues/24969))
- **Fixed** fix wrong error log in operator.
- **Fixed** allow k8s overlays on BaseComponentSpec. ([Issue 24476](https://github.com/istio/istio/issues/24476))
- **Fixed** support to use `ECC_SIGNATURE_ALGORITHM` for setting secret cache in pilot-agent.
- **Improved** map grpc status codes into http domain for metrics.
- **Fixed** fix HorizontalPodAutoscaler scaleTargetRef naming for istiod ([Issue 24809](https://github.com/istio/istio/issues/24809))
- **Improved** added a version label to pilot_xds to give more information on data plane versions.