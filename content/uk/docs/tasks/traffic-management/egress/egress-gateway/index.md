---
title: Egress Gateways
description: Описує, як налаштувати Istio для перенаправлення трафіку на зовнішні сервіси через виділений шлюз.
weight: 30
keywords: [traffic-management,egress]
aliases:
  - /uk/docs/examples/advanced-gateways/egress-gateway/
owner: istio/wg-networking-maintainers
test: yes
---

{{<warning>}}
Цей приклад не працює в Minikube.
{{</warning>}}

Задача [Доступ до зовнішніх сервісів](/docs/tasks/traffic-management/egress/egress-control) показує, як налаштувати Istio для дозволу доступу до зовнішніх HTTP і HTTPS сервісів з застосунків всередині мережі. Там зовнішні сервіси викликаються безпосередньо з клієнтського sidecar. Цей приклад також демонструє, як налаштувати Istio для виклику зовнішніх сервісів, хоча цього разу непрямо через спеціалізований _egress gateway_ сервіс.

Istio використовує [ingress та egress gateways](/docs/reference/config/networking/gateway/) для налаштування балансувальників навантаження, які працюють на краю сервісної мережі. Ingress gateway дозволяє визначити точки входу в мережу, через які проходить весь вхідний трафік. Egress gateway є симетричною концепцією; він визначає точки виходу з мережі. Egress gateways дозволяють застосовувати можливості Istio, наприклад, моніторинг та правила маршрутизації, до трафіку, що виходить з мережі.

## Використання {#use-case}

Розгляньте організацію, яка має суворі вимоги до безпеки, що весь трафік, який покидає сервісну мережу, повинен проходити через набір спеціалізованих вузлів. Ці вузли будуть працювати на окремих машинах, відокремлених від решти вузлів, які запускають застосунки в кластері. Ці спеціальні вузли будуть служити для застосування політики до вихідного трафіку і будуть моніторитися ретельніше, ніж інші вузли.

Інший випадок використання — кластер, де вузли застосунків не мають публічних IP-адрес, тому сервіси всередині мережі, які на них працюють, не можуть отримати доступ до Інтернету. Визначення egress gateway, що спрямовує весь вихідний трафік через себе, і виділення публічних IP-адрес для вузлів egress gateway дозволяє вузлам застосунків отримувати контрольований доступ до зовнішніх сервісів.

{{< boilerplate gateway-api-gamma-experimental >}}

## Перш ніж почати {#before-you-begin}

* Налаштуйте Istio, дотримуючись інструкцій з [Посібника з встановлення](/docs/setup/).

    {{< tip >}}
    Egress gateway і журналювання доступу буде увімкнено, якщо ви встановите
    [профіль конфігурації](/docs/setup/additional-setup/config-profiles/) `demo`.
    {{< /tip >}}

*   Розгорніть демонстраційний застосунок [curl]({{< github_tree >}}/samples/curl), щоб використовувати його як джерело для надсилання тестових запитів.

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    {{< tip >}}
    You can use any pod with `curl` installed as a test source.
    {{< /tip >}}

