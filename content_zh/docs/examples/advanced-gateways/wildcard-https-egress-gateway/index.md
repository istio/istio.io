---
title: 为通配符域名的 HTTPS 流量配置 Egress Gateway
description: 在通配符域名的 istio-egressgateway 中的 Envoy 实例之外，额外使用 SNI 代理。
keywords: [流量管理,egress]
weight: 50
---

[HTTPS 流量的 egress gateway](/docs/examples/advanced-gateways/egress-gateway/#egress-gateway-for-https-traffic) 一节中的[配置 Egress Gateway](/docs/examples/advanced-gateways/egress-gateway/) 示例描述了如何为特定主机名（如 `edition.cnn.com`）的 HTTPS 流量配置 Istio egress gateway。此示例说明如何为一组域的 HTTPS 流量启用 egress gateway（例如 `* .wikipedia.org`），而无需指定每个主机。

## 背景

假设您希望在 Istio 中为所有语言的 `wikipedia.org` 站点启用安全出口流量控制。`wikipedia.org` 的每个特定语言版本都有其对应的主机名，例如：`en.wikipedia.org` 和 `de.wikipedia.org` 分别对应英文和德文。您希望通过对所有 _wikipedia_ 站点进行通用配置来启用出口流量，而无需为所有语言指定站点。

## 开始之前

请按照[配置 Egress Gateway](/docs/examples/advanced-gateways/egress-gateway) 示例中[开始之前](/docs/examples/advanced-gateways/egress-gateway/#before-you-begin)小节中的步骤进行操作。

## 到单个主机的 HTTPS 流量

1. 定义一个用于 `*.wikipedia.org` 的 `ServiceEntry`：

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
    EOF
    {{< /text >}}

1. 验证正确应用了 `ServiceEntry`。发送 HTTPS 请求到 [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1. 为 `*.wikipedia.org` 创建一个 egress `Gateway`，端口为 443，协议为 TLS；创建一个 destination rule 来为该 gateway 设置 [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication)；还需创建一个 virtual service，用于将目的为 `*.wikipedia.org` 的流量引导到 gateway。

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
    EOF
    {{< /text >}}

1. 将发送到 `*.wikipedia.org` 的流量路由到 egress gateway，并从 egress gateway 路由到
  `www.wikipedia.org`。
   您可以使用这个技巧，因为所有 `*.wikipedia.org` 网站显然是由各自的 `wikipedia.org` 服务器提供服务。这意味着您可以将流量路由到任何 `*.wikipedia.org` 网站，特别是 `www.wikipedia.org`，然后该 IP 下的服务器将为任何 Wikipedia 网站[提供服务](https://en.wikipedia.org/wiki/Virtual_hosting)。
   对于一般情况，并不是所有主机都提供了 `ServiceEntry` 的所有域名，这就需要更复杂的配置。请注意，您必须为 `www.wikipedia.org` 创建一个带有 resolution `DNS` 的 `ServiceEntry`，以使 gateway 能够执行路由。

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

1. 发送 HTTPS 请求到
      [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1. 检查 egress gateway 代理的数据并找到请求 `*.wikipedia.org` 对应的 counter。如果 Istio 部署在 `istio-system` namespace 中，打印 counter 的命令为：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep www.wikipedia.org.upstream_cx_total
    cluster.outbound|443||www.wikipedia.org.upstream_cx_total: 2
    {{< /text >}}

### 清理单个主机的 HTTPS 流量配置

{{< text bash >}}
$ kubectl delete serviceentry wikipedia www-wikipedia
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-wikipedia
{{< /text >}}

## 到任意通配符域名的 HTTPS 流量

上一节中的配置可行，要归功于所有的 `*.wikipedia.org` 都由各自的 `wikipedia.org` 服务器提供服务。然而，情况可能并非总是如此。在许多情况下，
您可能想要为访问 `* .com` 或 `* .org` 域，甚至是 `*`（所有域）的 HTTPS 请求配置出口控制。

配置到任意通配符域名的流量对 Istio gateway 是一个挑战。在上一节中，您将流量转发到 `www.wikipedia.org`，并且在配置期间，您的 gateway 知道此主机。
但是，gateway 无法知道它收到请求的任意主机的 IP 地址。如果您想控制到 `*.com` 的访问和发送到 `www.cnn.com` 和 `www.abc.com` 的请求，Istio gateway
不会知道用哪个 IP 地址转发请求。
这种限制源于 [Envoy](https://www.envoyproxy.io) 的限制，而 Istio 基于此代理。Envoy 将流量路由到预定义的主机，或者预定义的 IP 地址，或者是请求的原始目的 IP 地址。在使用 gateway 的情况下，请求的原始目的 IP 地址将会丢失（因为请求被路由到 egress gateway，它的目的 IP 地址是 gateway 的 IP 地址）。

简而言之，基于 Envoy 的 Istio gateway 无法将流量路由到任意的，而非预先配置的主机，同理也就无法对任意通配符域名执行流量控制。要为 HTTPS（以及任何 TLS）启用此类流量控制，除了 Envoy 之外，您还需要部署 SNI 转发代理。Envoy 会将路由发送到通配符域名的请求路由到 SNI 转发代理，后者又会根据 SNI 值将请求转发到目的地址。

具有 SNI 代理的 egress gateway 和 Istio 的体系结构的相关部分如下图所示：

{{< image width="80%" ratio="57.89%"
    link="./EgressGatewayWithSNIProxy.svg"
    caption="带有 SNI proxy 的 Egress Gateway"
    >}}

在本节中，您将配置 Istio 以通过 egress gateway 将 HTTPS 流量路由到任意通配符域名。

### 具有 SNI 代理的自定义 egress gateway

在本小节中，除标准的 Istio Envoy 代理之外，您还将部署一个具有 SNI 代理的 egress gateway。您可以使用任何能够根据任意的、未预先配置的
 SNI 值路由流量的 SNI 代理；我们使用 [Nginx](http://nginx.org)。SNI 代理将监听端口 `8443`，您可以使用指定给 `Gateway` 的以及 `VirtualServices` 之上定义的端口以外的任意端口。SNI 代理会将流量转发到 `443` 端口。

1. 为 Nginx SNI 代理创建配置文件。如果需要，您可能希望编辑该文件以指定其他的 Nginx 配置。请注意，`server` 的 `listen` 指令指定端口 `8443`，
   其 `proxy_pass` 指令使用在 `443` 端口上的 `ssl_preread_server_name`，并使用 `ssl_preread` 指令启用 `SNI` 读取。

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

      # SNI 的 tcp 转发代理
      server {
        resolver 8.8.8.8 ipv6=off;
        listen       127.0.0.1:8443;
        proxy_pass   \$ssl_preread_server_name:443;
        ssl_preread  on;
      }
    }
    EOF
    {{< /text >}}

1. 创建一个保存 Nginx SNI 代理配置的 Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)：

    {{< text bash >}}
    $ kubectl create configmap egress-sni-proxy-configmap -n istio-system --from-file=nginx.conf=./sni-proxy.conf
    {{< /text >}}

1. 下列命令将生成一个用于编辑和部署的 `istio-egressgateway-with-sni-proxy.yaml`。

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

1. 验证新的 egress gateway 工作正常。请注意该 pod 有两个容器（一个是 Envoy 代理，另一个是 SNI 代理）。

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system
    NAME                                                  READY     STATUS    RESTARTS   AGE
    istio-egressgateway-with-sni-proxy-79f6744569-pf9t2   2/2       Running   0          17s
    {{< /text >}}

1. 创建一个带有静态地址 127.0.0.1 (`localhost`) 的 service entry，并对转发到这个新 service entry 上的流量禁用双向 TLS：

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

### 通过具有 SNI 代理的 egress gateway 的 HTTPS 流量

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

1. 验证已经正确的应用了 `ServiceEntry` 。发送 HTTPS 请求到 [https://en.wikipedia.org](https://en.wikipedia.org)
    和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1. 为 `*.wikipedia.org` 创建一个 egress `Gateway`，端口为 443，协议为 TLS，以及一个 virtual service，用于将目的为 `*.wikipedia.org`
   的流量转发到 gateway。

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

1. 发送 HTTPS 请求到
          [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1. 检查 egress gateway 代理的数据并找到请求 `*.wikipedia.org` 对应的 counter（到 SNI 代理的流量的 counter）。如果 Istio 部署在
    `istio-system` namespace 中，打印 counter 的命令为：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- curl -s localhost:15000/stats | grep sni-proxy.local.upstream_cx_total
    cluster.outbound|8443||sni-proxy.local.upstream_cx_total: 2
    {{< /text >}}

1. 检查 SNI 代理的日志。如果 Istio 部署在 `istio-system` namespace 中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl logs $(kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system -o jsonpath='{.items[0].metadata.name}') -n istio-system -c sni-proxy
    127.0.0.1 [01/Aug/2018:15:32:02 +0000] TCP [en.wikipedia.org]200 81513 280 0.600
    127.0.0.1 [01/Aug/2018:15:32:03 +0000] TCP [de.wikipedia.org]200 67745 291 0.659
    {{< /text >}}

1. 检查 mixer 的日志。如果 Istio 部署在 `istio-system` namespace 中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep '"connectionEvent":"open"' | grep '"sourceName":"istio-egressgateway' | grep 'wikipedia.org'; done
    {"level":"info","time":"2018-08-26T16:16:34.784571Z","instance":"tcpaccesslog.logentry.istio-system","connectionDuration":"0s","connectionEvent":"open","connection_security_policy":"unknown","destinationApp":"","destinationIp":"127.0.0.1","destinationName":"unknown","destinationNamespace":"default","destinationOwner":"unknown","destinationPrincipal":"cluster.local/ns/istio-system/sa/istio-egressgateway-with-sni-proxy-service-account","destinationServiceHost":"","destinationWorkload":"unknown","protocol":"tcp","receivedBytes":298,"reporter":"source","requestedServerName":"placeholder.wikipedia.org","sentBytes":0,"sourceApp":"istio-egressgateway-with-sni-proxy","sourceIp":"172.30.146.88","sourceName":"istio-egressgateway-with-sni-proxy-7c4f7868fb-rc8pr","sourceNamespace":"istio-system","sourceOwner":"kubernetes://apis/extensions/v1beta1/namespaces/istio-system/deployments/istio-egressgateway-with-sni-proxy","sourcePrincipal":"cluster.local/ns/default/sa/default","sourceWorkload":"istio-egressgateway-with-sni-proxy","totalReceivedBytes":298,"totalSentBytes":0}
    {{< /text >}}

    注意 `requestedServerName` 属性。

### SNI 监控和访问策略

现在，如果通过 egress gateway 转发出口流量，您就可以**安全的**在出口流量上应用监控和访问策略。在本小节中，您将为 `*.wikipedia.org` 的出口流量定义 log entry 和访问策略。

1. 创建 `logentry`、`rules` 和 `handlers`：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    # egress 访问的 Log entry
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
    # egress 访问的 info 日志处理器
    apiVersion: "config.istio.io/v1alpha2"
    kind: stdio
    metadata:
      name: egress-access-logger
      namespace: istio-system
    spec:
      severity_levels:
        info: 0 # 日志输出为 info 级别
      outputAsJson: true
    ---
    # 处理访问 *.wikipedia.org 的规则
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

1. 发送请求到
        [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1. 检查 mixer 的日志。如果 Istio 部署在 `istio-system` namespace 中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl -n istio-system logs -l istio-mixer-type=telemetry -c mixer | grep 'egress-access.logentry.istio-system'; done
    {{< /text >}}

1. 定义一个策略，允许访问除英文版 Wikipedia 外，与 `*.wikipedia.org` 匹配的主机名：

    {{< text bash >}}
    $ cat <<EOF | kubectl create -f -
    apiVersion: "config.istio.io/v1alpha2"
    kind: listchecker
    metadata:
      name: wikipedia-checker
      namespace: istio-system
    spec:
      overrides: ["en.wikipedia.org"]  # overrides 提供静态列表
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
    # *.wikipedia.org 访问规则
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

1. 发送 HTTPS 请求到被列入黑名单的 [https://en.wikipedia.org](https://en.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -v https://en.wikipedia.org/wiki/Main_Page'
    ...
    curl: (35) Unknown SSL protocol error in connection to en.wikipedia.org:443
    command terminated with exit code 35
    {{< /text >}}

1. 发送 HTTPS 请求到其他网站，例如 [https://es.wikipedia.org](https://es.wikipedia.org) 和
   [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- bash -c 'curl -s https://es.wikipedia.org/wiki/Wikipedia:Portada | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, la enciclopedia libre</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

#### 清理监控和策略

{{< text bash >}}
$ kubectl delete rule handle-wikipedia-access check-wikipedia-access -n istio-system
$ kubectl delete logentry egress-access -n istio-system
$ kubectl delete stdio egress-access-logger -n istio-system
$ kubectl delete listentry requested-server-name -n istio-system
$ kubectl delete listchecker wikipedia-checker -n istio-system
{{< /text >}}

### 清理到通配符域名的 HTTPS 流量配置

1. 删除针对 `*.wikipedia.org` 的配置项：

    {{< text bash >}}
    $ kubectl delete serviceentry wikipedia
    $ kubectl delete gateway istio-egressgateway-with-sni-proxy
    $ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
    $ kubectl delete destinationrule egressgateway-for-wikipedia
    {{< /text >}}

1. 删除针对 `egressgateway-with-sni-proxy` `Deployment` 的配置项：

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

执行[配置 Egress Gateway](/docs/examples/advanced-gateways/egress-gateway) 实例中[清理](/docs/examples/advanced-gateways/egress-gateway/#cleanup)小节的步骤。
