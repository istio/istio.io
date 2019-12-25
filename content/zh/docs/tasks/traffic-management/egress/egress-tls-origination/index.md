---
title: Egress TLS Origination
description: 描述如何配置 Istio 对来自外部服务的流量执行 TLS 发起。
keywords: [traffic-management,egress]
weight: 20
aliases:
  - /zh/docs/examples/advanced-gateways/egress-tls-origination/
---

[控制 Egress 流量](/zh/docs/tasks/traffic-management/egress/)的任务向我们展示了位于服务网格内部的应用应如何访问外部（即服务网格之外）的 HTTP 和 HTTPS 服务。
正如该任务所述，[`ServiceEntry`](/zh/docs/reference/config/networking/service-entry/) 用于配置 Istio 以受控的方式访问外部服务。
本示例将演示如何通过配置 Istio 去实现对发往外部服务的流量的 {{< gloss >}}TLS origination{{< /gloss >}}。
若此时原始的流量为 HTTP，则 Istio 会将其转换为 HTTPS 连接。

## 案例{#use-case}

假设有一个遗留应用正在使用 HTTP 和外部服务进行通信。而运行该应用的组织却收到了一个新的需求，该需求要求必须对所有外部的流量进行加密。
此时，使用 Istio 便可通过修改配置实现此需求，而无需更改应用中的任何代码。
该应用可以发送未加密的 HTTP 请求，然后 Istio 将为应用加密请求。

从应用源头发送未加密的 HTTP 请求并让 Istio 执行 TSL 升级的另一个好处是可以产生更好的遥测并为未加密的请求提供更多的路由控制。

## 开始之前{#before-you-begin}

*   根据[安装指南](/zh/docs/setup/)中的说明部署 Istio。

*   启动 [sleep]({{< github_tree >}}/samples/sleep) 示例，该示例将用作外部调用的测试源。

    如果启用了 [Sidecar 的自动注入功能](/zh/docs/setup/additional-setup/sidecar-injection/#automatic-sidecar-injection)，运行：

    {{< text bash >}}
    $ kubectl apply -f @samples/sleep/sleep.yaml@
    {{< /text >}}

    否则在部署 `sleep` 应用之前，您必须手动注入 Sidecar。

    {{< text bash >}}
    $ kubectl apply -f <(istioctl kube-inject -f @samples/sleep/sleep.yaml@)
    {{< /text >}}

    实际上任何可以 `exec` 和 `curl` 的 Pod 都可以用来完成这一任务。

*   创建一个环境变量来保存用于将请求发送到外部服务的 pod 的名称。
    如果您使用 [sleep]({{< github_tree >}}/samples/sleep) 示例，请运行：

    {{< text bash >}}
    $ export SOURCE_POD=$(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name})
    {{< /text >}}

## 配置对外部服务的访问{#configuring-access-to-an-external-service}

首先，使用与 [Egress 流量控制](/zh/docs/tasks/traffic-management/egress/)任务中的相同的技术，配置对外部服务 `edition.cnn.com` 的访问。
但这一次我们将使用单个 `ServiceEntry` 来启用对服务的 HTTP 和 HTTPS 访问。

1.  创建一个 `ServiceEntry` 和 `VirtualService` 以启用对 `edition.cnn.com` 的访问：

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https-port
        protocol: HTTPS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      tls:
      - match:
        - port: 443
          sni_hosts:
          - edition.cnn.com
        route:
        - destination:
            host: edition.cnn.com
            port:
              number: 443
          weight: 100
    EOF
    {{< /text >}}

1.  向外部的 HTTP 服务发送请求：

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

    输出应与上面类似（某些细节用省略号代替）。

