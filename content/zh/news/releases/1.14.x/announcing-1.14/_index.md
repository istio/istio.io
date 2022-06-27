---
title: Istio 1.14 公告
linktitle: 1.14
subtitle: 主要更新
description: Istio 1.14 发布公告。
publishdate: 2022-06-01
release: 1.14.0
skip_list: true
aliases:
- /zh/news/announcing-1.14
- /zh/news/announcing-1.14.0
---

我们很高兴地宣布发布 Istio 1.14！

{{< relnote >}}

这是 2022 年的第二个 Istio 版本。我们要感谢整个 Istio 社区对 Istio 1.14.0 发布的帮助。
特别感谢发布经理 Lei Tang（Google）和 Greg Hanson（Solo.io）
以及 Test 和 Release WG 负责人 Eric Van Norman（IBM）的持续帮助和指导。

{{< tip >}}
Istio 1.14.0 is officially supported on Kubernetes versions `1.21` to `1.24`.
{{< /tip >}}

以下是该版本的一些亮点：

## 支持 SPIRE 运行时{#support-for-the-spire-runtime}

SPIRE 是 SPIFFE 安全生产框架规范的生产就绪实现，
提供可插拔的多因素认证和 SPIFFE 下的不同软件系统之间的信任联邦。
我们已经改变了 Istio 与外部证书颁发机构相集成的方式，使用 Envoy SDS API 来支持 SPIRE。
感谢 HP Enterprise 团队对这项工作的贡献！

SPIRE 通过组合使用不同的认证机制，支持引入经过强认证的身份。
它为运行在 Kubernetes，AWS，GCP，Azure，Docker 中
运行的工作负载提供了开箱即用的各种节点和工作负载验证器，
并且通过面向插件的架构，它还支持使用自定义验证器。
该项目与用于存储 CA 私钥的自定义密钥管理系统进行了可插拔集成，并通过上游证书颁发机构插件实现与现有 PKI 的集成。
SPIRE 实现了 SPIFFE 身份验证体系的联邦，使工作负载能够通过 Federation API 以一种可配置和灵活的方式信任不同信任域中的对等方。

要了解更多信息，请查看 HP Enterprise 和 Solo.io 团队的[文档](/zh/docs/ops/integrations/spire/)和[视频](https://www.youtube.com/watch?v=WOPoNqfrhb4)。

## 添加 auto-sni 支持{#add-auto-sni-support}

有些服务器要求在请求中包含 SNI。
此新功能可自动配置 SNI，无需用户手动配置或使用 `EnvoyFilter` 资源。
有关更多信息，请查看[拉取请求 38604](https://github.com/istio/istio/pull/38604)
 和[拉取请求 38238](https://github.com/istio/istio/pull/38238)。

## 添加对为 Istio 工作负载配置 TLS 版本的支持{#add-support-for-configuring-the-tls-version-for-Istio-workloads}

TLS 版本对安全性有重要影响。这个功能增加了对 Istio 工作负载配置最小 TLS 版本的支持。要了解更多信息，请查看 TLS [文档](/zh/docs/tasks/security/tls-configuration/workload-min-tls-version/)。

## Telemetry 的改进{#telemetry-improvements}

[Telemetry API](/zh/docs/tasks/observability/telemetry/) 经历了许多的改进，包括支持 OpenTelemetry 访问日志
记录、基于 `WorkloadMode` 的过滤等。

## 升级到 1.14{#upgrading-to-1.14}

当您升级时，我们希望听到您的声音！请花几分钟时间回答一个简短的[调查](https://forms.gle/yEtCbt45FZ3VoDT5A)，让我们知道我们的工作情况。

您也可以加入 [Discuss Istio](https://discuss.istio.io/) 的对话，或加入我们的 [Slack 工作区](https://slack.istio.io/)。
你愿意直接向 Istio 投稿吗？查找并加入我们的 [Working Groups](https://github.com/istio/community/blob/master/WORKING-GROUPS.md) 之一，帮助我们改进。

## IstioCon 总结{#istiocon-wrap-up}

IstioCon 2022 是该项目大会的第二届会议，于 4 月 25 日至 29 日举行。
我们有近 4000 名注册参与者，满意度为 4.5/5。
会议以中英文两种语言举行，来自全球 120 个国家的参会者参会。
在 2022 年 4 月的会议当月，istio.io 上 81% 的用户是新用户。
我们将在 [events.istio.io](https://events.istio.io) 上分享更详细的活动报告。

## CNCF 新闻{#cncf-news}

我们对 [Istio 被提议加入 CNCF](/zh/blog/2022/istio-has-applied-to-join-the-cncf/) 公告的回应感到非常高兴。
我们正在努力开发我们的应用程序，希望在接下来的几个月里有更多的分享!
