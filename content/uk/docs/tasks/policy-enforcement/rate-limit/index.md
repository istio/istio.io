---
title: Увімкнення обмеження швидкості за допомогою Envoy
description: Ця задача показує, як налаштувати Istio для динамічного обмеження трафіку до сервісу.
weight: 10
keywords: [policies,quotas]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Ця задача показує, як використовувати вбудоване обмеження швидкості Envoy для динамічного обмеження трафіку до сервісу Istio. У цій задачі ви застосуєте глобальне обмеження швидкості для сервісу `productpage` через вхідний шлюз, яке дозволяє 1 запит на хвилину для всіх екземплярів сервісу. Додатково, ви застосуєте локальне обмеження швидкості для кожного окремого екземпляра `productpage`, яке дозволяє 4 запити на хвилину. Таким чином, ви забезпечите, що сервіс `productpage` обробляє максимум 1 запит на хвилину через вхідний шлюз, але кожен екземпляр `productpage` може обробляти до 4 запитів на хвилину, що дозволяє будь-який внутрішньомережевий трафік.

## Перед тим як почати {#before-you-begin}

1. Налаштуйте Istio в кластері Kubernetes, дотримуючись інструкцій з [Посібника з установки](/docs/setup/getting-started/).

1. Розгорніть демонстраційний застосунок [Bookinfo](/docs/examples/bookinfo/).

## Обмеження швидкості {#rate-limits}

Envoy підтримує два види обмеження швидкості: глобальне та локальне. Глобальне обмеження швидкості використовує глобальну службу обмеження швидкості gRPC для забезпечення обмеження швидкості для всієї мережі. Локальне обмеження швидкості використовується для обмеження кількості запитів для кожного екземпляра сервісу. Локальне обмеження швидкості можна використовувати разом з глобальним обмеженням швидкості для зменшення навантаження на глобальну службу обмеження швидкості.

У цій задачі ви налаштуєте Envoy для обмеження швидкості трафіку до конкретного шляху сервісу, використовуючи як глобальні, так і локальні обмеження швидкості.

## Глобальне обмеження швидкості {#global-rate-limit}

