---
title: 双向 TLS
description: 如何处理 TLS 认证的失效问题。
weight: 30
---

如果观察到双向 TLS 的问题，首先要确认 [Citadel 的健康情况](/zh/docs/ops/security/repairing-citadel/)，接下来要查看的是[密钥和证书](/docs/ops/security/keys-and-certs/)是否已经被正确分发给 Sidecar.

如果上述检查都正确无误，下一步就应该验证[认证策略](/zh/docs/tasks/security/authn-policy/)以及对应的目标规则是否正确应用。
