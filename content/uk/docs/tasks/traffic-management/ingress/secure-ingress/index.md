---
title: Захист Gateways
description: Експонування сервісу поза межами сервісної мережі через TLS або mTLS.
weight: 20
aliases:
    - /uk/docs/tasks/traffic-management/ingress/secure-ingress-sds/
    - /uk/docs/tasks/traffic-management/ingress/secure-ingress-mount/
keywords: [traffic-management,ingress,sds-credentials]
owner: istio/wg-networking-maintainers
test: yes
---

Завдання [Контроль вхідного трафіку](/docs/tasks/traffic-management/ingress/ingress-control) описує, як налаштувати ingress gateway, щоб відкрити HTTP-сервіс для зовнішнього трафіку. Це завдання показує, як експонувати захищений HTTPS-сервіс за допомогою простого або взаємного TLS.

{{< boilerplate gateway-api-support >}}

## Перш ніж почати {#before-you-begin}

*   Налаштуйте Istio, дотримуючись інструкцій з [Посібника з встановлення](/docs/setup/).

*   Запустіть [httpbin]({{< github_tree >}}/samples/httpbin):

    {{< text bash >}}
    $ kubectl apply -f @samples/httpbin/httpbin.yaml@
    {{< /text >}}

*   Для користувачів macOS переконайтеся, що ви використовуєте `curl`, скомпільований з бібліотекою [LibreSSL](http://www.libressl.org):

    {{< text bash >}}
    $ curl --version | grep LibreSSL
    curl 7.54.0 (x86_64-apple-darwin17.0) libcurl/7.54.0 LibreSSL/2.0.20 zlib/1.2.11 nghttp2/1.24.0
    {{< /text >}}

    Якщо попередня команда виводить версію LibreSSL, як показано, ваша команда `curl` має працювати коректно з інструкціями у цьому завданні. В іншому випадку, спробуйте іншу реалізацію `curl`, наприклад, на машині Linux.

## Генерація сертифікатів та ключів для клієнта і сервера {#generate-client-and-server-certificates-and-keys}

Це завдання вимагає кілька наборів сертифікатів та ключів, які використовуються в наведених нижче прикладах. Ви можете скористатися улюбленим інструментом для їх створення або скористатися командами нижче для генерації за допомогою [openssl](https://man.openbsd.org/openssl.1).

1.  Створіть кореневий сертифікат і приватний ключ для підпису сертифікатів для ваших сервісів:

    {{< text bash >}}
    $ mkdir example_certs1
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs1/example.com.key -out example_certs1/example.com.crt
    {{< /text >}}

1.  Згенеруйте сертифікат та приватний ключ для `httpbin.example.com`:

    {{< text bash >}}
    $ openssl req -out example_certs1/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 0 -in example_certs1/httpbin.example.com.csr -out example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  Створіть другий набір таких самих сертифікатів та ключів:

    {{< text bash >}}
    $ mkdir example_certs2
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs2/example.com.key -out example_certs2/example.com.crt
    $ openssl req -out example_certs2/httpbin.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs2/httpbin.example.com.key -subj "/CN=httpbin.example.com/O=httpbin organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs2/example.com.crt -CAkey example_certs2/example.com.key -set_serial 0 -in example_certs2/httpbin.example.com.csr -out example_certs2/httpbin.example.com.crt
    {{< /text >}}

1.  Згенеруйте сертифікат та приватний ключ для `helloworld.example.com`:

    {{< text bash >}}
    $ openssl req -out example_certs1/helloworld.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/helloworld.example.com.key -subj "/CN=helloworld.example.com/O=helloworld organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/helloworld.example.com.csr -out example_certs1/helloworld.example.com.crt
    {{< /text >}}

1.  Згенеруйте клієнтський сертифікат та приватний ключ:

    {{< text bash >}}
    $ openssl req -out example_certs1/client.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs1/client.example.com.key -subj "/CN=client.example.com/O=client organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs1/example.com.crt -CAkey example_certs1/example.com.key -set_serial 1 -in example_certs1/client.example.com.csr -out example_certs1/client.example.com.crt
    {{< /text >}}

{{< tip >}}
Ви можете підтвердити наявність всіх необхідних файлів, виконавши наступну команду:

{{< text bash >}}
$ ls example_cert*
example_certs1:
client.example.com.crt          example.com.key                 httpbin.example.com.crt
client.example.com.csr          helloworld.example.com.crt      httpbin.example.com.csr
client.example.com.key          helloworld.example.com.csr      httpbin.example.com.key
example.com.crt                 helloworld.example.com.key

example_certs2:
example.com.crt         httpbin.example.com.crt httpbin.example.com.key
example.com.key         httpbin.example.com.csr
{{< /text >}}

{{< /tip >}}

### Налаштування TLS ingress gateway для одного хоста {#configure-a-tls-ingress-gateway-for-a-single-host}

1.  Створіть секрет для ingress gateway:

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs1/httpbin.example.com.key \
      --cert=example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  Налаштуйте ingress gateway:

{{< tabset category-name="config-api" >}}

{{< tab name="API Istio" category-value="istio-apis" >}}

Спочатку визначте шлюз з розділом `servers:` для порту 443 і вкажіть значення для
`credentialName`, яке має бути `httpbin-credential`. Значення збігається з
назвою секрету. Режим TLS повинен мати значення `SIMPLE`.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # використовуйте станадртний istio ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: httpbin-credential # має збігатись з secret
    hosts:
    - httpbin.example.com
EOF
{{< /text >}}

Далі налаштуйте маршрути вхідного трафіку шлюзу, визначивши відповідний
віртуальний сервіс:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - mygateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
EOF
{{< /text >}}

Нарешті, дотримуйтесь [цих інструкцій](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports), щоб встановити змінні `INGRESS_HOST` та `SECURE_INGRESS_PORT` для доступу до шлюзу.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Спочатку створіть [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway):

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

Потім, налаштуйте маршрути вхідного трафіку шлюзу, визначивши відповідний `HTTPRoute`:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: httpbin
spec:
  parentRefs:
  - name: mygateway
    namespace: istio-system
  hostnames: ["httpbin.example.com"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /status
    - path:
        type: PathPrefix
        value: /delay
    backendRefs:
    - name: httpbin
      port: 8000
EOF
{{< /text >}}

Нарешті, отримайте адресу і порт шлюзу з ресурсу `Gateway`:

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw mygateway -n istio-system
$ export INGRESS_HOST=$(kubectl get gtw mygateway -n istio-system -o jsonpath='{.status.addresses[0].value}')
$ export SECURE_INGRESS_PORT=$(kubectl get gtw mygateway -n istio-system -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

1)  Надішліть HTTPS-запит, щоб отримати доступ до сервісу `httpbin` через HTTPS:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    HTTP/2 418
    ...
    I'm a teapot!
    ...
    {{< /text >}}

    Сервіс `httpbin` поверне код [418 I'm a Teapot](https://tools.ietf.org/html/rfc7168#section-2.3.3).

2)  Змініть облікові дані шлюзу, видаливши секрет шлюзу, а потім створивши його заново, використовуючи інші сертифікати та ключі:

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs2/httpbin.example.com.key \
      --cert=example_certs2/httpbin.example.com.crt
    {{< /text >}}

3)  Зверніться до сервісу `httpbin` за допомогою `curl`, використовуючи новий ланцюжок сертифікатів:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs2/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    HTTP/2 418
    ...
    I'm a teapot!
    ...
    {{< /text >}}

4) Якщо ви спробуєте отримати доступ до `httpbin`, використовуючи попередній ланцюжок сертифікатів, спроба завершиться невдачею:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    * TLSv1.2 (OUT), TLS handshake, Client hello (1):
    * TLSv1.2 (IN), TLS handshake, Server hello (2):
    * TLSv1.2 (IN), TLS handshake, Certificate (11):
    * TLSv1.2 (OUT), TLS alert, Server hello (2):
    * curl: (35) error:04FFF06A:rsa routines:CRYPTO_internal:block type is not 01
    {{< /text >}}

### Налаштування TLS ingress gateway для кількох хостів {#configure-a-tls-ingress-gateway-for-multiple-hosts}

Ви можете налаштувати ingress gateway для декількох хостів, наприклад, `httpbin.example.com` та `helloworld.example.com`. Ingress gateway налаштовується за допомогою унікальних облікових даних, що відповідають кожному хосту.

1.  Відновіть облікові дані `httpbin` з попереднього прикладу, видаливши і створивши заново секрет з оригінальними сертифікатами і ключами:

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret tls httpbin-credential \
      --key=example_certs1/httpbin.example.com.key \
      --cert=example_certs1/httpbin.example.com.crt
    {{< /text >}}

1.  Запустіть приклад `helloworld-v1`:

    {{< text bash >}}
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l service=helloworld
    $ kubectl apply -f @samples/helloworld/helloworld.yaml@ -l version=v1
    {{< /text >}}

2.  Створіть секрет `helloworld-credential`:

    {{< text bash >}}
    $ kubectl create -n istio-system secret tls helloworld-credential \
      --key=example_certs1/helloworld.example.com.key \
      --cert=example_certs1/helloworld.example.com.crt
    {{< /text >}}

3. Налаштуйте ingress gatewayз хостами `httpbin.example.com` та `helloworld.example.com`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Визначте шлюз з двома секціями server для порту 443. Встановіть значення параметра
`credentialName` на кожному порту на `httpbin-credential` і `helloworld-credential` відповідно. Встановіть режим TLS на `SIMPLE`.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # використовуйте стандартний istio ingress gateway
  servers:
  - port:
      number: 443
      name: https-httpbin
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: httpbin-credential
    hosts:
    - httpbin.example.com
  - port:
      number: 443
      name: https-helloworld
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: helloworld-credential
    hosts:
    - helloworld.example.com
EOF
{{< /text >}}

Налаштуйте маршрути трафіку шлюзу, визначивши відповідну віртуальну службу.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: helloworld
spec:
  hosts:
  - helloworld.example.com
  gateways:
  - mygateway
  http:
  - match:
    - uri:
        exact: /hello
    route:
    - destination:
        host: helloworld
        port:
          number: 5000
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Налаштуйте `Gateway` з двома слухачами для порту 443. Встановіть значення
`certificateRefs` на кожному слухачі на `httpbin-credential` та `helloworld-credential`
відповідно.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https-httpbin
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
  - name: https-helloworld
    hostname: "helloworld.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: helloworld-credential
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

Налаштуйте маршрути трафіку шлюзу для сервісу `helloworld`:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: helloworld
spec:
  parentRefs:
  - name: mygateway
    namespace: istio-system
  hostnames: ["helloworld.example.com"]
  rules:
  - matches:
    - path:
        type: Exact
        value: /hello
    backendRefs:
    - name: helloworld
      port: 5000
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

1) Надішліть запит HTTPS до `helloworld.example.com`:

    {{< text bash >}}
    $ curl -v -HHost:helloworld.example.com --resolve "helloworld.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://helloworld.example.com:$SECURE_INGRESS_PORT/hello"
    ...
    HTTP/2 200
    ...
    {{< /text >}}

