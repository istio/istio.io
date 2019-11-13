---
title: 流量管理
description: 描述 Istio 多样的流量路由和控制的特性。
weight: 20
keywords: [traffic-management,pilot, envoy-proxies, service-discovery, load-balancing]
aliases:
    - /zh/docs/concepts/traffic-management/pilot
    - /zh/docs/concepts/traffic-management/rules-configuration
    - /zh/docs/concepts/traffic-management/fault-injection
    - /zh/docs/concepts/traffic-management/handling-failures
    - /zh/docs/concepts/traffic-management/load-balancing
    - /zh/docs/concepts/traffic-management/request-routing
    - /zh/docs/concepts/traffic-management/pilot.html
---

Istio 的流量路由规则可以让您很容易的控制服务之间的流量和 API 调用。Istio 简化了服务级别属性的配置，比如熔断器、超时和重试，并且能力轻松的设置重要的任务，如 A/B 测试、金丝雀发布、基于百分比流量切分的分段发布等。它还提供开箱即用的故障恢复特性，帮助您的应用程序更好的应对依赖服务或网络的故障。

Istio的流量管理模型基于和服务一起部署的 {{< gloss >}}Envoy{{</ gloss >}} 代理。网格内的服务发送和接收的所有流量（{{< gloss >}}数据平面{{</ gloss >}}流量 ）都由 Envoy 代理，这使控制网格内的流量变得异常简单，而且不需要对服务做任何的更改。

如果您对本节中描述的功能特性是如何工作的感兴趣的话，可以在[架构概述](/zh/docs/ops/architecture/)中找到关于 Istio 的流量管理实现的更多信息。这部分只介绍 Istio 的流量管理特性。

## Istio 流量管理介绍 {#introducing-istio-traffic-management}

为了在网格中导流，Istio 需要知道所有的 endpoint 在哪里，它们属于哪个服务。为了定位到{{< gloss >}}服务注册{{</ gloss >}}中，Istio 会连接到一个服务发现系统。例如，如果您在 Kubernetes 集群上安装了 Istio，那么它将自动检测该集群中的服务和 endpoint。

使用此服务注册中心，Envoy 代理可以将流量定向到相关服务。大多数基于微服务的应用程序，每个服务的工作负载都有多个实例来处理流量，有时称为负载均衡池。默认情况下，Envoy 代理使用轮询方式将请求分发到每个服务的负载平衡池，请求被依次发送给每个池子，服务实例收到请求后返回到池的顶部。

Istio 基本的服务发现和负载均衡能力为您提供了一个可用的服务网格，但 Istio 能做到的远比这多的多。在许多情况下，您可能希望对网格的流量情况进行更细粒度的控制。作为 A/B 测试的一部分，您可能希望将特定百分比的流量定向到新版本的服务，或者为特定的服务实例子集应用不同的负载均衡策略。您可能还希望对进出网格的流量应用特殊的规则，或者将网格的外部依赖项添加到服务注册中心。通过使用 Istio 的流量管理 API 将流量配置添加到 Istio，您就可以完成所有这些甚至更多的工作。

和其他 Istio 配置一样，这些 API 也使用 Kubernetes 的自定义资源定义（{{< gloss >}}CRDs{{</ gloss >}}）来声明，你可以像示例中看到的那样使用 YAML 进行配置。

本章节的其余部分将分别介绍每个流量管理 API 以及如何使用它们。这些资源包括：

