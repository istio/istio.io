---
title: Отримання метрик в Prometheus
description: Це завдання показує, як запитувати метрики Istio за допомогою Prometheus.
weight: 30
keywords: [telemetry,metrics]
aliases:
    - /uk/docs/tasks/telemetry/querying-metrics/
    - /uk/docs/tasks/telemetry/metrics/querying-metrics/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Це завдання показує, як запитувати метрики Istio за допомогою Prometheus. В рамках цього завдання ви будете використовувати вебінтерфейс для запитів значень метрик.

В якості демонстраційного застосунку використовуватиметься [Bookinfo](/docs/examples/bookinfo/).

## Перед початком {#before-you-begin}

* [Встановіть Istio](/docs/setup) у вашому кластері.
* Встановіть [надбудову Prometheus](/docs/ops/integrations/prometheus/#option-1-quick-start).
* Розгорніть застосунок [Bookinfo](/docs/examples/bookinfo/).

## Отримання метрик з Istio {#querying-istio-metrics}

1. Перевірте, що сервіс `prometheus` працює у вашому кластері.

    У середовищах Kubernetes виконайте наступну команду:

    {{< text bash >}}
    $ kubectl -n istio-system get svc prometheus
    NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
    prometheus   ClusterIP   10.109.160.254   <none>        9090/TCP   4m
    {{< /text >}}

1. Надішліть трафік до мережі.

    Для застосунку Bookinfo відвідайте `http://$GATEWAY_URL/productpage` у вашому вебоглядачі або виконайте наступну команду:

    {{< text bash >}}
    $ curl "http://$GATEWAY_URL/productpage"
    {{< /text >}}

    {{< tip >}}
    `$GATEWAY_URL` — це значення, встановлене в застосунку [Bookinfo](/docs/examples/bookinfo/).
    {{< /tip >}}

1. Відкрийте UI Prometheus.

    У середовищах Kubernetes виконайте наступну команду:

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

    Натисніть **Graph** справа від заголовка Prometheus.

1. Виконайте запит до Prometheus.

    У полі "Expression" у верхній частині вебсторінки введіть текст:

    {{< text plain >}}
    istio_requests_total
    {{< /text >}}

    Потім натисніть кнопку **Execute**.

Результати будуть подібні до:

{{< image link="./prometheus_query_result.png" caption="Результат запиту Prometheus" >}}

Ви також можете переглянути результати запиту графічно, вибравши вкладку Graph під кнопкою **Execute**.

{{< image link="./prometheus_query_result_graphical.png" caption="Результат запиту Prometheus - графічний" >}}

Інші запити для спроби:

*   Загальна кількість усіх запитів до служби `productpage`:

    {{< text plain >}}
    istio_requests_total{destination_service="productpage.default.svc.cluster.local"}
    {{< /text >}}

*   Загальна кількість усіх запитів до `v3` служби `reviews`:

    {{< text plain >}}
    istio_requests_total{destination_service="reviews.default.svc.cluster.local", destination_version="v3"}
    {{< /text >}}

    Цей запит повертає поточну загальну кількість усіх запитів до версії v3 служби `reviews`.

*   Швидкість запитів за останні 5 хвилин до всіх екземплярів служби `productpage`:

    {{< text plain >}}
    rate(istio_requests_total{destination_service=~"productpage.*", response_code="200"}[5m])
    {{< /text >}}

### Про надбудову Prometheus {#about-the-prometheus-addon}

Надбудова Prometheus є сервером Prometheus, який постачається з попередньо налаштованими параметрами для збору метрик Istio. Він забезпечує механізм для постійного зберігання та отримання метрик Istio.

Більше про запити до Prometheus читайте в [документації з запитів](https://prometheus.io/docs/querying/basics/).

## Очищення {#cleanup}

*   Видаліть будь-які процеси `istioctl`, які можуть ще працювати, використовуючи control-C або:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

*   Якщо ви не плануєте досліджувати подальші завдання, дотримуйтесь інструкцій з [очищення Bookinfo](/docs/examples/bookinfo/#cleanup) для завершення роботи застосунку.
