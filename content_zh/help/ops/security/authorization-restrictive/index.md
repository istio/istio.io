---
title: 授权过于严格 
description: 启用了授权然后任何请求都无法到达服务。
weight: 60
---

当你第一次对一个服务启用授权，所有的请求都会被默认拒绝。在你增加上授权策略后，满足授权策略的请求就能够通过。如果所有的请求还是被拒绝，你可以试试下面的操作：

1. 确保在你的授权策略 YAML 文件中内容正确。

1. 不要为 Istio 的控制面组件启用授权，包括 Mixer、Pilot、Ingress。Istio 授权策略是为访问 Istio 网格内服务的授权而设计的。如果对 Istio 的控制面启用授权会导致不可预期的行为。

1. 确保你的 `ServiceRoleBinding` 和相关的 `ServiceRole` 对象在同一个命名空间（检查 `metadata/namespace` 这一行）。

1. 请您不要为 TCP 服务的 `ServiceRole` 和 `ServiceRoleBinding` 设置那些仅适用于 HTTP 服务的属性字段。
否则，Istio 会自动忽略这些配置，就好像它们不存在一样。

1. 在 Kubernetes 环境，确保所有在一个 `ServiceRole` 对象下的服务都在和 `ServiceRole` 在同一个命名空间。例如，如果 `ServiceRole` 对象中的服务是 `a.default.svc.cluster.local`，`ServiceRole` 必须在 `default` 命名空间（`metadata/namespace` 这一行应该是 `default`）。对于非 Kubernetes 的环境，一个网格的所有 `ServiceRoles` 和 `ServiceRoleBindings` 都应该在相同的命名空间下。

1. 根据[调试授权文档](/zh/help/ops/security/debugging-authorization/)找到确切的原因。