---
title: 发布 Istio 1.25.0
linktitle: 1.25.0
subtitle: 大版本更新
description: Istio 1.25 发布公告。
publishdate: 2025-03-03
release: 1.25.0
aliases:
- /zh/news/announcing-1.25
- /zh/news/announcing-1.25.0
---

我们很高兴地宣布 Istio 1.25 正式发布。感谢所有贡献者、
测试人员、用户和爱好者帮助我们发布 1.25.0 版本！
我们要感谢本次发布的发布经理，包括微软的 **Mike Morris**、爱立信软件的 **Faseela K** 以及 Solo.io 的 **Daniel Hawton**。

{{< relnote >}}

{{< tip >}}
Istio 1.25.0 正式支持 Kubernetes 版本 `1.29` 至 `1.32`。
{{< /tip >}}

## 新特性 {#whats-new}

### Ambient 模式下默认开启 DNS 代理 {#dns-proxying-on-by-default-for-ambient-mode}

Istio 通常会根据 HTTP 标头路由流量。在 Ambient 模式下，
ztunnel 只能看到四层的流量，无法访问 HTTP 标头。因此，
需要 DNS 代理来启用 `ServiceEntry` 地址的解析，
尤其是在[将出口流量发送到 waypoint](https://github.com/istio/istio/wiki/Troubleshooting-Istio-Ambient#scenario-ztunnel-is-not-sending-egress-traffic-to-waypoints) 的情况下。

为了在默认情况下简化此操作，在 Istio 1.25 的 Ambient 模式安装中默认启用 DNS 代理。
已添加注解以允许工作负载选择退出 DNS 代理。
查看[升级说明](/zh/news/releases/1.25.x/announcing-1.25/upgrade-notes#ambient-mode-dns-capture-on-by-default)了解更多信息。

### 适用于 waypoint 的默认拒绝策略 {#default-deny-policy-available-for-waypoints}

在 Sidecar 模式下，授权策略通过选择器附加到工作负载。
在 Ambient 模式下，选择器所针对的策略仅由 ztunnel 强制执行。
waypoint 代理通过使用 Gateway API 样式的 `targetRef` 字段进行绑定。
这导致了一种潜在的配置，其中工作负载默认被拒绝与端点通信，
但可以通过连接到允许与该端点通信的 waypoint **来绕过**该配置，从而无论如何都能到达该端点。

在此版本中，我们添加了将策略定位到已命名的 `GatewayClass` 以及已命名的 `Gateway` 的功能。
这允许您在 `istio-waypoint` 类上设置策略，该策略适用于 waypoint 的所有实例。

### 区域路由增强 {#zonal-routing-enhancements}

无论是出于可靠性、性能还是成本原因，控制跨区域和跨地区流量通常都是用户的重要“后续”操作。
借助 Istio 1.25，这变得更加容易！

[Kubernetes 的流量分配](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#%E6%B5%81%E9%87%8F%E5%88%86%E5%8F%91)功能现已被完全支持，
提供简化的界面以保持流量本地化。现有的 Istio [本地负载均衡](/zh/docs/tasks/traffic-management/locality-load-balancing/) 设置仍然可用于更复杂的用例。

在 Ambient 模式下，ztunnel 现在将向所有指标报告附加的
`source_zone`、`source_region`、`destination_zone` 和`destination_region` 标签，从而清晰地查看跨区域流量。

### 其他新功能 {#other-new-features}

- 我们添加了提供虚拟接口列表的功能，这些虚拟接口的入站流量将无条件视为出站流量。
  这允许使用虚拟网络（KubeVirt、VM、docker-in-docker 等）的工作负载在 Sidecar 和 Ambient 模式流量捕获中正常运行。
- `istio-cni` DaemonSet 现在可以在活动集群中安全地就地升级，
  而无需节点警戒线来防止升级过程中生成的 Pod 逃脱 Ambient 流量捕获。

请参阅[完整变更说明](/zh/news/releases/1.25.x/announcing-1.25/change-notes/)以了解所有其他新内容。

## 升级到 1.25 {#upgrading-to-1-25}

我们希望听取您关于升级到 Istio 1.25 的体验。
您可以在我们的 [Slack 工作区](https://slack.istio.io/)中的
`#release-1.25` 频道中提供反馈。

您想直接为 Istio 做出贡献吗？
查找并加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一，
帮助我们改进。

如果您参加 2025 年欧洲 KubeCon 大会，请务必前往同期举办的 [Istio Day](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/co-located-events/istio-day/) 聆听精彩演讲，
或前往 [Istio 项目展位](https://events.linuxfoundation.org/kubecon-cloudnativecon-europe/features-add-ons/project-engagement/#project-kiosk-directory/)进行交流。
