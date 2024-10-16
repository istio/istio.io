---
title: Ingress Gateway без термінації TLS
description: Описує, як налаштувати пропуск SNI для ingress gateway.
weight: 30
keywords: [traffic-management,ingress,https]
aliases:
  - /docs/examples/advanced-gateways/ingress-sni-passthrough/
owner: istio/wg-networking-maintainers
test: yes
---

Завдання [Захист Gateways з HTTPS](/docs/tasks/traffic-management/ingress/secure-ingress/) описує, як налаштувати доступ до HTTP-сервісу через HTTPS шлюз входу. У цьому прикладі розглядається, як налаштувати доступ до HTTPS-сервісу через HTTPS шлюз входу, тобто налаштувати шлюз входу для пропуску SNI, замість термінації TLS на вхідних запитах.

Приклад HTTPS-сервісу, що використовується для цього завдання, є простий сервер [NGINX](https://www.nginx.com). У наступних кроках спочатку розгортаєте сервіс NGINX у вашому кластері Kubernetes. Потім налаштовуєте шлюз для забезпечення доступу до сервісу через хост `nginx.example.com`.

{{< boilerplate gateway-api-gamma-experimental >}}

## Перш ніж почати {#before-you-begin}

Налаштуйте Istio, дотримуючись інструкцій з [Посібника з встановлення](/docs/setup/).

## Генерація сертифікатів та ключів для клієнта і сервера {#generate-client-and-server-certificates-and-keys}

Для цього завдання ви можете використовувати улюблений інструмент для генерації сертифікатів та ключів. Команди нижче використовують [openssl](https://man.openbsd.org/openssl.1):

1.  Створіть кореневий сертифікат і приватний ключ для підпису сертифікатів для ваших сервісів:

    {{< text bash >}}
    $ mkdir example_certs
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example_certs/example.com.key -out example_certs/example.com.crt
    {{< /text >}}

1.  Створіть сертифікат та приватний ключ для `nginx.example.com`:

    {{< text bash >}}
    $ openssl req -out example_certs/nginx.example.com.csr -newkey rsa:2048 -nodes -keyout example_certs/nginx.example.com.key -subj "/CN=nginx.example.com/O=some organization"
    $ openssl x509 -req -sha256 -days 365 -CA example_certs/example.com.crt -CAkey example_certs/example.com.key -set_serial 0 -in example_certs/nginx.example.com.csr -out example_certs/nginx.example.com.crt
    {{< /text >}}

## Розгортання сервера NGINX {#deploy-an-nginx-server}

1. Створіть Kubernetes [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) для зберігання сертифіката сервера.

    {{< text bash >}}
    $ kubectl create secret tls nginx-server-certs \
      --key example_certs/nginx.example.com.key \
      --cert example_certs/nginx.example.com.crt
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

        server_name nginx.example.com;
        ssl_certificate /etc/nginx-server-certs/tls.crt;
        ssl_certificate_key /etc/nginx-server-certs/tls.key;
      }
    }
    EOF
    {{< /text >}}

1.  Створіть Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) для зберігання конфігурації сервера NGINX:

    {{< text bash >}}
    $ kubectl create configmap nginx-configmap --from-file=nginx.conf=./nginx.conf
    {{< /text >}}

1.  Розгорніть сервер NGINX:

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: v1
    kind: Service
    metadata:
      name: my-nginx
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
    spec:
      selector:
        matchLabels:
          run: my-nginx
      replicas: 1
      template:
        metadata:
          labels:
            run: my-nginx
            sidecar.istio.io/inject: "true"
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
          volumes:
          - name: nginx-config
            configMap:
              name: nginx-configmap
          - name: nginx-server-certs
            secret:
              secretName: nginx-server-certs
    EOF
    {{< /text >}}

