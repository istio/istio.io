---
title: Wildcard 主机的 Egress
description: 描述如何开启通用域中一组主机的 Egress，无需单独配置每一台主机。
keywords: [traffic-management,egress]
weight: 50
aliases:
  - /zh/docs/examples/advanced-gateways/wildcard-egress-hosts/
owner: istio/wg-networking-maintainers
test: yes
---

[控制 Egress 流量](/zh/docs/tasks/traffic-management/egress/)任务和
[配置一个 Egress 网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/)示例描述如何配置特定主机的
Egress 流量，如：`edition.cnn.com`。本示例描述如何为通用域中的一组特定主机开启 Egress 流量，
譬如 `*.wikipedia.org`，无需单独配置每一台主机。

## 背景  {#background}

假定您想要为 Istio 中所有语种的 `wikipedia.org` 站点开启 Egress 流量。每个语种的
`wikipedia.org` 站点均有自己的主机名，譬如：英语和德语对应的主机分别为 `en.wikipedia.org`
和 `de.rikipedia.org`。您希望通过通用配置项开启所有 Wikipedia 站点的 Egress 流量，无需单独配置每个语种的站点。

{{< boilerplate gateway-api-gamma-support >}}

## 开始之前  {#before-you-begin}

*  安装 Istio，启用访问日志记录，并采用默认阻止出站流量策略。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio API" category-value="istio-apis" >}}

{{< text bash >}}
$ istioctl install --set profile=demo --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
{{< /text >}}

