---
title: Розширюйте waypoint з втулками WebAssembly
description: Описує, як зробити віддалені модулі WebAssembly доступними для режиму оточення.
weight: 55
keywords: [extensibility,Wasm,WebAssembly,Ambient]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio надає можливість [розширити свої функціональні можливості за допомогою WebAssembly (Wasm)](/docs/concepts/wasm/). Однією з ключових переваг розширюваності Wasm є те, що розширення можуть завантажуватися динамічно під час роботи. У цьому документі описується, як розширити режим ambient в Istio за допомогою можливостей Wasm. У режимі ambient конфігурація Wasm повинна бути застосована до waypoint-проксі, розгорнутого в кожному просторі імен.

## Перед початком роботи {#before-you-begin}

1. Налаштуйте Istio, дотримуючись інструкцій у [посібнику з початку роботи в режимі ambient](/docs/ambient/getting-started).
2. Розгорніть [демонстраційний застосунок Bookinfo](/docs/ambient/getting-started/deploy-sample-app).
3. [Додайте простір імен default до ambient mesh](/docs/ambient/getting-started/secure-and-visualize).
4. Розгорніть демонстраційний застосунок [curl]({{< github_tree >}}/samples/curl), щоб використовувати його як джерело для надсилання тестових запитів.

    {{< text syntax=bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

## На шлюзі {#at-a-gateway}

Завдяки Kubernetes Gateway API, Istio надає централізовану точку входу для керування трафіком у сервісних мережах. Ми налаштуємо WasmPlugin на рівні шлюзу, забезпечуючи, щоб весь трафік, який проходить через шлюз, підлягав розширеним правилам автентифікації.

### Налаштування втулка WebAssembly для шлюзу {#configure-a-webassembly-plugin-for-a-gateway}

У цьому прикладі ви додасте модуль HTTP [Basic auth](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth) до вашого mesh. Ви налаштуєте Istio на завантаження модуля Basic auth із віддаленого реєстру образів та його завантаження. Він буде налаштований для виконання при викликах до `/productpage`. Ці кроки схожі на ті, що описані в [Розповсюдження модулів WebAssembly](/docs/tasks/extensibility/wasm-module-distribution/), з тією різницею, що використовується поле `targetRefs` замість селекторів міток.

Щоб налаштувати фільтр WebAssembly з віддаленим модулем Wasm, створіть ресурс `WasmPlugin`, націлений на `bookinfo-gateway`:

{{< text syntax=bash snip_id=get_gateway >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         42m
{{< /text >}}

{{< text syntax=bash snip_id=apply_wasmplugin_gateway >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-gateway
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: bookinfo-gateway # ім'я шлюзу, отримане з попереднього кроку
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/productpage"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

Буде виконано інʼєкцію HTTP-фільра на шлюзі як фільтр автентифікації. Агент Istio інтерпретуватиме конфігурацію WasmPlugin, завантажуватиме віддалені модулі Wasm з реєстру образів OCI до локального файлу та вбудовувати HTTP-фільтр на шлюзі, посилаючись на цей файл.

### Перевірка трафіку через Gateway {#verify-the-traffic-via-the-gateway}

1. Перевірте `/productpage` без облікових даних:

    {{< text syntax=bash snip_id=test_gateway_productpage_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    401
    {{< /text >}}

2. Перевірте `/productpage` з обліковими даними, налаштованими у ресурсі WasmPlugin:

    {{< text syntax=bash snip_id=test_gateway_productpage_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" -w "%{http_code}" "http://bookinfo-gateway-istio.default.svc.cluster.local/productpage"
    200
    {{< /text >}}

## На waypoint для всіх сервісів у просторі імен {#at-a-waypoint-for-all-services-in-a-namespace}

Waypoint-проксі відіграють важливу роль у режимі ambient Istio, забезпечуючи безпечну та ефективну комунікацію в межах mesh-мережі. Нижче ми розглянемо, як застосувати конфігурацію Wasm до waypoint, покращуючи функціональність проксі динамічно.

### Розгортання waypoint-проксі {#deploy-a-waypoint-proxy}

Дотримуйтесь [інструкцій з розгортання waypoint](/docs/ambient/usage/waypoint/#deploy-a-waypoint-proxy) для розгортання waypoint-проксі у просторі імен bookinfo.

{{< text syntax=bash snip_id=create_waypoint >}}
$ istioctl waypoint apply --enroll-namespace --wait
{{< /text >}}

Переконайтеся, що трафік досягає сервісу:

{{< text syntax=bash snip_id=verify_traffic >}}
$ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
200
{{< /text >}}

### Налаштування втулка WebAssembly для waypoint {#configure-a-webassembly-plugin-for-a-waypoint}

Щоб налаштувати фільтр WebAssembly з віддаленим модулем Wasm, створіть ресурс `WasmPlugin`, який націлюється на gateway `waypoint`:

{{< text syntax=bash snip_id=get_gateway_waypoint >}}
$ kubectl get gateway
NAME               CLASS            ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio            bookinfo-gateway-istio.default.svc.cluster.local   True         23h
waypoint           istio-waypoint   10.96.202.82                                       True         21h
{{< /text >}}

{{< text syntax=bash snip_id=apply_wasmplugin_waypoint_all >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-at-waypoint
spec:
  targetRefs:
    - kind: Gateway
      group: gateway.networking.k8s.io
      name: waypoint # ім'я gateway, отримане з попереднього кроку
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/productpage"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "YWRtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

### Перегляд сконфігурованого втулка {#view-the-configured-plugin}

{{< text syntax=bash snip_id=get_wasmplugin >}}
$ kubectl get wasmplugin
NAME                     AGE
basic-auth-at-gateway    28m
basic-auth-at-waypoint   14m
{{< /text >}}

### Перевірка трафіку через waypoint-проксі{#verify-the-traffic-via-the-waypoint-proxy}

1. Перевірте внутрішню точку доступу `/productpage` без облікових даних:

    {{< text syntax=bash snip_id=test_waypoint_productpage_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://productpage:9080/productpage
    401
    {{< /text >}}

2. Перевірте внутрішню точку доступу `/productpage` з обліковими даними:

    {{< text syntax=bash snip_id=test_waypoint_productpage_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

## На waypoint для конкретного сервісу {#at-a-waypoint-for-a-specific-service}

Щоб налаштувати фільтр WebAssembly з віддаленим модулем Wasm для конкретного сервісу, створіть ресурс WasmPlugin, який націлюється безпосередньо на цей сервіс.

Створіть `WasmPlugin`, націлений на сервіс `reviews`, щоб розширення застосовувалося лише до цього сервісу. У цій конфігурації автентифікаційний токен і префікс налаштовані спеціально для сервісу reviews, забезпечуючи, що лише запити, спрямовані до нього, підлягають цьому механізму автентифікації.

{{< text syntax=bash snip_id=apply_wasmplugin_waypoint_service >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth-for-service
spec:
  targetRefs:
    - kind: Service
      group: ""
      name: reviews
  url: oci://ghcr.io/istio-ecosystem/wasm-extensions/basic_auth:1.12.0
  phase: AUTHN
  pluginConfig:
    basic_auth_rules:
      - prefix: "/reviews"
        request_methods:
          - "GET"
          - "POST"
        credentials:
          - "ok:test"
          - "MXQtaW4zOmFkbWluMw=="
EOF
{{< /text >}}

### Перевірка трафіку до сервісу {#verify-the-traffic-targeting-the-service}

1. Перевірте внутрішню точку доступу `/productpage` з обліковими даними, налаштованими на загальному проксі `waypoint`:

    {{< text syntax=bash snip_id=test_waypoint_service_productpage_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" http://productpage:9080/productpage
    200
    {{< /text >}}

2. Перевірте внутрішню точку доступу `/reviews` з обліковими даними, налаштованими на конкретному проксі `reviews-svc-waypoint`:

    {{< text syntax=bash snip_id=test_waypoint_service_reviews_with_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null -H "Authorization: Basic MXQtaW4zOmFkbWluMw==" http://reviews:9080/reviews/1
    200
    {{< /text >}}

3. Перевірте внутрішню точку доступу `/reviews` без облікових даних:

    {{< text syntax=bash snip_id=test_waypoint_service_reviews_without_credentials >}}
    $ kubectl exec deploy/curl -- curl -s -w "%{http_code}" -o /dev/null http://reviews:9080/reviews/1
    401
    {{< /text >}}

Виконуючи команду без облікових даних, ви переконаєтеся, що доступ до внутрішньої точки доступу `/productpage` повертає відповідь 401 (неавторизовано), що демонструє очікувану поведінку — неможливість доступу до ресурсу без відповідних автентифікаційних даних.

## Очищення {#cleanup}

1. Видаліть конфігурацію WasmPlugin:

    {{< text syntax=bash snip_id=remove_wasmplugin >}}
    $ kubectl delete wasmplugin basic-auth-at-gateway basic-auth-at-waypoint basic-auth-for-service
    {{< /text >}}

2. Дотримуйтесь [керівництва з видалення в режимі ambient](/docs/ambient/getting-started/#uninstall), щоб видалити Istio та демонстраційні застосунки.
