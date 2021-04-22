---
title: 如果全局启用 TLS 双向认证，那么非 Istio 服务还可以访问 Istio 服务吗？
weight: 30
---
非 Istio 服务无法与 Istio 服务通信。除非它能提供有效证书，但这基本不可能。
这是 *双向 TLS 认证* 的预期表现。
但是，您可以覆盖指定 namespace 或服务的全局标志。详见：[认证策略](/zh/docs/tasks/security/authentication/authn-policy)
