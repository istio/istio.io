---
title: Istio 权限认证是否使用了 Kubernetes secrets?
weight: 120
---

是的。Istio 权限认证中密钥和证书的分发是基于 [Kubernetes secrets](https://kubernetes.io/docs/concepts/configuration/secret/)。

Secrets 有已知的 [安全风险](https://kubernetes.io/docs/concepts/configuration/secret/#risks)。Kubernetes 团队正在开发 [几个功能特性](https://docs.google.com/document/d/1T2y-9geg9EfHHtCDYTXptCa-F4kQ0RyiH-c_M1SyD0s) 来提高 Kubernetes secret 的安全性，从 secret 的加密到节点级别的访问控制。并且 Kubernetes 从 1.6 版本引入了 [RBAC authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) ,提供了细力度的 secrets 管理。