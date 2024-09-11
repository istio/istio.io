---
title: Токени JWT
description: Показує, як налаштувати контроль доступу для токена JWT.
weight: 30
keywords: [security,authorization,jwt,claim]
aliases:
    - /uk/docs/tasks/security/rbac-groups/
    - /uk/docs/tasks/security/authorization/rbac-groups/
owner: istio/wg-security-maintainers
test: yes
---

Це завдання показує, як налаштувати політику авторизації Istio для забезпечення доступу на основі JSON Web Token (JWT). Політика авторизації Istio підтримує як рідкові типи JWT, так і типи списків рядків.

## Перед початком {#before-you-begin}

Перед тим, як почати це завдання, виконайте наступне:

* Завершіть [завдання автентифікації кінцевого користувача в Istio](/docs/tasks/security/authentication/authn-policy/#end-user-authentication).

* Прочитайте [концепції авторизації в Istio](/docs/concepts/security/#authorization).

* Встановіть Istio за допомогою [інструкції з встановлення Istio](/docs/setup/install/istioctl/).

* Розгорніть два навантаження: `httpbin` та `sleep`. Розгорніть їх в одному просторі імен, наприклад, `foo`. Обидва навантаження працюють з проксі Envoy перед кожним. Розгорніть простір імен та навантаження за допомогою цих команд:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    {{< /text >}}

* Переконайтесь, що `sleep` успішно спілкується з `httpbin`, використовуючи цю команду:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
Якщо ви не бачите очікуваного результату, спробуйте ще раз через кілька секунд. Кешування та розповсюдження можуть викликати затримку.
{{< /warning >}}

## Дозвіл запитів з дійсним JWT та заявками у вигляді списків{#allow-requests-with-valid-jwt-and-list-typed-claims}

1. Наступна команда створює політику автентифікації запитів `jwt-example` для навантаження `httpbin` у просторі імен `foo`. Ця політика для навантаження `httpbin` приймає JWT, виданий `testing@secure.istio.io`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: RequestAuthentication
    metadata:
      name: "jwt-example"
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      jwtRules:
      - issuer: "testing@secure.istio.io"
        jwksUri: "{{< github_file >}}/security/tools/jwt/samples/jwks.json"
    EOF
    {{< /text >}}

1. Перевірте, що запит з недійсним JWT відхилено:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer invalidToken" -w "%{http_code}\n"
    401
    {{< /text >}}

1. Перевірте, що запит без JWT дозволено, оскільки політики авторизації немає:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

1. Наступна команда створює політику авторизації `require-jwt` для навантаження `httpbin` у просторі імен `foo`. Політика вимагає, щоб усі запити до навантаження `httpbin` мали дійсний JWT з `requestPrincipal`, встановленим на `testing@secure.istio.io/testing@secure.istio.io`. Istio створює атрибут `requestPrincipal`, обʼєднуючи значення `iss` та `sub` токена JWT через роздільник `/`, як показано:

    {{< text syntax="bash" expandlinks="false" >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: require-jwt
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: ALLOW
      rules:
      - from:
        - source:
           requestPrincipals: ["testing@secure.istio.io/testing@secure.istio.io"]
    EOF
    {{< /text >}}

1. Отримайте JWT, що встановлює ключі `iss` і `sub` до однакового значення `testing@secure.istio.io`. Це дозволяє Istio згенерувати атрибут `requestPrincipal` зі значенням `testing@secure.istio.io/testing@secure.istio.io`:

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN" | cut -d '.' -f2 - | base64 --decode -
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

1. Перевірте, що запит з дійсним JWT дозволено:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n"
    200
    {{< /text >}}

1. Перевірте, що запит без JWT відхилено:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

1. Наступна команда оновлює політику авторизації `require-jwt`, щоб також вимагати
   щоб JWT мав заявку на імʼя `groups`, що містить значення `group1`:

    {{< text syntax="bash" expandlinks="false" >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: require-jwt
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: ALLOW
      rules:
      - from:
        - source:
           requestPrincipals: ["testing@secure.istio.io/testing@secure.istio.io"]
        when:
        - key: request.auth.claims[groups]
          values: ["group1"]
    EOF
    {{< /text >}}

    {{< warning >}}
    Не включайте лапки в поле `request.auth.claims`, якщо сам claim не містить лапок.
    {{< /warning >}}

1. Отримайте JWT, що додає заявку `groups` у список рядків: `group1` та `group2`:

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN_GROUP=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s) && echo "$TOKEN_GROUP" | cut -d '.' -f2 - | base64 --decode -
    {"exp":3537391104,"groups":["group1","group2"],"iat":1537391104,"iss":"testing@secure.istio.io","scope":["scope1","scope2"],"sub":"testing@secure.istio.io"}
    {{< /text >}}

1. Перевірте, що запит з JWT, який містить `group1` у заявці `groups`, дозволено:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN_GROUP" -w "%{http_code}\n"
    200
    {{< /text >}}

1. Переконайтеся, що запит з JWT, який не має заявки `groups`, відхилено:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n"
    403
    {{< /text >}}

## Очищення {#clean-up}

Видалити простір імен `foo`:

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}
