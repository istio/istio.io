---
title: Announcing Istio 1.24.0
linktitle: 1.24.0
subtitle: Major Release
description: Istio 1.24 Release Announcement.
publishdate: 2024-11-07
release: 1.24.0
aliases:
- /news/announcing-1.24
- /news/announcing-1.24.0
---

We are pleased to announce the release of Istio 1.24. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.24.0 release published!
We would like to thank the Release Managers for this release, **Zhonghu Xu** from Huawei, **Mike Morris** from Microsoft, and **Daniel Hawton** from Solo.io.

{{< relnote >}}

{{< tip >}}
Istio 1.24.0 is officially supported on Kubernetes versions `1.28` to `1.31`.
{{< /tip >}}

## What’s new?

### Ambient mode is promoted to stable

We are thrilled to announce the promotion of Istio ambient mode to Stable (or "General Available" or "GA")!
This marks the final stage in Istio's [feature phase progression](/docs/releases/feature-stages/), signaling the feature is fully ready for broad production usage.

Since its [announcement in 2022](/blog/2022/introducing-ambient-mesh/), the community has been hard at work [innovating](/blog/2024/inpod-traffic-redirection-ambient/),
[scaling](/blog/2024/ambient-vs-cilium/), [stabilizing](/blog/2024/ambient-reaches-beta/), and tuning ambient mode to be ready for prime time.

On top of [countless changes since the Beta release](/news/releases/1.23.x/announcing-1.23/#ambient-ambient-ambient), Istio 1.24 comes with a number of enhancements to ambient mode:

* New `status` messages are now written to a variety of resources, including `Services` and `AuthorizationPolicies`, to help understand the current state of the object.
* Policies can now be attached directly to `ServiceEntry`s. Give it a try with a simplified [egress gateway](https://www.solo.io/blog/egress-gateways-made-easy/)!
* A brand new, exhaustive, [troubleshooting guide](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient). Fortunately, a number of bug fixes in Istio 1.24 makes many of these troubleshooting steps no longer needed!
* Many bug fixes. In particular, edge cases around pods with multiple interfaces, GKE Intranode visibility, IPv4-only clusters, and many more have been improved.

### Improved retries

Automatic [retries](/docs/concepts/traffic-management/#retries) has been a core part of Istio's traffic management functionality.
In Istio 1.24, it gets even better.

Previously, retries were exclusively implemented on the *client sidecar*.
However, a common source of connection failures actually comes from communicating between the *server sidecar* and the server application,
typically from attempting to re-use a connection the backend is closing.
With the improved functionality, we are able to detect this case and retry on the server sidecar automatically.

Additionally, the default policy of retrying `503` errors has been removed.
This was initially added primarily to handle the above failure types, but has some negative side effects on some applications.

## Upgrading to 1.24

We would like to hear from you regarding your experience upgrading to Istio 1.24. You can provide feedback in the `#release-1.24` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.

Attending KubeCon North America 2024?
Be sure to stop by the co-located [Istio Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/) to catch some [great talks](blog/2024/kubecon-na/), or swing by the [Istio project booth](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/venue-travel/#venue-maps) to chat.
