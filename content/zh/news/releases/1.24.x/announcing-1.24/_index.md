---
title: 发布 Istio 1.24.0
linktitle: 1.24.0
subtitle: 大版本更新
description: Istio 1.24 发布公告。
publishdate: 2024-11-07
release: 1.24.0
aliases:
- /zh/news/announcing-1.24
- /zh/news/announcing-1.24.0
---

我们很高兴地宣布 Istio 1.24 正式发布。感谢所有贡献者、
测试人员、用户和爱好者帮助我们发布 1.24.0 版本！
我们要感谢本次发布的发布经理，包括华为的 **Zhonghu Xu**、
微软的 **Mike Morris** 和 Solo.io 的 **Daniel Hawton**。

{{< relnote >}}

{{< tip >}}
Istio 1.24.0 正式支持 Kubernetes 版本 `1.28` 至 `1.31`。
{{< /tip >}}

## 新特性 {#whats-new}

### Ambient 模式升级为稳定版 {#ambient-mode-is-promoted-to-stable}

我们很高兴地宣布 Istio Ambient 模式已升级为稳定版本
（或“通用版本”或“GA”）！这标志着 Istio
[功能阶段进展](/zh/docs/releases/feature-stages/)的最后阶段，
表明该功能已完全准备好广泛用于生产。

自 [2022 年发布公告](/zh/blog/2022/introducing-ambient-mesh/)以来，
社区一直在努力进行[创新](/zh/blog/2024/inpod-traffic-redirection-ambient/)、
[扩展](/zh/blog/2024/ambient-vs-cilium/)、
[稳定](/zh/blog/2024/ambient-reaches-beta/)以及优化 Ambient 模式，
并为关键时刻做好准备。

除了[自 Beta 版本以来的无数变化](/zh/news/releases/1.23.x/announcing-1.23/#ambient-ambient-ambient)之外，
Istio 1.24 还对 Ambient 模式进行了多项增强：

* 新的 `status` 消息现在被写入各种资源，包括 `Service`
  和 `AuthorizationPolicy`，以帮助了解对象的当前状态。
* 现在可以将策略直接附加到 `ServiceEntry`。可以使用简化的
  [Egress 网关](https://www.solo.io/blog/egress-gateways-made-easy/)尝试一下！
* 全新的、详尽的[故障排除指南](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient)。
  幸运的是，Istio 1.24 中的许多错误修复使得很多这些故障排除步骤不再被需要！
* 大量错误修复。特别是，具有多个接口的 Pod 周围的边缘情况、
  GKE Intranode 可见性、仅 IPv4 集群等都得到了改进。

### 改进重试 {#improved-retries}

自动[重试](/zh/docs/concepts/traffic-management/#retries)一直是
Istio 流量管理功能的核心部分。在 Istio 1.24 中，它变得更加强大。

之前，重试仅在**客户端 Sidecar** 中实现。然而，
连接失败的一个常见原因实际上是**服务器 Sidecar** 与服务器应用程序之间的通信，
通常是尝试重新使用后端正在关闭的连接。借助改进的功能，
我们能够检测到这种情况并自动在服务器 Sidecar 中进行重试。

此外，重试 `503` 错误的默认策略已被删除。
最初添加该策略主要是为了处理上述故障类型，但对某些应用程序有一些负面影响。

## 升级到 1.24 {#upgrading-to-1-24}

我们希望听取您关于升级到 Istio 1.24 的体验。
您可以在我们的 [Slack 工作区](https://slack.istio.io/)中的
`#release-1.24` 频道中提供反馈。

您想直接为 Istio 做出贡献吗？
查找并加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一，
帮助我们改进。

如果您参加 2024 年北美 KubeCon 会议，
请务必前往同一地点举办的 [Istio Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/)
聆听一些[精彩演讲](/zh/blog/2024/kubecon-na/)，
或前往 [Istio 项目展位](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/venue-travel/#venue-maps)进行沟通。
