---
title: 发布 Istio 1.22.0
linktitle: 1.22.0
subtitle: 大版本更新
description: Istio 1.22 发布公告。
publishdate: 2024-05-13
release: 1.22.0
---

We are pleased to announce the release of Istio 1.22 - one of the largest and most impactful releases we've ever launched. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.22.0 release published.
我们很高兴地宣布 Istio 1.22 发布。这是我们发布过的规模最大、影响力最强的版本之一。
感谢所有贡献者、测试人员、用户和爱好者帮助我们发布 1.22.0 版本。

We would like to thank the Release Managers for this release, **Jianpeng He** from Tetrate, **Sumit Vij** from Credit Karma and **Zhonghu Xu** from Huawei. Once again, the release managers owe a debt of gratitude to Test & Release WG lead Eric Van Norman for his help and guidance; more on him later.
我们要感谢此版本的发布经理，来自 Tetrate 的 **Jianpeng He**、
来自 Credit Karma 的 **Sumit Vij** 和来自华为的 **Zhonghu Xu**。
这些发布经理们再次感谢测试和发布工作组负责人 Eric Van Norman 的帮助和指导；稍后会详细介绍他。

{{< relnote >}}

{{< tip >}}
Istio 1.22.0 is officially supported on Kubernetes versions `1.27` to `1.30`.
Istio 1.22.0 已得到 Kubernetes `1.27` 到 `1.30` 的官方正式支持。
{{< /tip >}}

## 新特性 {#whats-new}

### Ambient mode now in Beta
### Ambient 模式现已处于测试阶段 {#ambient-mode-now-in-beta}

Istio’s ambient mode is designed for simplified operations without requiring changes or restarts to your application. It introduces lightweight, shared node proxies and optional Layer 7 per-workload proxies, thus removing the need for traditional sidecars from the data plane. Compared to sidecar mode, ambient mode reduces memory overhead and CPU usage by over 90% in many cases.
Istio 的 Ambient 模式旨在简化操作，无需更改或重新启动应用程序。
它引入了轻量级共享节点代理和可选的 Layer 7 全工作负载代理，
从而消除了数据平面对传统 Sidecar 的需求。与 Sidecar 模式相比，
Ambient 模式在很多情况下可以减少 90% 以上的内存开销和 CPU 使用率。

Under development since 2022, the Beta release status indicates ambient mode’s features and stability are ready for production workloads with appropriate precautions. [Our ambient mode blog post has all the details](/blog/2024/ambient-reaches-beta/).
自 2022 年以来一直在开发中，Beta 版本状态表明环境模式的功能和稳定性已为生产工作负载做好了准备，
并采取了适当的预防措施。[我们的环境模式博客文章包含所有详细信息](/blog/2024/ambient-reaches-beta/)。

### Istio APIs promoted to `v1`
### Istio API 升级为“v1”

Istio provides APIs that are crucial for ensuring the robust security, seamless connectivity, and effective observability of services within the service mesh. These APIs are used on thousands of clusters across the world, securing and enhancing critical infrastructure. Most of the features powered by these APIs have been [considered stable](/docs/releases/feature-stages/) for some time, but the API version has remained at `v1beta1`. As a reflection of the stability, adoption, and value of these resources, the Istio community has decided to promote these APIs to `v1` in Istio 1.22. Learn about what this means in [a blog post introducing the v1 APIs](/blog/2024/v1-apis/).
Istio 提供的 API 对于确保服务网格内服务的强大安全性、无缝连接和有效可观察性至关重要。 这些 API 用于全球数千个集群，保护和增强关键基础设施。 这些 API 提供的大多数功能已经[被认为是稳定的](/docs/releases/feature-stages/) 一段时间了，但 API 版本仍保持在“v1beta1”。 为了体现这些资源的稳定性、采用率和价值，Istio 社区决定在 Istio 1.22 中将这些 API 升级到“v1”。 请参阅[介绍 v1 API 的博客文章](/blog/2024/v1-apis/) 了解这意味着什么。

### Gateway API now Stable for service mesh
### 服务网格网关 API 现在稳定

We are thrilled to announce that Service Mesh support for the Gateway API is now officially marked as "Stable"! With the release of Gateway API v1.1 and its support in Istio 1.22, you can make use of Kubernetes' next-generation traffic management APIs for both ingress ("north-south") and service mesh ("east-west") use cases. Read more about the improvements in [our Gateway API v1.1 blog](/blog/2024/gateway-mesh-ga/).
我们很高兴地宣布，Service Mesh 对 Gateway API 的支持现已正式标记为“稳定”！ 随着 Gateway API v1.1 的发布及其在 Istio 1.22 中的支持，您可以利用 Kubernetes 的下一代流量管理 API 进行入口（“南北”）和服务网格（“东西”）使用 案例。 请阅读[我们的 Gateway API v1.1 博客](/blog/2024/gateway-mesh-ga/) 了解有关改进的更多信息。

### Delta xDS now on by default
### Delta xDS 现在默认开启

