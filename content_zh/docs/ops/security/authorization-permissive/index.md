---
title: 授权太过宽松
description: 已经启用了授权，但是无论如何请求还是会通过。 
weight: 50
---

如果已经对一个服务启用了授权，但是对这个服务的请求没有被阻止，那么很有可能是授权没有成功启用。通过以下步骤可以检查这种情况：

1. 检查[启用授权文档](/zh/docs/concepts/security/)来正确的启用 Istio 授权。

1. 避免为 Istio 控制面组件启用授权，包括 Mixer，Pilot 和 Ingress。Istio 的授权是设计用于 Istio Mesh 下的服务之间的授权的。对 Istio 组件启用授权会引发不可预料的行为。

1. 在你的 Kubernetes 环境中，检查所有命名空间下的部署，确保没有可能导致 Istio 错误的遗留的部署。如果发现在向 Envoy 推送授权策略的时候发生错误，你可以禁用 Pilot 的授权插件。

1. 根据[调试授权文档](/help/ops/security/debugging-authorization/)找到确切的原因。
