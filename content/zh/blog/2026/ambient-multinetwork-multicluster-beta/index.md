---
title: Ambient 多网络多集群支持现已进入 Beta 测试阶段
description: Istio 1.29 版本以 Beta 版的形式推出，支持 Ambient 多网络多集群，并在可观测、连接性和可靠性方面进行了改进。
date: 2026-02-18
attribution: Gustavo Meira (Microsoft), Mikhail Krinkin (Microsoft); Translated by Wilson Wu (DaoCloud) 
keywords: [ambient,multicluster]
---

在向 2026 年过渡的整个过程中，
我们的贡献者团队一直忙碌不停。
为了使 Ambient 多网络多集群功能达到生产就绪状态，
我们做了大量工作。从内部测试到 Ambient
中最常用的多网络多集群功能，
我们都进行了改进，尤其注重可观测方面的改进。

## 可观测技术的不足 {#gaps-in-telemetry}

多集群分布式系统的优势并非没有代价。随着规模的扩大，
复杂性不可避免，这使得良好的可观测功能显得尤为重要。
Istio 团队深谙此道，我们也意识到一些需要改进的地方。
值得庆幸的是，在 1.29 版本中，
当我们的 Ambient 数据平面运行于分布式集群和网络之上时，
可观测功能变得更加稳健和完善。

如果您之前在多网络场景中部署过 Alpha 多集群功能，
您可能已经注意到某些源或目标标签会显示为 "unknown"。

作为背景，在本地集群（或共享同一网络的集群）中，
waypoint 和 ztunnel 能够感知所有现有端点，
并通过 xDS 获取这些信息。然而，在多网络部署中，
由于需要在不同网络间复制的信息量巨大，
xDS 对等体发现机制变得不切实际，因此经常会出现指标混乱的情况。
不幸的是，当请求跨越网络边界访问不同的 Istio 集群时，
就会出现对等体信息缺失的情况。

## 可观测增强功能 {#telemetry-enhancements}

为了解决这个问题，Istio 1.29 在其数据平面中新增了增强的发现机制，
用于在不同网络之间的端点和网关之间交换对等元数据。
HBONE 协议现在也加入了 baggage 头部信息，
使得 waypoint 和 ztunnel 能够通过东西向网关透明地交换对等信息。

{{<
  image link="./peer-metadata-exchange-diagram.png"
  caption="图示不同网络间的对等元数据交换"
>}}

在上图中，我们重点关注 L7 指标，展示了对等元数据如何通过
baggage 头在位于不同网络中的不同集群之间流动。

1. 集群 A 中的客户端发起请求，ztunnel 开始通过 waypoint
  建立 HBONE 连接。这意味着 ztunnel 会发送一个 CONNECT 请求，
  其中包含一个 baggage 标头，该标头包含来自下游的对等元数据。
  然后，该元数据会被存储在 waypoint 中。
1. 包含元数据的 baggage 标头被移除，请求正常路由。
  在这种情况下，请求会被路由到不同的集群。
1. 在接收端，集群 B 中的 ztunnel 收到 HBONE 请求，
  并回复成功状态，附加 baggage 标头，现在包含上游对等元数据。
1. 上游对等元数据对东西向网关不可见。当响应到达路点时，
  它将拥有发布有关参与双方指标所需的所有信息。

请注意，此功能目前需要通过功能标志启用。
如果您想尝试这些可观测增强功能，
需要使用 `AMBIENT_ENABLE_BAGGAGE` 功能选项显式激活它们。

## 其他改进和修复 {#other-improvements-and-fixes}

针对连接性，我们进行了一些
[值得欢迎的改进](/zh/news/releases/1.29.x/announcing-1.29/change-notes/#traffic-management)。
入口网关和 waypoint 代理现在可以将请求直接路由到远程集群。
这为提高系统弹性奠定了基础，并支持更灵活的设计模式，
从而为 Istio 用户在多集群和多网络部署中带来他们所期望的优势。

当然，我们也进行了一些小的修复，
使多网络多集群更加稳定可靠。
我们已更新多集群文档以反映这些更改，
包括新增了关于如何为环境多网络部署设置 Kiali
的[指南](/zh/docs/ambient/install/multicluster/observability)。

## 局限性和后续步骤 {#limitations-and-next-steps}

尽管如此，我们仍然承认一些不足之处尚未完全解决。
目前的大部分工作都集中在多网络支持上。
需要注意的是，单网络部署中的多集群功能仍处于早期阶段。

此外，东西向网关在特定时间段内可能会优先处理特定端点。
这可能会影响来自不同网络的请求负载在各个端点之间的分配方式。
这种行为会影响 Ambient 数据平面模式和 Sidecar 数据平面模式，
我们计划针对这两种情况进行解决。

我们正与优秀的 Istio 社区合作，努力解决这些限制。
目前，我们很高兴推出这个测试版，并期待收到您的反馈。
Istio 多网络多集群的未来一片光明。

如果您想试用 Ambient 多网络多集群功能，
请参考[此指南](/zh/docs/ambient/install/multicluster/multi-primary_multi-network/)。
请注意，此功能目前处于测试阶段，尚未准备好用于生产环境。
我们欢迎您提交错误报告、想法、评论和使用案例。
您可以通过 [GitHub](https://github.com/istio/istio) 或
[Slack](https://istio.slack.com/) 联系我们。
