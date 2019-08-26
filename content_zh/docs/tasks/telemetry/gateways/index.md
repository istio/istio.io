---
title: 遥测插件的远程访问
description: 本任务展示了为 Istio 遥测插件配置外部访问的过程。
weight: 99
keywords: [telemetry,gateway,jaeger,zipkin,tracing,kiali,prometheus,addons]
---

本任务展示了对 Istio 进行配置，用于对集群外部开放访问遥测插件的方法。

## 配置远程访问 {#configuring-remote-access}

有很多种为遥测插件配置远程访问的方式。本文谈到了两种访问方式：安全的（HTTPS）和非安全的（HTTP）。**强烈推荐**为敏感环境配置安全的访问方式。非安全方式的配置很简单，但是无法为传输到集群之外的凭据和数据进行加密。

### 选项 1：安全访问（HTTPS） {#option-1-https}

要进行安全访问，就需要有个服务证书。下面的步骤可以用来为你控制的域名进行证书的安装和配置。

也可以使用一个自签发的证书。浏览[使用 SDS 为 Gateway 提供 HTTPS 加密支持](/zh/docs/tasks/traffic-management/secure-ingress/sds/)的任务内容，其中包含了使用自签发证书来访问集群内服务的一些介绍。

{{< warning >}}
这一选项**仅包含**了对传输层的加密工作。要把服务进行公开，还应该为遥测插件配置认证功能。
{{< /warning >}}

1. 在集群中[安装 Istio](/zh/docs/setup/kubernetes)，并启用 `cert-manager`，配置 `istio-ingressgateway`，打开对 [Secret Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret#config-secret-discovery-service) 的支持。

    使用下面的 Helm 参数来完成 Istio 部署：

    * `--set gateways.enabled=true`
    * `--set gateways.istio-ingressgateway.enabled=true`
    * `--set gateways.istio-ingressgateway.sds.enabled=true`
    * `--set certmanager.enabled=true`
    * `--set certmanager.email=mailbox@donotuseexample.com`

    要启用遥测插件，需要如下的 Helm 参数：

    * Grafana: `--set grafana.enabled=true`
    * Kiali: `--set kiali.enabled=true`
    * Prometheus: `--set prometheus.enabled=true`
    * Tracing: `--set tracing.enabled=true`

1. 为你的域名配置 DNS 记录。

    1. 获取 `istio-ingressgateway` 的外部 IP 地址。

        {{< text bash >}}
        $ kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
        <IP ADDRESS OF CLUSTER INGRESS>
        {{< /text >}}

    1. 为目标域名设置一个环境变量。

        {{< text bash >}}
        $ TELEMETRY_DOMAIN=<your.desired.domain>
        {{< /text >}}

    1. 在域名提供商界面中，把域名映射到外部 IP 上。

        不同域名提供商的配置步骤会有不同，这里提供一些简单的文档连接：

        * Bluehost：[DNS Management Add Edit or Delete DNS Entries](https://my.bluehost.com/hosting/help/559)
        * GoDaddy：[Add an A record](https://www.godaddy.com/help/add-an-a-record-19238)
        * Google Domains：[Resource Records](https://support.google.com/domains/answer/3290350?hl=en)
        * Name.com：[Adding an A record](https://www.name.com/support/articles/115004893508-Adding-an-A-record)

    1. 检查域名是否成功映射：

        {{< text bash >}}
        $ dig +short $TELEMETRY_DOMAIN
        <IP ADDRESS OF CLUSTER INGRESS>
        {{< /text >}}

1. 生成服务端证书：

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

1. 等待服务证书准备就绪：

    {{< text syntax="bash" expandlinks="false" >}}
    $ JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status}{end}{end}' && kubectl -n istio-system get certificates -o jsonpath="$JSONPATH"
    telemetry-gw-cert:Ready=True
    {{< /text >}}

1. 为遥测插件提供网络配置：

    1. 用下列配置开放 Grafana 的访问：

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

    1. 用下列配置开放对 Kiali 的访问：

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

    1. 用下面的配置开放对 Prometheus 的访问：

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

    1. 用下面的配置开放对跟踪服务的访问：

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

1. 使用浏览器访问遥测插件：

    * Kiali：`https://$TELEMETRY_DOMAIN:15029/`
    * Prometheus：`https://$TELEMETRY_DOMAIN:15030/`
    * Grafana：`https://$TELEMETRY_DOMAIN:15031/`
    * Tracing：`https://$TELEMETRY_DOMAIN:15032/`

### 选项 2：不安全访问（HTTP）{#option-2-http}

1. 在集群中[安装 Istio](/zh/docs/setup/)，并启用需要的遥测插件。

    可以用下面的 Helm 参数启用遥测插件：
    * Grafana：`--set grafana.enabled=true`
    * Kiali：`--set kiali.enabled=true`
    * Prometheus：`--set prometheus.enabled=true`
    * Tracing：`--set tracing.enabled=true`

1. 为遥测插件创建网络配置。

    1. 用下面的配置开放对 Grafana 的访问：

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

    1. 用下面的配置开放对 Kiali 的访问：

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

    1. 用下面的配置开放对 Prometheus 的访问：

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

    1. 用下面的配置开放对跟踪服务的访问：

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

1. 使用浏览器访问遥测插件：

    * Kiali：`http://<IP ADDRESS OF CLUSTER INGRESS>:15029/`
    * Prometheus：`http://<IP ADDRESS OF CLUSTER INGRESS>:15030/`
    * Grafana：`http://<IP ADDRESS OF CLUSTER INGRESS>:15031/`
    * Tracing：`http://<IP ADDRESS OF CLUSTER INGRESS>:15032/`

## 清理 {#cleanup}

* 删除相关的 `Gateway`：

    {{< text bash >}}
    $ kubectl -n istio-system delete gateway grafana-gateway kiali-gateway prometheus-gateway tracing-gateway
    gateway.networking.istio.io "grafana-gateway" deleted
    gateway.networking.istio.io "kiali-gateway" deleted
    gateway.networking.istio.io "prometheus-gateway" deleted
    gateway.networking.istio.io "tracing-gateway" deleted
    {{< /text >}}

* 删除相关的 `VirtualService`：

    {{< text bash >}}
    $ kubectl -n istio-system delete virtualservice grafana-vs kiali-vs prometheus-vs tracing-vs
    virtualservice.networking.istio.io "grafana-vs" deleted
    virtualservice.networking.istio.io "kiali-vs" deleted
    virtualservice.networking.istio.io "prometheus-vs" deleted
    virtualservice.networking.istio.io "tracing-vs" deleted
    {{< /text >}}

* 如果使用了证书，也需要一并清理：

    {{< text bash >}}
    $ kubectl -n istio-system delete certificate telemetry-gw-cert
    certificate.certmanager.k8s.io "telemetry-gw-cert" deleted
    {{< /text >}}