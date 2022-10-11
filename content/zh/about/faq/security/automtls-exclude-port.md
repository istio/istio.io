---
title: Auto 双向 TLS 是否排除使用 "excludeInboundPorts" 注释设置的端口？
weight: 80
---

不，当 `traffic.sidecar.istio.io/excludeInboundPorts` 用于服务器工作负载时，
Istio 仍然默认配置客户端 Envoy 以发送双向 TLS。要改变这一点，您需要配置一个目标规则，
将双向 TLS 模式设置为 `DISABLE`，
用以让客户端发送纯文本到这些端口。
