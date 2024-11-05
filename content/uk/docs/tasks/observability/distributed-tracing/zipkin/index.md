---
title: Zipkin
description: Дізнайтеся, як налаштувати проксі-сервери для надсилання запитів на трейсинг до Zipkin.
weight: 50
keywords: [telemetry,tracing,zipkin,span,port-forwarding]
aliases:
    - /uk/docs/tasks/zipkin-tracing.html
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Після виконання цього завдання ви дізнаєтесь, як забезпечити участь вашого застосунку у зборі трейсів за допомогою [Zipkin](https://zipkin.io/), незалежно від мови програмування, фреймворку або платформи, яку ви використовуєте для створення застосунку.

Це завдання використовує зразок застосунку [Bookinfo](/docs/examples/bookinfo/) як приклад.

Щоб дізнатися, як Istio обробляє трейси, відвідайте розділ [огляд](../overview/) цього завдання.

## Перш ніж почати {#before-you-begin}

1. Дотримуйтесь інструкцій у розділі [Встановлення Zipkin](/docs/ops/integrations/zipkin/#installation) для розгортання Zipkin у вашому кластері.

2. Коли ви увімкнете трейсинг, ви зможете встановити коефіцієнт відбору, який Istio використовує для трейсингу. Використовуйте параметр `meshConfig.defaultConfig.tracing.sampling` під час встановлення, щоб [встановити коефіцієнт відбору](/docs/tasks/observability/distributed-tracing/mesh-and-proxy-config/#customizing-trace-sampling). Стандартне значення для коефіцієнта відбору дорвінює 1%.

3. Розгорніть зразок застосунку [Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

## Доступ до інфопанелі (дашбоарду) {#accessing-the-dashboard}

Детальніше про конфігурацію доступу до надбудов Istio через шлюз можна прочитати в розділі [Віддалений доступ до надбудов телеметрії](/docs/tasks/observability/gateways).

Для тестування (та тимчасового доступу) ви також можете використовувати перенаправлення портів. Використовуйте наступну команду, припускаючи, що ви розгорнули Zipkin у просторі імен `istio-system`:

{{< text bash >}}
$ istioctl dashboard zipkin
{{< /text >}}

## Генерація трейсів за допомогою Bookinfo {#generating-traces-using-the-bookinfo-sample}

1. Коли застосунок Bookinfo буде запущений, зверніться до `http://$GATEWAY_URL/productpage` один або більше разів, щоб згенерувати інформацію для трейсів.

   {{< boilerplate trace-generation >}}

2. На панелі пошуку натисніть на плюсик. Виберіть `serviceName` з першого списку, `productpage.default` з другого списку, а потім натисніть на іконку пошуку:

   {{< image link="./istio-tracing-list-zipkin.png" caption="Панель трейсів" >}}

3. Натисніть на результат пошуку `ISTIO-INGRESSGATEWAY`, щоб побачити деталі, що відповідають останньому запиту до `/productpage`:

   {{< image link="./istio-tracing-details-zipkin.png" caption="Детальний вигляд трейсів" >}}

4. Трасування складається з набору відрізків, де кожен відрізок відповідає одному з сервісів Bookinfo, які викликаються під час виконання запиту до `/productpage`, або внутрішньому компоненту Istio, наприклад: `istio-ingressgateway`.

## Очищення {#cleanup}

1. Завершіть всі процеси `istioctl`, які можуть все ще працювати, за допомогою комбінації клавіш Control-C або наступної команди:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

2. Якщо ви не плануєте виконувати інші завдання, ознайомтеся з інструкціями [Очищення після використання Bookinfo](/docs/examples/bookinfo/#cleanup), щоб вимкнути застосунок.
