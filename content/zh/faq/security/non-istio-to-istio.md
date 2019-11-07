---
title: 如果启用了全局 TLS 双向认证，那么非 Istio 服务还可以访问 Istio 服务吗？
weight: 30
---
非 Istio 服务无法与 Istio 服务通信。除非它能出示有效证书，但这基本不可能。
这是 *双向 TLS 认证* 的预期表现。
但是，您可以为特定的 namespace 或服务重写全局标志。详见：[任务](/zh/docs/tasks/security/authn-policy)
