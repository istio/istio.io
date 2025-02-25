---
title: Announcing Istio 1.25.0
linktitle: 1.25.0
subtitle: Major Release
description: Istio 1.25 Release Announcement.
publishdate: 2025-02-25
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

### Ambient mode enhancements

- DNS proxying enabled by default for Ambient pods, allowing ServiceEntries and egress gateway routing to work by default.
- Default-deny policy for waypoints via GatewayClass `targetRef`.
- Ability to enforce L4 policy against the waypoint proxy instance itself.
- Support for per-pod traffic customization around virtual interfaces and DNS capture
- `istio-cni` DaemonSet can now be safely upgraded in-place in an active cluster, without requiring a node cordon to prevent pods spawned during the upgrade process from escaping ambient traffic capture.

### Zonal routing enhancements

Whether for reliability, performance, or cost reasons, controlling cross-zone and cross-region traffic is often an important day-2 operation for users.
With Istio 1.25, this just gets even easier!

The Kubernetes [Traffic distribution](https://kubernetes.io/docs/concepts/services-networking/service/#traffic-distribution) feature is now fully supported, offering a simplified interface to keep traffic local. The existing Istio [locality load balancing](https://github.com/docs/tasks/traffic-management/locality-load-balancing/) remains for more complex use cases. Ztunnel will now report the additional `source_zone`, `source_region`, `destination_zone`, and `destination_region` labels to all metrics, giving a clear view of cross-zonal traffic.

### DNS auto-allocation improvements

DNS proxying is now enabled by default for ambient workloads.
This enhances performance and security, as well as enabling [egress traffic controls](https://ambientmesh.io/docs/traffic/mesh-egress/#egress-gateways).
Along with this change comes a few advanced per-pod customization around traffic captured, including during off DNS capture for specific workloads if necessary; Check out the change notes for more information.

## Upgrading to 1.25

We would like to hear from you regarding your experience upgrading to Istio 1.25. You can provide feedback in the `#release-1.25` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.

Attending KubeCon Europe 2025?
Be sure to stop by the co-located [Istio Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/istio-day/) to catch some great talks, or swing by the [Istio project booth](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/attend/venue-travel/) to chat.
