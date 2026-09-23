---
title: Інʼєкція збоїв
description: Це завдання показує, як ініціювати збої для перевірки стійкості вашого застосунку.
weight: 20
keywords: [traffic-management,fault-injection]
aliases:
    - /uk/docs/tasks/fault-injection.html
owner: istio/wg-networking-maintainers
test: yes
---

Це завдання показує, як ініціювати збої для перевірки стійкості вашого застосунку.

## Перш ніж почати {#before-you-begin}

* Налаштуйте Istio, дотримуючись інструкцій у [керівництві з встановлення](/docs/setup/).

* Розгорніть демонстраційний застосунок [Bookinfo](/docs/examples/bookinfo/) разом із [типовими правилами призначення](/docs/examples/bookinfo/#apply-default-destination-rules).

* Ознайомтеся з обговоренням інʼєкцій збоїв у концепціях [Управління трафіком](/docs/concepts/traffic-management).

* Застосуйте маршрутизацію версій застосунку, виконавши або завдання
  [маршрутизації запитів](/docs/tasks/traffic-management/request-routing/), або
  виконайте наступні команди:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
    {{< /text >}}

* За допомогою наведеної вище конфігурації потік запитів буде виглядати так:
  * `productpage` → `reviews:v2` → `ratings` (лише для користувача `jason`)
  * `productpage` → `reviews:v1` (для всіх інших)

## Інʼєкція збою затримки HTTP {#injecting-an-http-delay-fault}

Щоб протестувати мікросервіси застосунку Bookinfo на стійкість, введіть затримку в 7 секунд між мікросервісами `reviews:v2` та `ratings` для користувача `jason`. Це тестування виявить помилку, яку навмисно було додано в застосунок Bookinfo.

Зверніть увагу, що сервіс `reviews:v2` має жорстко закодований тайм-аут зʼєднання в 10 секунд для викликів до сервісу `ratings`. Навіть з урахуванням введеної затримки в 7 секунд, ви все одно очікуєте, що потік даних пройде без помилок.

1. Створіть правило інʼєкції збою, щоб затримати трафік від тестового користувача `jason`.

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-test-delay.yaml@
    {{< /text >}}

2. Переконайтесь, що правило створено:

    {{< text bash yaml >}}
    $ kubectl get virtualservice ratings -o yaml
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    ...
    spec:
      hosts:
      - ratings
      http:
      - fault:
          delay:
            fixedDelay: 7s
            percentage:
              value: 100
        match:
        - headers:
            end-user:
              exact: jason
        route:
        - destination:
            host: ratings
            subset: v1
      - route:
        - destination:
            host: ratings
            subset: v1
    {{< /text >}}

    Почекайте кілка секунд для того, щоб нове правило поширилося на всі podʼи.

## Тестування конфігурації затримки {#testing-the-delay-configuration}

1. Відкрийте вебзастосунок [Bookinfo](/docs/examples/bookinfo) у вашому оглядачі.

1. На сторінці `/productpage` увійдіть як користувач `jason`.

    Ви очікуєте, що головна сторінка Bookinfo завантажиться без помилок приблизно за 7 секунд. Однак виникає проблема: розділ Відгуків показує повідомлення про помилку:

    {{< text plain >}}
    Sorry, product reviews are currently unavailable for this book.
    (Вибачте, відгуки про продукт наразі недоступні для цієї книги.)
    {{< /text >}}

1. Перегляньте час відповіді сторінки:

    1. Відкрийте меню *Інструменти розробника* у вашому вебоглядачі.
    1. Відкрийте вкладку Мережа (Network)
    1. Перезавантажте вебсторінку `/productpage`. Ви побачите, що сторінка фактично завантажується приблизно за 6 секунд.

## Розуміння того, що сталося {#understanding-what-happened}

Ви виявили помилку. Жорстко закодовані тайм-аути в мікросервісах призвели до збою сервісу `reviews`.

Як і очікувалося, введена вами затримка у 7 секунд не впливає на сервіс `reviews`, оскільки тайм-аут між сервісами `reviews` і `ratings` жорстко закодований на 10 секунд. Однак існує також жорстко закодований тайм-аут між сервісами `productpage` і `reviews`, який становить 3 секунди + 1 повторна спроба, тобто загалом 6 секунд. В результаті виклик від `productpage` до `reviews` завершується помилкою передчасно через тайм-аут після 6 секунд.

Такі помилки можуть траплятися в типових корпоративних застосунках, де різні команди розробляють різні мікросервіси незалежно одна від одної. Правила інʼєкції збоїв в Istio допомагають виявляти такі аномалії, не впливаючи на кінцевих користувачів.

{{< tip >}}
Зверніть увагу, що тест інʼєкції збоїв обмежений випадками, коли користувач, який увійшов у систему, є `jason`. Якщо ви увійдете як інший користувач, ви не відчуєте жодних затримок.
{{< /tip >}}

## Виправлення помилки {#fixing-the-bug}

Зазвичай проблему вирішують наступним чином:

1. Або збільшується тайм-аут між сервісами `productpage` і `reviews`, або зменшується тайм-аут між сервісами `reviews` і `ratings`.
2. Виправлений мікросервіс зупиняється та перезапускається.
3. Підтверджується, що сторінка `/productpage` повертає відповідь без помилок.

Однак, ви вже маєте виправлення у версії `v3` сервісу `reviews`. У сервісі `reviews:v3` тайм-аут між `reviews` і `ratings` зменшений з 10 секунд до 2,5 секунд, щоб він був сумісний з (меншим за) тайм-аутом низхідних запитів від `productpage`.

Якщо ви перемістите весь трафік до `reviews:v3`, як описано в завданні [перемикання трафіку](/docs/tasks/traffic-management/traffic-shifting/), ви зможете змінити правило затримки на будь-яке значення менше за 2.5 секунди, наприклад, 2 секунди, і підтвердити, що потік даних пройде без помилок.

## Інʼєкція збою HTTP abort {#injecting-an-http-abort-fault}

Ще один спосіб перевірити стійкість мікросервісів — це інʼєкція збою HTTP abort. У цьому завданні ви впровадите HTTP abort для мікросервісів `ratings` для тестового користувача `jason`.

У цьому випадку ви очікуєте, що сторінка завантажиться миттєво і відобразить повідомлення `Ratings service is currently unavailable` (`Сервіс оцінок наразі недоступний`).

1. Створіть правило впровадження помилок для надсилання HTTP-скасування для користувача `jason`:

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-ratings-test-abort.yaml@
    {{< /text >}}

2. Переконайтесь, що правило створено:

    {{< text bash yaml >}}
    $ kubectl get virtualservice ratings -o yaml
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    ...
    spec:
      hosts:
      - ratings
      http:
      - fault:
          abort:
            httpStatus: 500
            percentage:
              value: 100
        match:
        - headers:
            end-user:
              exact: jason
        route:
        - destination:
            host: ratings
            subset: v1
      - route:
        - destination:
            host: ratings
            subset: v1
    {{< /text >}}

## Тестування конфігурації abort {#testing-the-abort-configuration}

1. Відкрийте застосунок [Bookinfo](/docs/examples/bookinfo) у вашому оглядачі.

1. На сторінці `/productpage` увійдіть як користувач `jason`.

  Якщо правило успішно поширилося на всі podʼи, сторінка завантажиться миттєво і зʼявиться повідомлення `Ratings service is currently unavailable` (`Сервіс оцінок наразі недоступний`).

1. Якщо ви вийдете з облікового запису користувача `jason` або відкриєте застосунок Bookinfo в анонімному вікні (або в іншому оглядачі), ви побачите, що `/productpage` все ще викликає `reviews:v1` (який взагалі не викликає `ratings`) для всіх, крім `jason`. Тому ви не побачите жодного повідомлення про помилку.

## Очищення {#cleanup}

1. Видаліть правила маршрутизації застосунку:

    {{< text bash >}}
    $ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
    {{< /text >}}

1. Якщо ви не плануєте виконувати подальші завдання, зверніться до інструкції [вилучення Bookinfo](/docs/examples/bookinfo/#cleanup), щоб завершити роботу застосунку.
