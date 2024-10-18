---
title: Пряма заборона
description: Показує, як налаштувати контроль доступу для явної заборони трафіку.
weight: 40
keywords: [security,access-control,rbac,authorization,deny]
owner: istio/wg-security-maintainers
test: yes
---

Це завдання показує, як налаштувати політику авторизації Istio з дією `DENY`, щоб явно заборонити трафік в мережі Istio. Це відрізняється від дії `ALLOW`, оскільки дія `DENY` має вищий пріоритет і її не можна оминути будь-якими діями `ALLOW`.

## Перед початком {#before-you-begin}

Перед початком цього завдання зробіть наступне:

* Ознайомтеся з [концепціями авторизації Istio](/docs/concepts/security/#authorization).

* Слідуйте [посібнику з установки Istio](/docs/setup/install/istioctl/), щоб встановити Istio.

* Розгорніть навантаження:

    Це завдання використовує два навантаження, `httpbin` та `sleep`, розгорнуті в одному просторі імен, `foo`. Обидва навантаження працюють з проксі Envoy попереду. Розгорніть приклад простору імен та навантаження за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@) -n foo
    {{< /text >}}

* Перевірте, що `sleep` звертається до `httpbin` за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl http://httpbin.foo:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

{{< warning >}}
Якщо ви не бачите очікуваного результату, слідкуйте за завданням ще раз через кілька секунд. Кешування та затримки поширення можуть спричинити деякі затримки.
{{< /warning >}}

## Явне відхилення запиту {#explicitly-deny-a-request}

1. Наступна команда створює політику авторизації `deny-method-get` для навантаження `httpbin` в просторі імен `foo`. Політика встановлює `action` на `DENY`, щоб відхилити запити, які відповідають умовам, встановленим у секції `rules`. Цей тип політики краще відомий як політика відмови. У цьому випадку політика відхиляє запити, якщо їх метод `GET`.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: deny-method-get
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

2. Перевірте, що запити `GET` відхиляються:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -sS -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

3. Перевірте, що запити `POST` дозволені:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/post" -X POST -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

4. Оновіть політику авторизації `deny-method-get`, щоб відхиляти запити `GET` тільки в тому випадку, якщо значення заголовка HTTP `x-token` не `admin`. Наступний приклад політики встановлює значення поля `notValues` на `["admin"]`, щоб відхиляти запити з заголовком, значення якого не `admin`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: deny-method-get
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
        when:
        - key: request.headers[x-token]
          notValues: ["admin"]
    EOF
    {{< /text >}}

5. Перевірте, що запити `GET` з заголовком HTTP `x-token: admin` дозволені:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: admin" -sS -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

6. Перевірте, що запити `GET` з заголовком HTTP `x-token: guest` відхиляються:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: guest" -sS -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

7. Наступна команда створює політику авторизації `allow-path-ip`, щоб дозволити запити на шлях `/ip` до навантаження `httpbin`. Ця політика авторизації встановлює поле `action` на `ALLOW`. Цей тип політики краще відомий як політика дозволу.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: allow-path-ip
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: httpbin
      action: ALLOW
      rules:
      - to:
        - operation:
            paths: ["/ip"]
    EOF
    {{< /text >}}

8. Перевірте, що запити `GET` з заголовком HTTP `x-token: guest` на шлях `/ip` відхиляються політикою `deny-method-get`. Політики відмови мають пріоритет над політиками дозволу:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/ip" -X GET -H "x-token: guest" -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

9. Перевірте, що запити `GET` з заголовком HTTP `x-token: admin` на шлях `/ip` є дозволеними політикою `allow-path-ip`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/ip" -X GET -H "x-token: admin" -s -o /dev/null -w "%{http_code}\n"
    200
    {{< /text >}}

10. Перевірте, що запити `GET` з заголовком HTTP `x-token: admin` на шлях `/get` є відхиленими, оскільки вони не відповідають політиці `allow-path-ip`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=sleep -n foo -o jsonpath={.items..metadata.name})" -c sleep -n foo -- curl "http://httpbin.foo:8000/get" -X GET -H "x-token: admin" -s -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

## Очищення {#clean-up}

Видаліть простір імен `foo` з вашої конфігурації:

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}
