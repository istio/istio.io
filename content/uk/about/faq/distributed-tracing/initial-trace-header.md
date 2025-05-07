---
title: Хто генерує початкові заголовки трейсів?
weight: 15
---

Шлюз Istio або додатковий проксі-сервер (Envoy) генерує початкові [заголовки](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_conn_man/headers#x-request-id), якщо вони не вказані в запиті.
