---
title: Announcing Istio 1.25.0
linktitle: 1.25.0
subtitle: Major Release
description: Istio 1.25 Release Announcement.
publishdate: 2025-03-03
release: 1.25.0
aliases:
- /news/announcing-1.25
- /news/announcing-1.25.0
---

We are pleased to announce the release of Istio 1.25. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.25.0 release published!
We would like to thank the Release Managers for this release, **Mike Morris** from Microsoft, **Faseela K** from Ericsson Software Technology, and **Daniel Hawton** from Solo.io.

{{< relnote >}}

{{< tip >}}
Istio 1.25.0 is officially supported on Kubernetes versions `1.29` to `1.32`.
{{< /tip >}}

## What’s new?

### DNS proxying on by default for ambient mode

Istio will generally route traffic based on HTTP headers. In ambient mode, the ztunnel only sees traffic at Layer 4, and does not have access to HTTP headers. Therefore, DNS proxying is required to enable resolution of `ServiceEntry` addresses, especially in the case of [sending egress traffic to waypoints](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient#scenario-ztunnel-is-not-sending-egress-traffic-to-waypoints).

To make this easier in the default case, DNS proxying is enabled by default in ambient mode installations of Istio 1.25.  An annotation has been added to allow workloads to opt out of DNS proxying. Check the [upgrade notes](upgrade-notes/#ambient-mode-dns-capture-on-by-default) for more information.

### Default deny policy available for waypoints

In sidecar mode, authorization policy is attached to workloads via a selector. In ambient mode, policy targeted by selector is enforced by ztunnel only. Waypoint proxies use Gateway API-style binding using the `targetRef` field. This led to a potential configuration where a workload was default-denied the ability to talk to an endpoint, but could bypass that configuration by connecting to a waypoint that _was_ allowed to talk to that endpoint, and thus reach it anyway.

In this release, we have added the ability to target policy to a named `GatewayClass`, as well as a named `Gateway`. This allows you to set policy on the `istio-waypoint` class, which apply to all instances of a waypoint.

### Zonal routing enhancements

Whether for reliability, performance, or cost reasons, controlling cross-zone and cross-region traffic is often an important "day 2" operation for users. With Istio 1.25, this just got even easier!

[Kubernetes's traffic distribution](https://kubernetes.io/docs/concepts/services-networking/service/#traffic-distribution) feature is now fully supported, offering a simplified interface to keep traffic local. The existing Istio [locality load balancing](/docs/tasks/traffic-management/locality-load-balancing/) settings remain available for more complex use cases.

In ambient mode, ztunnel will now report the additional `source_zone`, `source_region`, `destination_zone`, and `destination_region` labels to all metrics, giving a clear view of cross-zonal traffic.

### Other new features

- We have added the ability to provide a list of virtual interfaces whose inbound traffic will be unconditionally treated as outbound. This allows workloads using virtual networking (KubeVirt, VMs, docker-in-docker, etc) to function correctly with both sidecar and ambient mode traffic capture.
- The `istio-cni` DaemonSet can now be safely upgraded in-place in an active cluster, without requiring a node cordon to prevent pods spawned during the upgrade process from escaping ambient traffic capture.

See the full change notes

## Upgrading to 1.25

We would like to hear from you regarding your experience upgrading to Istio 1.25. You can provide feedback in the `#release-1.25` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.

Attending KubeCon Europe 2025? Be sure to stop by the co-located [Istio Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/istio-day/) to catch some great talks, or swing by the [Istio project booth](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/attend/venue-travel/) to chat.
