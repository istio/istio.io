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
* 在 waypoint 和 ztunnel 的 DNS 中支持 `ServiceEntries`。
* 支持跨命名空间共享 waypoint。
* 支持新的 `Service` 中的 `trafficDistribution` 字段，允许将流量保持在本地区域/地区。
* 支持双栈和 IPv6 集群。
* 用于 ztunnel 的新 Grafana 仪表板。
* 单个 Helm Chart 用于一次性安装所有 Ambient 模式组件。
* 性能改进：我们的测试表明，与 Istio 1.22 相比，吞吐量提高了 50%。
* 修复了大量错误：改进了 Pod 启动、支持没有选择器的服务、改进了日志记录等等！

### DNS 自动分配改进 {#dns-auto-allocation-improvements}

多年来，Istio 一直有一个[地址分配选项](/zh/docs/ops/configuration/traffic-management/dns-proxy/#address-auto-allocation)用于 DNS 代理模式。
这解决了服务路由的许多问题。

在 Istio 1.23 中，添加了此功能的新实现。在新方法中，
被分配的 IP 地址将保留在 `ServiceEntry` `status` 字段中，
确保它们永远不会被更改。这解决了旧方法中长期存在的可靠性问题，
即分配偶尔会发生混乱并导致问题。此外，这种方法更标准、更易于调试，并使该功能适用​​于 Ambient 模式！

此模式在 1.23 中默认关闭，但可以使用 `PILOT_ENABLE_IP_AUTOALLOCATE=true` 启用。

### 重试功能的改进预览 {#retry-improvements-preview}

在此版本中，我们实现了一项新功能预览，以增强默认重试策略。
从历史上看，重试仅针对**出站**流量进行。在许多情况下，这就是您想要的：
可以将请求重试到其他 Pod，这更有可能成功。然而，这留下了一个漏洞：通常，
请求会失败，仅仅是因为应用程序关闭了我们保持活动状态并尝试重新使用的连接。

我们添加了检测这种情况的功能，并重试。这有望减少网格中常见的 503 错误源。

可以使用 `ENABLE_INBOUND_RETRY_POLICY=true` 启用此功能。预计在未来版本中它将默认启用。

### 粉饰一新的 Bookinfo {#a-coat-of-paint-for-bookinfo}

1.23 中的改进不仅限于 Istio 本身：在此版本中，大家最喜欢的示例应用程序 Bookinfo 也得到了改版！

新的应用程序具有更现代化的设计和性能改进，解决了 `productpage` 和 `details` 服务中一些意外的缓慢问题。

{{< image width="80%" link="/zh/docs/setup/getting-started/bookinfo-browser.png" caption="改进后的 Bookinfo 应用程序" >}}

### 其他亮点 {#other-highlights}

* distroless 镜像已升级为使用 [Wolfi](https://github.com/wolfi-dev) 容器基础操作系统。
* `istioctl proxy-status` 命令已改进，包括自上次更改以来的时间以及更多相关状态值。

## 弃用集群内 Operator {#deprecating-the-in-cluster-operator}

三年前，我们[更新了我们的文档](/zh/docs/setup/install/operator/)，
以阻止在新的 Istio 安装中使用集群内运算符。现在，我们准备在 Istio 1.23 中正式将其标记为弃用。
利用该运算符的用户（我们估计不到我们用户群的 10%）将需要迁移到其他安装和升级机制才能升级到
Istio 1.24 或更高版本。1.24 的预计发布日期是 2024 年 11 月。

我们建议用户迁移到 Helm 和 istioctl，它们仍受 Istio 项目支持。
迁移到 istioctl 很简单；迁移到 Helm 需要工具，我们将与 1.24 版本一起发布。

希望坚持使用 Operator 模式的用户在
[istio-ecosystem](https://github.com/istio-ecosystem/) 组织中有两个第三方选项。

有关此变更的更多详细信息，
请查看[我们的弃用公告博客文章](/zh/blog/2024/in-cluster-operator-deprecation-announcement/)。

## 升级到 1.23 {#upgrading-to-1-23}

我们希望听取您关于升级到 Istio 1.23 的体验。
您可以在我们的 [Slack 工作区](https://slack.istio.io/)中的 `#release-1.23` 频道中提供反馈。

您想直接为 Istio 做出贡献吗？
查找并加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一，帮助我们改进。
