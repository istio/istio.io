---
title: 远程访问遥测插件
description: 此任务向您展示如何配置从外部访问 Istio 遥测插件。
weight: 99
keywords: [telemetry,gateway,jaeger,zipkin,tracing,kiali,prometheus,addons]
aliases:
 - /zh/docs/tasks/telemetry/gateways/
owner: istio/wg-policies-and-telemetry-maintainers
test: yes
---

此任务说明如何配置 Istio 以显示和访问集群外部的遥测插件。

## 配置远程访问{#configuring-remote-access}

远程访问遥测插件的方式有很多种。
该任务涵盖了两种基本访问方式：安全的（通过 HTTPS）和不安全的（通过 HTTP）。
对于任何生产或敏感环境，*强烈建议* 通过安全方式访问。
不安全访问易于设置，但是无法保护在集群外传输的任何凭据或数据。

### 方式 1：安全访问（HTTPS）{#option-one-secure-access-HTTPS}

安全访问需要一个服务器证书。按照这些步骤来为您的域名安装并配置服务器证书。

您也可以使用自签名证书。访问[配置使用 SDS 通过 HTTPS 访问的安全网关任务](/zh/docs/tasks/traffic-management/ingress/secure-ingress-sds/)以了解使用自签名证书访问集群内服务的详情。

{{< warning >}}
本方式 *只* 涵盖了传输层的安全。您还应该配置遥测插件，使其暴露在外部时需要身份验证。
{{< /warning >}}

1. [安装 cert-manager](https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html) 以自动管理证书。

