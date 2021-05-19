---
title: 在同一集群中，我可以为部分服务开启 TLS 双向认证，并为其它服务关闭 TLS 双向认证吗？
weight: 20
---

[认证策略](/zh/docs/concepts/security/#authentication-policies)可以配置为 mesh-wide（影响网络中的所有服务）、namespace-wide（namespace 中的所有服务）或某个特定服务。
您可以根据需要对集群中的服务配置一种或多种 TLS 双向认证策略。
