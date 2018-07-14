---
title: 使用外部 Web 服务
description: 描述基于 Istio Bookinfo 示例的简单场景
publishdate: 2018-01-31
subtitle: HTTPS 流量的出口规则
attribution: Vadim Eisenberg
weight: 93
keywords: [traffic-management,egress,https]
---

在许多情况下，在 _service mesh_ 中的微服务序并不是应用程序的全部， 有时，网格内部的微服务需要使用在服务网格外部的遗留系统提供的功能， 虽然我们希望逐步将这些系统迁移到服务网格中。 但是在迁移这些系统之前，必须让服务网格内的应用程序能访问它们。 还有其他情况，应用程序使用外部组织提供的 Web 服务，通常是通过万维网提供的服务。

在这篇博客文章中，我修改了[Istio Bookinfo 示例应用程序](/docs/examples/bookinfo/)让它可以从外部 Web 服务（[Google Books APIs](https://developers.google.com/books/docs/v1/getting_started) ）获取图书详细信息。 我将展示如何使用 _egress rule_ 在 Istio 中启用外部 HTTPS 流量。 最后，我解释了当前与 Istio 出口流量控制相关的问题。

## Bookinfo 示例应用程序使用外部的 Web 服务扩展详细信息

### 初始设定

为了演示使用外部 Web 服务的场景，我首先使用安装了 [Istio](/docs/setup/kubernetes/quick-start/#installation-steps) 的 Kubernetes 集群, 然后我部署[Istio Bookinfo 示例应用程序](/docs/examples/bookinfo/), 此应用程序使用 _details_ 微服务来获取书籍详细信息，例如页数和发布者, 原始 _details_ 微服务提供书籍详细信息，无需咨询任何外部服务。

此博客文章中的示例命令与 Istio 0.2+ 一起使用，无论启用或不启用 [Mutual TLS](/docs/concepts/security/mutual-tls/)。

此帖子的场景所需的 Bookinfo 配置文件显示自 [Istio版本0.5](https://github.com/istio/istio/releases/tag/0.5.0)。

Bookinfo 配置文件位于 Istio 发行存档的 `samples/bookinfo/platform/kube` 目录中。

以下是原始[Bookinfo示例应用程序](/docs/examples/bookinfo/)中应用程序端到端体系结构的副本。

{{< image width="80%" ratio="59.08%"
    link="/docs/examples/bookinfo/withistio.svg"
    caption="The Original Bookinfo Application"
    >}}

### Bookinfo 详细信息版本 2

让我们添加一个新版本的 _details_ 微服务，_v2_ ，从[Google Books APIs](https://developers.google.com/books/docs/v1/getting_started)中获取图书详细信息。

{{< text bash >}}
$ kubectl apply -f <(istioctl kube-inject -f @samples/bookinfo/platform/kube/bookinfo-details-v2.yaml@)
{{< /text >}}

现在，应用程序的更新架构如下所示：

{{< image width="80%" ratio="65.16%"
    link="/blog/2018/egress-https/bookinfo-details-v2.svg"
    caption="The Bookinfo Application with details V2"
    >}}

请注意，Google Book 服务位于 Istio 服务网格之外，其边界由虚线标记。

现在让我们使用以下 _route rule_ 将指向 _details_ 微服务的所有流量定向到 _details version v2_：

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: config.istio.io/v1alpha2
kind: RouteRule
metadata:
  name: details-v2
  namespace: default
spec:
  destination:
    name: details
  route:
  - labels:
      version: v2
EOF
{{< /text >}}

在[确定入口IP和端口](/docs/examples/bookinfo/#determining-the-ingress-ip-and-port)之后，让我们访问应用程序的网页。

糟糕...页面显示 _Error fetching product details_，而不是书籍详细信息：

{{< image width="80%" ratio="36.01%"
    link="/blog/2018/egress-https/errorFetchingBookDetails.png"
    caption="The Error Fetching Product Details Message"
    >}}

好消息是我们的应用程序没有崩溃, 通过良好的微服务设计，我们没有让**故障扩散**。 在我们的例子中，失败的 _details_  微服务不会导致 _productpage_ 微服务失败, 尽管 _details_ 微服务失败，仍然提供了应用程序的大多数功能, 我们有**优雅的服务降级**：正如您所看到的，评论和评级正确显示，应用程序仍然有用。

那可能出了什么问题？ 啊......答案是我忘了启用从网格内部到外部服务的流量，在本例中是 Google Book Web服务。 默认情况下，Istio sidecar代理（[Envoy proxies](https://www.envoyproxy.io)）**阻止到集群外目的地的所有流量**, 要启用此类流量，我们必须定义[出口规则](https://archive.istio.io/v0.7/docs/reference/config/istio.routing.v1alpha1/#EgressRule)。

### Google Book 网络服务的出口规则

不用担心，让我们定义**出口规则**并修复我们的应用程序：

{{< text bash >}}
$ cat <<EOF | istioctl create -f -
apiVersion: config.istio.io/v1alpha2
kind: EgressRule
metadata:
  name: googleapis
  namespace: default
spec:
  destination:
      service: "*.googleapis.com"
  ports:
      - port: 443
        protocol: https
EOF
{{< /text >}}

现在访问应用程序的网页会显示书籍详细信息而不会出现错误：

{{< image width="80%" ratio="34.82%"
    link="/blog/2018/egress-https/externalBookDetails.png"
    caption="Book Details Displayed Correctly"
    >}}

请注意，我们的出口规则允许使用 HTTPS 协议在端口 443 上与任何与 _*.googleapis.com_ 匹配的域进行流量传输, 让我们假设为了示例，我们的 Istio 服务网格中的应用程序必须访问 _googleapis.com_ 的多个子域，例如 _www.googleapis.com_ 以及 _fcm.googleapis.com_ , 我们的规则允许流量到 _www.googleapis.com_ 和 _fcm.googleapis.com_，因为它们都匹配  _*.googleapis.com_ , 此**通配符**功能允许我们使用单个出口规则启用到多个域的流量。

我们可以查询我们的出口规则：

{{< text bash >}}
$ istioctl get egressrules
NAME        KIND                                NAMESPACE
googleapis  EgressRule.v1alpha2.config.istio.io default
{{< /text >}}

我们可以删除我们的出口规则：

{{< text bash >}}
$ istioctl delete egressrule googleapis -n default
Deleted config: egressrule googleapis
{{< /text >}}

并在输出中看到删除出口规则。

删除出口规则后访问网页会产生我们之前遇到的相同错误，即_Error fetching product details_, 正如我们所看到的，出口规则是**动态定义**，与许多其他 Istio 配置工件一样 , Istio 运算符可以动态决定它们允许微服务访问哪些域, 他们可以动态启用和禁用外部域的流量，而无需重新部署微服务。

## Istio出口流量控制的问题

### 由 Istio 发起的 TLS

这个故事有一个警告, 在 HTTPS 中，所有 HTTP 详细信息（主机名，路径，标头等）都已加密，因此 Istio 无法知道加密请求的目标域, 那么，Istio 可以通过 [SNI](https://tools.ietf.org/html/rfc3546#section-3.1)（_Server Name Indication_）字段来了解目标域, 但是，此功能尚未在 Istio 中实现, 因此，目前Istio无法基于目标域执行 HTTPS 请求的过滤。

为了允许 Istio 基于域执行出口请求的过滤，微服务必须发出 HTTP 请求, 然后，Istio 打开到目标的 HTTPS 连接（执行 TLS 发起）, 根据微服务是在 Istio 服务网格内部还是外部运行，微服务的代码必须以不同方式编写或以不同方式配置, 这与[最大化透明度](/docs/concepts/what-is-istio/#design-goals)的 Istio 设计目标相矛盾, 有时我们需要妥协......

下图显示了如何执行外部服务的 HTTPS 流量, 在顶部，Istio 服务网格外部的微服务

发送常规 HTTPS 请求，端到端加密, 在底部，Istio 服务网格内的相同微服务必须在 pod 内发送未加密的HTTP请求，这些请求被 sidecar Envoy 代理拦截 , sidecar 代理执行 TLS 发起，因此 pod 和外部服务之间的流量被加密。

{{< image width="80%" ratio="65.16%"
    link="/blog/2018/egress-https/https_from_the_app.svg"
    caption="HTTPS traffic to external services, from outside vs. from inside an Istio service mesh"
    >}}

以下是我们如何在[Bookinfo details microservice code]({{< github_file >}}/samples/bookinfo/src/details/details.rb)中使用Ruby [net/http模块](https://docs.ruby-lang.org/en/2.0.0/Net/HTTP.html)：

{{< text ruby >}}
uri = URI.parse('https://www.googleapis.com/books/v1/volumes?q=isbn:' + isbn)
http = Net::HTTP.new(uri.host, uri.port)
...
unless ENV['WITH_ISTIO'] === 'true' then
     http.use_ssl = true
end
{{< /text >}}

请注意，默认的 HTTPS 端口 `443` 的取值是 `URI.parse` 通过对 URI (https://) 的解析得来的， 当在 Istio 服务网格内运行时，微服务必须向端口 “443” 发出 HTTP 请求，该端口是外部服务侦听的端口。

当定义 `WITH_ISTIO` 环境变量时，请求在没有 SSL（普通 HTTP ）的情况下执行。

我们将 `WITH_ISTIO` 环境变量设置为 _"true"_ [details 的部署配置文件]({{< github_file >}}/samples/bookinfo/platform/kube/bookinfo-details-v2.yaml),

`container`部分：

{{< text yaml >}}
env:
- name: WITH_ISTIO
  value: "true"
{{< /text >}}

#### Istio 双向 TLS 的关系

请注意，在这种情况下，TLS 的源与 Istio 应用的 [双向 TLS](/docs/concepts/security/mutual-tls/) 无关, 无论 Istio mutual TLS 是否启用，外部服务的 TLS 源都将起作用 ,   保证服务网**内**的服务到服务通信，并为每个服务提供强大的身份认证, 在 **外部服务**的情况下，我们有**单向** TLS，这是用于保护 Web 浏览器和 Web 服务器之间通信的相同机制 , TLS 应用于与外部服务的通信，以验证外部服务器的身份并加密流量。

### 恶意微服务威胁

另一个问题是，出口规则不是一个安全方面的功能，它只是开放了到外部服务的通信功能。对基于 HTTP 的协议来说，这些规则是建立在域的基础之上的。Istio 不会检查请求的目标 IP 是否与 Host Header 相匹配。这意味着服务网格内的恶意微服务有能力对 Istio 进行欺骗，使之放行目标为恶意 IP 的流量。攻击方式就是在恶意请求中，将 Host Header 的值设置为 Egress 规则允许的域。

Istio 目前不支持保护出口流量，只能其他地方执行，例如通过防火墙或 Istio 外部的其他代理, 现在，我们正在努力在出口流量上启用混合器安全策略的应用，并防止上述攻击。

### 没有跟踪，遥测和没有 Mixer 检查

请注意，目前不能为出口流量收集跟踪和遥测信, 无法应用 Mixer, 我们正在努力在未来的 Istio 版本中解决这个问题。

## 未来的工作

在我的下一篇博客文章中，我将演示 TCP 流量的 Istio 出口规则，并将显示组合路由规则和出口规则的示例。

在 Istio，我们正在努力使 Istio 出口流量更加安全，特别是在启用出口流量的跟踪，遥测和 Mixer 检查时。

## 结论

在这篇博文中，我演示了 Istio 服务网格中的微服务如何通过 HTTPS 使用外部 Web 服务, 默认情况下，Istio 会阻止群集外主机的所有流量, 要启用此类流量，必须为服务网格创建出口规则, 可以通过 HTTPS 访问外部站点，但是微服务必须发出 HTTP 请求，而 Istio 将执行 TLS 发起, 目前，没有为出口流量启用跟踪，遥测和混合器检查, 出口规则目前不是安全功能，因此需要额外的机制来保护出口流量, 我们正在努力为将来版本中的出口流量启用日志记录/遥测和安全策略。

要了解有关 Istio 出口流量控制的更多信息，请参阅[控制出口流量任务](/docs/tasks/traffic-management/egress/)。
