---
title: 发布 Istio 1.28.0
linktitle: 1.28.0
subtitle: 大版本更新
description: Istio 1.28 发布公告。
publishdate: 2025-11-05
release: 1.28.0
aliases:
    - /zh/news/announcing-1.28
    - /zh/news/announcing-1.28.0
---

我们很高兴地宣布 Istio 1.28 正式发布。感谢所有贡献者、
测试人员、用户和爱好者们帮助我们发布 1.28.0 版本！
我们还要感谢本次发布的发布经理：来自微软的 **Gustavo Meira**、
来自红帽的 **Francisco Herrera** 以及来自微软的 **Darrin Cecil**。

{{< relnote >}}

{{< tip >}}
Istio 1.28.0 已正式支持 Kubernetes 1.29 至 1.34 版本。
{{< /tip >}}

## 新特性 {#whats-new}

### 推理扩展支持 {#inference-extension-support}

Istio 1.28 通过引入 `InferencePool` v1 继续增强对 Gateway API 推理扩展的支持。
此增强功能可更好地管理和路由 AI 推理工作负载，
从而更容易在 Kubernetes 上部署和扩展生成式 AI 模型，并实现智能流量管理。

`InferencePool` v1 API 为管理推理端点池提供了更高的稳定性和功能，
从而能够为 AI 工作负载实现更复杂的负载均衡和故障转移策略。

### Ambient 多集群 {#ambient-multicluster}

Istio 1.28 为 Ambient 多集群部署带来了显著改进。现在，在环境多集群配置中，
waypoint 可以将流量路由到远程网络，从而扩展了环境功能。
此增强功能支持异常值检测和其他跨网络请求的 L7 策略，使管理多网络服务网格部署更加便捷。

Ambient 多集群功能仍处于 Alpha 测试阶段，存在一些已知问题，
这些问题将在未来的版本中得到解决。如果最近的更改对您的 Ambient 多集群部署产生了负面影响，
可以通过将 `AMBIENT_ENABLE_MULTI_NETWORK_WAYPOINT` 试点环境变量设置为 `false` 来禁用最近的航点行为更改。

我们欢迎 Ambient 多集群的早期用户提供反馈和错误报告。

### Ambient 模式下的原生 nftables 支持 {#native-nftables-support-in-ambient-mode}

Istio 1.28 版本在 Ambient 模式下引入了对原生 nftables 的支持。
这项重大改进允许您使用 nftables 而非 iptables 来管理网络规则，
从而提供更灵活的规则管理方式。要启用 nftables 模式，
请在安装 Istio 时使用 `--set values.global.nativeNftables=true` 参数。

这项新增功能完善了 Sidecar 模式下现有的 nftables 支持，
确保 Istio 与现代 Linux 网络框架保持同步。

### 双栈支持升级至 Beta 版 {#dual-stack-support-promoted-to-beta}

在此版本中，Istio 的双栈网络支持已升级为 Beta 版。
此项改进提供了强大的 IPv4/IPv6 网络功能，
使企业能够在需要同时使用两种 IP 协议版本的现代网络环境中部署 Istio。

### 增强安全功能 {#enhanced-security-features}

此版本包含多项重要的安全改进：

- **增强的 JWT 身份验证**：改进的 JWT 过滤器配置现在除了支持“scope”和“permission”等默认声明外，
  还支持自定义的空格分隔声明。此增强功能确保使用 `RequestAuthentication`
  资源中的 `spaceDelimitedClaims` 字段正确验证带有自定义声明的 JWT 令牌。
- **`NetworkPolicy` 支持**：为 istiod 提供可选的 `NetworkPolicy` 部署，
  并启用 `global.networkPolicy.enabled=true`。
- **增强容器安全性**：支持在 istio-validation 和 istio-proxy 容器中配置
  `seccompProfile`，以提高安全合规性。
- **Gateway API 安全性**：支持 `FrontendTLSValidation` (GEP-91)，
  实现双向 TLS 入口网关配置
- **改进的证书处理**：优化了根证书解析，能够过滤掉格式错误的证书，而不是直接拒绝整个证书包。

### Gateway API 和流量管理增强功能 {#gateway-api-and-traffic-management-enhancements}

- **`BackendTLSPolicy` v1**：全面支持 Gateway API v1.4，并增强了 TLS 配置选项
- **`ServiceEntry` 集成**：支持将 `ServiceEntry` 作为 `BackendTLSPolicy`
  中的 `targetRef`，用于外部服务的 TLS 配置
- **通配符主机支持**：`ServiceEntry` 资源现在支持使用 `DYNAMIC_DNS`
  解析的通配符主机（仅限 HTTP 流量，需要环境模式和路径点）

### 还有更多精彩内容 {#plus-much-more}

- **基于角色的安装**：Helm Chart 中新增 `resourceScope` 选项，
  用于命名空间或集群范围的资源管理
- **改进的负载均衡**：在一致性哈希负载均衡中支持 Cookie 属性，
  并提供 `SameSite`、`Secure` 和 `HttpOnly` 等安全选项
- **增强的遥测功能**：支持 B3/W3C 双标头传播，以提高追踪互操作性
- **istioctl 改进**：自动检测默认版本并增强调试功能

请参阅完整的[发行说明](change-notes/)了解这些内容及更多信息。

## 升级到 1.28 {#upgrading-to-1-28}

我们期待您分享升级到 Istio 1.28 的体验。
您可以在我们 [Slack 工作区](https://slack.istio.io/) 的 `#release-1.28` 频道中提供反馈。

您想直接为 Istio 做出贡献吗？
查找并加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)，帮助我们改进。
