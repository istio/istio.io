---
title: 策略
description: 描述 Istio 的策略管理功能。
weight: 30
keywords: [policy,policies]
---

Istio 允许您为应用程序自定义策略，用以在运行时强制执行相应的规则，例如：

- 限流用于动态限制发送给服务的流量
- Denials、白名单和黑名单用于限制服务的访问
- Header 的重写和重定向

Istio 还允许您创建自己的[策略适配器](/zh/docs/tasks/policy-enforcement/control-headers)，比如，您自定义的授权行为。

您必须为您的服务网格[启用策略实施](/zh/docs/tasks/policy-enforcement/enabling-policy)以后才能使用此功能。
