---
title: Приклади політик безпеки
description: Демонструє поширені приклади використання політик безпеки Istio.
weight: 60
owner: istio/wg-security-maintainers
test: yes
---

## Передумови {#background}

Ця сторінка демонструє поширені шаблони використання політик безпеки Istio. Ви можете знайти їх корисними для вашого розгортання або використовувати як швидкий довідник щодо прикладів політик.

Представлені політики є лише прикладами та потребують змін для адаптації до вашого середовища перед застосуванням.

Також перегляньте завдання з [автентифікації](/docs/tasks/security/authentication/authn-policy) та [авторизації](/docs/tasks/security/authorization) для практичних уроків використання політик безпеки більш детально.

## Вимога різних видавців JWT для кожного хосту {#require-different-jwt-issuer-per-host}

Валідація JWT є поширеною на вхідному шлюзі (ingress gateway), і ви можете захотіти вимагати наявності різних видавців JWT для різних хостів. Ви можете використовувати політику авторизації для детальної валідації JWT у доповнення до політики [аутентифікації запитів](/docs/tasks/security/authentication/authn-policy/#end-user-authentication).

Використовуйте наступну політику, якщо ви хочете дозволити доступ до певних хостів, якщо JWT-принципал збігається. Доступ до інших хостів завжди буде заборонений.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: jwt-per-host
  namespace: istio-system
spec:
  selector:
    matchLabels:
      istio: ingressgateway
  action: ALLOW
  rules:
  - from:
    - source:
        # токен JWT має мати видавця із суфіксом "@example.com"
        requestPrincipals: ["*@example.com"]
    to:
    - operation:
        hosts: ["example.com", "*.example.com"]
  - from:
    - source:
        # токен JWT має мати видавця із суфіксом "@another.org"
        requestPrincipals: ["*@another.org"]
    to:
    - operation:
        hosts: [".another.org", "*.another.org"]
{{< /text >}}

## Ізоляція простору імен {#namespace-isolation}

Наступні дві політики вмикають строгий режим mTLS у просторі імен `foo` і дозволяють трафік лише з того ж простору імен.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: foo-isolation
  namespace: foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["foo"]
{{< /text >}}

## Ізоляція простору імен з винятком для ingress {#namespace-isolation-with-ingress-exception}

Наступні дві політики вмикають строгий режим mTLS у просторі імен `foo` і дозволяють трафік як з того ж простору імен, так і з вхідного шлюзу (ingress gateway).

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: foo
spec:
  mtls:
    mode: STRICT
---
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ns-isolation-except-ingress
  namespace: foo
spec:
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces: ["foo"]
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
{{< /text >}}

## Вимога mTLS на рівні авторизації (захист в глибину) {#require-mtls-in-authorization-layer-defense-in-depth}

Ви налаштували `PeerAuthentication` у режимі `STRICT`, але хочете додатково переконатися, що трафік дійсно захищений за допомогою mTLS через додаткову перевірку на рівні авторизації, тобто захист у глибину.

Наступна політика відхиляє запит, якщо принципал є порожнім. Принципал буде порожнім, якщо використовується звичайний текст. Іншими словами, політика дозволяє запити, якщо принципал не є порожнім. `"*"` означає непорожню відповідність, і використання з `notPrincipals` означає відповідність порожньому принципалу.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: require-mtls
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        notPrincipals: ["*"]
{{< /text >}}

## Вимога обовʼязкової перевірки авторизації за допомогою політики `DENY` {#require-mandatory-authorization-check-with-deny-policy}

Ви можете використовувати політику `DENY`, якщо хочете вимагати обовʼязкову перевірку авторизації, яку не можна обійти за допомогою іншої, більш дозвільної політики `ALLOW`. Це працює тому, що політика `DENY` має пріоритет над політикою `ALLOW` і може відхилити запит раніше, ніж політики `ALLOW` почнуться.

Використовуйте наступну політику, щоб забезпечити обовʼязкову валідацію JWT у доповнення до політики [автентифікації запитів](/docs/tasks/security/authentication/authn-policy/#end-user-authentication). Політика відхиляє запит, якщо принципал запиту є порожнім. Принципал запиту буде порожнім, якщо валідація JWT не вдалася. Іншими словами, політика дозволяє запити, якщо принципал запиту не є порожнім. `"*"` означає непорожню відповідність, і використання з `notRequestPrincipals` означає відповідність порожньому принципалу запиту.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: require-jwt
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
{{< /text >}}

Так само використовуйте наступну політику, щоб забезпечити обовʼязкову ізоляцію простору імен та дозволити запити також від вхідного шлюзу (ingress gateway). Політика відхиляє запит, якщо простір імен не є `foo`, а принципал не є `cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account`. Іншими словами, політика дозволяє запити лише в тому випадку, якщо простір імен є `foo`, або принципал є `cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account`.

{{< text yaml >}}
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: ns-isolation-except-ingress
  namespace: foo
spec:
  action: DENY
  rules:
  - from:
    - source:
        notNamespaces: ["foo"]
        notPrincipals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
{{< /text >}}
