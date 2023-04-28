---
title: 如何验证流量是否使用双向 TLS 加密？
weight: 25
---

如果您使用 `values.global.proxy.privileged=true` 安装 Istio，
您可以使用 `tcpdump` 来确定加密状态。同样在 Kubernetes 1.23 及以后的版本中，
作为将 Istio 安装为特权用户的另一种选择，
您可以使用 `kubectl debug` 在 [ephemeral container](https://kubernetes.io/zh-cn/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container) 中运行 `tcpdump`。
有关说明，请参见 [Istio 双向 TLS 迁移](/zh/docs/tasks/security/authentication/mtls-migration)。
