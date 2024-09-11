---
title: Використання функцій 7-го рівня
description: Підтримувані функції при використанні L7 waypoint-проксі.
weight: 50
owner: istio/wg-networking-maintainers
test: no
---

Додавши waypoint-проксі до потоку вашого трафіку, ви можете увімкнути більше [функцій Istio](/docs/concepts). Waypoints налаштовуються за допомогою {{< gloss "gateway api" >}}Kubernetes Gateway API{{< /gloss >}}.

{{< warning >}}
Класичні API керування трафіком Istio (virtual service, destination rules тощо) залишаються на стадії Alpha, якщо використовуються з режимом ambient панелі даних.

Змішування конфігурацій Istio classic API та Gateway API не підтримується і призведе до невизначеної поведінки.
{{< /warning >}}

## Прив’язка маршрутів та політик {#route-and-policy-attachment}

Gateway API визначає взаємозв’язок між об’єктами (такими як маршрути та шлюзи) через *прив’язку*.

* Обʼєкти маршруту (такі як [HTTPRoute](https://gateway-api.sigs.k8s.io/api-types/httproute/)) включають спосіб посилання на **батьківські** ресурси, до яких вони хочуть підʼєднатисяя.
* Об’єкти політик вважаються [*метаресурсами*](https://gateway-api.sigs.k8s.io/geps/gep-713/): об’єкти, які розширюють поведінку **цільового** об’єкта стандартним способом.

У таблицях нижче показано тип прив’язки, який налаштований для кожного обʼєкта.

## Маршрутизація трафіку {#traffic-routing}

За наявності розгорнутої waypoint-проксі ви можете використовувати такі типи маршрутів:

|  Назва  | Статус функції | Привʼязка |
| --- | --- | --- |
| [`HTTPRoute`](https://gateway-api.sigs.k8s.io/guides/http-routing/) | Бета | `parentRefs` |
| [`TLSRoute`](https://gateway-api.sigs.k8s.io/guides/tls) | Альфа | `parentRefs` |
| [`TCPRoute`](https://gateway-api.sigs.k8s.io/guides/tcp/) | Альфа | `parentRefs` |

Перегляньте документацію з [керування трафіком](/docs/tasks/traffic-management/), щоб ознайомитись з діапазоном функцій, які можна реалізувати за допомогою цих маршрутів.

## Безпека {#security}

Без встановленого waypoint ви можете використовувати лише [політики безпеки рівня 4](/docs/ambient/usage/l4-policy/). Додавши waypoint, ви отримаєте доступ до наступних політик:

|  Назва  | Статус функції | Привʼязка |
| --- | --- | --- |
| [`AuthorizationPolicy`](/docs/reference/config/security/authorization-policy/) (включаючи функції L7) | Бета | `targetRefs` |
| [`RequestAuthentication`](/docs/reference/config/security/request_authentication/) | Бета | `targetRefs` |

### Розгляд політик авторизації {#considerations}

У режимі ambient, політики авторизації можуть бути або *націлені* (для забезпечення ztunnel), або *прикріплені* (для забезпечення waypoint). Щоб політика авторизації була прикріплена до waypoint, вона повинна мати `targetRef`, який посилається на waypoint або на Service, що використовує цей waypoint.

Ztunnel не може забезпечувати політики L7. Якщо політика з правилами, що відповідають атрибутам L7, буде націлена за допомогою селектора робочого навантаження (а не прикріплена за допомогою `targetRef`), так що вона забезпечується ztunnel, вона стане політикою `DENY` через збій у безпеці.

Дивіться [керівництво з політики L4](/docs/ambient/usage/l4-policy/) для отримання додаткової інформації, включаючи коли прикріпляти політики до Service для випадків використання тільки TCP.

## Спостережуваність {#observability}

[Повний набір метрик трафіку Istio](/docs/reference/config/metrics/) експортується waypoint-проксі.

## Розширення {#extension}

Оскільки waypoint-проксі є розгортанням {{< gloss >}}Envoy{{< /gloss >}}, механізми розширення, доступні для Envoy у {{< gloss "sidecar">}}режимі sidecar{{< /gloss >}}, також доступні для waypoint-проксі.

|  Назва  | Статус функції | Привʼязка |
| --- | --- | --- |
| `WasmPlugin` † | Альфа | `targetRefs` |
| `EnvoyFilter` | Альфа | `targetRefs` |

† [Детальніше про те, як розширити waypoint за допомогою WebAssembly втулків](/docs/ambient/usage/extend-waypoint-wasm/).

Конфігурації розширень вважаються політикою за визначенням Gateway API.

## Сфера дії маршрутів або політик {#scoping-routes-or-policies}

Маршрут або політика можуть бути обмежені для застосування до всього трафіку, що проходить через waypoint-проксі, або лише до конкретних сервісів.

### Прикріплення до всього waypoint-проксі {#attach-to-the-entire-waypoint-proxy}

Щоб прикріпити маршрут або політику до всього waypoint — так, щоб він застосовувався до всього трафіку, зареєстрованого для його використання, — встановіть значення `Gateway` як `parentRefs` або `targetRefs`, залежно від типу.

Щоб обмежити політику `AuthorizationPolicy` для застосування до waypoint з назвою `default` у просторі імен `default`:

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: view-only
  namespace: default
spec:
  targetRefs:
  - kind: Gateway
    group: gateway.networking.k8s.io
    name: default
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["default", "istio-system"]
    to:
    - operation:
        methods: ["GET"]
{{< /text >}}

### Прикріплення до конкретного сервісу {#attach-to-a-specific-service}

Ви також можете прикріпити маршрут до одного або кількох конкретних сервісів у межах waypoint. Встановіть значення `Service` як `parentRefs` або `targetRefs`, залежно від ситуації.

Щоб застосувати маршрут `reviews` HTTPRoute до сервісу `reviews` у просторі імен `default`:

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
  namespace: default
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
      weight: 90
    - name: reviews-v2
      port: 9080
      weight: 10
{{< /text >}}
