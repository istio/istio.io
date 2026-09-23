---
title: Egress з використанням шаблонів хостів
description: Описує, як увімкнути вихідний трафік для набору хостів у спільному домені, замість того, щоб налаштовувати кожен хост окремо.
keywords: [traffic-management,egress]
weight: 50
aliases:
  - /docs/examples/advanced-gateways/wildcard-egress-hosts/
owner: istio/wg-networking-maintainers
test: yes
---

Завдання [Доступ до зовнішніх сервісів](/docs/tasks/traffic-management/egress/egress-control) та приклад [Налаштування Egress Gateway](/docs/tasks/traffic-management/egress/egress-gateway/) описують, як налаштувати вихідний трафік для конкретних доменів, таких як `edition.cnn.com`. Цей приклад показує, як увімкнути вихідний трафік для набору хостів у спільному домені, наприклад `*.wikipedia.org`, замість того, щоб налаштовувати кожен хост окремо.

## Контекст {#background}

Припустимо, ви хочете увімкнути вихідний трафік в Istio для сайтів `wikipedia.org` всіма мовами. Кожна версія `wikipedia.org` для конкретної мови має свій власний хост, наприклад, `en.wikipedia.org` та `uk.wikipedia.org` для англійської та української відповідно. Ви хочете увімкнути вихідний трафік за допомогою загальних конфігураційних елементів для всіх сайтів Wikipedia, без необхідності вказувати сайт для кожної мови окремо.

{{< boilerplate gateway-api-support >}}

## Перш ніж почати {#before-you-begin}

*   Встановіть Istio з увімкненим журналюванням доступу та політикою стандартного блокування вихідного трафіку:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ istioctl install --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
{{< /text >}}

