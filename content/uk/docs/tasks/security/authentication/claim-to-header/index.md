---
title: Копіювання JWT-заявок до заголовків HTTP
description: Показує, як користувачі можуть копіювати свої JWT-заявки до заголовків HTTP.
weight: 30
keywords: [security,authentication,JWT,claim]
aliases:
    - /uk/docs/tasks/security/istio-auth.html
    - /uk/docs/tasks/security/authn-policy/
owner: istio/wg-security-maintainers
test: yes
status: Experimental
---

{{< boilerplate experimental >}}

Це завдання показує, як скопіювати дійсні заявки JWT до HTTP заголовків після успішного завершення автентифікації JWT за допомогою політики автентифікації запитів Istio.

{{< warning >}}
Підтримуються лише заявки типу рядок, булевий та ціле число. Заявки типу масиву на цей час не підтримуються.
{{< /warning >}}

## Перед початком {#before-you-begin}

Перед початком цього завдання виконайте наступні кроки:

* Ознайомтеся з [автентифікацією кінцевого користувача Istio](/docs/tasks/security/authentication/authn-policy/#end-user-authentication).

* Встановіть Istio за допомогою [посібника з установки Istio](/docs/setup/install/istioctl/).

* Розгорніть навантаження `httpbin` та `sleep` в просторі імен `foo` з увімкненою інʼєкцією sidecar. Розгорніть приклад простору імен і навантаження за допомогою цих команд:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl label namespace foo istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@ -n foo
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n foo
    {{< /text >}}

* Переконайтеся, що `sleep` успішно взаємодіє з `httpbin` за допомогою цієї команди:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

    {{< warning >}}
    Якщо ви не бачите очікуваного результату, повторіть спробу через кілька секунд. Кешування та розповсюдження можуть спричинити затримку.
    {{< /warning >}}

## Дозволити запити з дійсним JWT і заявками типу список {#allow-requests-with-valid-jwt-and-list-typed-claims}

1. Наступна команда створює політику автентифікації запитів `jwt-example` для навантаження `httpbin` в просторі імен `foo`. Ця політика приймає JWT, виданий `testing@secure.istio.io`, і копіює значення заявки `foo` в HTTP заголовок `X-Jwt-Claim-Foo`:

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
        outputClaimToHeaders:
        - header: "x-jwt-claim-foo"
          claim: "foo"
    EOF
    {{< /text >}}

1. Переконайтеся, що запит з недійсним JWT відхилено:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer invalidToken" -w "%{http_code}\n"
    401
    {{< /text >}}

1. Отримайте JWT, який видано `testing@secure.istio.io` і має заявку з ключем `foo`.

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN" | cut -d '.' -f2 - | base64 --decode -
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

1. Переконайтеся, що запит з дійсним JWT дозволено:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -o /dev/null -H "Authorization: Bearer $TOKEN" -w "%{http_code}\n"
    200
    {{< /text >}}

1. Переконайтеся, що запит містить дійсний HTTP-заголовок зі значенням заявки JWT:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/headers" -sS -H "Authorization: Bearer $TOKEN" | grep "X-Jwt-Claim-Foo" | sed -e 's/^[ \t]*//'
    "X-Jwt-Claim-Foo": "bar"
    {{< /text >}}

## Очищення {#clean-up}

Видаліть простір імен `foo`:

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}
