---
title: Авторизація на основі політик за допомогою Kyverno
description: Делегування логіки прийняття рішень щодо авторизації Layer 7 за допомогою сервера авторизації Kyverno, використовуючи політики на основі CEL.
publishdate: 2024-11-25
attribution: "Charles-Edouard Brétéché (Nirmata)"
keywords: [istio,kyverno,policy,platform,authorization]
---

Istio підтримує інтеграцію з багатьма різними проєктами. Нещодавно в блозі Istio була опублікована стаття про [функціональність політик L7 з OpenPolicyAgent](../l7-policy-with-opa). Kyverno є подібним проєктом, і сьогодні ми розглянемо, як Istio та сервер авторизації Kyverno можуть використовуватися разом для забезпечення політик Layer 7 у вашій платформі.

Ми покажемо вам, як почати роботу з простого прикладу. Ви побачите, як це поєднання є надійним варіантом для швидкого та прозорого впровадження політик для команд розробників у всій організації, одночасно надаючи дані, необхідні командам безпеки для аудиту та відповідності вимогам.

## Спробуймо {#try-it-out}

При інтеграції з Istio, сервер авторизації Kyverno можна використовувати для забезпечення детального контролю доступу до мікросервісів.

Цей посібник показує, як застосовувати політики контролю доступу для простого мікросервісного застосунку.

### Передумови {#prerequisites}

- Кластер Kubernetes з встановленим Istio.
- Встановлений інструмент командного рядка `istioctl`.

Встановіть Istio та налаштуйте ваші [параметри мережі](/docs/reference/config/istio.mesh.v1alpha1/) для активації Kyverno:

{{< text bash >}}
$ istioctl install -y -f - <<EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
    accessLogFormat: |
      [KYVERNO DEMO] my-new-dynamic-metadata: '%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%'
    extensionProviders:
    - name: kyverno-authz-server
      envoyExtAuthzGrpc:
        service: kyverno-authz-server.kyverno.svc.cluster.local
        port: '9081'
EOF
{{< /text >}}

Зверніть увагу, що в конфігурації ми визначаємо розділ `extensionProviders`, який вказує на встановлення сервера авторизації Kyverno:

{{< text yaml >}}
[...]
    extensionProviders:
    - name: kyverno-authz-server
      envoyExtAuthzGrpc:
        service: kyverno-authz-server.kyverno.svc.cluster.local
        port: '9081'
[...]
{{< /text >}}

#### Розгортання сервера авторизації Kyverno {#deploy-the-kyverno-authz-server}

Сервер авторизації Kyverno — це GRPC сервер, здатний обробляти запити зовнішньої авторизації Envoy.

Його можна налаштувати за допомогою ресурсів `AuthorizationPolicy` Kyverno, які зберігаються в кластері або надаються ззовні.

{{< text bash >}}
$ kubectl create ns kyverno
$ kubectl label namespace kyverno istio-injection=enabled
$ helm install kyverno-authz-server --namespace kyverno --wait --version 0.1.0 --repo https://kyverno.github.io/kyverno-envoy-plugin kyverno-authz-server
{{< /text >}}

#### Розгортання демонстраційного застосунку {#deploy-the-sample-application}

httpbin — це добре відомий застосунок, який можна використовувати для тестування HTTP-запитів і який допомагає швидко показати, як ми можемо працювати з атрибутами запиту та відповіді.

{{< text bash >}}
$ kubectl create ns my-app
$ kubectl label namespace my-app istio-injection=enabled
$ kubectl apply -f {{< github_file >}}/samples/httpbin/httpbin.yaml -n my-app
{{< /text >}}

#### Розгортання Istio AuthorizationPolicy {#deploy-an-istio-authorization-policy}

`AuthorizationPolicy` визначає сервіси, які будуть захищені сервером авторизації Kyverno.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: my-kyverno-authz
  namespace: istio-system # Це застосовує політику на всю мережу, istio-system буде кореневим простором імен мережі