2) Надішліть запит HTTPS до `httpbin.example.com` і також отримайте відповідь [HTTP 418](https://datatracker.ietf.org/doc/html/rfc2324):

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    HTTP/2 418
    ...
    server: istio-envoy
    ...
    {{< /text >}}

### Налаштуйте взаємний TLS ingress gateway {#configure-a-mutual-tls-ingress-gateway}

Ви можете розширити визначення вашого шлюзу підтримкою [mutual TLS](https://en.wikipedia.org/wiki/Mutual_authentication).

1. Змініть облікові дані ingress gateway, видаливши його секрет і створивши новий. Сервер використовує сертифікат ЦС для перевірки своїх клієнтів, і ми повинні використовувати ключ `ca.crt` для зберігання сертифіката ЦС.

    {{< text bash >}}
    $ kubectl -n istio-system delete secret httpbin-credential
    $ kubectl create -n istio-system secret generic httpbin-credential \
      --from-file=tls.key=example_certs1/httpbin.example.com.key \
      --from-file=tls.crt=example_certs1/httpbin.example.com.crt \
      --from-file=ca.crt=example_certs1/example.com.crt
    {{< /text >}}

    {{< tip >}}
    {{< boilerplate crl-tip >}}

    Обліковий запис може також включати [OCSP Staple](https://datatracker.ietf.org/doc/html/rfc6961) за допомогою ключа `tls.ocsp-staple`, який можна вказати додатковим аргументом: `--from-file=tls.ocsp-staple=/some/path/to/your-ocsp-staple.pem`.
    {{< /tip >}}

2. Налаштуйте ingress gateway:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Змініть визначення шлюзу, щоб встановити режим TLS на `MUTUAL`.

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # використовуйте стандартний istio ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: MUTUAL
      credentialName: httpbin-credential # має збігатись з secret
    hosts:
    - httpbin.example.com
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Оскільки Kubernetes Gateway API наразі не підтримує термінацію mutual TLS в [Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io/v1.Gateway), ми використовуємо Istio-специфічну опцію, `gateway.istio.io/tls-terminate-mode: MUTUAL`,  щоб зробити це:

{{< text bash >}}
$ cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: mygateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "httpbin.example.com"
    port: 443
    protocol: HTTPS
    tls:
      mode: Terminate
      certificateRefs:
      - name: httpbin-credential
      options:
        gateway.istio.io/tls-terminate-mode: MUTUAL
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels:
            kubernetes.io/metadata.name: default
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

1) Спробуйте надіслати HTTPS-запит, використовуючи попередній підхід, і подивіться, що це не вдасться:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
    --cacert example_certs1/example.com.crt "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    * TLSv1.3 (OUT), TLS handshake, Client hello (1):
    * TLSv1.3 (IN), TLS handshake, Server hello (2):
    * TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
    * TLSv1.3 (IN), TLS handshake, Request CERT (13):
    * TLSv1.3 (IN), TLS handshake, Certificate (11):
    * TLSv1.3 (IN), TLS handshake, CERT verify (15):
    * TLSv1.3 (IN), TLS handshake, Finished (20):
    * TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
    * TLSv1.3 (OUT), TLS handshake, Certificate (11):
    * TLSv1.3 (OUT), TLS handshake, Finished (20):
    * TLSv1.3 (IN), TLS alert, unknown (628):
    * OpenSSL SSL_read: error:1409445C:SSL routines:ssl3_read_bytes:tlsv13 alert certificate required, errno 0
    {{< /text >}}

2) Передайте сертифікат клієнта і приватний ключ `curl` і повторно надішліть запит. Передайте сертифікат клієнта з прапорцем `--cert` і ваш приватний ключ з прапорцем `--key` в `curl`:

    {{< text bash >}}
    $ curl -v -HHost:httpbin.example.com --resolve "httpbin.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" \
      --cacert example_certs1/example.com.crt --cert example_certs1/client.example.com.crt --key example_certs1/client.example.com.key \
      "https://httpbin.example.com:$SECURE_INGRESS_PORT/status/418"
    ...
    HTTP/2 418
    ...
    server: istio-envoy
    ...
    I'm a teapot!
    ...
    {{< /text >}}

## Додаткова інформація {#more-info}

### Формати ключів {#key-formats}

Istio підтримує кілька різних форматів секретів для інтеграції з різними інструментами, такими як [cert-manager](/docs/ops/integrations/certmanager/):

* TLS секрет з ключами `tls.key` та `tls.crt`, як описано вище. Для взаємного TLS можна використовувати ключ `ca.crt`.
* Загальний секрет з ключами `key` та `cert`. Для взаємного TLS можна використовувати ключ `cacert`.
* Загальний секрет з ключами `key` та `cert`. Для взаємного TLS можна використовувати окремий загальний секрет з назвою `<secret>-cacert`, який містить ключ `cacert`. Наприклад, `httpbin-credential` має `key` та `cert`, а `httpbin-credential-cacert` має `cacert`.
* Значення ключа `cacert` може бути зв'язкою сертифікатів CA, яка складається з окремих об'єднаних сертифікатів CA.

### SNI маршрутизація {#sni-routing}

HTTPS `Gateway` здійснює [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) зіставлення з його сконфігурованими хостами перед пересиланням запиту, що може призвести до збою деяких запитів. Дивіться [налаштування SNI маршрутизації](/docs/ops/common-problems/network-issues/#configuring-sni-routing-when-not-sending-sni) для отримання деталей.

## Усунення несправностей {#troubleshooting}

*   Перевірте значення змінних середовища `INGRESS_HOST` та `SECURE_INGRESS_PORT`. Переконайтеся, що вони мають дійсні значення відповідно до результатів наступних команд:

    {{< text bash >}}
    $ kubectl get svc -n istio-system
    $ echo "INGRESS_HOST=$INGRESS_HOST, SECURE_INGRESS_PORT=$SECURE_INGRESS_PORT"
    {{< /text >}}

*   Переконайтеся, що значення `INGRESS_HOST` є IP-адресою. У деяких хмарних платформах, наприклад, AWS, ви можете отримати доменне імʼя замість IP-адреси. Це завдання очікує IP-адресу, тому вам потрібно буде перетворити її за допомогою команд, схожих на такі:

    {{< text bash >}}
    $ nslookup ab52747ba608744d8afd530ffd975cbf-330887905.us-east-1.elb.amazonaws.com
    $ export INGRESS_HOST=3.225.207.109
    {{< /text >}}

*   Перевірте журнал контролера шлюзу на наявність повідомлень про помилки:

    {{< text syntax=bash snip_id=none >}}
    $ kubectl logs -n istio-system <gateway-service-pod>
    {{< /text >}}

*   Якщо ви використовуєте macOS, перевірте, чи використовуєте ви `curl`, скомпільований з бібліотекою [LibreSSL](http://www.libressl.org), як описано в розділі [Перш ніж розпочати](#before-you-begin).

*   Перевірте, чи секрети успішно створені в просторі імен `istio-system`:

    {{< text bash >}}
    $ kubectl -n istio-system get secrets
    {{< /text >}}

    Секрети `httpbin-credential` та `helloworld-credential` повинні бути показані у переліку секретів.

*   Перевірте журнали, щоб підтвердити, що агент ingress gateway надіслав пару ключ/сертифікат до шлюзу входу:

    {{< text syntax=bash snip_id=none >}}
    $ kubectl logs -n istio-system <gateway-service-pod>
    {{< /text >}}

    Журнал має показувати, що секрет `httpbin-credential` був доданий. Якщо використовується взаємний TLS, то також має зʼявитися секрет `httpbin-credential-cacert`. Перевірте, що в журналі відображається, що агент шлюзу отримав запити SDS від шлюзу входу, що імʼя ресурсу є `httpbin-credential`, і що шлюз входу отримав пару ключ/сертифікат. Якщо використовується взаємний TLS, журнал має показувати, що ключ/сертифікат був надісланий до шлюзу входу, що агент шлюзу отримав запит SDS з імʼям ресурсу `httpbin-credential-cacert`, і що шлюз входу отримав кореневий сертифікат.

## Очищення {#cleanup}

1.  Видаліть конфігурацію шлюзу та маршрути:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete gateway mygateway
$ kubectl delete virtualservice httpbin helloworld
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete -n istio-system gtw mygateway
$ kubectl delete httproute httpbin helloworld
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Видаліть секрети, сертифікати та ключі:

    {{< text bash >}}
    $ kubectl delete -n istio-system secret httpbin-credential helloworld-credential
    $ rm -rf ./example_certs1 ./example_certs2
    {{< /text >}}

3)  Вимкніть служби `httpbin` і `helloworld`:

    {{< text bash >}}
    $ kubectl delete -f samples/httpbin/httpbin.yaml
    $ kubectl delete deployment helloworld-v1
    $ kubectl delete service helloworld
    {{< /text >}}
