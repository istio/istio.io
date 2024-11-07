---
title: Політика автентифікації
description: Показує, як використовувати політику автентифікації Istio для налаштування взаємної TLS і базової автентифікації кінцевого користувача.
weight: 10
keywords: [security,authentication]
aliases:
    - /uk/docs/tasks/security/istio-auth.html
    - /uk/docs/tasks/security/authn-policy/
owner: istio/wg-security-maintainers
test: yes
---

Це завдання охоплює основні дії, які можуть знадобитися для увімкнення, налаштування та використання політик автентифікації Istio. Дізнайтеся більше про основні концепції у [огляді автентифікації](/docs/concepts/security/#authentication).

## Перед початком {#before-you-begin}

* Дізнайтесь про [політику автентифікації](/docs/concepts/security/#authentication-policies) Istio і повʼязані концепції [взаємної TLS-автентифікації](/docs/concepts/security/#mutual-tls-authentication).

* Встановіть Istio в кластер Kubernetes з конфігураційним профілем `default`, як описано в
[кроках установки](/docs/setup/getting-started).

{{< text bash >}}
$ istioctl install --set profile=default
{{< /text >}}

### Налаштування {#setup}

Наші приклади використовують два простори імен: `foo` і `bar`, з двома сервісами, `httpbin` і `curl`, які обидва працюють з проксі Envoy. Ми також використовуємо інші екземпляри `httpbin` і `curl`, що працюють без sidecar у просторі імен `legacy`. Якщо ви хочете використовувати ті ж приклади для виконання завдань, виконайте наступне:

{{< text bash >}}
$ kubectl create ns foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
$ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n foo
$ kubectl create ns bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
$ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n bar
$ kubectl create ns legacy
$ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n legacy
$ kubectl apply -f @samples/curl/curl.yaml@ -n legacy
{{< /text >}}

Ви можете перевірити налаштування, відправивши HTTP-запит за допомогою `curl` з будь-якого podʼа `curl` у просторі імен `foo`, `bar` або `legacy` на будь-який з `httpbin.foo`,
`httpbin.bar` або `httpbin.legacy`. Усі запити мають бути успішними з HTTP-кодом 200.

Наприклад, ось команда для перевірки доступності `curl.bar` до `httpbin.foo`:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n bar -o jsonpath={.items..metadata.name})" -c curl -n bar -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

Ця команда зручно перебирає всі комбінації доступності:

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl -s "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 200
curl.legacy to httpbin.bar: 200
curl.legacy to httpbin.legacy: 200
{{< /text >}}

Переконайтеся, що в системі немає політики однорангової автентифікації за допомогою наступної команди:

{{< text bash >}}
$ kubectl get peerauthentication --all-namespaces
No resources found
{{< /text >}}

Останнім кроком перевірте, що немає правил призначення, які застосовуються до демонстраційних сервісів. Ви можете зробити це, перевіривши значення `host:` існуючих правил призначення та переконавшись, що вони не збігаються. Наприклад:

{{< text bash >}}
$ kubectl get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"
{{< /text >}}

{{< tip >}}
Залежно від версії Istio, ви можете побачити правила призначення для хостів, відмінних від наведених. Однак не повинно бути жодного з хостами в просторах імен `foo`, `bar` і `legacy`, а також жодного універсального шаблону `*`.
{{< /tip >}}

## Автоматичний взаємний TLS {#auto-mutual-tls}

Стандартно Istio відстежує серверні робочі навантаження, перенесені на проксі Istio, і налаштовує проксі клієнтів для автоматичного надсилання трафіку з взаємним TLS до цих робочих навантажень і для надсилання простого текстового трафіку до робочих навантажень без sidecar.

Таким чином, весь трафік між робочими навантаженнями з проксі використовує взаємний TLS, без додаткових дій з вашого боку. Наприклад, візьміть відповідь на запит до `httpbin/header`. При використанні взаємного TLS проксі вставляє заголовок `X-Forwarded-Client-Cert` у запит до бекенду. Наявність цього заголовка є доказом використання взаємного TLS. Наприклад:

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl -s http://httpbin.foo:8000/headers -s | jq '.headers["X-Forwarded-Client-Cert"][0]' | sed 's/Hash=[a-z0-9]*;/Hash=<redacted>;/'
  "By=spiffe://cluster.local/ns/foo/sa/httpbin;Hash=<redacted>;Subject=\"\";URI=spiffe://cluster.local/ns/foo/sa/curl"
{{< /text >}}

Коли сервер не має sidecar, заголовок `X-Forwarded-Client-Cert` відсутній, що вказує на те, що запити передаються у звичайному текстовому режимі.

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" -c curl -n foo -- curl http://httpbin.legacy:8000/headers -s | grep X-Forwarded-Client-Cert

{{< /text >}}

## Глобальне увімкнення взаємного TLS Istio в режимі STRICT {#globally-enabling-istio-mutual-tls-in-strict-mode}

Хоча Istio автоматично оновлює весь трафік між проксі та робочими навантаженнями до взаємного TLS, робочі навантаження все ще можуть отримувати трафік у звичайному текстовому форматі. Щоб запобігти невзаємному TLS-трафіку для всієї мережі, встановіть політику однорангової автентифікації для всієї мережі з режимом взаємного TLS, встановленим на `STRICT`. Політика однорангової автентифікації для всієї мережі не повинна мати `selector` і повинна застосовуватися, наприклад, у **кореневому просторі імен**:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "istio-system"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

{{< tip >}}
Приклад припускає, що `istio-system` є кореневим простором імен. Якщо ви використовували інше значення під час установки, замініть `istio-system` на використане вами значення.
{{< /tip >}}

Ця політика однорангової автентифікації налаштовує робочі навантаження так, щоб вони приймали тільки запити, зашифровані TLS. Оскільки не вказано значення для поля `selector`, політика застосовується до всіх робочих навантажень у mesh.

Запустіть команду перевірки знову:

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 000
command terminated with exit code 56
curl.legacy to httpbin.legacy: 200
{{< /text >}}

Ви побачите, що запити все ще успішні, за винятком тих, що надходять від клієнта без проксі, `curl.legacy`, до сервера з проксі, `httpbin.foo` або `httpbin.bar`. Це очікувано, оскільки тепер взаємний TLS є обовʼязковим, але робоче навантаження без sidecar не може відповідати вимогам.

### Очистка частина 1 {#cleanup-part-1}

Видаліть глобальну політику автентифікації, додану під час сесії:

{{< text bash >}}
$ kubectl delete peerauthentication -n istio-system default
{{< /text >}}

## Увімкнення взаємного TLS в кожен простір імен або робоче навантаження {#enable-mutual-tls-per-namespace-or-workload}

### Політика для всього простору імен {#namespace-wide-policy}

Щоб змінити взаємний TLS для всіх робочих навантажень у певному просторі імен, використовуйте політику для всього простору імен. Специфікація політики така ж, як і для політики для всього mesh, але ви вказуєте простір імен, до якого вона застосовується, в `metadata`. Наприклад, наступна політика однорангової автентифікації увімкне строгий взаємний TLS для простору імен `foo`:

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "default"
  namespace: "foo"
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Оскільки ця політика застосовується лише до робочих навантажень у просторі імен `foo`, ви побачите, що тільки запити від клієнта без sidecar (`curl.legacy`) до `httpbin.foo` почнуть давати збої.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 200
curl.legacy to httpbin.legacy: 200
{{< /text >}}

### Увімкнення взаємного TLS для робочого навантаження {#enable-mutual-tls-per-workload}

Щоб налаштувати політику однорангової автентифікації для конкретного робочого навантаження, ви повинні налаштувати розділ `selector` та вказати мітки, які відповідають потрібному робочому навантаженню. Наприклад, наступна політика однорангової автентифікації увімкне строгий взаємний TLS для робочого навантаження `httpbin.bar`:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Знову запустіть команду probing. Як і очікувалося, запит з ` curl.legacy` до `httpbin.bar` починає зазнавати невдачі з тих самих причин.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 000
command terminated with exit code 56
curl.legacy to httpbin.legacy: 200
{{< /text >}}

{{< text plain >}}
...
curl.legacy to httpbin.bar: 000
command terminated with exit code 56
{{< /text >}}

Щоб уточнити налаштування взаємного TLS для кожного порту, ви повинні налаштувати розділ `portLevelMtls`. Наприклад, наступна політика однорангової автентифікації вимагає взаємного TLS на всіх портах, окрім порту `8080`:

{{< text bash >}}
$ cat <<EOF | kubectl apply -n bar -f -
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "httpbin"
  namespace: "bar"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
  portLevelMtls:
    8080:
      mode: DISABLE
EOF
{{< /text >}}

1. Значення порту в політиці однорангової автентифікації — це порт контейнера.
2. Ви можете використовувати `portLevelMtls` тільки якщо порт привʼязано до сервісу. В іншому випадку Istio ігнорує його.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar" "legacy"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl "http://httpbin.${to}:8000/ip" -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.foo to httpbin.legacy: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.bar to httpbin.legacy: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 200
curl.legacy to httpbin.legacy: 200
{{< /text >}}

### Пріоритет політики {#policy-precedence}

Політика однорангової автентифікації для конкретного робочого навантаження має пріоритет над політикою для всього простору імен. Ви можете перевірити таку поведінку, додавши політику вимкнення взаємного TLS для робочого навантаження `httpbin.foo`, наприклад. Зверніть увагу, що ви вже створили політику для всього простору імен, яка вмикає взаємне TLS для всіх служб у просторі імен `foo`, і помітили, що запити від `curl.legacy` до `httpbin.foo` зазнають невдачі (див. вище).

{{< text bash >}}
$ cat <<EOF | kubectl apply -n foo -f -
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: "overwrite-example"
  namespace: "foo"
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: DISABLE
EOF
{{< /text >}}

Повторно запустивши запит з `curl.legacy`, ви знову побачите успішний код повернення (200), що підтверджує перевизначення політики для конкретного сервісу по відношенню до політики для всього простору імен.

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l app=curl -n legacy -o jsonpath={.items..metadata.name})" -c curl -n legacy -- curl http://httpbin.foo:8000/ip -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### Очистка частина 2 {#cleanup-part-2}

