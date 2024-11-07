---
title: Egress Gateways зі створенням TLS
description: Описує, як налаштувати вихідний шлюз для створення TLS для зовнішніх служб.
weight: 40
keywords: [traffic-management,egress]
aliases:
  - /uk/docs/examples/advanced-gateways/egress-gateway-tls-origination/
  - /uk/docs/examples/advanced-gateways/egress-gateway-tls-origination-sds/
  - /uk/docs/tasks/traffic-management/egress/egress-gateway-tls-origination-sds/
owner: istio/wg-networking-maintainers
test: yes
---

[Приклад створення TLS для вихідного трафіку](/docs/tasks/traffic-management/egress/egress-tls-origination/) показує, як налаштувати Istio для виконання {{< gloss "Створення TLS" >}}створення TLS{{< /gloss >}} для трафіку до зовнішнього сервісу. [Приклад Налаштування Egress Gateway](/docs/tasks/traffic-management/egress/egress-gateway/) показує, як налаштувати Istio для направлення вихідного трафіку через спеціалізований сервіс _egress gateway_. Цей приклад поєднує два попередні, описуючи, як налаштувати вихідний шлюз для виконання створення TLS для трафіку до зовнішніх сервісів.
{{< boilerplate gateway-api-support >}}

## Перш ніж почати {#before-you-begin}

* Налаштуйте Istio, дотримуючись інструкцій з [Посібника з встановлення](/docs/setup/).

*   Розгорніть демонстраційний застосунок [curl]({{< github_tree >}}/samples/curl), щоб використовувати його як джерело для надсилання тестових запитів.

    Якщо у вас увімкнено [автоматичну інʼєкцію sidecar](/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection), виконайте наступну команду, розгорніть застосунок `curl`:

    {{< text bash >}}
    $ kubectl apply -f @samples/curl/curl.yaml@
    {{< /text >}}

    В іншому випадку вам потрібно вручну виконати інʼєкцію sidecar перед розгортанням застосунку `curl`:

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/curl/curl.yaml@)
    {{< /text >}}

    Зверніть увагу, що будь-який pod, з якого ви можете виконати `exec` та `curl`, підійде для подальших процедур.

*   Створіть змінну оболонки, яка буде містити ім'я вихідного пакунка для надсилання запитів до зовнішніх сервісів. Якщо ви використовували приклад [curl]({{< github_tree >}}/samples/curl), запустіть його:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})
    {{< /text >}}

*   Для користувачів macOS переконайтеся, що ви використовуєте `openssl` версії 1.1 або новішої:

    {{< text bash >}}
    $ openssl version -a | grep OpenSSL
    OpenSSL 1.1.1g  21 Apr 2020
    {{< /text >}}

    Якщо попередня команда виведе версію `1.1` або новішу, як показано, ваша команда `openssl` має працювати правильно з інструкціями в цьому завданні. В іншому випадку, оновіть ваш `openssl` або спробуйте іншу реалізацію `openssl`, наприклад, на машині з Linux.

*   [Увімкніть ведення журналу доступу Envoy](/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging) якщо його ще не ввімкнено. Наприклад, за допомогою `istioctl`:

    {{< text bask >}}
    $ istioctl install <flags-you-used-to-install-Istio> --set meshConfig.accessLogFile=/dev/stdout
    {{< /text >}}

