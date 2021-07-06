---
title: 如果全局启用 TLS 双向认证，那么非 Istio 服务还可以访问 Istio 服务吗？
weight: 30
---
启用 `STRICT` 双向 TLS 时，非 Istio 工作负载无法与 Istio 服务通信，因为它们没有有效的 Istio 客户端证书。

如果需要允许这些客户端，可以将双向 TLS 模式配置为 `PERMISSIVE`，允许明文和双向 TLS。
这可以针对单个工作负载或整个网格来完成。

有关更多详细信息，请参阅 [身份验证策略](/zh/docs/tasks/security/authentication/authn-policy)。
