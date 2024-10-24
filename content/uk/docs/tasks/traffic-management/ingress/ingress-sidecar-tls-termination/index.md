---
title: Ingress Sidecar термінація TLS
description: Описує, як термінувати TLS-трафік на додатковому пристрої без використання Ingress Gateway.
weight: 31
keywords: [traffic-management,ingress,https]
owner: istio/wg-networking-maintainers
test: yes
---

У звичайному розгортанні Istio mesh термінація TLS для запитів від клієнтів відбувається в Ingress Gateway. Хоча це задовольняє більшість випадків використання, для деяких сценаріїв (наприклад, API Gateway у mesh) шлюз входу може бути непотрібний. Це завдання показує, як усунути додатковий перехід, введений Ingress Gateway Istio, і дозволити Envoy sidecar, що працює поруч з застосунком, виконувати темінацію TLS для запитів, що надходять ззовні службової мережі.

Приклад HTTPS-сервісу, що використовується для цього завдання, є простий сервіс [httpbin](https://httpbin.org). У наступних кроках ви розгорнете сервіс httpbin всередині вашої сервісної мережі і налаштуєте його.

{{< boilerplate experimental-feature-warning >}}

## Перш ніж розпочати {#before-you-begin}

*   Налаштуйте Istio, дотримуючись інструкцій з [Посібника з встановлення](/docs/setup/) увімкнувши експериментальну функцію `ENABLE_TLS_ON_SIDECAR_INGRESS`.

    {{< text bash >}}
    $ istioctl install --set profile=default --set values.pilot.env.ENABLE_TLS_ON_SIDECAR_INGRESS=true
    {{< /text >}}

*   Створіть простір імен test, в якому буде розгорнуто цільовий сервіс `httpbin`. Переконайтеся, що увімкнуто інʼєкцію sidecar для простору імен.

    {{< text bash >}}
    $ kubectl create ns test
    $ kubectl label namespace test istio-injection=enabled
    {{< /text >}}

## Увімкнення глобального mTLS {#enable-global-mtls}

Застосуйте наступну політику `PeerAuthentication`, щоб вимагати трафік mTLS для всіх робочих навантажень у мережі.

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
spec:
  mtls:
    mode: STRICT
EOF
{{< /text >}}

## Вимкнення PeerAuthentication для відкритого ззовні порту httpbin {#disable-peerauthentication-for-the-externally-exposed-httpbin-port}

Вимкніть `PeerAuthentication` для порту сервісу httpbin, який буде виконувати вхідну термінацію TLS з sidecar. Зверніть увагу, що це `targetPort` сервісу httpbin, який слід використовувати виключно для зовнішнього зв'язку.

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: disable-peer-auth-for-external-mtls-port
  namespace: test
spec:
  selector:
    matchLabels:
      app: httpbin
  mtls:
    mode: STRICT
  portLevelMtls:
    9080:
      mode: DISABLE
EOF
{{< /text >}}

## Генерація сертифіката ЦС, серверного та клієнтського сертифіката/ключа {#generate-ca-cert-server-cert-key-and-client-cert-key}

Для цього завдання ви можете скористатися вашим улюбленим інструментом для генерації сертифікатів і ключів. У наведених нижче командах використовується
[openssl](https://man.openbsd.org/openssl.1):

{{< text bash >}}
$ #CA is example.com
$ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
$ #Server is httpbin.test.svc.cluster.local
$ openssl req -out httpbin.test.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout httpbin.test.svc.cluster.local.key -subj "/CN=httpbin.test.svc.cluster.local/O=httpbin organization"
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in httpbin.test.svc.cluster.local.csr -out httpbin.test.svc.cluster.local.crt
$ #client is client.test.svc.cluster.local
$ openssl req -out client.test.svc.cluster.local.csr -newkey rsa:2048 -nodes -keyout client.test.svc.cluster.local.key -subj "/CN=client.test.svc.cluster.local/O=client organization"
$ openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 1 -in client.test.svc.cluster.local.csr -out client.test.svc.cluster.local.crt
{{< /text >}}

## Створіть k8s-секрети для сертифікатів і ключів {#create-k8s-secrets-for-the-certificates-and-keys}

{{< text bash >}}
$ kubectl -n test create secret generic httpbin-mtls-termination-cacert --from-file=ca.crt=./example.com.crt
$ kubectl -n test create secret tls httpbin-mtls-termination --cert ./httpbin.test.svc.cluster.local.crt --key ./httpbin.test.svc.cluster.local.key
{{< /text >}}

## Розгортання тестового сервісу httpbin {#deploy-the-httpbin-test-service}

Коли розгорнуто httpbin, потрібно використовувати анотації `userVolumeMount` у розгортанні для монтування сертифікатів для sidecar istio-proxy. Зверніть увагу, що цей крок потрібен лише тому, що наразі Istio не підтримує `credentialName` у конфігурації sidecar.

{{< text yaml >}}
sidecar.istio.io/userVolume: '{"tls-secret":{"secret":{"secretName":"httpbin-mtls-termination","optional":true}},"tls-ca-secret":{"secret":{"secretName":"httpbin-mtls-termination-cacert"}}}'
sidecar.istio.io/userVolumeMount: '{"tls-secret":{"mountPath":"/etc/istio/tls-certs/","readOnly":true},"tls-ca-secret":{"mountPath":"/etc/istio/tls-ca-certs/","readOnly":true}}'
{{< /text >}}

Використовуйте наступну команду для розгортання сервісу `httpbin` з необхідною конфігурацією `userVolumeMount`:

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: httpbin
---
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  labels:
    app: httpbin
    service: httpbin
spec:
  ports:
  - port: 8443
    name: https
    targetPort: 9080
  - port: 8080
    name: http
    targetPort: 9081
  selector:
    app: httpbin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpbin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: httpbin
      version: v1
  template:
    metadata:
      labels:
        app: httpbin
        version: v1
      annotations:
        sidecar.istio.io/userVolume: '{"tls-secret":{"secret":{"secretName":"httpbin-mtls-termination","optional":true}},"tls-ca-secret":{"secret":{"secretName":"httpbin-mtls-termination-cacert"}}}'
        sidecar.istio.io/userVolumeMount: '{"tls-secret":{"mountPath":"/etc/istio/tls-certs/","readOnly":true},"tls-ca-secret":{"mountPath":"/etc/istio/tls-ca-certs/","readOnly":true}}'
    spec:
      serviceAccountName: httpbin
      containers:
      - image: docker.io/kennethreitz/httpbin
        imagePullPolicy: IfNotPresent
        name: httpbin
        ports:
        - containerPort: 80
EOF
{{< /text >}}

## Налаштуйте httpbin для ввімкнення зовнішнього mTLS {#configure-httpbin-to-enable-external-mtls}

Це основний крок для цієї функції. Використовуючи API `Sidecar`, налаштуйте параметри вхідного TLS. Режим TLS може бути `SIMPLE` або `MUTUAL`. У цьому прикладі використовується `MUTUAL`.

{{< text bash >}}
$ kubectl -n test apply -f - <<EOF
apiVersion: networking.istio.io/v1
kind: Sidecar
metadata:
  name: ingress-sidecar
  namespace: test
spec:
  workloadSelector:
    labels:
      app: httpbin
      version: v1
  ingress:
  - port:
      number: 9080
      protocol: HTTPS
      name: external
    defaultEndpoint: 0.0.0.0:80
    tls:
      mode: MUTUAL
      privateKey: "/etc/istio/tls-certs/tls.key"
      serverCertificate: "/etc/istio/tls-certs/tls.crt"
      caCertificates: "/etc/istio/tls-ca-certs/ca.crt"
  - port:
      number: 9081
      protocol: HTTP
      name: internal
    defaultEndpoint: 0.0.0.0:80
EOF
{{< /text >}}

## Перевірка {#verification}

Тепер, коли сервер httpbin розгорнуто та налаштовано, запустіть два клієнти для тестування з’єднання як всередині, так і ззовні mesh:

1. Внутрішній клієнт (sleep) в тому ж просторі імен (test), що і сервіс httpbin, з доданим sidecar.
2. Зовнішній клієнт (sleep) в просторі імен default (тобто, поза сервісною мережею).

{{< text bash >}}
$ kubectl apply -f samples/sleep/sleep.yaml
$ kubectl -n test apply -f samples/sleep/sleep.yaml
{{< /text >}}

Запустіть наступні команди, щоб перевірити, що все працює і налаштовано правильно.

{{< text bash >}}
$ kubectl get pods
NAME                     READY   STATUS    RESTARTS   AGE
sleep-557747455f-xx88g   1/1     Running   0          4m14s
{{< /text >}}

{{< text bash >}}
$ kubectl get pods -n test
NAME                       READY   STATUS    RESTARTS   AGE
httpbin-5bbdbd6588-z9vbs   2/2     Running   0          8m44s
sleep-557747455f-brzf6     2/2     Running   0          6m57s
{{< /text >}}

{{< text bash >}}
$ kubectl get svc -n test
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)             AGE
httpbin   ClusterIP   10.100.78.113   <none>        8443/TCP,8080/TCP   10m
sleep     ClusterIP   10.110.35.153   <none>        80/TCP              8m49s
{{< /text >}}

У наступній команді замініть `httpbin-5bbdbd6588-z9vbs` на назву вашого podʼа httpbin.

{{< text bash >}}
$ istioctl proxy-config secret httpbin-5bbdbd6588-z9vbs.test
RESOURCE NAME                                                           TYPE           STATUS     VALID CERT     SERIAL NUMBER                               NOT AFTER                NOT BEFORE
file-cert:/etc/istio/tls-certs/tls.crt~/etc/istio/tls-certs/tls.key     Cert Chain     ACTIVE     true           1                                           2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
default                                                                 Cert Chain     ACTIVE     true           329492464719328863283539045344215802956     2022-02-15T09:55:46Z     2022-02-14T09:53:46Z
ROOTCA                                                                  CA             ACTIVE     true           204427760222438623495455009380743891800     2032-02-07T16:58:00Z     2022-02-09T16:58:00Z
file-root:/etc/istio/tls-ca-certs/ca.crt                                Cert Chain     ACTIVE     true           14033888812979945197                        2023-02-14T09:51:56Z     2022-02-14T09:51:56Z
{{< /text >}}

### Перевірка внутрішнього мережевого зʼєднання на порту 8080 {#verify-internal-mesh-connectivity-on-port-8080}

{{< text bash >}}
$ export INTERNAL_CLIENT=$(kubectl -n test get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl -n test exec "${INTERNAL_CLIENT}" -c sleep -- curl -IsS "http://httpbin:8080/status/200"
HTTP/1.1 200 OK
server: envoy
date: Mon, 24 Oct 2022 09:04:52 GMT
content-type: text/html; charset=utf-8
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 0
x-envoy-upstream-service-time: 5
{{< /text >}}

### Перевірка зʼєднання ззовні в середину mesh на порту 8443 {#verify-external-to-internal-mesh-connectivity-on-port-8443}

Щоб перевірити трафік mTLS від зовнішнього клієнта, спочатку скопіюйте сертифікат центру сертифікації та сертифікат/ключ клієнта в клієнта sleep, який працює у просторі імен default.

{{< text bash >}}
$ export EXTERNAL_CLIENT=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
$ kubectl cp client.test.svc.cluster.local.key default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp client.test.svc.cluster.local.crt default/"${EXTERNAL_CLIENT}":/tmp/
$ kubectl cp example.com.crt default/"${EXTERNAL_CLIENT}":/tmp/ca.crt
{{< /text >}}

Тепер, коли сертифікати доступні для зовнішнього клієнта sleep, ви можете перевірити підключення з нього до внутрішнього httpbin-сервісу за допомогою наступної команди.

{{< text bash >}}
$ kubectl exec "${EXTERNAL_CLIENT}" -c sleep -- curl -IsS --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -HHost:httpbin.test.svc.cluster.local "https://httpbin.test.svc.cluster.local:8443/status/200"
server: istio-envoy
date: Mon, 24 Oct 2022 09:05:31 GMT
content-type: text/html; charset=utf-8
access-control-allow-origin: *
access-control-allow-credentials: true
content-length: 0
x-envoy-upstream-service-time: 4
x-envoy-decorator-operation: ingress-sidecar.test:9080/*
{{< /text >}}

Окрім перевірки зовнішнього mTLS-зʼєднання через вхідний порт 8443, важливо також переконатися, що порт 8080 не приймає ніякого зовнішнього mTLS-трафіку.

{{< text bash >}}
$ kubectl exec "${EXTERNAL_CLIENT}" -c sleep -- curl -IsS --cacert /tmp/ca.crt --key /tmp/client.test.svc.cluster.local.key --cert /tmp/client.test.svc.cluster.local.crt -HHost:httpbin.test.svc.cluster.local "http://httpbin.test.svc.cluster.local:8080/status/200"
curl: (56) Recv failure: Connection reset by peer
command terminated with exit code 56
{{< /text >}}

## Очищення прикладу термінації взаємного TLS{#cleanup-the-mutual-tls-termination-example}

1.  Видаліть створені ресурси Kubernetes:

    {{< text bash >}}
    $ kubectl delete secret httpbin-mtls-termination httpbin-mtls-termination-cacert -n test
    $ kubectl delete service httpbin sleep -n test
    $ kubectl delete deployment httpbin sleep -n test
    $ kubectl delete namespace test
    $ kubectl delete service sleep
    $ kubectl delete deployment sleep
    {{< /text >}}

1.  Видаліть сертифікати та приватні ключі:

    {{< text bash >}}
    $ rm example.com.crt example.com.key httpbin.test.svc.cluster.local.crt httpbin.test.svc.cluster.local.key httpbin.test.svc.cluster.local.csr \
        client.test.svc.cluster.local.crt client.test.svc.cluster.local.key client.test.svc.cluster.local.csr
    {{< /text >}}

1.  Видаліть Istio з кластера:

    {{< text bash >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}
