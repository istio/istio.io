---
title: 为什么要初始化生成 Zipkin (B3) HTTP header?
weight: 15
---

如果请求中没有 Zipkin (B3) HTTP header，Istio sidecar 代理(Envoy) 会自动生成初始化的
[headers](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-request-id)。
