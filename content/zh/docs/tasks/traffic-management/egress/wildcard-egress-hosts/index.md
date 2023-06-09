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

## 清除{#cleanup}

* 关闭服务 [sleep]({{< github_tree >}}/samples/sleep)：

{{< text bash >}}
$ kubectl delete -f @samples/sleep/sleep.yaml@
{{< /text >}}

* 从您的集群中卸载 Istio:

    {{< text bash >}}
    $ istioctl uninstall --purge -y
    {{< /text >}}
