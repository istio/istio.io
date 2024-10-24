---
title: Розподіл WebAssembly модулів
description: Описує, як зробити віддалені WebAssembly модулі доступними в мещі.
weight: 10
aliases:
  - /uk/help/ops/extensibility/distribute-remote-wasm-module
  - /uk/docs/ops/extensibility/distribute-remote-wasm-module
  - /uk/ops/configuration/extensibility/wasm-module-distribution
keywords: [extensibility,Wasm,WebAssembly]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Istio надає можливість [розширювати функціональність проксі за допомогою WebAssembly (Wasm)](/blog/2020/wasm-announce/). Однією з основних переваг розширюваності Wasm є те, що розширення можуть завантажуватися динамічно під час виконання. Ці розширення спочатку повинні бути розподілені до проксі Envoy. Istio робить це можливим, дозволяючи агенту проксі динамічно завантажувати модулі Wasm.

## Налаштування тестового застосунку {#setup-the-test-application}

Перш ніж почати це завдання, будь ласка, розгорніть [демонстраційний застосунок Bookinfo](/docs/examples/bookinfo/#deploying-the-application).

## Налаштування модулів Wasm {#configure-wasm-modules}

У цьому прикладі ви додасте розширення HTTP Basic auth до вашого mesh. Ви налаштуєте Istio для завантаження [модуля Basic auth](https://github.com/istio-ecosystem/wasm-extensions/tree/master/extensions/basic_auth) з віддаленого реєстру образів і завантаження його. Він буде налаштований для роботи при викликах до `/productpage`.

Щоб налаштувати фільтр WebAssembly з віддаленим модулем Wasm, створіть ресурс `WasmPlugin`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: extensions.istio.io/v1alpha1
kind: WasmPlugin
metadata:
  name: basic-auth
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
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

HTTP фільтр буде впроваджено в проксі ingress gateway як фільтр автентифікації. Агент Istio інтерпретує конфігурацію `WasmPlugin`, завантажує віддалені модулі Wasm з реєстру образів OCI до локального файлу і впроваджує HTTP фільтр в Envoy, посилаючись на цей файл.

{{< idea >}}
Якщо ресурс `WasmPlugin` створений у конкретному просторі імен, окрім `istio-system`, будуть налаштовані podʼи в цьому просторі імен. Якщо ресурс створено в просторі імен `istio-system`, будуть впливати всі простори імен.
{{< /idea >}}

## Перевірка налаштованого модуля Wasm {#check-the-configured-wasm-module}

1. Перевірте `/productpage` без облікових даних

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    401
    {{< /text >}}

1. Перевірте `/productpage` з обліковими даними

    {{< text bash >}}
    $ curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Basic YWRtaW4zOmFkbWluMw==" "http://$INGRESS_HOST:$INGRESS_PORT/productpage"
    200
    {{< /text >}}

Для отримання додаткових прикладів використання API `WasmPlugin`, будь ласка, ознайомтеся з [документацією API](/docs/reference/config/proxy_extensions/wasm-plugin/).

## Очищення модулів Wasm {#clean-up-wasm-modules}

{{< text bash >}}
$ kubectl delete wasmplugins.extensions.istio.io -n istio-system basic-auth
{{< /text >}}

## Моніторинг розподілу модулів Wasm {#monitor-wasm-module-distribution}

Є кілька статистик, які відстежують статус розподілу віддалених модулів Wasm.

Наступні статистики збираються агентом Istio:

- `istio_agent_wasm_cache_lookup_count`: кількість перевірок кешу для віддаленого завантаження Wasm.
- `istio_agent_wasm_cache_entries`: кількість перетворень конфігурації Wasm і результатів, включаючи успіх, відсутність віддаленого завантаження, помилки маркування, помилки віддаленого завантаження та пропущені підказки віддаленого завантаження.
- `istio_agent_wasm_config_conversion_duration_bucket`: Загальний час у мілісекундах, який агент istio витрачає на перетворення конфігурації для модулів Wasm.
- `istio_agent_wasm_remote_fetch_count`: кількість віддалених завантажень Wasm і результатів, включаючи успіх, помилки завантаження та невідповідність контрольної суми.

Якщо конфігурація фільтра Wasm відхиляється через помилку завантаження або інші причини, istiod також видасть `pilot_total_xds_rejects` з міткою типу `type.googleapis.com/envoy.config.core.v3.TypedExtensionConfig`.

## Розробка розширення Wasm {#develop-a-wasm-extension}

Щоб дізнатися більше про розробку модулів Wasm, будь ласка, ознайомтеся з посібниками, наданими в репозиторії [`istio-ecosystem/wasm-extensions`](https://github.com/istio-ecosystem/wasm-extensions), який підтримується спільнотою Istio та використовується для розробки розширення Telemetry Wasm від Istio:

- [Напишіть, протестуйте, розгорніть і підтримуйте розширення Wasm за допомогою C++](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-a-wasm-extension-with-cpp.md)
- [Створіть сумісні з втулком Istio Wasm OCI-образи](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/how-to-build-oci-images.md)
- [Напишіть юніт тести для розширень Wasm на C++](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-cpp-unit-test.md)
- [Напишіть інтеграційні тести для розширень Wasm](https://github.com/istio-ecosystem/wasm-extensions/blob/master/doc/write-integration-test.md)

## Обмеження {#limitations}

Є відомі обмеження з цим механізмом розподілу модулів, які будуть усунені в майбутніх версіях:

- Підтримуються лише HTTP фільтри.
