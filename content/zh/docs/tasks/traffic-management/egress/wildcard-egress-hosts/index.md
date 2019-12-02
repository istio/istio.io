---
title: 使用通配符主机配置 Egress 流量
description: 介绍如何为公共域中的一组主机启用 Egress 流量，而不是单独配置每个主机。
keywords: [traffic-management,egress]
weight: 50
aliases:
  - /zh/docs/examples/advanced-gateways/wildcard-egress-hosts/
---

[控制 Egress 流量](/zh/docs/tasks/traffic-management/egress/)任务和[配置 Egress Gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/) 示例示例讲述了如何为类似 `edition.cnn.com` 的特定主机名配置 egress 流量。此示例演示了如何为一组处于公共域（如 `*.wikipedia.org`）的主机启用 egress 流量，而非单独配置每个主机。

## 背景{#background}

假设您希望在 Istio 中为 `wikipedia.org` 网站的所有语言版本启用 egress 流量。每个特定语言版本的 `wikipedia.org`
都有自己的主机名，例如 `en.wikipedia.org` 和 `de.wikipedia.org` 分别对应英文和德文。
您希望通过通用配置项对所有 `wikipedia` 网站启用 egress 流量，而无需单独配置每个语言的站点。

{{< boilerplate before-you-begin-egress >}}

