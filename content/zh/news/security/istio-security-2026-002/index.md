---
title: ISTIO-SECURITY-2026-002
subtitle: 安全公告
description: 通过 VirtualService 进行中间人攻击。
cves: []
cvss: "5.9"
vector: "AV:N/AC:L/PR:H/UI:R/S:C/C:L/I:L/A:L"
releases: ["自 `VirtualService` 资源中引入网格网关选项以来的所有版本"]
publishdate: 2026-03-21
skip_seealso: true
---

{{< security_bulletin >}}

Istio 安全委员会希望解决一种潜在的中间人攻击场景，即 `VirtualService`
可以重定向或拦截服务网格内的流量。该攻击仅影响基于命名空间的多租户环境。

此攻击允许拥有某个命名空间中 `VirtualService` 权限的攻击者将 Istio
服务网格中任何 Pod 的流量重定向到攻击者控制的服务。该攻击场景利用了在设置了 `mesh` 网关时，
可以在 `VirtualService` 资源的 `spec.hosts.[]` 字段中设置任意主机名的功能。
攻击者可以拦截、重定向并丢弃服务之间的通信流量。这会影响到网格中其他服务以及外部服务的流量。
但是，攻击者无法绕过目标服务上配置的[授权策略](/zh/docs/reference/config/security/authorization-policy/)或相互 TLS 身份验证。

请注意，即使在[**"具有多个集群的单个网格"**部署](/zh/docs/ops/deployment/deployment-models/#multiple-clusters)中，
这些问题也会超出集群范围。

Istio 维护者认为这是 Istio 的预期行为。他们的一些资源，例如 `VirtualService`、`DestinationRule` 和 `ServiceEntry`，
会修改网格中特定主机名的流量。尽管这些资源使用了命名空间，但它们仍然会影响网格（在给定集群内）的流量模式。
这是为了避免为每个主机名和命名空间进行繁琐的管理控制而有意做出的用户体验权衡。
与较新的 [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) 不同，
这些 CRD 是在基于命名空间的 RBAC 引入 Kubernetes 之前创建并稳定下来的，因此任何更改都会破坏现有功能。

因此，在基于命名空间的多租户架构中运行 Istio 或在多个集群上运行单个网格的运维人员应采取额外的安全措施来维持强大的隔离性。
如果没有这些控制措施，数据平面层面可能会发生意外的跨命名空间流量篡改。

建议的缓解措施是在这些配置中迁移到更新的 Gateway API。如果在旧配置中无法进行此类更改和限制，
则应[应用进一步的强化和限制](/zh/blog/2026/security-considerations-on-namespace-based-multi-tenancy/#mitigation-and-best-practices)以减少这些弱点的影响。

有关此问题和缓解措施的更多详细信息，
请参阅[博客文章](/zh/blog/2026/security-considerations-on-namespace-based-multi-tenancy/)。

Istio 安全委员会感谢 ERNW Enno Rey Netzwerke GmbH 的 Sven Nobis 和 Lorin Lehawany 披露了这个问题。
