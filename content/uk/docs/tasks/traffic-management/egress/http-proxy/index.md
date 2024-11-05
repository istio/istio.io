---
title: Використання зовнішнього HTTPS-проксі
description: Описує, як налаштувати Istio, щоб дозволити застосункам використовувати зовнішній HTTPS проксі.
weight: 70
keywords: [traffic-management,egress]
aliases:
  - /uk/docs/examples/advanced-gateways/http-proxy/
owner: istio/wg-networking-maintainers
test: yes
---
Приклад [Налаштування Egress Gateway](/docs/tasks/traffic-management/egress/egress-gateway/) показує, як спрямовувати трафік до зовнішніх сервісів з вашої сервісної мережі через компонент Istio на периметрі мережі, який називається _Egress Gateway_. Однак у деяких випадках необхідно використовувати зовнішній, застарілий (non-Istio) HTTPS-проксі для доступу до зовнішніх сервісів. Наприклад, у вашій компанії може вже бути налаштований такий проксі, і всі застосунки в організації можуть бути зобовʼязані спрямовувати свій трафік через нього.

Цей приклад показує, як забезпечити доступ до зовнішнього HTTPS-проксі. Оскільки застосунки використовують метод HTTP [CONNECT](https://tools.ietf.org/html/rfc7231#section-4.3.6) для встановлення зʼєднань з HTTPS-проксі, конфігурація трафіку до зовнішнього HTTPS-проксі відрізняється від конфігурації трафіку до зовнішніх HTTP та HTTPS-сервісів.

{{< boilerplate before-you-begin-egress >}}

*   [Увімкніть реєстрування доступу в Envoy](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

## Розгортання HTTPS-проксі {#deploy-an-https-proxy}

Щоб змоделювати застарілий проксі та лише для цього прикладу, розгорніть HTTPS-проксі всередині вашого кластера. Також, щоб змоделювати більш реалістичний проксі, який працює поза вашим кластером, ви будете звертатися до podʼа проксі за його IP-адресою, а не за доменним іменем сервісу Kubernetes. Цей приклад використовує [Squid](http://www.squid-cache.org), але ви можете використовувати будь-який HTTPS-проксі, який підтримує HTTP CONNECT.

1. Створіть простір імен для HTTPS-проксі, не позначаючи його міткою для інʼєкції sidecar. Без мітки інʼєкція sidecar відключена в новому просторі імен, тому Istio не буде контролювати трафік там. Вам потрібна ця поведінка для моделювання проксі поза кластером.

    {{< text bash >}}
    $ kubectl create namespace external
    {{< /text >}}

1.  Створіть конфігураційний файл для проксі-сервера Squid.

    {{< text bash >}}
    $ cat <<EOF > ./proxy.conf
    http_port 3128

    acl SSL_ports port 443
    acl CONNECT method CONNECT

    http_access deny CONNECT !SSL_ports
    http_access allow localhost manager
    http_access deny manager
    http_access allow all

    coredump_dir /var/spool/squid
    EOF
    {{< /text >}}

1.  Створіть Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
    для зберігання конфігурації проксі-сервера:

    {{< text bash >}}
    $ kubectl create configmap proxy-configmap -n external --from-file=squid.conf=./proxy.conf
    {{< /text >}}

1.  Розгорніть контейнер Squid:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: squid
      namespace: external
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: squid
      template:
        metadata:
          labels:
            app: squid
        spec:
          volumes:
          - name: proxy-config
            configMap:
              name: proxy-configmap
          containers:
          - name: squid
            image: sameersbn/squid:3.5.27
            imagePullPolicy: IfNotPresent
            volumeMounts:
            - name: proxy-config
              mountPath: /etc/squid
              readOnly: true
    EOF
    {{< /text >}}

1.  Розгорніть зразок [sleep]({{< github_tree >}}/samples/sleep) у просторі імен `external` для тестування трафіку на проксі без контролю трафіку Istio.

    {{< text bash >}}
    $ kubectl apply -n external -f @samples/sleep/sleep.yaml@
    {{< /text >}}

1.  Отримайте IP-адресу проксі-сервера і визначте змінну оточення `PROXY_IP` для її зберігання:

    {{< text bash >}}
    $ export PROXY_IP="$(kubectl get pod -n external -l app=squid -o jsonpath={.items..podIP})"
    {{< /text >}}

1.  Визначте змінну оточення `PROXY_PORT` для зберігання порту вашого проксі. У цьому випадку Squid використовує порт 3128.

    {{< text bash >}}
    $ export PROXY_PORT=3128
    {{< /text >}}

1.  Надішліть запит з пода `sleep` в просторі імен `external` до зовнішнього сервіса через проксі:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n external -l app=sleep -o jsonpath={.items..metadata.name})" -n external -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1.  Перевірте журнал доступу проксі-сервера на наявність вашого запиту:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name})" -n external -- tail /var/log/squid/access.log
    1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
    {{< /text >}}

Наразі ви виконали наступні завдання без Istio:

* Ви розгорнули HTTPS проксі.
* Ви використовували `curl` для доступу до зовнішнього сервісу `wikipedia.org` через проксі.

Далі, ви повинні налаштувати трафік з podʼів з підтримкою Istio на використання HTTPS-проксі.

## Налаштування трафіку до зовнішнього HTTPS-проксі {#configure-traffic-to-external-https-proxy}

1. Визначте Service Entry для HTTPS-проксі з протоколом TCP (не HTTP!). Хоча застосунки використовують метод HTTP CONNECT для встановлення зʼєднань з HTTPS-проксі, вам потрібно налаштувати проксі для TCP-трафіку, а не для HTTP. Як тільки зʼєднання буде встановлено, проксі просто діє як TCP-тунель.

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: proxy
    spec:
      hosts:
      - my-company-proxy.com # ignored
      addresses:
      - $PROXY_IP/32
      ports:
      - number: $PROXY_PORT
        name: tcp
        protocol: TCP
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1.  Надішліть запит з пода `sleep` в просторі імен `default`. Оскільки под `sleep` має sidecar, Istio контролює його трафік.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- sh -c "HTTPS_PROXY=$PROXY_IP:$PROXY_PORT curl https://en.wikipedia.org/wiki/Main_Page" | grep -o "<title>.*</title>"
    <title>Wikipedia, the free encyclopedia</title>
    {{< /text >}}

1.  Перевірте журнали sidecar-проксі Istio для вашого запиту:

    {{< text bash >}}
    $ kubectl logs "$SOURCE_POD" -c istio-proxy
    [2018-12-07T10:38:02.841Z] "- - -" 0 - 702 87599 92 - "-" "-" "-" "-" "172.30.109.95:3128" outbound|3128||my-company-proxy.com 172.30.230.52:44478 172.30.109.95:3128 172.30.230.52:44476 -
    {{< /text >}}

2.  Перевірте журнал доступу проксі на наявність вашого запиту:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n external -l app=squid -o jsonpath={.items..metadata.name})" -n external -- tail /var/log/squid/access.log
    1544160065.248    228 172.30.109.89 TCP_TUNNEL/200 87633 CONNECT en.wikipedia.org:443 - HIER_DIRECT/91.198.174.192 -
    {{< /text >}}

## Розуміння того, що відбулося {#understanding-what-happened}

В цьому прикладі ви виконали наступні кроки:

1. Розгорнули HTTPS-проксі для моделювання зовнішнього проксі.
2. Створили TCP-сервісний запис, щоб дозволити трафіку під контролем Istio до зовнішнього проксі.

Зверніть увагу, що не слід створювати сервісні записи для зовнішніх сервісів, до яких ви звертаєтеся через зовнішній проксі, таких як `wikipedia.org`. Це повʼязано з тим, що з погляду Istio запити надсилаються тільки до зовнішнього проксі; Istio не знає, що зовнішній проксі далі пересилає запити.

## Очищення {#cleanup}

1. Завершіть роботу сервісу [sleep]({{< github_tree >}}/samples/sleep):

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

2. Завершіть роботу сервісу [sleep]({{< github_tree >}}/samples/sleep) в просторі імен `external`:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@ -n external
    {{< /text >}}

3. Завершіть роботу проксі Squid, видаліть `ConfigMap` і конфігураційний файл:

    {{< text bash >}}
    $ kubectl delete -n external deployment squid
    $ kubectl delete -n external configmap proxy-configmap
    $ rm ./proxy.conf
    {{< /text >}}

4. Видаліть простір імен `external`:

    {{< text bash >}}
    $ kubectl delete namespace external
    {{< /text >}}

5. Видаліть Service Entry:

    {{< text bash >}}
    $ kubectl delete serviceentry proxy
    {{< /text >}}
