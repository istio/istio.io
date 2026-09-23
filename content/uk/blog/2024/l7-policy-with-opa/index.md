---
title: "Чи може ваша платформа реалізовувати політики? Прискорте команди завдяки функціональності платформних політик L7"
description: Чи є політика вашою основною компетенцією? Ймовірно, ні, але важливо зробити все правильно. Зробіть це один раз з Istio та OPA і поверніть команді фокус на те, що має найбільше значення.
publishdate: 2024-10-14
attribution: "Antonio Berben (Solo.io), Charlie Egan (Styra)"
keywords: [istio,opa,policy,platform,authorization]
---

Спільні обчислювальні платформи надають ресурси та функціональність для команд орендарів, щоб їм не доводилося створювати все з нуля. Хоча часом буває важко збалансувати всі запити від орендарів, важливо, щоб платформа ставила питання: яку найціннішу функцію ми можемо запропонувати нашим орендарям?

Часто роботу доручають безпосередньо командам що створюють застосунки, але деякі функції найкраще реалізувати один раз і надавати їх як сервіс для всіх команд. Однією з таких функцій, яку може запропонувати більшість команд, що опікуються платформами, є надання стандартної, гнучкої системи політики авторизації для рівня застосунків L7. Політика як код дозволяє командам переносити рішення щодо авторизації з рівня застосунків у легку та ефективну розподілену систему. Це може здатися складним завданням, але з правильними інструментами воно не обов’язково є таким.

Ми розглянемо, як Istio та Open Policy Agent (OPA) можуть використовуватися для забезпечення політик рівня L7 у вашій платформі. Ми покажемо, як почати з простого прикладу. Ви побачите, як ця комбінація є надійним варіантом для швидкого і прозорого надання політик командам розробки застосунків у бізнесі, а також забезпечує дані, необхідні командам безпеки для аудиту та дотримання стандартів.

## Спробуйте самі {#try-it-out}

Коли OPA інтегровано з Istio, він може використовуватися для забезпечення детальних політик контролю доступу для мікросервісів. У цьому посібнику описано, як забезпечити політики контролю доступу для простого мікросервісного застосунку.

### Попередні вимоги {#prerequisites}

- Кластер Kubernetes з встановленим Istio.
- Встановлений інструмент командного рядка `istioctl`.

Встановіть Istio і налаштуйте [параметри mesh](/docs/reference/config/istio.mesh.v1alpha1/), щоб увімкнути OPA:

{{< text bash >}}
$ istioctl install -y -f - <<'EOF'
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
    accessLogFormat: |
      [OPA DEMO] my-new-dynamic-metadata: "%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%"
    extensionProviders:
    - name: "opa.local"
      envoyExtAuthzGrpc:
        service: "opa.opa.svc.cluster.local"
        port: "9191"
EOF
{{< /text >}}

Зверніть увагу, що в конфігурації ми визначаємо розділ `extensionProviders`, який вказує на самостійне встановлення OPA.

Розгорніть приклад застосунків. Httpbin — відомий застосунок, який можна використовувати для тестування HTTP-запитів; він швидко демонструє, як можна працювати з атрибутами запиту та відповіді.

{{< text bash >}}
$ kubectl create ns my-app
$ kubectl label namespace my-app istio-injection=enabled

$ kubectl apply -f {{< github_file >}}/samples/httpbin/httpbin.yaml -n my-app
{{< /text >}}

Розгорніть OPA. Це не вдасться, оскільки очікується `configMap`, що містить стандартне правило Rego для використання. Цей `configMap` буде розгорнуто пізніше у нашому прикладі.

{{< text bash >}}
$ kubectl create ns opa
$ kubectl label namespace opa istio-injection=enabled

$ kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: opa
  name: opa
  namespace: opa