Configuration is distributed to Istio’s Envoy sidecars (as well as ztunnel and waypoints) using the xDS protocol. Traditionally, this has been through a "state of the world" design, where if one out of a thousand services is modified, Istio would send information about all 1,000 services to every sidecar. This was very costly in terms of CPU usage (both in the control plane, and aggregated across the sidecars) and network throughput.
使用 xDS 协议将配置分发到 Istio 的 Envoy sidecar（以及 ztunnel 和 waypoints）。 传统上，这是通过“世界状态”设计实现的，如果千分之一的服务被修改，Istio 会将所有 1,000 个服务的信息发送到每个 sidecar。 就 CPU 使用率（在控制平面中以及跨 sidecar 聚合）和网络吞吐量而言，这非常昂贵。

To improve performance, we implemented the [delta (or incremental) xDS APIs](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol#incremental-xds), which sends only _changed_ configurations. We have worked hard over the past 3 years to ensure that the outcome with delta xDS is provably the same as using the state of the world system. and it has been a supported option in the last few Istio releases. In 1.22, we have made it the default. To learn more about the development of this feature, check out [this EnvoyCon talk](https://www.youtube.com/watch?v=LOm1ptEWx_Y).
为了提高性能，我们实现了[delta（或增量）xDS API](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol#incremental-xds)，它仅发送_changed_配置。 在过去 3 年里，我们一直在努力确保 delta xDS 的结果与使用世界状态系统的结果相同。 在最近的几个 Istio 版本中，它一直是受支持的选项。 在 1.22 中，我们将其设为默认值。 要了解有关此功能开发的更多信息，请查看 [此 EnvoyCon 演讲](https://www.youtube.com/watch?v=LOm1ptEWx_Y)。

### Path templating in Authorization Policy

Up until now, you have had to list every path to which you wanted to apply an `AuthorizationPolicy` object. Istio 1.22 takes advantage of a new feature in Envoy allowing you to specify [template wildcards](/docs/reference/config/security/authorization-policy/#Operation) to match of a path.
到目前为止，您必须列出要应用“AuthorizationPolicy”对象的每个路径。 Istio 1.22 利用 Envoy 中的一项新功能，允许您指定[模板通配符](/docs/reference/config/security/authorization-policy/#Operation) 来匹配路径。

You can now safely allow path matches like `/tenants/{*}/application_forms/guest` — a [long-requested feature](https://github.com/istio/istio/issues/16585)!
您现在可以安全地允许像“/tenants/{*}/application_forms/guest”这样的路径匹配——这是一个[长期请求的功能](https://github.com/istio/istio/issues/16585)！

Special thanks to [Emre Savcı](https://github.com/mstrYoda) from Trendyol for building a prototype, and for never giving up.
特别感谢 Trendyol 的 [Emre Savcı](https://github.com/mstrYoda) 构建了原型，并且永不放弃。

## A thank you

Finally, we would like to take this opportunity to congratulate [Eric Van Norman](https://github.com/ericvn) on the eve of his retirement, after 34 years at IBM.
最后，我们想借此机会祝贺 [Eric Van Norman](https://github.com/ericvn) 在 IBM 工作 34 年后退休。

Eric is a much respected member of the Istio community. Joining the project in early 2019, he served as a Release Manager for Istio 1.4, a maintainer in the Documentation working group, the lead of the Test and Release working group, and was an obvious choice to join the Technical Oversight Committee in 2021.
Eric 是 Istio 社区中一位备受尊敬的成员。 他于 2019 年初加入该项目，担任 Istio 1.4 的发布经理、文档工作组的维护者、测试和发布工作组的负责人，并且是 2021 年加入技术监督委员会的理所当然的选择。

Much of Eric’s development work is behind-the-scenes, making sure the various pipelines that build and test Istio’s releases and documentation continue to operate and improve. Indeed, Eric is the [second largest contributor](https://istio.devstats.cncf.io/d/66/developer-activity-counts-by-companies?orgId=1&var-period_name=Last%20decade&var-metric=contributions&var-repogroup_name=All&var-country_name=All&var-companies=All) to Istio on GitHub.
Eric 的大部分开发工作都是在幕后进行的，确保构建和测试 Istio 版本和文档的各种管道继续运行和改进。 事实上，Eric 是[第二大贡献者](https://istio.devstats.cncf.io/d/66/developer-activity-counts-by-companies?orgId=1&var-period_name=Last%20decade&var-metric=contributions&var -repogroup_name=All&var-country_name=All&var-companies=All) 到 GitHub 上的 Istio。

While Eric will be stepping down from the TOC, he has promised to stay around in the community - although we may have to change from Slack to ham radio to reach him!
虽然 Eric 将从 TOC 辞职，但他已承诺留在社区 - 尽管我们可能需要从 Slack 改为业余无线电才能联系到他！

## Upgrading to 1.22

We would like to hear from you regarding your experience upgrading to Istio 1.22. You can provide feedback in the [`#release-1.22`](https://istio.slack.com/archives/C06PU4H4EMR) channel in our [Slack workspace](https://slack.istio.io/).
我们希望听到您关于升级到 Istio 1.22 的体验。 您可以在我们的 [Slack 工作区](https://slack.istio.io/) 的 [`#release-1.22`](https://istio.slack.com/archives/C06PU4H4EMR) 频道中提供反馈。

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
您想直接为 Istio 做出贡献吗？ 查找并加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一并帮助我们改进。
