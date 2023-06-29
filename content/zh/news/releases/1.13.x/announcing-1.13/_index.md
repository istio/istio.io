---
title: 发布 Istio 1.13
linktitle: 1.13
subtitle: 重大更新
description: Istio 1.13 发布公告。
publishdate: 2022-02-11
release: 1.13.0
skip_list: true
aliases:
    - /zh/news/announcing-1.13
    - /zh/news/announcing-1.13.0
---

我们很高兴地宣布 Istio 1.13 发布！

{{< relnote >}}

这是 2022 年 Istio 的第一个版本发布。我们要感谢整个 Istio 社区为发布 Istio 1.13.0 所做出的贡献。
特别感谢发布经理 Steven Landow（Google）、Lei Tang（Google）和 Elizabeth Avelar（SAP），
以及测试与发布工作组负责人 Eric Van Norman（IBM）提供的帮助和指导。

{{< tip >}}
Istio 1.13.0 正式支持的 Kubernetes 版本为 `1.20` 至 `1.23`。
{{< /tip >}}

以下是此版本的一些亮点：

## 使用 `ProxyConfig` API 配置 Istio Sidecar 代理 {#configure-istio-sidecar-proxy-with-proxyconfig-api}

在之前的 Istio 版本中，代理级别的 Envoy 选项可以通过[网格维度配置 API](/zh/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig)进行配置。
在 1.13 中，我们将此配置提升为其开放的顶级自定义资源 `ProxyConfig`。与其他 Istio 配置 API 一样，此 CR 可以进行全局、按命名空间或按工作负载的配置。

在初始发布中，您可以通过 `ProxyConfig` CR 来配置并发性和代理映像类型。这在未来的版本中会进一步扩展。

更多信息，请查看 [`ProxyConfig` 文档](/zh/docs/reference/config/networking/proxy-config/)。

## 针对 Telemetry API 持续改进 {#continued-improvements-to-telemetry-API}

我们继续完善 Istio 1.11 中引入的新 [Telemetry API](/zh/docs/tasks/observability/telemetry/)。
在 1.13 中，我们增加了对 [`OpenTelemetry` 日志记录](https://opentelemetry.io/docs/reference/specification/logs/overview/)、
[过滤访问日志](/zh/docs/reference/config/telemetry/#AccessLogging-Filter)和自定义跟踪服务名称的支持。
同时也有大量的错误修复和改进。

## 支持基于主机名的负载均衡器用于多网络网关 {#support-hostname-based-load-balancers-for-multi-network-gateways}

迄今为止，Istio 依赖于知道在东西向配置中两个网络之间所使用的负载均衡器的 IP 地址。
但 `Amazon EKS` 负载均衡器提供的是主机名而不是 IP 地址，用户必须[手动解析此名称并设置 IP 地址](https://szabo.jp/2021/09/22/multicluster-istio-on-eks/)才能正常运行 Istio。

在 1.13 中，Istio 现在可以自动解析网关的主机名，并且可以自动发现 EKS 上从集群的网关。

## 功能更新 {#feature-updates}

[`WorkloadGroup`](/zh/docs/reference/config/networking/workload-group/) API 功能在 Istio 1.8 中首次以 Alpha 引入，在此版本中已升级为 Beta。

[授权策略试运行模式](/zh/docs/tasks/security/authorization/authz-dry-run/)也已从实验性状态升级为 Alpha。

## 升级到 Istio 1.13 {#upgrading-to-istio-1.13}

请注意，[Istio 1.13.1 将于 2 月 22 日发布](https://discuss.istio.io/t/upcoming-istio-v1-11-7-v1-12-4-and-v1-13-1-security-releases/12264)以解决各种安全漏洞。

当您进行升级时，我们希望聆听您的反馈！请花几分钟时间做一份简短的[调查问卷](https://forms.gle/pzWZpAvMVBecaQ9h9)，让我们知道自己做得怎么样。

## 与我们一起参与 IstioCon {#join-us-at-istiocon}

[IstioCon 2022](https://events.istio.io/istiocon-2022/) 定于 4 月 25 日至 29 日举行，
这是 Istio 社区的第二届年度会议。今年的会议将仍旧以线上会议的形式，
连接全球各地的社区成员与 Istio 的开发人员、合作伙伴和供应商生态系统。
请访问[会议网站](https://events.istio.io/istiocon-2022/)了解有关此活动的所有信息。

您还可以在 [Discuss Istio](https://discuss.istio.io/) 上加入对话，或加入我们的
[Slack 工作区](https://slack.istio.io/)。您想直接为 Istio 做出贡献吗？
找到并加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)，帮助我们改进。
