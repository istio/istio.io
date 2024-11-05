---
title: Як працює розподілений трейсинг з Istio?
weight: 0
---

Istio інтегрується з системами розподіленого трейсингу, використовуючи [Envoy-based](#how-envoy-based-tracing-works) трейсинг. Завдяки інтеграції трейсингу на основі Envoy, [застосунки відповідають за перенаправлення заголовків трейсів](#istio-copy-headers) для наступних вихідних запитів.

Додаткову інформацію можна знайти в завданнях Розподілений трейсинг в Istio ([Jaeger](/docs/tasks/observability/distributed-tracing/jaeger/), [Lightstep](/docs/tasks/observability/distributed-tracing/lightstep/), [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/)) та у [документації Envoy щодо трейсів](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/observability/tracing).
