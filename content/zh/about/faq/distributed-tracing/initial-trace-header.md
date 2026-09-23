---
title: 初始链路头由谁来生成？
weight: 15
---

如果请求中未提供初始[标头](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-request-id)，
则 Istio 网关或 Sidecar 代理 (Envoy) 会生成初始[标头](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-request-id)。
