---
title: Kubernetes Services для вихідного трафіку
description: Показує, як налаштувати Istio для зовнішніх служб Kubernetes.
keywords: [traffic-management,egress]
weight: 60
owner: istio/wg-networking-maintainers
test: yes
---

Kubernetes-сервіси [ExternalName](https://kubernetes.io/docs/concepts/services-networking/service/#externalname) та Kubernetes-сервіси з [Endpoints](https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors) дозволяють створити локальний DNS _псевдонім_ для зовнішнього сервісу. Цей DNS-псевдонім має такий же формат, як і DNS-записи для локальних сервісів, а саме `<імʼя сервісу>.<імʼя простору імен>.svc.cluster.local`. DNS-псевдоніми забезпечують _прозорість розташування_ для ваших робочих навантажень: робочі навантаження можуть викликати як локальні, так і зовнішні сервіси однаковим чином. Якщо в певний момент ви вирішите розгорнути зовнішній сервіс всередині свого кластера, ви можете просто оновити його Kubernetes-сервіс для посилання на локальну версію. Робочі навантаження продовжать працювати без будь-яких змін.

Це завдання показує, що ці механізми Kubernetes для доступу до зовнішніх сервісів продовжують працювати з Istio. Єдиний крок конфігурації, який потрібно виконати, це використати TLS-режим, відмінний від [взаємного TLS](/docs/concepts/security/#mutual-tls-authentication) Istio. Зовнішні сервіси не є частиною сервісної мережі Istio, тому вони не можуть виконувати взаємний TLS Istio. Ви повинні встановити TLS-режим відповідно до вимог TLS зовнішнього сервісу та способу, яким ваші робочі навантаження звертаються до зовнішнього сервісу. Якщо ваші робочі навантаження виконують прості HTTP-запити, а зовнішній сервіс вимагає TLS, можливо, вам варто виконати ініціалізацію TLS через Istio. Якщо ваші робочі навантаження вже використовують TLS, трафік вже зашифрований, то ви можете просто вимкнути взаємний TLS Istio.

{{< warning >}}
Ця сторінка описує, як Istio може інтегруватися з наявними конфігураціями Kubernetes. Для нових розгортань ми рекомендуємо дотримуватися інструкцій у розділі [Доступ до зовнішніх сервісів](/docs/tasks/traffic-management/egress/egress-control/).
{{< /warning >}}

Хоча в прикладах цього завдання використовуються HTTP-протоколи, Kubernetes-сервіси для вихідного трафіку працюють також з іншими протоколами.

{{< boilerplate before-you-begin-egress >}}

*  Створіть простір імен для вихідного pod без керування Istio:

    {{< text bash >}}
    $ kubectl create namespace without-istio
    {{< /text >}}

*  Запустіть зразок [sleep]({{< github_tree >}}/samples/sleep) у просторі імен `without-istio`.

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@ -n without-istio
    {{< /text >}}

*   Для надсилання запитів створіть змінну оточення `SOURCE_POD_WITHOUT_ISTIO` для зберігання назви джерела podʼа:

    {{< text bash >}}
    $ export SOURCE_POD_WITHOUT_ISTIO="$(kubectl get pod -n without-istio -l app=sleep -o jsonpath={.items..metadata.name})"
    {{< /text >}}

*   Переконайтеся, що sidecar Istio не була додано, тобто pod має один контейнер:

    {{< text bash >}}
    $ kubectl get pod "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio
    NAME                     READY   STATUS    RESTARTS   AGE
    sleep-66c8d79ff5-8tqrl   1/1     Running   0          32s
    {{< /text >}}

## Сервіс Kubernetes ExternalName для доступу до зовнішніх сервісів {#kubernetes-externalname-service-to-access-an-external-service}

1.  Створіть сервіс Kubernetes [ExternalName](https://kubernetes.io/docs/concepts/services-networking/service/#externalname) для `httpbin.org` у просторі імен default:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Service
    apiVersion: v1
    metadata:
      name: my-httpbin
    spec:
      type: ExternalName
      externalName: httpbin.org
      ports:
      - name: http
        protocol: TCP
        port: 80
    EOF
    {{< /text >}}

1.  Поспостерігайте за своїм сервісом. Зверніть увагу, що він не має кластерного IP.

    {{< text bash >}}
    $ kubectl get svc my-httpbin
    NAME         TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
    my-httpbin   ExternalName   <none>       httpbin.org   80/TCP    4s
    {{< /text >}}

1.  Отримайте доступ до `httpbin.org` через імʼя хосту сервісу Kubernetes з вихідного podʼа без Istio sidecar. Зверніть увагу, що команда _curl_ нижче використовує [формат DNS Kubernetes для сервісів](https://v1-13.docs.kubernetes.io/docs/concepts/services-networking/dns-pod-service/#a-records): `<назва сервісу>.<простір імен>.svc.cluster.local`.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio -c sleep -- curl -sS my-httpbin.default.svc.cluster.local/headers
    {
      "headers": {
        "Accept": "*/*",
        "Host": "my-httpbin.default.svc.cluster.local",
        "User-Agent": "curl/7.55.0"
      }
    }
    {{< /text >}}

1.  У цьому прикладі незашифровані HTTP-запити надсилаються на `httpbin.org`. Лише для прикладу, ви відключаєте режим TLS і дозволити незашифрований трафік до зовнішнього сервісу. У реальних сценаріях ми рекомендуємо виконати [Створення TLS для вихідного трафіку](/docs/tasks/traffic-management/egress/egress-tls-origination/) за допомогою Istio.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: my-httpbin
    spec:
      host: my-httpbin.default.svc.cluster.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

1.  Отримайте доступ до `httpbin.org` через імʼя хоста Kubernetes-сервісу з вихідного podʼа з Istio sidecar. Зверніть увагу на заголовки, додані Istio sidecar, наприклад, `X-Envoy-Decorator-Operation`. Також зауважте, що заголовок `Host` дорівнює імені хосту вашого сервісу.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sS my-httpbin.default.svc.cluster.local/headers
    {
      "headers": {
        "Accept": "*/*",
        "Content-Length": "0",
        "Host": "my-httpbin.default.svc.cluster.local",
        "User-Agent": "curl/7.64.0",
        "X-B3-Sampled": "0",
        "X-B3-Spanid": "5795fab599dca0b8",
        "X-B3-Traceid": "5079ad3a4af418915795fab599dca0b8",
        "X-Envoy-Decorator-Operation": "my-httpbin.default.svc.cluster.local:80/*",
        "X-Envoy-Peer-Metadata": "...",
        "X-Envoy-Peer-Metadata-Id": "sidecar~10.28.1.74~sleep-6bdb595bcb-drr45.default~default.svc.cluster.local"
      }
    }
    {{< /text >}}

### Видалення сервісу Kubernetes ExternalName {#cleanup-of-kubernetes-externalname-service}

{{< text bash >}}
$ kubectl delete destinationrule my-httpbin
$ kubectl delete service my-httpbin
{{< /text >}}

## Використовуйте сервіс Kubernetes з точками доступу до зовнішнього сервісу {#use-a-kubernetes-service-with-endpoints-to-access-an-external-service}

1.  Створіть сервіс Kubernetes без селектора для Вікіпедії:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Service
    apiVersion: v1
    metadata:
      name: my-wikipedia
    spec:
      ports:
      - protocol: TCP
        port: 443
        name: tls
    EOF
    {{< /text >}}

2.  Створіть точки доступу для вашого сервісу. Виберіть кілька IP-адрес зі списку діапазонів Вікіпедії (https://www.mediawiki.org/wiki/Wikipedia_Zero/IP_Addresses).

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    kind: Endpoints
    apiVersion: v1
    metadata:
      name: my-wikipedia
    subsets:
      - addresses:
          - ip: 198.35.26.96
          - ip: 208.80.153.224
        ports:
          - port: 443
            name: tls
    EOF
    {{< /text >}}

3.  Поспостерігайте за своїм сервісом. Зверніть увагу, що він має кластерний IP, який ви можете використовувати для доступу до `wikipedia.org`.

    {{< text bash >}}
    $ kubectl get svc my-wikipedia
    NAME           TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
    my-wikipedia   ClusterIP   172.21.156.230   <none>        443/TCP   21h
    {{< /text >}}

4.  Надсилайте HTTPS-запити до `wikipedia.org` за IP кластера вашого сервісу Kubernetes з вихідного podʼа без Istio sidecar. Використовуйте параметр `--resolve` у команді `curl` для доступу до `wikipedia.org` за кластерною IP-адресою:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD_WITHOUT_ISTIO" -n without-istio -c sleep -- curl -sS --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

5.  У цьому випадку робоче навантаження надсилає HTTPS-запити (відкрите TLS-зʼєднання) до `wikipedia.org`. Трафік вже зашифрований робочим навантаженням зашифрований робочим навантаженням, тому ви можете безпечно відключити взаємний TLS в Istio:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: my-wikipedia
    spec:
      host: my-wikipedia.default.svc.cluster.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

6.  Отримайте доступ до `wikipedia.org` за IP-адресою кластера вашого сервісу Kubernetes з вихідного podʼа за допомогою sidecar Istio:

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sS --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

7.  Переконайтеся, що доступ дійсно виконується з IP кластера. Зверніть увагу на речення `Connected to en.wikipedia.org (172.21.156.230)` у виводі `curl -v`, в ньому згадується IP, який було надруковано у виводі вашого сервісу як IP кластера.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- curl -sS -v --resolve en.wikipedia.org:443:"$(kubectl get service my-wikipedia -o jsonpath='{.spec.clusterIP}')" https://en.wikipedia.org/wiki/Main_Page -o /dev/null
    * Added en.wikipedia.org:443:172.21.156.230 to DNS cache
    * Hostname en.wikipedia.org was found in DNS cache
    *   Trying 172.21.156.230...
    * TCP_NODELAY set
    * Connected to en.wikipedia.org (172.21.156.230) port 443 (#0)
    ...
    {{< /text >}}

### Видалення сервісу Kubernetes з точками доступу {#cleanup-of-kubernetes-service-with-endpoints}

{{< text bash >}}
$ kubectl delete destinationrule my-wikipedia
$ kubectl delete endpoints my-wikipedia
$ kubectl delete service my-wikipedia
{{< /text >}}

## Очищення {#cleanup}

1.  Вимкніть сервіс [sleep]({{< github_tree >}}/samples/sleep):

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  Вимкніть сервіс [sleep]({{< github_tree >}}/samples/sleep) у просторі імен `without-istio`:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n without-istio
    {{< /text >}}

2.  Видаліть простір імен `without-istio`:

    {{< text bash >}}
    $ kubectl delete namespace without-istio
    {{< /text >}}

3. Скиньте змінні оточення:

    {{< text bash >}}
    $ unset SOURCE_POD SOURCE_POD_WITHOUT_ISTIO
    {{< /text >}}
