---
title: Announcing Istio 1.18.0
linktitle: 1.18.0
subtitle: 大版本更新
description: Istio 1.18 发布公告。
publishdate: 2023-06-07
release: 1.18.0
aliases:
    - /zh/news/announcing-1.18
    - /zh/news/announcing-1.18.0
---

我们很高兴地宣布 Istio 1.18 发布。这是 2023 年的第二个 Istio
版本，也是第一个带有 Ambient 模式的版本！我们要感谢整个 Istio
社区对 1.18.0 版本发布所作出的帮助。我们要感谢此版本的几位发布经理：
来自 Tetrate 的 `Paul Merrison`、来自 Microsoft 的 `Kalya Subramanian`
和来自 DaoCloud 的 `Xiaopeng Han`。这些发布经理们要特别感谢测试和发布工作组负责人
Eric Van Norman (IBM) 在整个发布周期中提供的帮助和指导。我们还要感谢 Istio
工作组的维护者以及广大 Istio 社区，在发布过程中提供及时反馈、
审核和社区测试，以及在确保及时发布方面给予的全力支持。

{{< relnote >}}

{{< tip >}}
Istio 1.18.0 已得到 Kubernetes `1.24` 到 `1.27` 的官方正式支持。
{{< /tip >}}

## 新特性 {#what-is-new}

### Ambient Mesh

Istio 1.18 标志着 Ambient Mesh 的首次发布，这是一种全新的 Istio 数据平面模式，
旨在简化操作、更广泛的应用程序兼容性并降低基础设施成本。有关详细信息，
请参阅[官宣博文](/zh/blog/2022/introducing-ambient-mesh/)。

### Gateway API 支持改进 {#gateway-api-support-improvements}

Istio 1.18 改进了对 Kubernetes Gateway API 的支持，
包括对额外 v1beta1 资源的支持以及对自动化部署逻辑的增强，
不再依赖于 Pod 注入。Istio 上的 Gateway API
用户应查看此版本的升级说明以获取有关升级的重要指导。

### 并发性设置的改变 {#proxy-concurrency-changes}

以前，代理 `concurrency` 设置（用于配置代理运行的工作线程数量）在
Sidecar 和不同的网关机制之间存在不一致的配置。
在 Istio 1.18 中，这种设置被调整，以保持在不同部署类型之间的一致性。
有关此更改的更多详细信息，请参阅此版本的升级说明。

### Istioctl 的增强 {#enhancements-to-the-istioctl-command}

为 istioctl 命令添加了一些增强功能，包括对错误报告过程的增强功能和对
istioctl analyze 命令的各种改进。

## 升级至 1.18 {#upgrading-to-1.18}

我们期待倾听您关于升级到 Istio 1.18 的体验。
您可以加入 [Discuss Istio](https://discuss.istio.io/) 的会话中提供反馈，
或加入我们的 [Slack 工作空间](https://slack.istio.io/)中的 #release-1.18 频道。

您想直接为 Istio 做贡献吗？
找到并加入我们的某个[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)，
帮助我们改进。
