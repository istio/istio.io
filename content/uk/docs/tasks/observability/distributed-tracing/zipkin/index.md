---
title: Zipkin
description: Дізнайтеся, як налаштувати проксі-сервери для надсилання запитів на трейсинг до Zipkin.
weight: 7
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

1. Розгорніть зразок застосунку [Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

## Налаштування Istio для розподіленого трейсингу {#configure-istio-for-distributed-tracing}

### Налаштування постачальника розширень {#configure-an-extension-provider}

Встановіть Istio з [постачальником розширень](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ExtensionProvider) посилаючись на сервіс Zipkin:

{{< text bash >}}
$ cat <<EOF > ./tracing.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    enableTracing: true
    defaultConfig:
       tracing: {} # відключіть застарілі параметри трейсингу MeshConfig
    extensionProviders:
    - name: zipkin
      zipkin:
        address: zipkin.istio-system.svc.cluster.local
        port: 9411
EOF
$ istioctl install -f ./tracing.yaml --skip-confirmation
{{< /text >}}

### Увімкнення трейсингу {#enable-tracing}

Увімкніть трейсинг, застосувавши наступну конфігурацію:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
   tracing:
   - providers:
     - name: "zipkin"
EOF
{{< /text >}}

## Доступ до інфопанелі (дашбоарду) {#accessing-the-dashboard}

Детальніше про конфігурацію доступу до надбудов Istio через шлюз можна прочитати в завданні [Віддалений доступ до надбудов телеметрії](/docs/tasks/observability/gateways).

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
