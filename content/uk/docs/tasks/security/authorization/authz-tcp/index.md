---
title: Трафік TCP
description: Показує, як налаштувати контроль доступу для TCP-трафіку.
weight: 20
keywords: [security,access-control,rbac,tcp,authorization]
aliases:
    - /uk/docs/tasks/security/authz-tcp/
owner: istio/wg-security-maintainers
test: no
---

Це завдання показує, як налаштувати політику авторизації Istio для TCP-трафіку в Istio mesh.

## Перед початком {#before-you-begin}

Перед початком цього завдання виконайте наступне:

* Ознайомтесь з [концепціями авторизації Istio](/docs/concepts/security/#authorization).

* Встановіть Istio, використовуючи [посібник з установки Istio](/docs/setup/install/istioctl/).

* Розгорніть два навантаження з іменами `curl` та `tcp-echo` разом у просторі імен, наприклад, `foo`. Обидва навантаження працюють з проксі Envoy попереду кожного з них. Навантаження `tcp-echo` слухає порти 9000, 9001 та 9002 та відповідає будь-якому отриманому трафіку з префіксом `hello`. Наприклад, якщо ви надішлете "world" на `tcp-echo`, він відповість `hello world`. Обʼєкт сервісу Kubernetes `tcp-echo` оголошує тільки порти 9000 і 9001, і не вказує порт 9002. Трафік на порт 9002 буде оброблятися через фільтр прохідного зʼєднання. Розгорніть приклад простору імен та навантаження, використовуючи наступну команду:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/tcp-echo/tcp-echo.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n foo
    {{< /text >}}

* Перевірте, чи `curl` успішно комунікує з `tcp-echo` на портах 9000 та 9001, використовуючи наступну команду:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9000
    connection succeeded
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9001
    connection succeeded
    {{< /text >}}

* Перевірте, чи `curl` успішно комунікує з `tcp-echo` на порту 9002. Вам потрібно надіслати трафік безпосередньо на IP-адресу pod `tcp-echo`, оскільки порт 9002 не визначений у обʼєкті сервісу Kubernetes `tcp-echo`. Отримайте IP-адресу pod і надішліть запит наступною командою:

    {{< text bash >}}
    $ TCP_ECHO_IP=$(kubectl get pod "$(kubectl get pod -l app=tcp-echo -n foo -o jsonpath={.items..metadata.name})" -n foo -o jsonpath="{.status.podIP}")
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        "echo \"port 9002\" | nc $TCP_ECHO_IP 9002" | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9002
    connection succeeded
    {{< /text >}}

{{< warning >}}
Якщо ви не бачите очікуваного результату, повторіть спробу через кілька секунд. Кешування та поширення можуть спричинити затримку.
{{< /warning >}}

## Налаштування політики авторизації ALLOW для TCP-навантаження {#configure-allow-authorization-policy-for-a-tcp-workload}

1. Створіть політику авторизації `tcp-policy` для навантаження `tcp-echo` у просторі імен `foo`. Виконайте наступну команду для застосування політики, щоб дозволити запити на порти 9000 та 9001:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: tcp-policy
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: tcp-echo
      action: ALLOW
      rules:
      - to:
        - operation:
            ports: ["9000", "9001"]
    EOF
    {{< /text >}}

1. Перевірте, чи запити на порт 9000 дозволені, використовуючи наступну команду:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9000
    connection succeeded
    {{< /text >}}

1. Перевірте, чи запити на порт 9001 дозволені, використовуючи наступну команду:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9001
    connection succeeded
    {{< /text >}}

1. Перевірте, чи запити на порт 9002 відхилені. Це забезпечується політикою авторизації, яка також застосовується до фільтра прохідного зʼєднання, навіть якщо порт не оголошений явно в обʼєкті сервісу Kubernetes `tcp-echo`. Виконайте наступну команду та перевірте результат:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        "echo \"port 9002\" | nc $TCP_ECHO_IP 9002" | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. Оновіть політику, щоб додати поле тільки для HTTP з назвою `methods` для порту 9000, використовуючи наступну команду:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: tcp-policy
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: tcp-echo
      action: ALLOW
      rules:
      - to:
        - operation:
            methods: ["GET"]
            ports: ["9000"]
    EOF
    {{< /text >}}

1. Перевірте, чи запити на порт 9000 відхилені. Це відбувається, тому що правило стає недійсним, коли використовуються поля тільки для HTTP (`methods`) для TCP-трафіку. Istio ігнорує недійсне правило ALLOW. Остаточний результат — запит відхилено, оскільки він не відповідає жодним ALLOW правилам. Виконайте наступну команду та перевірте результат:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. Перевірте, чи запити на порт 9001 відхилені. Це відбувається, оскільки запити не відповідають жодним ALLOW правилам. Виконайте наступну команду та перевірте результат:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

## Налаштування політики авторизації DENY для TCP-навантаження {#configure-deny-authorization-policy-for-a-tcp-workload}

1. Додайте політику DENY з полями тільки для HTTP, використовуючи наступну команду:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: tcp-policy
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: tcp-echo
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
    EOF
    {{< /text >}}

1. Перевірте, чи запити на порт 9000 відхилені. Це відбувається тому, що Istio не розуміє поля тільки для HTTP при створенні правила DENY для TCP-порту, і через свою обмежувальну природу він блокує весь трафік до TCP-портів:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. Перевірте, чи запити на порт 9001 відхилені. Та сама причина, що й вище.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. Додайте політику DENY з полями для TCP та HTTP, використовуючи наступну команду:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: tcp-policy
      namespace: foo
    spec:
      selector:
        matchLabels:
          app: tcp-echo
      action: DENY
      rules:
      - to:
        - operation:
            methods: ["GET"]
            ports: ["9000"]
    EOF
    {{< /text >}}

1. Перевірте, чи запити на порт 9000 відхилені. Це відбувається, тому що запит відповідає `ports` у згаданій вище політиці DENY.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9000" | nc tcp-echo 9000' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    connection rejected
    {{< /text >}}

1. Перевірте, чи запити на порт 9001 дозволені. Це відбувається, тому що запити не відповідають `ports` у політиці DENY:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -n foo -o jsonpath={.items..metadata.name})" \
        -c curl -n foo -- sh -c \
        'echo "port 9001" | nc tcp-echo 9001' | grep "hello" && echo 'connection succeeded' || echo 'connection rejected'
    hello port 9001
    connection succeeded
    {{< /text >}}

## Очищення {#clean-up}

Видаліть простір імен `foo`:

{{< text bash >}}
$ kubectl delete namespace foo
{{< /text >}}