- [虚拟服务](#virtual-services)
- [目标规则](#destination-rules)
- [网关](#gateways)
- [服务入口](#service-entries)
- [Sidecar](#sidecars)

指南也对构建在 API 资源内的[网络弹性和测试](#network-resilience-and-testing)做了概述。 

## 虚拟服务 {#virtual-services}

[虚拟服务](/zh/docs/reference/config/networking/virtual-service/#VirtualService)和[目标规则](#destination-rules)是 Istio 流量路由功能的关键拼图。虚拟服务让您配置如何在服务网格内将请求路由到服务，这基于 Istio 和平台提供的基本的连通性和服务发现能力。每个虚拟服务由一组按顺序执行的路由规则组成，Istio 将每个给定的请求匹配到虚拟服务指定的实际目标地址。您的网格可以有多个虚拟服务，也可以没有，取决于您的使用场景。

### 为什么使用虚拟服务？ {#why-use-virtual-services}

Istio 的流量管理变得灵活且强大，虚拟服务发挥了关键作用。通过把客户端发送请求和实际的目标工作负载完全的解耦来做到的这一点。虚拟服务还提供了丰富的方式来指定不同的流量路由规则，用于向这些工作负载发送流量。

为什么这如此有用？没有虚拟服务，就像在介绍中所说，Envoy 在所有的服务实例中使用轮询的负载均衡进行请求分发。你可以用你对工作负载的了解来改善这种行为。例如，有些可能代表不同的版本。这在 A/B 测试中可能有用，您可能希望在其中配置基于不同服务版本的百分比流量路由，或指引从内部用户到特定实例集的流量。

使用虚拟服务，您可以为一个或多个主机名指定流量行为。在虚拟服务中使用路由规则，告诉 Envoy 如何发送
虚拟服务的流量到适当的目标。路由目标地址可以是相同服务的版本，也可以是完全不同的服务。

一个典型的用例是将流量发送到服务的不同版本，指定为服务子集。客户端将请求发送到虚拟服务主机好像这是一个单一的实体，然后 Envoy 根据虚拟服务规则把流量路由到不同的版本。例如，“20%的调用转到
新版本”或“这些用户的调用转到版本 2”。这允许你创建一个金丝雀发布，逐步增加发送到新服务版本的流量百分比。流量路由完全独立于实例部署，这意味着实现新服务版本的实例可以根据流量的负载来伸缩，完全不影响流量路由。相比之下，像 Kubernetes 这样的容器编排平台只支持基于实例缩放的流量分发，这会很快变得复杂。你可以在[使用  Istio 进行金丝雀部署](/zh/blog/2017/0.1-canary/)的文章里阅读到更多用虚拟服务实现金丝雀部署的内容。

虚拟服务可以让你：

-   通过单个虚拟服务处理多个应用程序服务。如果您的网格使用 Kubernetes，可以配置一个虚拟服务处理特定namespace中的所有服务。映射单一的虚拟服务到多个“真实”服务特别有用，可以在不需要客户适应转换的情况下，将单体应用转换为微服务构建的复合应用系统。您的路由规则可以指定为“对这些 `monolith.com` 的 URI 调用转到`microservice A`”等等。你可以[下面的一个示例](#more-about-routing-rules)看到它是如何工作的。
-   配置流量规则和[网关](/zh/docs/concepts/traffic-management/#gateways)整合来控制出入流量。

在某些情况下，您还需要配置目标规则来使用这些规则特性，因为这是指定服务子集的地方。指定的服务子集和其他特定目标策略彼此独立，这让您可以在虚拟服务间重用它们。在下一章节你可以找到更多关于目标规则的内容。

### 虚拟服务示例 {#virtual-service-example}

下面的虚拟服务根据请求是否来自特定的用户，把它们路由到服务的不同版本。
{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
    http:
  - match:
    - headers:
        end-user:
          exact: jason
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v3
{{< /text >}}

#### hosts 字段 {#the-hosts-field}

The `hosts` field lists the virtual service’s hosts - in other words, the user-addressable
destination or destinations that these routing rules apply to. This is the
address or addresses the client uses when sending requests to the service.

{{< text yaml >}}
hosts:
- reviews
{{< /text >}}

虚拟服务主机名可以是IP地址、DNS名称，也可以取决于
平台，一个短名称(例如Kubernetes服务的短名称)，
隐式或显式地发送到完全限定域名(FQDN)。你也可以
使用通配符(“\*”)前缀，让您创建一组路由规则
所有匹配的服务。虚拟服务主机实际上不必是
Istio服务注册表，它们只是虚拟目的地。这让你可以建模
网格内没有可路由项的虚拟主机的流量。
The virtual service hostname can be an IP address, a DNS name, or, depending on
the platform, a short name (such as a Kubernetes service short name) that resolves,
implicitly or explicitly, to a fully qualified domain name (FQDN). You can also
use wildcard ("\*") prefixes, letting you create a single set of routing rules for
all matching services. Virtual service hosts don't actually have to be part of the
Istio service registry, they are simply virtual destinations. This lets you model
traffic for virtual hosts that don't have routable entries inside the mesh.

#### 路由规则 {#routing-rules}

`http`部分包含虚拟服务的路由规则
匹配发送的HTTP/1.1、HTTP2和gRPC流量的路由条件和操作
到在hosts字段中指定的目的地(也可以使用“tcp”和
' tls '节，为[TCP]和未终止的[tls]流量配置路由规则)。路由规则由您希望流量到达的目的地组成
根据您的用例，执行零个或多个匹配条件。
The `http` section contains the virtual service’s routing rules, describing
match conditions and actions for routing HTTP/1.1, HTTP2, and gRPC traffic sent
to the destination(s) specified in the hosts field (you can also use `tcp` and
`tls` sections to configure routing rules for
[TCP](/zh/docs/reference/config/networking/virtual-service/#TCPRoute) and
unterminated
[TLS](/zh/docs/reference/config/networking/virtual-service/#TLSRoute)
traffic). A routing rule consists of the destination where you want the traffic
to go and zero or more match conditions, depending on your use case.

##### 匹配条件 {#match-condition}

示例中的第一个路由规则有一个条件，因此以
“匹配”。在本例中，您希望此路由应用于来自的所有请求
用户“jason”，所以您使用“header”、“终端用户”和“精确”字段进行选择
适当的请求。
The first routing rule in the example has a condition and so begins with the
`match` field. In this case you want this routing to apply to all requests from
the user "jason", so you use the `headers`, `end-user`, and `exact` fields to select
the appropriate requests.

{{< text yaml >}}
- match:
   - headers:
       end-user:
         exact: jason
{{< /text >}}

##### Destination {#destination}

route部分的“destination”字段指定了实际的目的地
符合此条件的流量。与虚拟服务的主机不同
目的地的主机必须是存在于Istio服务中的实际目的地
注册表或特使将不知道将流量发送到哪里。这可以是一个网格
使用服务条目添加代理或非网格服务的服务。在这个
如果我们在Kubernetes上运行，主机名是Kubernetes服务名:
The route section’s `destination` field specifies the actual destination for
traffic that matches this condition. Unlike the virtual service’s host(s), the
destination’s host must be a real destination that exists in Istio’s service
registry or Envoy won’t know where to send traffic to it. This can be a mesh
service with proxies or a non-mesh service added using a service entry. In this
case we’re running on Kubernetes and the host name is a Kubernetes service name:

{{< text yaml >}}
route:
- destination:
    host: reviews
    subset: v2
{{< /text >}}

请注意，在本文和本页上的其他示例中，我们使用Kubernetes的短名称表示
目的主机的简单性。在计算此规则时，Istio添加一个基于域后缀的规则
包含要获取的路由规则的虚拟服务的名称空间
主机的完全限定名。在我们的示例中使用简短的名称
也意味着您可以复制并在任何您喜欢的名称空间中尝试它们。
Note in this and the other examples on this page, we use a Kubernetes short name for the
destination hosts for simplicity. When this rule is evaluated, Istio adds a domain suffix based
on the namespace of the virtual service that contains the routing rule to get
the fully qualified name for the host. Using short names in our examples
also means that you can copy and try them in any namespace you like.

{{< warning >}}
只有在。时才可以使用这样的短名称
目标主机和虚拟服务实际上位于相同的Kubernetes中
名称空间。因为使用Kubernetes的短名称会导致
错误配置，我们建议您指定完全限定的主机名
生产环境中。
Using short names like this only works if the
destination hosts and the virtual service are actually in the same Kubernetes
namespace. Because using the Kubernetes short name can result in
misconfigurations, we recommend that you specify fully qualified host names in
production environments.
{{< /warning >}}

目的地部分还指定Kubernetes服务的哪个子集
要将符合此规则条件的请求转到，在本例中为
名叫v2子集。您将在有关的部分中看到如何定义服务子集
(目的地规则)(# destination-rules)。
The destination section also specifies which subset of this Kubernetes service
you want requests that match this rule’s conditions to go to, in this case the
subset named v2. You’ll see how you define a service subset in the section on
[destination rules](#destination-rules) below.

#### 路由规则优先级 {#routing-rule-precedence}

属性按从上到下的顺序**计算路由规则
虚拟服务定义中的第一条规则被赋予最高优先级。在
在这种情况下，您希望任何与第一个路由规则不匹配的内容都转到a
默认目的地，在第二条规则中指定。因为这个，第二个
rule没有匹配条件，只是将流量导向v3子集。
Routing rules are **evaluated in sequential order from top to bottom**, with the
first rule in the virtual service definition being given highest priority. In
this case you want anything that doesn't match the first routing rule to go to a
default destination, specified in the second rule. Because of this, the second
rule has no match conditions and just directs traffic to the v3 subset.

{{< text yaml >}}
- route:
  - destination:
      host: reviews
      subset: v3
{{< /text >}}

We recommend providing a default "no condition" or weight-based rule (described
below) like this as the last rule in each virtual service to ensure that traffic
to the virtual service always has at least one matching route.

### 路由规则的更多内容 {#more-about-routing-rules}

正如上面所看到的，路由规则是路由特定内容的强大工具
特定目的地流量的子集。您可以设置匹配条件
流量端口、头字段、uri等等。例如，这个虚拟服务
让用户发送流量到两个独立的服务，评级和评论，就好像
它们是http://bookinfo.com/这个更大的虚拟服务的一部分
虚拟服务规则根据请求uri和直接请求匹配流量
适当的服务。
As you saw above, routing rules are a powerful tool for routing particular
subsets of traffic to particular destinations. You can set match conditions on
traffic ports, header fields, URIs, and more. For example, this virtual service
lets users send traffic to two separate services, ratings and reviews, as if
they were part of a bigger virtual service at `http://bookinfo.com/.` The
virtual service rules match traffic based on request URIs and direct requests to
the appropriate service.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
    - bookinfo.com
  http:
  - match:
    - uri:
        prefix: /reviews
    route:
    - destination:
        host: reviews
  - match:
    - uri:
        prefix: /ratings
    route:
    - destination:
        host: ratings
...

  http:
  - match:
      sourceLabels:
        app: reviews
    route:
...
{{< /text >}}

For some match conditions, you can also choose to select them using the exact
value, a prefix, or a regex.

您可以将多个匹配条件添加到同一个“匹配”块中
条件，或将多个匹配块添加到同一规则或您的条件中。
对于任何给定的虚拟服务，也可以有多个路由规则。这
允许您使您的路由条件复杂或简单，因为您喜欢在一个
单一的虚拟服务。匹配条件字段及其可能值的完整列表
值可以在引用中找到
You can add multiple match conditions to the same `match` block to AND your
conditions, or add multiple match blocks to the same rule to OR your conditions.
You can also have multiple routing rules for any given virtual service. This
lets you make your routing conditions as complex or simple as you like within a
single virtual service. A full list of match condition fields and their possible
values can be found in the
[`HTTPMatchRequest` reference](/zh/docs/reference/config/networking/virtual-service/#HTTPMatchRequest).

In addition to using match conditions, you can distribute traffic
by percentage "weight". This is useful for A/B testing and canary rollouts:

{{< text yaml >}}
spec:
  hosts:
  - reviews
    http:
  - route:
    - destination:
        host: reviews
        subset: v1
      weight: 75
    - destination:
        host: reviews
        subset: v2
      weight: 25
{{< /text >}}

You can also use routing rules to perform some actions on the traffic, for
example:

-   Append or remove headers.
-   Rewrite the URL.
-   Set a [retry policy](#retries) for calls to this destination.

To learn more about the actions available, see the
[`HTTPRoute` reference](/zh/docs/reference/config/networking/virtual-service/#HTTPRoute).

## 目标规则 {#destination-rules}

与[虚拟服务](#虚拟服务)一起，
(目的地规则)(/ zh型/ docs /引用/ config /网络/目的地规定/ # DestinationRule)
是Istio流量路由功能的关键部分。你可以想到
虚拟服务，即您如何将您的流量**路由到**给定的目的地，以及
然后您使用目标规则来配置会发生什么流量** *
目的地。目标规则应用于虚拟服务路由规则之后
因此，它们适用于交通的“真正”目的地。
Along with [virtual services](#virtual-services),
[destination rules](/zh/docs/reference/config/networking/destination-rule/#DestinationRule)
are a key part of Istio’s traffic routing functionality. You can think of
virtual services as how you route your traffic **to** a given destination, and
then you use destination rules to configure what happens to traffic **for** that
destination. Destination rules are applied after virtual service routing rules
are evaluated, so they apply to the traffic’s "real" destination.

特别是，您可以使用目标规则来指定指定的服务子集
将给定服务的所有实例按版本分组。你可以使用这些
服务子集在虚拟服务的路由规则中进行控制
到服务的不同实例的流量。
In particular, you use destination rules to specify named service subsets, such
as grouping all a given service’s instances by version. You can then use these
service subsets in the routing rules of virtual services to control the
traffic to different instances of your services.

目的地规则还允许您在呼叫时自定义特使的流量策略
整个目标服务或特定服务子集，如您的
首选负载平衡模式，TLS安全模式，或断路器设置。
属性中可以看到目标规则选项的完整列表
(目的地规则参考)(/ zh型/ docs /引用/ config /网络/目的地规定)。
Destination rules also let you customize Envoy’s traffic policies when calling
the entire destination service or a particular service subset, such as your
preferred load balancing model, TLS security mode, or circuit breaker settings.
You can see a complete list of destination rule options in the
[Destination Rule reference](/zh/docs/reference/config/networking/destination-rule/).

### 负载均衡选项

默认情况下，Istio使用循环负载平衡策略，其中每个服务
实例池中的实例依次获取请求。Istio也支持
以下模型，您可以在针对a的请求的目标规则中指定这些模型
特定服务或服务子集。
By default, Istio uses a round-robin load balancing policy, where each service
instance in the instance pool gets a request in turn. Istio also supports the
following models, which you can specify in destination rules for requests to a
particular service or service subset.

-   Random: Requests are forwarded at random to instances in the pool.
-   Weighted: Requests are forwarded to instances in the pool according to a
    specific percentage.
-   Least requests: Requests are forwarded to instances with the least number of
    requests.

See the
[Envoy load balancing documentation](https://www.envoyproxy.io/zh/docs/envoy/v1.5.0/intro/arch_overview/load_balancing)
for more information about each option.

### 目标规则示例 {#destination-rule-example}

The following example destination rule configures three different subsets for
the `my-svc` destination service, with different load balancing policies:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: my-destination-rule
spec:
  host: my-svc
  trafficPolicy:
    loadBalancer:
      simple: RANDOM
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
  - name: v3
    labels:
      version: v3
{{< /text >}}

每个子集都是基于一个或多个“标签”定义的，在Kubernetes中是这样的
附加到对象(如Pods)上的键/值对。这些标签
应用于Kubernetes服务的部署作为“元数据”来识别
不同的版本。

除了定义子集之外，此目标规则还具有默认流量
此目标中的所有子集的策略，以及特定于子集的策略
只覆盖那个子集。默认策略，在“子集”上面定义
字段，为“v1”和“v3”子集设置一个简单的随机负载均衡器。在
' v2 '策略中，循环负载均衡器被指定在相应的
子集的领域。
Each subset is defined based on one or more `labels`, which in Kubernetes are
key/value pairs that are attached to objects such as Pods. These labels are
applied in the Kubernetes service’s deployment as `metadata` to identify
different versions.

As well as defining subsets, this destination rule has both a default traffic
policy for all subsets in this destination and a subset-specific policy that
overrides it for just that subset. The default policy, defined above the `subsets`
field, sets a simple random load balancer for the `v1` and `v3` subsets. In the
`v2` policy, a round-robin load balancer is specified in the corresponding
subset’s field.

## Gateways {#gateways}

你使用一个[网关](/zh/docs/reference/config/networking/gateway/# gateway)
管理入站和出站流量为您的网格，让您指定
要进入或离开网格的流量。应用网关配置
而不是运行在网格边缘的独立特使代理
比sidecar特使代理运行在您的服务工作负载。
You use a [gateway](/zh/docs/reference/config/networking/gateway/#Gateway) to
manage inbound and outbound traffic for your mesh, letting you specify which
traffic you want to enter or leave the mesh. Gateway configurations are applied
to standalone Envoy proxies that are running at the edge of the mesh, rather
than sidecar Envoy proxies running alongside your service workloads.


与控制进入系统的流量的其他机制不同，例如
Kubernetes Ingress api, Istio网关让您充分利用和
Istio的流量路由灵活性。你可以这么做，因为Istio是网关
资源只是让您配置层4-6负载平衡属性，如
要公开的端口、TLS设置等等。而不是相加
应用程序层流量路由(L7)到相同的API资源，您绑定一个
常规Istio[虚拟服务](#虚拟服务)到网关。这允许您
基本上是管理网关流量，就像在一个Istio中的任何其他数据平面流量一样
网。
Unlike other mechanisms for controlling traffic entering your systems, such as
the Kubernetes Ingress APIs, Istio gateways let you use the full power and
flexibility of Istio’s traffic routing. You can do this because Istio’s Gateway
resource just lets you configure layer 4-6 load balancing properties such as
ports to expose, TLS settings, and so on. Then instead of adding
application-layer traffic routing (L7) to the same API resource, you bind a
regular Istio [virtual service](#virtual-services) to the gateway. This lets you
basically manage gateway traffic like any other data plane traffic in an Istio
mesh.

网关主要用于管理进入流量，但你也可以
出口网关进行配置。出口网关允许您配置专用出口
节点的流量离开网格，让您限制哪些服务可以或
应该访问外部网络，还是启用
[安全控制出口交通](/blog/2019/egress-traffic-control-in-istio-part-1/)
例如，为您的网格添加安全性。你也可以使用网关
配置一个纯粹的内部代理。
Gateways are primarily used to manage ingress traffic, but you can also
configure egress gateways. An egress gateway lets you configure a dedicated exit
node for the traffic leaving the mesh, letting you limit which services can or
should access external networks, or to enable
[secure control of egress traffic](/blog/2019/egress-traffic-control-in-istio-part-1/)
to add security to your mesh, for example. You can also use a gateway to
configure a purely internal proxy.

Istio提供一些预先配置的网关代理部署
(istio-ingressgateway和istio-egressgateway)
如果你使用我们的[演示安装](/zh/docs/setup/install/kubernetes/)，
而只有入口网关与我们的部署
[默认或sds配置文件](/zh/docs/setup/additional-setup/config-profiles/)你
可以将您自己的网关配置应用到这些部署或部署
配置您自己的网关代理。
Istio provides some preconfigured gateway proxy deployments
(`istio-ingressgateway` and `istio-egressgateway`) that you can use - both are
deployed if you use our [demo installation](/zh/docs/setup/install/kubernetes/),
while just the ingress gateway is deployed with our
[default or sds profiles.](/zh/docs/setup/additional-setup/config-profiles/) You
can apply your own gateway configurations to these deployments or deploy and
configure your own gateway proxies.

### Gateway 示例 {#gateway-example}

The following example shows a possible gateway configuration for external HTTPS
ingress traffic:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: ext-host-gwy
spec:
  selector:
    app: my-gateway-controller
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - ext-host.example.com
    tls:
      mode: SIMPLE
      serverCertificate: /tmp/tls.crt
      privateKey: /tmp/tls.key
{{< /text >}}

This gateway configuration lets HTTPS traffic from `ext-host.example.com` into the mesh on
port 443, but doesn’t specify any routing for the traffic.

To specify routing and for the gateway to work as intended, you must also bind
the gateway to a virtual service. You do this using the virtual service’s
`gateways` field, as shown in the following example:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: virtual-svc
spec:
  hosts:
  - ext-host.example.com
    gateways:
    - ext-host-gwy
{{< /text >}}

You can then configure the virtual service with routing rules for the external
traffic.

## 服务入口 {#service-entries}

你使用
[服务条目](/zh/docs/reference/config/networking/service-entry/#ServiceEntry)来添加
Istio内部维护的服务注册表条目。在你添加
服务入口，特使代理可以向服务发送流量，就好像它
是你的服务。配置服务条目允许您进行管理
网格外运行服务的流量，包括以下任务:
You use a
[service entry](/zh/docs/reference/config/networking/service-entry/#ServiceEntry) to add
an entry to the service registry that Istio maintains internally. After you add
the service entry, the Envoy proxies can send traffic to the service as if it
was a service in your mesh. Configuring service entries allows you to manage
traffic for services running outside of the mesh, including the following tasks:

-   Redirect and forward traffic for external destinations, such as APIs
    consumed from the web, or traffic to services in legacy infrastructure.
-   Define [retry](#retries), [timeout](#timeouts), and
    [fault injection](#fault-injection) policies for external destinations.
-   Add a service running in a Virtual Machine (VM) to the mesh to
    [expand your mesh](/zh/docs/examples/virtual-machines/single-network/#running-services-on-the-added-vm).
-   Logically add services from a different cluster to the mesh to configure a
    [multicluster Istio mesh](/zh/docs/setup/install/multicluster/gateways/#configure-the-example-services)
    on Kubernetes.

您不需要为需要的每个外部服务添加服务条目
您的网格服务使用。默认情况下，Istio将特使代理配置为
将请求传递给未知服务。但是，您不能使用Istio功能
控制没有在mesh中注册的目的地的流量。
You don’t need to add a service entry for every external service that you want
your mesh services to use. By default, Istio configures the Envoy proxies to
passthrough requests to unknown services. However, you can’t use Istio features
to control the traffic to destinations that aren't registered in the mesh.

### 服务入口示例 {#service-entry-example}

The following example mesh-external service entry adds the `ext-resource`
external dependency to Istio’s service registry:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: svc-entry
spec:
  hosts:
  - ext-svc.example.com
    ports:
  - number: 443
    name: https
    protocol: HTTPS
    location: MESH_EXTERNAL
    resolution: DNS
{{< /text >}}

You specify the external resource using the `hosts` field. You can qualify it
fully or use a wildcard prefixed domain name.

您可以配置虚拟服务和目标规则来控制a的流量
以更细粒度的方式输入服务，与您配置流量的方式相同
网格中的任何其他服务。例如，下面的目标规则
将通信路由配置为使用相互TLS来保护到的连接
我们使用服务条目配置的外部服务:
You can configure virtual services and destination rules to control traffic to a
service entry in a more granular way, in the same way you configure traffic for
any other service in the mesh. For example, the following destination rule
configures the traffic route to use mutual TLS to secure the connection to the
`ext-svc.example.com` external service that we configured using the service entry:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ext-res-dr
spec:
  host: ext-svc.example.com
  trafficPolicy:
    tls:
      mode: MUTUAL
      clientCertificate: /etc/certs/myclientcert.pem
      privateKey: /etc/certs/client_private_key.pem
      caCertificates: /etc/certs/rootcacerts.pem
{{< /text >}}

See the
[Service Entry reference](/zh/docs/reference/config/networking/service-entry)
for more possible configuration options.

## Sidecars {#sidecars}

By default, Istio configures every Envoy proxy to accept traffic on all the
ports of its associated workload, and to reach every workload in the mesh when
forwarding traffic. You can use a [sidecar](/zh/docs/reference/config/networking/sidecar/#Sidecar) configuration to do the following:

-   Fine-tune the set of ports and protocols that an Envoy proxy accepts.
-   Limit the set of services that the Envoy proxy can reach.

你可能想要在更大的应用中像这样限制边车的可达性，
将每个代理都配置为可以访问网格中的所有其他服务
由于高内存使用量，可能会影响网格的性能。

可以指定希望将sidecar配置应用于所有工作负载
或选择特定的工作负载
“workloadSelector”。例如，下面的sidecar配置进行配置
“bookinfo”名称空间中的所有服务只到达在
相同的名称空间和Istio控制平面(当前需要使用Istio控制平面)
政策和遥测技术特点):
You might want to limit sidecar reachability like this in larger applications,
where having every proxy configured to reach every other service in the mesh can
potentially affect mesh performance due to high memory usage.

You can specify that you want a sidecar configuration to apply to all workloads
in a particular namespace, or choose specific workloads using a
`workloadSelector`. For example, the following sidecar configuration configures
all services in the `bookinfo` namespace to only reach services running in the
same namespace and the Istio control plane (currently needed to use Istio’s
policy and telemetry features):

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default
  namespace: bookinfo
spec:
  egress:
  - hosts:
    - "./*"
    - "istio-system/*"
{{< /text >}}

See the [Sidecar reference](/zh/docs/reference/config/networking/sidecar/)
for more details.

## 网络弹性和测试 {#network-resilience-and-testing}

除了帮助你引导你的网格周围的交通，Istio还提供了选择
可以动态配置的故障恢复和故障注入功能
在运行时。使用这些特性可以帮助您的应用程序可靠地运行，
确保服务网格能够容忍故障节点并进行预防
从级联到其他节点的局部故障。
As well as helping you direct traffic around your mesh, Istio provides opt-in
failure recovery and fault injection features that you can configure dynamically
at runtime. Using these features helps your applications operate reliably,
ensuring that the service mesh can tolerate failing nodes and preventing
localized failures from cascading to other nodes.

### 超时 {#timeouts}

超时是特使代理应该等待的回复时间
一个给定的服务，确保服务不会等待回复
在可预测的时间范围内调用成功或失败。的
HTTP请求的默认超时时间是15秒，这意味着如果服务
15秒内没有响应，通话失败。

对于某些应用程序和服务，Istio的默认超时可能不是
合适的。例如，超时太长可能会导致过度超时
等待失败服务的响应的延迟，而超时
太短可能会导致在等待a时不必要地失败
涉及多个返回服务的操作。找到并使用您的最佳超时时间
通过设置，Istio可以轻松地动态调整每个服务的超时
基本使用[虚拟服务](#虚拟服务)而无需编辑您的
服务代码。这里有一个虚拟服务，它指定了10秒的超时时间
呼叫评级服务的v1子集:
A timeout is the amount of time that an Envoy proxy should wait for replies from
a given service, ensuring that services don’t hang around waiting for replies
indefinitely and that calls succeed or fail within a predictable timeframe. The
default timeout for HTTP requests is 15 seconds, which means that if the service
doesn’t respond within 15 seconds, the call fails.

For some applications and services, Istio’s default timeout might not be
appropriate. For example, a timeout that is too long could result in excessive
latency from waiting for replies from failing services, while a timeout that is
too short could result in calls failing unnecessarily while waiting for an
operation involving multiple services to return. To find and use your optimal timeout
settings, Istio lets you easily adjust timeouts dynamically on a per-service
basis using [virtual services](#virtual-services) without having to edit your
service code. Here’s a virtual service that specifies a 10 second timeout for
calls to the v1 subset of the ratings service:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
    http:
  - route:
    - destination:
        host: ratings
        subset: v1
    timeout: 10s
{{< /text >}}

### 重试 {#retries}

重试设置指定特使代理尝试的最大次数
如果初始调用失败，则连接到服务。重试可以增强服务
确保调用不会失败，从而提高可用性和应用程序性能
永久地由于暂时的问题，如暂时超载
服务或网络。重试之间的间隔(25ms+)是可变的
由Istio自动确定，防止被调用服务的存在
不知所措的请求。默认情况下，特使代理不会尝试这样做
在第一次失败后重新连接到服务。

与超时一样，Istio的默认重试行为可能不适合您的应用程序
延迟方面的需求(对失败的服务进行过多的重试会降低速度
)或可用性。也像超时，你可以调整你的重试设置
在[虚拟服务](#虚拟服务)中的每个服务基础，而不必
触摸您的服务代码。您还可以进一步细化您的重试行为
添加每次重试超时，指定要等待的时间量
每次重试都试图成功连接到服务。下面的例子
事件后最多配置3次重试以连接到此服务子集
初始调用失败，每个调用超时2秒。
A retry setting specifies the maximum number of times an Envoy proxy attempts to
connect to a service if the initial call fails. Retries can enhance service
availability and application performance by making sure that calls don’t fail
permanently because of transient problems such as a temporarily overloaded
service or network. The interval between retries (25ms+) is variable and
determined automatically by Istio, preventing the called service from being
overwhelmed with requests. By default, the Envoy proxy doesn’t attempt to
reconnect to services after a first failure.

Like timeouts, Istio’s default retry behavior might not suit your application
needs in terms of latency (too many retries to a failed service can slow things
down) or availability. Also like timeouts, you can adjust your retry settings on
a per-service basis in [virtual services](#virtual-services) without having to
touch your service code. You can also further refine your retry behavior by
adding per-retry timeouts, specifying the amount of time you want to wait for
each retry attempt to successfully connect to the service. The following example
configures a maximum of 3 retries to connect to this service subset after an
initial call failure, each with a 2 second timeout.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
    http:
  - route:
    - destination:
        host: ratings
        subset: v1
    retries:
      attempts: 3
      perTryTimeout: 2s
{{< /text >}}

### 熔断器 {#circuit-breakers}

断路器是Istio提供的另一个有用的创建机制
弹性microservice-based应用程序。在断路器中，你设置限制
用于调用服务中的各个主机，例如并发数量
连接或对此主机的调用失败多少次。一旦限制
已经到达断路器“跳闸”并停止进一步连接到
主机。使用断路器模式，使快速故障，而不是
试图连接到过载或故障主机的客户端。

因为断路适用于负载平衡中的“真实”网格目的地
池，你配置断路器阈值在
[目的地规则](#destination-rules)，每个规则都有相应的设置
服务中的单个主机。下面的示例限制了
对v1子集的“审查”服务工作负载进行并发连接
100:
Circuit breakers are another useful mechanism Istio provides for creating
resilient microservice-based applications. In a circuit breaker, you set limits
for calls to individual hosts within a service, such as the number of concurrent
connections or how many times calls to this host have failed. Once that limit
has been reached the circuit breaker "trips" and stops further connections to
that host. Using a circuit breaker pattern enables fast failure rather than
clients trying to connect to an overloaded or failing host.

As circuit breaking applies to "real" mesh destinations in a load balancing
pool, you configure circuit breaker thresholds in
[destination rules](#destination-rules), with the settings applying to each
individual host in the service. The following example limits the number of
concurrent connections for the `reviews` service workloads of the v1 subset to
100:

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      connectionPool:
        tcp:
          maxConnections: 100
{{< /text >}}

You can find out more about creating circuit breakers in
[Circuit Breaking](/zh/docs/tasks/traffic-management/circuit-breaking/).

### 故障注入 {#fault-injection}

在您配置了网络(包括故障恢复策略)之后，您可以
是否可以使用Istio的故障注入机制来测试故障恢复能力
你的申请作为一个整体。故障注入是一种测试方法
将错误引入系统，以确保系统能够承受并从中恢复
错误条件。使用故障注入可以特别有用地确保
您的故障恢复策略不是不兼容或限制太多，
可能导致关键服务不可用。

不像其他引入错误的机制，如延迟数据包或
在网络层杀死吊舱，Istio允许你在
应用程序层。这使您可以注入更多相关的失败，比如HTTP
错误代码，以获得更多相关的结果。
After you’ve configured your network, including failure recovery policies, you
can use Istio’s fault injection mechanisms to test the failure recovery capacity
of your application as a whole. Fault injection is a testing method that
introduces errors into a system to ensure that it can withstand and recover from
error conditions. Using fault injection can be particularly useful to ensure
that your failure recovery policies aren’t incompatible or too restrictive,
potentially resulting in critical services being unavailable.

Unlike other mechanisms for introducing errors such as delaying packets or
killing pods at the network layer, Istio’ lets you inject faults at the
application layer. This lets you inject more relevant failures, such as HTTP
error codes, to get more relevant results.

You can inject two types of faults, both configured using a
[virtual service](#virtual-services):

-   Delays: Delays are timing failures. They mimic increased network latency or
    an overloaded upstream service.
-   Aborts: Aborts are crash failures. They mimic failures in upstream services.
    Aborts usually manifest in the form of HTTP error codes or TCP connection
    failures.

For example, this virtual service introduces a 5 second delay for 1 out of every 1000
requests to the `ratings` service.

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
    http:
  - fault:
      delay:
        percentage:
          value: 0.1
        fixedDelay: 5s
    route:
    - destination:
        host: ratings
        subset: v1
{{< /text >}}

For detailed instructions on how to configure delays and aborts, see
[Fault Injection](/zh/docs/tasks/traffic-management/fault-injection/).

### 和你的应用程序一起运行 {#working-with-your-applications}

的Istio故障恢复功能是完全透明的
应用程序。应用程序不知道是否有特使sidecar代理在处理
在返回响应之前调用的服务失败。这意味着
如果还在应用程序代码中设置故障恢复策略
您需要记住，两者都是独立工作的，因此可能是独立工作的
冲突。例如，假设您可以有两个超时，一个配置为in
虚拟服务和应用程序中的另一个。应用程序设置一个2
对服务的API调用的第二个超时。但是，您配置了一个3
第二次超时，在虚拟服务中重试一次。在这种情况下，
应用程序的超时首先生效，因此您的特使超时并重试
尝试没有效果。

Istio故障恢复功能提高了可靠性和可靠性
服务在网格中的可用性，应用程序必须处理故障
或错误，并采取适当的后备行动。例如，当所有
负载平衡池中的实例失败，Envoy返回' HTTP 503 '
代码。应用程序必须实现处理
' HTTP 503 '错误代码..
Istio failure recovery features are completely transparent to the
application. Applications don’t know if an Envoy sidecar proxy is handling
failures for a called service before returning a response. This means that
if you are also setting failure recovery policies in your application code
you need to keep in mind that both work independently, and therefore might
conflict. For example, suppose you can have two timeouts, one configured in
a virtual service and another in the application. The application sets a 2
second timeout for an API call to a service. However, you configured a 3
second timeout with 1 retry in your virtual service. In this case, the
application’s timeout kicks in first, so your Envoy timeout and retry
attempt has no effect.

While Istio failure recovery features improve the reliability and
availability of services in the mesh, applications must handle the failure
or errors and take appropriate fallback actions. For example, when all
instances in a load balancing pool have failed, Envoy returns an `HTTP 503`
code. The application must implement any fallback logic needed to handle the
`HTTP 503` error code..
