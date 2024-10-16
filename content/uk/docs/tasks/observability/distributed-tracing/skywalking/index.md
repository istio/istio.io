---
title: Apache SkyWalking
description: Дізнайтеся, як налаштувати проксі для надсилання запитів трейсингу до Apache SkyWalking.
weight: 10
keywords: [телеметрія,трейсинг,skywalking,спан,порт-форвардинг,telemetry,tracing,skywalking,span,port-forwarding]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Після завершення цього завдання ви зможете зрозуміти, як ваш застосунок може брати участь у трейсингу з [Apache SkyWalking](https://skywalking.apache.org), незалежно від мови, фреймворка або платформи, яку ви використовуєте для його створення.

Це завдання використовує [Bookinfo](/docs/examples/bookinfo/), як демонстраційний застосунок.

Щоб дізнатися, як Istio обробляє трейсинг, відвідайте розділ [Огляд розподіленого трейсингу](../overview/).

## Налаштування трейсингу {#configure-tracing}

Якщо ви використовували CR `IstioOperator` для установки Istio, додайте наступне поле до вашої конфігурації:

{{< text yaml >}}
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    defaultProviders:
      tracing:
      - "skywalking"
    enableTracing: true
    extensionProviders:
    - name: "skywalking"
      skywalking:
        service: tracing.istio-system.svc.cluster.local
        port: 11800
{{< /text >}}

З цією конфігурацією Istio буде встановлено з агентом SkyWalking як стандартним трейсером. Дані трейсингу будуть надсилатись до бекенду SkyWalking.

В стандартному профілі швидкість відбору становить 1%. Збільште її до 100% за допомогою [Telemetry API](/docs/tasks/observability/telemetry/):

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  tracing:
  - randomSamplingPercentage: 100.00
EOF
{{< /text >}}

## Розгортання SkyWalking Collector {#deploy-the-skywalking-collector}

Слідуйте [документації з установки SkyWalking](/docs/ops/integrations/skywalking/#installation) для розгортання SkyWalking у вашому кластері.

## Розгортання застосунку Bookinfo {#deploy-the-bookinfo-application}

Розгорніть [демонстраційний застосунок Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

## Доступ до панелі управління {#accessing-the-dashboard}

[Віддалений доступ до надбудов телеметрії](/docs/tasks/observability/gateways) описує, як налаштувати доступ до надбудов Istio через шлюз.

Для тестування (та тимчасового доступу) ви також можете використовувати порт-форвардинг. Використовуйте наступне, припускаючи, що ви розгорнули SkyWalking у просторі імен `istio-system`:

{{< text bash >}}
$ istioctl dashboard skywalking
{{< /text >}}

## Генерація трейсів за допомогою Bookinfo {#generating-traces-using-the-bookinfo-sample}

1. Коли застосунок Bookinfo буде запущено, отримайте доступ до `http://$GATEWAY_URL/productpage` один або кілька разів для генерації інформації про трейс.

    {{< boilerplate trace-generation >}}

1. У панелі "General Service" ви можете побачити список сервісів.

    {{< image link="./istio-service-list-skywalking.png" caption="Список сервісів" >}}

1. Виберіть вкладку `Trace` в основному контенті. Ви можете побачити список трейсів на лівій панелі та деталі трейсів на правій панелі:

    {{< image link="./istio-tracing-list-skywalking.png" caption="Перегляд трейсів" >}}

1. Трейс складається з набору відрізків (span), де кожен відрізок відповідає сервісу Bookinfo, викликаному під час виконання запиту `/productpage`, або внутрішньому компоненту Istio, наприклад: `istio-ingressgateway`.

## Дослідження офіційного демонстраційного додатка SkyWalking {#explore-skywalkings-official-demo-application}

У цьому навчальному посібнику ми використовуємо демонстраційний застосунок [Bookinfo](/docs/examples/bookinfo/#deploying-the-application), у цьому застосунку агент SkyWalking не встановлений на сервісах, всі трейсинги генеруються проксі.

Якщо ви хочете дізнатися більше про [агенти мови SkyWalking](https://skywalking.apache.org/docs/#Agent), команда SkyWalking також надає [демонстраційний застосунок](http://github.com/apache/skywalking-showcase), який інтегрований з мовними агентами, і ви можете отримати більш детальні трейсинги, а також інші специфічні функції агента мови, такі як профілювання.

## Очищення {#cleanup}

1. Видаліть будь-які процеси `istioctl`, які можуть все ще працювати, використовуючи control-C або:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

2. Якщо ви не плануєте досліджувати жодних подальших завдань, зверніться до інструкцій з [очищення Bookinfo](/docs/examples/bookinfo/#cleanup), щоб завершити роботу з застосунком.
