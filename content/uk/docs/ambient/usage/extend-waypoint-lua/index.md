---
title: Розширення waypoint за допомогою Lua-скриптів
description: Описує, як розширити проксі waypoint у режимі ambient за допомогою вбудованих Lua-скриптів.
weight: 56
keywords: [extensibility,Lua,TrafficExtension,Ambient]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio надає можливість розширювати проксі waypoint за допомогою вбудованих скриптів [Lua](https://www.lua.org/) через API [`TrafficExtension`](/docs/reference/config/proxy_extensions/traffic_extension/). У режимі ambient ресурси `TrafficExtension` мають бути прикріплені до проксі waypoint за допомогою `targetRefs`.

## Перед початком {#before-you-begin}

1. Налаштуйте Istio, дотримуючись [посібника з початку роботи в режимі ambient](/docs/ambient/getting-started).
1. Розгорніть [приклад застосунку Bookinfo](/docs/ambient/getting-started/deploy-sample-app).
1. [Додайте типовий простір імен до ambient мережі](/docs/ambient/getting-started/secure-and-visualize).
1. Розгорніть приклад застосунку [curl]({{< github_tree >}}/samples/curl) як тестове джерело:

    {{< text syntax=bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

## На шлюзі {#at-a-gateway}

Отримайте імʼя шлюзу:

{{< text syntax=bash snip_id=get_gateway >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
{{< /text >}}

Створіть `TrafficExtension`, який націлюється на `bookinfo-gateway`, з фільтром парності Lua. Фільтр читає заголовок запиту `x-number` і додає заголовок відповіді `x-parity`, який вказує, чи є значення `odd` чи `even`. Значення зберігається в динамічних метаданих під час обробки запиту, щоб воно було доступним під час запису заголовка відповіді:

{{< text syntax=bash snip_id=apply_lua_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway
  phase: STATS
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

### Перевірка трафіку через шлюз {#verify-the-traffic-via-the-gateway}

{{< text syntax=bash snip_id=test_gateway_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 4" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage" | grep x-parity
x-parity: even
{{< /text >}}

## На waypoint, для всіх сервісів у просторі імен {#at-a-waypoint-for-all-services-in-a-namespace}

### Розгортання проксі waypoint {#deploy-a-waypoint-proxy}

Дотримуйтеся [інструкцій з розгортання waypoint](/docs/ambient/usage/waypoint/#deploy-a-waypoint-proxy), щоб розгорнути проксі waypoint у просторі імен bookinfo:

{{< text syntax=bash snip_id=create_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
{{< /text >}}

Перевірте, що трафік досягає сервісу:

{{< text syntax=bash snip_id=verify_traffic >}}
$ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
200
{{< /text >}}

Отримайте імʼя шлюзу waypoint:

{{< text syntax=bash snip_id=get_gateway_waypoint >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
{{< /text >}}

Створіть `TrafficExtension`, який орієнтований на waypoint:

{{< text syntax=bash snip_id=apply_lua_waypoint_all >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint
  phase: STATS
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

### Перевірка трафіку через проксі waypoint {#verify-the-traffic-via-the-waypoint-proxy}

{{< text syntax=bash snip_id=test_waypoint_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 7" http://productpage:9080/productpage | grep x-parity
x-parity: odd
{{< /text >}}

## На waypoint, для конкретного сервісу {#at-a-waypoint-for-a-specific-service}

Видаліть фільтр для всього простору імен і замініть його на той, що націлюється лише на сервіс `reviews`:

{{< text syntax=bash snip_id=remove_waypoint_parity >}}
$ kubectl delete trafficextension parity-at-waypoint
{{< /text >}}

Створіть `TrafficExtension`, який націлюється безпосередньо на сервіс `reviews`, щоб фільтр застосовувався лише до трафіку, призначеного для цього сервісу:

{{< text syntax=bash snip_id=apply_lua_waypoint_service >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: TrafficExtension
metadata:
  name: parity-for-reviews
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  match:
  - mode: SERVER
  phase: STATS
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

### Перевірка трафіку, призначеного для сервісу {#verify-the-traffic-targeting-the-service}

{{< text syntax=bash snip_id=test_waypoint_service_parity >}}
$ kubectl exec deploy/curl -- curl -s -o /dev/null -D - -H "x-number: 3" http://reviews:9080/reviews/1 | grep x-parity
x-parity: odd
{{< /text >}}

## Очищення {#cleanup}

1. Видаліть ресурси `TrafficExtension`:

    {{< text syntax=bash snip_id=remove_traffic_extensions >}}
    $ kubectl delete trafficextension parity-at-gateway parity-for-reviews
    {{< /text >}}

1. Дотримуйтеся [посібника з видалення в режимі ambient](/docs/ambient/getting-started/#uninstall), щоб видалити Istio та прикладні тестові застосунки.