*   [部署 Istio egress gateway](/zh/docs/tasks/traffic-management/egress/egress-gateway/#deploy-Istio-egress-gateway)。

*   [开启 Envoy 访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

## 配置到通配符主机的直接流量{#configure-direct-traffic-to-a-wildcard-host}

访问公共域中的一组主机的第一种也是最简单的方法是通过配置一个简单的带有通配符主机的 `ServiceEntry`，并直接从 sidecar 调用服务。直接调用服务（即不通过 egress gateway）时，通配符主机与任何其他（例如，全限定的）主机都没有区别，只有当公共域中有许多主机时，此功能才会更加方便。

1.  为`*.wikipedia.org`配置 `ServiceEntry` 和相应的 `VirtualSevice`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      ports:
      - number: 443
        name: tls
        protocol: TLS
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      tls:
      - match:
        - port: 443
          sni_hosts:
          - "*.wikipedia.org"
        route:
        - destination:
            host: "*.wikipedia.org"
            port:
              number: 443
    EOF
    {{< /text >}}

1.  向
    [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org) 发送 HTTP 请求：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

### 清理到通配符主机的直接流量{#cleanup-direct-traffic-to-a-wildcard-host}

{{< text bash >}}
$ kubectl delete serviceentry wikipedia
$ kubectl delete virtualservice wikipedia
{{< /text >}}

## 配置到通配符主机的 egress gateway 流量{#configure-egress-gateway-traffic-to-a-wildcard-host}

通过出口网关访问通配符主机的配置取决于是否为一组通配符域由单个公共主机提供服务。
通过 egress gateway 访问通配符主机的配置取决于通配符域名集合和是否由单个公共主机提供。
这是 _*.wikipedia.org_ 的情况。所有特定语言的网站都由 _wikipedia.org_ 服务器之一提供服务。您可以将流量路由到任意 _*.wikipedia.org_ 网站的 IP，包括 _www.wikipedia.org_，然后它将为任意特定网站[提供服务](https://en.wikipedia.org/wiki/Virtual_hosting)。

在一般情况下，单个主机服务器无法提供通配符的所有域名，
需要更复杂的配置。

### 单个托管服务器的通配符配置{#wildcard-configuration-for-a-single-hosting-server}

当所有通配符主机都由单个服务器提供服务时，基于 egress gateway 到一个通配符主机的配置和到任意主机的配置非常相似，除了一个例外：配置后的路由目的地址将与配置的主机（通配符）不同。它将使用域名集合的单一服务器主机进行配置。

1.   为 _*.wikipedia.org_ 创建一个 egress `Gateway`、一个 destination rule 和一 个 virtual service，以将流量定向到 egress gateway，并从 egress gateway 发送到外部 service。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
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
        - "*.wikipedia.org"
        tls:
          mode: PASSTHROUGH
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-wikipedia
    spec:
      host: istio-egressgateway.istio-system.svc.cluster.local
      subsets:
        - name: wikipedia
    ---
    apiVersion: networking.istio.io/v1alpha3
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
          sni_hosts:
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
          sni_hosts:
          - "*.wikipedia.org"
        route:
        - destination:
            host: www.wikipedia.org
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  为目标服务创建 `ServiceEntry`，即 _www.wikipedia.org_。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: www-wikipedia
    spec:
      hosts:
      - www.wikipedia.org
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
    EOF
    {{< /text >}}

1.  发送 HTTP 请求到
    [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  检查 egress gateway 代理的统计数据，找到对应于到 _*.wikipedia.org_ 的请求的 counter。如果 Istio 部署在 `istio-system`
   namespace 中，打印 counter 的命令为：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- pilot-agent request GET clusters | grep '^outbound|443||www.wikipedia.org.*cx_total:'
    outbound|443||www.wikipedia.org::208.80.154.224:443::cx_total::2
    {{< /text >}}

#### 清理单个托管服务器的通配符配置{#cleanup-wildcard-configuration-for-a-single-hosting-server}

{{< text bash >}}
$ kubectl delete serviceentry www-wikipedia
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-wikipedia
{{< /text >}}

### 任意域名的通配符配置{#wildcard-configuration-for-arbitrary-domains}

上一节中的配置之所以有效，是因为所有 _*.wikipedia.org_ 网站都可以由任何一个 _*.wikipedia.org_ 服务器提供服务。然而并非总是如此。
例如，您可能希望配置 egress 控制以访问更一般的通配符域名，如 `*.com` 或者 `*.org`。

配置到任意通配符域名的流量为 Istio gateway 带来了挑战。在上一节中，您将流量定向到 _www.wikipedia.org_，并且在配置期间，您的 gateway 知道此主机。但是，gateway 无法知道它收到请求的任意主机的 IP 地址。这是由于 [Envoy](https://www.envoyproxy.io) 的限制，默认 Istio egress gateway 使用它作为代理。
Envoy 将流量路由到预定义的主机、预定义的 IP 地址或请求的原始目标 IP 地址。在 gateway 的情况下，请求的原始目的 IP 将会丢失，因为请求会首先路由到 egress gateway，故其目标 IP 地址为 gateway 的 IP 地址。

因此，基于 Envoy 的 Istio gateway 无法将流量路由到未预先配置的任意主机，也就无法对任意通配符域名执行流量控制。要为 HTTPS 和任何 TLS 启用此类流量控制，
除了 Envoy 之外，还需要部署 SNI 转发代理。Envoy 会将发往通配符域名的请求路由到 SNI 转发代理，而 SNI 转发代理将转发请求到 SNI 值指定的目的地。

具有 SNI 代理的 egress gateway 和 Istio 体系结构的相关部分如下图所示：

{{< image width="80%" link="./EgressGatewayWithSNIProxy.svg" caption="Egress Gateway with SNI proxy" >}}

以下部分介绍如何使用 SNI 代理重新部署 egress gateway，然后配置 Istio 通过 gateway 将 HTTPS 流量路由到任意通配符域名。

#### 使用 SNI 代理配置 egress gateway{#setup-egress-gateway-with-server-name-indication-proxy}

在本节中，您部署的 egress gateway 在标准的 Istio Envoy 代理之外，还会部署一个 SNI 代理。此示例使用 [Nginx](http://nginx.org) 作为 SNI
代理，但是，任何能够根据任意的、非提前配置的 SNI 值路由流量的 SNI 代理都可以使用。SNI 代理将会监听 `8443` 端口，您也可以使用任何端口，但需与指定给
egress `Gateway` 的和 `VirtualServices` 绑定的端口不同。
SNI 代理会将流量转发到 `443` 端口。

1.  为 Nginx SNI 代理创建一个配置文件。当需要时，您可能希望编辑该文件指定附加的 Nginx 配置。请注意，`server` 的 `listen` 指令指定端口 `8443`，
   其 `proxy_pass` 指令使用 `ssl_preread_server_name` 和 `443` 端口及 `ssl_preread` 为 `on` 来启用 `SNI` 读取。

    {{< text bash >}}
    $ cat <<EOF > ./sni-proxy.conf
    user www-data;

    events {
    }

    stream {
      log_format log_stream '\$remote_addr [\$time_local] \$protocol [\$ssl_preread_server_name]'
      '\$status \$bytes_sent \$bytes_received \$session_time';

      access_log /var/log/nginx/access.log log_stream;
      error_log  /var/log/nginx/error.log;

      # tcp forward proxy by SNI
      server {
        resolver 8.8.8.8 ipv6=off;
        listen       127.0.0.1:8443;
        proxy_pass   \$ssl_preread_server_name:443;
        ssl_preread  on;
      }
    }
    EOF
    {{< /text >}}

1.  创建一个 Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
    来保存 Nginx SNI 的配置：

    {{< text bash >}}
    $ kubectl create configmap egress-sni-proxy-configmap -n istio-system --from-file=nginx.conf=./sni-proxy.conf
    {{< /text >}}

1.  以下命令将生成 `istio-egressgateway-with-sni-proxy.yaml` 文件，您可以选择性编辑并部署。

    {{< text bash >}}
    $ cat <<EOF | istioctl manifest generate --set values.global.istioNamespace=istio-system -f - > ./istio-egressgateway-with-sni-proxy.yaml
    gateways:
      enabled: true
      istio-ingressgateway:
        enabled: false
      istio-egressgateway:
        enabled: false
      istio-egressgateway-with-sni-proxy:
        enabled: true
        labels:
          app: istio-egressgateway-with-sni-proxy
          istio: egressgateway-with-sni-proxy
        replicaCount: 1
        autoscaleMin: 1
        autoscaleMax: 5
        cpu:
          targetAverageUtilization: 80
        serviceAnnotations: {}
        type: ClusterIP
        ports:
          - port: 443
            name: https
        secretVolumes:
          - name: egressgateway-certs
            secretName: istio-egressgateway-certs
            mountPath: /etc/istio/egressgateway-certs
          - name: egressgateway-ca-certs
            secretName: istio-egressgateway-ca-certs
            mountPath: /etc/istio/egressgateway-ca-certs
        configVolumes:
          - name: sni-proxy-config
            configMapName: egress-sni-proxy-configmap
        additionalContainers:
        - name: sni-proxy
          image: nginx
          volumeMounts:
          - name: sni-proxy-config
            mountPath: /etc/nginx
            readOnly: true
    EOF
    {{< /text >}}

1.  部署新的 egress gateway：

    {{< text bash >}}
    $ kubectl apply -f ./istio-egressgateway-with-sni-proxy.yaml
    serviceaccount "istio-egressgateway-with-sni-proxy-service-account" created
    role "istio-egressgateway-with-sni-proxy-istio-system" created
    rolebinding "istio-egressgateway-with-sni-proxy-istio-system" created
    service "istio-egressgateway-with-sni-proxy" created
    deployment "istio-egressgateway-with-sni-proxy" created
    horizontalpodautoscaler "istio-egressgateway-with-sni-proxy" created
    {{< /text >}}

1.  验证新的 egress gateway 工作正常。请注意，pod 包含两个容器（一个是 Envoy 代理，另一个是 SNI 代理）。

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system
    NAME                                                  READY     STATUS    RESTARTS   AGE
    istio-egressgateway-with-sni-proxy-79f6744569-pf9t2   2/2       Running   0          17s
    {{< /text >}}

1.  创建一个 service entry，指定静态地址为 127.0.0.1（`localhost`），并对定向到新 service entry 的流量禁用双向 TLS

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: sni-proxy
    spec:
      hosts:
      - sni-proxy.local
      location: MESH_EXTERNAL
      ports:
      - number: 8443
        name: tcp
        protocol: TCP
      resolution: STATIC
      endpoints:
      - address: 127.0.0.1
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: disable-mtls-for-sni-proxy
    spec:
      host: sni-proxy.local
      trafficPolicy:
        tls:
          mode: DISABLE
    EOF
    {{< /text >}}

#### 通过具有 SNI 代理的 egress gateway 配置流量{#configure-traffic-through-egress-gateway-with-server-name-indication-proxy}

1.  为 `*.wikipedia.org` 定义一个 `ServiceEntry`：

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: wikipedia
    spec:
      hosts:
      - "*.wikipedia.org"
      ports:
      - number: 443
        name: tls
        protocol: TLS
    EOF
    {{< /text >}}

1.   为 _*.wikipedia.org_ 创建一个端口 443，协议为 TLS 的 egress `Gateway`，和一个 virtual service 以将目的为 _*.wikipedia.org_ 的流量定向到 gateway。

    选择与您是否要在源 pod 和 egress gateway 之间启用[双向 TLS 认证](/zh/docs/tasks/security/authentication/mutual-tls/)的相应指示。

    {{< idea >}}
    您可能需要启用双向 TLS，以使 egress gateway 监视源 Pod 的身份，并基于该身份启用 Mixer 策略实施。
    {{< /idea >}}

    {{< tabset category-name="mtls" >}}

    {{< tab name="mutual TLS enabled" category-value="enabled" >}}

    {{< text_hack bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: istio-egressgateway-with-sni-proxy
    spec:
      selector:
        istio: egressgateway-with-sni-proxy
      servers:
      - port:
          number: 443
          name: tls-egress
          protocol: TLS
        hosts:
        - "*.wikipedia.org"
        tls:
          mode: MUTUAL
          serverCertificate: /etc/certs/cert-chain.pem
          privateKey: /etc/certs/key.pem
          caCertificates: /etc/certs/root-cert.pem
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: egressgateway-for-wikipedia
    spec:
      host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
      subsets:
        - name: wikipedia
          trafficPolicy:
            loadBalancer:
              simple: ROUND_ROBIN
            portLevelSettings:
            - port:
                number: 443
              tls:
                mode: ISTIO_MUTUAL
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: direct-wikipedia-through-egress-gateway
    spec:
      hosts:
      - "*.wikipedia.org"
      gateways:
      - mesh
      - istio-egressgateway-with-sni-proxy
      tls:
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - "*.wikipedia.org"
        route:
        - destination:
            host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
            subset: wikipedia
            port:
              number: 443
          weight: 100
      tcp:
      - match:
        - gateways:
          - istio-egressgateway-with-sni-proxy
          port: 443
        route:
        - destination:
            host: sni-proxy.local
            port:
              number: 8443
          weight: 100
    ---
    # 以下过滤器用于转发原始 SNI（由应用程序发送）作为双向 TLS 连接的 SNI。
    # 转发的 SNI 将报告给 Mixer，以便根据原始 SNI 值实施策略。
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: forward-downstream-sni
    spec:
      filters:
      - listenerMatch:
          portNumber: 443
          listenerType: SIDECAR_OUTBOUND
        filterName: forward_downstream_sni
        filterType: NETWORK
        filterConfig: {}
    ---
    # 以下过滤器验证双向 TLS 连接的 SNI（报告给 Mixer 的 SNI）与应用程序发布的原始 SNI（用于 SNI Proxy 路由的 SNI）相同。该过滤器可防止 Mixer 被恶意应用程序欺骗：在报告其他 SNI 值的同时路由到一个 SNI。如果原始 SNI 与双向 TLS 连接的 SNI 不匹配，则过滤器将阻止与外部服务的连接。
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: egress-gateway-sni-verifier
    spec:
      workloadLabels:
        app: istio-egressgateway-with-sni-proxy
      filters:
      - listenerMatch:
          portNumber: 443
          listenerType: GATEWAY
        filterName: sni_verifier
        filterType: NETWORK
        filterConfig: {}
    EOF
    {{< /text_hack >}}

    {{< /tab >}}

    {{< tab name="mutual TLS disabled" category-value="disabled" >}}

    {{< text_hack bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
     name: istio-egressgateway-with-sni-proxy
    spec:
     selector:
       istio: egressgateway-with-sni-proxy
     servers:
     - port:
         number: 443
         name: tls
         protocol: TLS
       hosts:
       - "*.wikipedia.org"
       tls:
         mode: PASSTHROUGH
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
     name: egressgateway-for-wikipedia
    spec:
     host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
     subsets:
       - name: wikipedia
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
     name: direct-wikipedia-through-egress-gateway
    spec:
     hosts:
     - "*.wikipedia.org"
     gateways:
     - mesh
     - istio-egressgateway-with-sni-proxy
     tls:
     - match:
       - gateways:
         - mesh
         port: 443
         sni_hosts:
         - "*.wikipedia.org"
       route:
       - destination:
           host: istio-egressgateway-with-sni-proxy.istio-system.svc.cluster.local
           subset: wikipedia
           port:
             number: 443
         weight: 100
     - match:
       - gateways:
         - istio-egressgateway-with-sni-proxy
         port: 443
         sni_hosts:
         - "*.wikipedia.org"
       route:
       - destination:
           host: sni-proxy.local
           port:
             number: 8443
         weight: 100
    EOF
    {{< /text_hack >}}

    {{< /tab >}}

    {{< /tabset >}}

1.  发送 HTTPS 请求到
    [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1.  检查 egress gateway 的 Envoy proxy 的日志。如果 Istio 是被部署到  `istio-system` namespace 中，打印日志的命令是：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway-with-sni-proxy -c istio-proxy -n istio-system
    {{< /text >}}

    你会看到几行类似的日志：

    {{< text plain >}}
    [2019-01-02T16:34:23.312Z] "- - -" 0 - 578 79141 624 - "-" "-" "-" "-" "127.0.0.1:8443" outbound|8443||sni-proxy.local 127.0.0.1:55018 172.30.109.84:443 172.30.109.112:45346 en.wikipedia.org
    [2019-01-02T16:34:24.079Z] "- - -" 0 - 586 65770 638 - "-" "-" "-" "-" "127.0.0.1:8443" outbound|8443||sni-proxy.local 127.0.0.1:55034 172.30.109.84:443 172.30.109.112:45362 de.wikipedia.org
    {{< /text >}}

1.  检查 SNI 代理的日志。如果 Istio 部署在 `istio-system` namespace 中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway-with-sni-proxy -n istio-system -c sni-proxy
    127.0.0.1 [01/Aug/2018:15:32:02 +0000] TCP [en.wikipedia.org]200 81513 280 0.600
    127.0.0.1 [01/Aug/2018:15:32:03 +0000] TCP [de.wikipedia.org]200 67745 291 0.659
    {{< /text >}}

1.  检查 mixer 日志。如果 Istio 部署在 `istio-system` namespace 中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep '"connectionEvent":"open"' | grep '"sourceName":"istio-egressgateway' | grep 'wikipedia.org'
    {"level":"info","time":"2018-08-26T16:16:34.784571Z","instance":"tcpaccesslog.logentry.istio-system","connectionDuration":"0s","connectionEvent":"open","connection_security_policy":"unknown","destinationApp":"","destinationIp":"127.0.0.1","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"cluster.local/ns/istio-system/sa/istio-egressgateway-with-sni-proxy-service-account","destinationServiceHost":"","destinationWorkload":"unknown","protocol":"tcp","receivedBytes":298,"reporter":"source","requestedServerName":"en.wikipedia.org","sentBytes":0,"sourceApp":"istio-egressgateway-with-sni-proxy","sourceIp":"172.30.146.88","sourceName":"istio-egressgateway-with-sni-proxy-7c4f7868fb-rc8pr","sourceNamespace":"istio-system","sourceOwner":"kubernetes://apis/extensions/v1beta1/namespaces/istio-system/deployments/istio-egressgateway-with-sni-proxy","sourcePrincipal":"cluster.local/ns/sleep/sa/default","sourceWorkload":"istio-egressgateway-with-sni-proxy","totalReceivedBytes":298,"totalSentBytes":0}
    {{< /text >}}

    注意 `requestedServerName` 属性。

#### 清理任意域名的通配符配置{#cleanup-wildcard-configuration-for-arbitrary-domains}

1.  删除 _*.wikipedia.org_ 的配置项：

    {{< text bash >}}
    $ kubectl delete serviceentry wikipedia
    $ kubectl delete gateway istio-egressgateway-with-sni-proxy
    $ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
    $ kubectl delete destinationrule egressgateway-for-wikipedia
    $ kubectl delete --ignore-not-found=true envoyfilter forward-downstream-sni egress-gateway-sni-verifier
    {{< /text >}}

1.  删除 `egressgateway-with-sni-proxy` `Deployment` 的配置项：

    {{< text bash >}}
    $ kubectl delete serviceentry sni-proxy
    $ kubectl delete destinationrule disable-mtls-for-sni-proxy
    $ kubectl delete -f ./istio-egressgateway-with-sni-proxy.yaml
    $ kubectl delete configmap egress-sni-proxy-configmap -n istio-system
    {{< /text >}}

1.  删除您创建的配置文件：

    {{< text bash >}}
    $ rm ./istio-egressgateway-with-sni-proxy.yaml
    $ rm ./sni-proxy.conf
    {{< /text >}}

## 清理{#cleanup}

关闭 [sleep]({{<github_tree>}}/samples/sleep) service：

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
