---
title: Огляд
description: Огляд розподіленого трейсингу в Istio.
weight: 1
keywords: [телеметрія,трейсинг,telemetry,tracing]
aliases:
 - /uk/docs/tasks/telemetry/distributed-tracing/overview/
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

Розподілений трейсинг дозволяє користувачам відстежувати запит через мережу, розподілену між кількома сервісами. Це дозволяє глибше зрозуміти затримки запиту, серіалізацію та паралелізм через візуалізацію.

Istio використовує [розподілений трейсинг Envoy](https://www.envoyproxy.io/docs/envoy/v1.12.0/intro/arch_overview/observability/tracing), щоб забезпечити інтеграцію трейсингу з коробки. Зокрема, Istio надає можливість встановлення різних бекендів трейсингу та конфігурації проксі для автоматичного надсилання трейс-спанів до них. Дивіться документацію завдань [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/), [Jaeger](/docs/tasks/observability/distributed-tracing/jaeger/), та [Lightstep](/docs/tasks/observability/distributed-tracing/lightstep/) про те, як Istio працює з цими системами трейсингу.

## Пропагування контексту трейсингу {#trace-context-propagation}

Хоча проксі Istio можуть автоматично надсилати відрізки, додаткова інформація потрібна для зʼєднання цих відрізків в один трейс. Застосунки повинні пропагувати цю інформацію в HTTP-заголовках, щоб, коли проксі надсилають відрізки, бекенд міг обʼєднати їх у єдиний трейс.

Для цього кожний застосунок має збирати заголовки з кожного вхідного запиту і передавати заголовки всім вихідним запитам, що ініціюються цим вхідним запитом. Вибір заголовків для передачі залежить від налаштованого бекенду трейсингу. Набір заголовків для передачі описується на кожній сторінці специфічних завдань трейсингу. Ось короткий огляд:

Усі застосунки повинні передавати наступний заголовок:

* `x-request-id`: це заголовок, специфічний для Envoy, який використовується для послідовного відбору логів та трейсів.

Для Zipkin, Jaeger та Stackdriver слід передавати формат B3 multi-header:

* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`

Ці заголовки підтримуються Zipkin, Jaeger та багатьма іншими інструментами.

Для Datadog слід передавати наступні заголовки. Передача цих заголовків автоматично обробляється бібліотеками клієнтів Datadog для багатьох мов і фреймворків.

* `x-datadog-trace-id`.
* `x-datadog-parent-id`.
* `x-datadog-sampling-priority`.

Для Lightstep слід передавати заголовок контексту відрізку OpenTracing:

* `x-ot-span-context`

Для Stackdriver ви можете вибрати один з наступних заголовків замість формату B3 multi-header.

* `grpc-trace-bin`: стандартний заголовок трейсингу grpc.
* `traceparent`: стандарт W3C Trace Context для трейсингу. Підтримується OpenTelemetry та збільшується кількість бібліотек клієнтів Jaeger.
* `x-cloud-trace-context`: використовується API продуктів Google Cloud.

Якщо подивитися на приклад сервісу Python `productpage`, наприклад, ви побачите, що застосунок витягує необхідні заголовки для всіх трейсерів з HTTP-запиту за допомогою бібліотек [OpenTracing](https://opentracing.io/):

{{< text python >}}
def getForwardHeaders(request):
    headers = {}

    # x-b3-*** заголовки можуть бути заповнені за допомогою відрізку opentracing
    span = get_current_span()
    carrier = {}
    tracer.inject(
        span_context=span.context,
        format=Format.HTTP_HEADERS,
        carrier=carrier)

    headers.update(carrier)

    # ...

        incoming_headers = ['x-request-id',
        'x-ot-span-context',
        'x-datadog-trace-id',
        'x-datadog-parent-id',
        'x-datadog-sampling-priority',
        'traceparent',
        'tracestate',
        'x-cloud-trace-context',
        'grpc-trace-bin',
        'user-agent',
        'cookie',
        'authorization',
        'jwt',
    ]

    # ...

    for ihdr in incoming_headers:
        val = request.headers.get(ihdr)
        if val is not None:
            headers[ihdr] = val

    return headers
{{< /text >}}

Застосунок reviews (Java) робить щось подібне за допомогою `requestHeaders`:

{{< text java >}}
@GET
@Path("/reviews/{productId}")
public Response bookReviewsById(@PathParam("productId") int productId, @Context HttpHeaders requestHeaders) {

  // ...

  if (ratings_enabled) {
    JsonObject ratingsResponse = getRatings(Integer.toString(productId), requestHeaders);
{{< /text >}}

Коли ви робите подальші виклики у ваших застосунках, переконайтеся, що включаєте ці заголовки.