*   Якщо ви НЕ використовуєте інструкції `Gateway API`, переконайтесь що ви [розгорнули Istio egress gateway](/docs/tasks/traffic-management/egress/egress-gateway/#deploy-istio-egress-gateway).

## Виконання створення TLS за допомогою egress gateway {#perform-tls-origination-with-an-egress-gateway}

У цьому розділі описується, як виконати таке ж створення TLS, як у [Прикладі створення TLS для вихідного трафіку](/docs/tasks/traffic-management/egress/egress-tls-origination/), але цього разу використовуючи egress gateway. Зверніть увагу, що в цьому випадку створення TLS буде здійснено egress gateway, на відміну від попереднього прикладу, де це робив sidecar.

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
      - number: 80
        name: http
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

2.  Переконайтеся, що ваш `ServiceEntry` було застосовано правильно, надіславши запит до [http://edition.cnn.com/politics](https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "${SOURCE_POD}" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...
    {{< /text >}}

    Ваш `ServiceEntry` було налаштовано правильно, якщо у виводі ви побачите _301 Moved Permanently_.

3.  Створіть вихідний `Gateway` для _edition.cnn.com_, порт 80, і правило призначення для додаткових запитів, які будуть спрямовані на egress gateway.

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
      number: 80
      name: https-port-for-tls-origination
      protocol: HTTPS
    hosts:
    - edition.cnn.com
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: cnn
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
      portLevelSettings:
      - port:
          number: 80
        tls:
          mode: ISTIO_MUTUAL
          sni: edition.cnn.com
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
  - name: https-listener-for-tls-origination
    hostname: edition.cnn.com
    port: 80
    protocol: HTTPS
    tls:
      mode: Terminate
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-cnn
spec:
  host: cnn-egress-gateway-istio.default.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 80
      tls:
        mode: ISTIO_MUTUAL
        sni: edition.cnn.com
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4) Налаштуйте правила маршруту, щоб спрямовувати трафік через egress gateway:

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
          number: 443
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
      port: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

5)  Визначте `DestinationRule` для створення TLS для запитів до `edition.cnn.com`:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1
    kind: DestinationRule
    metadata:
      name: originate-tls-for-edition-cnn-com
    spec:
      host: edition.cnn.com
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: SIMPLE # initiates HTTPS for connections to edition.cnn.com
    EOF
    {{< /text >}}

6)  Надішліть HTTP-запит до [http://edition.cnn.com/politics] (https://edition.cnn.com/politics).

    {{< text bash >}}
    $ kubectl exec "${SOURCE_POD}" -c curl -- curl -sSL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    ...
    {{< /text >}}

    The output should be the same as in the [TLS Origination for Egress Traffic](/docs/tasks/traffic-management/egress/egress-tls-origination/)
    example, with TLS origination: without the _301 Moved Permanently_ message.

7) Перевірте журнал проксі egress gateway.

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Якщо Istio розгорнуто у просторі імен `istio-system`, команда для друку журналу буде такою:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -c istio-proxy -n istio-system | tail
{{< /text >}}

Ви повинні побачити рядок, схожий на наступний:

{{< text plain>}}
[2020-06-30T16:17:56.763Z] "GET /politics HTTP/2" 200 - "-" "-" 0 1295938 529 89 "10.244.0.171" "curl/7.64.0" "cf76518d-3209-9ab7-a1d0-e6002728ef5b" "edition.cnn.com" "151.101.129.67:443" outbound|443||edition.cnn.com 10.244.0.170:54280 10.244.0.170:8080 10.244.0.171:35628 - -
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Отримайте доступ до журналу, що відповідає egress gateway, використовуючи згенеровану Istio мітку podʼа:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=cnn-egress-gateway -c istio-proxy | tail
{{< /text >}}

You should see a line similar to the following:

