---
title: 远程访问遥测插件
description: 此任务向您展示如何配置从外部访问 Istio 遥测插件集。
weight: 98
keywords: [telemetry,gateway,jaeger,zipkin,tracing,kiali,prometheus,addons]
aliases:
 - /zh/docs/tasks/telemetry/gateways/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

此任务说明如何配置 Istio 以暴露和访问集群外部的遥测插件。

## 配置远程访问 {#configuring-remote-access}

远程访问遥测插件的方式有很多种。
该任务涵盖了两种基本访问方式：安全的（通过 HTTPS）和不安全的（通过 HTTP）。
对于任何生产或敏感环境，**强烈建议**通过安全方式访问。
不安全访问易于设置，但是无法保护在集群外传输的任何凭据或数据。

对于这两种方式，首先请执行以下步骤：

1. 在您的集群中[安装 Istio](/zh/docs/setup/install/istioctl)。

    要安装额外的遥测插件，请参考[集成](/zh/docs/ops/integrations/)文档。

1. 设置域名暴露这些插件。在此示例中，您将在子域名 `grafana.example.com` 上暴露每个插件。

    * 如果您有一个域名（例如 example.com）指向 `istio-ingressgateway` 的外部 IP 地址：

        {{< text bash >}}
        $ export INGRESS_DOMAIN="example.com"
        {{< /text >}}

    * 如果您没有域名，您可以使用 [`nip.io`](https://nip.io/)，它将自动解析为提供的
      IP 地址，这种方式不建议用于生产用途。

        {{< text bash >}}
        $ export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        $ export INGRESS_DOMAIN=${INGRESS_HOST}.nip.io
        {{< /text >}}

### 方式 1：安全访问（HTTPS）{#option-one-secure-access-HTTPS}

安全访问需要一个服务器证书。按照这些步骤来为您的域名安装并配置服务器证书。

{{< warning >}}
本方式**只**涵盖了传输层的安全。您还应该配置遥测插件，使其暴露在外部时需要身份验证。
{{< /warning >}}

此示例使用自签名证书，这可能不适合生产用途。针对生产环境，请考虑使用
[cert-manager](/zh/docs/ops/integrations/certmanager/) 或其他工具来配置证书。
您还可以参阅[使用 HTTPS 保护网关](/zh/docs/tasks/traffic-management/ingress/secure-ingress/)任务，
了解有关在网关上使用 HTTPS 的基本信息。

1. 设置证书，此示例使用 `openssl` 进行自签名。

    {{< text bash >}}
    $ CERT_DIR=/tmp/certs
    $ mkdir -p ${CERT_DIR}
    $ openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj "/O=example Inc./CN=*.${INGRESS_DOMAIN}" -keyout ${CERT_DIR}/ca.key -out ${CERT_DIR}/ca.crt
    $ openssl req -out ${CERT_DIR}/cert.csr -newkey rsa:2048 -nodes -keyout ${CERT_DIR}/tls.key -subj "/CN=*.${INGRESS_DOMAIN}/O=example organization"
    $ openssl x509 -req -sha256 -days 365 -CA ${CERT_DIR}/ca.crt -CAkey ${CERT_DIR}/ca.key -set_serial 0 -in ${CERT_DIR}/cert.csr -out ${CERT_DIR}/tls.crt
    $ kubectl create -n istio-system secret tls telemetry-gw-cert --key=${CERT_DIR}/tls.key --cert=${CERT_DIR}/tls.crt
    {{< /text >}}

1. 应用遥测插件的网络配置。

    1. 应用以下配置以暴露 Grafana：

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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

    1. 应用以下配置以暴露 Kiali：

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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

    1. 应用以下配置以暴露 Prometheus：

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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

    1. 应用以下配置以暴露跟踪服务：

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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

1. 通过浏览器访问这些遥测插件。

    {{< warning >}}
    如果您使用了自签名的证书，您的浏览器可能将其标记为不安全的。
    {{< /warning >}}

    * Kiali：`https://kiali.${INGRESS_DOMAIN}`
    * Prometheus：`https://prometheus.${INGRESS_DOMAIN}`
    * Grafana：`https://grafana.${INGRESS_DOMAIN}`
    * Tracing：`https://tracing.${INGRESS_DOMAIN}`

### 方式 2：不安全访问（HTTP）{#option-two-insecure-access-HTTP}

1. 应用遥测插件的网络配置。

    1. 应用以下配置以暴露 Grafana：

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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

    1. 应用以下配置以暴露 Kiali：

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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

    1. 应用以下配置以暴露 Prometheus：

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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

    1. 应用以下配置以暴露跟踪服务：

        {{< text bash >}}
        $ cat <<EOF | kubectl apply -f -
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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
        apiVersion: networking.istio.io/v1alpha3
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

1. 通过浏览器访问这些遥测插件。

    * Kiali：`http://kiali.${INGRESS_DOMAIN}`
    * Prometheus：`http://prometheus.${INGRESS_DOMAIN}`
    * Grafana：`http://grafana.${INGRESS_DOMAIN}`
    * Tracing：`http://tracing.${INGRESS_DOMAIN}`

## 清理 {#cleanup}

* 移除所有相关的 Gateway：

    {{< text bash >}}
    $ kubectl -n istio-system delete gateway grafana-gateway kiali-gateway prometheus-gateway tracing-gateway
    gateway.networking.istio.io "grafana-gateway" deleted
    gateway.networking.istio.io "kiali-gateway" deleted
    gateway.networking.istio.io "prometheus-gateway" deleted
    gateway.networking.istio.io "tracing-gateway" deleted
    {{< /text >}}

* 移除所有相关的 Virtual Service：

    {{< text bash >}}
    $ kubectl -n istio-system delete virtualservice grafana-vs kiali-vs prometheus-vs tracing-vs
    virtualservice.networking.istio.io "grafana-vs" deleted
    virtualservice.networking.istio.io "kiali-vs" deleted
    virtualservice.networking.istio.io "prometheus-vs" deleted
    virtualservice.networking.istio.io "tracing-vs" deleted
    {{< /text >}}

* 移除所有相关的 Destination Rule：

    {{< text bash >}}
    $ kubectl -n istio-system delete destinationrule grafana kiali prometheus tracing
    destinationrule.networking.istio.io "grafana" deleted
    destinationrule.networking.istio.io "kiali" deleted
    destinationrule.networking.istio.io "prometheus" deleted
    destinationrule.networking.istio.io "tracing" deleted
    {{< /text >}}
