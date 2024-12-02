---
title: Налаштування метрик Istio за допомогою Telemetry API
description: Це завдання показує, як налаштувати метрики Istio за допомогою Telemetry API.
weight: 10
keywords: [telemetry,metrics,customize]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Telemetry API вже деякий час є в Istio як API першокласного рівня. Раніше користувачам потрібно було налаштовувати метрики в розділі `telemetry` конфігурації Istio.

Це завдання показує, як налаштувати метрики, які Istio генерує за допомогою Telemetry API.

## Перед тим як почати {#before-you-begin}

[Встановіть Istio](/docs/setup/) у вашому кластері та розгорніть застосунок.

Telemetry API не може працювати разом з `EnvoyFilter`. Для отримання додаткової інформації ознайомтесь з цим [тікетом](https://github.com/istio/istio/issues/39772).

* Починаючи з версії Istio `1.18`, `EnvoyFilter` для Prometheus не буде стандартно встановлений, і замість цього використовується `meshConfig.defaultProviders` для його активації. Telemetry API слід використовувати для подальшого налаштування конвеєра телеметрії.

* Для версій Istio до `1.18` слід встановити з наступною конфігурацією `IstioOperator`:

    {{< text yaml >}}
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      values:
        telemetry:
          enabled: true
          v2:
            enabled: false
    {{< /text >}}

## Перевизначення метрик {#override-metrics}

Розділ `metrics` надає значення для метрик у вигляді виразів та дозволяє видаляти або перевизначати наявні визначення метрик. Ви можете змінити стандартні визначення метрик за допомогою `tags_to_remove` або шляхом повторного визначення.

1. Видаліть теги `grpc_response_status` з метрики `REQUEST_COUNT`

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: remove-tags
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - match:
                mode: CLIENT_AND_SERVER
                metric: REQUEST_COUNT
              tagOverrides:
                grpc_response_status:
                  operation: REMOVE
    {{< /text >}}

2. Додайте власні теґи для метрики `REQUEST_COUNT`

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: custom-tags
      namespace: istio-system
    spec:
      metrics:
        - overrides:
            - match:
                metric: REQUEST_COUNT
                mode: CLIENT
              tagOverrides:
                destination_x:
                  value: filter_state.upstream_peer.app
            - match:
                metric: REQUEST_COUNT
                mode: SERVER
              tagOverrides:
                source_x:
                  value: filter_state.downstream_peer.app
          providers:
            - name: prometheus
    {{< /text >}}

## Вимкнення метрик {#disable-metrics}

1. Вимкніть усі метрики, виконавши такі налаштування:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: remove-all-metrics
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: CLIENT_AND_SERVER
                metric: ALL_METRICS
    {{< /text >}}

1. Вимкніть метрику `REQUEST_COUNT` за допомогою наступних налаштувань:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: remove-request-count
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: CLIENT_AND_SERVER
                metric: REQUEST_COUNT
    {{< /text >}}

1. Вимкніть метрику `REQUEST_COUNT` для клієнта, виконавши такі налаштування:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: remove-client
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: CLIENT
                metric: REQUEST_COUNT
    {{< /text >}}

1. Вимкніть метрику `REQUEST_COUNT` для сервера, виконавши такі налаштування:

    {{< text yaml >}}
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: remove-server
      namespace: istio-system
    spec:
      metrics:
        - providers:
            - name: prometheus
          overrides:
            - disabled: true
              match:
                mode: SERVER
                metric: REQUEST_COUNT
    {{< /text >}}

## Перевірка результатів {#verify-the-results}

Надішліть трафік до мережі. Для застосунку Bookinfo відвідайте `http://$GATEWAY_URL/productpage` у вашому вебоглядачі або виконайте наступну команду:

{{< text bash >}}
$ curl "http://$GATEWAY_URL/productpage"
{{< /text >}}

{{< tip >}}
`$GATEWAY_URL` — це значення, встановлене в застосунку [Bookinfo](/docs/examples/bookinfo/).
{{< /tip >}}

Використовуйте наступну команду для перевірки того, що Istio генерує дані для ваших нових або змінених метрик:

{{< text bash >}}
$ istioctl x es "$(kubectl get pod -l app=productpage -o jsonpath='{.items[0].metadata.name}')" -oprom | grep istio_requests_total | grep -v TYPE | grep -v 'reporter="destination"'
{{< /text >}}

{{< text bash >}}
$ istioctl x es "$(kubectl get pod -l app=details -o jsonpath='{.items[0].metadata.name}')" -oprom | grep istio_requests_total
{{< /text >}}

Наприклад, у виводі знайдіть метрику `istio_requests_total` і перевірте, чи містить вона вашу нову розмірність.

{{< tip >}}
Може знадобитися невеликий проміжок часу, щоб проксі почали застосовувати конфігурацію. Якщо метрику не отримано, ви можете повторити спробу надсилання запитів після короткої паузи та знову перевірити метрику.
{{< /tip >}}
