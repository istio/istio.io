---
title: Маршрутизація запитів
description: Це завдання показує, як налаштувати динамічну маршрутизацію запитів до декількох версій мікросервісу.
weight: 10
aliases:
    - /uk/docs/tasks/request-routing.html
keywords: [traffic-management,routing]
owner: istio/wg-networking-maintainers
test: yes
---

Це завдання показує, як налаштувати динамічну маршрутизацію запитів до декількох версій мікросервісу.

{{< boilerplate gateway-api-support >}}

## Перш ніж почати {#before-you-begin}

* Налаштуйте Istio, дотримуючись інструкцій у [керівництві з встановлення](/docs/setup/).

* Розгорніть демонстраційний застосунок [Bookinfo](/docs/examples/bookinfo/).

* Перегляньте документ із концепціями [Управління трафіком](/docs/concepts/traffic-management).

## Про це завдання {#about-this-task}

Демонстраційний застосунок [Bookinfo](/docs/examples/bookinfo/) від Istio складається з чотирьох окремих мікросервісів, кожен з яких має кілька версій. Три різні версії одного з мікросервісів, `reviews`, розгорнуті та працюють одночасно. Щоб ілюструвати проблему, яку це створює, відкрийте `/productpage` застосунку Bookinfo в оглядачі та кілька разів оновіть сторінку. URL-адреса: `http://$GATEWAY_URL/productpage`, де `$GATEWAY_URL` — це зовнішня IP-адреса ingress, як описано в документі [Bookinfo](/docs/examples/bookinfo/#determine-the-ingress-ip-and-port).

Ви помітите, що іноді результат огляду книги містить оцінки зірочками, а іноді ні. Це відбувається тому, що без явного стандартного маршруту для версії сервісу Istio направляє запити на всі доступні версії за принципом кругового опитування.

Початковою метою цього завдання є застосування правил, які перенаправляють весь трафік на `v1` (версія 1) мікросервісів. Пізніше ви застосуєте правило для маршрутизації трафіку на основі значення заголовка HTTP-запиту.

## Маршрутизація на версію 1 {#route-to-version-1}

Щоб спрямовувати маршрути лише на одну версію, налаштуйте правила маршрутизації, які стандартно надсилають трафік на версії сервісів.

{{< warning >}}
Якщо ви ще цього не зробили, дотримуйтесь інструкцій у [визначенні версій сервісу](/docs/examples/bookinfo/#define-the-service-versions).
{{< /warning >}}

1. Виконайте наступну команду, щоб створити правила маршрутизації:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Istio використовує віртуальні сервіси для визначення правил маршрутизації. Виконайте наступну команду, щоб використовувати віртуальні сервіси, які маршрутизуватимуть увесь трафік на `v1` кожного мікросервісу:

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

Оскільки поширення конфігурації є зрештою узгодженим, зачекайте кілька секунд, щоб віртуальні сервіси набули чинності.

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
    - name: reviews-v1
      port: 9080
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2. Перегляньте визначені маршрути за допомогою наступної команди:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash yaml >}}
$ kubectl get virtualservices -o yaml
- apiVersion: networking.istio.io/v1
  kind: VirtualService
  ...
  spec:
    hosts:
    - details
    http:
    - route:
      - destination:
          host: details
          subset: v1
- apiVersion: networking.istio.io/v1
  kind: VirtualService
  ...
  spec:
    hosts:
    - productpage
    http:
    - route:
      - destination:
          host: productpage
          subset: v1
- apiVersion: networking.istio.io/v1
  kind: VirtualService
  ...
  spec:
    hosts:
    - ratings
    http:
    - route:
      - destination:
          host: ratings
          subset: v1
- apiVersion: networking.istio.io/v1
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
{{< /text >}}

Ви можете також переглянути відповідні визначення `subset` за допомогою наступної команди:

{{< text bash >}}
$ kubectl get destinationrules -o yaml
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get httproute reviews -o yaml
...
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Service
    name: reviews
    port: 9080
  rules:
  - backendRefs:
    - group: ""
      kind: Service
      name: reviews-v1
      port: 9080
      weight: 1
    matches:
    - path:
        type: PathPrefix
        value: /