spec:
  selector:
    matchLabels:
      ext-authz: enabled
  action: CUSTOM
  provider:
    name: kyverno-authz-server
  rules: [{}] # Порожні правила, буде застосовано до селекторів з міткою ext-authz: enabled
EOF
{{< /text >}}

Зверніть увагу, що в цьому ресурсі ми визначаємо `extensionProvider` Kyverno Authz Server, який ви встановили в конфігурації Istio:

{{< text yaml >}}
[...]
  provider:
    name: kyverno-authz-server
[...]
{{< /text >}}

#### Додавання мітки до застосунку для застосування політики {#add-the-label-to-enforce-the-policy}

Додамо мітку до застосунку для застосування політики. Мітка потрібна для того, щоб політика авторизації Istio застосовувалася до podʼів демонстраційного застосунку.

{{< text bash >}}
$ kubectl patch deploy httpbin -n my-app --type=merge -p='{
  "spec": {
    "template": {
      "metadata": {
        "labels": {
          "ext-authz": "enabled"
        }
      }
    }
  }
}'
{{< /text >}}

#### Розгортання Kyverno AuthorizationPolicy {#deploy-a-kyverno-authorizationpolicy}

Політика авторизації Kyverno `AuthorizationPolicy` визначає правила, які використовуються сервером авторизації Kyverno для прийняття рішення на основі наданого Envoy [CheckRequest](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkrequest).

