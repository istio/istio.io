---
title: TLS Origination
---

TLS 源（TLS Origination）发生于一个被配置为接收内部未加密 HTTP 连接的 Istio 代理（sidecar 或 egress gateway）加密请求并使用简单或双向 TLS 将其转发至安全的 HTTPS 服务器时。
这与 [TLS 终止](https://en.wikipedia.org/wiki/TLS_termination_proxy)相反，后者发生于一个接受 TLS 连接的 ingress 代理解密 TLS 并将未加密的请求传递到网格内部的服务时。
