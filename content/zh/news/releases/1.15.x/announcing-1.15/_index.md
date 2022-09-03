---
title: 发布 Istio 1.15
linktitle: 1.15
subtitle: Major Update
description: Istio 1.15 发布公告。
publishdate: 2022-08-31
release: 1.15.0
skip_list: true
aliases:
- /zh/news/announcing-1.15
- /zh/news/announcing-1.15.0
---

我们很高兴地宣布发布 Istio 1.15！

{{< relnote >}}

这是 2022 年发布的第三个 Istio 版本，我们要感谢整个 Istio 社区帮助发布 Istio 1.15.0。
我们特别感谢来自 Google 的发布经理 Sam Naser 和 Aryan Gupta、来自 Intel 的 Ziyang Xiao 和来自 Solo.io 的 Daniel Hawton。
同样，我们还要感谢测试和发布工作组负责人 Eric Van Norman（IBM）的帮助和指导。

{{< tip >}}
Istio 1.15.0 正式支持了 Kubernetes `1.22` 到 `1.25` 的所有版本。
{{< /tip >}}

## 版本新特性{#whats-new}

以下是该版本的一些亮点：

### 支持了 arm64{#arm64-support}

我们现在为适配 arm64 系统架构重新构建了 Istio，因此您可以在 Raspberry Pi 或 [Tau T2A](https://cloud.google.com/blog/products/compute/tau-t2a-is-first-compute-engine-vm-on-an-arm-chip) VM 上运行 Istio。

### 支持卸载 istioctl {#istioctl-uninstall}

我们希望您永远不需要从集群中卸载 Istio，但如果您确实需要卸载 Istio（也许您想使用不同的参数重新安装它？），在此版本发布之前，我们已经为许多版本的卸载 Istio 提供了实验性支持。
在最新发布的 1.15 中，我们修复了之前卸载 Istio 剩余的问题，并且将这个功能提升至稳定版。

## 升级到 Istio 1.15{#upgrading-to-1.15}

当您升级时，我们希望收到您的来信！请花几分钟时间回复一份简短的[问卷](https://forms.gle/SWHFBmwJspusK1hv6)，以便让我们知道我们的工作情况。

您还可以加入 [Discuss Istio](https://discuss.istio.io/)的对话，或加入我们的 [Slack 工作区](https://slack.istio.io/)。
您想直接为 Istio 做出贡献吗？您可以查找并加入我们其中任意一个[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)以帮助我们改进 Istio。

## KubeCon NA 上的 Istio{#istio-at-kubecon-na}

Istio 将于今年 10 月在底特律参加 [KubeCon 北美会议](https://events.linuxfoundation.org/kubecon-cloudnativecon-north-america/)，请不要错过 [TOC 成员 John Howard 与来自 Microsoft 的 Keith Mattix 的演讲](https://sched.co/182KL)，您将在其中了解[通用服务网格 API 的新 GAMMA 计划](https://gateway-api.sigs.k8s.io/contributing/gamma/)。还有关于[在生产环境中动态测试版本和分片应用的分散路由的讨论](https://sched.co/182KO)。而且，如果这还不够的话，还有一个专门用于服务网格的整个同地活动——[ServiceMeshCon NA](https://events.linuxfoundation.org/servicemeshcon-north-america/)。与项目主席 Craig Box（来自 Google）和 Lin Sun（来自 Solo.io）一起讨论服务网格技术的发展历程。

## CNCF 进度更新{#cncf-progress-update}

4 月，我们宣布 Istio 已被提议成为 [CNCF 的孵化项目](/zh/blog/2022/istio-has-applied-to-join-the-cncf/)。我们的团队一直在努力准备我们的申请，项目目前处于公开征求意见阶段。如果您想参加，请看这个[帖子](https://lists.cncf.io/g/cncf-toc/message/7367)！