Вона використовує мову [CEL](https://github.com/google/cel-spec) для аналізу вхідного `CheckRequest` і повинна створити [CheckResponse](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto#service-auth-v3-checkresponse) у відповідь.

Вхідний запит доступний у полі `object`, і політика може визначати `variables`, які будуть доступні для всіх `authorizations`.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  failurePolicy: Fail
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.?headers["x-force-authorized"].orValue("")
  - name: allowed
    expression: variables.force_authorized in ["enabled", "true"]
  authorizations:
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
EOF
{{< /text >}}

Зверніть увагу, що ви можете створити `CheckResponse` вручну або використовувати [допоміжні функції CEL](https://kyverno.github.io/kyverno-envoy-plugin/latest/cel-extensions/) як `envoy.Allowed()` та `envoy.Denied(403)`, щоб спростити створення повідомлення відповіді:

{{< text yaml >}}
[...]
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
[...]
{{< /text >}}

## Як це працює {#how-it-works}

При застосуванні `AuthorizationPolicy`, панель управління Istio (istiod) надсилає необхідні конфігурації до проксі-сервера sidecar (Envoy) вибраних сервісів у політиці. Envoy потім надсилає запит до сервера авторизації Kyverno, щоб перевірити, чи дозволено запит, чи ні.

{{< image width="75%" link="./overview.svg" alt="Istio та сервер авторизації Kyverno" >}}

Проксі-сервер Envoy працює, налаштовуючи фільтри в ланцюжку. Один з цих фільтрів — `ext_authz`, який реалізує зовнішню службу авторизації зі конкретним повідомленням. Будь-який сервер, що реалізує правильний protobuf, може підʼєднатися до проксі-сервера Envoy і надати рішення щодо авторизації; сервер авторизації Kyverno є одним з таких серверів.

{{< image link="./filters-chain.svg" alt="Фільтри" >}}

Ознайомившись з [документацією служби авторизації Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto), ви побачите, що повідомлення має такі атрибути:

- Відповідь Ok

    {{< text json >}}
    {
      "status": {...},
      "ok_response": {
        "headers": [],
        "headers_to_remove": [],
        "response_headers_to_add": [],
        "query_parameters_to_set": [],
        "query_parameters_to_remove": []
      },
      "dynamic_metadata": {...}
    }
    {{< /text >}}

- Відповідь Denied

    {{< text json >}}
    {
      "status": {...},
      "denied_response": {
        "status": {...},
        "headers": [],
        "body": "..."
      },
      "dynamic_metadata": {...}
    }
    {{< /text >}}

Це означає, що на основі відповіді від сервера авторизації Envoy може додавати або видаляти заголовки, параметри запиту і навіть змінювати тіло відповіді.

Ми також можемо це зробити, як задокументовано в [документації сервера авторизації Kyverno](https://kyverno.github.io/kyverno-envoy-plugin).

## Тестування {#testing}

Протестуймо просте використання (авторизація), а потім створимо складнішу політику, щоб показати, як ми можемо використовувати сервер авторизації Kyverno для зміни запиту та відповіді.

Розгорніть застосунок для виконання команд curl до демонстраційного застосунку httpbin:

{{< text bash >}}
$ kubectl apply -n my-app -f {{< github_file >}}/samples/curl/curl.yaml
{{< /text >}}

Застосуйте політику:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  failurePolicy: Fail
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.?headers["x-force-authorized"].orValue("")
  - name: allowed
    expression: variables.force_authorized in ["enabled", "true"]
  authorizations:
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : envoy.Denied(403).Response()
EOF
{{< /text >}}

Простий сценарій полягає в тому, щоб дозволити запити, якщо вони містять заголовок `x-force-authorized` зі значенням `enabled` або `true`. Якщо заголовок відсутній або має інше значення, запит буде відхилено.

У цьому випадку ми поєднали обробку дозволених і відхилених відповідей в одному виразі. Однак можна використовувати кілька виразів, перший з яких повертає ненульову відповідь, буде використаний сервером авторизації Kyverno, це корисно, коли правило не хоче приймати рішення і делегує наступному правилу:

{{< text yaml >}}
[...]
  authorizations:
  # дозволити запит, коли значення заголовка збігається
  - expression: >
      variables.allowed
        ? envoy.Allowed().Response()
        : null
  # інакше відхилити запит
  - expression: >
      envoy.Denied(403).Response()
[...]
{{< /text >}}

### Прості правила {#simple-rules}

Наступний запит поверне `403`:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

Наступний запит поверне `200`:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

### Складніші маніпуляції {#advanced-manipulations}

Тепер складніший випадок використання, застосуйте другу політику:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: envoy.kyverno.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: demo-policy.example.com
spec:
  variables:
  - name: force_authorized
    expression: object.attributes.request.http.headers[?"x-force-authorized"].orValue("") in ["enabled", "true"]
  - name: force_unauthenticated
    expression: object.attributes.request.http.headers[?"x-force-unauthenticated"].orValue("") in ["enabled", "true"]
  - name: metadata
    expression: '{"my-new-metadata": "my-new-value"}'
  authorizations:
    # якщо force_unauthenticated -> 401
  - expression: >
      variables.force_unauthenticated
        ? envoy
            .Denied(401)
            .WithBody("Authentication Failed")
            .Response()
        : null
    # якщо force_authorized -> 200
  - expression: >
      variables.force_authorized
        ? envoy
            .Allowed()
            .WithHeader("x-validated-by", "my-security-checkpoint")
            .WithoutHeader("x-force-authorized")
            .WithResponseHeader("x-add-custom-response-header", "added")
            .Response()
            .WithMetadata(variables.metadata)
        : null
    # інакше -> 403
  - expression: >
      envoy
        .Denied(403)
        .WithBody("Unauthorized Request")
        .Response()
EOF
{{< /text >}}

У цій політиці ви можете побачити:

- Якщо запит має заголовок `x-force-unauthenticated: true` (або `x-force-unauthenticated: enabled`), ми повернемо `401` з тілом "Authentication Failed"
- Інакше, якщо запит має заголовок `x-force-authorized: true` (або `x-force-authorized: enabled`), ми повернемо `200` і маніпулюватимемо заголовками запиту, заголовками відповіді та вставлятимемо динамічні метадані
- У всіх інших випадках ми повернемо `403` з тілом "Unauthorized Request"

Відповідний CheckResponse буде повернуто до проксі-сервера Envoy від сервера авторизації Kyverno. Envoy використовуватиме ці значення для зміни запиту та відповіді відповідно.

#### Зміна тіла відповіді {#changing-returned-body}

Протестуймо нові можливості:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

Тепер ми можемо змінити тіло відповіді.

З `403` тіло буде змінено на "Unauthorized Request", виконавши попередню команду, ви повинні отримати:

{{< text plain >}}
Unauthorized Request
http_code=403
{{< /text >}}

#### Зміна тіла відповіді та коду статусу {#change-returned-body-and-status-code}

Виконання запиту з заголовком `x-force-unauthenticated: true`:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-unauthenticated: true"
{{< /text >}}

Цього разу ви повинні отримати тіло "Authentication Failed" та помилку `401`:

{{< text plain >}}
Authentication Failed
http_code=401
{{< /text >}}

#### Додавання заголовків до запиту {#adding-headers-to-request}

Виконання валідного запиту:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

Ви повинні отримати тіло з новим заголовком `x-validated-by: my-security-checkpoint` і видаленим заголовком `x-force-authorized`:

{{< text plain >}}
[...]
    "X-Validated-By": [
      "my-security-checkpoint"
    ]
[...]
http_code=200
{{< /text >}}

#### Додавання заголовків до відповіді {#adding-headers-to-response}

Виконання того ж запиту, але показуючи лише заголовок:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -I -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

Ви знайдете заголовок відповіді, доданий під час перевірки авторизації `x-add-custom-response-header: added`:

{{< text plain >}}
HTTP/1.1 200 OK
[...]
x-add-custom-response-header: added
[...]
http_code=200
{{< /text >}}

### Обмін даними між фільтрами {#sharing-data-between-filters}

Нарешті, ви можете передавати дані наступним фільтрам Envoy, використовуючи `dynamic_metadata`.

Це корисно, коли ви хочете передати дані іншому фільтру `ext_authz` у ланцюжку або хочете надрукувати їх у журналах застосунку.

{{< image link="./dynamic-metadata.svg" alt="Метадані" >}}

Для цього перегляньте формат журналу доступу, який ви встановили раніше:

{{< text plain >}}
[...]
    accessLogFormat: |
      [KYVERNO DEMO] my-new-dynamic-metadata: "%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%"
[...]
{{< /text >}}

`DYNAMIC_METADATA` — це зарезервоване ключове слово для доступу до обʼєкта метаданих. Решта — це назва фільтра, до якого ви хочете отримати доступ.

У нашому випадку назва `envoy.filters.http.ext_authz` створюється автоматично Istio. Ви можете перевірити це, зробивши дамп конфігурації Envoy:

{{< text bash >}}
$ istioctl pc all deploy/httpbin -n my-app -oyaml | grep envoy.filters.http.ext_authz
{{< /text >}}

Ви побачите конфігурації для фільтра.

Тепер протестуємо динамічні метадані. У розширеному правилі ми створюємо новий запис метаданих: `{"my-new-metadata": "my-new-value"}`.

Виконайте запит і перевірте журнали застосунку:

{{< text bash >}}
$ kubectl exec -n my-app deploy/curl -- curl -s -I httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

{{< text bash >}}
$ kubectl logs -n my-app deploy/httpbin -c istio-proxy --tail 1
{{< /text >}}

Ви побачите у вихідних даних нові атрибути, налаштовані політикою Kyverno:

{{< text plain >}}
[...]
[KYVERNO DEMO] my-new-dynamic-metadata: '{"my-new-metadata":"my-new-value","ext_authz_duration":5}'
[...]
{{< /text >}}

## Висновок {#conclusion}

У цьому посібнику ми показали, як інтегрувати Istio та сервер авторизації Kyverno для забезпечення політик для простого мікросервісного застосунку. Ми також показали, як використовувати політики для зміни атрибутів запиту та відповіді.

Це основний приклад для побудови системи політик на рівні платформи, яка може використовуватися всіма командами розробників.
