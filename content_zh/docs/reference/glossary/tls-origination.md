---
title: TLS 源
---
TLS 源 (TLS origination) 出现在：当 Istio 代理（sidecar 或出口网关）配置为接受未加密的内部 HTTP 连接，加密请求，然后将它们转发到使用简单或相互 TLS 保护的 HTTPS 服务器时。 这与 [TLS 终止](https://en.wikipedia.org/wiki/TLS_termination_proxy)相反，TLS 终止出现在一个入口代理接受 TLS 连接，解密这个连接，并将未加密的请求传递给内部网格服务。