Envoy можна використовувати для [налаштування глобальних обмежень швидкості](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/global_rate_limiting) для вашої мережі. Глобальне обмеження швидкості в Envoy використовує API gRPC для запиту квоти від служби обмеження швидкості. [Приклад реалізації](https://github.com/envoyproxy/ratelimit) API, написаний на Go з бекендом Redis, використовується нижче.

1. Використовуйте наступний configmap для [налаштування референсної реалізації](https://github.com/envoyproxy/ratelimit#configuration) для обмеження швидкості запитів до шляху `/productpage` на 1 запит/хв, значення `api` для наступного розширеного прикладу і всі інші запити на 100 запитів/хв.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: ratelimit-config
    data:
      config.yaml: |
        domain: ratelimit
        descriptors:
          - key: PATH
            value: "/productpage"
            rate_limit:
              unit: minute
              requests_per_unit: 1
          - key: PATH
            value: "api"
            rate_limit:
              unit: minute
              requests_per_unit: 2
          - key: PATH
            rate_limit:
              unit: minute
              requests_per_unit: 100
    EOF
    {{< /text >}}

1. Створіть глобальну службу обмеження швидкості, яка реалізує [протокол служби обмеження швидкості Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/ratelimit/v3/rls.proto). Для прикладу конфігурації можна скористатися [цим посиланням]({{< github_blob >}}/samples/ratelimit/rate-limit-service.yaml), яке базується на [реалізації](https://github.com/envoyproxy/ratelimit), наданій Envoy.

    {{< text bash >}}
    $ kubectl apply -f @samples/ratelimit/rate-limit-service.yaml@
    {{< /text >}}

1. Застосуйте `EnvoyFilter` до `ingressgateway`, щоб увімкнути глобальне обмеження швидкості, використовуючи глобальний фільтр обмеження швидкості Envoy.

    Патч вставляє `envoy.filters.http.ratelimit` [глобальний фільтр envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/ratelimit/v3/rate_limit.proto#envoy-v3-api-msg-extensions-filters-http-ratelimit-v3-ratelimit) у ланцюг `HTTP_FILTER`. Поле `rate_limit_service` вказує на зовнішню службу обмеження швидкості, `outbound|8081||ratelimit.default.svc.cluster.local` у цьому випадку.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: filter-ratelimit
      namespace: istio-system
    spec:
      workloadSelector:
        # вибрати за міткою в тому самому просторі імен
        labels:
          istio: ingressgateway
      configPatches:
        # Конфігурація Envoy, яку ви хочете змінити
        - applyTo: HTTP_FILTER
          match:
            context: GATEWAY
            listener:
              filterChain:
                filter:
                  name: "envoy.filters.network.http_connection_manager"
                  subFilter:
                    name: "envoy.filters.http.router"
          patch:
            operation: INSERT_BEFORE
            # Додає фільтр обмеження швидкості Envoy до ланцюжка фільтрів HTTP.
            value:
              name: envoy.filters.http.ratelimit
              typed_config:
                "@type": type.googleapis.com/envoy.extensions.filters.http.ratelimit.v3.RateLimit
                # домен може бути будь-яким! Порівняйте його з конфігом сервісу ratelimter
                domain: ratelimit
                failure_mode_deny: true
                timeout: 10s
                rate_limit_service:
                  grpc_service:
                    envoy_grpc:
                      cluster_name: outbound|8081||ratelimit.default.svc.cluster.local
                      authority: ratelimit.default.svc.cluster.local
                  transport_api_version: V3
    EOF
    {{< /text >}}

1. Застосуйте інший `EnvoyFilter` до `ingressgateway`, який визначає конфігурацію маршруту, на якому слід обмежити швидкість. Це додає [дії обмеження швидкості](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/route/v3/route_components.proto#envoy-v3-api-msg-config-route-v3-ratelimit) для будь-якого маршруту з віртуального хосту з назвою `bookinfo.com:80`.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: filter-ratelimit-svc
      namespace: istio-system
    spec:
      workloadSelector:
        labels:
          istio: ingressgateway
      configPatches:
        - applyTo: VIRTUAL_HOST
          match:
            context: GATEWAY
            routeConfiguration:
              vhost:
                name: ""
                route:
                  action: ANY
          patch:
            operation: MERGE
            # Applies the rate limit rules.
            value:
              rate_limits:
                - actions: # any actions in here
                  - request_headers:
                      header_name: ":path"
                      descriptor_key: "PATH"
    EOF
    {{< /text >}}

### Глобальне обмеження швидкості, розширений випадок {#global-rate-limit-advanced-case}

Цей приклад використовує regex для порівняння `/api/*` `uri` і визначає дію обмеження швидкості, яка вставляється на рівні маршруту, використовуючи імʼя http VirtualService. Значення PATH `api`, вставлене в попередньому прикладі, стає актуальним.

1. Змініть VirtualService так, щоб префікс `/api/v1/products` був переміщений на маршрут з імʼям `api`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: bookinfo
    spec:
      gateways:
      - bookinfo-gateway
      hosts:
      - '*'
      http:
      - match:
        - uri:
            exact: /productpage
        - uri:
            prefix: /static
        - uri:
            exact: /login
        - uri:
            exact: /logout
        route:
        - destination:
            host: productpage
            port:
              number: 9080
      - match:
        - uri:
            prefix: /api/v1/products
        route:
        - destination:
            host: productpage
            port:
              number: 9080
        name: api
    EOF
    {{< /text >}}

1. Застосуйте EnvoyFilter, щоб додати дію обмеження швидкості на рівні маршруту для будь-якого продукту з 1 до 99:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: filter-ratelimit-svc-api
      namespace: istio-system
    spec:
      workloadSelector:
        labels:
          istio: ingressgateway
      configPatches:
        - applyTo: HTTP_ROUTE
          match:
            context: GATEWAY
            routeConfiguration:
              vhost:
                name: "*:8080"
                route:
                  name: "api"
          patch:
            operation: MERGE
            value:
              route:
                rate_limits:
                - actions:
                  - header_value_match:
                      descriptor_key: "PATH"
                      descriptor_value: "api"
                      headers:
                        - name: ":path"
                          safe_regex_match:
                            google_re2: {}
                            regex: "/api/v1/products/[1-9]{1,2}"
    EOF
    {{< /text >}}

## Локальне обмеження швидкості {#local-rate-limit}

Envoy підтримує [локальне обмеження швидкості](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_features/local_rate_limiting#arch-overview-local-rate-limit) для зʼєднань L4 і HTTP запитів. Це дозволяє застосовувати обмеження швидкості на рівні екземпляра, без виклику будь-якого іншого сервісу.

Наступний `EnvoyFilter` включає локальне обмеження швидкості для будь-якого трафіку через сервіс `productpage`. Патч `HTTP_FILTER` вставляє `envoy.filters.http.local_ratelimit` [локальний envoy filter](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#config-http-filters-local-rate-limit) у фільтр-ланцюг HTTP зʼєднання менеджера. Локальний фільтр обмеження швидкості [кошик з токенами](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/filters/http/local_ratelimit/v3/local_rate_limit.proto#envoy-v3-api-field-extensions-filters-http-local-ratelimit-v3-localratelimit-token-bucket) налаштовано на дозвіл 4 запитів/хв. Фільтр також налаштований на додавання заголовка `x-local-rate-limit` до запитів, які заблоковані.

{{< tip >}}
Статистика, згадана на [сторінці обмеження швидкості Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/local_rate_limit_filter#statistics), стандартно вимкнена. Ви можете увімкнути її за допомогою наступних анотацій під час розгортання:

{{< text yaml >}}
template:
  metadata:
    annotations:
      proxy.istio.io/config: |-
        proxyStatsMatcher:
          inclusionRegexps:
          - ".*http_local_rate_limit.*"

{{< /text >}}

{{< /tip >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: filter-local-ratelimit-svc
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      app: productpage
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: SIDECAR_INBOUND
        listener:
          filterChain:
            filter:
              name: "envoy.filters.network.http_connection_manager"
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.local_ratelimit
          typed_config:
            "@type": type.googleapis.com/udpa.type.v1.TypedStruct
            type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
            value:
              stat_prefix: http_local_rate_limiter
              token_bucket:
                max_tokens: 4
                tokens_per_fill: 4
                fill_interval: 60s
              filter_enabled:
                runtime_key: local_rate_limit_enabled
                default_value:
                  numerator: 100
                  denominator: HUNDRED
              filter_enforced:
                runtime_key: local_rate_limit_enforced
                default_value:
                  numerator: 100
                  denominator: HUNDRED
              response_headers_to_add:
                - append: false
                  header:
                    key: x-local-rate-limit
                    value: 'true'
EOF
{{< /text >}}

Вищезазначена конфігурація застосовує локальне обмеження швидкості до всіх vhosts/routes. Альтернативно, ви можете обмежити його до конкретного маршруту.

Наступний `EnvoyFilter` включає локальне обмеження швидкості для будь-якого трафіку на порт 9080 сервісу `productpage`. На відміну від попередньої конфігурації, в патчі `HTTP_FILTER` не включено `token_bucket`. `token_bucket` визначено в другому патчі (`HTTP_ROUTE`), який включає `typed_per_filter_config` для фільтра `envoy.filters.http.local_ratelimit`, для маршрутів до віртуального хоста `inbound|http|9080`.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: filter-local-ratelimit-svc
  namespace: istio-system
spec:
  workloadSelector:
    labels:
      app: productpage
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: SIDECAR_INBOUND
        listener:
          filterChain:
            filter:
              name: "envoy.filters.network.http_connection_manager"
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.local_ratelimit
          typed_config:
            "@type": type.googleapis.com/udpa.type.v1.TypedStruct
            type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
            value:
              stat_prefix: http_local_rate_limiter
    - applyTo: HTTP_ROUTE
      match:
        context: SIDECAR_INBOUND
        routeConfiguration:
          vhost:
            name: "inbound|http|9080"
            route:
              action: ANY
      patch:
        operation: MERGE
        value:
          typed_per_filter_config:
            envoy.filters.http.local_ratelimit:
              "@type": type.googleapis.com/udpa.type.v1.TypedStruct
              type_url: type.googleapis.com/envoy.extensions.filters.http.local_ratelimit.v3.LocalRateLimit
              value:
                stat_prefix: http_local_rate_limiter
                token_bucket:
                  max_tokens: 4
                  tokens_per_fill: 4
                  fill_interval: 60s
                filter_enabled:
                  runtime_key: local_rate_limit_enabled
                  default_value:
                    numerator: 100
                    denominator: HUNDRED
                filter_enforced:
                  runtime_key: local_rate_limit_enforced
                  default_value:
                    numerator: 100
                    denominator: HUNDRED
                response_headers_to_add:
                  - append: false
                    header:
                      key: x-local-rate-limit
                      value: 'true'
EOF
{{< /text >}}

## Перевірка результатів {#verify-the-results}

### Перевірка глобального обмеження швидкості {#verify-global-rate-limit}

Надішліть трафік до застосунку Bookinfo. Відвідайте `http://$GATEWAY_URL/productpage` у вашому вебоглядачі або виконайте наступну команду:

{{< text bash >}}
$ for i in {1..2}; do curl -s "http://$GATEWAY_URL/productpage" -o /dev/null -w "%{http_code}\n"; sleep 3; done
200
429
{{< /text >}}

{{< text bash >}}
$ for i in {1..3}; do curl -s "http://$GATEWAY_URL/api/v1/products/${i}" -o /dev/null -w "%{http_code}\n"; sleep 3; done
200
200
429
{{< /text >}}

{{< tip >}}
`$GATEWAY_URL` — це значення, яке встановлено у [застосунку Bookinfo](/docs/examples/bookinfo/).
{{< /tip >}}

Для `/productpage` ви побачите, що перший запит проходить, але кожен наступний запит протягом хвилини отримує відповідь 429. А для `/api/v1/products/*` потрібно буде зробити два запити, з будь-яким числом між 1 і 99, поки не отримаєте відповідь 429 протягом хвилини.

### Перевірка локального обмеження швидкості {#verify-local-rate-limit}

Хоча глобальне обмеження швидкості на шлюзі вхідних запитів обмежує запити до сервісу `productpage` до 1 запиту/хв, локальне обмеження швидкості для екземплярів `productpage` дозволяє 4 запити/хв. Щоб підтвердити це, надішліть внутрішні запити до `productpage` з podʼа `ratings`, використовуючи наступну команду `curl`:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- bash -c 'for i in {1..5}; do curl -s productpage:9080/productpage -o /dev/null -w "%{http_code}\n"; sleep 1; done'

200
200
200
200
429
{{< /text >}}

Ви повинні побачити не більше 4 запитів/хв, які проходять через кожен екземпляр `productpage`.

## Очищення {#cleanup}

{{< text bash >}}
$ kubectl delete envoyfilter filter-ratelimit -nistio-system
$ kubectl delete envoyfilter filter-ratelimit-svc -nistio-system
$ kubectl delete envoyfilter filter-ratelimit-svc-api -nistio-system
$ kubectl delete envoyfilter filter-local-ratelimit-svc -nistio-system
$ kubectl delete cm ratelimit-config
$ kubectl delete -f @samples/ratelimit/rate-limit-service.yaml@
{{< /text >}}
