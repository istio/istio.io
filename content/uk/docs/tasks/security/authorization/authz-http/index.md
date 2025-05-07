---
title: Трафік HTTP
description: Показує, як налаштувати контроль доступу для HTTP-трафіку.
weight: 10
keywords: [security,access-control,rbac,authorization]
aliases:
    - /uk/docs/tasks/security/role-based-access-control.html
    - /uk/docs/tasks/security/authz-http/
owner: istio/wg-security-maintainers
test: yes
---

Це завдання показує, як налаштувати політику авторизації Istio з дією `ALLOW` для HTTP трафіку в mesh Istio.

## Перед початком {#before-you-begin}

Перед початком цього завдання виконайте наступні кроки:

* Ознайомтеся з [концепціями авторизації Istio](/docs/concepts/security/#authorization).

* Дотримуйтесь [посібника з установки Istio](/docs/setup/install/istioctl/), щоб встановити Istio з увімкненим взаємним TLS.

* Розгорніть [демонстраційний застосунок Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

Після розгортання застосунку Bookinfo перейдіть на сторінку продукту Bookinfo за адресою `http://$GATEWAY_URL/productpage`. На сторінці продукту ви побачите такі розділи:

* **Деталі книги** в середній частині сторінки, що включає: тип книги, кількість сторінок, видавець тощо.
* **Огляди книг** в нижній частині сторінки.

Коли ви оновите сторінку, застосунок показує різні версії оглядів на сторінці продукту. Застосунок представляє огляди у стилі "кругового розподілу" (round robin): червоні зірки, чорні зірки або без зірок.

{{< tip >}}
Якщо ви не бачите очікуваного результату в оглядачі під час виконання завдання, спробуйте ще раз через кілька секунд, оскільки можливі затримки через кешування та інші накладні витрати на поширення.
{{< /tip >}}

{{< warning >}}
Це завдання вимагає увімкненого взаємного TLS, оскільки наступні приклади використовують principal та namespace у політиках.
{{< /warning >}}

## Налаштування контролю доступу для навантажень за допомогою HTTP трафіку {#configure-access-control-for-workloads-using-http-traffic}

Використовуючи Istio, ви можете легко налаштувати контроль доступу для {{< gloss "Робоче навантаження" >}}робочого навантаження{{< /gloss >}} у вашому mesh. Це завдання показує, як налаштувати контроль доступу за допомогою авторизації Istio. Спочатку ви налаштовуєте просту політику `allow-nothing`, яка відхиляє всі запити до навантаження, а потім поступово надаєте більше доступу до навантаження.

1. Запустіть наступну команду для створення політики `allow-nothing` у просторі імен `default`. Політика не має поля `selector`, що застосовує політику до всіх навантажень у просторі імен `default`. Поле `spec:` політики має пусте значення `{}`. Це значення означає, що жоден трафік не дозволяється, ефективно відмовляючи всім запитам.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: allow-nothing
      namespace: default
    spec:
      {}
    EOF
    {{< /text >}}

    Відкрийте в оглядачі сторінку продукту Bookinfo (`http://$GATEWAY_URL/productpage`). Ви повинні побачити `"RBAC: access denied"`. Ця помилка показує, що конфігурована політика `deny-all` працює як потрібно, і в Istio немає жодних правил, які дозволяють доступ до навантажень у mesh.

1. Запустіть наступну команду для створення політики `productpage-viewer`, щоб дозволити доступ з методом `GET` до навантаження `productpage`. Політика не встановлює поле `from` у `rules`, що означає, що дозволені всі джерела, ефективно дозволяючи доступ усім користувачам та навантаженням:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: "productpage-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: productpage
      action: ALLOW
      rules:
      - to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    Відкрийте в браузері сторінку продукту Bookinfo (`http://$GATEWAY_URL/productpage`).
    Тепер ви повинні побачити сторінку "Bookinfo Sample".
    Однак на сторінці можуть з'явитися наступні помилки:

    * `Error fetching product details`
    * `Error fetching product reviews`

    Ці помилки є очікуваними, оскільки ми ще не надали навантаженню `productpage` доступ до навантажень `details` і `reviews`. Далі вам потрібно налаштувати політику для надання доступу до цих навантажень.

1. Запустіть наступну команду для створення політики `details-viewer`, щоб дозволити навантаженню `productpage`, яке надсилає запити за допомогою службового облікового запису  `cluster.local/ns/default/sa/bookinfo-productpage`, отримувати доступ до навантаження `details` через методи `GET`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: "details-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: details
      action: ALLOW
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

1. Запустіть наступну команду для створення політики `reviews-viewer`, щоб дозволити навантаженню `productpage`, яке надсилає запити за допомогою службового облікового запису `cluster.local/ns/default/sa/bookinfo-productpage`, отримувати доступ до навантаження `reviews` через методи `GET`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: "reviews-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: reviews
      action: ALLOW
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-productpage"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    Відкрийте в оглядачі сторінку продукту Bookinfo (`http://$GATEWAY_URL/productpage`). Тепер ви повинні побачити сторінку "Bookinfo Sample" з розділами "Деталі книги" з лівого нижнього кута і "Огляди книг" з правого нижнього кута. Однак у розділі "Огляди книг" може зʼявитися помилка `Ratings service currently unavailable`.

    Це повʼязано з тим, що навантаження `reviews` не має дозволу на доступ до навантаження `ratings`. Щоб розвʼязати цю проблему, потрібно надати навантаженню `reviews` доступ до навантаження `ratings`. Далі налаштуйте політику для надання доступу навантаженню `reviews`.

1. Запустіть наступну команду для створення політики `ratings-viewer`, щоб дозволити навантаженню `reviews`, яке надсилає запити за допомогою службового облікового запису `cluster.local/ns/default/sa/bookinfo-reviews`, отримувати доступ до навантаження `ratings` через методи `GET`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: "ratings-viewer"
      namespace: default
    spec:
      selector:
        matchLabels:
          app: ratings
      action: ALLOW
      rules:
      - from:
        - source:
            principals: ["cluster.local/ns/default/sa/bookinfo-reviews"]
        to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

    Відкрийте в оглядачі сторінку продукту Bookinfo (`http://$GATEWAY_URL/productpage`). Тепер ви повинні побачити "чорні" та "червоні" рейтинги у розділі "Огляди книг".

    **Вітаємо!** Ви успішно застосували політику авторизації для забезпечення контролю доступу для навантажень за допомогою HTTP трафіку.

## Очищення {#clean-up}

Видаліть усі політики авторизації з вашої конфігурації:

{{< text bash >}}
$ kubectl delete authorizationpolicy.security.istio.io/allow-nothing
$ kubectl delete authorizationpolicy.security.istio.io/productpage-viewer
$ kubectl delete authorizationpolicy.security.istio.io/details-viewer
$ kubectl delete authorizationpolicy.security.istio.io/reviews-viewer
$ kubectl delete authorizationpolicy.security.istio.io/ratings-viewer
{{< /text >}}