{{< tip >}}
Ви можете виконати це завдання з конфігурацією Istio, відмінній від профілю `demo`, за умови, що ви [розгорнете вихідний шлюз Istio](/docs/tasks/traffic-management/egress/egress-gateway/#deploy-istio-egress-gateway),
[увімкнете доступ до журналів Envoy](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging), та [застосуєте політику стандартного блокування вихідного трафіку](/docs/tasks/traffic-management/egress/egress-control/#change-to-the-blocking-by-default-policy) у вашому встановленні.
{{< /tip >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ istioctl install --set profile=minimal -y \
    --set values.pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true \
    --set meshConfig.accessLogFile=/dev/stdout \
    --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

*   Розгорніть демонстраційний застосунок [curl]({{< github_tree >}}/samples/curl) для використання його як джерела тестових запитів.
Якщо у вас увімкнено [автоматична інʼєкія sidecar](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), виконайте наступну команду для розгортання застосунку:

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    В іншому випадку, вручну додайте sidecar перед розгортанням застосунку `curl` за допомогою наступної команди:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@)
    {{< /text >}}

    {{< tip >}}
    Ви можете використовувати будь-який pod з `curl` для надсилання тестових запитів.
    {{< /tip >}}

*   Встановіть змінну оточення `SOURCE_POD` на імʼя вашого тестового podʼа:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}

## Налаштування прямого трафіку до хосту за шаблоном {#direct-traffic-to-wildcard-host}

Перший, і найпростіший, спосіб отримати доступ до набору хостів у спільному домені — це налаштування простого `ServiceEntry` зі знаком підстановки та виклик сервісів безпосередньо з sidecar. Коли ви викликаєте сервіси безпосередньо (тобто не через вихідний шлюз), конфігурація для знака підстановки не відрізняється від конфігурації будь-якого іншого (наприклад, повністю кваліфікованого) хосту, а є тільки зручнішим, коли багато хостів присутньо в спільному домені.

{{< warning >}}
Зверніть увагу, що зловмисний застосунок може легко оминути конфігурацію нижче. Для забезпечення безпеки контролю вихідного трафіку направляйте трафік через вихідний шлюз.
{{< /warning >}}

{{< warning >}}
Зверніть увагу, що `DNS` розвʼязання не може бути використане для знаків підстановки. Тому в записі служби нижче використовується розвʼязання `NONE` (яка пропущена, оскільки є стандартним значенням).
{{< /warning >}}

1.  Визначте `ServiceEntry` для `*.wikipedia.org`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      ports:
      - number: 443
        name: https
        protocol: HTTPS
    EOF
    {{< /text >}}

2.  Надішліть HTTPS-запит до [https://en.wikipedia.org](https://en.wikipedia.org) та [https://uk.wikipedia.org](https://uk.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://uk.wikipedia.org/wiki/Головна_сторінка | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Вікіпедія</title>
    {{< /text >}}

### Вилучення налаштувань для прямого трафіку до хосту за шаблоном {#cleanup-direct-traffic-to-wildcard-host}

{{< text bash >}}
$ kubectl delete serviceentry wikipedia
{{< /text >}}

## Налаштування трафіку через вихідний шлюз до хосту з підстановочним знаком {#configure-egress-gateway-traffic-to-wildcard-host}

Коли всі хости з підстановочним знаком обслуговуються одним сервером, конфігурація для доступу через вихідний шлюз до хосту з підстановочним знаком дуже схожа на конфігурацію для будь-якого іншого хосту, з однією відмінністю: кінцевий пункт маршруту не буде тим же, що й налаштований хост, тобто підстановочним знаком. Замість цього буде налаштовано хост єдиного сервера для набору доменів.

1.  Створіть вихідний `Gateway` для _*.wikipedia.org_ та правила маршрутизації, щоб направити трафік через вихідний шлюз і з вихідного шлюзу до зовнішнього сервісу:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: istio-egressgateway
spec:
  selector:
    istio: egressgateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "*.wikipedia.org"
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-wikipedia
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
    - name: wikipedia
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-wikipedia-through-egress-gateway
spec:
  hosts:
  - "*.wikipedia.org"
  gateways:
  - mesh
  - istio-egressgateway
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
      - "*.wikipedia.org"
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: wikipedia
        port:
          number: 443
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
      sniHosts:
      - "*.wikipedia.org"
    route:
    - destination:
        host: www.wikipedia.org
        port:
          number: 443
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: wikipedia-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: tls
    hostname: "*.wikipedia.org"
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: direct-wikipedia-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: wikipedia
  rules:
  - backendRefs:
    - name: wikipedia-egress-gateway-istio
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: forward-wikipedia-from-egress-gateway
spec:
  parentRefs:
  - name: wikipedia-egress-gateway
  hostnames:
  - "*.wikipedia.org"
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: www.wikipedia.org
      port: 443
---
apiVersion: networking.istio.io/v1
kind: ServiceEntry
metadata:
  name: wikipedia
spec:
  hosts:
  - "*.wikipedia.org"
  ports:
  - number: 443
    name: https
    protocol: HTTPS
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Створіть `ServiceEntry` для сервера призначення, _www.wikipedia.org_:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: www-wikipedia
    spec:
      hosts:
      - www.wikipedia.org
      ports:
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

3)  Надсилайте HTTPS-запити на адреси
    [https://en.wikipedia.org](https://en.wikipedia.org) та [https://uk.wikipedia.org](https://uk.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://uk.wikipedia.org/wiki/Головна_сторінка | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Вікіпедія</title>
    {{< /text >}}

4)  Перевірте статистику проксі вихідного шлюзу на наявність лічильника, який відповідає вашим запитам до _*.wikipedia.org_:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -n istio-system -- pilot-agent request GET clusters | grep '^outbound|443||www.wikipedia.org.*cx_total:'
outbound|443||www.wikipedia.org::208.80.154.224:443::cx_total::2
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l gateway.networking.k8s.io/gateway-name=wikipedia-egress-gateway -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -- pilot-agent request GET clusters | grep '^outbound|443||www.wikipedia.org.*cx_total:'
outbound|443||www.wikipedia.org::208.80.154.224:443::cx_total::2
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Вилучення налаштувань трафіку через вихідний шлюз до хосту з підстановочним знаком {#cleanup-egress-gateway-traffic-to-a-wildcard-host}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry www-wikipedia
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-wikipedia
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete se wikipedia
$ kubectl delete se www-wikipedia
$ kubectl delete gtw wikipedia-egress-gateway
$ kubectl delete tlsroute direct-wikipedia-to-egress-gateway
$ kubectl delete tlsroute forward-wikipedia-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Конфігурація підстановочного знака для довільних доменів {#wildcard-configuration-for-arbitrary-domains}

Конфігурація в попередньому розділі працювала, оскільки всі сайти `*.wikipedia.org` можуть обслуговуватися будь-яким із серверів `wikipedia.org`. Однак це не завжди так. Наприклад, ви можете захотіти налаштувати контроль вихідного трафіку для доступу до більш загальних доменів з підстановочними знаками, таких як `*.com` або `*.org`. Налаштування трафіку для довільних доменів з підстановочними знаками створює проблему для шлюзів Istio; шлюз Istio можна налаштувати лише для маршрутизації трафіку до попередньо визначених хостів, попередньо визначених IP-адрес або до початкової IP-адреси призначення запиту.

У попередньому розділі ви налаштували віртуальний сервіс для перенаправлення трафіку на попередньо визначений хост `www.wikipedia.org`. Однак у загальному випадку ви не знаєте хост або IP-адресу, які можуть обслуговувати довільний хост, отриманий у запиті, що залишає початкову адресу призначення запиту єдиним значенням, за допомогою якого можна маршрутизувати запит. На жаль, при використанні вихідного шлюзу початкова адреса призначення запиту втрачається, оскільки початковий запит перенаправляється на шлюз, що призводить до зміни IP-адреси призначення на IP-адресу шлюзу.

Хоча цей підхід є не таким простим і дещо вразливим, оскільки він залежить від деталей реалізації Istio, ви можете використовувати [фільтри Envoy](/docs/reference/config/networking/envoy-filter/) для налаштування шлюзу на підтримку довільних доменів за допомогою значення [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) в запиті HTTPS або будь-якому запиті TLS для ідентифікації початкового призначення, до якого потрібно маршрутизувати запит. Один із прикладів такого підходу можна знайти в статті [маршрутизація вихідного трафіку до підстановочних пунктів призначення](/blog/2023/egress-sni/).

## Очищення {#cleanup}

* Зупиніть сервіс [curl]({{< github_tree >}}/samples/curl):

    {{< text bash >}}
    $ kubectl delete -f @samples/curl/curl.yaml@
    {{< /text >}}

* Видаліть Istio з вашого кластера:

    {{< text bash >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}
