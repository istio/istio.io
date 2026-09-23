---
title: 发布 Istio 1.26.0
linktitle: 1.26.0
subtitle: 大版本更新
description: Istio 1.26 发布公告。
publishdate: 2025-05-08
release: 1.26.0
aliases:
    - /zh/news/announcing-1.26
    - /zh/news/announcing-1.26.0
---

我们很高兴地宣布 Istio 1.26 正式发布。感谢所有贡献者、
测试人员、用户和爱好者们帮助我们发布 1.26.0 版本！
我们还要感谢本次发布的发布经理：来自 Solo.io 的 **Daniel Hawton**、
来自爱立信软件技术公司的 **Faseela K** 以及来自微软的 **Gustavo Meira**。

{{< relnote >}}

{{< tip >}}
Istio 1.26.0 已正式支持 Kubernetes 1.29 至 1.32 版本。
我们预计 1.33 版本也能支持，并计划在 Istio 1.26.1 版本发布之前进行测试和支持。
{{< /tip >}}

## 关于 Ambient 模式下 `EnvoyFilter` 支持的说明 {#a-note-on-envoyfilter-support-in-ambient-mode}

`EnvoyFilter` 是 Istio 的应急 API，用于对 Envoy 代理进行高级配置。
请注意，**`EnvoyFilter` 目前不支持任何带有 waypoint 代理的现有 Istio 版本**。
虽然在有限的场景下可以使用带有 waypoint 的 `EnvoyFilter`，
但目前尚不支持该 API，并且维护人员也极力劝阻。随着 Alpha API 的不断发展，
未来版本中可能会出现问题。我们预计官方支持将在稍后提供。

## 新特性 {#whats-new}

### 定制 Gateway API 提供的资源 {#customization-of-resources-provisioned-by-the-gateway-api}

使用 Gateway API 创建 Gateway 或 waypoint 时，
会自动创建 `Service` 和 `Deployment`。自定义这些对象一直以来都是一个常见的需求，
现在 Istio 1.26 中通过指定包含参数的 `ConfigMap` 实现了此功能。
如果提供了 `HorizontalPodAutoscaler` 或 `PodDisruptionBudget` 的配置，
这些资源也会自动创建。
[了解更多关于自定义 Gateway API 生成资源的信息。](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)

### 新的 Gateway API 支持 {#new-gateway-api-support}

[`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/)
现已在 waypoint 中可用，允许在 Ambient 模式下转移 TCP 流量。

我们还添加了对实验性 [`BackendTLSPolicy`](https://gateway-api.sigs.k8s.io/api-types/backendtlspolicy/) 的支持，
并在 Gateway API 1.3 中开始实现
[`BackendTrafficPolicy`](https://gateway-api.sigs.k8s.io/api-types/backendtrafficpolicy/)，
最终将设置重试约束。

### 支持新的 Kubernetes `ClusterTrustBundle` {#support-for-the-new-kubernetes-clustertrustbundle}

我们添加了对 [Kubernetes 中的实验性 `ClusterTrustBundle` 资源](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/certificate-signing-requests/#cluster-trust-bundles)
的实验性支持，从而支持将证书及其信任根捆绑到单个对象中的新方法。

### 还有更多 {#plus-much-much-more}

* `istioctl analyze` 现在可以运行特定检查！
* CNI 节点代理不再默认在 `hostNetwork` 命名空间中运行，
  从而降低了与主机上运行的其他服务发生端口冲突的可能性！
* 在 GKE 上安装时，所需的 `ResourceQuota` 资源和 `cniBinDir` 值会被自动设置！
* `EnvoyFilter` 现在可以匹配域名上的 `VirtualHost`！

请参阅完整的[更新说明](change-notes/)，了解这些内容及更多信息。

## 了解 Istio 项目 {#catch-up-with-the-istio-project}

如果您只在新版本发布时才关注我们，
那么您可能错过了[我们发布了 ztunnel 安全审计](/zh/blog/2025/ztunnel-security-assessment/)、
[我们比较了环境模式吞吐量与内核运行的性能](/zh/blog/2025/ambient-performance/)，
以及[我们出席了 KubeCon EU 大会](/zh/blog/2025/istio-at-kubecon-eu/)。快来看看这些帖子吧！

## 升级到 1.26 {#upgrading-to-1-26}

我们期待您分享升级到 Istio 1.26 的体验。
您可以在我们 [Slack 工作区](https://slack.istio.io/) 的 `#release-1.26` 频道中提供反馈。

您想直接为 Istio 做出贡献吗？查找并加入我们的工作组，帮助我们改进。
