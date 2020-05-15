---
title: Istio 1.2 发布公告
linktitle: 1.2
subtitle: 重大更新
description: Istio 1.2 发布公告。
publishdate: 2019-06-18
release: 1.2.0
skip_list: true
aliases:
    - /zh/blog/2019/announcing-1.2
    - /zh/news/2019/announcing-1.2
    - /zh/news/announcing-1.2.0
    - /zh/news/announcing-1.2
---

我们很高兴的宣布 Istio 1.2 发布了！

{{< relnote >}}

Istio 1.2 的主题是：可预测的发布 - 质量可预测（我们想每一个发布都是一个好的发布），以及事件可预测（我们希望能够按照大家都知道的时间来发布）。

几乎所有使用 Istio 1.0 的人都注意到了，我们花了很长时间才发布了 1.1。时间太长了。其中一个原因是我们需要在测试和基础设施上做一些工作 -- 之前的构建，测试和发布过程都太过手工化。就因为这个，1.2 聚焦在了提升这些新特性的稳定性，提升整体产品的健康度。

为了让发布的质量和时间都可以预期，我们宣布了 "Code Mauve"，意味着我们将在下个迭代中聚焦建设项目基础设施。因此我们在构建，测试和发布机制上投入了大量的精力。

我们组建了 3 个新小组（GitHub 工作流组，源码组，测试方法组，构建和发布自动化最）。每个小组都有一系列要处理的问题和一组退出标准。"Code Mauve" 计划还没有结束，实际上我们希望能再持续一段时间。我们正在建立一些基础工具来度量每个团队定出来的指标（套用彼得德鲁克的话说：如果你不能度量它，你就不能管理它）。

你可能注意到过 1.1 的[补丁发布](/zh/news/)发布的非常快速。

为了尽快的让客户和用户掌握功能，过去三个月的大多数新功能被分到了 1.1.x 的版本中了。在 1.2 的版本中，这些功能正式成为发布的一部分。

我们从易用性组的早期结果看到。在发布说明中，你会发现你可以全局的给控制平面和数据平面设置日志级别了。你可以使用 [`istioctl`](/zh/docs/reference/commands/istioctl) 来验证 Kubernetes 的安装是符合 Istio 的要求的。并且新的 `traffic.sidecar.istio.io/includeInboundPorts` 注释允许服务拥有者不在 deployment yaml 文件中声明 `containerPort`。

一些功能已经成熟了。下面的一些功能已经从 Beta 状态发展了稳定状态：ingress 上的 SNI，分布式追踪和服务追踪。下面的功能已经到了 beta 状态：ingress 上的证书管理，配置资源验证，Galley 配置处理。我们知道有很多功能需求没有完成，并且我们有一个令人兴奋的路线图（请关注 TOC 即将发布的关于这个的帖子）。在这个版本中完成的一些工作是一些技术债，这些工作可以帮助我们未来可靠的推出上面这些功能。

一如既往，在[社区会议](https://github.com/istio/community#community-meeting)（周四`太平洋时间上午 11 点`）和[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)中发生了很多事情。如果你还没有加入到 [discuss.istio.io](https://discuss.istio.io) 的会议中，来吧，用你的 GitHub 证书登录进来加入我们！
