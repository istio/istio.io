---
title: 出口流量的 TLS
description: 此任务描述 Istio 如何配置出口流量的 TLS。
weight: 42
---

[控制出口流量](/zh/docs/tasks/traffic-management/egress/)任务演示了如何从网格内部的应用程序访问 Kubernetes 集群外部的 HTTP 和 HTTPS 服务, 如该主题中所述，默认情况下，启用了 Istio 的应用程序无法访问集群外的 URL, 要启用外部访问，必须定义外部服务的[`ServiceEntry`](/zh/docs/reference/config/istio.networking.v1alpha3/#serviceentry)，或者[直接访问外部服务](/zh/docs/tasks/traffic-management/egress/#直接调用外部服务)。

此任务描述 Istio 如何配置出口流量的 TLS。

## 用例

考虑一个对外部站点执行 HTTP 调用的遗留应用程序, 假设运行应用程序的组织收到一个新要求，该要求规定必须加密所有外部流量, 使用 Istio，只需通过配置就可以实现这样的要求，而无需更改应用程序的代码。

在此任务中，如果原始流量为 HTTP，则将 Istio 配置为打开与外部服务的 HTTPS 连接, 应用程序将像以前一样发送未加密的 HTTP 请求，Istio 将加密应用程序的请求。

## 前提条件

* 按照[安装指南](/zh/docs/setup/)中的说明设置 Istio 。

*   启动 [sleep]({{< github_tree >}}/samples/sleep) 示例，它将作为外部调用的测试源。

    如果您已启用[自动注入 sidecar](/zh/docs/setup/kubernetes/additional-setup/sidecar-injection/#sidecar-的自动注入), 请按如下命令部署 `sleep` 应用程序:

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则，您必须在部署 `sleep` 应用程序之前手动注入 sidecar：

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    请注意，任何可以 `exec` 和 `curl` 的 pod 都可以执行以下步骤。

*   创建一个 shell 变量来保存源 pod 的名称，以便将请求发送到外部服务, 如果您使用 [sleep]({{< github_tree >}}/samples/sleep) 示例，请按如下命令运行:

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## 配置 HTTP 和 HTTPS 外部服务

首先，与[控制出口流量](/zh/docs/tasks/traffic-management/egress/)任务相同的方式配置对 _cnn.com_ 的访问。
请注意，在 `hosts` 中定义中使用 `*` 通配符：`*.cnn.com` , 使用通配符可以访问 _www.cnn.com_ 以及 _edition.cnn.com_ 。

1.  创建一个 `ServiceEntry` 以允许访问外部 HTTP 和 HTTPS 服务：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - "*.cnn.com"
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: NONE
    EOF
    {{< /text >}}

1.  向外部 HTTP 服务发出请求：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 301 Moved Permanently
    ...
    location: https://edition.cnn.com/politics
    ...

    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

    输出应该与上面的类似（一些细节用省略号代替）。

注意 _curl_ 的 `-L` 标志，它指示 _curl_ 遵循重定向, 在这种情况下，
服务器返回一个重定向响应（[301 Moved Permanently](https://tools.ietf.org/html/rfc2616#section-10.3.2)）到 `http://edition.cnn.com/politics` 的 HTTP 请求, 重定向响应指示客户端通过 HTTPS 向 `https://edition.cnn.com/politics` 发送附加请求, 对于第二个请求，服务器返回所请求的内容和 _200 OK_ 状态代码。

而对于 _curl_ 命令，这种重定向是透明的，这里有两个问题, 第一个问题是冗余的第一个请求，它使获取 `http://edition.cnn.com/politics` 内容的延迟加倍, 第二个问题是 URL 的路径，在这种情况下是 _politics_ ，以明文形式发送, 如果有攻击者嗅探您的应用程序与 _cnn.com_ 之间的通信，则攻击者会知道您的应用程序获取的 _cnn.com_ 的哪些特定主题和文章, 出于隐私原因，您可能希望阻止攻击者披露此类信息。

在下一节中，您将配置 Istio 以执行 TLS 以解决这两个问题, 在继续下一部分之前清理配置：

{{< text bash >}}
$ kubectl delete serviceentry cnn
{{< /text >}}

## 出口流量的 TLS

1.  定义一个 `ServiceEntry` 以允许流量到 _edition.cnn.com_ ，一个 `VirtualService` 来执行请求端口重写，一个 `DestinationRule` 用于 TLS 发起。

    与上一节中的 `ServiceEntry` 不同，这里使用 HTTP 作为端口 433 上的协议，因为客户端将发送 HTTP 请求，而 Istio 将为它们执行 TLS 发起, 此外，在此示例中，必须将分辨率设置为 DNS 才能正确配置 Envoy。

    最后，请注意 `VirtualService` 使用特定的主机 _edition.cnn.com_ （没有通配符），因为 Envoy 代理需要确切地知道使用 HTTPS 访问哪个主机：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: cnn
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: http-port-for-tls-origination
        protocol: HTTP
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: rewrite-port-for-edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      http:
      - match:
          - port: 80
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: originate-tls-for-edition-cnn-com
    spec:
      host: edition.cnn.com
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: SIMPLE # initiates HTTPS when accessing edition.cnn.com
    EOF
    {{< /text >}}

1. 发送 HTTP 请求到 `http://edition.cnn.com/politics` ，如上一节所述：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

    这次你收到 _200 OK_ , Istio 为 _curl_ 执行了 TLS 发起，因此原始 HTTP 请求作为 HTTPS 转发到 _cnn.com_ , _cnn.com_ 服务器直接返回内容，无需重定向, 您消除了客户端和服务器之间的双重往返，并且请求使网格加密，而没有透露应用程序获取 _cnn.com_ 的 _politics_ 部分这一事实。

    请注意，您使用的命令与上一节中的命令相同, 对于以编程方式访问外部服务的应用程序，代码不会更改, 因此，您可以通过配置 Istio 来获得 TLS 的好处，而无需更改代码行。

## 其他安全因素

请注意，应用程序 `pod` 与本地主机上的 `sidecar` 之间的流量仍未加密, 这意味着如果攻击者能够穿透应用程序的节点，他们仍然可以在节点的本地网络上看到未加密的通信, 在某些环境中，可能存在严格的安全要求，即必须加密所有流量，即使在节点的本地网络上也是如此, 如果有这么严格的要求，应用程序应该只使用 HTTPS（TLS），此任务中描述的 TLS 是不够的。

另请注意，即使对于应用程序发起的 HTTPS ，攻击者也可以通过检查[服务器名称指示（SNI）](https://en.wikipedia.org/wiki/Server_Name_Indication)来了解对 _cnn.com_ 的请求, ）, 在 TLS 握手期间，未加密地发送 _SNI_ 字段, 使用 HTTPS 可防止攻击者了解特定主题和文章，但这并不能阻止攻击者了解 _cnn.com_ 被访问。

## 清理

1.  删除您创建的 Istio 配置项：

    {{< text bash >}}
    $ kubectl delete serviceentry cnn
    $ kubectl delete virtualservice rewrite-port-for-edition-cnn-com
    $ kubectl delete destinationrule originate-tls-for-edition-cnn-com
    {{< /text >}}

1.  关闭 [sleep]({{< github_tree >}}/samples/sleep) 服务：

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}
