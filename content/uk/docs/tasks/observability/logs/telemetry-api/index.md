---
title: Налаштування журналів доступу з Telemetry API
description: Це завдання показує, як налаштувати проксі Envoy для надсилання журналів доступу за допомогою Telemetry API.
weight: 10
keywords: [telemetry,logs,телеметрія,журнали]
owner: istio/wg-policies-and-telemetry-maintainers
test: так
---

Telemetry API є першокласним API в Istio вже певний час. Раніше користувачам потрібно було налаштовувати телеметрію в розділі `MeshConfig` конфігурації Istio.

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

## Встановлення {#installation}

У цьому прикладі ми будемо надсилати журнали до [Grafana Loki](https://grafana.com/oss/loki/), тому переконайтеся, що він встановлений:

{{< text syntax=bash snip_id=install_loki >}}
$ istioctl install -f @samples/open-telemetry/loki/iop.yaml@ --skip-confirmation
$ kubectl apply -f @samples/addons/loki.yaml@ -n istio-system
$ kubectl apply -f @samples/open-telemetry/loki/otel.yaml@ -n istio-system
{{< /text >}}

## Початок роботи з Telemetry API {#get-started-with-telemetry-api}

1. Увімкніть ведення журналу доступу

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n istio-system -f -
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: mesh-logging-default
    spec:
      accessLogging:
      - providers:
        - name: otel
    EOF
    {{< /text >}}

    Наведений вище приклад використовує вбудованого постачальника журналу доступу `envoy`, і ми не налаштовуємо нічого, крім стандартних параметрів.

1. Вимкніть журнал доступу для конкретного робочого навантаження

    Ви можете вимкнути журнал доступу для служби `sleep` за допомогою наступної конфігурації:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: disable-sleep-logging
      namespace: default
    spec:
      selector:
        matchLabels:
          app: sleep
      accessLogging:
      - providers:
        - name: otel
        disabled: true
    EOF
    {{< /text >}}

1. Фільтруйте журнал доступу за режимом робочого навантаження

    Ви можете вимкнути вхідний журнал доступу для служби `httpbin` за допомогою наступної конфігурації:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1
    kind: Telemetry
    metadata:
      name: disable-httpbin-logging
    spec:
      selector:
        matchLabels:
          app: httpbin
      accessLogging:
      - providers:
        - name: otel
        match:
          mode: SERVER
        disabled: true
    EOF
    {{< /text >}}

1. Фільтруйте журнал доступу за виразом CEL

    Наступна конфігурація показує журнал доступу лише тоді, коли код відповіді більший або дорівнює 500:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -n default -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: filter-sleep-logging
    spec:
      selector:
        matchLabels:
          app: sleep
      accessLogging:
      - providers:
        - name: otel
        filter:
          expression: response.code >= 500
    EOF
    {{< /text >}}

    {{< tip >}}
    Коли зʼєднання не вдається, атрибут `response.code` відсутній. У такому випадку слід використовувати вираз CEL `!has(response.code) || response.code >= 500`.
    {{< /tip >}}

1. Встановіть стандартний фільтр журналу доступу з виразом CEL

    Наступна конфігурація показує журнали доступу лише тоді, коли код відповіді більший або дорівнює 400, або запит було надіслано до BlackHoleCluster чи PassthroughCluster:
    Примітка: `xds.cluster_name` доступний лише з випуску Istio 1.16.2 і вище

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: default-exception-logging
      namespace: istio-system
    spec:
      accessLogging:
      - providers:
        - name: otel
        filter:
          expression: "response.code >= 400 || xds.cluster_name == 'BlackHoleCluster' ||  xds.cluster_name == 'PassthroughCluster' "
    EOF
    {{< /text >}}

1. Фільтруйте журнали доступу для перевірки стану за допомогою виразу CEL

    Наступна конфігурація показує журнали доступу лише тоді, коли вони не згенеровані службою перевірки стану Amazon Route 53. Примітка: `request.useragent` специфічний для HTTP-трафіку, тому, щоб не порушувати роботу TCP-трафіку, потрібно перевірити наявність цього поля. Для отримання додаткової інформації див. [Перевірка типів CEL](https://kubernetes.io/docs/reference/using-api/cel/#type-checking)

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: telemetry.istio.io/v1alpha1
    kind: Telemetry
    metadata:
      name: filter-health-check-logging
    spec:
      accessLogging:
      - providers:
        - name: otel
        filter:
          expression: "!has(request.useragent) || !(request.useragent.startsWith("Amazon-Route53-Health-Check-Service"))"
    EOF
    {{< /text >}}

    Для отримання додаткової інформації див. [Використання виразів для значень](/docs/tasks/observability/metrics/customize-metrics/#use-expressions-for-values)

## Робота з постачальником OpenTelemetry {#work-with-opentelemetry-provider}

Istio підтримує надсилання журналів доступу з протоколом [OpenTelemetry](https://opentelemetry.io/), як пояснено [тут](/docs/tasks/observability/logs/otel-provider).

## Очищення {#cleanup}

1.  Видаліть усі Telemetry API:

    {{< text bash >}}
    $ kubectl delete telemetry --all -A
    {{< /text >}}

1.  Видаліть `loki`:

    {{< text bash >}}
    $ kubectl delete -f @samples/addons/loki.yaml@ -n istio-system
    $ kubectl delete -f @samples/open-telemetry/loki/otel.yaml@ -n istio-system
    {{< /text >}}

1.  Видаліть Istio з кластера:

    {{< text bash >}}
    $ istioctl uninstall --purge --skip-confirmation
    {{< /text >}}