{{< tip >}}
您可以在 `demo` 配置文件以外的 Istio 配置上运行此任务，
只要您确保[部署 Istio Egress 网关](/zh/docs/tasks/traffic-management/egress/egress-gateway/#deploy-Istio-egress-gateway)。
[开启 Envoy 的访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)和
[应用默认阻止出站流量策略](/zh/docs/tasks/traffic-management/egress/egress-control/#change-to-the-blocking-by-default-policy)
{{< /tip >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ istioctl install --set profile=minimal -y \
    --set values.pilot.env.PILOT_ENABLE_ALPHA_GATEWAY_API=true \
    --set meshConfig.accessLogFile=/dev/stdout \
    --set meshConfig.outboundTrafficPolicy.mode=REGISTRY_ONLY
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

*   部署 [sleep]({{< github_tree >}}/samples/sleep) 示例应用程序，以用作发送请求的测试源。
    如果您开启了 [Sidecar 自动注入](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，
    运行以下命令以部署示例应用程序：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则，在使用以下命令部署 `sleep` 应用程序之前，手动注入 Sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    {{< tip >}}
    您可以在任意 Pod 上使用 `curl` 作为测试源。
    {{< /tip >}}

*   将 `SOURCE_POD` 环境变量设置为您的源 Pod 的名称：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## 引导流量流向 Wildcard 主机  {#configure-direct-traffic-to-a-wildcard-host}

访问通用域中一组主机的第一个也是最简单的方法，是使用一个 wildcard 主机配置一个简单的 `ServiceEntry`，
直接从 Sidecar 调用服务。当直接调用服务时（譬如：不是通过一个 Egress 网关），一个 wildcard
主机的配置与任何其他主机（如：全域名主机）没有什么不同，只是当通用域中有许多台主机时，这样比较方便。

{{< warning >}}
请注意，恶意应用程序很容易绕过以下配置。为了实现安全的出口流量控制，可以通过出口网关引导流量。
{{< /warning >}}

{{< warning >}}
请注意，`DNS` 解析不能用于通配符主机。这就是为什么 `NONE` 分辨率（因为它是默认）用于以下服务条目。
{{< /warning >}}

1. 为 `*.wikipedia.org` 定义一个 `ServiceEntry`：

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

### 清理将流量引导至 Wildcard 主机的规则  {#cleanup-direct-traffic-to-a-wildcard-host}

{{< text bash >}}
$ kubectl delete serviceentry wikipedia
{{< /text >}}

## 配置到 Wildcard 主机的 Egress 网关流量规则 {#configure-egress-gateway-traffic-to-a-wildcard-host}

当一台唯一的服务器为所有 wildcard 主机提供服务时，基于 Egress 网关访问 wildcard 主机的配置与普通主机类似，
除了：配置的路由目标不能与配置的主机相同，如：wildcard 主机，需要配置为通用域集合的唯一服务器主机。

1. 为 _*.wikipedia.org_ 创建一个 Egress `Gateway`，并创建路由规则引导经过
   Egress 网关的流量以及从 Egress 网关到外部服务的流量。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio API" category-value="istio-apis" >}}

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

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: wikipedia-egress-gateway
  annotations:
    networking.istio.io/service-type: ClusterIP
spec:
  gatewayClassName: istio
  listeners:
  - name: tls
    hostname: "*.wikipedia.org"
    port: 443
    protocol: TLS
    tls:
      mode: Passthrough
    allowedRoutes:
      namespaces:
        from: Same
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: direct-wikipedia-to-egress-gateway
spec:
  parentRefs:
  - kind: ServiceEntry
    group: networking.istio.io
    name: wikipedia
  rules:
  - backendRefs:
    - name: wikipedia-egress-gateway-istio
      port: 443
---
apiVersion: gateway.networking.k8s.io/v1alpha2
kind: TLSRoute
metadata:
  name: forward-wikipedia-from-egress-gateway
spec:
  parentRefs:
  - name: wikipedia-egress-gateway
  hostnames:
  - "*.wikipedia.org"
  rules:
  - backendRefs:
    - kind: Hostname
      group: networking.istio.io
      name: www.wikipedia.org
      port: 443
---
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

{{< /tab >}}

{{< /tabset >}}

2)  为目标服务器 _www.wikipedia.org_ 创建一个 `ServiceEntry`：

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
        name: https
        protocol: HTTPS
      resolution: DNS
    EOF
    {{< /text >}}

3)  发送 HTTPS 请求至
    [https://en.wikipedia.org](https://en.wikipedia.org) 和 [https://de.wikipedia.org](https://de.wikipedia.org)：

    {{< text bash >}}
    $ kubectl exec "$SOURCE_POD" -c sleep -- sh -c 'curl -s https://en.wikipedia.org/wiki/Main_Page | grep -o "<title>.*</title>"; curl -s https://de.wikipedia.org/wiki/Wikipedia:Hauptseite | grep -o "<title>.*</title>"'
    <title>Wikipedia, the free encyclopedia</title>
    <title>Wikipedia – Die freie Enzyklopädie</title>
    {{< /text >}}

4)  检查 Egress 网关代理访问 `*.wikipedia.org` 的计数器统计值。

{{< tabset category-name="config-api" >}}

{{< tab name="Istio API" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l istio=egressgateway -n istio-system -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -n istio-system -- pilot-agent request GET clusters | grep '^outbound|443||www.wikipedia.org.*cx_total:'
outbound|443||www.wikipedia.org::208.80.154.224:443::cx_total::2
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl exec "$(kubectl get pod -l gateway.networking.k8s.io/gateway-name=wikipedia-egress-gateway -o jsonpath='{.items[0].metadata.name}')" -c istio-proxy -- pilot-agent request GET clusters | grep '^outbound|443||www.wikipedia.org.*cx_total:'
outbound|443||www.wikipedia.org::208.80.154.224:443::cx_total::2
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### 清理到 Wildcard 主机的 Egress 网关流量 {#cleanup-egress-gateway-traffic-to-a-wildcard-host}

{{< tabset category-name="config-api" >}}

{{< tab name="Istio API" category-value="istio-apis" >}}

{{< text bash >}}
$ kubectl delete serviceentry www-wikipedia
$ kubectl delete gateway istio-egressgateway
$ kubectl delete virtualservice direct-wikipedia-through-egress-gateway
$ kubectl delete destinationrule egressgateway-for-wikipedia
{{< /text >}}

{{< /tab >}}

{{< tab name="Gateway API" category-value="gateway-api" >}}

{{< text bash >}}
$ kubectl delete se wikipedia
$ kubectl delete se www-wikipedia
$ kubectl delete gtw wikipedia-egress-gateway
$ kubectl delete tlsroute direct-wikipedia-to-egress-gateway
$ kubectl delete tlsroute forward-wikipedia-from-egress-gateway
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## 任意域的 Wildcard 配置  {#wildcard-configuration-for-arbitrary-domains}

上一节中的配置之所以有效，是因为所有 `*.wikipedia.org` 站点都可能由任何一个 `wikipedia.org` 服务器提供服务。
然而，实际情况并非总是如此。例如，您可能想要配置出口控制以访问更通用的 Wildcard 域，
例如 `*.com` 或 `*.org`。为任意 Wildcard 域名配置流量给 Istio 网关带来了挑战；
Istio 网关只能将流量路由配置到预定义的主机、预定义的 IP 地址或请求的原始目标 IP 地址。

在上一节中，您配置了虚拟服务用于将流量定向预定义主机 `www.wikipedia.org`。
然而，在一般情况下，您不知道可以为请求中收到的任意主机提供服务的主机或 IP 地址，
这使得请求的原始目标地址成为路由请求的唯一值。不幸的是，当使用出口网关时，
由于原始请求被重定向到网关，因此请求的原始目标地址丢失，导致目标 IP 地址变成网关的 IP 地址。

尽管这样做并不简单且有些脆弱，因为它依赖于 Istio 实现细节，但您可以使用
[Envoy 过滤器](/zh/docs/reference/config/networking/envoy-filter/)通过使用
[SNI](https://en.wikipedia.org/wiki/Server_Name_Indication)
配置网关以支持任意域 HTTPS 或任何 TLS 请求中的值，用于标识将请求路由到的原始目的地。
这种配置方法的一个示例可以在[将出口流量路由至通配符目的地](/zh/blog/2023/egress-sni/)中找到。

## 清理  {#cleanup}

* 关闭 [sleep]({{< github_tree >}}/samples/sleep) 服务：

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}

* 从您的集群中卸载 Istio：

    {{< text bash >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}
