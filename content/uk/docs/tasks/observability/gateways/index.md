---
title: Віддалений доступ до надбудов телеметрії.
description: Це завдання показує, як налаштувати зовнішній доступ до набору надбудов телеметрії Istio.
weight: 98
keywords: [telemetry,gateway,jaeger,zipkin,tracing,kiali,prometheus,addons]
aliases:
 - /uk/docs/tasks/telemetry/gateways/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

Це завдання показує, як налаштувати Istio для відкриття та доступу до надбудов телеметрії за межами кластера.

## Налаштування віддаленого доступу {#configuring-remote-access}

Віддалений доступ до надбудов телеметрії можна налаштувати кількома різними способами. Це завдання охоплює два основних методи доступу: захищений (через HTTPS) та незахищений (через HTTP). Захищений метод *рекомендується* для будь-якого промислового або чутливого середовища. Незахищений доступ простіший у налаштуванні, але не захищає жодні облікові дані чи дані, що передаються за межі вашого кластера.

Для обох варіантів спочатку виконайте ці кроки:

1. [Встановіть Istio](/docs/setup/install/istioctl) у вашому кластері.

    Щоб додатково встановити надбудови телеметрії, дотримуйтесь документації з [інтеграцій](/docs/ops/integrations/).

1. Налаштуйте домен для експонування надбудов. У цьому прикладі ви експонуєте кожну надбудову у піддомені, наприклад, `grafana.example.com`.

    * Якщо у вас є домен, що вказує на зовнішню IP-адресу `istio-ingressgateway` (наприклад, example.com):

    {{< text bash >}}
    $ export INGRESS_DOMAIN="example.com"
    {{< /text >}}

    * Якщо у вас немає домену, ви можете використовувати [`nip.io`](https://nip.io/), який автоматично виконає розвʼязання для IP-адреси, що надається. Це не рекомендується для промислового використання.

    {{< text bash >}}
    $ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    $ export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io
    {{< /text >}}

### Варіант 1: Захищений доступ (HTTPS) {#option-1-secure-access-https}

Для захищеного доступу потрібен серверний сертифікат. Виконайте ці кроки, щоб встановити та налаштувати серверні сертифікати для домену, який ви контролюєте.

{{< warning >}}
Цей варіант охоплює лише захист транспортного рівня. Вам також слід налаштувати надбудови телеметрії для вимоги автентифікації при їх відкритті зовні.
{{< /warning >}}

Цей приклад використовує самопідписні сертифікати, які можуть бути не підходящими для промислового використання. Для таких випадків розгляньте використання [cert-manager](/docs/ops/integrations/certmanager/) або інших інструментів для видачі сертифікатів. Ви також можете відвідати завдання [Захист шлюзів за допомогою HTTPS](/docs/tasks/traffic-management/ingress/secure-ingress/) для загальної інформації про використання HTTPS на шлюзі.

1. Налаштуйте сертифікати. Цей приклад використовує `openssl` для самопідписання.

    {{< text bash >}}
    $ CERT_DIR=/tmp/certs
    $ mkdir -p ${CERT_DIR}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj "/O=example Inc./CN=*.${INGRESS_DOMAIN}" -keyout ${CERT_DIR}/ca.key -out ${CERT_DIR}/ca.crt
    $ openssl req -out ${CERT_DIR}/cert.csr -newkey rsa:2048 -nodes -keyout ${CERT_DIR}/tls.key -subj "/CN=*.${INGRESS_DOMAIN}/O=example organization"
    $ openssl x509 -req -sha256 -days 365 -CA ${CERT_DIR}/ca.crt -CAkey ${CERT_DIR}/ca.key -set_serial 0 -in ${CERT_DIR}/cert.csr -out ${CERT_DIR}/tls.crt
    $ kubectl create -n istio-system secret tls telemetry-gw-cert --key=${CERT_DIR}/tls.key --cert=${CERT_DIR}/tls.crt
    {{< /text >}}

1. Застосуйте мережеву конфігурацію для надбудов телеметрії.

    1. Застосуйте наступну конфігурацію для розгортання Grafana:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: grafana-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 443
              name: https-grafana
              protocol: HTTPS
            tls:
              mode: SIMPLE
              credentialName: telemetry-gw-cert
            hosts:
            - "grafana.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: grafana-vs
          namespace: istio-system
        spec:
          hosts:
          - "grafana.${INGRESS_DOMAIN}"
          gateways:
          - grafana-gateway
          http:
          - route:
            - destination:
                host: grafana
                port:
                  number: 3000
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: grafana
          namespace: istio-system
        spec:
          host: grafana
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/grafana-gateway created
        virtualservice.networking.istio.io/grafana-vs created
        destinationrule.networking.istio.io/grafana created
        {{< /text >}}

    1. Застосуйте наступну конфігурацію для розгортання Kiali:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: kiali-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 443
              name: https-kiali
              protocol: HTTPS
            tls:
              mode: SIMPLE
              credentialName: telemetry-gw-cert
            hosts:
            - "kiali.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: kiali-vs
          namespace: istio-system
        spec:
          hosts:
          - "kiali.${INGRESS_DOMAIN}"
          gateways:
          - kiali-gateway
          http:
          - route:
            - destination:
                host: kiali
                port:
                  number: 20001
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: kiali
          namespace: istio-system
        spec:
          host: kiali
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/kiali-gateway created
        virtualservice.networking.istio.io/kiali-vs created
        destinationrule.networking.istio.io/kiali created
        {{< /text >}}

    1. Застосуйте наступну конфігурацію для розгортання Prometheus:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: prometheus-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 443
              name: https-prom
              protocol: HTTPS
            tls:
              mode: SIMPLE
              credentialName: telemetry-gw-cert
            hosts:
            - "prometheus.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: prometheus-vs
          namespace: istio-system
        spec:
          hosts:
          - "prometheus.${INGRESS_DOMAIN}"
          gateways:
          - prometheus-gateway
          http:
          - route:
            - destination:
                host: prometheus
                port:
                  number: 9090
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: prometheus
          namespace: istio-system
        spec:
          host: prometheus
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/prometheus-gateway created
        virtualservice.networking.istio.io/prometheus-vs created
        destinationrule.networking.istio.io/prometheus created
        {{< /text >}}

    1. Застосуйте наведену нижче конфігурацію для запуску служби трейсингу:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: tracing-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 443
              name: https-tracing
              protocol: HTTPS
            tls:
              mode: SIMPLE
              credentialName: telemetry-gw-cert
            hosts:
            - "tracing.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: tracing-vs
          namespace: istio-system
        spec:
          hosts:
          - "tracing.${INGRESS_DOMAIN}"
          gateways:
          - tracing-gateway
          http:
          - route:
            - destination:
                host: tracing
                port:
                  number: 80
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: tracing
          namespace: istio-system
        spec:
          host: tracing
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/tracing-gateway created
        virtualservice.networking.istio.io/tracing-vs created
        destinationrule.networking.istio.io/tracing created
        {{< /text >}}

1. Відвідайте надбудови телеметрії через ваш оглядач.

    {{< warning >}}
    Якщо ви використовували самопідписні сертифікати, ваш оглядач, ймовірно, позначить їх як небезпечні.
    {{< /warning >}}

    * Kiali: `https://kiali.${INGRESS_DOMAIN}`
    * Prometheus: `https://prometheus.${INGRESS_DOMAIN}`
    * Grafana: `https://grafana.${INGRESS_DOMAIN}`
    * Tracing: `https://tracing.${INGRESS_DOMAIN}`

### Варіант 2: Незахищений доступ (HTTP) {#option-2-insecure-access-http}

1. Застосуйте мережеву конфігурацію для надбудов телеметрії.

    1. Застосуйте наступну конфігурацію для розгортання Grafana:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: grafana-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 80
              name: http-grafana
              protocol: HTTP
            hosts:
            - "grafana.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: grafana-vs
          namespace: istio-system
        spec:
          hosts:
          - "grafana.${INGRESS_DOMAIN}"
          gateways:
          - grafana-gateway
          http:
          - route:
            - destination:
                host: grafana
                port:
                  number: 3000
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: grafana
          namespace: istio-system
        spec:
          host: grafana
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/grafana-gateway created
        virtualservice.networking.istio.io/grafana-vs created
        destinationrule.networking.istio.io/grafana created
        {{< /text >}}

    1. Застосуйте наступну конфігурацію для розгортання Kiali:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: kiali-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 80
              name: http-kiali
              protocol: HTTP
            hosts:
            - "kiali.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: kiali-vs
          namespace: istio-system
        spec:
          hosts:
          - "kiali.${INGRESS_DOMAIN}"
          gateways:
          - kiali-gateway
          http:
          - route:
            - destination:
                host: kiali
                port:
                  number: 20001
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: kiali
          namespace: istio-system
        spec:
          host: kiali
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/kiali-gateway created
        virtualservice.networking.istio.io/kiali-vs created
        destinationrule.networking.istio.io/kiali created
        {{< /text >}}

    1. Застосуйте наступну конфігурацію для розгортання Prometheus:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: prometheus-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 80
              name: http-prom
              protocol: HTTP
            hosts:
            - "prometheus.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: prometheus-vs
          namespace: istio-system
        spec:
          hosts:
          - "prometheus.${INGRESS_DOMAIN}"
          gateways:
          - prometheus-gateway
          http:
          - route:
            - destination:
                host: prometheus
                port:
                  number: 9090
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: prometheus
          namespace: istio-system
        spec:
          host: prometheus
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/prometheus-gateway created
        virtualservice.networking.istio.io/prometheus-vs created
        destinationrule.networking.istio.io/prometheus created
        {{< /text >}}

    1. Застосуйте наведену нижче конфігурацію для запуску служби трейсингу:

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1
        kind: Gateway
        metadata:
          name: tracing-gateway
          namespace: istio-system
        spec:
          selector:
            istio: ingressgateway
          servers:
          - port:
              number: 80
              name: http-tracing
              protocol: HTTP
            hosts:
            - "tracing.${INGRESS_DOMAIN}"
        ---
        apiVersion: networking.istio.io/v1
        kind: VirtualService
        metadata:
          name: tracing-vs
          namespace: istio-system
        spec:
          hosts:
          - "tracing.${INGRESS_DOMAIN}"
          gateways:
          - tracing-gateway
          http:
          - route:
            - destination:
                host: tracing
                port:
                  number: 80
        ---
        apiVersion: networking.istio.io/v1
        kind: DestinationRule
        metadata:
          name: tracing
          namespace: istio-system
        spec:
          host: tracing
          trafficPolicy:
            tls:
              mode: DISABLE
        ---
        EOF
        gateway.networking.istio.io/tracing-gateway created
        virtualservice.networking.istio.io/tracing-vs created
        destinationrule.networking.istio.io/tracing created
        {{< /text >}}

1. Відвідайте надбудови телеметрії через ваш оглядач.

    * Kiali: `http://kiali.${INGRESS_DOMAIN}`
    * Prometheus: `http://prometheus.${INGRESS_DOMAIN}`
    * Grafana: `http://grafana.${INGRESS_DOMAIN}`
    * Tracing: `http://tracing.${INGRESS_DOMAIN}`

## Очищення {#cleanup}

* Видаліть усі повʼязані шлюзи:

    {{< text bash >}}
    $ kubectl -n istio-system delete gateway grafana-gateway kiali-gateway prometheus-gateway tracing-gateway
    gateway.networking.istio.io "grafana-gateway" deleted
    gateway.networking.istio.io "kiali-gateway" deleted
    gateway.networking.istio.io "prometheus-gateway" deleted
    gateway.networking.istio.io "tracing-gateway" deleted
    {{< /text >}}

* Видаліть усі повʼязані віртуальні сервіси:

    {{< text bash >}}
    $ kubectl -n istio-system delete virtualservice grafana-vs kiali-vs prometheus-vs tracing-vs
    virtualservice.networking.istio.io "grafana-vs" deleted
    virtualservice.networking.istio.io "kiali-vs" deleted
    virtualservice.networking.istio.io "prometheus-vs" deleted
    virtualservice.networking.istio.io "tracing-vs" deleted
    {{< /text >}}

* Видаліть усі повʼязані правила призначення:

    {{< text bash >}}
    $ kubectl -n istio-system delete destinationrule grafana kiali prometheus tracing
    destinationrule.networking.istio.io "grafana" deleted
    destinationrule.networking.istio.io "kiali" deleted
    destinationrule.networking.istio.io "prometheus" deleted
    destinationrule.networking.istio.io "tracing" deleted
    {{< /text >}}
