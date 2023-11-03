---
title: 发布 Istio 1.16
linktitle: 1.16
subtitle: Major Update
description: Istio 1.16 发布公告。
publishdate: 2022-11-15
release: 1.16.0
skip_list: true
aliases:
- /zh/news/announcing-1.16
- /zh/news/announcing-1.16.0
---

我们很高兴地宣布发布 Istio 1.16！

{{< relnote >}}

这是 2022 年发布的第四个 Istio 版本，
我们要感谢整个 Istio 社区帮助发布 Istio 1.16.0。
我们特别感谢来自 Solo.io 的发布经理 Daniel Hawton、
来自 Intel 的 Ziyang Xiao 和来自 IBM 的 Tong Li。
同样，我们还要感谢测试和发布工作组负责人
Eric Van Norman（IBM）的帮助和指导。

{{< tip >}}
Istio 1.16.0 正式支持了 Kubernetes `1.22` 到 `1.25` 的所有版本。
{{< /tip >}}

## 版本新特性{#whats-new}

以下是该版本的一些亮点：

### 外部鉴权功能升级为 Beta 版{#external-authorization-promoted-to-beta}

Istio 的外部鉴权功能已升级为 Beta 版。有关详细信息，
请参阅[外部鉴权](/zh/docs/tasks/security/authorization/authz-custom/)文档。

### Kubernetes Gateway API 实现升级为 Beta 版{#kubernetes-gateway-api-implementation-promoted-to-beta}

Istio 对 [Gateway API](https://gateway-api.sigs.k8s.io/)
的实现已升级为 Beta 版。
这是朝着使 Gateway API 成为流量管理的默认 API
[未来](/zh/blog/2022/gateway-api-beta/)的目标迈出的重要一步。

随着 Beta 版本的升级，我们增强了所有
[Ingress 任务](/zh/docs/tasks/traffic-management/ingress/)包括使用
Gateway API 或 Istio 配置 API 进行 Ingress 的设置。
此外，尽管使用 Gateway API
更普遍地配置内部网格流量仍然是一项[实验性功能](https://gateway-api.sigs.k8s.io/concepts/versioning/#release-channels-eg-experimental-standard)，
[上游协议](https://gateway-api.sigs.k8s.io/contributing/gamma/)功能也处于待定状态，
但是其他几个 Istio 文档已使用 Gateway API
说明进行更新，以允许早期实验。
有关详细信息，请参阅
[Gateway API 任务](/zh/docs/tasks/traffic-management/ingress/gateway-api/)。

### JWT Claim Based Routing 功能升级为 Alpha 版{#jwt-claim-based-routing-promoted-to-alpha}

Istio 的 JWT Claim Based Routing 功能已升级为 Alpha 版。
有关详细信息，请参阅
[JWT Claim Based Routing](/zh/docs/tasks/security/authentication/jwt-route/) 文档。

### 针对 Sidecar 和 Ingress 的 HBONE 协议支持（实验性）{#hbone-for-sidecars-and-ingress-experimental}

我们为 Sidecar 和 Ingress 网关添加了对 HBONE 协议的支持。
有关详细信息，请参阅
[PR #41391](https://github.com/istio/istio/pull/41391)。

### 支持 MAGLEV 负载均衡算法{#maglev-load-balancing-support}

我们添加了对 MAGLEV 负载均衡算法的支持。
有关详细信息，请参阅
[Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/load_balancers#maglev)。

### 添加了 OpenTelemetry 链路追踪提供程序的支持{#added-openTelemetry-tracing-provider-support}

我们通过 Telemetry API 添加了对 OpenTelemetry 链路追踪提供程序的支持。

## 升级到 Istio 1.16{#upgrading-to-1.16}

当您升级时，我们希望收到您的来信！
请花几分钟时间回复一份简短的[问卷](https://forms.gle/99uiMML96AmsXY5d6)，
以便让我们知道我们的工作情况。

您还可以加入 [Discuss Istio](https://discuss.istio.io/)的对话，
或加入我们的 [Slack 工作区](https://slack.istio.io/)。
您想直接为 Istio 做出贡献吗？
您可以查找并加入我们其中任意一个[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)以帮助我们改进 Istio。
