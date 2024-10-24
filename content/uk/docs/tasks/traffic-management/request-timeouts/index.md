---
title: Тайм-аути запитів
description: У цьому завданні показано, як налаштувати таймаути запитів в Envoy за допомогою Istio.
weight: 40
aliases:
    - /docs/tasks/request-timeouts.html
keywords: [traffic-management,timeouts]
owner: istio/wg-networking-maintainers
test: yes
---

У цьому завданні показано, як налаштувати таймаути запитів в Envoy за допомогою Istio.

{{< boilerplate gateway-api-support >}}

## Перш ніж почати {#before-you-begin}

* Налаштуйте Istio, дотримуючись інструкцій у [керівництві з встановлення](/docs/setup/).

* Розгорніть демонстраційний застосунок [Bookinfo](/docs/examples/bookinfo/) включаючи [версії сервісів](/docs/examples/bookinfo/#define-the-service-versions).

## Тайм-аут запитів {#request-timeouts}

Тайм-аут для HTTP запитів можна вказати, використовуючи поле тайм-ауту в правилі маршрутизації. Стандартно тайм-аут запиту вимкнено, але в цьому завданні ви перевизначите тайм-аут сервісу `reviews` встановивши його на пів секунди. Щоб побачити його ефект, ви також вводите штучну затримку у 2 секунди в запитах до сервісу `ratings`.

1.  Направте запити до версії `v2` сервісу `reviews`, тобто версії, яка викликає сервіс `ratings`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v2
      port: 9080
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Додайте 2-секундну затримку для викликів сервісу `ratings`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percentage:
          value: 100
        fixedDelay: 2s
    route:
    - destination:
        host: ratings
        subset: v1
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Gateway API поки що не підтримує інʼєкції збоїв, тому нам потрібно використовувати Istio `VirtualService` для додавання затримки:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      delay:
        percentage:
          value: 100
        fixedDelay: 2s
    route:
    - destination:
        host: ratings
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3) Відкрийте URL-адресу Bookinfo `http://$GATEWAY_URL/productpage` у вашому оглядачі, де `$GATEWAY_URL` —це зовнішня IP-адреса ingress, як пояснено в документації [Bookinfo](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port).

    Ви повинні побачити, що застосунок Bookinfo працює нормально (з показом рейтингу зірками), але є затримка у 2 секунди щоразу, коли ви оновлюєте сторінку.

4) Тепер додайте тайм-аут запиту в пів секунди для викликів до сервісу `reviews`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v2
    timeout: 0.5s
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - group: ""
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - name: reviews-v2
      port: 9080
    timeouts:
      request: 500ms
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  Оновіть сторінку Bookinfo.

    Тепер ви повинні побачити, що вона повертається за приблизно 1 секунду, замість 2, і відгуки недоступні.

    {{< tip >}}
    Причина, чому відповідь займає 1 секунду, навіть якщо тайм-аут налаштований на пів секунди, полягає в тому, що в сервісі `productpage` є жорстко закодоване повторне звернення, тому він викликає сервіс `reviews`, що вичерпав тайм-аут, двічі перед поверненням.
    {{< /tip >}}

## Розуміння того, що відбулося {#understanding-what-happened}

У цьому завданні ви використовували Istio для встановлення тайм-ауту запитів до мікросервісу `reviews` на пів секунди. Стандартно тайм-аут запитів вимкнено. Оскільки сервіс `reviews` потім викликає сервіс `ratings` при обробці запитів, ви використали Istio для введення 2-секундної затримки у виклики до `ratings`, щоб спричинити затримку сервісу `reviews` більше ніж пів секунди, і, відповідно, ви могли побачити тайм-аут в дії.

Ви спостерігали, що замість відображення відгуків сторінка продукту Bookinfo (яка викликає сервіс `reviews`, щоб заповнити сторінку) показувала повідомлення: "Sorry, product reviews are currently unavailable for this book" ("Вибачте, відгуки про цей товар наразі недоступні"). Це сталося через отримання помилки тайм-ауту від сервісу `reviews`.

Якщо ви переглянете [завдання з інʼєкції збоїв](/docs/tasks/traffic-management/fault-injection/), ви дізнаєтеся, що мікросервіс `productpage` також має власний рівень тайм-ауту (3 секунди) для викликів до мікросервісу `reviews`. Зверніть увагу, що в цьому завданні ви використовували правило маршрутизації Istio для встановлення тайм-ауту на пів секунди. Якби ви встановили тайм-аут на щось більше, ніж 3 секунди (наприклад, 4 секунди), тайм-аут не мав би жодного ефекту, оскільки більш обмежувальний з двох має перевагу. Більше деталей можна знайти [тут](/docs/concepts/traffic-management/#network-resilience-and-testing).

Ще одне, що варто зазначити про тайм-аути в Istio, це те, що, крім перевизначення їх у правилах маршрутизації, як ви зробили в цьому завданні, їх також можна перевизначити на основі кожного запиту, якщо застосунок додає заголовок `x-envoy-upstream-rq-timeout-ms` у вихідні запити. У заголовку тайм-аут вказується в мілісекундах замість секунд.

## Очищення {#cleanup}

*   Видалити правила маршрутизації застосунків:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete httproute reviews
$ kubectl delete virtualservice ratings
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

* Якщо ви не плануєте виконувати подальші завдання, зверніться до інструкції [вилучення Bookinfo](/docs/examples/bookinfo/#cleanup), щоб завершити роботу застосунку.
