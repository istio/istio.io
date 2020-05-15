---
title: Istio 认证是使用的 Kubernetes secret 吗？
weight: 120
---

是的，Istio 认证的密钥和证书分发基于 [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/) 实现。

Secret [安全风险](https://kubernetes.io/docs/concepts/configuration/secret/#risks)需知。
Kubernetes 团队正在研究[多种特性](https://docs.google.com/document/d/1T2y-9geg9EfHHtCDYTXptCa-F4kQ0RyiH-c_M1SyD0s)，以从 secret 加密到节点级访问控制，全面增强 Kubernetes secret 的安全性。
从 1.6 版本开始，Kubernetes 引入了 [RBAC 认证](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)，可以提供细粒度的 secret 管理。