spec:
  replicas: 1
  selector:
    matchLabels:
      app: opa
  template:
    metadata:
      labels:
        app: opa
    spec:
      containers:
      - image: openpolicyagent/opa:0.61.0-envoy
        name: opa
        args:
          - "run"
          - "--server"
          - "--disable-telemetry"
          - "--config-file=/config/config.yaml"
          - "--log-level=debug" # Розкоментуйте цей рядок, щоб увімкнути журнали налагодження
          - "--diagnostic-addr=0.0.0.0:8282"
          - "/policy/policy.rego" # Стандартна політика
        volumeMounts:
          - mountPath: "/config"
            name: opa-config
          - mountPath: "/policy"
            name: opa-policy
      volumes:
        - name: opa-config
          configMap:
            name: opa-config
        - name: opa-policy
          configMap:
            name: opa-policy
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-config
  namespace: opa
data:
  config.yaml: |
    # Тут ви знайдете конфігурацію OPA, яку ви можете знайти в офіційній документації
    decision_logs:
      console: true
    plugins:
      envoy_ext_authz_grpc:
        addr: ":9191"
        path: mypackage/mysubpackage/myrule # Default path for grpc plugin
    # Тут ви можете додати власну конфігурацію з сервісами та пакетами
---
apiVersion: v1
kind: Service
metadata:
  name: opa
  namespace: opa
  labels:
    app: opa
spec:
  ports:
    - port: 9191
      protocol: TCP
      name: grpc
  selector:
    app: opa
---
EOF
{{< /text >}}

Розгорніть `AuthorizationPolicy`, щоб визначити, які служби будуть захищені OPA.

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: my-opa-authz
  namespace: istio-system # Цей рядок застосовує політику до всіх мереж в просторі назв налаштувань istio-system
spec:
  selector:
    matchLabels:
      ext-authz: enabled
  action: CUSTOM
  provider:
    name: "opa.local"
  rules: [{}] # Порожнє правило, буде застосовуватися до селекторів з міткою ext-authz: enabled
EOF
{{< /text >}}

Позначімо застосунок міткою, щоб впровадити політику:

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

Зверніть увагу, що в цьому ресурсі ми визначаємо OPA `extensionProvider`, який ви встановили в конфігурації Istio:

{{< text yaml >}}
[...]
  provider:
    name: "opa.local"
[...]
{{< /text >}}

## Як це працює {#how-it-works}

При застосуванні `AuthorizationPolicy` панель управління Istio (istiod) надсилає необхідні конфігурації до sidecar проксі (Envoy) вибраних сервісів, зазначених у політиці. Envoy потім відправляє запит на сервер OPA, щоб перевірити, чи дозволено цей запит.

{{< image width="75%"
    link="./opa1.png"
    alt="Istio та OPA"
    >}}

Проксі Envoy працює шляхом налаштування фільтрів у ланцюгу. Одним із таких фільтрів є `ext_authz`, який реалізує зовнішню службу авторизації з певним повідомленням. Будь-який сервер, що реалізує відповідний protobuf, може підʼєднатися до проксі Envoy та надати рішення щодо авторизації; OPA є одним з таких серверів.

{{< image width="75%"
    link="./opa2.png"
    alt="Фільтри"
    >}}

Раніше, коли ви встановлювали сервер OPA, ви використовували версію сервера Envoy. Цей образ дозволяє налаштувати втулок gRPC, який впроваджує службу `ext_authz` protobuf.

{{< text yaml >}}
[...]
      containers:
      - image: openpolicyagent/opa:0.61.0-envoy # Це версія образу OPA з втулком Envoy
        name: opa
[...]
{{< /text >}}

У конфігурації ви увімкнули втулок Envoy та порт, на якому він слухає:

{{< text yaml >}}
[...]
    decision_logs:
      console: true
    plugins:
      envoy_ext_authz_grpc:
        addr: ":9191" # Це порт, на якому буде слухати втулок Envoy
        path: mypackage/mysubpackage/myrule # Стандартний шлях для втулка grpc
    # Тут ви можете додати власну конфігурацію з сервісами та наборами даних
[...]
{{< /text >}}

