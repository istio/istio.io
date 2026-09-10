---
title: Виконання скриптів Lua
description: Описує, як розширити функціональність проксі за допомогою вбудованих скриптів Lua.
weight: 15
keywords: [extensibility,Lua,TrafficExtension]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio надає можливість розширювати функціональність проксі за допомогою вбудованих скриптів [Lua](https://www.lua.org/) через API [`TrafficExtension`](/docs/reference/config/proxy_extensions/traffic_extension/). Фільтри Lua є легкою альтернативою [WebAssembly](/docs/tasks/extensibility/wasm-modules/) для простих перетворень запитів і відповідей&nbsp;— скрипт вбудовується безпосередньо в ресурс і виконується в проксі Envoy, без необхідності розповсюдження модулів.

## Перед початком {#before-you-begin}

Розгорніть [демонстраційний застосунок Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

## Налаштування скрипта Lua {#configure-a-lua-script}

Скрипт Lua повинен визначати одну або обидві з наступних функцій:

- `envoy_on_request(request_handle)`: викликається для кожного вхідного запиту
- `envoy_on_response(response_handle)`: викликається для кожної вихідної відповіді

Дескриптори надають доступ до заголовків, тіла, метаданих і журналювання. Повний API див. у [документації фільтра Lua для Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/lua_filter).

У цьому прикладі ви додасте фільтр Lua до ingress gateway, який читає заголовок запиту `x-number` і відповідає заголовком `x-parity`, що вказує, чи є значення `odd` чи `even`. Значення зчитується під час обробки запиту та зберігається в динамічних метаданих, щоб воно було доступним під час запису заголовка відповіді:

{{< text syntax=bash snip_id=apply_parity >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  phase: AUTHN
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
EOF
{{< /text >}}

## Перевірка скрипта Lua {#verify-the-lua-script}

[Визначте IP-адресу та порт ingress](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports).

Надішліть запит із заголовком `x-number` і перевірте, що у відповіді встановлено `x-parity`:

{{< text syntax=bash snip_id=verify_parity_even >}}
$ curl -s -o /dev/null -D - -H "x-number: 42" "http://$INGRESS_HOST:$INGRESS_PORT/productpage" | grep x-parity
x-parity: even
{{< /text >}}

{{< text syntax=bash snip_id=verify_parity_odd >}}
$ curl -s -o /dev/null -D - -H "x-number: 7" "http://$INGRESS_HOST:$INGRESS_PORT/productpage" | grep x-parity
x-parity: odd
{{< /text >}}

## Впорядкування та область застосування {#ordering-and-scoping}

Коли кілька ресурсів `TrafficExtension` націлені на одне й те саме робоче навантаження, порядок виконання контролюється за допомогою `phase` та `priority`.

- **`phase`** визначає загальну позицію в ланцюжку фільтрів: `AUTHN`, `AUTHZ` або `STATS`. Розширення без фази вставляються ближче до кінця ланцюжка, перед маршрутизатором.
- **`priority`** визначає порядок у межах однієї фази. Вищі значення виконуються першими.

Поле `match` обмежує `TrafficExtension` певним трафіком за режимом і портом:

{{< text yaml >}}
spec:
  match:
  - mode: SERVER
    ports:
    - number: 8080
{{< /text >}}

Дійсні режими: `CLIENT` (вихідний), `SERVER` (вхідний) та `CLIENT_AND_SERVER` (обидва, за замовчуванням).

## Очищення {#clean-up}

{{< text syntax=bash snip_id=clean_up >}}
$ kubectl delete trafficextension -n istio-system parity
{{< /text >}}
