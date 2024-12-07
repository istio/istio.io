---
title: Логи доступу Envoy
description: Це завдання показує, як налаштувати проксі Envoy для виведення логів доступу на стандартний вихід.
weight: 20
keywords: [telemetry,logs,телеметрія,логи]
aliases:
    - /uk/docs/tasks/telemetry/access-log
    - /uk/docs/tasks/telemetry/logs/access-log/
owner: istio/wg-policies-and-telemetry-maintainers
test: так
---

Найпростіший тип логування в Istio — це [логи доступу Envoy](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage). Проксі Envoy виводять інформацію про доступ на свій стандартний вихід. Стандартний вихід контейнерів Envoy можна вивести за допомогою команди `kubectl logs`.

{{< boilerplate before-you-begin-egress >}}

{{< boilerplate start-httpbin-service >}}

## Увімкнення логів доступу Envoy {#enable-envoy-s-access-logging}

Istio пропонує декілька способів увімкнення логів доступу. Рекомендується використовувати Telemetry API.

### Використання Telemetry API {#using-telemetry-api}

Telemetry API можна використовувати для увімкнення або вимкнення логів доступу:

{{< text yaml >}}
apiVersion: telemetry.istio.io/v1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  accessLogging:
    - providers:
      - name: envoy
{{< /text >}}

У прикладі вище використовується стандартний провайдер логів доступу `envoy`, і ми не налаштовуємо нічого, окрім стандартних параметрів.

Подібну конфігурацію можна також застосувати на рівні окремого простору імен або конкретного навантаження для детальнішого контролю логування.

Більше інформації про використання Telemetry API дивіться в [огляді Telemetry API](/docs/tasks/observability/telemetry/).

### Використання конфігурації Mesh {#using-mesh-config}

Якщо ви використовували конфігурацію `IstioOperator` для встановлення Istio, додайте наступне поле до вашої конфігурації:

{{< text yaml >}}
spec:
  meshConfig:
    accessLogFile: /dev/stdout
{{< /text >}}

В іншому випадку, додайте еквівалентне налаштування до вашої початкової команди `istioctl install`, наприклад:

{{< text syntax=bash snip_id=none >}}
$ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
{{< /text >}}

Ви також можете вибрати між JSON і текстом, встановивши `accessLogEncoding` на `JSON` або `TEXT`.

Ви також можете налаштувати [формат](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules) логів доступу, редагуючи `accessLogFormat`.

Дивіться [глобальні параметри mesh](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) для отримання додаткової інформації про ці три налаштування:

* `meshConfig.accessLogFile`
* `meshConfig.accessLogEncoding`
* `meshConfig.accessLogFormat`

## Формат логів доступу за замовчуванням {#default-access-log-format}

Якщо не вказано `accessLogFormat`, Istio використовуватиме наступний стандартний формат логів доступу:

{{< text plain >}}
[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\"
\"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n
{{< /text >}}

У таблиці нижче наведено приклад використання формату стандартних логів доступу для запиту від `curl` до `httpbin`:

| Оператор логу | логи доступу у curl | логи доступу у httpbin |
|---------------|---------------------|------------------------|
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

## Тестування логів доступу {#test-the-access-log}

1.  Надішліть запит від `curl` до `httpbin`:

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

1.  Перевірте логи `curl`:

    {{< text bash >}}
    $ kubectl logs -l app=curl -c istio-proxy
    [2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 4 4 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "10.44.1.27:80" outbound|8000||httpbin.foo.svc.cluster.local 10.44.1.23:37652 10.0.45.184:8000 10.44.1.23:46520 - default
    {{< /text >}}

1.  Перевірте логи `httpbin`:

    {{< text bash >}}
    $ kubectl logs -l app=httpbin -c istio-proxy
    [2020-11-25T21:26:18.409Z] "GET /status/418 HTTP/1.1" 418 - via_upstream - "-" 0 135 3 1 "-" "curl/7.73.0-DEV" "84961386-6d84-929d-98bd-c5aee93b5c88" "httpbin:8000" "127.0.0.1:80" inbound|8000|| 127.0.0.1:41854 10.44.1.27:80 10.44.1.23:37652 outbound_.8000_._.httpbin.foo.svc.cluster.local default
    {{< /text >}}

Зверніть увагу, що повідомлення, повʼязані із запитом, зʼявляються в логах Istio-проксі як на джерелі, так і на пункті призначення — відповідно, `curl` і `httpbin`. Ви можете побачити в логах HTTP-метод (`GET`), HTTP-шлях (`/status/418`), код відповіді (`418`) та іншу [інформацію про запит](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#format-rules).

## Очищення {#cleanup}

Завершіть роботу сервісів [curl]({{< github_tree >}}/samples/curl) та [httpbin]({{< github_tree >}}/samples/httpbin):

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@
$ kubectl delete -f @samples/httpbin/httpbin.yaml@
{{< /text >}}

### Вимкнення логування доступу Envoy {#disable-envoys-access-logging}

Видаліть або встановіть значення `meshConfig.accessLogFile` у вашу конфігурацію встановлення Istio на `""`.

{{< tip >}}
У прикладі нижче замініть `default` на назву профілю, який ви використовували під час встановлення Istio.
{{< /tip >}}

{{< text bash >}}
$ istioctl install --set profile=default
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
{{< /text >}}
