---
title: Міграція взаємних TLS
description: Показує, як поетапно мігрувати ваші сервіси Istio на взаємний TLS.
weight: 40
keywords: [security,authentication,migration]
aliases:
    - /uk/docs/tasks/security/mtls-migration/
owner: istio/wg-security-maintainers
test: yes
---

Це завдання показує, як забезпечити, щоб ваші навантаження спілкувалися лише за допомогою взаємного TLS під час міграції на Istio.

Istio автоматично конфігурує sidecar-и навантажень для використання [взаємного TLS](/docs/tasks/security/authentication/authn-policy/#auto-mutual-tls) при виклику інших навантажень. Стандартно Istio конфігурує навантаження призначення з використанням режиму `PERMISSIVE`. Коли режим `PERMISSIVE` увімкнено, сервіс може приймати як звичайний, так і взаємний TLS трафік. Щоб дозволити лише трафік взаємного TLS, конфігурацію потрібно змінити на режим `STRICT`.

Ви можете використовувати [дашборд Grafana](/docs/tasks/observability/metrics/using-istio-dashboard/) для перевірки, які навантаження все ще надсилають звичайний трафік до навантажень у режимі `PERMISSIVE`, і вибрати заблокувати їх, коли міграція завершена.

## Перед початком {#before-you-begin}

<!-- TODO: update the link after other PRs are merged -->

* Ознайомтеся з [політикою автентифікації Istio](/docs/concepts/security/#authentication-policies) та повʼязаними концепціями [автентифікації взаємного TLS](/docs/concepts/security/#mutual-tls-authentication).

* Прочитайте [завдання з політики автентифікації](/docs/tasks/security/authentication/authn-policy), щоб дізнатися, як конфігурувати політику автентифікації.

* Майте кластер Kubernetes з встановленим Istio, без увімкненого глобального взаємного TLS (наприклад, використовуйте профіль конфігурації `default`, як описано в [кроках установки](/docs/setup/getting-started)).

У цьому завданні ви можете спробувати процес міграції, створивши зразкові навантаження та модифікувавши політики для забезпечення STRICT взаємного TLS між навантаженнями.

## Налаштування кластера {#set-up-the-cluster}

* Створіть два простори імен, `foo` та `bar`, і розгорніть [httpbin]({{< github_tree >}}/samples/httpbin) та [curl]({{< github_tree >}}/samples/curl) з sidecar-ами в обох:

    {{< text bash >}}
    $ kubectl create ns foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n foo
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n foo
    $ kubectl create ns bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/httpbin/httpbin.yaml@) -n bar
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@) -n bar
    {{< /text >}}

* Створіть інший простір імен, `legacy`, і розгорніть [curl]({{< github_tree >}}/samples/curl) без sidecar:

    {{< text bash >}}
    $ kubectl create ns legacy
    $ kubectl apply -f @samples/curl/curl.yaml@ -n legacy
    {{< /text >}}

* Перевірте налаштування, надіславши HTTP запити (з використанням curl) з podʼів `curl`, у просторах імен `foo`, `bar` і `legacy`, до `httpbin.foo` і `httpbin.bar`. Всі запити повинні успішно завершитися з кодом повернення 200.

    {{< text bash >}}
    $ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
    curl.foo to httpbin.foo: 200
    curl.foo to httpbin.bar: 200
    curl.bar to httpbin.foo: 200
    curl.bar to httpbin.bar: 200
    curl.legacy to httpbin.foo: 200
    curl.legacy to httpbin.bar: 200
    {{< /text >}}

    {{< tip >}}
    Якщо жодна з команд curl не спрацює, переконайтеся, що немає жодних наявних політик автентифікації або правил призначення які можуть перешкоджати запитам до сервісу httpbin.

    {{< text bash >}}
    $ kubectl get peerauthentication --all-namespaces
    No resources found
    {{< /text >}}

    {{< text bash >}}
    $ kubectl get destinationrule --all-namespaces
    No resources found
    {{< /text >}}

    {{< /tip >}}

## Перемикання на лише взаємний TLS за простором імен {#lock-down-to-mutual-tls-by-namespace}

Після міграції всіх клієнтів на Istio та інʼєкції sidecarʼа Envoy ви можете перемкнути навантаження в просторі імен `foo` для приймання лише трафіку взаємного TLS.

{{< text bash >}}
$ kubectl apply -n foo -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Тепер ви повинні побачити, що запит від `curl.legacy` до `httpbin.foo` зазнає невдачі.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
curl.foo to httpbin.foo: 200
curl.foo to httpbin.bar: 200
curl.bar to httpbin.foo: 200
curl.bar to httpbin.bar: 200
curl.legacy to httpbin.foo: 000
command terminated with exit code 56
curl.legacy to httpbin.bar: 200
{{< /text >}}

Якщо ви встановили Istio з `values.global.proxy.privileged=true`, ви можете використовувати `tcpdump` для перевірки, чи зашифровано трафік.

{{< text bash >}}
$ kubectl exec -nfoo "$(kubectl get pod -nfoo -lapp=httpbin -ojsonpath={.items..metadata.name})" -c istio-proxy -- sudo tcpdump dst port 80  -A
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
{{< /text >}}

Ви побачите як незашифрований, так і зашифрований текст у виводі, коли запити надсилаються з `curl.legacy` і `curl.foo` відповідно.

Якщо ви не можете мігрувати всі свої сервіси на Istio (тобто, зробити інʼєкцію sidecar Envoy у всі з них), вам слід продовжити використовувати режим `PERMISSIVE`. Однак у режимі `PERMISSIVE` стандартно жодні перевірки автентифікації чи авторизації не будуть виконані для звичайного трафіку. Рекомендуємо використовувати [Авторизацію Istio](/docs/tasks/security/authorization/authz-http/) для конфігурації різних шляхів з різними політиками авторизації.

## Перемикання на взаємний TLS для всього mesh {#lock-down-mutual-tls-for-the-entire-mesh}

Ви можете перемкнути навантаження у всіх просторах імен для приймання лише трафіку взаємного TLS, розмістивши політику в системному просторі імен вашої установки Istio.

{{< text bash >}}
$ kubectl apply -n istio-system -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

Тепер обидва простори імен `foo` і `bar` забезпечують взаємний трафік тільки з TLS, тому ви повинні бачити, що запити з `curl.legacy` в обох просторах.

{{< text bash >}}
$ for from in "foo" "bar" "legacy"; do for to in "foo" "bar"; do kubectl exec "$(kubectl get pod -l app=curl -n ${from} -o jsonpath={.items..metadata.name})" -c curl -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "curl.${from} to httpbin.${to}: %{http_code}\n"; done; done
{{< /text >}}

## Очищення прикладу {#clean-up-the-example}

1. Видаліть політику автентифікації для всієї мережі.

    {{< text bash >}}
    $ kubectl delete peerauthentication -n foo default
    $ kubectl delete peerauthentication -n istio-system default
    {{< /text >}}

1. Видаліть тестові простори імен.

    {{< text bash >}}
    $ kubectl delete ns foo bar legacy
    Namespaces foo bar legacy deleted.
    {{< /text >}}
