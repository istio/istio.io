---
title: 把 Istio 作为外部服务的代理
subtitle: 把 Istio 入口网关配置为外部服务的代理
description: 把 Istio 入口网关配置为外部服务的代理。
publishdate: 2019-10-15
attribution: Vadim Eisenberg (IBM)
keywords: [traffic-management,ingress,https,http]
---

在网格内如何配置一个入口网关来把内部服务暴露出去，让外部可以访问，在这两篇文章中有介绍[控制入口流量](/zh/docs/tasks/traffic-management/ingress/ingress-control/)和[无 TLS 终止的入口网关](/zh/docs/tasks/traffic-management/ingress/ingress-sni-passthrough/)。这些服务可以是 HTTP 或者 HTTPS。如果是 HTTPS，网关会透传流量，而不终止 TLS。

这篇博客介绍如何使用 Istio 的入口网关机制来访问外部服务，而不是网格内应用。这样，Istio 整个作为一个代理服务，具有可观测性、流量管理和策略执行的附加价值。

这篇博客也展示了如何配置访问一个外部的 HTTP 和 HTTPS 服务，分别是 `httpbin.org` 和 `edition.cnn.com`。

## 配置一个入口网关{#configure-an-ingress-gateway}

1. 定义一个入口网关，在 `servers:` 配置中配置 `80` 和 `443` 端口。
    在对端口 `443` 的配置终确定 `tls:` 的 `mode:` 配置为 `PASSTHROUGH`，这配置网关直接透传流量而且不终止 TLS。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: Gateway
    metadata:
      name: proxy
    spec:
      selector:
        istio: ingressgateway # use istio default ingress gateway
      servers:
      - port:
          number: 80
          name: http
          protocol: HTTP
        hosts:
        - httpbin.org
      - port:
          number: 443
          name: tls
          protocol: TLS
        tls:
          mode: PASSTHROUGH
        hosts:
        - edition.cnn.com
    EOF
    {{< /text >}}

1. 为 `httpbin.org` 和 `edition.cnn.com` 创建服务入口，让他们可以通过入口网关访问：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: httpbin-ext
    spec:
      hosts:
      - httpbin.org
      ports:
      - number: 80
        name: http
        protocol: HTTP
      resolution: DNS
      location: MESH_EXTERNAL
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 443
        name: tls
        protocol: TLS
      resolution: DNS
      location: MESH_EXTERNAL
    EOF
    {{< /text >}}

1. 创建一个服务入口，并且为 `localhost` 服务配置目的规则。在下一步中，需要这个服务入口作为网格内部应用流量到外部服务的目的地，从而隔断来自网格内部的流量。在此例中把 Istio 用作外部应用和外部服务间的代理。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: localhost
    spec:
      hosts:
      - localhost.local
      location: MESH_EXTERNAL
      ports:
      - number: 80
        name: http
        protocol: HTTP
      - number: 443
        name: tls
        protocol: TLS
      resolution: STATIC
      endpoints:
      - address: 127.0.0.1
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: localhost
    spec:
      host: localhost.local
      trafficPolicy:
        tls:
          mode: DISABLE
          sni: localhost.local
    EOF
    {{< /text >}}

1. 为每个外部服务创建一个虚拟服务并配置路由规则。两个虚拟服务的 `gateways:` 和 `match:` 配置中有针对 HTTP 和 HTTPS 流量相关的 `proxy` 网关配置。

    注意 `route:` 配置中的 `mesh` 网关配置，这个网关代表网格内的应用程序。`mesh` 网关中的 `route:` 配置表示如何将流量转向 `localhost.local` 服务，从而有效地阻隔了流量。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: httpbin
    spec:
      hosts:
      - httpbin.org
      gateways:
      - proxy
      - mesh
      http:
      - match:
        - gateways:
          - proxy
          port: 80
          uri:
            prefix: /status
        route:
        - destination:
            host: httpbin.org
            port:
              number: 80
      - match:
        - gateways:
          - mesh
          port: 80
        route:
        - destination:
            host: localhost.local
            port:
              number: 80
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      gateways:
      - proxy
      - mesh
      tls:
      - match:
        - gateways:
          - proxy
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
      - match:
        - gateways:
          - mesh
          port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: localhost.local
            port:
              number: 443
    EOF
    {{< /text >}}

1. [启用 Envoy 的访问日志](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)。

1. 根据[确定入口网关的 IP 和端口](/zh/docs/tasks/traffic-management/ingress/ingress-control/#determining-the-ingress-i-p-and-ports)中的命令，设置 `SECURE_INGRESS_PORT` 和 `INGRESS_HOST` 两个环境变量。

1. 在上一步中分别把 IP 和端口存储到了环境变量 `$INGRESS_HOST` 和 `$INGRESS_PORT` 中，现在可以用这个 IP 和端口访问 `httpbin.org` 服务。访问 `httpbin.org` 服务的 `/status/418` 路径，会返回 [418 我是一个茶壶](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/418)的 HTTP 状态码。

    {{< text bash >}}
    $ curl $INGRESS_HOST:$INGRESS_PORT/status/418 -Hhost:httpbin.org

    -=[ teapot ]=-

       _...._
     .'  _ _ `.
    | ."` ^ `". _,
    \_;`"---"`|//
      |       ;/
      \_     _/
        `"""`
    {{< /text >}}

1. 如果 Istio 入口网关部署在 `istio-system` 名字空间下，使用下面的命令打印网关日志。

    {{< text bash >}}
    $ kubectl logs -l istio=ingressgateway -c istio-proxy -n istio-system | grep 'httpbin.org'
    {{< /text >}}

1. 检索日志找到类似如下内容：

    {{< text plain >}}
    [2019-01-31T14:40:18.645Z] "GET /status/418 HTTP/1.1" 418 - 0 135 187 186 "10.127.220.75" "curl/7.54.0" "28255618-6ca5-9d91-9634-c562694a3625" "httpbin.org" "34.232.181.106:80" outbound|80||httpbin.org - 172.30.230.33:80 10.127.220.75:52077 -
    {{< /text >}}

1. 通过入口网关访问 `edition.cnn.com` 服务：

    {{< text bash >}}
    $ curl -s --resolve edition.cnn.com:$SECURE_INGRESS_PORT:$INGRESS_HOST https://edition.cnn.com:$SECURE_INGRESS_PORT | grep -o "<title>.*</title>"
    <title>CNN International - Breaking News, US News, World News and Video</title>
    {{< /text >}}

1. 如果 Istio 入口网关部署在 `istio-system` 名字空间下，使用下面的命令打印网关日志。

    {{< text bash >}}
    $ kubectl logs -l istio=ingressgateway -c istio-proxy -n istio-system | grep 'edition.cnn.com'
    {{< /text >}}

1. 检索日志找到类似如下内容：

    {{< text plain >}}
    [2019-01-31T13:40:11.076Z] "- - -" 0 - 589 17798 1644 - "-" "-" "-" "-" "172.217.31.132:443" outbound|443||edition.cnn.com 172.30.230.33:54508 172.30.230.33:443 10.127.220.75:49467 edition.cnn.com
    {{< /text >}}

## 清除{#cleanup}

删除网关、虚拟服务和服务入口：

{{< text bash >}}
$ kubectl delete gateway proxy
$ kubectl delete virtualservice cnn httpbin
$ kubectl delete serviceentry cnn httpbin-ext localhost
$ kubectl delete destinationrule localhost
{{< /text >}}
