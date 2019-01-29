---
title: Istio 0.8
weight: 93
icon: notes
---

这是 Istio 1.0 路上的一次重要发布，除了通常的问题修复和性能增强之外，其中包含了很多新功能，架构方面也做出了很多改进。

{{< relnote_links >}}

## 网络

- **重构网络管理模型**：[新的流量管理 API](/zh/blog/2018/v1alpha3-routing/) 业已就绪。新的模型覆盖了更多真实世界的部署[用例](/zh/docs/tasks/traffic-management/)，更加易于理解和使用。如果要从早期部署中进行升级，这里提供了[升级指南](/zh/docs/setup/kubernetes/upgrading-istio/)，并且在 `istioctl` 中加入了转换工具，帮助用户对旧版本配置进行升级。

- **Envoy 配置传播**：新版本中，Pilot 缺省使用 Envoy 的 [ADS API](https://github.com/envoyproxy/data-plane-api/blob/master/XDS_PROTOCOL.md) 进行配置传播。这种新方法提高了稳定性、降低了生效延迟，应该也解决了之前的方法造成的 404 错误。

- **Ingress/Egress Gateway**：路由规则不再提供对 Kubernetes Ingress 规范的支持，这种支持曾经导致了大量的 Bug 和可靠性问题。Istio 现在为 Ingress 和 Egress 代理提供了平台独立的 [Gateway](/zh/docs/concepts/traffic-management/#gateway) 模型。新模型能够很好的和 Kubernetes 以及 Cloud Foundry 协作，并可以无缝应用路由能力。Gateway 支持基于 [服务器命名认证（SNI）](https://en.wikipedia.org/wiki/Server_Name_Indication) 的路由功能，并且能够根据客户端要求的服务器名称提供证书。

- **有约束的入站端口**：目前会根据 Pod 中运行的应用定义，对入站端口进行限制。

## 安全

- **引入 Citadel**：安全组件最终定名。之前的 `Istio-Auth` 或 `Istio-CA` 现更名为 `Citadel`。

- **多集群支持**：在多集群部署中能够支持每集群的 Citadel 部署，所有的 Citadel 共享同样的根证书，工作负载之间能够进行跨网格认证。

- **认证策略**：我们为[认证策略](/zh/docs/tasks/security/authn-policy/)提供了统一的 API，管理范围涵盖了服务间的双向 TLS 认证和最终用户认证。我们推荐使用认证策略来管理认证的相关行为。

## 遥测

- **自发报告**：Mixer 和 Pilot 现在会生成遥测数据，并和网格中运行的其他服务一样，将遥测指标汇总到 Istio 的遥测管线之中。

## 安装

- **Istio 的按需安装**：Istio 具有丰富的功能，可能有用户并不需要使用所有功能，可以使用 Helm 或者 `istioctl gen-deploy` 工具，来满足按需安装的需要。例如用户可以只安装 Pilot 来对流量进行管理，而不去触及 Mixer 和 Citadel 方面的功能。

## Mixer 适配器

- **CloudWatch**：Mixer 目前可以把指标报告给 AWS CloudWatch。[参考资料](/docs/reference/config/policy-and-telemetry/adapters/cloudwatch/)

## 0.8 版本的已知问题

- 如果 Virtual Service 对象指向了 Headless 服务，则对应的 Gateway 无法工作（[Issue #5005](https://github.com/istio/istio/issues/5005)）。

- [Google Kubernetes Engine 1.10.2](https://github.com/istio/istio/issues/5723) 中，使用 Kubernetes 1.9 或者把节点切换为 Ubuntu 就会复现这一问题。该问题在 GKE 1.10.4 中有望得到更正。

- `istioctl experimental convert-networking-config` 会引发一个命名相关的问题——目标命名空间可能被替换为 `istio-system`，因此在运行这一工具之后，需要手工调整命名空间。[参考资料](https://github.com/istio/istio/issues/5817)
