---
title: Announcing Istio 1.21.0
linktitle: 1.21.0
subtitle: Major Release
description: Istio 1.21 Release Announcement.
publishdate: 2024-02-28
release: 1.21.0
aliases:
- /news/announcing-1.21
- /news/announcing-1.21.0
---

We are pleased to announce the release of Istio 1.21. This is the first Istio release of 2024. We would like to thank the
entire Istio community for helping get the 1.21.0 release published. We would like to thank the Release Managers for
this release, `Aryan Gupta` from Google, `Jianpeng He` from Tetrate, and `Sumit Vij`. The release
managers would specially like to thank the Test & Release WG lead Eric Van Norman (IBM) for his help and guidance
throughout the release cycle. We would also like to thank the maintainers of the Istio work groups and the broader Istio
community for helping us throughout the release process with timely feedback, reviews, community testing and for all
your support to help ensure a timely release.

{{< relnote >}}

{{< tip >}}
Istio 1.21.0 is officially supported on Kubernetes versions `1.26` to `1.29`.
{{< /tip >}}

## What's new

### Easing upgrades with compatibility versions

Istio 1.21 introduces a new concept known as
[compatibility versions](/docs/setup/additional-setup/compatibility-versions/).

Compatibility versions solve a long running problem in Istio: as time
passes, changes to the behavior of Istio may be desired to fix bugs,
improve integration with the rest of the
ecosystem, improve security, or fix surprising behaviors. However, even
the smallest
behavioral changes can cause issues on upgrade for a project like
Istio deployed across
thousands of companies in production. At best, this makes upgrades
more challenging - at
worst, it pushes users to not upgrade at all!

With compatibility versions, behavioral changes are decoupled from the Istio version. For
example, if you want to upgrade to Istio 1.21 but don't want to adopt the changes
introduced yet, simply install with `--set compatibilityVersion=1.20` to retain the 1.20
behavior.

Not sure if you need the old behavior? Not a problem, `istioctl` can tell you!

{{< text shell >}}
$ istioctl experimental precheck --from-version {{< istio_previous_version >}}
Warning [IST0168] (DestinationRule default/tls) The configuration "ENABLE_AUTO_SNI"
changed in release 1.20: previously, no SNI would be set; now it will be automatically
set. Or, install with `--set compatibilityVersion=1.20` to retain the old default.

Error: Issues found when checking the cluster. Istio may not be safe to install or upgrade.
See https://istio.io/v1.21/docs/reference/config/analysis for more information about
causes and resolutions.
{{< /text >}}

In this release, the following changes are gated behind compatibility versions:
* Improved `ExternalName` service support
* Automatic SNI for `SIMPLE` TLS origination in `DestinationRule`
* Default-on TLS verification for TLS origination in `DestinationRule`

`istioctl experimental precheck` can detect possibly impacted resources for all of these changes. For
more info on these changes, see the
[Upgrade Notes](/news/releases/1.21.x/announcing-1.21/upgrade-notes).

Istio joins related projects like [Kubernetes](https://github.com/kubernetes/enhancements/blob/master/keps/sig-architecture/4330-compatibility-versions/README.md) and [Go](https://go.dev/blog/compat) who have introduced
similar features.

### Binary size reductions

With each release, Istio gets faster, more reliable, and more stable, and this release is
no different. In this release, binary sizes have dropped across the board, with roughly
10MB smaller binaries.

This is especially important with the sidecar, because its deployed alongside every
workload. Coming in at 25% smaller, the sidecar image can be pulled faster improving pod
startup times. Additionally, the reduced binary size typically results in a 5MB RAM
reduction - across many pods, this quickly adds up to cost savings.
