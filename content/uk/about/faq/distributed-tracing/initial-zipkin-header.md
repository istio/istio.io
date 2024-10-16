---
title: Хто генерує початкові HTTP заголовки Zipkin (B3)?
weight: 15
---

Початкові [заголовки](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-request-id) Zipkin (B3) генерує sidecar проксі Istio (Envoy), якщо вони не надаються запитом.
