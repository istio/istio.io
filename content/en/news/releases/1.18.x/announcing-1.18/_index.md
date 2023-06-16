---
title: Announcing Istio 1.18.0
linktitle: 1.18.0
subtitle: Major Release
description: Istio 1.18 Release Announcement.
publishdate: 2023-06-07
release: 1.18.00
aliases:
    - /news/announcing-1.18
    - /news/announcing-1.18.0
---

We are pleased to announce the release of Istio 1.18. This is the second Istio release of 2023, and the first to ship with Ambient mode! We would like to thank the entire Istio community for helping get the 1.18.0 release published. We would like to thank the Release Managers for this release, `Paul Merrison` from Tetrate, `Kalya Subramanian` from Microsoft and `Xiaopeng Han` from DaoCloud. The release managers would specially like to thank the Test & Release WG lead Eric Van Norman (IBM) for his help and guidance throughout the release cycle. We would also like to thank the maintainers of the Istio work groups and the broader Istio community for helping us throughout the release process with timely feedback, reviews, community testing and for all your support to help ensure a timely release.

{{< relnote >}}

{{< tip >}}
Istio 1.18.0 is officially supported on Kubernetes versions `1.24` to `1.27`.
{{< /tip >}}

## What's new

### Ambient Mesh

Istio 1.18 marks the first release of ambient mesh, a new Istio data plane mode that’s designed for simplified operations, broader application compatibility, and reduced infrastructure cost. For more details see the [announcement blog](/blog/2022/introducing-ambient-mesh/).

### Gateway API Support Improvements

Istio 1.18 improves support for the Kubernetes Gateway API, including support for extra v1beta1 resources and enhancements to automated deployment logic to no longer rely on pod injection.  Users of Gateway API on Istio should review this release's upgrade notes for important guidance on upgrading.

### Proxy Concurrency Changes

Previously, the proxy `concurrency` setting, which configures how many worker threads the proxy runs,
was inconsistently configured between sidecars and different gateway installation mechanisms.  In Istio 1.18, concurrency configuration has been tweaked to be consistent across deployment types.  More details on this change can be found in the upgrade notes for this release.

### Enhancements to the `istioctl` command

Added a number of enhancements to the istioctl command including enhancements to the bug reporting process and various improvements to the istioctl analyze command.

## Upgrading to 1.18

We would like to hear from you regarding your experience upgrading to Istio 1.18. You can provide feedback at [Discuss Istio](https://discuss.istio.io/), or join the #release-1.18 channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
