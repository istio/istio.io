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

Istio використовує [розподілений трейсинг Envoy](https://www.envoyproxy.io/docs/envoy/v1.12.0/intro/arch_overview/observability/tracing), щоб забезпечити інтеграцію трейсингу з коробки.

Більшість бекендів трейсингу зараз приймають протокол [OpenTelemetry](/docs/tasks/observability/distributed-tracing/opentelemetry/) для отримання трейсів, хоча Istio також підтримує застарілі протоколи для таких проєктів, як [Zipkin](/docs/tasks/observability/distributed-tracing/zipkin/) та [Apache SkyWalking](/docs/tasks/observability/distributed-tracing/skywalking/).

## Налаштування трейсингу {#configuring-tracing}

Istio надає [Telemetry API](/docs/tasks/observability/distributed-tracing/telemetry-api/), за допомогою якого можна налаштувати розподілений трейсинг, включаючи вибір провайдера, встановлення [частоти дискретизації](/docs/tasks/observability/distributed-tracing/sampling/) та зміну заголовків.

## Постачальники розширень {#extension-providers}

[Провайдери розширень](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider) визначаються у `MeshConfig` і дозволяють визначити конфігурацію для бекенду трейсингу. Підтримувані провайдери: OpenTelemetry, Zipkin, SkyWalking, Datadog та Stackdriver.

## Створення застосунків для підтримки поширення контексту трейсингу {#building-applications-to-support-trace-context-propagation}

Хоча проксі Istio можуть автоматично надсилати відрізки, додаткова інформація потрібна для зʼєднання цих відрізків в один трейс. Застосунки повинні пропагувати цю інформацію в HTTP-заголовках, щоб, коли проксі надсилають відрізки, бекенд міг обʼєднати їх у єдиний трейс.

Для цього кожний застосунок має збирати заголовки з кожного вхідного запиту і передавати заголовки всім вихідним запитам, що ініціюються цим вхідним запитом. Вибір заголовків для передачі залежить від налаштованого бекенду трейсингу. Набір заголовків для передачі описується на кожній сторінці специфічних завдань трейсингу. Ось короткий огляд:

Усі застосунки повинні передавати наступні заголовки:

* `x-request-id`: це заголовок, специфічний для Envoy, який використовується для послідовного відбору логів та трейсів.
* `traceparent` та `tracestate`: [W3C standard headers](https://www.w3.org/TR/trace-context/)

Для Zipkin слід передавати [формат B3 multi-header](https://github.com/openzipkin/b3-propagation):

* `x-b3-traceid`
* `x-b3-spanid`
* `x-b3-parentspanid`
* `x-b3-sampled`
* `x-b3-flags`

Щодо комерційних інструментів спостереження, зверніться до їхньої документації.

Якщо подивитися на [приклад сервісу Python `productpage`]({{< github_blob >}}/samples/bookinfo/src/productpage/productpage.py#L125), наприклад, ви побачите, що застосунок витягує необхідні заголовки для всіх трейсерів з HTTP-запиту за допомогою бібліотек OpenTelemetry:

{{< text python >}}
def getForwardHeaders(request):
    headers = {}

    # x-b3-*** заголовки можуть бути поширені за допомогою відрізку OpenTelemetry
    ctx = propagators.extract(carrier={k.lower(): v for k, v in request.headers})
    propagators.inject(headers, ctx)

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

[Застосунок reviews]({{< github_blob >}}/samples/bookinfo/src/reviews/reviews-application/src/main/java/application/rest/LibertyRestEndpoint.java#L186) (Java) робить щось подібне за допомогою `requestHeaders`:

{{< text java >}}
@GET
@Path("/reviews/{productId}")
public Response bookReviewsById(@PathParam("productId") int productId, @Context HttpHeaders requestHeaders) {

  // ...

  if (ratings_enabled) {
    JsonObject ratingsResponse = getRatings(Integer.toString(productId), requestHeaders);
{{< /text >}}

Коли ви робите подальші виклики у ваших застосунках, переконайтеся, що включаєте ці заголовки.