1.  Щоб перевірити, що сервер NGINX був успішно розгорнутий, надішліть запит до сервера з його sidecar-проксі без перевірки сертифіката сервера (використовуйте параметр `-k` для `curl`). Переконайтеся, що сертифікат сервера виводиться правильно, тобто `common name (CN)` дорівнює `nginx.example.com`.

    {{< text bash >}}
    $ kubectl exec "$(kubectl get pod  -l run=my-nginx -o jsonpath={.items..metadata.name})" -c istio-proxy -- curl -sS -v -k --resolve nginx.example.com:443:127.0.0.1 https://nginx.example.com
    ...
    SSL connection using TLSv1.2 / ECDHE-RSA-AES256-GCM-SHA384
    ALPN, server accepted to use http/1.1
    Server certificate:
      subject: CN=nginx.example.com; O=some organization
      start date: May 27 14:18:47 2020 GMT
      expire date: May 27 14:18:47 2021 GMT
      issuer: O=example Inc.; CN=example.com
      SSL certificate verify result: unable to get local issuer certificate (20), continuing anyway.

    > GET / HTTP/1.1
    > User-Agent: curl/7.58.0
    > Host: nginx.example.com
    ...
    < HTTP/1.1 200 OK

    < Server: nginx/1.17.10
    ...
    <!DOCTYPE html>
    <html>
    <head>
    <title>Welcome to nginx!</title>
    ...
    {{< /text >}}

## Налаштуйте ingress gateway {#configure-an-ingress-gateway}

1.  Визначте `Gateway`, що відкриває порт 443 з прохідним режимом TLS. Це вказує шлюзу пропускати вхідний трафік "as is", не перериваючи TLS:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Gateway
metadata:
  name: mygateway
spec:
  selector:
    istio: ingressgateway # використовуємо стандартний istio ingress gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: PASSTHROUGH
    hosts:
    - nginx.example.com
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: mygateway
spec:
  gatewayClassName: istio
  listeners:
  - name: https
    hostname: "nginx.example.com"
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough
    allowedRoutes:
      namespaces:
        from: All
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Налаштуйте маршрути для трафіку, що надходить через `Gateway`:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: nginx
spec:
  hosts:
  - nginx.example.com
  gateways:
  - mygateway
  tls:
  - match:
    - port: 443
      sniHosts:
      - nginx.example.com
    route:
    - destination:
        host: my-nginx
        port:
          number: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: nginx
spec:
  parentRefs:
  - name: mygateway
  hostnames:
  - "nginx.example.com"
  rules:
  - backendRefs:
    - name: my-nginx
      port: 443
EOF
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

3)  Визначте вхідний IP і порт:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

Дотримуйтесь інструкцій у статті [Визначення вхідного IP і портів](/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-ip-and-ports), щоб встановити змінні оточення `SECURE_INGRESS_PORT` та `INGRESS_HOST`.

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

Використовуйте наступні команди для встановлення змінних оточення `SECURE_INGRESS_PORT` та `INGRESS_HOST`:

{{< text bash >}}
$ kubectl wait --for=condition=programmed gtw mygateway
$ export INGRESS_HOST=$(kubectl get gtw mygateway -o jsonpath='{.status.addresses[0].value}')
$ export SECURE_INGRESS_PORT=$(kubectl get gtw mygateway -o jsonpath='{.spec.listeners[?(@.name=="https")].port}')
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

4)  Доступ до служби NGINX ззовні кластера. Зверніть увагу, що сервер повертає правильний сертифікат і його успішно перевірено (надруковано _SSL certificate verify ok_).

    {{< text bash >}}
    $ curl -v --resolve "nginx.example.com:$SECURE_INGRESS_PORT:$INGRESS_HOST" --cacert example_certs/example.com.crt "https://nginx.example.com:$SECURE_INGRESS_PORT"
    Server certificate:
      subject: CN=nginx.example.com; O=some organization
      start date: Wed, 15 Aug 2018 07:29:07 GMT
      expire date: Sun, 25 Aug 2019 07:29:07 GMT
      issuer: O=example Inc.; CN=example.com
      SSL certificate verify ok.

      < HTTP/1.1 200 OK
      < Server: nginx/1.15.2
      ...
      <html>
      <head>
      <title>Welcome to nginx!</title>
    {{< /text >}}

## Очищення {#cleanup}

1.  Видаліть конфігурацію шлюзу та маршрут:

{{< tabset category-name="config-api" >}}

{{< tab name="Istio APIs" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete gateway mygateway
$ kubectl delete virtualservice nginx
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete gtw mygateway
$ kubectl delete tlsroute nginx
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

2)  Видаліть ресурси NGINX і файл конфігурації:

    {{< text bash >}}
    $ kubectl delete secret nginx-server-certs
    $ kubectl delete configmap nginx-configmap
    $ kubectl delete service my-nginx
    $ kubectl delete deployment my-nginx
    $ rm ./nginx.conf
    {{< /text >}}

3)  Видаліть сертифікати та ключі:

    {{< text bash >}}
    $ rm -rf ./example_certs
    {{< /text >}}
