---
title: 发布 Istio 1.23.0
linktitle: 1.23.0
subtitle: 大版本更新
description: Istio 1.23 发布公告。
publishdate: 2024-08-14
release: 1.23.0
aliases:
- /zh/news/announcing-1.23
- /zh/news/announcing-1.23.0
---

我们很高兴地宣布 Istio 1.23 正式发布。感谢所有贡献者、测试人员、
用户和爱好者帮助我们发布 1.23.0 版本！我们要感谢本次发布的发布经理，
包括来自 Credit Karma 的 **Sumit Vij**、来自华为的 **Zhonghu Xu** 和来自微软的 **Mike Morris**。

{{< relnote >}}

{{< tip >}}
Istio 1.23.0 已得到 Kubernetes `1.27` 到 `1.30` 的官方正式支持。
{{< /tip >}}

## 新特性 {#whats-new}

### Ambient，Ambient 还是 Ambient {#ambient-ambient-ambient}

继最近将 [Istio 1.22 中的 Ambient 模式升级为 Beta 版](/zh/blog/2024/ambient-reaches-beta/)之后，
Istio 1.23 进行了一系列重大改进。我们与众多采用 Ambient 模式的用户密切合作，
努力解决收到的所有反馈。这些改进包括更广泛的平台支持、新增功能、错误修复和性能改进。

以下是一些亮点：

* 在 waypoint 代理中支持 `DestinationRule`。
* Support for DNS `ServiceEntries` in waypoints and ztunnel.
* 在 waypoint 和 ztunnel 的 DNS 中支持 `ServiceEntries`。
* Support for sharing waypoints across namespaces.
* 支持跨命名空间共享航点。
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