Переглядаючи [документацію про службу авторизації Envoy](https://www.envoyproxy.io/docs/envoy/latest/api-v3/service/auth/v3/external_auth.proto), можна побачити, що повідомлення має такі атрибути:

{{< text json >}}
OkHttpResponse
{
  "status": {...},
  "denied_response": {...},
  "ok_response": {
      "headers": [],
      "headers_to_remove": [],
      "dynamic_metadata": {...},
      "response_headers_to_add": [],
      "query_parameters_to_set": [],
      "query_parameters_to_remove": []
    },
  "dynamic_metadata": {...}
}
{{< /text >}}

Це означає, що на основі відповіді від сервера authz Envoy може додавати або видаляти заголовки, параметри запиту та навіть змінювати статус відповіді. OPA також може це робити, як описано в його [документації](https://www.openpolicyagent.org/docs/latest/envoy-primer/#example-policy-with-additional-controls).

## Тестування {#testing}

Протестуймо просте використання (авторизацію), а потім створимо більш розширене правило, щоб показати, як можна використовувати OPA для зміни запиту та відповіді.

Розгорніть застосунок для запуску команд curl до тестового застосунку httpbin:

{{< text bash >}}
$ kubectl -n my-app run --image=curlimages/curl curl -- /bin/sleep 100d
{{< /text >}}

Застосуйте перше правило Rego і перезапустіть розгортання OPA:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-policy
  namespace: opa
data:
  policy.rego: |
    package mypackage.mysubpackage

    import rego.v1

    default myrule := false

    myrule if {
      input.attributes.request.http.headers["x-force-authorized"] == "enabled"
    }

    myrule if {
      input.attributes.request.http.headers["x-force-authorized"] == "true"
    }
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl rollout restart deployment -n opa
{{< /text >}}

Простий сценарій передбачає дозвіл запитів, якщо вони містять заголовок `x-force-authorized` зі значенням `enabled` або `true`. Якщо заголовок відсутній або має інше значення, запит буде відхилено.

Існує кілька способів створити правило Rego. У цьому випадку ми створили два різні правила. Виконуються вони у порядку, і перше правило, яке задовольняє всі умови, буде застосоване.

### Просте правило {#simple-rule}

Результатом наступного запиту буде відповідь `403`:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

Наступний запит поверне `200` та тіло відповіді:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-authorized: enabled"
{{< /text >}}

### Складніші маніпуляції {#advanced-manipulations}

Тепер складніше правило. Застосуйте друге правило Rego і перезапустіть розгортання OPA:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-policy
  namespace: opa
data:
  policy.rego: |
    package mypackage.mysubpackage

    import rego.v1

    request_headers := input.attributes.request.http.headers

    force_unauthenticated if request_headers["x-force-unauthenticated"] == "enabled"

    default allow := false

    allow if {
      not force_unauthenticated
      request_headers["x-force-authorized"] == "true"
    }

    default status_code := 403

    status_code := 200 if allow

    status_code := 401 if force_unauthenticated

    default body := "Unauthorized Request"

    body := "Authentication Failed" if force_unauthenticated

    myrule := {
      "body": body,
      "http_status": status_code,
      "allowed": allow,
      "headers": {"x-validated-by": "my-security-checkpoint"},
      "response_headers_to_add": {"x-add-custom-response-header": "added"},
      "request_headers_to_remove": ["x-force-authorized"],
      "dynamic_metadata": {"my-new-metadata": "my-new-value"},
    }
EOF
{{< /text >}}

{{< text bash >}}
$ kubectl rollout restart deployment -n opa
{{< /text >}}

В цьому правилі ви можете побачити:

{{< text plain >}}
myrule["allowed"] := allow # Зверніть увагу, що `allowed` є обовʼязковим при поверненні обʼєкта, як тут `myrule`.
myrule["headers"] := headers
myrule["response_headers_to_add"] := response_headers_to_add
myrule["request_headers_to_remove"] := request_headers_to_remove
myrule["body"] := body
myrule["http_status"] := status_code
{{< /text >}}

Це значення, які будуть повернуті проксі-серверу Envoy від OPA-сервера. Envoy буде використовувати ці значення для модифікації запиту і відповіді.

Зверніть увагу, що при поверненні JSON-обʼєкта потрібно вказувати `allowed`, а не тільки true/false. Це можна знайти [в документації OPA](https://www.openpolicyagent.org/docs/latest/envoy-primer/#output-document).

#### Зміна тіла відповіді {#change-returned-body}

Випробуємо нові можливості:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get
{{< /text >}}

Тепер ми можемо змінити тіло відповіді. Значення `403` змінює тіло в правилі Rego на «Unauthorized Request» (Несанкціонований запит). За допомогою попередньої команди ви повинні отримати:

{{< text plain >}}
Unauthorized Request
http_code=403
{{< /text >}}

#### Зміна тіла, що повертається і коду статусу {#change-returned-body-and-status-code}

Запустивши запит із заголовком `x-force-authorized: enabled` ви повинні отримати тіло «Authentication Failed» і помилку «401»:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -w "\nhttp_code=%{http_code}" httpbin:8000/get -H "x-force-unauthenticated: enabled"
{{< /text >}}

#### Додавання заголовків до запиту {#adding-headers-to-request}

Запустивши відповідний запит, ви повинні отримати тіло відповіді з новим заголовком `x-validated-by: my-security-checkpoint` і видаленим заголовком `x-force-authorized`:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

#### Додавання заголовків до відповіді {#adding-headers-to-response}

Запустивши той самий запит, але показавши лише заголовок, ви побачите заголовок відповіді, доданий під час перевірки Authz `x-add-custom-response-header: added`:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -I httpbin:8000/get -H "x-force-authorized: true"
{{< /text >}}

#### Обмін даними між фільтрами {#sharing-data-between-filters}

Останнім кроком є передача даних іншим фільтрам Envoy за допомогою `dynamic_metadata`. Це корисно, коли потрібно передати дані іншому фільтру `ext_authz` у ланцюзі або вивести їх у логи застосунку.

{{< image width="75%"
    link="./opa3.png"
    alt="Metadata"
    >}}

Для цього перегляньте формат журналу доступу, який ви налаштували раніше:

{{< text plain >}}
[...]
    accessLogFormat: |
      [OPA DEMO] my-new-dynamic-metadata: "%DYNAMIC_METADATA(envoy.filters.http.ext_authz)%"
[...]
{{< /text >}}

`DYNAMIC_METADATA` — це зарезервоване ключове слово для доступу до обʼєкта метаданих. Далі вказується назва фільтра, до якого ви хочете звернутися. У вашому випадку, імʼя `envoy.filters.http.ext_authz` автоматично створюється Istio. Ви можете перевірити це, вивівши конфігурацію Envoy:

{{< text bash >}}
$ istioctl pc all deploy/httpbin -n my-app -oyaml | grep envoy.filters.http.ext_authz
{{< /text >}}

Ви побачите конфігурації для фільтра.

Тепер перевіримо динамічні метадані. У розширеному правилі ви створюєте новий запис метаданих: `{"my-new-metadata": "my-new-value"}`.

Виконайте запит і перевірте логи застосунку:

{{< text bash >}}
$ kubectl exec -n my-app curl -c curl  -- curl -s -I httpbin:8000/get -H "x-force-authorized: true"
$ kubectl logs -n my-app deploy/httpbin -c istio-proxy --tail 1
{{< /text >}}

У виводі ви побачите нові атрибути, налаштовані за допомогою правил OPA Rego:

{{< text plain >}}
[...]
 my-new-dynamic-metadata: "{"my-new-metadata":"my-new-value","decision_id":"8a6d5359-142c-4431-96cd-d683801e889f","ext_authz_duration":7}"
[...]
{{< /text >}}

## Підсумки {#conclusion}

У цьому посібнику ми показали, як інтегрувати Istio та OPA для впровадження політик для простого мікросервісного застосунку. Ми також продемонстрували, як використовувати Rego для модифікації атрибутів запиту та відповіді. Це основний приклад для побудови системи політик на платформі, яку можуть використовувати всі команди розробників застосунків.