1. [安装 Istio](/zh/docs/setup/install/istioctl) 到您的集群并启用 `cert-manager` 标志且配置 `istio-ingressgateway` 使用 [Secret Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#sds-configuration)。

    要安装相应的 Istio，使用下列安装选项：

    * `--set values.gateways.enabled=true`
    * `--set values.gateways.istio-ingressgateway.enabled=true`
    * `--set values.gateways.istio-ingressgateway.sds.enabled=true`

    要额外安装遥测插件，使用下列安装选项：

    * Grafana: `--set values.grafana.enabled=true`
    * Kiali: `--set values.kiali.enabled=true`
    * Prometheus: `--set values.prometheus.enabled=true`
    * Tracing: `--set values.tracing.enabled=true`

1. 为您的域名配置 DNS 记录。

    1. 获取 `istio-ingressgateway` 的外部 IP 地址。

        {{< text bash >}}
        $ kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
        <IP ADDRESS OF CLUSTER INGRESS>
        {{< /text >}}

    1. 设置环境变量保存目标域名：

        {{< text bash >}}
        $ TELEMETRY_DOMAIN=<your.desired.domain>
        {{< /text >}}

    1. 通过您的域名提供商将所需的域名指向该外部 IP 地址。

        实现此步骤的机制因提供商而异。以下是一些示例文档链接：

        * Bluehost: [DNS 管理增改删 DNS 条目](https://my.bluehost.com/hosting/help/559)
        * GoDaddy: [添加 A 记录](https://www.godaddy.com/help/add-an-a-record-19238)
        * Google Domains: [资源记录](https://support.google.com/domains/answer/3290350?hl=en)
        * Name.com: [添加 A 记录](https://www.name.com/support/articles/115004893508-Adding-an-A-record)

    1. 验证 DNS 记录无误。

        {{< text bash >}}
        $ dig +short $TELEMETRY_DOMAIN
        <IP ADDRESS OF CLUSTER INGRESS>
        {{< /text >}}

1. 生成服务器证书

    {{< text bash >}}
    $ cat <<EOF | kubectl apply -f -
    apiVersion: certmanager.k8s.io/v1alpha1
    kind: Certificate
    metadata:
      name: telemetry-gw-cert
      namespace: istio-system
    spec:
      secretName: telemetry-gw-cert
      issuerRef:
        name: letsencrypt
        kind: ClusterIssuer
      commonName: $TELEMETRY_DOMAIN
      dnsNames:
      - $TELEMETRY_DOMAIN
      acme:
        config:
        - http01:
            ingressClass: istio
          domains:
          - $TELEMETRY_DOMAIN
    ---
    EOF
    certificate.certmanager.k8s.io "telemetry-gw-cert" created
    {{< /text >}}

1. 等待服务器证书准备就绪。

    {{< text syntax="bash" expandlinks="false" >}}
    $ JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status}{end}{end}' && kubectl -n istio-system get certificates -o jsonpath="$JSONPATH"
    telemetry-gw-cert:Ready=True
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
              number: 15031
              name: https-grafana
              protocol: HTTPS
            tls:
              mode: SIMPLE
              serverCertificate: sds
              privateKey: sds
              credentialName: telemetry-gw-cert
            hosts:
            - "$TELEMETRY_DOMAIN"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: grafana-vs
          namespace: istio-system
        spec:
          hosts:
          - "$TELEMETRY_DOMAIN"
          gateways:
          - grafana-gateway
          http:
          - match:
            - port: 15031
            route:
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
        gateway.networking.istio.io "grafana-gateway" configured
        virtualservice.networking.istio.io "grafana-vs" configured
        destinationrule.networking.istio.io "grafana" configured
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
              number: 15029
              name: https-kiali
              protocol: HTTPS
            tls:
              mode: SIMPLE
              serverCertificate: sds
              privateKey: sds
              credentialName: telemetry-gw-cert
            hosts:
            - "$TELEMETRY_DOMAIN"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: kiali-vs
          namespace: istio-system
        spec:
          hosts:
          - "$TELEMETRY_DOMAIN"
          gateways:
          - kiali-gateway
          http:
          - match:
            - port: 15029
            route:
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
        gateway.networking.istio.io "kiali-gateway" configured
        virtualservice.networking.istio.io "kiali-vs" configured
        destinationrule.networking.istio.io "kiali" configured
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
              number: 15030
              name: https-prom
              protocol: HTTPS
            tls:
              mode: SIMPLE
              serverCertificate: sds
              privateKey: sds
              credentialName: telemetry-gw-cert
            hosts:
            - "$TELEMETRY_DOMAIN"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: prometheus-vs
          namespace: istio-system
        spec:
          hosts:
          - "$TELEMETRY_DOMAIN"
          gateways:
          - prometheus-gateway
          http:
          - match:
            - port: 15030
            route:
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
        gateway.networking.istio.io "prometheus-gateway" configured
        virtualservice.networking.istio.io "prometheus-vs" configured
        destinationrule.networking.istio.io "prometheus" configured
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
              number: 15032
              name: https-tracing
              protocol: HTTPS
            tls:
              mode: SIMPLE
              serverCertificate: sds
              privateKey: sds
              credentialName: telemetry-gw-cert
            hosts:
            - "$TELEMETRY_DOMAIN"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: tracing-vs
          namespace: istio-system
        spec:
          hosts:
          - "$TELEMETRY_DOMAIN"
          gateways:
          - tracing-gateway
          http:
          - match:
            - port: 15032
            route:
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
        gateway.networking.istio.io "tracing-gateway" configured
        virtualservice.networking.istio.io "tracing-vs" configured
        destinationrule.networking.istio.io "tracing" configured
        {{< /text >}}

1. 通过浏览器访问这些遥测插件。

    * Kiali: `https://$TELEMETRY_DOMAIN:15029/`
    * Prometheus: `https://$TELEMETRY_DOMAIN:15030/`
    * Grafana: `https://$TELEMETRY_DOMAIN:15031/`
    * Tracing: `https://$TELEMETRY_DOMAIN:15032/`

### 方式 2：不安全访问（HTTP）{#option-two-insecure-access-HTTP}

1. [安装 Istio](/zh/docs/setup/install/istioctl) 到您的集群并启用您所需要的遥测插件。

    要额外安装这些遥测插件，使用下列安装选项：

    * Grafana: `--set values.grafana.enabled=true`
    * Kiali: `--set values.kiali.enabled=true`
    * Prometheus: `--set values.prometheus.enabled=true`
    * Tracing: `--set values.tracing.enabled=true`

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
              number: 15031
              name: http-grafana
              protocol: HTTP
            hosts:
            - "*"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: grafana-vs
          namespace: istio-system
        spec:
          hosts:
          - "*"
          gateways:
          - grafana-gateway
          http:
          - match:
            - port: 15031
            route:
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
        gateway.networking.istio.io "grafana-gateway" configured
        virtualservice.networking.istio.io "grafana-vs" configured
        destinationrule.networking.istio.io "grafana" configured
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
              number: 15029
              name: http-kiali
              protocol: HTTP
            hosts:
            - "*"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: kiali-vs
          namespace: istio-system
        spec:
          hosts:
          - "*"
          gateways:
          - kiali-gateway
          http:
          - match:
            - port: 15029
            route:
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
        gateway.networking.istio.io "kiali-gateway" configured
        virtualservice.networking.istio.io "kiali-vs" configured
        destinationrule.networking.istio.io "kiali" configured
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
              number: 15030
              name: http-prom
              protocol: HTTP
            hosts:
            - "*"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: prometheus-vs
          namespace: istio-system
        spec:
          hosts:
          - "*"
          gateways:
          - prometheus-gateway
          http:
          - match:
            - port: 15030
            route:
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
        gateway.networking.istio.io "prometheus-gateway" configured
        virtualservice.networking.istio.io "prometheus-vs" configured
        destinationrule.networking.istio.io "prometheus" configured
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
              number: 15032
              name: http-tracing
              protocol: HTTP
            hosts:
            - "*"
        ---
        apiVersion: networking.istio.io/v1alpha3
        kind: VirtualService
        metadata:
          name: tracing-vs
          namespace: istio-system
        spec:
          hosts:
          - "*"
          gateways:
          - tracing-gateway
          http:
          - match:
            - port: 15032
            route:
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
        gateway.networking.istio.io "tracing-gateway" configured
        virtualservice.networking.istio.io "tracing-vs" configured
        destinationrule.networking.istio.io "tracing" configured
        {{< /text >}}

1. 通过浏览器访问这些遥测插件。

    * Kiali: `http://<IP ADDRESS OF CLUSTER INGRESS>:15029/`
    * Prometheus: `http://<IP ADDRESS OF CLUSTER INGRESS>:15030/`
    * Grafana: `http://<IP ADDRESS OF CLUSTER INGRESS>:15031/`
    * Tracing: `http://<IP ADDRESS OF CLUSTER INGRESS>:15032/`

## 清除{#cleanup}

* 移除所有相关的网关：

    {{< text bash >}}
    $ kubectl -n istio-system delete gateway grafana-gateway kiali-gateway prometheus-gateway tracing-gateway
    gateway.networking.istio.io "grafana-gateway" deleted
    gateway.networking.istio.io "kiali-gateway" deleted
    gateway.networking.istio.io "prometheus-gateway" deleted
    gateway.networking.istio.io "tracing-gateway" deleted
    {{< /text >}}

* 移除所有相关的 Virtual Services：

    {{< text bash >}}
    $ kubectl -n istio-system delete virtualservice grafana-vs kiali-vs prometheus-vs tracing-vs
    virtualservice.networking.istio.io "grafana-vs" deleted
    virtualservice.networking.istio.io "kiali-vs" deleted
    virtualservice.networking.istio.io "prometheus-vs" deleted
    virtualservice.networking.istio.io "tracing-vs" deleted
    {{< /text >}}

* 如果安装了网关证书，移除它：

    {{< text bash >}}
    $ kubectl -n istio-system delete certificate telemetry-gw-cert
    certificate.certmanager.k8s.io "telemetry-gw-cert" deleted
    {{< /text >}}