*   Встановіть змінну оточення `SOURCE_POD` на імʼя вашого вихідного podʼа:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}

    {{< warning >}}
    Інструкції в цьому завданні створюють правило призначення для egress gateway в просторі імен `default` і припускають, що клієнт `SOURCE_POD` також працює у просторі імен `default`. Якщо ні, то правило призначення не буде знайдено за адресою [правил пошуку шляху призначення](/docs/ops/best-practices/traffic-management/#cross-namespace-configuration) і клієнтські запити не будуть виконані.
    {{< /warning >}}

*   [Увімкніть ведення журналу доступу Envoy](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging) якщо його ще не ввімкнено. Наприклад, за допомогою `istioctl`:

    {{< text bask >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
    {{< /text >}}

## Розгортання egress gateway Istio {#deploy-isito-egress-gateway}

{{< tip >}}
Egress gateways автоматично [розгортаються](/docs/tasks/traffic-management/ingress/gateway-api/#deployment-methods) при використанні Gateway API для їх налаштування. Ви можете пропустити цей розділ, якщо ви користуєтеся інструкціями `Gateway API` в наступних розділах.
{{< /tip >}}

1.  Перевірте чи розгорнтуо Istio egress gateway:

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway -n istio-system
    {{< /text >}}

    Якщо жодного з podʼів не було повернено, розгорніть Istio egress gateway, виконавши наступний крок.

2.  Якщо ви використовували CR `IstioOperator` для встановлення Istio, додайте наступні поля до конфігурації:

    {{< text yaml >}}
    spec:
      components:
        egressGateways:
        - name: istio-egressgateway
          enabled: true
    {{< /text >}}

    В іншому випадку, додайте еквівалентні параметри, наприклад, до вашої оригінальної команди `istioctl install`:

    {{< text syntax=bash snip_id=none >}}
    $ istioctl install <flags-you-used-to-install-Istio> \
                       --set "components.egressGateways[0].name=istio-egressgateway" \
                       --set "components.egressGateways[0].enabled=true"
    {{< /text >}}

## Egress gateway для трафіку HTTP {#egress-gateway-for-http-traffic}

Спочатку створіть `ServiceEntry`, щоб дозволити прямий трафік до зовнішнього сервісу.

1.  Визначте `ServiceEntry` для `edition.cnn.com`.

    {{< warning >}}
    Для `ServiceEntry` нижче потрібно використовувати розвʼязання `DNS`. Якщо розвʼязання встановлене на `NONE`, шлюз буде направляти трафік сам на себе в нескінченному циклі. Це відбувається тому, що шлюз отримує запит з оригінальною IP-адресою призначення, яка дорівнює IP-адресі сервісу шлюзу (оскільки запит направляється sidecar проксі до шлюзу).

    При використанні розвʼязання `DNS` шлюз виконує DNS-запит для отримання IP-адреси зовнішнього сервісу і направляє трафік на цю IP-адресу.
    {{< /warning >}}

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

2.  Переконайтеся, що ваш `ServiceEntry` було застосовано правильно, надіславши HTTP-запит на [http://edition.cnn.com/politics](http://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    ...
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

    Результат має бути таким самим, як у прикладі [Створення TLS для вихідного трафіку](/docs/tasks/traffic-management/egress/egress-tls-origination/), без TLS origination.

3.  Створіть `Gateway` для вихідного трафіку до _edition.cnn.com_ на порті 80.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< tip >}}
Щоб спрямувати кілька хостів через  egress gateway, ви можете включити список хостів або використовувати `*`, щоб мати збіг зі всім, у полі `Gateway`. Поле `subset` в `DestinationRule` слід використовувати повторно для додаткових хостів.
{{< /tip >}}

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
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - edition.cnn.com
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    hostname: edition.cnn.com
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)  Налаштуйте правила маршрутизації, щоб спрямувати трафік від sidecars до egress gateway та від egress gateway до зовнішнього сервісу:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - istio-egressgateway
  - mesh
  http:
  - match:
    - gateways:
      - mesh
      port: 80
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 80
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 80
    route:
    - destination:
        host: edition.cnn.com
        port:
          number: 80
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 80
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 80
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  Повторно надішліть HTTP-запит до [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    ...
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

    The output should be the same as in the step 2.

6)  Перевірте журнал podʼа egress gateway на наявність рядка, що відповідає нашому запиту.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Якщо Istio розгорнуто у просторі імен `istio-system`, команда для друку журналу буде такою:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
{{< /text >}}

Ви повинні побачити рядок, схожий на наступний:

{{< text plain >}}
[2019-09-03T20:57:49.103Z] "GET /politics HTTP/2" 301 - "-" "-" 0 0 90 89 "10.244.2.10" "curl/7.64.0" "ea379962-9b5c-4431-ab66-f01994f5a5a5" "edition.cnn.com" "151.101.65.67:80" outbound|80||edition.cnn.com - 10.244.1.5:80 10.244.2.10:50482 edition.cnn.com -
{{< /text >}}

{{< tip >}}
Якщо увімкнено [взаємну автентифікацію TLS](/docs/tasks/security/authentication/authn-policy/), і у вас виникли проблеми з підключенням до egress gateway, виконайте наступну команду, щоб перевірити правильність сертифіката:

{{< text bash >}}
$ istioctl pc secret -n istio-system "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/istio-system/sa/istio-egressgateway-service-account
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Отримайте доступ до журналу, що відповідає egress gateway, використовуючи згенеровану Istio мітку poʼа:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

Ви повинні побачити рядок, схожий на наступний:

{{< text plain >}}
[2024-01-09T15:35:47.283Z] "GET /politics HTTP/1.1" 301 - via_upstream - "-" 0 0 2 2 "172.30.239.55" "curl/7.87.0-DEV" "6c01d65f-a157-97cd-8782-320a40026901" "edition.cnn.com" "151.101.195.5:80" outbound|80||edition.cnn.com 172.30.239.16:55636 172.30.239.16:80 172.30.239.55:59224 - default.forward-cnn-from-egress-gateway.0
{{< /text >}}

{{< tip >}}
Якщо увімкнено [взаємну автентифікацію TLS] (/docs/tasks/security/authentication/authn-policy/), і у вас виникли проблеми з підключенням до egress gateway, виконайте наступну команду, щоб перевірити правильність сертифіката:

{{< text bash >}}
$ istioctl pc secret "$(kubectl get pod -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -o jsonpath='{.items[0].metadata.name}')" -ojson | jq '[.dynamicActiveSecrets[] | select(.name == "default")][0].secret.tlsCertificate.certificateChain.inlineBytes' -r | base64 -d | openssl x509 -text -noout | grep 'Subject Alternative Name' -A 1
            X509v3 Subject Alternative Name: critical
                URI:spiffe://cluster.local/ns/default/sa/cnn-egress-gateway-istio
{{< /text >}}

{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

Зверніть увагу, що ви перенаправили тільки HTTP-трафік з порту 80 через egress gateway.
HTTPS-трафік на порт 443 йшов безпосередньо на _edition.cnn.com_.

### Видалення HTTP-шлюзу {#cleanup-http-gateway}

Видаліть попередні визначення, перш ніж переходити до наступного кроку:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete httproute direct-cnn-to-egress-gateway
$ kubectl delete httproute forward-cnn-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Egress gateway для трафіку HTTPS {#egress-gateway-for-https-traffic}

У цьому розділі ви направляєте HTTPS-трафік (TLS, ініційований застосунком) через egress gateway. Вам потрібно вказати порт 443 з протоколом `TLS` у відповідному `ServiceEntry` і egress `Gateway`.

1.  Визначте `ServiceEntry` для `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
    EOF
    {{< /text >}}

1.  Переконайтеся, що ваш `ServiceEntry` було застосовано правильно, надіславши HTTPS-запит на [https://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    ...
    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

1.  Створіть вихідний `Gateway` для _edition.cnn.com_ і правила маршрутизації, щоб спрямувати трафік через egress gateway і від egress gateway до зовнішнього сервісу.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< tip >}}
Щоб спрямувати кілька хостів через  egress gateway, ви можете включити список хостів або використовувати `*`, щоб мати збіг зі всім, у полі `Gateway`. Поле `subset` в `DestinationRule` слід використовувати повторно для додаткових хостів.
{{< /tip >}}

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
      name: tls
      protocol: TLS
    hosts:
    - edition.cnn.com
    tls:
      mode: PASSTHROUGH
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
---
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-cnn-through-egress-gateway
spec:
  hosts:
  - edition.cnn.com
  gateways:
  - mesh
  - istio-egressgateway
  tls:
  - match:
    - gateways:
      - mesh
      port: 443
      sniHosts:
      - edition.cnn.com
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
        subset: cnn
        port:
          number: 443
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
      sniHosts:
      - edition.cnn.com
    route:
    - destination:
        host: edition.cnn.com
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
  name: cnn-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: tls
    hostname: edition.cnn.com
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
  name: direct-cnn-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: cnn
  rules:
  - backendRefs:
    - name: cnn-egress-gateway-istio
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: forward-cnn-from-egress-gateway
spec:
  parentRefs:
  - name: cnn-egress-gateway
  hostnames:
  - edition.cnn.com
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: edition.cnn.com
      port: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)  Надішліть HTTPS-запит на адресу [https://edition.cnn.com/politics](https://edition.cnn.com/politics). Результат має бути таким самим, як і раніше.

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c curl -- curl -sSL -o /dev/null -D - https://edition.cnn.com/politics
    ...
    HTTP/2 200
    Content-Type: text/html; charset=utf-8
    ...
    {{< /text >}}

5)  Перевірте журнал проксі egress gateway.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Якщо Istio розгорнуто у просторі імен `istio-system`, команда для друку журналу буде такою:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system
{{< /text >}}

Ви повинні побачити рядок, схожий на наступний:

{{< text plain >}}
[2019-01-02T11:46:46.981Z] "- - -" 0 - 627 1879689 44 - "-" "-" "-" "-" "151.101.129.67:443" outbound|443||edition.cnn.com 172.30.109.80:41122 172.30.109.80:443 172.30.109.112:59970 edition.cnn.com
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Отримайте доступ до журналу, що відповідає egress gateway, використовуючи згенеровану Istio мітку podʼа:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

Ви повинні побачити рядок, схожий на наступний:

{{< text plain >}}
[2024-01-11T21:09:42.835Z] "- - -" 0 - - - "-" 839 2504306 231 - "-" "-" "-" "-" "151.101.195.5:443" outbound|443||edition.cnn.com 172.30.239.8:34470 172.30.239.8:443 172.30.239.15:43956 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Видалення HTTPS-шлюзу {#cleanup-https-gateway}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete tlsroute direct-cnn-to-egress-gateway
$ kubectl delete tlsroute forward-cnn-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Додаткові міркування щодо безпеки {#additional-security-considerations}

Зверніть увагу, що визначення egress `Gateway` в Istio не забезпечує спеціального поводження для вузлів, на яких працює сервіс egress gateway. Завдання адміністратора кластера або постачальника хмари полягає в розгортанні egress gateway на спеціалізованих вузлах та впровадженні додаткових заходів безпеки, щоб зробити ці вузли більш захищеними, ніж інші вузли мережі.

Istio *не може безпечно забезпечити* те, щоб весь вихідний трафік дійсно проходив через egress gateway. Istio лише дозволяє такий потік через свої sidecar проксі. Якщо зловмисники обійдуть sidecar проксі, вони можуть безпосередньо отримати доступ до зовнішніх сервісів без проходження через egress gateway. Таким чином, зловмисники уникнуть контролю та моніторингу з боку Istio. Адміністратор кластера або постачальник хмари повинні забезпечити, щоб жоден трафік не покидав мережу, оминаючи egress gateway. Механізми поза Istio повинні забезпечити цю вимогу. Наприклад, адміністратор кластера може налаштувати брандмауер для блокування всього трафіку, що не походить з egress gateway.

[Політики мережі Kubernetes](https://kubernetes.io/docs/concepts/services-networking/network-policies/) також можуть забороняти весь вихідний трафік, що не походить з egress gateway (див. [наступний розділ](#apply-kubernetes-network-policies) для прикладу).

Крім того, адміністратор кластера або постачальник хмари можуть налаштувати мережу так, щоб вузли застосунків могли отримувати доступ до Інтернету лише через шлюз. Для цього адміністратор кластера або постачальник хмари можуть запобігти виділенню публічних IP-адрес podʼам, крім шлюзів, і налаштувати NAT-пристрої для відкидання пакетів, що не походять з egress gateways.

## Застосування мережевих політик Kubernetes {#apply-kubernetes-network-policies}

У цьому розділі описується, як створити [мережеву політику Kubernetes](https://kubernetes.io/docs/concepts/services-networking/network-policies/), щоб запобігти оминання шлюзу вихідного трафіку. Для тестування мережевої політики створюється простір імен `test-egress`, у який розгортається зразок [curl]({{< github_tree >}}/samples/curl), а потім виконується спроба надіслати запити до зовнішнього сервісу, захищеного шлюзом.

1) Виконайте кроки з розділу [Шлюз вихідного трафіку для HTTPS-трафіку](#egress-gateway-for-https-traffic).

2) Створіть простір імен `test-egress`:

    {{< text bash >}}
    $ kubectl create namespace test-egress
    {{< /text >}}

3) Розгорніть зразок [curl]({{< github_tree >}}/samples/curl) у просторі імен `test-egress`.

    {{< text bash >}}
    $ kubectl apply -n test-egress -f @samples/curl/curl.yaml@
    {{< /text >}}

4) Перевірте, що розгорнутий pod має лише один контейнер без підключеного sidecar контейнера Istio:

    {{< text bash >}}
    $ kubectl get pod "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress
    NAME                     READY     STATUS    RESTARTS   AGE
    curl-776b7bcdcd-z7mc4    1/1       Running   0          18m
    {{< /text >}}

5) Надішліть HTTPS-запит до [https://edition.cnn.com/politics](https://edition.cnn.com/politics) з podʼа `curl` у просторі імен `test-egress`. Запит буде успішним, оскільки ви ще не визначили жодних обмежувальних політик.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -c curl -- curl -s -o /dev/null -w "%{http_code}\n"  https://edition.cnn.com/politics
    200
    {{< /text >}}

6)  Позначте простори імен, у яких запущено панель управління Istio та egress gateway. Якщо ви розгорнули Istio у просторі імен `istio-system`, команда буде такою:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl label namespace istio-system istio=system
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl label namespace istio-system istio=system
$ kubectl label namespace default gateway=true
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

7)  Позначте міткою простір імен `kube-system`.

    {{< text bash >}}
    $ kubectl label ns kube-system kube-system=true
    {{< /text >}}

8)  Визначте `NetworkPolicy`, щоб обмежити вихідний трафік із простору імен `test-egress` до трафіку, що спрямовується до панелі управління, шлюзу, а також до DNS-сервісу в просторі імен `kube-system` (порт 53).

    {{< warning >}}
    [Мережеві політики](https://kubernetes.io/docs/concepts/services-networking/network-policies/) реалізуються мережевим втулком у вашому кластері Kubernetes. Залежно від вашого тестового кластера, трафік може не бути заблокованим на наступному кроці.
    {{< /warning >}}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ cat <<EOF | kubectl apply -n test-egress -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-istio-system-and-kube-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kube-system: "true"
    ports:
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          istio: system
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ cat <<EOF | kubectl apply -n test-egress -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-istio-system-and-kube-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kube-system: "true"
    ports:
    - protocol: UDP
      port: 53
  - to:
    - namespaceSelector:
        matchLabels:
          istio: system
  - to:
    - namespaceSelector:
        matchLabels:
          gateway: "true"
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

9)  Повторно надішліть HTTPS-запит до [https://edition.cnn.com/politics](https://edition.cnn.com/politics). Тепер він має не виконатися, оскільки трафік заблокований мережевою політикою. Зверніть увагу, що pod `curl` не може оминути шлюз вихідного трафіку. Єдиний спосіб, яким він може отримати доступ до `edition.cnn.com`, — це використання sudecar проксі Istio та спрямування трафіку через шлюз вихідного трафіку. Це налаштування демонструє, що навіть якщо якийсь шкідливий pod зуміє обійти свій sidecar проксі, він не зможе отримати доступ до зовнішніх сайтів і буде заблокований мережевою політикою.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -c curl -- curl -v -sS https://edition.cnn.com/politics
    Hostname was NOT found in DNS cache
      Trying 151.101.65.67...
      Trying 2a04:4e42:200::323...
    Immediate connect fail for 2a04:4e42:200::323: Cannot assign requested address
      Trying 2a04:4e42:400::323...
    Immediate connect fail for 2a04:4e42:400::323: Cannot assign requested address
      Trying 2a04:4e42:600::323...
    Immediate connect fail for 2a04:4e42:600::323: Cannot assign requested address
      Trying 2a04:4e42::323...
    Immediate connect fail for 2a04:4e42::323: Cannot assign requested address
    connect to 151.101.65.67 port 443 failed: Connection timed out
    {{< /text >}}

10)  Тепер додай проксі Istio sidecar у pod `curl` в просторі імен `test-egress`, спочатку увімкнувши автоматичне додавання sidecar проксі в просторі імен `test-egress`:

    {{< text bash >}}
    $ kubectl label namespace test-egress istio-injection=enabled
    {{< /text >}}

11)  Потім виконайте повторне розгортання `curl`:

    {{< text bash >}}
    $ kubectl delete deployment curl -n test-egress
    $ kubectl apply -f @samples/curl/curl.yaml@ -n test-egress
    {{< /text >}}

12)  Перевір, що у розгорнутому pod є два контейнери, включаючи проксі Istio sidecar (`istio-proxy`):

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl get pod "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}'
curl istio-proxy
{{< /text >}}

Перш ніж продовжити, потрібно створити аналогічне правило призначення, як і для pod `curl` у просторі імен `default`, щоб спрямувати трафік простору імен `test-egress` через шлюз egress:

{{< text bash >}}
$ kubectl apply -n test-egress -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl get pod "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -o jsonpath='{.spec.containers[*].name}'
curl istio-proxy
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

13) Надішліть HTTPS-запит на [https://edition.cnn.com/politics](https://edition.cnn.com/politics). Тепер він повинен успішно пройти, оскільки трафік до шлюзу egress дозволений мережевою політикою, яку ви визначили. Шлюз потім пересилає трафік на `edition.cnn.com`.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -n test-egress -l app=curl -o jsonpath={.items..metadata.name})" -n test-egress -c curl -- curl -sS -o /dev/null -w "%{http_code}\n" https://edition.cnn.com/politics
    200
    {{< /text >}}

14) Перевірте журнали проксі шлюзу egress.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Якщо Istio розгорнуто у просторі імен `istio-system`, команда для друку журналу буде такою:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system
{{< /text >}}

Ви повинні побачити рядок, схожий на наступний:

{{< text plain >}}
[2020-03-06T18:12:33.101Z] "- - -" 0 - "-" "-" 906 1352475 35 - "-" "-" "-" "-" "151.101.193.67:443" outbound|443||edition.cnn.com 172.30.223.53:39460 172.30.223.53:443 172.30.223.58:38138 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Отримайте доступ до журналу, що відповідає egress gateway , використовуючи згенеровану Istio мітку podʼа:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

Ви повинні побачити рядок, схожий на наступний:

{{< text plain >}}
[2024-01-12T19:54:01.821Z] "- - -" 0 - - - "-" 839 2504837 46 - "-" "-" "-" "-" "151.101.67.5:443" outbound|443||edition.cnn.com 172.30.239.60:49850 172.30.239.60:443 172.30.239.21:36512 edition.cnn.com -
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Видалення мережевих політик {#cleanup-network-policies}

1.  Видаліть ресурси, створені у цьому розділі:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@ -n test-egress
$ kubectl delete destinationrule egressgateway-for-cnn -n test-egress
$ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
$ kubectl label namespace kube-system kube-system-
$ kubectl label namespace istio-system istio-
$ kubectl delete namespace test-egress
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@ -n test-egress
$ kubectl delete networkpolicy allow-egress-to-istio-system-and-kube-dns -n test-egress
$ kubectl label namespace kube-system kube-system-
$ kubectl label namespace istio-system istio-
$ kubectl label namespace default gateway-
$ kubectl delete namespace test-egress
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Виконайте кроки в розділі [Видалення HTTPS-шлюзу](#cleanup-https-gateway).

## Очищення {#cleanup}

Вимкніть сервіс [curl]({{< github_tree >}}/samples/curl):

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@
{{< /text >}}
