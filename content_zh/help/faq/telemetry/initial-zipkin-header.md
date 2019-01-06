---
title:  Zipkin 初始的 HTTP Header 是谁产生的？
weight: 90
---

Istio sidecar 代理（Envoy）生成了第一个 [Header](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_conn_man/headers#x-request-id)。