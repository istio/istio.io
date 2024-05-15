---
title: 发布 Istio 1.22.0
linktitle: 1.22.0
subtitle: 大版本更新
description: Istio 1.22 发布公告。
publishdate: 2024-05-13
release: 1.22.0
aliases:
- /zh/news/announcing-1.22
- /zh/news/announcing-1.22.0
---

我们很高兴地宣布 Istio 1.22 发布。这是我们发布过的规模最大、影响力最强的版本之一。
感谢所有贡献者、测试人员、用户和爱好者帮助我们发布 1.22.0 版本。

我们要感谢此版本的发布经理，来自 Tetrate 的 **Jianpeng He**、
来自 Credit Karma 的 **Sumit Vij** 和来自华为的 **Zhonghu Xu**。
这些发布经理们再次感谢测试和发布工作组负责人 Eric Van Norman 的帮助和指导；稍后会详细介绍他。

{{< relnote >}}

{{< tip >}}
Istio 1.22.0 已得到 Kubernetes `1.27` 到 `1.30` 的官方正式支持。
{{< /tip >}}

## 新特性 {#whats-new}

### Ambient 模式现已处于 Beta 阶段 {#ambient-mode-now-in-beta}

Istio 的 Ambient 模式旨在简化操作，无需更改或重新启动应用程序。
它引入了轻量级共享节点代理和可选的 Layer 7 全工作负载代理，
从而消除了数据平面对传统 Sidecar 的需求。与 Sidecar 模式相比，
Ambient 模式在很多情况下可以减少 90% 以上的内存开销和 CPU 使用率。

自 2022 年以来的持续开发，Beta 版本的发布状态表明 Ambient
模式的功能和稳定性已为生产工作负载做好了准备，并采取了适当的预防措施。
[我们的 Ambient 模式博客文章包含所有详细信息](/zh/blog/2024/ambient-reaches-beta/)。

### Istio API 升级至 `v1` {#istio-apis-promoted-to-v1}

Istio 提供的 API 对于确保服务网格内服务的强大安全性、无缝连接和有效可观测性至关重要。
这些 API 用于全球数千个集群，保护和增强关键基础设施。
这些 API 提供的大多数功能经过了一段时间已经[被认为是稳定的](/zh/docs/releases/feature-stages/)，
但 API 版本仍保持在 `v1beta1`。为了体现这些资源的稳定性、采用率和价值，
Istio 社区决定在 Istio 1.22 中将这些 API 升级到 `v1`。
请参阅[介绍 v1 API 的博客文章](/zh/blog/2024/v1-apis/)了解这意味着什么。

### 服务网格 Gateway API 现已稳定 {#gateway-api-now-stable-for-service-mesh}

我们很高兴地宣布，服务网格对 Gateway API 的支持现已正式被标记为“稳定”！
随着 Gateway API v1.1 的发布及其在 Istio 1.22 中的支持，
您可以利用 Kubernetes 的下一代流量管理 API 进行入口（“南北”）和服务网格（“东西”）进行案例使用。
请阅读[我们的 Gateway API v1.1 博客](/zh/blog/2024/gateway-mesh-ga/)了解有关改进的更多信息。

### Delta xDS 现在默认开启 {#delta-xds-now-on-by-default}

使用 xDS 协议将配置分发到 Istio 的 Envoy Sidecar（以及 ztunnel 和 waypoint）。
传统意义上，这是通过“全局状态”设计实现的，如果一千个服务中的一个被修改，
Istio 会将所有 1,000 个服务的信息发送到每个 Sidecar。
就 CPU 使用率（在控制平面中以及跨 Sidecar 聚合）和网络吞吐量而言，这非常昂贵。

为了提高性能，我们实现了 [Delta（或增量）xDS API](https://www.envoyproxy.io/docs/envoy/latest/api-docs/xds_protocol#incremental-xds)，
它仅发送**已变更**的配置。在过去 3 年里，我们一直在努力确保 Delta xDS 的结果与使用全局状态系统的结果相同。
在最近的几个 Istio 版本中，它一直是受支持的选项。在 1.22 中，我们将其设为默认值。
要了解有关此功能开发的更多信息，请查看[此 EnvoyCon 演讲](https://www.youtube.com/watch?v=LOm1ptEWx_Y)。

### 鉴权策略中的路径模板 {#path-templating-in-authorization-policy}

到目前为止，您必须列出要应用 `AuthorizationPolicy` 对象的每个路径。
Istio 1.22 利用 Envoy 中的一项新功能，允许您指定[模板通配符](/zh/docs/reference/config/security/authorization-policy/#Operation)来匹配路径。

您现在可以安全地允许像 `/tenants/{*}/application_forms/guest`
这样的路径匹配 - 这是一个[历经沧桑的功能需求](https://github.com/istio/istio/issues/16585)！

特别感谢来自 Trendyol 的 [Emre Savcı](https://github.com/mstrYoda) 构建了该原型，以及永不放弃的精神。

## 感谢 {#a-thank-you}

最后，我们想借此机会祝贺 [Eric Van Norman](https://github.com/ericvn) 在 IBM 工作 34 年后退休。

Eric 是 Istio 社区中一位备受尊敬的成员。他于 2019 年初加入该项目，
担任 Istio 1.4 的发布经理、文档工作组的维护者、测试和发布工作组的负责人，
并且在 2021 年顺理成章的加入技术监督委员会。

Eric 的大部分开发工作都是在幕后进行的，确保构建和测试 Istio 版本和文档的各种管道继续运行和改进。
事实上，Eric 是 Istio GitHub 中的[第二大贡献者](https://istio.devstats.cncf.io/d/66/developer-activity-counts-by-companies?orgId=1&var-period_name=Last%20decade&var-metric=contributions&var-repogroup_name=All&var-country_name=All&var-companies=All)。

虽然 Eric 将从 TOC 辞职，但他已承诺留在社区 - 尽管我们可能需要从 Slack 改为业余无线电才能联系到他！

## 升级到 1.22 {#upgrading-to-122}

我们希望听到您关于升级到 Istio 1.22 的体验。
您可以在我们的 [Slack 工作区](https://slack.istio.io/)的
[`#release-1.22`](https://istio.slack.com/archives/C06PU4H4EMR) 频道中提供反馈。

您想直接为 Istio 做出贡献吗？找到并加入我们的某一个[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)并帮助我们改进。
