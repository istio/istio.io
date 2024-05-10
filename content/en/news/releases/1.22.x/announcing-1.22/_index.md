---
title: Announcing Istio 1.22.0
linktitle: 1.22.0
subtitle: Major Release
description: Istio 1.22 Release Announcement.
publishdate: 2024-05-13
release: 1.22.0
aliases:
- /news/announcing-1.22
- /news/announcing-1.22.0
---

We are pleased to announce the release of Istio 1.22. We would like to thank the entire Istio community for helping get the 1.22.0 release published.
We would like to thank the Release Managers for this release, `Jianpeng He` from Tetrate, `Sumit Vij` from Credit Karma and `Zhonghu Xu` from Huawei.
The release managers would once again like to thank the Test & Release WG lead Eric Van Norman (IBM) for his help and guidance throughout the release cycle.
We would also like to thank the maintainers of the Istio work groups and the broader Istio community for helping us throughout the release process with timely feedback,
reviews, community testing and for all your support to help ensure a timely release.

{{< relnote >}}

{{< tip >}}
Istio 1.22.0 is officially supported on Kubernetes versions `1.27` to `1.30`.
{{< /tip >}}

## What's new

### Ambient Beta

Ambient mode is beta now, check more details [here]().

### Istio API Promotion

Istio provides APIs that are crucial for ensuring the robust security, seamless connectivity, and effective observability of services within the service mesh.
In Istio 1.22, the Istio community has decided to promote these APIs to `v1`, check this [blog](/blog/2024/v1-apis/).

### Gateway API

The Kubernetes [Gateway API](http://gateway-api.org/) bump to [`v1.1.0`](https://github.com/kubernetes-sigs/gateway-api/releases/tag/v1.1.0), Service Mesh support has graduated to GA.

### Delta XDS

In this release, the ["Delta"](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol#incremental-xds) xDS protocol is enabled by default, which will improve performance of configuration distribution.

### Path templating in `AuthorizationPolicy`

Support path templating was one of the hottest topic in the past, now it's available. Check more details [here](https://github.com/istio/istio/issues/16585).

## Upgrading to 1.22

We would like to hear from you regarding your experience upgrading to Istio 1.22. You can provide feedback
in the [`#release-1.22`](https://istio.slack.com/archives/C06PU4H4EMR) channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of
our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
