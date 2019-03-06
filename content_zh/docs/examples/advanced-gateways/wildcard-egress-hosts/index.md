---
title: 使用通配符主机配置 Egress 流量
description: 介绍如何为公共域中的一组主机启用 Egress 流量，而不是单独配置每个主机。
keywords: [traffic-management,egress]
weight: 50
---

[控制 Egress 流量](/zh/docs/tasks/traffic-management/egress/)任务和[配置 Egress Gateway](/zh/docs/examples/advanced-gateways/egress-gateway/) 示例讲述了如何为类似 `edition.cnn.com` 的特定主机名配置
egress 流量。此示例演示了如何为一组处于公共域（如 `*.wikipedia.org`）的主机启用 egress 流量，而非单独配置每个主机。

## 背景

假设您希望在 Istio 中为 `wikipedia.org` 网站的所有语言版本启用 egress 流量。每个特定语言版本的 `wikipedia.org`
都有自己的主机名，例如 `en.wikipedia.org` 和 `de.wikipedia.org` 分别对应英文和德文。
您希望通过通用配置项对所有 `wikipedia` 网站启用 egress 流量，而无需单独配置每个语言的站点。

## 开始之前

* 按照[安装指南](/zh/docs/setup/)中的说明安装 Istio。

* 启动 [sleep]({{< github_tree >}}/samples/sleep) 示例，它将被用作外部请求的测试源。

  如果您启用了[自动 sidecar 注入](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/#sidecar-的自动注入)，请运行

{{< text bash >}}
$ kubectl apply -f @samples/sleep/sleep.yaml@
{{< /text >}}

  否则，您需要在部署 `sleep` 应用之前手动注入 sidecar：

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
{{< /text >}}

  请注意，任何您能够 `exec` 和 `curl` 的 pod 都可以作为示例。

* 创建一个 shell 变量来保存源 pod 的名称，以便将请求发送到外部服务。如果您使用 [sleep]({{<github_tree>}}/samples/sleep) 示例，请运行：

{{< text bash >}}
$ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
{{< /text >}}

## 配置到通配符主机的直接流量

访问公共域中的一组主机的第一步（也是最简单的一步）是使用通配符主机配置一个简单的 `ServiceEntry`，并从 sidecar 直接请求 service。
当直接请求 service（意即不通过 egress gateway）时，通配符主机的配置和其余主机（例如全限定的）配置并没有什么不同，只是在公共域中有许多主机时会更方便。

1. 为 `*.wikipedia.org` 定义一个 `ServiceEntry` 和对应的 `VirtualSevice`：

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

1. 发送请求到 [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

### 清理到通配符主机的直接流量

{{< text bash >}}
$ kubectl delete serviceentry wikipedia
$ kubectl delete virtualservice wikipedia
{{< /text >}}

## 配置到通配符主机的 egress gateway

通过 egress gateway 访问通配符主机的配置取决于通配符域名集合和是否由单个公共主机提供。`*.wikipedia.org` 的情况就是如此。所有特定语言的网站都由 `wikipedia.org` 服务器之一提供服务。您可以将流量路由到任意 `*.wikipedia.org` 网站的 IP，包括 `www.wikipedia.org`，然后它将设法为任意特定网站提供服务。

在通常情况下，单个托管服务器并没有提供一个通配符域下的所有域名，此时就需要一个更复杂的配置。

### 针对单个托管服务器的通配符配置

当所有通配符主机都由单个服务器提供服务时，基于 egress gateway 到一个通配符主机的配置和到任意主机的配置非常相似，除了一个例外：配置后的路由目的地址将与配置的主机（通配符）不同。它将使用域名集合的单一服务器主机进行配置。

1. 为 `*.wikipedia.org` 创建一个 egress `Gateway`、一个 destination rule 和一 个 virtual service，以将流量定向到 egress gateway，并从 egress gateway 发送到外部 service。

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

1. 为目的服务器创建一个 `ServiceEntry`，即 `www.wikipedia.org`。

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

1. 发送请求到 [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1. 检查 egress gateway 代理的统计数据，找到对应于到 `*.wikipedia.org` 的请求的 counter。如果 Istio 部署在 `istio-system`
   namespace 中，打印 counter 的命令为：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep www.wikipedia.org.upstream_cx_total
    cluster.outbound|443||www.wikipedia.org.upstream_cx_total: 2
    {{< /text >}}

#### 清理单个托管服务器的通配符配置

{{< text bash >}}
$ kubectl delete serviceentry www-wikipedia
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-wikipedia
{{< /text >}}

### 任意域名的通配符配置

上一节中的配置之所以有效，是因为所有 `*.wikipedia.org` 网站都可以由任何一个 `*.wikipedia.org` 服务器提供服务。然而并非总是如此。
例如，您可能希望配置 egress 控制以访问更一般的通配符域名，如 `*.com` 或者 `*.org`。

配置到任意通配符域名的流量为 Istio gateway 带来了挑战。 在上一节中，您将流量定向到 `www.wikipedia.org`，并且在配置期间，您的 gateway
知道此主机。但是，gateway 无法知道它收到请求的任意主机的 IP 地址。这是由于 [Envoy](https://www.envoyproxy.io) 的限制，默认 Istio
egress gateway 使用它作为代理。Envoy 将流量路由到预定义的主机、预定义的 IP 地址或请求的原始目标 IP 地址。在 gateway 的情况下，请求的原始目的 IP
将会丢失，因为请求会首先路由到 egress gateway，故其目标 IP 地址为 gateway 的 IP 地址。

因此，基于 Envoy 的 Istio gateway 无法将流量路由到未预先配置的任意主机，也就无法对任意通配符域名执行流量控制。要为 HTTPS 和任何 TLS 启用此类流量控制，
除了 Envoy 之外，还需要部署 SNI 转发代理。Envoy 会将发往通配符域名的请求路由到 SNI 转发代理，而 SNI 转发代理将转发请求到 SNI 值指定的目的地。

具有 SNI 代理的 egress gateway 和 Istio 体系结构的相关部分如下图所示：

{{< image width="80%" link="./EgressGatewayWithSNIProxy.svg" caption="具有 SNI proxy 的 Egress Gateway" >}}

以下部分介绍如何使用 SNI 代理重新部署 egress gateway，然后配置 Istio 通过 gateway 将 HTTPS 流量路由到任意通配符域名。

#### 使用 SNI 代理配置 egress gateway

在本节中，您部署的 egress gateway 在标准的 Istio Envoy 代理之外，还会部署一个 SNI 代理。此示例使用 [Nginx](http://nginx.org) 作为 SNI
代理，但是，任何能够根据任意的、非提前配置的 SNI 值路由流量的 SNI 代理都可以使用。SNI 代理将会监听 `8443` 端口，您也可以使用任何端口，但需与指定给
egress `Gateway` 的和 `VirtualServices` 绑定的端口不同。
SNI 代理会将流量转发到 `443` 端口。

1. 为 Nginx SNI 代理创建一个配置文件。当需要时，您可能希望编辑该文件指定附加的 Nginx 配置。请注意，`server` 的 `listen` 指令指定端口 `8443`，
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

1. 创建一个 Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) 来保存
   Nginx SNI 的配置：

    {{< text bash >}}
    $ kubectl create configmap egress-sni-proxy-configmap -n istio-system --from-file=nginx.conf=./sni-proxy.conf
    {{< /text >}}

1. 以下命令将生成 `istio-egressgateway-with-sni-proxy.yaml` 文件，您可以选择性编辑并部署。

    {{< text bash >}}
    $ cat <<EOF | helm template install/kubernetes/helm/istio/ --name istio-egressgateway-with-sni-proxy --namespace istio-system -x charts/gateways/templates/deployment.yaml -x charts/gateways/templates/service.yaml -x charts/gateways/templates/serviceaccount.yaml -x charts/gateways/templates/autoscale.yaml -x charts/gateways/templates/clusterrole.yaml -x charts/gateways/templates/clusterrolebindings.yaml --set global.istioNamespace=istio-system -f - > ./istio-egressgateway-with-sni-proxy.yaml
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

1. 部署新的 egress gateway：

    {{< text bash >}}
    $ kubectl apply -f ./istio-egressgateway-with-sni-proxy.yaml
    serviceaccount "istio-egressgateway-with-sni-proxy-service-account" created
    clusterrole "istio-egressgateway-with-sni-proxy-istio-system" created
    clusterrolebinding "istio-egressgateway-with-sni-proxy-istio-system" created
    service "istio-egressgateway-with-sni-proxy" created
    deployment "istio-egressgateway-with-sni-proxy" created
    horizontalpodautoscaler "istio-egressgateway-with-sni-proxy" created
    {{< /text >}}

1. 验证新的 egress gateway 工作正常。请注意，pod 包含两个容器（一个是 Envoy 代理，另一个是 SNI 代理）。

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system
    NAME                                                  READY     STATUS    RESTARTS   AGE
    istio-egressgateway-with-sni-proxy-79f6744569-pf9t2   2/2       Running   0          17s
    {{< /text >}}

1. 创建一个 service entry，指定静态地址为 127.0.0.1 （`localhost`），并对定向到新 service entry 的流量禁用双向 TLS。

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

#### 通过具有 SNI 代理的 egress gateway 配置流量

1. 为 `*.wikipedia.org` 定义一个 `ServiceEntry`：

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

1. 为 `*.wikipedia.org` 创建一个 egress `Gateway`，端口为 443，协议为 TLS，并创建一个 virtual service 以将目的为 `*.wikipedia.org`
   的流量定向到 gateway。

    {{< text bash >}}
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
    {{< /text >}}

1. 发送 HTTPS 请求到 [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1. 检查 egress gateway 代理的统计数据，找到对应于到 `*.wikipedia.org` 的请求的 counter（到 SNI 代理流量的 counter）。如果 Istio 部署在 `istio-system` namespace 中，打印 counter 的命令为：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep sni-proxy.local.upstream_cx_total
    cluster.outbound|8443||sni-proxy.local.upstream_cx_total: 2
    {{< /text >}}

1. 检查 SNI 代理的日志。如果 Istio 部署在 `istio-system` namespace 中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway-with-sni-proxy -n istio-system -c sni-proxy
    127.0.0.1 [01/Aug/2018:15:32:02 +0000] TCP [en.wikipedia.org]200 81513 280 0.600
    127.0.0.1 [01/Aug/2018:15:32:03 +0000] TCP [de.wikipedia.org]200 67745 291 0.659
    {{< /text >}}

1. 检查 mixer 日志。如果 Istio 部署在 `istio-system` namespace 中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep '"connectionEvent":"open"' | grep '"sourceName":"istio-egressgateway' | grep 'wikipedia.org'; done
    {"level":"info","time":"2018-08-26T16:16:34.784571Z","instance":"tcpaccesslog.logentry.istio-system","connectionDuration":"0s","connectionEvent":"open","connection_security_policy":"unknown","destinationApp":"","destinationIp":"127.0.0.1","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"cluster.local/ns/istio-system/sa/istio-egressgateway-with-sni-proxy-service-account","destinationServiceHost":"","destinationWorkload":"unknown","protocol":"tcp","receivedBytes":298,"reporter":"source","requestedServerName":"placeholder.wikipedia.org","sentBytes":0,"sourceApp":"istio-egressgateway-with-sni-proxy","sourceIp":"172.30.146.88","sourceName":"istio-egressgateway-with-sni-proxy-7c4f7868fb-rc8pr","sourceNamespace":"istio-system","sourceOwner":"kubernetes://apis/extensions/v1beta1/namespaces/istio-system/deployments/istio-egressgateway-with-sni-proxy","sourcePrincipal":"cluster.local/ns/default/sa/default","sourceWorkload":"istio-egressgateway-with-sni-proxy","totalReceivedBytes":298,"totalSentBytes":0}
    {{< /text >}}

    注意 `requestedServerName` 属性。

#### SNI 监控和访问策略

现在，一旦通过一个 egress gateway 引导 egress 流量，您就可以在 egress 流量上**安全的**应用监控和访问策略。在本小节中，您将为到 `*.wikipedia.org`
的 egress 流量定义一个 log entry 和访问策略。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    # Log entry for egress access
    apiVersion: "config.istio.io/v1alpha2"
    kind: logentry
    metadata:
      name: egress-access
      namespace: istio-system
    spec:
      severity: '"info"'
      timestamp: context.time | timestamp("2017-01-01T00:00:00Z")
      variables:
        connectionEvent: connection.event | ""
        source: source.labels["app"] | "unknown"
        sourceNamespace: source.namespace | "unknown"
        sourceWorkload: source.workload.name | ""
        sourcePrincipal: source.principal | "unknown"
        requestedServerName: connection.requested_server_name | "unknown"
        destinationApp: destination.labels["app"] | ""
      monitored_resource_type: '"UNSPECIFIED"'
    ---
    # Handler for info egress access entries
    apiVersion: "config.istio.io/v1alpha2"
    kind: stdio
    metadata:
      name: egress-access-logger
      namespace: istio-system
    spec:
      severity_levels:
        info: 0 # output log level as info
      outputAsJson: true
    ---
    # Rule to handle access to *.wikipedia.org
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: handle-wikipedia-access
      namespace: istio-system
    spec:
      match: source.labels["app"] == "istio-egressgateway-with-sni-proxy" && destination.labels["app"] == "" && connection.event == "open"
      actions:
      - handler: egress-access-logger.stdio
        instances:
          - egress-access.logentry
    EOF
    {{< /text >}}

1. 发送 HTTPS 请求到 [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1. 检查 mixer 日志。如果 Istio 部署在 `istio-system` namespace 中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'egress-access.logentry.istio-system'; done
    {{< /text >}}

1. 定义一个策略，允许访问除英文版 Wikipedia 之外匹配 `*.wikipedia.org` 的主机名：

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: "config.istio.io/v1alpha2"
    kind: listchecker
    metadata:
      name: wikipedia-checker
      namespace: istio-system
    spec:
      overrides: ["en.wikipedia.org"]  # overrides 提供一个静态列表
      blacklist: true
    ---
    apiVersion: "config.istio.io/v1alpha2"
    kind: listentry
    metadata:
      name: requested-server-name
      namespace: istio-system
    spec:
      value: connection.requested_server_name
    ---
    # Rule to check access to *.wikipedia.org
    apiVersion: "config.istio.io/v1alpha2"
    kind: rule
    metadata:
      name: check-wikipedia-access
      namespace: istio-system
    spec:
      match: source.labels["app"] == "istio-egressgateway-with-sni-proxy" && destination.labels["app"] == ""
      actions:
      - handler: wikipedia-checker.listchecker
        instances:
          - requested-server-name.listentry
    EOF
    {{< /text >}}

1. 发送一个 HTTPS 请求到被纳入黑名单的 [https://en.wikipedia.org](https://en.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -v https://en.wikipedia.org/wiki/Main_Page'
    ...
    curl: (35) Unknown SSL protocol error in connection to en.wikipedia.org:443
    command terminated with exit code 35
    {{< /text >}}

1. 发送 HTTPS 请求到其余网站，例如 [https://es.wikipedia.org](https://es.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, la enciclopedia libre</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

##### 清理监控和策略

{{< text bash >}}
$ kubectl delete rule handle-wikipedia-access check-wikipedia-access -n istio-system
$ kubectl delete logentry egress-access -n istio-system
$ kubectl delete stdio egress-access-logger -n istio-system
$ kubectl delete listentry requested-server-name -n istio-system
$ kubectl delete listchecker wikipedia-checker -n istio-system
{{< /text >}}

#### 清理任意域名的通配符配置

1. 删除 `*.wikipedia.org` 的配置项：

    {{< text bash >}}
    $ kubectl delete serviceentry wikipedia
    $ kubectl delete gateway istio-egressgateway-with-sni-proxy
    $ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
    $ kubectl delete destinationrule egressgateway-for-wikipedia
    {{< /text >}}

1. 删除 `egressgateway-with-sni-proxy` `Deployment` 的配置项：

    {{< text bash >}}
    $ kubectl delete serviceentry sni-proxy
    $ kubectl delete destinationrule disable-mtls-for-sni-proxy
    $ kubectl delete -f ./istio-egressgateway-with-sni-proxy.yaml
    $ kubectl delete configmap egress-sni-proxy-configmap -n istio-system
    {{< /text >}}

1. 删除您创建的配置文件：

    {{< text bash >}}
    $ rm ./istio-egressgateway-with-sni-proxy.yaml
    $ rm ./sni-proxy.conf
    {{< /text >}}

## 清理

关闭 [sleep]({{<github_tree>}}/samples/sleep) service：

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}
