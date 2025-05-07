---
title: Міграція домену довіри
description: Показує, як мігрувати з одного домену довіри в інший без зміни політики авторизації.
weight: 60
keywords: [security,access-control,rbac,authorization,trust domain, migration]
owner: istio/wg-security-maintainers
test: yes
---

Це завдання показує, як мігрувати з одного домену довіри в інший без зміни політики авторизації.

У Istio 1.4 ми представили альфа-функцію для підтримки {{< gloss "Міграція Домену Довіри" >}}міграції домену довіри{{</ gloss >}} для політики авторизації. Це означає, що якщо Istio mesh потрібно змінити свій {{< gloss "Домен довіри" >}}домен довіри{{</ gloss >}}, політику авторизації не потрібно змінювати вручну. В Istio, якщо {{< gloss "Робоче навантаження" >}}робоче навантаження{{</ gloss >}} працює в просторі імен `foo` зі службовим обліковим записом `bar`, а домен довіри системи `my-td`, ідентифікатор цього робочого навантаження — `spiffe://my-td/ns/foo/sa/bar`. Стандартно домен довіри Istio mesh — `cluster.local`, якщо ви не вказали його під час установки.

## Перед початком {#before-you-begin}

Перед початком цього завдання виконайте наступне:

1. Ознайомтеся з [поняттями авторизації Istio](/docs/concepts/security/#authorization).

1. Встановіть Istio з власним доменом довіри та увімкненою взаємною TLS.

    {{< text bash >}}
    $ istioctl install --set profile=demo --set meshConfig.trustDomain=old-td
    {{< /text >}}

1. Розгорніть демонстраційний застосунок [httpbin]({{< github_tree >}}/samples/httpbin) у просторі імен `default`, а [curl]({{< github_tree >}}/samples/curl) — у просторах імен `default` та `curl-allow`:

    {{< text bash >}}
    $ kubectl label namespace default istio-injection=enabled
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    $ kubectl apply -f @samples/curl/curl.yaml@
    $ kubectl create namespace curl-allow
    $ kubectl label namespace curl-allow istio-injection=enabled
    $ kubectl apply -f @samples/curl/curl.yaml@ -n curl-allow
    {{< /text >}}

1. Застосуйте політику авторизації нижче, щоб заборонити всі запити до `httpbin`, крім запитів від `curl` у просторі імен `curl-allow`.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: security.istio.io/v1
    kind: AuthorizationPolicy
    metadata:
      name: service-httpbin.default.svc.cluster.local
      namespace: default
    spec:
      rules:
      - from:
        - source:
            principals:
            - old-td/ns/curl-allow/sa/curl
        to:
        - operation:
            methods:
            - GET
      selector:
        matchLabels:
          app: httpbin
    ---
    EOF
    {{< /text >}}

    Зверніть увагу, що може знадобитися кілька секунд для розповсюдження політики авторизації на sidecar.

1. Перевірте, що запити до `httpbin` з:

    * `curl` в просторі імен `default` відхилені.

        {{< text bash >}}
        $ kubectl exec "$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
        403
        {{< /text >}}

    * `curl` в просторі імен `curl-allow` дозволені.

        {{< text bash >}}
        $ kubectl exec "$(kubectl -n curl-allow get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -n curl-allow -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
        200
        {{< /text >}}

## Міграція домену довіри без аліасів домену довіри {#migrate-trust-domain-without-trust-domain-aliases}

1. Встановіть Istio з новим доменом довіри.

    {{< text bash >}}
    $ istioctl install --set profile=demo --set meshConfig.trustDomain=new-td
    {{< /text >}}

1. Перезапустіть istiod, щоб застосувати зміни домену довіри.

    {{< text bash >}}
    $ kubectl rollout restart deployment -n istio-system istiod
    {{< /text >}}

    Istio mesh тепер працює з новим доменом довіри, `new-td`.

2. Перезавантажте застосунки `httpbin` і `curl`, щоб вони отримали зміни від нової панелі управління Istio.

    {{< text bash >}}
    $ kubectl delete pod --all
    {{< /text >}}

    {{< text bash >}}
    $ kubectl delete pod --all -n curl-allow
    {{< /text >}}

3. Перевірте, що запити до `httpbin` з обох просторів імен `curl` у `default` та `curl-allow` відхилені.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

    {{< text bash >}}
    $ kubectl exec "$(kubectl -n curl-allow get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -n curl-allow -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
    403
    {{< /text >}}

    Це тому, що ми вказали політику авторизації, яка забороняє всі запити до `httpbin`, крім запитів з ідентифікатора `old-td/ns/curl-allow/sa/curl`, що є старим ідентифікатором програми `curl` у просторі імен `curl-allow`. Коли ми перейшли до нового домену довіри, тобто `new-td`, ідентифікатор цієї програми `curl` тепер `new-td/ns/curl-allow/sa/curl`, що відрізняється від `old-td/ns/curl-allow/sa/curl`. Тому запити з програми `curl` у просторі імен `curl-allow` до `httpbin`, які раніше були дозволені, тепер відхиляються. До Istio 1.4 єдиний спосіб це виправити — змінити політику авторизації вручну. У Istio 1.4 ми представляємо простий спосіб, як показано нижче.

## Міграція домену довіри з аліасами домену довіри {#migrate-trust-domain-with-trust-domain-aliases}

1. Встановіть Istio з новим доменом довіри та псевдонімами домену довіри.

    {{< text bash >}}
    $ cat <<EOF > ./td-installation.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      meshConfig:
        trustDomain: new-td
        trustDomainAliases:
          - old-td
    EOF
    $ istioctl install --set profile=demo -f td-installation.yaml -y
    {{< /text >}}

1. Не змінюючи політику авторизації, перевірте, що запити до `httpbin` з:

    * `curl` в просторі імен `default` відхилені.

        {{< text bash >}}
        $ kubectl exec "$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
        403
        {{< /text >}}

    * `curl` в просторі імен `curl-allow` дозволені.

        {{< text bash >}}
        $ kubectl exec "$(kubectl -n curl-allow get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -n curl-allow -- curl http://httpbin.default:8000/ip -sS -o /dev/null -w "%{http_code}\n"
        200
        {{< /text >}}

## Найкращі практики {#best-practices}

Починаючи з Istio 1.4, при написанні політики авторизації слід розглянути можливість використання значення `cluster.local` як частини домену довіри в політиці. Наприклад, замість `old-td/ns/curl-allow/sa/curl`, це має бути `cluster.local/ns/curl-allow/sa/curl`. Зверніть увагу, що в цьому випадку `cluster.local` не є доменом довіри Istio mesh (домен довіри залишається `old-td`). Однак, у політиці авторизації `cluster.local` є покажчиком, який вказує на поточний домен довіри, тобто `old-td` (а пізніше `new-td`), а також на його псевдоніми. Використовуючи `cluster.local` у політиці авторизації, коли ви мігруєте до нового домену довіри, Istio виявить це та розгляне новий домен довіри як старий домен довіри без необхідності включення псевдонімів.

## Очищення {#clean-up}

{{< text bash >}}
$ kubectl delete authorizationpolicy service-httpbin.default.svc.cluster.local
$ kubectl delete deploy httpbin; kubectl delete service httpbin; kubectl delete serviceaccount httpbin
$ kubectl delete deploy curl; kubectl delete service curl; kubectl delete serviceaccount curl
$ istioctl uninstall --purge -y
$ kubectl delete namespace curl-allow istio-system
$ rm ./td-installation.yaml
{{< /text >}}