status:
  parents:
  - conditions:
    - lastTransitionTime: "2022-11-08T19:56:19Z"
      message: Route was valid
      observedGeneration: 8
      reason: Accepted
      status: "True"
      type: Accepted
    - lastTransitionTime: "2022-11-08T19:56:19Z"
      message: All references resolved
      observedGeneration: 8
      reason: ResolvedRefs
      status: "True"
      type: ResolvedRefs
    controllerName: istio.io/gateway-controller
    parentRef:
      group: gateway.networking.k8s.io
      kind: Service
      name: reviews
      port: 9080
{{< /text >}}

У статусі ресурсу переконайтеся, що умова `Accepted` має значення `True` для батька `reviews`.

{{< /tab >}}

{{< /tabset >}}

Ви налаштували Istio для переходу до версії `v1` мікросервісів Bookinfo, а саме на сервіс `reviews` версії 1.

## Перевірка нової конфігурації маршрутизації {#test-the-new-routing-configuration}

Ви можете легко перевірити нову конфігурацію, знову оновивши сторінку `/productpage` застосунку Bookinfo у вашому оглядачі. Зверніть увагу, що частина сторінки, присвячена оглядам, відображається без оцінок зірочками, незалежно від того, скільки разів ви оновлюєте сторінку. Це відбувається тому, що ви налаштували Istio для маршрутизації всього трафіку для сервісу оглядів на версію `reviews:v1`, і ця версія сервісу не звертається до сервісу оцінок зірочками.

Ви успішно завершили першу частину цього завдання: маршрутизація трафіку на одну версію сервісу.

## Маршрутизація на основі ідентичності користувача {#route-based-on-user-identity}

Далі ви зміните конфігурацію маршрутизації, щоб увесь трафік від певного користувача маршрутизувався до певної версії сервісу. У цьому випадку весь трафік від користувача на імʼя Jason буде маршрутизований до сервісу `reviews:v2`.

Цей приклад можливий завдяки тому, що сервіс `productpage` додає спеціальний заголовок `end-user` до всіх вихідних HTTP-запитів до сервісу оглядів.

Istio також підтримує маршрутизацію на основі сильно автентифікованого JWT на вхідному шлюзі, детальніше можна ознайомитися в розділі [Маршрутизація на основі заявок JWT](/docs/tasks/security/authentication/jwt-route).

Нагадаємо, `reviews:v2` — це версія, яка включає функцію оцінювання зірками.

1. Виконайте наступну команду, щоб увімкнути маршрутизацію на основі імені користувача:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml@
{{< /text >}}

Ви можете підтвердити створення правила за допомогою наступної команди:

{{< text bash yaml >}}
$ kubectl get virtualservice reviews -o yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
...
spec:
  hosts:
  - reviews
  http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
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
  - matches:
    - headers:
      - name: end-user
        value: jason
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2) На сторінці `/productpage` застосунку Bookinfo увійдіть як користувач `jason`.

   Оновіть сторінку в браузері. Що ви бачите? Зоряні рейтинги з'являються поруч із кожним відгуком.

3) Увійдіть як інший користувач (виберіть будь-яке ім'я на ваш вибір).

   Оновіть сторінку в браузері. Тепер зірки зникли. Це тому, що трафік спрямовується до `reviews:v1` для всіх користувачів, крім Jason.

Ви успішно налаштували Istio для маршрутизації трафіку на основі ідентичності користувача.

## Розуміння того, що сталося {#understanding-what-happened}

У цьому завданні ви використовували Istio для спрямування 100% трафіку до версії `v1` кожного з сервісів Bookinfo. Потім ви встановили правило, щоб вибірково спрямовувати трафік до версії `v2` сервісу `reviews` на основі спеціального заголовка `end-user`, доданого до запиту сервісом `productpage`.

Зверніть увагу, що сервіси Kubernetes, як для Bookinfo, використані в цьому завданні, повинні дотримуватись певних обмежень, щоб скористатися перевагами функцій маршрутизації L7 від Istio. Детальніше дивіться в розділі [Вимоги до Podʼів та Сервісів](/docs/ops/deployment/application-requirements/).

У завданні [перемикання трафіку](/docs/tasks/traffic-management/traffic-shifting) ви будете слідувати тій самій основній схемі, про яку ви дізнались тут, щоб налаштувати правила маршрутизації для поступового перенаправлення трафіку з однієї версії сервісу на іншу.

## Очищення {#cleanup}

1. Видаліть правила маршрутизації застосунків:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-all-v1.yaml@
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete httproute reviews
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

1) Якщо ви не плануєте виконувати подальші завдання, зверніться до інструкції [вилучення Bookinfo](/docs/examples/bookinfo/#cleanup), щоб завершити роботу застосунку.
