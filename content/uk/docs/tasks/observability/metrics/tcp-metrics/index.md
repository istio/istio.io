---
title: Збір метрик для TCP-сервісів
description: Це завдання показує, як налаштувати Istio для збору метрик для TCP-сервісів.
weight: 20
keywords: [telemetry,metrics,tcp]
aliases:
    - /uk/docs/tasks/telemetry/tcp-metrics
    - /uk/docs/tasks/telemetry/metrics/tcp-metrics/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Це завдання показує, як налаштувати Istio для автоматичного збору телеметрії для TCP-сервісів у мережі. Наприкінці цього завдання ви зможете запитувати стандартні TCP-метрики для вашої мережі.

Для прикладу у цьому завданні використовується демонстраційний застосунок [Bookinfo](/docs/examples/bookinfo/).

## Перед початком {#before-you-begin}

* [Встановіть Istio](/docs/setup) у вашому кластері та розгорніть застосунок. Вам також потрібно встановити [Prometheus](/docs/ops/integrations/prometheus/).

* Це завдання передбачає, що застосунок Bookinfo буде розгорнуто в просторі імен `default`. Якщо ви використовуєте інший простір імен, оновіть приклад конфігурації та команди.

## Збір нових даних телеметрії {#collecting-new-telemetry-data}

1.  Налаштуйте Bookinfo для використання MongoDB.

    1.  Встановіть `v2` версію сервісу `ratings`.

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-ratings-v2.yaml@
        serviceaccount/bookinfo-ratings-v2 created
        deployment.apps/ratings-v2 created
        {{< /text >}}

    1.  Встановіть сервіс `mongodb`:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-db.yaml@
        service/mongodb created
        deployment.apps/mongodb-v1 created
        {{< /text >}}

    1.  Зразок Bookinfo розгортає кілька версій кожного мікросервісу, тому почніть зі створення правил призначення які визначають підмножини сервісу, що відповідають кожній версії, та політику балансування навантаження для кожної підмножини.

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all.yaml@
        {{< /text >}}

        Якщо ви ввімкнули взаємний TLS, запустіть наступну команду замість цього:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/destination-rule-all-mtls.yaml@
        {{< /text >}}

        Щоб показати правила призначення, запустіть наступну команду:

        {{< text bash >}}
        $ kubectl get destinationrules -o yaml
        {{< /text >}}

        Почекайте кілька секунд, щоб правила призначення поширилися перед додаванням віртуальних сервісів, які посилаються на ці підмножини, оскільки посилання на підмножини у віртуальних сервісах залежать від правил призначення.

    1.  Створіть віртуальні сервіси `ratings` та `reviews`:

        {{< text bash >}}
        $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-db.yaml@
        virtualservice.networking.istio.io/reviews created
        virtualservice.networking.istio.io/ratings created
        {{< /text >}}

1.  Надішліть трафік до демонстраційного застосунку.

    Для застосунку Bookinfo відвідайте `http://$GATEWAY_URL/productpage` у вашому вебоглядачі або використайте наступну команду:

    {{< text bash >}}
    $ curl http://"$GATEWAY_URL/productpage"
    {{< /text >}}

    {{< tip >}}
    `$GATEWAY_URL` — це значення, встановлене в [Bookinfo](/docs/examples/bookinfo/).
    {{< /tip >}}

2.  Перевірте, чи генеруються та збираються значення TCP-метрик.

    У середовищі Kubernetes налаштуйте порт-форвардинг для Prometheus за допомогою наступної команди:

    {{< text bash >}}
    $ istioctl dashboard prometheus
    {{< /text >}}

    Перегляньте значення TCP-метрик у вікні оглядача Prometheus. Виберіть **Graph**. Введіть метрику `istio_tcp_connections_opened_total` або `istio_tcp_connections_closed_total` і виберіть **Execute**. Таблиця, що показується на вкладці **Console**, містить записи, подібні до:

    {{< text plain >}}
    istio_tcp_connections_opened_total{
    destination_version="v1",
    instance="172.17.0.18:42422",
    job="istio-mesh",
    canonical_service_name="ratings-v2",
    canonical_service_revision="v2"}
    {{< /text >}}

    {{< text plain >}}
    istio_tcp_connections_closed_total{
    destination_version="v1",
    instance="172.17.0.18:42422",
    job="istio-mesh",
    canonical_service_name="ratings-v2",
    canonical_service_revision="v2"}
    {{< /text >}}

## Розуміння збору TCP телеметрії {#understanding-tcp-telemetry-collection}

У цьому завданні ви використали конфігурацію Istio для автоматичного створення та використання метрик для всього трафіку до TCP-сервісу в межах мережі. TCP-метрики для всіх активних зʼєднань стандартно записуються кожні `15s`, і цей таймер можна налаштувати
через `tcpReportingDuration`. Метрики для зʼєднання також записуються наприкінці зʼєднання.

### Атрибути TCP {#tcp-attributes}

Декілька специфічних для TCP атрибутів уможливлюють політику та контроль TCP в Istio. Ці атрибути генеруються проксі Envoy та отримуються з Istio за допомогою метаданих вузла Envoy. Envoy передає метадані вузла до Peer Envoys за допомогою тунелювання на основі ALPN та протоколу на основі префіксів. Ми визначаємо новий протокол `istio-peer-exchange`, який оголошується та пріоритезується клієнтом і sidecars на стороні сервера в мережі. Переговори ALPN визначають протокол як `istio-peer-exchange` для зʼєднань між проксі-серверами, що підтримують Istio, але не між проксі-сервером, що підтримує Istio, та будь-яким іншим проксі.
Цей протокол розширює TCP наступним чином:

1.  TCP-клієнт, як першу послідовність байтів, надсилає рядок магічних байтів та корисне навантаження з префіксом довжини.
2.  TCP-сервер, як першу послідовність байтів, надсилає рядок магічних байтів та корисне навантаження з префіксом довжини. Ці корисні навантаження є серіалізованими метаданими у форматі protobuf.
3.  Клієнт і сервер можуть писати одночасно, а не за порядком. Розширювальний фільтр в Envoy далі обробляє низхідну та висхідну інформацію, поки або рядок магічних байтів не буде знайдено, або все корисне навантаження не буде прочитано.

{{< image link="./alpn-based-tunneling-protocol.svg"
    alt="Attribute Generation Flow for TCP Services in an Istio Mesh."
    caption="TCP Attribute Flow"
    >}}

## Очищення {#cleanup}

*   Видаліть процес `port-forward`:

    {{< text bash >}}
    $ killall istioctl
    {{< /text >}}

* Якщо ви не плануєте досліджувати наступні завдання, зверніться до інструкцій [очищення Bookinfo](/docs/examples/bookinfo/#cleanup) для завершення роботи застосунком.