Видаліть політики, створені в попередніх кроках:

{{< text bash >}}
$ kubectl delete peerauthentication default overwrite-example -n foo
$ kubectl delete peerauthentication httpbin -n bar
{{< /text >}}

## Автентифікація кінцевих користувачів {#end-user-authentication}

Щоб експериментувати з цією функцією, вам потрібен дійсний JWT. JWT повинен відповідати точці доступу JWKS, яку ви хочете використовувати для демонстрації. Цей посібник використовує тестовий токен [JWT test]({{< github_file >}}/security/tools/jwt/samples/demo.jwt) та
[точку доступу JWKS]({{< github_file >}}/security/tools/jwt/samples/jwks.json) з коду Istio.

Також, для зручності, експонуйте `httpbin.foo` через ingress gateway (для отримання додаткової інформації, див. [завдання з ingress](/docs/tasks/traffic-management/ingress/)).

{{< boilerplate gateway-api-support >}}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Налаштуйте шлюз:

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/httpbin-gateway.yaml@ -n foo
{{< /text >}}

Дотримуйтесь інструкцій з [Визначення вхідного IP і портів](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) для визначення змінних оточення `INGRESS_PORT` і `INGRESS_HOST`.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Створіть шлюз:

{{< text bash >}}
$ kubectl apply -f @samples/httpbin/gateway-api/httpbin-gateway.yaml@ -n foo
$ kubectl wait --for=condition=programmed gtw -n foo httpbin-gateway
{{< /text >}}

