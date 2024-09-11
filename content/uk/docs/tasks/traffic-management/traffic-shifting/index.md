---
title: Перемикання трафіку
description: Показує, як перенести трафік зі старої версії сервісу на нову.
weight: 30
keywords: [traffic-management,traffic-shifting]
aliases:
    - /uk/docs/tasks/traffic-management/version-migration.html
owner: istio/wg-networking-maintainers
test: yes
---

Це завдання показує, як перенести трафік з одної версії мікросервісу на іншу.

Звичайний випадок використання – це поступове перенесення трафіку зі старої версії мікросервісу на нову. В Istio ви досягаєте цієї мети, конфігуруючи послідовність правил маршрутизації, які перенаправляють відсоток трафіку з одного призначення на інше.

У цьому завданні ви направите 50% трафіку до `reviews:v1` і 50% до `reviews:v3`. Потім ви завершите міграцію, направивши 100% трафіку до `reviews:v3`.

{{< boilerplate gateway-api-support >}}

## Перш ніж почати {#before-you-begin}

* Налаштуйте Istio, дотримуючись інструкцій у [керівництві з встановлення](/docs/setup/).

* Розгорніть демонстраційний застосунок [Bookinfo](/docs/examples/bookinfo/)

* Ознайомтеся з документацією [Управління трафіком](/docs/concepts/traffic-management).

## Застосування маршрутизації на основі коефіцієнтів {#apply-weight-based-routing}

{{< warning >}}
Якщо ви цього ще не зробили, дотримуйтесь інструкцій з [визначення версій сервісу](/docs/examples/bookinfo/#define-the-service-versions).
{{< /warning >}}

1. Щоб почати, виконайте цю команду, щоб направити весь трафік до версії `v1`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_all_v1 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_all_v1 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

1) Відкрийте сайт Bookinfo у вашому оглядачі. URL-адреса: `http://$GATEWAY_URL/productpage`, де `$GATEWAY_URL` — це зовнішня IP-адреса ingress, як пояснено в документації [Bookinfo](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port).

   Зверніть увагу, що частина сторінки з відгуками показується без зірок рейтингу, незалежно від того, скільки разів ви оновлюєте сторінку. Це відбувається тому, що ви налаштували Istio для маршрутизації всього трафіку для сервісу відгуків до версії `reviews:v1`, і ця версія сервісу не використовує сервіс оцінок з зірками.

2) Перенаправте 50% трафіку з `reviews:v1` на `reviews:v3` за допомогою такої команди:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_50_v3 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-50-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_50_v3 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-50-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4) Зачекайте кілька секунд, поки нові правила поширяться, а потім підтвердіть заміну правила:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash outputis=yaml snip_id=verify_config_50_v3 >}}
$ kubectl get virtualservice reviews -o yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
...
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 50
    - destination:
        host: reviews
        subset: v3
      weight: 50
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash outputis=yaml snip_id=gtw_verify_config_50_v3 >}}
$ kubectl get httproute reviews -o yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
...
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: reviews-v1
      port: 9080
      weight: 50
    - group: ""
      kind: Service
      name: reviews-v3
      port: 9080
      weight: 50
    matches:
    - path:
        type: PathPrefix
        value: /
status:
  parents:
  - conditions:
    - lastTransitionTime: "2022-11-10T18:13:43Z"
      message: Route was valid
      observedGeneration: 14
      reason: Accepted
      status: "True"
      type: Accepted
...
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5) Оновіть сторінку `/productpage` у вашому оглядачі, і тепер ви будете бачити *червоні* зірки рейтингів приблизно 50% часу. Це відбувається тому, що версія `v3` сервісу `reviews` використовує сервіс рейтингів з зірками, а версія `v1` — ні.

    {{< tip >}}
    З поточною реалізацією Envoy sidecar вам може знадобитися оновити сторінку `/productpage` багато разів (можливо, 15 чи більше) щоб побачити правильний розподіл. Ви можете змінити правила, щоб направити 90% трафіку до `v3`, щоб частіше бачити червоні зірки.
    {{< /tip >}}

6) Якщо ви вирішите, що мікросервіс `reviews:v3` стабільний, ви можете направити 100% трафіку до `reviews:v3`, застосувавши цей віртуальний сервіс:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=config_100_v3 >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_config_100_v3 >}}
$ kubectl apply -f @samples/bookinfo/gateway-api/route-reviews-v3.yaml@
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7) Оновіть сторінку `/productpage` кілька разів. Тепер ви завжди будете бачити рецензії на книги з *червоними* зірками для кожної рецензії.

## Розуміння того, що відбулося {#understanding-what-happened}

У цьому завданні ви мігрували трафік зі старої версії на нову версію сервісу `reviews`, використовуючи функцію маршрутизації за коефіцієнтами в Istio. Зверніть увагу, що це дуже відрізняється від міграції версій за допомогою функцій розгортання платформ оркестрування контейнерів, які використовують масштабування екземплярів для управління трафіком.

За допомогою Istio ви можете дозволити двом версіям сервісу `reviews` масштабуватися вгору та вниз незалежно одна від одної, не впливаючи на розподіл трафіку між ними.

Для отримання додаткової інформації про маршрутизацію версій з автомасштабуванням, ознайомтеся зі статтею в блозі [Canary Deployment з використанням Istio](/blog/2017/0.1-canary/).

## Очищення {#cleanup}

1. Видаліть правила маршрутизації застосунку:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text syntax=bash snip_id=cleanup >}}
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text syntax=bash snip_id=gtw_cleanup >}}
$ kubectl delete httproute reviews
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

1. Якщо ви не плануєте виконувати подальші завдання, зверніться до інструкції [вилучення Bookinfo](/docs/examples/bookinfo/#cleanup), щоб завершити роботу застосунку.
