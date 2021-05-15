---
title: Wildcard 主机的 egress
description: 描述如何开启通用域中一组主机的 egress，无需单独配置每一台主机。
keywords: [traffic-management,egress]
weight: 50
aliases:
  - /zh/docs/examples/advanced-gateways/wildcard-egress-hosts/
owner: istio/wg-networking-maintainers
test: yes
---

[控制 Egress 流量](/zh/docs/tasks/traffic-management/egress/)任务和[配置一个 Egress 网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/)示例描述如何配置特定主机的 egress 流量，如：`edition.cnn.com`。本示例描述如何为通用域中的一组特定主机开启 egress 流量，譬如：`*.wikipedia.org`，无需单独配置每一台主机。

## 背景{#background}

假定您想要为 Istio 中所有语种的 `wikipedia.org` 站点开启 egress 流量。每个语种的 `wikipedia.org` 站点均有自己的主机名，譬如：英语和德语对应的主机分别为 `en.wikipedia.org` 和 `de.rikipedia.org`。您希望通过通用配置项开启所有 Wikipedia 站点的 egress 流量，无需单独配置每个语种的站点。

## 开始之前(before-you-begin)

*  使用 `demo` [配置文件](/zh/docs/setup/additional-setup/config-profiles/)安装 Istio 以及默认阻止出站流量策略：

    {{< text bash >}}
    $ istioctl install --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
    {{< /text >}}

    {{< tip >}}
    您可以在 `demo` 配置文件以外的 Istio 配置上运行此任务，只要您确保 [部署 Istio egress 网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/#deploy-Istio-egress-gateway)。
    [开启 Envoy 的访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)和
    [应用默认阻止出站流量策略](/zh/docs/tasks/traffic-management/egress/egress-control/#change-to-the-blocking-by-default-policy)
    在您的安装步骤中。您还需要使用自己的 `IstioOperator` CR 代替[使用SNI代理设置出口网关](#setup-egress-gateway-with-sni-proxy)中显示。
    {{< /tip >}}

*   部署[sleep]({{< github_tree >}}/samples/sleep)示例应用程序，以用作发送请求的测试源。如果您开启了 [自动 sidecar 注入](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，运行以下命令以部署示例应用程序：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则，在使用以下命令部署 `sleep` 应用程序之前，手动注入 sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    {{< tip >}}
    您可以在任意 pod 上使用 `curl` 作为测试源。
    {{< /tip >}}

*   将 `SOURCE_POD` 环境变量设置为您的源 Pod 的名称：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## 引导流量流向 Wildcard 主机{#configure-direct-traffic-to-a-wildcard-host}

访问通用域中一组主机的第一个也是最简单的方法，是使用一个 wildcard 主机配置一个简单的 `ServiceEntry`，直接从 sidecar 调用服务。
当直接调用服务时（譬如：不是通过一个 egress 网关），一个 wildcard 主机的配置与任何其他主机（如：全域名主机）没有什么不同，只是当通用域中有许多台主机时，这样比较方便。

{{< warning >}}
请注意，恶意应用程序很容易绕过以下配置。为了实现安全的出口流量控制，可以通过出口网关引导流量。
{{< /warning >}}

{{< warning >}}
请注意，`DNS` 解析不能用于通配符主机。这就是为什么`NONE`分辨率（因为它是默认）用于以下服务条目。
{{< /warning >}}

1. 为 `*.wikipedia.org` 定义一个 `ServiceEntry` 以及相应的 `VirtualSevice`：

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
        name: https
        protocol: HTTPS
    EOF
    {{< /text >}}

1. 发送 HTTPS 请求至
    [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

### 清除引导流量至 wildcard 主机{#cleanup-direct-traffic-to-a-wildcard-host}

{{< text bash >}}
$ kubectl delete serviceentry wikipedia
{{< /text >}}

## 配置访问 wildcard 主机的 egress 网关{#configure-egress-gateway-traffic-to-a-wildcard-host}

能否配置通过 egress 网关访问 wildcard 主机取决于这组 wildcard 域名有唯一一个通用主机。
以 _*.wikipedia.org_ 为例。每个语种特殊的站点都有自己的 _wikipedia.org_ 服务器。您可以向任意一个 _*.wikipedia.org_ 站点的 IP 发送请求，包括 _www.wikipedia.org_，该站点[管理服务](https://en.wikipedia.org/wiki/Virtual_hosting)所有特定主机。

通常情况下，通用域中的所有域名并不由一个唯一的 hosting server 提供服务。此时，需要一个更加复杂的配置。

### 单一 hosting 服务器的 Wildcard 配置{#wildcard-configuration-for-a-single-hosting-server}

当一台唯一的服务器为所有 wildcard 主机提供服务时，基于 egress 网关访问 wildcard 主机的配置与普通主机类似，除了：配置的路由目标不能与配置的主机相同，如：wildcard 主机，需要配置为通用域集合的唯一服务器主机。

1. 为 _*.wikipedia.org_ 创建一个 egress `Gateway`、一个目标规则以及一个虚拟服务，来引导请求通过 egress 网关并从 egress 网关访问外部服务。

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
          name: https
          protocol: HTTPS
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
          sniHosts:
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
          sniHosts:
          - "*.wikipedia.org"
        route:
        - destination:
            host: www.wikipedia.org
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1. 为目标服务器 _www.wikipedia.org_ 创建一个 `ServiceEntry`。

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

1. 发送请求至
    [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1. 检查 egress 网关代理访问 _*.wikipedia.org_ 的计数器统计值。如果 Istio 部署在 `istio-system` 命名空间中，打印输出计数器的命令为：

    {{< text bash >}}
    $ kubectl exec -it $(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}') -c istio-proxy -n istio-system -- pilot-agent request GET clusters | grep '^outbound|443||www.wikipedia.org.*cx_total:'
    outbound|443||www.wikipedia.org::208.80.154.224:443::cx_total::2
    {{< /text >}}

#### 清除单点服务器的 wildcard 配置{#cleanup-wildcard-configuration-for-a-single-hosting-server}

{{< text bash >}}
$ kubectl delete serviceentry www-wikipedia
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-wikipedia
{{< /text >}}

### 任意域的 Wildcard 配置{#wildcard-configuration-for-arbitrary-domains}

前面章节的配置生效，是因为 _*.wikipedia.org_ 站点可以由任意一个 _wikipedia.org_ 服务器提供服务。然而，情况并不总是如此。
譬如，你可能想要配置 egress 控制到更为通用的 wildcard 域，如：`*.com` 或 `*.org`。

配置流量流向任意 wildcard 域，为 Istio 网关引入一个挑战。在前面的章节中，您在配置中，将 _www.wikipedia.org_ 配置为网关的路由目标主机，将流量导向该地址。
然而，网关并不知道它接收到的请求中任意 arbitrary 主机的 IP 地址。
这是 Istio 默认的 egress 网关代理 [Envoy](https://www.envoyproxy.io) 的限制。Envoy 或者将流量路由至提前定义好的主机，或者路由至提前定义好的 IP 地址，或者是请求的最初 IP 地址。在网关案例中，请求的最初目标 IP 被丢弃，因为请求首先路由至 egress 网关，其目标 IP 为网关的 IP 地址。

因此，基于 Envoy 的 Istio 网关无法将流量路由至没有预先配置的 arbitrary 主机，从而，无法对任意 wildcard 域实施流量控制。
为了对 HTTPS 和任意 TLS 连接开启流量控制，您需要在 Envoy 的基础上再部署一个 SNI 转发代理。Envoy 将访问 wildcard 域的请求路由至 SNI 转发代理，代理反过来将请求转发给 SNI 值中约定的目标地址。

带 SNI 代理的 egress 网关，以及相关的 Istio 架构部分如下图所示：

{{< image width="80%" link="./EgressGatewayWithSNIProxy.svg" caption="Egress Gateway with SNI proxy" >}}

如下章节向您展示如何重新部署带 SNI 代理的 egress 网关，并配置 Istio 通过网关将 HTTPS 请求导向任意 wildcard 域。

#### 安装带 SNI 代理的 egress 网关{#setup-egress-gateway-with-SNI-proxy}

本章节，除了标准的 Istio Envoy 代理，您将再部署一个带 SNI 代理的 egress 网关。本示例使用 [Nginx](http://nginx.org) 作为 SNI 代理。任何一个能够根据任意的、非预先配置的 SNI 值路由流量的 SNI 代理均可。
SNI 代理将监听在端口 `8443` 上，您可以绑定任意其它端口，egress `Gateway` 和 `VirtualServices` 中配置的端口除外。SNI 代理将流量转发至端口 `443`。

1. 创建一个 Nginx SNI 代理的配置文件。您可以按需编辑文件指定附加的 Nginx 设置。注意 `server` 的 `listen` 原语指定端口为 `8443`，其 `proxy_pass` 原语使用 `ssl_preread_server_name` 端口为 `443`，`ssl_preread` 为 `on` 以开启 `SNI` 读。

    {{< text bash >}}
    $ cat <<EOF > ./sni-proxy.conf
    # 设置不需要根访问权限的自定义路径
    pid /tmp/nginx.pid;

    events {
    }

    stream {
      log_format log_stream '\$remote_addr [\$time_local] \$protocol [\$ssl_preread_server_name]'
      '\$status \$bytes_sent \$bytes_received \$session_time';

      access_log /var/log/nginx/access.log log_stream;
      error_log  /var/log/nginx/error.log;

      # SNI 的 TCP 转发代理
      server {
        resolver 8.8.8.8 ipv6=off;
        listen       127.0.0.1:8443;
        proxy_pass   \$ssl_preread_server_name:443;
        ssl_preread  on;
      }
    }
    EOF
    {{< /text >}}

1. 创建一个 Kubernetes [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
    来保存 Nginx SNI 代理的配置文件：

    {{< text bash >}}
    $ kubectl create configmap egress-sni-proxy-configmap -n istio-system --from-file=nginx.conf=./sni-proxy.conf
    {{< /text >}}

1.  创建一个 `IstioOperator` CR，以使用SNI代理添加新的出口网关：

    {{< text bash >}}
    $ istioctl manifest generate -f - <<EOF > ./egressgateway-with-sni-proxy.yaml
    apiVersion: install.istio.io/v1alpha1
    kind: IstioOperator
    spec:
      # Only generate a gateway component defined below.
      # Using this with "istioctl install" will reconcile and remove existing control-plane components.
      # Instead use "istioctl manifest generate" or "kubectl create" if using the istio operator.
      profile: empty
      components:
        egressGateways:
        - name: istio-egressgateway-with-sni-proxy
          enabled: true
          label:
            app: istio-egressgateway-with-sni-proxy
            istio: egressgateway-with-sni-proxy
          k8s:
            service:
              ports:
              - port: 443
                targetPort: 8443
                name: https
            overlays:
            - kind: Deployment
              name: istio-egressgateway-with-sni-proxy
              patches:
              - path: spec.template.spec.containers[-1]
                value: |
                  name: sni-proxy
                  image: nginx
                  volumeMounts:
                  - name: sni-proxy-config
                    mountPath: /etc/nginx
                    readOnly: true
                  securityContext:
                    runAsNonRoot: true
                    runAsUser: 101
              - path: spec.template.spec.volumes[-1]
                value: |
                  name: sni-proxy-config
                  configMap:
                    name: egress-sni-proxy-configmap
                    defaultMode: 292 # 0444
    EOF
    {{< /text >}}

1. 部署新的 egress 网关：

    {{< text bash >}}
    $ kubectl apply -f ./egressgateway-with-sni-proxy.yaml
    {{< /text >}}

1. 验证新的 egress 网关正在运行。注意 pod 有两个容器（一个是 Envoy 代理，另一个是 SNI 代理）。

    {{< text bash >}}
    $ kubectl get pod -l istio=egressgateway-with-sni-proxy -n istio-system
    NAME                                                  READY     STATUS    RESTARTS   AGE
    istio-egressgateway-with-sni-proxy-79f6744569-pf9t2   2/2       Running   0          17s
    {{< /text >}}

1. 创建一个 service entry，静态地址为 127.0.0.1 (`localhost`)，关闭发送至新 service entry 的双向 TLS 请求。

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

#### 配置流量流经包含 SNI 代理的 egress 网关{#configure-traffic-through-egress-gateway-with-SNI-proxy}

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

1. 为 _*.wikipedia.org_ 创建一个 egress `Gateway`，端口 443，协议 TLS，以及一个虚拟服务负责引导目标为 _*.wikipedia.org_ 的流量流经网关。

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
          name: tls-egress
          protocol: TLS
        hosts:
        - "*.wikipedia.org"
        tls:
          mode: ISTIO_MUTUAL
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
          sniHosts:
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
              number: 18443
          weight: 100
    ---
    # 下面的 filter 用于将最初的 SNI （应用发送的）转换为双向 TLS 连接的 SNI。
    # 双向 TLS 连接。
    # 转换后的 SNI 将被报告给 Mixer，以基于初始 SNI 的值强制实施策略。
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: forward-downstream-sni
    spec:
      configPatches:
      - applyTo: NETWORK_FILTER
        match:
          context: SIDECAR_OUTBOUND
          listener:
            portNumber: 443
            filterChain:
              filter:
                name: istio.stats
        patch:
          operation: INSERT_BEFORE
          value:
             name: forward_downstream_sni
             config: {}
    EOF
    {{< /text >}}

1.  Add an `EnvoyFilter` to the gateway, to prevent it from being deceived.

    {{< text bash >}}
    $ kubectl apply -n istio-system -f - <<EOF
    # The following filter verifies that the SNI of the mutual TLS connection is
    # identical to the original SNI issued by the client (the SNI used for routing by the SNI proxy).
    # The filter prevents the gateway from being deceived by a malicious client: routing to one SNI while
    # reporting some other value of SNI. If the original SNI does not match the SNI of the mutual TLS connection,
    # the filter will block the connection to the external service.
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    metadata:
      name: egress-gateway-sni-verifier
    spec:
      workloadSelector:
        labels:
          app: istio-egressgateway-with-sni-proxy
      configPatches:
      - applyTo: NETWORK_FILTER
        match:
          context: GATEWAY
          listener:
            portNumber: 443
            filterChain:
              filter:
                name: istio.stats
        patch:
          operation: INSERT_BEFORE
          value:
             name: sni_verifier
             config: {}
    EOF
    {{< /text >}}

1. 发送 HTTPS 请求至
    [https://en.wikipedia.org](https://en.wikipedia.org) and [https://de.wikipedia.org](https://de.wikipedia.org):

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

1. 检查 Egress 网关 Envoy 代理的日志。如果 Istio 被部署在 `istio-system` 命名空间中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway-with-sni-proxy -c istio-proxy -n istio-system
    {{< /text >}}

    您将看到类似如下的内容：

    {{< text plain >}}
    [2019-01-02T16:34:23.312Z] "- - -" 0 - 578 79141 624 - "-" "-" "-" "-" "127.0.0.1:8443" outbound|8443||sni-proxy.local 127.0.0.1:55018 172.30.109.84:443 172.30.109.112:45346 en.wikipedia.org
    [2019-01-02T16:34:24.079Z] "- - -" 0 - 586 65770 638 - "-" "-" "-" "-" "127.0.0.1:8443" outbound|8443||sni-proxy.local 127.0.0.1:55034 172.30.109.84:443 172.30.109.112:45362 de.wikipedia.org
    {{< /text >}}

1. 检查 SNI 代理的日志。如果 Istio 被部署在 `istio-system` 命名空间中，打印日志的命令为：

    {{< text bash >}}
    $ kubectl logs -l istio=egressgateway-with-sni-proxy -n istio-system -c sni-proxy
    127.0.0.1 [01/Aug/2018:15:32:02 +0000] TCP [en.wikipedia.org]200 81513 280 0.600
    127.0.0.1 [01/Aug/2018:15:32:03 +0000] TCP [de.wikipedia.org]200 67745 291 0.659
    {{< /text >}}

#### 清除任意域的 wildcard 配置{#cleanup-wildcard-configuration-for-arbitrary-domains}

1. 删除 _*.wikipedia.org_ 的配置项：

    {{< text bash >}}
    $ kubectl delete serviceentry wikipedia
    $ kubectl delete gateway istio-egressgateway-with-sni-proxy
    $ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
    $ kubectl delete destinationrule egressgateway-for-wikipedia
    $ kubectl delete --ignore-not-found=true envoyfilter forward-downstream-sni
    $ kubectl delete --ignore-not-found=true envoyfilter -n istio-system egress-gateway-sni-verifier
    {{< /text >}}

1. 删除部署 `egressgateway-with-sni-proxy` 的配置项：

    {{< text bash >}}
    $ kubectl delete serviceentry sni-proxy
    $ kubectl delete destinationrule disable-mtls-for-sni-proxy
    $ kubectl delete configmap egress-sni-proxy-configmap -n istio-system
    $ kubectl delete -f ./egressgateway-with-sni-proxy.yaml
    {{< /text >}}

1. 删除您创建的配置文件：

    {{< text bash >}}
    $ rm ./sni-proxy.conf ./egressgateway-with-sni-proxy.yaml
    {{< /text >}}

## 清除{#cleanup}

* 关闭服务 [sleep]({{< github_tree >}}/samples/sleep)：

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}

* 从您的集群中卸载 Istio:

    {{< text bash >}}
    $ istioctl x uninstall --purge
    {{< /text >}}

