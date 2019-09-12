---
title: 如果全局启用了双向 TLS，非 Istio 服务可以访问 Istio 服务吗？
weight: 30
---
非 Istio 服务无法与 Istio 服务进行通信，除非它们可以提供有效证书，而这种证书也很难提供。这正是*双向 TLS* 功能的目的。但是，你可以覆盖特定命名空间或服务的全局标志 (global flag)。有关详细信息，请参阅[任务](/zh/docs/tasks/security/authn-policy)。
