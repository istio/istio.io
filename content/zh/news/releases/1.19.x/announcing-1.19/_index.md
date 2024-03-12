---
title: 发布 Istio 1.19.0
linktitle: 1.19.0
subtitle: 大版本更新
description: Istio 1.19 发布公告。
publishdate: 2023-09-05
release: 1.19.0
aliases:
    - /zh/news/announcing-1.19
    - /zh/news/announcing-1.19.0
---

我们很高兴地宣布 Istio 1.19 发布。这是 2023 年的第三个 Istio 版本，
我们要感谢整个 Istio 社区对 1.19.0 版本发布所作出的帮助。
我们要感谢此版本的几位发布经理：来自 Microsoft 的 `Kalya Subramanian`、
来自 DaoCloud 的 `Xiaopeng Han` 和来自 Google 的 `Aryan Gupta`。
这些发布经理们要特别感谢测试和发布工作组负责人 Eric Van Norman (IBM) 在整个发布周期中提供的帮助和指导。
我们还要感谢 Istio 工作组的维护者以及广大 Istio 社区，在发布过程中提供及时反馈、
审核和社区测试，以及在确保及时发布方面给予的全力支持。

{{< relnote >}}

{{< tip >}}
Istio 1.19.0 已得到 Kubernetes `1.25` 到 `1.28` 的官方正式支持。
{{< /tip >}}

## 新特性 {#what-is-new}

### Gateway API

Kubernetes [Gateway API](http://gateway-api.org/)
是一项旨在为 Kubernetes 带来丰富的服务网络 API
（类似于 Istio VirtualService 和 Gateway）的举措。

随着 Gateway API v0.8.0 的发布，
正式添加了[对服务网格的支持](https://gateway-api.sigs.k8s.io/blog/2023/0829-mesh-support/)！
这项进展是与更广泛的 Kubernetes 生态社区共同努力的结果，并且包含 Istio 在内的多个合规性实现。

查看[网格文档](/zh/docs/tasks/traffic-management/ingress/gateway-api/#mesh-traffic)以开始使用。
与任何实验性功能一样，我们非常感谢反馈。

除了网格流量之外，入口流量的 API
使用[处于 Beta 阶段](/zh/docs/tasks/traffic-management/ingress/gateway-api/#configuring-a-gateway)并迅速接近 GA。

### Ambient Mesh

在此发布周期中，团队一直在努力改进 [Ambient 网格](/zh/docs/ops/ambient/)，
这是替代之前 Sidecar 模型的新 Istio 部署模型。如果您还没有听说过 Ambient，
请查看[介绍博客文章](/zh/blog/2022/introducing-ambient-mesh/)。

在此版本中，添加了对 `ServiceEntry`、`WorkloadEntry`、`PeerAuthentication`
和 DNS 代理的支持。此外，还修复了许多错误并提高了可靠性。

请注意，在此版本中，Ambient 网格仍处于 Alpha 功能阶段。
您的反馈对于推动 Ambient 进入 Beta 版至关重要，因此请尝试一下并告诉我们您的想法！

### 其他改进 {#additional-improvements}

为了进一步简化 `Virtual Machine` 和 `Multicluster` 体验，
`WorkloadEntry` 资源中的地址字段现在是可选的。

我们还增强了安全配置。例如，您可以为 Istio 入口网关的 TLS 设置配置 `OPTIONAL_MUTUAL`，
这允许选择性使用和验证客户端证书。此外，您还可以通过
`MeshConfig` 配置用于非 Istio mTLS 流量的首选密码套件。

## 升级至 1.19 {#upgrading-to-1.19}

我们期待倾听您关于升级到 Istio 1.19 的体验。
您可以加入 [Discuss Istio](https://discuss.istio.io/) 的会话中提供反馈，
或加入我们的 [Slack 工作空间](https://slack.istio.io/)中的 #release-1.19 频道。

您想直接为 Istio 做贡献吗？
找到并加入我们的某个[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)，
帮助我们改进。