请注意 _curl_ 的 `-L` 标志，该标志指示 _curl_ 将遵循重定向。
在这种情况下，服务器将对到 `http://edition.cnn.com/politics` 的 HTTP 请求返回重定向响应 ([301 Moved Permanently](https://tools.ietf.org/html/rfc2616#section-10.3.2))。
而重定向响应将指示客户端使用 HTTPS 向 `https://edition.cnn.com/politics` 重新发送请求。
对于第二个请求，服务器则返回了请求的内容和 _200 OK_ 状态码。

尽管 _curl_ 命令简明地处理了重定向，但是这里有两个问题。
第一个问题是请求冗余，它使获取 `http://edition.cnn.com/politics` 内容的延迟加倍。
第二个问题是 URL 中的路径（在本例中为 _politics_ ）被以明文的形式发送。
如果有人嗅探您的应用与 `edition.cnn.com` 之间的通信，他将会知晓该应用获取了此网站中哪些特定的内容。
而出于隐私的原因，您可能希望阻止这些内容被披露。

通过配置 `Istio` 执行 `TLS` 发起，则可以解决这两个问题。

## 用于 egress 流量的 TLS 发起{#TLS-origination-for-egress-traffic}

1.  重新定义上一节的 `ServiceEntry` 和 `VirtualService` 以重写 HTTP 请求端口，并添加一个 `DestinationRule` 以执行 TLS 发起。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      ports:
      - number: 80
        name: http-port
        protocol: HTTP
      - number: 443
        name: https-port-for-tls-origination
        protocol: HTTPS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: edition-cnn-com
    spec:
      hosts:
      - edition.cnn.com
      http:
      - match:
        - port: 80
        route:
        - destination:
            host: edition.cnn.com
            subset: tls-origination
            port:
              number: 443
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: edition-cnn-com
    spec:
      host: edition.cnn.com
      subsets:
      - name: tls-origination
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

    如您所见 `VirtualService` 将 80 端口的请求重定向到 443 端口，并在相应的 `DestinationRule` 执行 TSL 发起。
    请注意，与上一节中的 `ServiceEntry` 不同，这次 443 端口上的协议是 HTTP，而不是 HTTPS。
    这是因为客户端仅发送 HTTP 请求，而 Istio 会将连接升级到 HTTPS。

1. 如上一节一样，向 `http://edition.cnn.com/politics` 发送 HTTP 请求：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - http://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

    这次将会收到唯一的 _200 OK_ 响应。
    因为 Istio 为 _curl_ 执行了 TSL 发起，原始的 HTTP 被升级为 HTTPS 并转发到 `edition.cnn.com`。
    服务器直接返回内容而无需重定向。
    这消除了客户端与服务器之间的请求冗余，使网格保持加密状态，隐藏了您的应用获取 `edition.cnn.com` 中 _politics_ 的事实。

    请注意，您使用了一些与上一节相同的命令。
    您可以通过配置 Istio，使以编程方式访问外部服务的应用无需更改任何代码即可获得 TLS 发起的好处。

1.  请注意，使用 HTTPS 访问外部服务的应用程序将继续像以前一样工作：

    {{< text bash >}}
    $ kubectl exec -it $SOURCE_POD -c sleep -- curl -sL -o /dev/null -D - https://edition.cnn.com/politics
    HTTP/1.1 200 OK
    Content-Type: text/html; charset=utf-8
    ...
    Content-Length: 151654
    ...
    {{< /text >}}

## 其它安全注意事项{#additional-security-considerations}

由于应用容器与本地 Host 上的 Sidecar 代理之间的流量仍未加密，能够渗透到您应用 Node 的攻击者仍然可以看到未加密 Node 本地网络上的通信。
在某些环境中，严格的安全性要求可能规定所有流量都必须加密，即使在 Node 的本地网络上也是如此。
此时，使用在此示例中描述的 TLS 发起是不能满足要求的，应用应仅使用 HTTPS（TLS）而不是 HTTP。

还要注意，即使应用发起的是 HTTPS 请求，攻击者也可能会通过检查 [Server Name Indication (SNI)](https://en.wikipedia.org/wiki/Server_Name_Indication) 知道客户端正在对 `edition.cnn.com` 发送请求。
_SNI_ 字段在 TLS 握手过程中以未加密的形式发送。
使用 HTTPS 可以防止攻击者知道客户端访问了哪些特点的内容，但并不能阻止攻击者得知客户端访问了 `edition.cnn.com` 站点。

## 清除{#cleanup}

1.  移除您创建的 Istio 配置项:

    {{< text bash >}}
    $ kubectl delete serviceentry edition-cnn-com
    $ kubectl delete virtualservice edition-cnn-com
    $ kubectl delete destinationrule edition-cnn-com
    {{< /text >}}

1.  关闭 [sleep]({{< github_tree >}}/samples/sleep) 服务:

    {{< text bash >}}
    $ kubectl delete -f @samples/sleep/sleep.yaml@
    {{< /text >}}
