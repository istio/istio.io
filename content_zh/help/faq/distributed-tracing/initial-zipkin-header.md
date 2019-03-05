---
title: 初始的 Zipkin (B3) HTTP header 由谁生成？
weight: 15
---

如果请求没有提供 header，Istio sidecar 代理（Envoy）将为其生成初始 [header](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_conn_man/headers#x-request-id)。