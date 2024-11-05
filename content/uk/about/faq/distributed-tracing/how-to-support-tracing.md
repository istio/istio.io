---
title: Що потрібно для розподіленого трейсингу на основі Istio?
weight: 10
---

Istio дозволяє звітувати про трейс-відрізки (span) для комунікацій між робочими навантаженнями всередині мережі. Проте, щоб різні трейс-відрізки (span) могли бути зшиті разом для повного огляду потоку трафіку, застосунки повинні пропагувати контекст трейсингу між вхідними та вихідними запитами.

Зокрема, Istio покладається на застосунки для [пропагування заголовків B3 трейсингу](https://github.com/openzipkin/b3-propagation), а також згенерованого Envoy ID запиту. Ці заголовки включають:

- `x-request-id`
- `x-b3-traceid`
- `x-b3-spanid`
- `x-b3-parentspanid`
- `x-b3-sampled`
- `x-b3-flags`
- `b3`

Якщо ви використовуєте Lightstep, вам також потрібно буде передавати наступні заголовки:

- `x-ot-span-context`

Якщо ви використовуєте OpenTelemetry або Stackdriver, вам також потрібно буде передавати наступні заголовки:

- `traceparent`
- `tracestate`

Пропагування заголовків може бути здійснене за допомогою бібліотек клієнтів, таких як [Zipkin](https://zipkin.io/pages/tracers_instrumentation.html) або [Jaeger](https://github.com/jaegertracing/jaeger-client-java/tree/master/jaeger-core#b3-propagation). Також це можна зробити вручну, як документовано в [Завданні з трейсингу](/docs/tasks/observability/distributed-tracing/overview/#trace-context-propagation).
