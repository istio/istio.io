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

We are pleased to announce the release of Istio 1.24. Thank you to all our contributors, testers, users and enthusiasts for helping us get the 1.24.0 release published! We would like to thank the Release Managers for this release, **Zhonghu Xu** from Huawei, **Mike Morris** from Microsoft, and **Daniel Hawton** from Solo.io.
我们很高兴地宣布 Istio 1.24 正式发布。感谢所有贡献者、测试人员、用户和爱好者帮助我们发布 1.24.0 版本！我们要感谢本次发布的发布经理，包括华为的 **Zhonghu Xu**、微软的 **Mike Morris** 和 Solo.io 的 **Daniel Hawton**。

{{< relnote >}}

{{< tip >}}
Istio 1.24.0 is officially supported on Kubernetes versions `1.28` to `1.31`.
Istio 1.24.0 正式支持 Kubernetes 版本“1.28”至“1.31”。
{{< /tip >}}

## 新特性 {#whats-new}

### Ambient mode is promoted to stable
### Ambient 模式升级为稳定模式

We are thrilled to announce the promotion of Istio ambient mode to Stable (or "General Available" or "GA")! This marks the final stage in Istio's [feature phase progression](/docs/releases/feature-stages/), signaling the feature is fully ready for broad production usage.
我们很高兴地宣布 Istio 环境模式已升级为稳定版本（或“通用版本”或“GA”）！这标志着 Istio [功能阶段进展](/docs/releases/feature-stages/) 的最后阶段，表明该功能已完全准备好广泛用于生产。

Since its [announcement in 2022](/blog/2022/introducing-ambient-mesh/), the community has been hard at work [innovating](/blog/2024/inpod-traffic-redirection-ambient/), [scaling](/blog/2024/ambient-vs-cilium/), [stabilizing](/blog/2024/ambient-reaches-beta/), and tuning ambient mode to be ready for prime time.
自 [2022 年发布公告](/blog/2022/introducing-ambient-mesh/) 以来，社区一直在努力进行 [创新](/blog/2024/inpod-traffic-redirection-ambient/)、[扩展](/blog/2024/ambient-vs-cilium/)、[稳定](/blog/2024/ambient-reaches-beta/) 和调整环境模式，为黄金时段做好准备。

On top of [countless changes since the Beta release](/news/releases/1.23.x/announcing-1.23/#ambient-ambient-ambient), Istio 1.24 comes with a number of enhancements to ambient mode:
除了 [自 Beta 版本以来的无数变化](/news/releases/1.23.x/announcing-1.23/#ambient-ambient-ambient) 之外，Istio 1.24 还对环境模式进行了多项增强：

* New `status` messages are now written to a variety of resources, including `Services` and `AuthorizationPolicies`, to help understand the current state of the object.
* Policies can now be attached directly to `ServiceEntry`s. Give it a try with a simplified [egress gateway](https://www.solo.io/blog/egress-gateways-made-easy/)!
* A brand new, exhaustive, [troubleshooting guide](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient). Fortunately, a number of bug fixes in Istio 1.24 makes many of these troubleshooting steps no longer needed!
* Many bug fixes. In particular, edge cases around pods with multiple interfaces, GKE Intranode visibility, IPv4-only clusters, and many more have been improved.
* 新的 `status` 消息现在被写入各种资源，包括 `Services` 和 `AuthorizationPolicies`，以帮助了解对象的当前状态。
* 现在可以将策略直接附加到 `ServiceEntry`。使用简化的 [egress 网关](https://www.solo.io/blog/egress-gateways-made-easy/) 尝试一下！
* 全新的、详尽的 [故障排除指南](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient)。幸运的是，Istio 1.24 中的许多错误修复使得这些故障排除步骤中的许多不再需要！
* 大量错误修复。特别是，具有多个接口的 pod 周围的边缘情况、GKE Intranode 可见性、仅 IPv4 集群等都得到了改进。

### Improved retries
### 改进重试

Automatic [retries](/docs/concepts/traffic-management/#retries) has been a core part of Istio's traffic management functionality. In Istio 1.24, it gets even better.
自动重试一直是 Istio 流量管理功能的核心部分。在 Istio 1.24 中，它变得更加强大。

Previously, retries were exclusively implemented on the *client sidecar*. However, a common source of connection failures actually comes from communicating between the *server sidecar* and the server application, typically from attempting to re-use a connection the backend is closing. With the improved functionality, we are able to detect this case and retry on the server sidecar automatically.
以前，重试仅在 *客户端 sidecar* 上实现。然而，连接失败的一个常见原因实际上是 *服务器 sidecar* 与服务器应用程序之间的通信，通常是尝试重新使用后端正在关闭的连接。借助改进的功能，我们能够检测到这种情况并自动在服务器 sidecar 上重试。

Additionally, the default policy of retrying `503` errors has been removed. This was initially added primarily to handle the above failure types, but has some negative side effects on some applications.
此外，重试“503”错误的默认策略已被删除。最初添加该策略主要是为了处理上述故障类型，但对某些应用程序有一些负面影响。

## Upgrading to 1.24
## 升级到 1.24

We would like to hear from you regarding your experience upgrading to Istio 1.24. You can provide feedback in the `#release-1.24` channel in our [Slack workspace](https://slack.istio.io/).
我们希望听取您关于升级到 Istio 1.24 的体验。您可以在我们的 [Slack 工作区](https://slack.istio.io/) 中的 `#release-1.24` 频道中提供反馈。

Would you like to contribute directly to Istio? Find and join one of our [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) and help us improve.
您想直接为 Istio 做出贡献吗？查找并加入我们的 [工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) 之一，帮助我们改进。

Attending KubeCon North America 2024? Be sure to stop by the co-located [Istio Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/) to catch some [great talks](blog/2024/kubecon-na/), or swing by the [Istio project booth](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/venue-travel/#venue-maps) to chat.
参加 2024 年北美 KubeCon 会议？请务必前往同一地点举办的 [Istio Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/co-located-events/istio-day/) 聆听一些 [精彩演讲](blog/2024/kubecon-na/)，或前往 [Istio 项目展位](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/venue-travel/#venue-maps) 聊天。
