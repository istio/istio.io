---
title: 发布 Istio 1.27.0
linktitle: 1.27.0
subtitle: 大版本更新
description: Istio 1.27 发布公告。
publishdate: 2025-08-11
release: 1.27.0
aliases:
    - /zh/news/announcing-1.27
    - /zh/news/announcing-1.27.0
---

我们很高兴地宣布 Istio 1.27 正式发布。感谢所有贡献者、
测试人员、用户和爱好者们帮助我们发布 1.27.0 版本！
我们还要感谢本次发布的发布经理：来自 Tetrate 的 **Jianpeng He**、
来自爱立信软件技术公司的 **Faseela K** 以及来自微软的 **Gustavo Meira**。

{{< relnote >}}

{{< tip >}}
Istio 1.27.0 已正式支持 Kubernetes 1.29 至 1.33 版本。
{{< /tip >}}

## 新特性 {#whats-new}

### 推理扩展支持 {#inference-extension-support}

[Gateway API 推理扩展](https://gateway-api-inference-extension.sigs.k8s.io/)是一个
Kubernetes 官方项目，旨在优化 Kubernetes 上生成式 AI 模型的自托管。
它提供了一种标准化、与供应商无关的智能 AI 流量管理方法。

当使用 Gateway API 进行集群入口流量控制时，
Istio 1.27 包含该扩展的[完全兼容实现](https://gateway-api-inference-extension.sigs.k8s.io/implementations/gateways/#istio)。

[了解有关扩展和 Istio 实现的更多信息](/zh/blog/2025/inference-extension-support/)。

### Ambient 多集群 {#ambient-multicluster}

Alpha 版本现已支持在 Ambient 模式下进行多集群部署。
这使得多个 Ambient 模式集群可以连接到同一个网格，
从而将无 Sidecar 网络的范围扩展到更大、更分布式的环境。

在此初始版本中，测试主要集中在多网络、多主拓扑上，
其中每个集群运行各自的控制平面。随着基线功能的成熟，我们将逐步支持更复杂的拓扑。

### 插入式 CA 的 CRL 支持 {#crl-support-for-plugged-in-cas}

证书吊销列表 (CRL) 支持现已面向已“插入”自有 CA 而非使用 Istio 默认证书的用户开放。
这允许代理验证并拒绝已吊销的证书，从而增强使用插入 CA 的网格部署的安全性。

### ListenerSets 支持 {#listenersets-support}

新的 [ListenerSets](https://gateway-api.sigs.k8s.io/geps/gep-1713) API
允许您定义一组可重用的监听器，并将其附加到 `Gateway` 资源。
这在管理共享通用监听器配置的多个网关时，可以提高一致性并减少重复。

### Sidecar 模式下的原生 nftables 支持 {#native-nftables-support-in-sidecar-mode}

Istio 现在支持 Sidecar 模式下的[原生 nftables](https://github.com/istio/istio/issues/47821) 后端。
nftables 是 iptables 的现代继承者，它提供了更好的性能、
改进的可维护性和更灵活的规则管理，可实现往返于 Envoy Sidecar 代理的透明流量重定向。

许多主流 Linux 发行版都采用 nftables 作为默认的数据包过滤框架，
而 Istio 的原生支持确保了与这种转变的兼容性。

Ambient 模式下对 nftables 的支持正在积极开发中，并将在未来版本中推出。

## 升级到 1.27 {#upgrading-to-1-27}

我们期待您分享升级到 Istio 1.27 的体验。
您可以在我们 [Slack 工作区](https://slack.istio.io/) 的 `#release-1.27` 频道中提供反馈。

您想直接为 Istio 做出贡献吗？
查找并加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)，帮助我们改进。
