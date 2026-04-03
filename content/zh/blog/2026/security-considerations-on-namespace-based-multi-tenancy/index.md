---
title: "基于命名空间的多租户 Istio CRD 的安全注意事项"
description: 解决基于命名空间的多租户架构中的中间人攻击弱点。
publishdate: 2026-03-21
attribution: "Lorin Lehawany - ERNW, Sven Nobis - ERNW; Translated by Wilson Wu (DaoCloud)"
keywords: [Istio,Security,Multi-Tenancy,MITM,Man-in-the-Middle]
---

Istio 项目旨在解决一种可能的中间人（MITM）攻击场景，
即 `VirtualService` 可以重定向或拦截服务网格内的流量。
这会影响基于命名空间的多租户集群，其中租户拥有部署 Istio
资源的权限 (``networking.istio.io/v1``)。

这篇博文重点介绍了在多租户集群中使用 Istio 的风险，
并解释了用户如何降低这些风险并在其部署中安全地运行 Istio。

请注意，即使在 [**"具有多个集群的单个网格"**部署](/zh/docs/ops/deployment/deployment-models/#multiple-clusters)中，
这些问题也会超出集群范围。

本文描述的行为适用于 Istio 版本 1.29.0 以及自
`VirtualService` 资源中引入网格网关选项以来的所有版本。

## 背景 {#background}

### 基于命名空间的多租户 {#namespace-based-multi-tenancy}

Kubernetes 中的命名空间提供了一种机制，用于组织集群内的资源组。
命名空间提供了一种逻辑抽象，允许团队、应用程序或环境共享单个集群，
同时通过网络策略、基于角色的访问控制（RBAC）等控制措施来隔离各自的资源。

在这篇博文中，我们重点介绍如何在集群中运行 Istio，其中多个租户共享同一个集群和服务网格，
并且可以在各自的命名空间中部署 Istio 资源（``networking.istio.io/v1``），同时依靠命名空间边界进行隔离。

### Istio 中的流量路由 {#traffic-routing-in-istio}

Istio 通过将应用逻辑与网络路由行为分离，提供流量管理功能。
它通过 CRD 引入额外的配置资源，允许运维人员定义网格中服务之间的流量路由方式。

为此，`VirtualService` 是核心资源之一。`VirtualService` 定义了一组路由规则，
用于决定如何处理对 `spec.hosts.[]` 中指定的主机的请求。
这些规则可以根据 HTTP 标头、路径或端口等属性匹配请求，然后将流量定向到一个或多个目标服务。

在 `VirtualService` 中定义的路由决策并不局限于单个工作负载或命名空间。
根据资源的配置方式，这些规则可以影响整个网格中的流量路由。

与较新的 [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) 不同，
这些 CRD 是在基于命名空间的 RBAC 引入 Kubernetes 之前创建并有效稳定下来的。
因此，共享同一服务网格的基于命名空间的多租户架构在当时的威胁模型中并不包含。
随着 RBAC 的引入，此类多租户环境应运而生。因此，强调并解决与这些架构相关的安全风险至关重要。

在接下来的章节中，我们将展示这些风险，并说明这种机制可能被滥用以拦截基于命名空间的多租户集群中的流量。
随后，我们将介绍缓解这些风险的方法。

## 通过 VirtualService 进行中间人攻击 {#man-in-the-middle-attacks-through-virtualservice}

在基于命名空间的多租户环境中，通常假设命名空间能够为不同命名空间之间的资源提供足够的信任边界。
然而，Istio 的流量路由配置是在网格级别运行的，这意味着在一个命名空间中定义的路由规则会影响来自其他命名空间工作负载的流量。

拥有创建或修改 `VirtualService` 资源权限的攻击者可以利用此行为，
为任意主机定义路由规则。当在规范的 `gateways` 部分设置服务网格参数 ``mesh`` 时，
路由规则将应用于网格中的所有 Sidecar 代理（无论其命名空间如何）。

这使得攻击者能够创建一个恶意 `VirtualService`，该服务会匹配特定主机名的请求，
并将它们重定向到攻击者控制的服务。因此，网格中其他工作负载的流量可以在到达其预期目的地之前，透明地路由到攻击者的服务。

这种行为使得服务网格内部可以发起中间人攻击。攻击者控制的服务可以拦截来自网格内其他服务的流量，
包括发往网格内其他服务的流量以及发往外部服务的流量。这使得攻击者能够：

* 作为目标服务。
* 将流量重定向到备用目标。
* 丢弃请求以中断通信（拒绝服务攻击）。

由于 `VirtualService` 覆盖了默认行为，源服务会将请求发送到攻击者控制的服务，
而不是目标服务。Istio 的双向 TLS 认证在这里不起作用，
因为代理会将攻击者控制的服务识别为被覆盖主机名的合法目标。然而，
对于攻击者来说，将此流量转发到目标服务以读取或修改两个服务之间的通信更具挑战性，
因为他们无法绕过 Istio 的 [Layer 4 和 Layer 7 安全特性](/zh/docs/overview/dataplane-modes/#layer-4-vs-layer-7-features)。
当攻击者拦截通信时，源服务和目标服务之间的端到端加密和认证将被破坏。
因此，从攻击者控制的服务转发到目标服务的请求会被认证为来自攻击者控制的服务的请求。
结果，目标服务上配置的[授权策略](/zh/docs/reference/config/security/authorization-policy/)可能会拒绝该请求。
此外，目标服务将在 ``X-Forwarded-Client-Cert`` 标头中看到攻击者控制的服务身份，并且来自源服务的身份验证丢失。

## 为什么会出现这种行为？ {#why-does-this-behavior-occur}

这种行为是由 Istio 在服务网格内分发和评估流量路由配置的方式造成的。

Istio 服务网格在逻辑上分为数据平面和控制平面。Istio 的控制平面聚合所有
`VirtualService` 资源的路由配置，并将生成的配置分发给构成数据平面的 Envoy Sidecar 代理。
这些代理随后在本地对其处理的流量强制执行路由规则，另请参阅 [Istio 架构](/zh/docs/ops/deployment/architecture/)。

当 `VirtualService` 配置为网格网关时，其路由规则将应用于网格中的所有边车服务，
包括内部服务间流量。由于此配置的影响范围不限于 `VirtualService` 所在的命名空间，
因此在一个命名空间中创建的配置可以匹配来自其他命名空间中工作负载的请求。

## 缓解措施和最佳实践 {#mitigation-and-best-practices}

在基于命名空间的多租户架构中运行 Istio 或在多个集群上运行单个网格的运维人员应采取额外的安全措施来维持严格的隔离。
如果没有这些控制措施，可能会在数据平面层面发生意外的跨命名空间流量篡改。

### 建议的缓解措施：迁移到较新的 Gateway API {#recommended-mitigation-migrate-to-the-newer-gateway-api}

理想情况下，创建或修改 Istio 网络资源（``networking.istio.io/v1`` 以及 ``security.istio.io/v1``）的权限应仅限于负责全局路由的平台操作员。

作为一种替代方案，运营商可以为租户提供对更新的 [Gateway API](https://gateway-api.sigs.k8s.io/) 的访问权限，
该 API 的设计充分考虑了安全的跨命名空间支持。但是，平台运营商仍然需要控制对网关等共享资源的访问。

[配置作用域](/zh/docs/ops/configuration/mesh/configuration-scoping/#scoping-mechanisms)可以作为附加控制来实现。

### 传统架构中的缓解措施 {#mitigation-in-legacy-setups}

当由于业务或组织需求而无法进行此类更改和限制时，路由配置应限定于特定服务或命名空间。
除非明确需要且其影响已得到充分理解，否则应避免使用影响整个网络结构的通用规则。

缓解此类攻击的一种方法是配置作用域（[Scoping](/zh/docs/ops/configuration/mesh/configuration-scoping/#scoping-mechanisms)）。
例如，将每个命名空间中的出口监听器（[Egress listener](/zh/docs/reference/config/networking/sidecar/#IstioEgressListener)）限制在受信任的命名空间内。
但是，这种方法只能缓解 Sidecar 模式和使用 waypoint 的 Ambient 模式下的问题，
而不能缓解[仅限 L4 Ambient 模式](/zh/docs/ambient/overview/)下的问题，
也不能缓解使用 [Istio 网关](/zh/docs/reference/config/networking/gateway/)时配置的主机的问题。

另一种缓解此类攻击的方法是实施[准入策略](https://kubernetes.io/zh-cn/docs/reference/access-authn-authz/admission-controllers/)，
限制每个租户在 ``host`` 部分可以使用的主机。这也能缓解环境模式下的问题。

## 结论 {#conclusion}

如本文所示，Istio 的网格网关选项允许在一个命名空间中定义的规则影响其他命名空间的流量。
在基于命名空间的多租户设置中，或者当在多个集群上运行单个网格时，
这种行为可能会使服务网格暴露给恶意攻击者，例如，允许中间人攻击，正如这篇博文中所述。

Istio 并不声称（也不寻求声称）提供严格的基于命名空间的多租户架构，
因为该项目选择了更易于采用的折衷方案。因此，依赖此类多租户架构的运维人员应评估其架构中存在的风险并解决缺陷，
例如，移除不必要的基于角色的访问控制（RBAC）权限并实施严格的准入控制。

## 参考 {#references}

* [Istio 文档 — 安全模型](/zh/docs/ops/deployment/security-model/#k8s-account-compromise)
* [安全公告 ISTIO-SECURITY-2026-002](/zh/news/security/istio-security-2026-002/)
* [Istio 文档 — 流量管理](/zh/docs/concepts/traffic-management/)
* [Istio 文档 — VirtualService](/zh/docs/reference/config/networking/virtual-service/)
