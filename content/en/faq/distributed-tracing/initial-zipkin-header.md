---
title: What generates the initial Zipkin (B3) HTTP headers?
weight: 15
---

The Istio sidecar proxy (Envoy) generates the initial [headers](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-request-id), if they are not provided by the request.
