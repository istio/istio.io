---
title: Jaeger
description: Дізнайтеся, як налаштувати проксі для відправки запитів трейсингу до Jaeger.
weight: 20
keywords: [телеметрія,трейсинг,jaeger,спан,порт-форвардинг,telemetry,tracing,jaeger,span,port-forwarding]
aliases:
 - /uk/docs/tasks/telemetry/distributed-tracing/jaeger/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Після завершення цього завдання ви зможете зрозуміти, як ваш застосунок може брати участь у трейсингу з [Jaeger](https://www.jaegertracing.io/), незалежно від мови, фреймворка або платформи, який ви використовуєте для створення застосунку.

Це завдання використовує [Bookinfo](/docs/examples/bookinfo/) як демонстраційний застосунок.

Щоб дізнатися, як Istio обробляє трейсинг, відвідайте [огляд цього завдання](../overview/).

## Перед початком {#before-you-begin}

1. Слідуйте [документації з установки Jaeger](/docs/ops/integrations/jaeger/#installation) для розгортання Jaeger у вашому кластері.

1. При увімкненні трейсингу ви можете налаштувати швидкість відбору, яку Istio використовує для трейсингу. Використовуйте опцію `meshConfig.defaultConfig.tracing.sampling` під час установки для [налаштування швидкості відбору](/docs/tasks/observability/distributed-tracing/mesh-and-proxy-config/#customizing-trace-sampling). Стандартно швидкість відбору становить 1%.

1. Розгорніть [демонстраційний застосунок Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

## Доступ до панелі управління {#accessing-the-dashboard}

[Віддалений доступ до надбудов телеметрії](/docs/tasks/observability/gateways) описує, як налаштувати доступ до надбудов Istio через шлюз.

Для тестування (та тимчасового доступу) ви також можете використовувати порт-форвардинг. Використовуйте наступне, припускаючи, що ви розгорнули Jaeger у просторі імен `istio-system`:

{{< text bash >}}
$ istioctl dashboard jaeger
{{< /text >}}

## Генерація трейсів за допомогою Bookinfo {#generate-traces-using-the-bookinfo-sample}

1. Коли застосунок Bookinfo буде запущено, отримайте доступ до `http://$GATEWAY_URL/productpage` один або кілька разів для генерації інформації про трейс.

    {{< boilerplate trace-generation >}}

1. У лівій частині панелі управління виберіть `productpage.default` зі списку **Service** та натисніть **Find Traces**:

    {{< image link="./istio-tracing-list.png" caption="Панель трейсингу" >}}

1. Клацніть на останньому трейсі вгорі, щоб переглянути деталі, що відповідають останньому запиту до `/productpage`:

    {{< image link="./istio-tracing-details.png" caption="Детальний перегляд трейсів" >}}

1. Трейс складається з набору відрізків, де кожен відрізок відповідає сервісу Bookinfo, викликаному під час виконання запиту `/productpage`, або внутрішньому компоненту Istio, наприклад: `istio-ingressgateway`.

## Очищення {#cleanup}

1. Видаліть будь-які процеси `istioctl`, які можуть все ще працювати, використовуючи control-C або:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

1. Якщо ви не плануєте досліджувати жодних подальших завдань, зверніться до інструкцій з [очищення Bookinfo](/docs/examples/bookinfo/#cleanup), щоб завершити роботу з застосунком.