Встановіть змінні оточення `INGRESS_PORT` та `INGRESS_HOST`:

{{< text bash >}}
$ export INGRESS_HOST=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.status.addresses[0].value}')
$ export INGRESS_PORT=$(kubectl get gtw httpbin-gateway -n foo -o jsonpath='{.spec.listeners[?(@.name=="http")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Виконайте тестовий запит через шлюз:

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

Тепер додайте політику автентифікації запитів, яка вимагає від кінцевого користувача JWT для вхідного шлюзу.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: "jwt-example"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: RequestAuthentication
metadata:
  name: "jwt-example"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Застосуйте політику в просторі імен робочого навантаження, яке вона вибирає, у цьому випадку — у шлюзі входу.

Якщо ви надасте токен у заголовку авторизації, його стандартне місце, Istio перевіряє токен за допомогою [набору публічних ключів]({{< github_file >}}/security/tools/jwt/samples/jwks.json) та відхиляє запити, якщо токен недійсний. Однак запити без токенів приймаються. Щоб спостерігати за цією поведінкою, повторіть запит без токена, з недійсним токеном та з дійсним токеном:

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

{{< text bash >}}
$ curl --header "Authorization: Bearer deadbeef" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
401
{{< /text >}}

{{< text bash >}}
$ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s)
$ curl --header "Authorization: Bearer $TOKEN" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

