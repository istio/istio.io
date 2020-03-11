---
title: 使用外部 Web 服务
description: 描述基于 Istio Bookinfo 示例的简单场景。
publishdate: 2018-01-31
last_update: 2019-04-11
subtitle: HTTPS 流量的出口规则
attribution: Vadim Eisenberg
keywords: [traffic-management,egress,https]
target_release: 1.1
---

在许多情况下，在 _service mesh_ 中的微服务序并不是应用程序的全部，有时，
网格内部的微服务需要使用在服务网格外部的遗留系统提供的功能，虽然我们希望逐步将这些系统迁移到服务网格中。
但是在迁移这些系统之前，必须让服务网格内的应用程序能访问它们。还有其他情况，
应用程序使用外部组织提供的 Web 服务，通常是通过万维网提供的服务。

在这篇博客文章中，我修改了 [Istio Bookinfo 示例应用程序](/zh/docs/examples/bookinfo/)让它可以
从外部 Web 服务（[Google Books APIs](https://developers.google.com/books/docs/v1/getting_started) ）获取图书详细信息。
我将展示如何使用 _mesh-external service entries_ 在 Istio 中启用外部 HTTPS 流量。最后，
我解释了当前与 Istio 出口流量控制相关的问题。

## 初始设定{#initial-setting}

为了演示使用外部 Web 服务的场景，我首先使用安装了 [Istio](/zh/docs/setup/getting-started/) 的
 Kubernetes 集群, 然后我部署 [Istio Bookinfo 示例应用程序](/zh/docs/examples/bookinfo/),
 此应用程序使用 _details_ 微服务来获取书籍详细信息，例如页数和发布者, 原始 _details_ 微服务提供书籍
 详细信息，无需咨询任何外部服务。

此博客文章中的示例命令适用于 Istio 1.0+，无论启用或不启用[双向 TLS](/zh/docs/concepts/security/#mutual-TLS-authentication)。
 Bookinfo 配置文件位于 Istio 发行存档的 `samples/bookinfo` 目录中。

以下是原始 [Bookinfo 示例应用程序](/zh/docs/examples/bookinfo/)中应用程序端到端体系结构的副本。

{{< image width="80%"
    link="/zh/docs/examples/bookinfo/withistio.svg"
    caption="原 Bookinfo 应用程序"
    >}}

执行[部署应用程序](/zh/docs/examples/bookinfo/#deploying-the-application)、[确认应用正在运行](/zh/docs/examples/bookinfo/#confirm-the-app-is-accessible-from-outside-the-cluster)，以及
[应用默认目标规则](/zh/docs/examples/bookinfo/#apply-default-destination-rules)中的步骤部分。

### Bookinfo 使用 HTTPS 访问 Google 图书网络服务{#Bookinfo-with-https-access-to-a-google-books-web-service}

让我们添加一个新版本的 _details_ 微服务，_v2_，从 [Google Books APIs](https://developers.google.com/books/docs/v1/getting_started) 中获取图书详细信息。
它设定了服务容器的 `DO_NOT_ENCRYPT` 环境变量为 `false`。此设置将指示已部署服务使用 HTTPS（而不是 HTTP ）来访问外部服务。

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-details-v2.yaml@ --dry-run -o yaml | kubectl set env --local -f - 'DO_NOT_ENCRYPT=false' -o yaml | kubectl apply -f -
{{< /text >}}

现在，应用程序的更新架构如下所示：

{{< image width="80%"
    link="bookinfo-details-v2.svg"
    caption="Bookinfo 的 details V2 应用程序"
    >}}

请注意，Google Book 服务位于 Istio 服务网格之外，其边界由虚线标记。

现在让我们将指向 _details_ 微服务的所有流量定向到 _details v2_：

{{< text bash >}}
$ kubectl apply -f @samples/bookinfo/networking/virtual-service-details-v2.yaml@
{{< /text >}}

请注意，`VirtualService` 依赖于您在[应用默认目标规则](/zh/docs/examples/bookinfo/#apply-default-destination-rules)部分中创建的目标规则。

在[确定 ingress 的 IP 和端口](/zh/docs/examples/bookinfo/#determine-the-ingress-IP-and-port)之后，
让我们访问应用程序的网页。

糟糕... 页面显示 _Error fetching product details_，而不是书籍详细信息：

{{< image width="80%" link="errorFetchingBookDetails.png" caption="获取产品详细信息的错误消息" >}}

好消息是我们的应用程序没有崩溃, 通过良好的微服务设计，我们没有让**故障扩散**。在我们的例子中，
失败的 _details_ 微服务不会导致 `productpage` 微服务失败, 尽管 _details_ 微服务失败，
仍然提供了应用程序的大多数功能, 我们有**优雅的服务降级**：正如您所看到的，评论和评级正确显示，
应用程序仍然有用。

那可能出了什么问题？ 啊...... 答案是我忘了启用从网格内部到外部服务的流量，在本例中是 Google Book Web 服务。
默认情况下，Istio sidecar 代理（[Envoy proxies](https://www.envoyproxy.io)）
**阻止到集群外目的地的所有流量**, 要启用此类流量，我们必须定义 [mesh-external service entry](/zh/docs/reference/config/networking/service-entry/)。

### 启用对 Google Books 网络服务的 HTTPS 访问{#enable-https-access-to-a-google-books-web-service}

不用担心，让我们定义**网格外部 `ServiceEntry`** 并修复我们的应用程序。您还必须定义 _virtual
service_ 使用 [SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) 对外部服务执行路由。

{{< text bash >}}
$ kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: googleapis
spec:
  hosts:
  - www.googleapis.com
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  location: MESH_EXTERNAL
  resolution: DNS
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: googleapis
spec:
  hosts:
  - www.googleapis.com
  tls:
  - match:
    - port: 443
      sni_hosts:
      - www.googleapis.com
    route:
    - destination:
        host: www.googleapis.com
        port:
          number: 443
      weight: 100
EOF
{{< /text >}}

现在访问应用程序的网页会显示书籍详细信息而不会出现错误：

{{< image width="80%" link="externalBookDetails.png" caption="正确显示书籍详细信息" >}}

您可以查询您的 `ServiceEntry` ：

{{< text bash >}}
$ kubectl get serviceentries
NAME         AGE
googleapis   8m
{{< /text >}}

您可以删除您的 `ServiceEntry` ：

{{< text bash >}}
$ kubectl delete serviceentry googleapis
serviceentry "googleapis" deleted
{{< /text >}}

并在输出中看到删除了 `ServiceEntry`。

删除 `ServiceEntry` 后访问网页会产生我们之前遇到的相同错误，即 _Error fetching product details_,
正如我们所看到的，，与许多其他 Istio 配置一样，`ServiceEntry` 是**动态定义**的 , Istio 运算符可以动态决定
它们允许微服务访问哪些域, 他们可以动态启用和禁用外部域的流量，而无需重新部署微服务。

### 清除对 Google 图书网络服务的 HTTPS 访问权限{#cleanup-of-https-access-to-a-google-books-web-service}

{{< text bash >}}
$ kubectl delete serviceentry googleapis
$ kubectl delete virtualservice googleapis
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-details-v2.yaml@
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo-details-v2.yaml@
{{< /text >}}

## 由 Istio 发起的 TLS{#TLS-origination-by-Istio}

这个故事有一个警告。假设您要监视您的微服务使用 [Google API](https://developers.google.com/apis-explorer/) 的哪个特定集
（[书籍](https://developers.google.com/books/docs/v1/getting_started)，[日历](https://developers.google.com/calendar/)，[任务](https://developers.google.com/tasks/)等）
假设您要强制执行仅允许使用[图书 API](https://developers.google.com/books/docs/v1/getting_started) 的策略。
假设您要监控您的微服务访问的标识符。对于这些监视和策略任务，您需要知道 URL 路径。
考虑例如 URL [`www.googleapis.com/books/v1/volumes?q=isbn:0486424618`](https://www.googleapis.com/books/v1/volumes?q=isbn:0486424618)。
在该网址中，路径段指定了[图书 API](https://developers.google.com/books/docs/v1/getting_started)
`/books` 和路径段的 [ISBN](https://en.wikipedia.org/wiki/International_Standard_Book_Number) 代码
 `/volumes?q=isbn:0486424618`。但是，在 HTTPS 中，所有 HTTP 详细信息（主机名，路径，标头等）都是加密的
sidecar 代理的这种监督和策略执行是无法实现的。Istio 只能通过 [SNI](https://tools.ietf.org/html/rfc3546#section-3.1)（_Server Name Indication_）得知加密请求中的主机名称，在这里就是 `www.googleapis.com`。

为了允许 Istio 基于域执行出口请求的过滤，微服务必须发出 HTTP 请求, 然后，Istio 打开到目标的 HTTPS 连接（执行 TLS 发起）,
根据微服务是在 Istio 服务网格内部还是外部运行，
微服务的代码必须以不同方式编写或以不同方式配置, 这与[最大化透明度](/zh/docs/ops/deployment/architecture/#design-goals)
的 Istio 设计目标相矛盾, 有时我们需要妥协......

下图显示了如何执行外部服务的 HTTPS 流量, 在顶部，Istio 服务网格外部的微服务发送常规 HTTPS 请求，
端到端加密, 在底部，Istio 服务网格内的相同微服务必须在 pod 内发送未加密的 HTTP 请求，
这些请求被 sidecar Envoy 代理拦截 , sidecar 代理执行 TLS 发起，因此 pod 和外部服务之间的流量被加密。

{{< image width="60%"
    link="https_from_the_app.svg"
    caption="对外发起 HTTPS 流量的两种方式：微服务自行发起，或由 Sidecar 代理发起"
    >}}

以下是我们如何在 [Bookinfo 的 details 微服务代码]({{< github_file >}}/samples/bookinfo/src/details/details.rb)
中使用 Ruby [net/http 模块](https://docs.ruby-lang.org/en/2.0.0/Net/HTTP.html)：

{{< text ruby >}}
uri = URI.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:' + isbn)
http = Net::HTTP.new(uri.host, ENV['DO_NOT_ENCRYPT'] === 'true' ? 80:443)
...
unless ENV['DO_NOT_ENCRYPT'] === 'true' then
     http.use_ssl = true
end
{{< /text >}}

当定义 `WITH_ISTIO` 环境变量时，在没有 SSL（普通 HTTP ）的情况下请求会通过 80 端口执行。

我们将 [details v2 的部署配置文件]({{< github_file >}}/samples/bookinfo/platform/kube/bookinfo-details-v2.yaml) 的环境变量 `DO_NOT_ENCRYPT` 设置为 _"true"_。
`container` 部分：

{{< text yaml >}}
env:
- name: DO_NOT_ENCRYPT
  value: "true"
{{< /text >}}

在下一节中，您将配置 TLS 发起以访问外部 Web 服务。

## 具有 TLS 的 Bookinfo 起源于 Google Books 网络服务{#Bookinfo-with-TLS-origination-to-a-google-books-web-service}

1.  部署 _details v2_ 版本，将 HTTP 请求发送到 [Google Books API](https://developers.google.com/books/docs/v1/getting_started)。
    在 [`bookinfo-details-v2.yaml`]({{<github_file>}}/samples/bookinfo/platform/kube/bookinfo-details-v2.yaml) 中，
    `DO_NOT_ENCRYPT` 变量设置为 true。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/platform/kube/bookinfo-details-v2.yaml@
    {{< /text >}}

1.  将指向 _details_ 微服务的流量定向到 _details v2_。

    {{< text bash >}}
    $ kubectl apply -f @samples/bookinfo/networking/virtual-service-details-v2.yaml@
    {{< /text >}}

1.  为 `www.google.apis` 创建网格外部 `ServiceEntry`，virtual service 将目标端口从 80 重写为 443，并执行 TLS 的 `destination rule`。

    {{< text bash >}}
    $ kubectl apply -f - <<EOF
    apiVersion: networking.istio.io/v1alpha3
    kind: ServiceEntry
    metadata:
      name: googleapis
    spec:
      hosts:
      - www.googleapis.com
      ports:
      - number: 80
        name: http
        protocol: HTTP
      - number: 443
        name: https
        protocol: HTTPS
      resolution: DNS
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
      name: rewrite-port-for-googleapis
    spec:
      hosts:
      - www.googleapis.com
      http:
      - match:
        - port: 80
        route:
        - destination:
            host: www.googleapis.com
            port:
              number: 443
    ---
    apiVersion: networking.istio.io/v1alpha3
    kind: DestinationRule
    metadata:
      name: originate-tls-for-googleapis
    spec:
      host: www.googleapis.com
      trafficPolicy:
        loadBalancer:
          simple: ROUND_ROBIN
        portLevelSettings:
        - port:
            number: 443
          tls:
            mode: SIMPLE # 访问 edition.cnn.com 时启动 HTTPS
    EOF
    {{< /text >}}

1.  访问应用程序的网页，并验证显示的书籍详细信息没有错误。

1.  [开启 Envoy 访问记录功能](/zh/docs/tasks/observability/logs/access-log/#enable-envoy-s-access-logging)

1.  检查 _details v2_ 的 sidecar 代理的日志，并查看 HTTP 请求。

    {{< text bash >}}
    $ kubectl logs $(kubectl get pods -l app=details -l version=v2 -o jsonpath='{.items[0].metadata.name}') istio-proxy | grep googleapis
    [2018-08-09T11:32:58.171Z] "GET /books/v1/volumes?q=isbn:0486424618 HTTP/1.1" 200 - 0 1050 264 264 "-" "Ruby" "b993bae7-4288-9241-81a5-4cde93b2e3a6" "www.googleapis.com:80" "172.217.20.74:80"
    EOF
    {{< /text >}}

    请注意日志中的 URL 路径，可以监视路径并根据它来应用访问策略。要了解有关 HTTP 出口流量的监控和访问策略
    的更多信息，请查看[归档博客之出口流量监控之日志](https://archive.istio.io/v0.8/blog/2018/egress-monitoring-access-control/#logging)。

### 清除 TLS 原始数据到 Google Books 网络服务{#cleanup-of-TLS-origination-to-a-google-books-web-service}

{{< text bash >}}
$ kubectl delete serviceentry googleapis
$ kubectl delete virtualservice rewrite-port-for-googleapis
$ kubectl delete destinationrule originate-tls-for-googleapis
$ kubectl delete -f @samples/bookinfo/networking/virtual-service-details-v2.yaml@
$ kubectl delete -f @samples/bookinfo/platform/kube/bookinfo-details-v2.yaml@
{{< /text >}}

### Istio 双向 TLS 的关系{#relation-to-Istio-mutual-TLS}

请注意，在这种情况下，TLS 的源与 Istio 应用的[双向 TLS](/zh/docs/concepts/security/#mutual-TLS-authentication) 无关,
无论 Istio 双向 TLS 是否启用，外部服务的 TLS 源都将起作用 , 保证服务网**内**的服务到服务通信，
并为每个服务提供强大的身份认证, 在此博客文章中的 **外部服务**的情况下，我们有**单向** TLS，
这是用于保护 Web 浏览器和 Web 服务器之间通信的相同机制 , TLS 应用于与外部服务的通信，
以验证外部服务器的身份并加密流量。

## 结论{#conclusion}

在这篇博文中，我演示了 Istio 服务网格中的微服务如何通过 HTTPS 使用外部 Web 服务, 默认情况下，
Istio 会阻止集群外主机的所有流量, 要启用此类流量，请使用 mesh-external, 必须为服务网格创建 `ServiceEntry` ,
可以通过 HTTPS 访问外部站点，当微服务发出 HTTPS 请求时，流量是端到端加密的，但是 Istio 无法监视 HTTP 详细信息，
例如请求的 URL 路径。当微服务发出 HTTP 请求时，Istio 可以监视请求的 HTTP 详细信息并强制执行基于 HTTP 的访问策略。
但是，在这种情况下，微服务和 sidecar 代理之间的流量是未加密的。在具有非常严格的安全要求的组织中，
可以禁止未加密的部分流量。
