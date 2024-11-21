---
title: What generates the initial trace headers?
weight: 15
---

The Istio gateway or sidecar proxy (Envoy) generates the initial [headers](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-request-id), if they are not provided by the request.
