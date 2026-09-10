---
title: "Представляємо TrafficExtension API"
description: "Новий уніфікований API для розширення проксі Envoy в Istio з WebAssembly та Lua, підтримуючи як sidecar, так і ambient mode."
publishdate: 2026-05-18
attribution: "Liam White - Docusign"
keywords: [istio, wasm, lua, extensibility, ambient, traffic extension]
target_release: "1.30"
---

Розширюваність Mesh завжди була основним принципом архітектури Istio. Надаючи користувачам можливість вбудовувати власну логіку безпосередньо в панель даних, Istio відкриває широкий спектр сценаріїв використання для здійснення власної автентифікації, збору спеціалізованих телеметричних даних або перетворення запитів і відповідей на льоту.

Дотепер єдиним підтримуваним API розширюваності в Istio був `WasmPlugin`, який обслуговував розширення на основі WebAssembly. Користувачі, які хотіли використовувати скрипти Lua, могли це робити лише опосередковано через `EnvoyFilter` — низькорівневий механізм, який є потужним, але його легко налаштувати неправильно.

У версії Istio 1.30 представлено API `TrafficExtension` — єдиний уніфікований API для налаштування розширень Wasm та Lua для sidecars, шлюзів та waypoints на базі Envoy.

## Що таке TrafficExtension? {#what-is-trafficextension}

`TrafficExtension` є новим Istio API, який замінює `WasmPlugin` як основний механізм розширюваності проксі. Він підтримує два типи розширень:

- **Скрипти Lua** — вбудовані скрипти Lua, розміщені безпосередньо в ресурсі, що виконуються в Envoy без необхідності розповсюдження модулів. Найкраще підходять для простої обробки заголовків, ведення журналів та реалізації умовної логіки. Застосовуються лише до трафіку рівня 7 (HTTP).
- **Втулки WebAssembly** — модулі пісочниці Proxy-Wasm, що динамічно завантажуються з реєстрів образів OCI. Підтримують кілька мов (Go, Rust, C++, AssemblyScript) і рекомендуються для складної обробки, застосування політик, збору телеметрії та модифікації корисного навантаження. Застосовуються до трафіку рівня 7 (HTTP) або рівня 4 (TCP).

Див. [сторінку концепцій TrafficExtension](/docs/concepts/extensibility/) для детального керівництва щодо вибору між Lua та Wasm для вашого випадку використання.

## Написання розширень {#writing-extensions}

### Lua

Скрипти Lua пишуться безпосередньо в коді. У наведеному нижче прикладі зчитується заголовок запиту `x-number`, обчислюється, чи є значення парним чи непарним, і додається заголовок відповіді `x-parity`:

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  lua:
    inlineCode: |
      function envoy_on_request(request_handle)
        local number = tonumber(request_handle:headers():get("x-number"))
        if number == nil then return end
        local parity = number % 2 == 0 and "even" or "odd"
        request_handle:streamInfo():dynamicMetadata():set(
          "envoy.filters.http.lua", "parity", parity)
      end
      function envoy_on_response(response_handle)
        local meta = response_handle:streamInfo():dynamicMetadata():get(
          "envoy.filters.http.lua")
        if meta == nil then return end
        response_handle:headers():add("x-parity", meta["parity"])
      end
{{< /text >}}

### WebAssembly

Модулі Wasm завантажуються з реєстрів OCI. Наступний приклад застосує basic authentication до шляху `/productpage`, використовуючи попередньо зібраний втулок Wasm:

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
    pluginConfig:
      basic_auth_rules:
        - prefix: "/productpage"
          request_methods: ["GET", "POST"]
          credentials: ["ok:test"]
{{< /text >}}

Попередньо зібрані розширення Wasm доступні у [репозиторії Istio ecosystem](https://github.com/istio-ecosystem/wasm-extensions). Щоб побудувати власне, дивіться [Proxy-Wasm SDKs](https://github.com/proxy-wasm).

## Таргетинг {#targeting}

`TrafficExtension` підтримує два механізми таргетингу, пристосовані до різних режимів розгортання.

**`selector`** здійснює таргетинг проксі-серверів типу sidecar за допомогою селекторів міток. Ресурс, створений у `istio-system`, діє в межах усього кластера; ресурс у будь-якому іншому просторі імен застосовується лише до робочих навантажень у цьому просторі імен.

**`targetRefs`** здійснює таргетин безпосередньо на шлюзи (Gateways) або сервіси (Services) — це необхідно для проксі-серверів типу waypoint, що працюють у режимі ambient, які не зіставляються з робочими навантаженнями за допомогою селекторів на основі міток. Те саме розширення `basic-auth`, застосоване до шлюзу в режимі ambient, виглядає так:

{{< text yaml >}}
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: basic-auth-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway
  phase: AUTHN
  wasm:
    url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
    pluginConfig:
      basic_auth_rules:
        - prefix: "/productpage"
          request_methods: ["GET", "POST"]
          credentials: ["ok:test"]
{{< /text >}}

## Порядок виконання розширень {#ordering-extensions}

Коли декілька розширень таргетують один проксі, `phase` та `priority` контролюють порядок виконання.

`phase` розміщує розширення в відомій точці ланцюга фільтрів:

| Фаза | Позиція |
|-------|----------|
| `AUTHN` | Фаза автентифікації |
| `AUTHZ` | Фаза авторизації |
| `STATS` | Фаза статистики/спостереження |
| *(unset)* | Біля маршрутизатора (за замовчуванням) |

У межах фази `priority` розвʼязує конфлікти — вищі значення виконуються раніше в шляху запиту.

## Міграція з WasmPlugin {#migrating-from-wasmplugin}

`TrafficExtension` замінює `WasmPlugin` як рекомендовану API розширюваності. Наявні `WasmPlugin` ресурси є повністю сумісними з новою API — насправді, Istio тепер внутрішньо перетворює всі `WasmPlugin` ресурси у `TrafficExtension` ресурси перед генерацією конфігурації для розподілу до Envoy.

Немає обовʼязкової міграції у Istio 1.30. Коли ви готові до міграції, [TrafficExtension API reference](/docs/reference/config/proxy_extensions/traffic_extension/) містить повну специфікацію.

## Як почати {#get-started}

- [Концепції TrafficExtension](/docs/concepts/extensibility/) — пояснення типів розширень, таргетингу та порядку виконання
- [Виконання WebAssembly модулів](/docs/tasks/extensibility/wasm-modules/) — покрокове завдання для sidecar deployments
- [Виконання Lua скриптів](/docs/tasks/extensibility/lua-scripts/) — покрокове завдання для sidecar deployments
- [Розширення waypoints за допомогою WebAssembly](/docs/ambient/usage/extend-waypoint-wasm/) — керівництво для ambient mode
- [Розширення waypoints за допомогою Lua](/docs/ambient/usage/extend-waypoint-lua/) — керівництво для ambient mode

## Спільнота {#community}

`TrafficExtension` перебуває на стадії альфа-тестування, і ваші відгуки безпосередньо впливають на формування API до його стабілізації. Якщо ви зіткнулися з проблемами або маєте пропозиції, будь ласка, [створіть тікет на GitHub](https://github.com/istio/istio/issues) або долучіться до обговорення на [каналі Istio у Slack](https://slack.istio.io/). Ми будемо раді дізнатися, як ви використовуєте розширення проксі у своїх розгортаннях.

Готові долучитися? Відвідайте [сторінку спільноти](/get-involved/) Istio.