{{< text plain >}}
[2024-03-14T18:37:01.451Z] "GET /politics HTTP/1.1" 200 - via_upstream - "-" 0 2484998 59 37 "172.30.239.26" "curl/7.87.0-DEV" "b80c8732-8b10-4916-9a73-c3e1c848ed1e" "edition.cnn.com" "151.101.131.5:443" outbound|443||edition.cnn.com 172.30.239.33:51270 172.30.239.33:80 172.30.239.26:35192 edition.cnn.com default.forward-cnn-from-egress-gateway.0
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Видалення прикладу створення TLS {#cleanup-tls-origination-example}

Видаліть створені вами елементи конфігурації Istio:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete gw istio-egressgateway
$ kubectl delete serviceentry cnn
$ kubectl delete virtualservice direct-cnn-through-egress-gateway
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
$ kubectl delete destinationrule egressgateway-for-cnn
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete serviceentry cnn
$ kubectl delete gtw cnn-egress-gateway
$ kubectl delete httproute direct-cnn-to-egress-gateway
$ kubectl delete httproute forward-cnn-from-egress-gateway
$ kubectl delete destinationrule egressgateway-for-cnn
$ kubectl delete destinationrule originate-tls-for-edition-cnn-com
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Виконання створення взаємного TLS за допомогою egress gateway {#perform-mutual-tls-origination-with-an-egress-gateway}

Аналогічно до попереднього розділу, у цьому розділі описується, як налаштувати egress gateway для виконання створення TLS для зовнішнього сервісу, але цього разу з використанням сервісу, який потребує взаємного TLS.

Цей приклад є значно складнішим, оскільки спочатку потрібно:

1. згенерувати сертифікати клієнта і сервера
1. розгорнути зовнішній сервіс, який підтримує протокол взаємного TLS
1. перезавантажити вихідний шлюз з потрібними сертифікатами взаємного TLS

Лише після цього можна налаштувати зовнішній трафік для проходження через вихідний шлюз, який виконає створення TLS.

### Створення сертифікатів і ключів клієнта та сервера {#generate-client-and-server-certificates-and-keys}

Для цього завдання ви можете скористатися вашим улюбленим інструментом для генерації сертифікатів і ключів. У наведених нижче командах використовуються [openssl](https://man.openbsd.org/openssl.1)

1.  Створіть кореневий сертифікат і приватний ключ для підписання сертифіката для ваших сервісів:

    {{< text bash >}}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
    {{< /text >}}

1.  Створіть сертифікат і приватний ключ для `my-nginx.mesh-external.svc.cluster.local`:

    {{< text bash >}}
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt
    {{< /text >}}

    За бажанням ви можете додати `SubjectAltNames` до сертифіката, якщо хочете увімкнути перевірку SAN для місця призначення. Наприклад:

    {{< text syntax=bash snip_id=none >}}
    $ cat > san.conf <<EOF
    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    x509_extensions = v3_req
    prompt = no
    [req_distinguished_name]
    countryName = US
    [v3_req]
    keyUsage = critical, digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth, clientAuth
    basicConstraints = critical, CA:FALSE
    subjectAltName = critical, @alt_names
    [alt_names]
    DNS = my-nginx.mesh-external.svc.cluster.local
    EOF
    $
    $ openssl req -out my-nginx.mesh-external.svc.cluster.local.csr -newkey rsa:4096 -nodes -keyout my-nginx.mesh-external.svc.cluster.local.key -subj "/CN=my-nginx.mesh-external.svc.cluster.local/O=some organization" -config san.conf
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in my-nginx.mesh-external.svc.cluster.local.csr -out my-nginx.mesh-external.svc.cluster.local.crt -extfile san.conf -extensions v3_req
    {{< /text >}}

1.  Згенеруйте клієнтський сертифікат і приватний ключ:

    {{< text bash >}}
    $ openssl req -out client.example.com.csr -newkey rsa:2048 -nodes -keyout client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -sha256 -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.example.com.csr -out client.example.com.crt
    {{< /text >}}

### Розгортання сервера взаємного TLS {#deploy-mutual-tls-server}

Щоб змоделювати реальний зовнішній сервіс, який підтримує протокол взаємного TLS, розгорніть сервер [NGINX](https://www.nginx.com) у вашому кластері Kubernetes, але розмістіть його поза межами сервісної мережі Istio, тобто в просторі імен, де не включена інʼєкція sidecar проксі Istio.

1.  Створіть простір імен для представлення сервісів поза межами мережі Istio, а саме `mesh-external`. Зауважте, що sidecar проксі не буде автоматично додано до podsʼів у цьому просторі імен, оскільки автоматичне додавання sidecar не було [увімкнено](/docs/setup/additional-setup/sidecar-injection/#deploying-an-app).

    {{< text bash >}}
    $ kubectl create namespace mesh-external
    {{< /text >}}

1. Створіть Kubernetes [Secrets] (https://kubernetes.io/docs/concepts/configuration/secret/) для зберігання сертифікатів сервера та центру сертифікації.

    {{< text bash >}}
    $ kubectl create -n mesh-external secret tls nginx-server-certs --key my-nginx.mesh-external.svc.cluster.local.key --cert my-nginx.mesh-external.svc.cluster.local.crt
    $ kubectl create -n mesh-external secret generic nginx-ca-certs --from-file=example.com.crt
    {{< /text >}}

1.  Створіть конфігураційний файл для сервера NGINX:

    {{< text bash >}}
    $ cat <<\EOF > ./nginx.conf
    events {
    }

    http {
      log_format main '$remote_addr - $remote_user [$time_local]  $status '
      '"$request" $body_bytes_sent "$http_referer" '
      '"$http_user_agent" "$http_x_forwarded_for"';
      access_log /var/log/nginx/access.log main;
      error_log  /var/log/nginx/error.log;

      server {
        listen 443 ssl;

        root /usr/share/nginx/html;
        index index.html;

        server_name my-nginx.mesh-external.svc.cluster.local;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
        ssl_client_certificate /etc/nginx-ca-certs/example.com.crt;
        ssl_verify_client on;
      }
    }
    EOF
    {{< /text >}}

1.  Створіть Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) для зберігання конфігурації сервера NGINX:

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap -n mesh-external --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

2.  Розгорніть сервер the NGINX:

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
      namespace: mesh-external
      labels:
        run: my-nginx
    spec:
      ports:
      - port: 443
        protocol: TCP
      selector:
        run: my-nginx
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: my-nginx
      namespace: mesh-external
    spec:
      selector:
        matchLabels:
          run: my-nginx
      replicas: 1
      template:
        metadata:
          labels:
            run: my-nginx
        spec:
          containers:
          - name: my-nginx
            image: nginx
            ports:
            - containerPort: 443
            volumeMounts:
            - name: nginx-config
              mountPath: /etc/nginx
              readOnly: true
            - name: nginx-server-certs
              mountPath: /etc/nginx-server-certs
              readOnly: true
            - name: nginx-ca-certs
              mountPath: /etc/nginx-ca-certs
              readOnly: true
          volumes:
          - name: nginx-config
            configMap:
              name: nginx-configmap
          - name: nginx-server-certs
            secret:
              secretName: nginx-server-certs
          - name: nginx-ca-certs
            secret:
              secretName: nginx-ca-certs
    EOF
    {{< /text >}}

### Налаштування створення взаємного TLS для вихідного трафіку {#configure-mutual-tls-origination-for-egress-traffic}

1)  Створіть [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) у **тому ж просторі імен**, де розгорнуто egress gateway, для зберігання сертифікатів клієнта:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl create secret -n istio-system generic client-credential --from-file=tls.key=client.example.com.key \
  --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
{{< /text >}}

Для підтримки інтеграції з різними інструментами, Istio підтримує кілька різних форматів секретів. У цьому прикладі використовується один загальний Secret з ключами `tls.key`, `tls.crt` і `ca.crt`.

{{< tip >}}
{{< boilerplate crl-tip >}}
{{< /tip >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl create secret -n default generic client-credential --from-file=tls.key=client.example.com.key \
  --from-file=tls.crt=client.example.com.crt --from-file=ca.crt=example.com.crt
{{< /text >}}

Для підтримки інтеграції з різними інструментами, Istio підтримує кілька різних форматів секретів. У цьому прикладі використовується один загальний Secret з ключами `tls.key`, `tls.crt` і `ca.crt`.

{{< tip >}}
{{< boilerplate crl-tip >}}
{{< /tip >}}

{{< /tab >}}

{{< /tabset >}}

2)  Створіть вихідний `Gateway` для `my-nginx.mesh-external.svc.cluster.local`, порт 443 і правило призначення для sidecar запитів, які будуть спрямовані на вихідний шлюз:

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
    - my-nginx.mesh-external.svc.cluster.local
    tls:
      mode: ISTIO_MUTUAL
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-nginx
spec:
  host: istio-egressgateway.istio-system.svc.cluster.local
  subsets:
  - name: nginx
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
      portLevelSettings:
      - port:
          number: 443
        tls:
          mode: ISTIO_MUTUAL
          sni: my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: nginx-egressgateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: my-nginx.mesh-external.svc.cluster.local
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      options:
        gateway.istio.io/tls-terminate-mode: ISTIO_MUTUAL
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: nginx-egressgateway-istio-sds
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - watch
  - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: nginx-egressgateway-istio-sds
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: nginx-egressgateway-istio-sds
subjects:
- kind: ServiceAccount
  name: nginx-egressgateway-istio
---
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: egressgateway-for-nginx
spec:
  host: nginx-egressgateway-istio.default.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: ISTIO_MUTUAL
        sni: my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3) Налаштуйте правила маршруту, щоб спрямовувати трафік через egress gateway:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-nginx-through-egress-gateway
spec:
  hosts:
  - my-nginx.mesh-external.svc.cluster.local
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
        subset: nginx
        port:
          number: 443
      weight: 100
  - match:
    - gateways:
      - istio-egressgateway
      port: 443
    route:
    - destination:
        host: my-nginx.mesh-external.svc.cluster.local
        port:
          number: 443
      weight: 100
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: direct-nginx-to-egress-gateway
spec:
  hosts:
  - my-nginx.mesh-external.svc.cluster.local
  gateways:
  - mesh
  http:
  - match:
    - port: 80
    route:
    - destination:
        host: nginx-egressgateway-istio.default.svc.cluster.local
        port:
          number: 443
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: forward-nginx-from-egress-gateway
spec:
  parentRefs:
  - name: nginx-egressgateway
  hostnames:
  - my-nginx.mesh-external.svc.cluster.local
  rules:
  - backendRefs:
    - name: my-nginx
      namespace: mesh-external
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata:
  name: my-nginx-reference-grant
  namespace: mesh-external
spec:
  from:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      namespace: default
  to:
    - group: ""
      kind: Service
      name: my-nginx
EOF
{{< /text >}}

TODO: зʼясувати, чому не працює використання `HTTPRoute` замість вищезгаданого `VirtualService`. Він повністю ігнорує `HTTPRoute` і намагається пройти до цільового сервісу, що призводить до тайм-ауту. Єдина відмінність від наведеного вище `VirtualService` полягає в тому, що згенерований `VirtualService` включає анотацію: `internal.istio.io/route-semantics`: «gateway"`.

{{< /tab >}}

{{< /tabset >}}

4)  Додайте `DestinationRule` для виконання створення взаємного TLS:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -n istio-system -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: originate-mtls-for-nginx
spec:
  host: my-nginx.mesh-external.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: MUTUAL
        credentialName: client-credential # має збігатися з секретом, створеним раніше для зберігання клієнтських сертифікатів
        sni: my-nginx.mesh-external.svc.cluster.local
        # subjectAltNames: # можна ввімкнути, якщо сертифікат було згенеровано за допомогою SAN, як зазначено в попередньому розділі
        # - my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: originate-mtls-for-nginx
spec:
  host: my-nginx.mesh-external.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    portLevelSettings:
    - port:
        number: 443
      tls:
        mode: MUTUAL
        credentialName: client-credential # має збігатися з секретом, створеним раніше для зберігання клієнтських сертифікатів
        sni: my-nginx.mesh-external.svc.cluster.local
        # subjectAltNames: # можна ввімкнути, якщо сертифікат було згенеровано за допомогою SAN, як зазначено в попередньому розділі
        # - my-nginx.mesh-external.svc.cluster.local
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

{{< boilerplate auto-san-validation >}}

5)  Переконайтеся, що облікові дані передано на вихідний шлюз і вони активні:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ istioctl -n istio-system proxy-config secret deploy/istio-egressgateway | grep client-credential
kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           16491643791048004260                       2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ istioctl proxy-config secret deploy/nginx-egressgateway-istio | grep client-credential
kubernetes://client-credential            Cert Chain     ACTIVE     true           1                                          2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
kubernetes://client-credential-cacert     Cert Chain     ACTIVE     true           16491643791048004260                       2024-06-04T12:46:28Z     2023-06-05T12:46:28Z
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

6)  Надішліть HTTP-запит на адресу `http://my-nginx.mesh-external.svc.cluster.local`:

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod -l app=curl -o jsonpath={.items..metadata.name})" -c curl -- curl -sS http://my-nginx.mesh-external.svc.cluster.local
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

