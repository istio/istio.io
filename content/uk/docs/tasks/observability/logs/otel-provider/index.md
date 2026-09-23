---
title: OpenTelemetry
description: Це завдання показує, як налаштувати проксі Envoy для надсилання логів доступу з використанням OpenTelemetry collector.
weight: 30
keywords: [telemetry,logs,телеметрія,логи]
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Проксі Envoy можна налаштувати для експорту [логів доступу](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage) у [форматі OpenTelemetry](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/access_loggers/open_telemetry/v3/logs_service.proto). У цьому прикладі проксі надсилають логи доступу до [OpenTelemetry collector](https://github.com/open-telemetry/opentelemetry-collector), який налаштований для виведення логів у стандартний вивід. Стандартний вивід OpenTelemetry collector можна переглянути за допомогою команди `kubectl logs`.

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

{{< boilerplate start-otel-collector-service >}}

## Увімкнення логування доступу Envoy {#enable-envoys-access-logging}

Щоб увімкнути логування доступу, використовуйте [Telemetry API](/docs/tasks/observability/telemetry/).

Редагуйте `MeshConfig`, щоб додати постачальника OpenTelemetry з іменем `otel`. Це передбачає додавання розширення:

{{< text yaml >}}
extensionProviders:
- name: otel
  envoyOtelAls:
    service: opentelemetry-collector.observability.svc.cluster.local
    port: 4317
{{< /text >}}

Кінцева конфігурація виглядатиме приблизно так:

{{< text yaml >}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: istio
  namespace: istio-system
data:
  mesh: |-
    accessLogFile: /dev/stdout
    defaultConfig:
      discoveryAddress: istiod.istio-system.svc:15012
      proxyMetadata: {}
      tracing:
        zipkin:
          address: zipkin.istio-system:9411
    enablePrometheusMerge: true
    extensionProviders:
    - name: otel
      envoyOtelAls:
        service: opentelemetry-collector.observability.svc.cluster.local
        port: 4317
    rootNamespace: istio-system
    trustDomain: cluster.local
  meshNetworks: 'networks: {}'
{{< /text >}}

Додайте ресурс Telemetry, який вказує Istio надсилати логи доступу до OpenTelemetry collector.

{{< text bash >}}
$ cat <<EOF | kubectl apply -n default -f -
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: curl-logging
spec:
  selector:
    matchLabels:
      app: curl
  accessLogging:
    - providers:
      - name: otel
EOF
{{< /text >}}

Наведений приклад використовує постачальника логів `otel`, і ми не налаштовуємо нічого, крім стандартних параметрів.

Подібну конфігурацію можна також застосувати до окремого простору імен або робочого навантаження для точного контролю логування.

Детальнішу інформацію про використання Telemetry API можна знайти в [огляді Telemetry API](/docs/tasks/observability/telemetry/).

### Використання Mesh Config {#using-mesh-config}

Якщо ви використовували конфігурацію `IstioOperator` для встановлення Istio, додайте наступне поле до вашої конфігурації:

{{< text yaml >}}
spec:
  meshConfig:
    accessLogFile: /dev/stdout
    extensionProviders:
    - name: otel
      envoyOtelAls:
        service: opentelemetry-collector.observability.svc.cluster.local
        port: 4317
    defaultProviders:
      accessLogging:
      - envoy
      - otel
{{< /text >}}

Інакше додайте відповідне налаштування до вашої оригінальної команди `istioctl install`, наприклад:

{{< text syntax=bash snip_id=none >}}
$ istioctl install -f <your-istio-operator-config-file>
{{< /text >}}

## Стандартний формат логу доступу {#default-access-log-format}

Istio використовуватиме наступний стандартний формат логу доступу, якщо параметр `accessLogFormat` не вказаний:

{{< text plain >}}
[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\"
\"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n
{{< /text >}}

У таблиці нижче наведено приклад використання стандартного формату логів для запиту від `curl` до `httpbin`:

| Оператор логів | лог доступу у curl | лог доступу у httpbin |
|----------------|--------------------|-----------------------|
| `[%START_TIME%]` | `[2020-11-25T21:26:18.409Z]` | `[2020-11-25T21:26:18.409Z]`
| `\"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\"` | `"GET /status/418 HTTP/1.1"` | `"GET /status/418 HTTP/1.1"`
| `%RESPONSE_CODE%` | `418` | `418`
| `%RESPONSE_FLAGS%` | `-` | `-`
| `%RESPONSE_CODE_DETAILS%` | `via_upstream` | `via_upstream`
| `%CONNECTION_TERMINATION_DETAILS%` | `-` | `-`
| `\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\"` | `"-"` | `"-"`
| `%BYTES_RECEIVED%` | `0` | `0`
| `%BYTES_SENT%` | `135` | `135`
| `%DURATION%` | `4` | `3`
| `%RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)%` | `4` | `1`
| `\"%REQ(X-FORWARDED-FOR)%\"` | `"-"` | `"-"`
| `\"%REQ(USER-AGENT)%\"` | `"curl/7.73.0-DEV"` | `"curl/7.73.0-DEV"`
| `\"%REQ(X-REQUEST-ID)%\"` | `"84961386-6d84-929d-98bd-c5aee93b5c88"` | `"84961386-6d84-929d-98bd-c5aee93b5c88"`
| `\"%REQ(:AUTHORITY)%\"` | `"httpbin:8000"` | `"httpbin:8000"`
| `\"%UPSTREAM_HOST%\"` | `"10.44.1.27:80"` | `"127.0.0.1:80"`
| `%UPSTREAM_CLUSTER%` | <code>outbound&#124;8000&#124;&#124;httpbin.foo.svc.cluster.local</code> | <code>inbound&#124;8000&#124;&#124;</code>
| `%UPSTREAM_LOCAL_ADDRESS%` | `10.44.1.23:37652` | `127.0.0.1:41854`
| `%DOWNSTREAM_LOCAL_ADDRESS%` | `10.0.45.184:8000` | `10.44.1.27:80`
| `%DOWNSTREAM_REMOTE_ADDRESS%` | `10.44.1.23:46520` | `10.44.1.23:37652`
| `%REQUESTED_SERVER_NAME%` | `-` | `outbound_.8000_._.httpbin.foo.svc.cluster.local`
| `%ROUTE_NAME%` | `default` | `default`

## Тестування журналу доступу {#test-the-access-log}

1.  Надішліть запит з `curl` до `httpbin`:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sS -v httpbin:8000/status/418
    ...
    < HTTP/1.1 418 Unknown
    ...
    < server: envoy
    ...
    I'm a teapot!
    ...
    {{< /text >}}

1.  Перевірте журнал `otel-collector`:

    {{< text bash >}}
    $ kubectl logs -l app=opentelemetry-collector -n observability
    [2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 3 1 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "127.0.0.1:80" inbound|8000|| 127.0.0.1:41854 10.44.1.27:80 10.44.1.23:37652 outbound_.8000_._.httpbin.foo.svc.cluster.local default
    {{< /text >}}

Зверніть увагу, що повідомлення, що відповідають запиту, з’являються в журналах Istio проксі як для джерела, так і для місця призначення, відповідно `curl` і `httpbin`. Ви можете побачити в журналі HTTP-дієслово (`GET`), HTTP-шлях (`/status/418`), код відповіді (`418`) та іншу [інформацію про запит](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules).

## Очищення {#cleanup}

Зупиніть сервіси [curl]({{< github_tree >}}/samples/curl) і [httpbin]({{< github_tree >}}/samples/httpbin):

{{< text bash >}}
$ kubectl delete telemetry curl-logging
$ kubectl delete -f @samples/curl/curl.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
$ kubectl delete -f @samples/open-telemetry/otel.yaml@ -n istio-system
$ kubectl delete namespace observability
{{< /text >}}

### Вимкнення журналу доступу Envoy {#disable-envoys-access-logging}

Видаліть або встановіть значення `""` для налаштувань `meshConfig.extensionProviders` і `meshConfig.defaultProviders` у конфігурації встановлення Istio.

{{< tip >}}
У наведеному нижче прикладі замініть `default` на імʼя профілю, який ви використовували під час встановлення Istio.
{{< /tip >}}

{{< text bash >}}
$ istioctl install --set profile=default
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
{{< /text >}}
