---
title: Announcing Istio 1.19.0
linktitle: 1.19.0
subtitle: Major Release
description: Istio 1.19 Release Announcement.
publishdate: 2023-09-05
release: 1.19.0
aliases:
    - /news/announcing-1.19
    - /news/announcing-1.19.0
---

We are pleased to announce the release of Istio 1.19. This is the third Istio release of 2023. We would like to thank the entire Istio community for helping get the 1.19.0 release published. We would like to thank the Release Managers for this release, `Kalya Subramanian` from Microsoft, `Xiaopeng Han` from DaoCloud, and `Aryan Gupta` from Google. The release managers would specially like to thank the Test & Release WG lead Eric Van Norman (IBM) for his help and guidance throughout the release cycle. We would also like to thank the maintainers of the Istio work groups and the broader Istio community for helping us throughout the release process with timely feedback, reviews, community testing and for all your support to help ensure a timely release.

{{< relnote >}}

{{< tip >}}
Istio 1.19.0 is officially supported on Kubernetes versions `1.25` to `1.28`.
{{< /tip >}}

## What's new

### Gateway API

The Kubernetes [Gateway API](http://gateway-api.org/) is an initiative to bring a rich set of service networking APIs (similar to those of Istio VirtualService and Gateway) to Kubernetes.

In this release, in tandem with the Gateway API v0.8.0 release, [service mesh support](https://gateway-api.sigs.k8s.io/blog/2023/0829-mesh-support/) is officially added! This effort was a widespread community effort across the broader Kubernetes ecosystem and has multiple conformant implementations (including Istio).

Check out the [mesh documentation](/docs/tasks/traffic-management/ingress/gateway-api/#mesh-traffic) to get started. As with any experimental feature, feedback is highly appreciated.

In addition to mesh traffic, usage of the API for ingress traffic [is in beta](/docs/tasks/traffic-management/ingress/gateway-api/#configuring-a-gateway) and rapidly approaching GA.

### Ambient Mesh

During this release cycle, the team has been hard at work improving the [ambient mesh](/docs/ops/ambient/), a new Istio deployment model alternative to the previous sidecar model. If you haven't heard of ambient yet, check out the [introduction blog post](/blog/2022/introducing-ambient-mesh/).

In this release, support for `ServiceEntry`, `WorkloadEntry`, `PeerAuthentication`, and DNS proxying has been added. In addition, a number of bug fixes and reliability improvements have been made.

Note that ambient mesh remains at the alpha feature phase in this release. Your feedback is critical to driving ambient to Beta, so please try it out and let us know what you think!

### Additional Improvements

To further simplify the `Virtual Machine` and `Multicluster` experiences, the address field is now optional in the `WorkloadEntry` resources.

We also added enhancements to security configurations. For example, you
can configure `OPTIONAL_MUTUAL` for your Istio ingress gateway's TLS settings, which allows optional use and validation of a client certificate. Furthermore, you can also configure your preferred cipher suites used for non Istio mTLS traffic via `MeshConfig`.

## Upgrading to 1.19

We would like to hear from you regarding your experience upgrading to Istio 1.19. You can provide feedback at [Discuss Istio](https://discuss.istio.io/), or join the #release-1.19 channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