Щоб спостерігати за іншими аспектами перевірки JWT, використовуйте скрипт [`gen-jwt.py`]({{< github_tree >}}/security/tools/jwt/samples/gen-jwt.py), щоб генерувати нові токени для тестування з різними емітентами, аудиторіями, термінами дії тощо. Скрипт можна завантажити з репозиторію Istio:

{{< text bash >}}
$ wget --no-verbose {{< github_file >}}/security/tools/jwt/samples/gen-jwt.py
{{< /text >}}

Вам також потрібен файл `key.pem`:

{{< text bash >}}
$ wget --no-verbose {{< github_file >}}/security/tools/jwt/samples/key.pem
{{< /text >}}

{{< tip >}}
Завантажте бібліотеку [jwcrypto](https://pypi.org/project/jwcrypto), якщо ви ще не встановили її на свою систему.
{{< /tip >}}

Автентифікація JWT має розбіжність годинника в 60 секунд, що означає, що токен JWT стане дійсним на 60 секунд раніше, ніж його налаштоване значення `nbf`, і залишиться дійсним на 60 секунд після його налаштованого значення `exp`.

Наприклад, команда нижче створює токен, який закінчується через 5 секунд. Як ви бачите, Istio спочатку успішно автентифікує запити з цим токеном, але відхиляє їх після 65 секунд:

{{< text bash >}}
$ TOKEN=$(python3 ./gen-jwt.py ./key.pem --expire 5)
$ for i in $(seq 1 10); do curl --header "Authorization: Bearer $TOKEN" "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"; sleep 10; done
200
200
200
200
200
200
200
401
401
401
{{< /text >}}

Ви також можете додати політику JWT до шлюзу входу (наприклад, сервіс `istio-ingressgateway.istio-system.svc.cluster.local`). Це часто використовується для визначення політики JWT для всіх сервісів, привʼязаних до шлюзу, замість окремих сервісів.

### Потрібен дійсний токен {#require-a-valid-token}

Щоб відхиляти запити без дійсних токенів, додайте політику авторизації з правилом, яке вказує дію `DENY` для запитів без принципалів запиту, показаних як `notRequestPrincipals: ["*"]` у наступному прикладі. Принципали запиту доступні лише тоді, коли надано дійсні токени JWT. Отже, правило відхиляє запити без дійсних токенів.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

Повторіть запит без токена. Запит завершився невдачею з кодом помилки `403`:

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
403
{{< /text >}}

### Вимагати дійсні токени для кожного шляху {#require-valid-tokens-per-path}

Щоб уточнити авторизацію з вимогою токена для кожного хоста, шляху або методу, змініть політику авторизації, щоб вимагати JWT тільки на `/headers`. Коли це правило авторизації вступить в силу, запити до `$INGRESS_HOST:$INGRESS_PORT/headers` завершаться з кодом помилки `403`. Запити до всіх інших шляхів успішно обробляються, наприклад, `$INGRESS_HOST:$INGRESS_PORT/ip`.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
    to:
    - operation:
        paths: ["/headers"]
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "frontend-ingress"
  namespace: foo
spec:
  targetRef:
    kind: Gateway
    group: gateway.networking.k8s.io
    name: httpbin-gateway
  action: DENY
  rules:
  - from:
    - source:
        notRequestPrincipals: ["*"]
    to:
    - operation:
        paths: ["/headers"]
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/headers" -s -o /dev/null -w "%{http_code}\n"
403
{{< /text >}}

{{< text bash >}}
$ curl "$INGRESS_HOST:$INGRESS_PORT/ip" -s -o /dev/null -w "%{http_code}\n"
200
{{< /text >}}

### Очистка частина 3 {#cleanup-part-3}

1. Видаліть політику автентифікації:

    {{< text bash >}}
    $ kubectl -n istio-system delete requestauthentication jwt-example
    {{< /text >}}

1. Видаліть політику авторизації:

    {{< text bash >}}
    $ kubectl -n istio-system delete authorizationpolicy frontend-ingress
    {{< /text >}}

1. Видаліть скрипт генератора токенів і файл ключа:

    {{< text bash >}}
    $ rm -f ./gen-jwt.py ./key.pem
    {{< /text >}}

1. Якщо ви не плануєте досліджувати подальші завдання, ви можете вилучити всі ресурси, просто видаливши тестові простори імен.

    {{< text bash >}}
    $ kubectl delete ns foo bar legacy
    {{< /text >}}
