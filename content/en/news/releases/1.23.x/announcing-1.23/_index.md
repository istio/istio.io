---
title: Announcing Istio 1.23.0
linktitle: 1.23.0
subtitle: Major Release
description: Istio 1.23 Release Announcement.
publishdate: 2024-08-14
release: 1.23.0
aliases:
- /news/announcing-1.23
- /news/announcing-1.23.0
---

We are pleased to announce the release of Istio 1.23. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.23.0 release published! We would like to thank the Release Managers for this release, **Sumit Vij** from Credit Karma, **Zhonghu Xu** from Huawei and **Mike Morris** from Microsoft.

{{< relnote >}}

{{< tip >}}
Istio 1.23.0 is officially supported on Kubernetes versions `1.27` to `1.30`.
{{< /tip >}}

## What’s new?

### Ambient, ambient, ambient

Hot on the tail of the recent promotion of [ambient mode to Beta in Istio 1.22](/blog/2024/ambient-reaches-beta/), Istio 1.23 comes with a huge set of improvements. Working closely with the many users who have been adopting ambient mode, we have been working diligently to address all the feedback we have received. These improvements include broader platform support, added features, bug fixes, and performance improvements.

A small sample of the highlights:

* Support for `DestinationRule` in waypoint proxies.
* Support for DNS `ServiceEntries` in waypoints and ztunnel.
* Support for sharing waypoints across namespaces.
* Support for the new `Service` field `trafficDistribution`, allowing keeping traffic in local zones/regions.
* Support for Dual Stack and IPv6 clusters.
* A new Grafana dashboard for ztunnel.
* A single Helm chart for installing all the ambient mode components at once.
* Performance improvements: our testing shows up to a 50% improvement in throughput compared to Istio 1.22.
* Tons of bug fixes: improvements to pod startup, support for Services without selectors, improvements to logging, and more!

### DNS auto-allocation improvements

For years, Istio has has an [address allocation option](/docs/ops/configuration/traffic-management/dns-proxy/#address-auto-allocation) for use with the DNS proxy mode. This solves a number of problems for Service routing.

In Istio 1.23, a new implementation of this feature was added. In the new approach, the allocated IP addresses are persisted in the `ServiceEntry` `status` field, ensuring that they are never changed. This fixes long-standing reliability issues with the old approach, where the allocation would occasionally shuffle and cause issues. Additionally, this approach is more standard, easier to debug, and makes the feature work with ambient mode!

This mode is off by default in 1.23, but can be enabled with `PILOT_ENABLE_IP_AUTOALLOCATE=true`.

### Retry improvements preview

In this release, a new feature preview for an enhancement to the default retry policy has been implemented. Historically, retries were done only on *outbound* traffic. For many cases, this is what you want: the request can be retried to a different pod, which has a better chance to succeed. However, this left a gap: often, a request would fail simply because the application had closed a connection we had kept alive and tried to re-use.

We have added to detect this scenario, and retry. This is expected to reduce a common source of 503 errors in the mesh.

This can be enabled with `ENABLE_INBOUND_RETRY_POLICY=true`. It is expected to be on by default in future releases.

### A coat of paint for Bookinfo

Improvements in 1.23 are not limited to Istio itself: in this release, everyone's favorite sample application, Bookinfo, also gets a facelift!

The new application features a more modern design, and performance improvements that resolve some unexpected slowness in the `productpage` and `details` services.

{{< image width="80%" link="/docs/setup/getting-started/bookinfo-browser.png" caption="The improved Bookinfo application" >}}

### Other highlights

* The distroless images were upgraded to use the [Wolfi](https://github.com/wolfi-dev) container base OS.
* The `istioctl proxy-status` command was improved to include the time since last change, and more relevant status values.

## Deprecating the in-cluster Operator

Three years ago, we [updated our documentation](/docs/setup/install/operator/) to discourage the use of the in-cluster operator for new Istio installations. We are now ready to formally mark it as deprecated in Istio 1.23. People leveraging the operator — which we estimate to be fewer than 10% of our user base — will need to migrate to other install and upgrade mechanisms in order to upgrade to Istio 1.24 or above. The expected release date for 1.24 is November 2024.

We recommend users move to Helm and istioctl, which remain supported by the Istio project.  Migrating to istioctl is trivial; migrating to Helm will require tooling which we will publish along with the 1.24 release.

Users who wish to stick with the operator pattern have two third-party options in the [istio-ecosystem](https://github.com/istio-ecosystem/) org.

Please check out [our deprecation announcement blog post](/blog/2024/in-cluster-operator-deprecation-announcement/) for more details on the change.

## Upgrading to 1.23

We would like to hear from you regarding your experience upgrading to Istio 1.23. You can provide feedback in the `#release-1.23` channel in our [Slack workspace](https://slack.istio.io/).

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
