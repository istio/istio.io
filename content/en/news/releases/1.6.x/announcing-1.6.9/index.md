---
title: Announcing Istio 1.6.9
linktitle: 1.6.89
subtitle: Patch Release
description: Istio 1.6.9 patch release.
publishdate: 2020-09-00
release: 1.6.9
aliases:
    - /news/announcing-1.6.9
---

This release contains bug fixes to improve robustness. This release note describes
what’s different between Istio 1.6.8 and Istio 1.6.9.

{{< relnote >}}

## Changes
- **Added** istioctl analyzer to detect when Destination Rules do not specify `caCertificates` ([Istio 25652](https://github.com/istio/istio/issues/25652))
- **Fixed** `istioctl remove-from-mesh` not removing init containers on CNI installations.
- **Updated** default protocol sniffing timeout to 5s to help explain telemetry involving passthrough and unknown ([Istio 24379](https://github.com/istio/istio/issues/24379))
- **Fixed** gateway listeners created with traffic direction outbound to be drained properly on exit
- **Fixed** regression in gateway name resoltion ([Istio 26264](https://github.com/istio/istio/issues/26264))
- **Fixed** inaccurate `endpointsPendingPodUpdate` metric
- **Fixed** HTTP match request without headers conflict
- **Updated** `app_containers` to use comma separated values for container specification
- **Fixed** Istio operator to watch muliple namespaces ([Istio 26317](https://github.com/istio/istio/issues/26317))
- **Fixed** ingress SDS from not getting secret update ([Istio 18912](https://github.com/istio/istio/issues/18912))
- **Added** missing `telemetry.loadshedding.*` options to mixer container arguments
- **Fixed** egress gateway ports binding to 80/443 due to user permissions
- **Updated** SDS timeout to fetch workload certs to 0s as timeouts are not needed for workload certs.
- **Fixed** headless services not updating listeners ([Istio 26617](https://github.com/istio/istio/issues/26617))
- **Fixed** `istioctl` `add-to-mesh` and `remove-from-mesh` commands from affecting `OwnerReferences` ([Istio 26720](https://github.com/istio/istio/issues/26720))
- **Improved** specifying network for a cluster without `meshNetworks` also being configured
- **Improved** the cache readiness state with TTL ([Istio 26418](https://github.com/istio/istio/issues/26418))
- **Fixed** trust domain validation in transport socket level ([Istio 26435](https://github.com/istio/istio/issues/26435))
- **Fixed** rotated certificates not being stored to `/etc/istio-certs` `VolumeMount` ([Istio 26821](https://github.com/istio/istio/issues/26821))
- **Fixed** ledger capacity size
- **Fixed** cleaning up of service information when the cluster secret is deleted
- **Fixed** `EDS` cache when an endpoint appears after its service resource ([Istio 26983](https://github.com/istio/istio/issues/26983))
- **Fixed** operator to update service monitor due to invalid permissions ([Istio 26961](https://github.com/istio/istio/issues/26961)) 


