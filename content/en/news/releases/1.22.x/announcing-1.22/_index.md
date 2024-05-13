---
title: Announcing Istio 1.22.0
linktitle: 1.22.0
subtitle: Major Release
description: Istio 1.22 Release Announcement.
publishdate: 2024-05-13
release: 1.22.0
---

We are pleased to announce the release of Istio 1.22 - one of the largest and most impactful releases we've ever launched. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.22.0 release published.

We would like to thank the Release Managers for this release, **Jianpeng He** from Tetrate, **Sumit Vij** from Credit Karma and **Zhonghu Xu** from Huawei. Once again, the release managers owe a debt of gratitude to Test & Release WG lead Eric Van Norman for his help and guidance; more on him later.

{{< relnote >}}

{{< tip >}}
Istio 1.22.0 is officially supported on Kubernetes versions `1.27` to `1.30`.
{{< /tip >}}

## What's new

### Ambient mode now in Beta

Istio’s ambient mode is designed for simplified operations without requiring changes or restarts to your application. It introduces lightweight, shared node proxies and optional Layer 7 per-workload proxies, thus removing the need for traditional sidecars from the data plane. Compared to sidecar mode, ambient mode reduces memory overhead and CPU usage by over 90% in many cases.

Under development since 2022, the Beta release status indicates ambient mode’s features and stability are ready for production workloads with appropriate precautions. [Our ambient mode blog post has all the details](/blog/2024/ambient-reaches-beta/).

### Istio APIs promoted to `v1`

Istio provides APIs that are crucial for ensuring the robust security, seamless connectivity, and effective observability of services within the service mesh. These APIs are used on thousands of clusters across the world, securing and enhancing critical infrastructure. Most of the features powered by these APIs have been [considered stable](/docs/releases/feature-stages/) for some time, but the API version has remained at `v1beta1`. As a reflection of the stability, adoption, and value of these resources, the Istio community has decided to promote these APIs to `v1` in Istio 1.22. Learn about what this means in [a blog post introducing the v1 APIs](/blog/2024/v1-apis/).

### Gateway API now Stable for service mesh

We are thrilled to announce that Service Mesh support for the Gateway API is now officially marked as "Stable"! With the release of Gateway API v1.1 and its support in Istio 1.22, you can make use of Kubernetes' next-generation traffic management APIs for both ingress ("north-south") and service mesh ("east-west") use cases. Read more about the improvements in [our Gateway API v1.1 blog](/blog/2024/gateway-mesh-ga/).

### Delta xDS now on by default

Configuration is distributed to Istio’s Envoy sidecars (as well as ztunnel and waypoints) using the xDS protocol. Traditionally, this has been through a "state of the world" design, where if one out of a thousand services is modified, Istio would send information about all 1,000 services to every sidecar. This was very costly in terms of CPU usage (both in the control plane, and aggregated across the sidecars) and network throughput.

To improve performance, we implemented the [delta (or incremental) xDS APIs](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol#incremental-xds), which sends only _changed_ configurations. We have worked hard over the past 3 years to ensure that the outcome with delta xDS is provably the same as using the state of the world system. and it has been a supported option in the last few Istio releases. In 1.22, we have made it the default. To learn more about the development of this feature, check out [this EnvoyCon talk](https://www.youtube.com/watch?v=LOm1ptEWx_Y).

### Path templating in Authorization Policy

Up until now, you have had to list every path to which you wanted to apply an `AuthorizationPolicy` object. Istio 1.22 takes advantage of a new feature in Envoy allowing you to specify [template wildcards](/docs/reference/config/security/authorization-policy/#Operation) to match of a path.

You can now safely allow path matches like `/tenants/{*}/application_forms/guest` — a [long-requested feature](https://github.com/istio/istio/issues/16585)!

Special thanks to [Emre Savcı](https://github.com/mstrYoda) from Trendyol for building a prototype, and for never giving up.

## A thank you

Finally, we would like to take this opportunity to congratulate [Eric Van Norman](https://github.com/ericvn) on the eve of his retirement, after 34 years at IBM.

Eric is a much respected member of the Istio community. Joining the project in early 2019, he served as a Release Manager for Istio 1.4, a maintainer in the Documentation working group, the lead of the Test and Release working group, and was an obvious choice to join the Technical Oversight Committee in 2021.

Much of Eric’s development work is behind-the-scenes, making sure the various pipelines that build and test Istio’s releases and documentation continue to operate and improve. Indeed, Eric is the [second largest contributor](https://istio.devstats.cncf.io/d/66/developer-activity-counts-by-companies?orgId=1&var-period_name=Last%20decade&var-metric=contributions&var-repogroup_name=All&var-country_name=All&var-companies=All) to Istio on GitHub.

While Eric will be stepping down from the TOC, he has promised to stay around in the community - although we may have to change from Slack to ham radio to reach him!

## Upgrading to 1.22

We would like to hear from you regarding your experience upgrading to Istio 1.22. You can provide feedback
in the [`#release-1.22`](https://istio.slack.com/archives/C06PU4H4EMR) channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of
our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