7) Перевірте журнал проксі egress gateway:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Якщо Istio розгорнуто у просторі імен `istio-system`, команда для друку журналу буде такою:

{{< text bash >}}
$ kubectl logs -l istio=egressgateway -n istio-system | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
{{< /text >}}

Ви повинні побачити рядок, схожий на наступний:

{{< text plain>}}
[2018-08-19T18:20:40.096Z] "GET / HTTP/1.1" 200 - 0 612 7 5 "172.30.146.114" "curl/7.35.0" "b942b587-fac2-9756-8ec6-303561356204" "my-nginx.mesh-external.svc.cluster.local" "172.21.72.197:443"
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Отримайте доступ до журналу, що відповідає egress gateway, використовуючи згенеровану Istio мітку podʼа:

{{< text bash >}}
$ kubectl logs -l gateway.networking.k8s.io/gateway-name=nginx-egressgateway | grep 'my-nginx.mesh-external.svc.cluster.local' | grep HTTP
{{< /text >}}

Ви повинні побачити рядок, схожий на наступний:

{{< text plain >}}
[2024-04-08T20:08:18.451Z] "GET / HTTP/1.1" 200 - via_upstream - "-" 0 615 5 5 "172.30.239.41" "curl/7.87.0-DEV" "86e54df0-6dc3-46b3-a8b8-139474c32a4d" "my-nginx.mesh-external.svc.cluster.local" "172.30.239.57:443" outbound|443||my-nginx.mesh-external.svc.cluster.local 172.30.239.53:48530 172.30.239.53:443 172.30.239.41:53694 my-nginx.mesh-external.svc.cluster.local default.forward-nginx-from-egress-gateway.0
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Вилучення прикладу створення взаємного TLS {#cleanup-mutual-tls-origination-example}

1.  Видаліть ресурси сервера взаємного TLS NGINX:

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs nginx-ca-certs -n mesh-external
    $ kubectl delete configmap nginx-configmap -n mesh-external
    $ kubectl delete service my-nginx -n mesh-external
    $ kubectl delete deployment my-nginx -n mesh-external
    $ kubectl delete namespace mesh-external
    {{< /text >}}

1.  Видаліть ресурси конфігурації шлюзу:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete secret client-credential -n istio-system
$ kubectl delete gw istio-egressgateway
$ kubectl delete virtualservice direct-nginx-through-egress-gateway
$ kubectl delete destinationrule -n istio-system originate-mtls-for-nginx
$ kubectl delete destinationrule egressgateway-for-nginx
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete secret client-credential
$ kubectl delete gtw nginx-egressgateway
$ kubectl delete role nginx-egressgateway-istio-sds
$ kubectl delete rolebinding nginx-egressgateway-istio-sds
$ kubectl delete virtualservice direct-nginx-to-egress-gateway
$ kubectl delete httproute forward-nginx-from-egress-gateway
$ kubectl delete destinationrule originate-mtls-for-nginx
$ kubectl delete destinationrule egressgateway-for-nginx
$ kubectl delete referencegrant my-nginx-reference-grant -n mesh-external
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Видаліть сертифікати та приватні ключі:

    {{< text bash >}}
    $ rm example.com.crt example.com.key my-nginx.mesh-external.svc.cluster.local.crt my-nginx.mesh-external.svc.cluster.local.key my-nginx.mesh-external.svc.cluster.local.csr client.example.com.crt client.example.com.csr client.example.com.key
    {{< /text >}}

4)  Видаліть згенеровані конфігураційні файли, використані у цьому прикладі:

    {{< text bash >}}
    $ rm ./nginx.conf
    {{< /text >}}

## Очищення {#cleanup}

Видаліть сервіс та розгортання `curl`:

{{< text bash >}}
$ kubectl delete -f @samples/curl/curl.yaml@
{{< /text >}}
