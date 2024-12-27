---
title: Маршрутизація на основі вимог JWT
description: Показує, як використовувати політику автентифікації Istio для маршрутизації запитів на основі заявок JWT.
weight: 20
keywords: [security,authentication,jwt,route]
owner: istio/wg-security-maintainers
test: yes
status: Alpha
---

{{< boilerplate alpha >}}

Це завдання показує, як маршрутизувати запити на основі заявок JWT на шлюзі входу Istio, використовуючи автентифікацію запитів та віртуальні сервіси.

Зверніть увагу: ця функція підтримується тільки для шлюзу входу Istio і вимагає використання як автентифікації запитів, так і віртуального сервісу для належної перевірки та маршрутизації на основі заявок JWT.

## Перед початком {#before-you-begin}

* Ознайомтеся з концепціями політики [автентифікації Istio](/docs/concepts/security/#authentication-policies) та [віртуального сервісу](/docs/concepts/traffic-management/#virtual-services).

* Встановіть Istio, дотримуючись [посібника з установки Istio](/docs/setup/install/istioctl/).

* Розгорніть навантаження, наприклад, `httpbin` в просторі імен, наприклад `foo`, та експонуйте його через шлюз входу Istio за допомогою цієї команди:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f @samples/httpbin/httpbin-gateway.yaml@ -n foo
    {{< /text >}}

* Слідуйте інструкціям у розділі [Визначення IP та портів входу](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports) для визначення змінних середовища `INGRESS_HOST` та `INGRESS_PORT`.

* Перевірте, що навантаження `httpbin` та шлюз входу працюють як очікується, використовуючи цю команду:

    {{< text bash >}}
    $ curl "$INGRESS_HOST:$INGRESS_PORT"/headers -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
Якщо ви не бачите очікуваного результату, спробуйте знову через кілька секунд. Кешування та затримки в розповсюдженні можуть спричинити затримку.
{{< /warning >}}

## Налаштування маршрутизації ingress на основі заявок JWT {#configuring-ingress-routing-based-on-jwt-claims}

Istio ingress gateway підтримує маршрутизацію на основі автентифікованого JWT, що є корисним для маршрутизації на основі ідентичності кінцевого користувача і є більш безпечним у порівнянні з використанням неавтентифікованих HTTP атрибутів (наприклад, шлях або заголовок).

1. Для маршрутизації на основі заявок JWT спочатку створіть автентифікацію запитів для ввімкнення перевірки JWT:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: RequestAuthentication
    metadata:
      name: ingress-jwt
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

    Автентифікація запиту уможливлює перевірку JWT на вхідному шлюзі Istio, щоб підтверджені JWT-запити пізніше можуть бути використані у віртуальному сервісі для маршрутизації.

    Автентифікація запиту застосовується на вхідному шлюзі, оскільки маршрутизація на основі заявок JWT підтримується тільки на вхідних шлюзах.

    Примітка: автентифікація запитів перевірятиме JWT лише в разі його наявності у запиті. Щоб зробити JWT обовʼязковим і відхиляти запити, які не містять JWT, застосуйте політику авторизації, як зазначено в [завданні](/docs/tasks/security/authentication/authn-policy#require-a-valid-token).

2. Оновіть віртуальну службу, щоб прокласти маршрут на основі підтверджених заявок JWT:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: VirtualService
    metadata:
      name: httpbin
      namespace: foo
    spec:
      hosts:
      - "*"
      gateways:
      - httpbin-gateway
      http:
      - match:
        - uri:
            prefix: /headers
          headers:
            "@request.auth.claims.groups":
              exact: group1
        route:
        - destination:
            port:
              number: 8000
            host: httpbin
    EOF
    {{< /text >}}

    Віртуальний сервіс використовує зарезервований заголовок `"@request.auth.claims.groups"` для збігів з заявкою JWT `groups`. Префікс `@` позначає, що він має збіг з метаданими, отриманими з перевірки JWT, а не з HTTP заголовками.

    Підтримуються заявки типу рядок, список рядків і вкладені заявки. Використовуйте `.` або `[]` як роздільник для імен вкладених заявок. Наприклад, `"@request.auth.claims.name.givenName"` або `"@request.auth.claims[name][givenName]"` збігається з вкладеними заявками `name` та `givenName`, вони еквівалентні тут. Коли імʼя заявки містить `.`, лише `[]` може бути використано як роздільник.

## Перевірка маршрутизації вхідних даних на основі заявок JWT {#validating-ingress-routing-based-on-jwt-claims}

1. Перевірка вхідного шлюзу повертає HTTP код 404 без JWT:

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

    Ви також можете створити політику авторизації для явного відхилення запиту з HTTP-кодом 403, коли JWT відсутній.

1. Перевірка вхідного шлюзу повертає HTTP код 401 з недійсним JWT:

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer some.invalid.token"
    HTTP/1.1 401 Unauthorized
    ...
    {{< /text >}}

    401 повертається при перевірці автентичності запиту, оскільки JWT не пройшов перевірку.

1. Переконайтеся, що вхідний шлюз направляє запит з дійсним токеном JWT, який містить заявку `groups: group1`:

    {{< text syntax="bash" expandlinks="false" >}}
    $ TOKEN_GROUP=$(curl {{< github_file >}}/security/tools/jwt/samples/groups-scope.jwt -s) && echo "$TOKEN_GROUP" | cut -d '.' -f2 - | base64 --decode
    {"exp":3537391104,"groups":["group1","group2"],"iat":1537391104,"iss":"testing@secure.istio.io","scope":["scope1","scope2"],"sub":"testing@secure.istio.io"}
    {{< /text >}}

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer $TOKEN_GROUP"
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

1. Перевірте вхідний шлюз, і він поверне HTTP код 404 з дійсним JWT, але не містить твердження `groups: group1`:

    {{< text syntax="bash" >}}
    $ TOKEN_NO_GROUP=$(curl {{< github_file >}}/security/tools/jwt/samples/demo.jwt -s) && echo "$TOKEN_NO_GROUP" | cut -d '.' -f2 - | base64 --decode
    {"exp":4685989700,"foo":"bar","iat":1532389700,"iss":"testing@secure.istio.io","sub":"testing@secure.istio.io"}
    {{< /text >}}

    {{< text bash >}}
    $ curl -s -I "http://$INGRESS_HOST:$INGRESS_PORT/headers" -H "Authorization: Bearer $TOKEN_NO_GROUP"
    HTTP/1.1 404 Not Found
    ...
    {{< /text >}}

## Очищення {#cleanup}

* Видаліть простір імен `foo`:

    {{< text bash >}}
    $ kubectl delete namespace foo
    {{< /text >}}

* Видаліть автентифікацію запиту:

    {{< text bash >}}
    $ kubectl delete requestauthentication ingress-jwt -n istio-system
    {{< /text >}}
