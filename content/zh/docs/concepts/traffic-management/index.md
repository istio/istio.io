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

`hosts`字段列出了虚拟服务的主机——换言之，用户指定的目标或是路由规则设定的目标。这是客户端向服务发送请求时使用的一个或多个地址。

{{< text yaml >}}
hosts:
- reviews
{{< /text >}}

虚拟服务主机名可以是IP地址、DNS名称，或者依赖于平台的一个简称（例如 Kubernetes 服务的短名称），隐式或显式地指向一个完全限定域名（FQDN）。你也可以使用通配符（”*“）前缀，让您创建一组匹配所有服务的路由规则。虚拟服务的`hosts`字段实际上不必是 Istio 服务注册的一部分，它只是虚拟的目标地址。这让您可以为没有路由到网格内部的虚拟主机建模。

#### 路由规则 {#routing-rules}

`http`部分包含了虚拟服务的路由规则，用来描述匹配条件和路由行为，它们把 HTTP/1.1、HTTP2 和 gRPC等流量发送到 hosts字段指定的目标（你也可以用`tcp`和`tls`片段为 [TCP](/zh/docs/reference/config/networking/virtual-service/#TCPRoute) 和为关闭的 [TLS](/zh/docs/reference/config/networking/virtual-service/#TLSRoute) 流量设置路由规则）。一个路由规则包含了你指定请求要流向哪的目标地址，0 个或多个匹配条件，取决于你的使用场景。

##### 匹配条件 {#match-condition}

示例中的第一个路由规则有一个条件，因此以`match`字段开始。在本例中，您希望此路由应用于来自于用户”jason“的所有请求，所以使用`headers`、`end-user` 和 `exact` 字段选择适当的请求。

{{< text yaml >}}
- match:
   - headers:
       end-user:
         exact: jason
{{< /text >}}

##### Destination {#destination}

route 部分的`destination`字段指定了符合此条件的流量的实际目标地址。与虚拟服务的 host 不同，
destination 的 host 必须是存在于Istio服务注册中的实际目标地址，否则 Envoy 不知道将请求发送到哪里。这可以是一个有代理的服务网格，或者是一个通过服务入口被添加进来的非网格服务。在这个例子中，运行在 Kubernetes 上的主机名是它的服务名：

{{< text yaml >}}
route:
- destination:
    host: reviews
    subset: v2
{{< /text >}}

请注意，在本文和本页上的其他示例中，为了简单，我们使用 Kubernetes 的短名称设置destination的host。在评估此规则时，Istio会添加一个基于虚拟服务命名空间的域后缀，这个虚拟服务包含要获取主机的完全限定名的路由规则。在我们的示例中使用短名称也意味着您可以复制并在任何喜欢的命名空间中尝试它们。

{{< warning >}}
只有在目标主机和虚拟服务位于相同的 Kubernetes 命名空间时才可以使用这样的短名称。因为使用 Kubernetes的短名称容易导致配置出错，我们建议您在生产环境中指定完全限定的主机名。
{{< /warning >}}

destination 片段还指定了 Kubernetes 服务的子集，将符合此规则条件的请求转入其中。在本例中子集名称是 v2。您可以在 [目标规则](#destination-rules) 章节中看到如何定义服务子集。

#### 路由规则优先级 {#routing-rule-precedence}

**路由规则**按从上到下的顺序选择，虚拟服务定义中的第一条规则有最高优先级。在
在这种情况下，您希望任何与第一个路由规则不匹配的内容都转到一个默认目标的话，就得在第二条规则中指定。因为第二个规则没有匹配条件，只是将流量导向v3子集。

{{< text yaml >}}
- route:
  - destination:
      host: reviews
      subset: v3
{{< /text >}}

我们推荐提供一个默认的”无条件“规则或是基于权重的规则（下面会介绍），就好像每个虚拟服务的最终规则，能保证请求至少能有一个匹配的路由。

### 路由规则的更多内容 {#more-about-routing-rules}

正如上面所看到的，路由规则是将特定流量子集路由到指定目标地址的强大工具。您可以在流量端口、header 字段、URI 等内容上设置匹配条件。例如，这个虚拟服务让用户发送请求到两个独立的服务：ratings 和 reviews，就好像它们是 `http://bookinfo.com/`这个更大的虚拟服务的一部分。虚拟服务规则根据请求的 URI 和指向适当服务的请求匹配流量。

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

对一些匹配条件，你可以使用精确的值，如前缀或正则。

您可以使用 AND 向同一个`match`块添加多个匹配条件，或者使用 OR 向同一个规则添加多个`match`块。对于任何给定的虚拟服务也可以有多个路由规则。这可以在单个虚拟服务中使路由条件变得随你所愿的复杂或简单。匹配条件字段和备选值的完整列表可以在[`HTTPMatchRequest` 参考](/zh/docs/reference/config/networking/virtual-service/#HTTPMatchRequest)中找到。


额外的使用匹配条件，你可以按百分比”权重“分发请求。这在A/B测试和金丝雀发布中非常有用：

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

你也可以使用路由规则在流量上执行一些操作，例如：

-   添加或删除header。
-   重写 URL。
-   为调用这一目标地址的请求设置[重试策略](#retries) 。

想了解如何利用这些，查看 [`HTTPRoute` 参考](/zh/docs/reference/config/networking/virtual-service/#HTTPRoute)。

## 目标规则 {#destination-rules}

与[虚拟服务](#virtual-services)一样，[目标规则](/zh/docs/reference/config/networking/destination-rule/#DestinationRule)也是 Istio 流量路由功能的关键部分。您可以将虚拟服务视为将流量如何路由到给定目标地址，然后使用目标规则来配置该目标的流量。在评估虚拟服务路由规则之后，目标规则将应用于流量的“真实”目标地址。

特别是，您可以使用目标规则来指定命名的服务子集，例如按版本为所有给定服务的实例分组。然后可以在虚拟服务的路由规则中使用这些服务子集来控制到服务不同实例的流量。

目标规则还允许您在调用整个目的地服务或特定服务子集时定制 Envoy 的流量策略，比如您喜欢的负载均衡模型、TLS安全模式或熔断器设置。在[目标规则参考](/zh/docs/reference/config/networking/destination-rule/)中可以看到目标规则选项的完整列表。

### 负载均衡选项

默认情况下，Istio 使用轮询的负载均衡策略，实例池中的每个实例依次获取请求。Istio 也支持以下模型，您可以在目标规则中为请求指定到一个特定服务或服务子集。

-   随机：请求以随机的方式转到池中的实例。
-   权重：请求根据指定的百分比转到实例。
-   最少请求：请求被转到最少被访问的实例。

查看 [Envoy 负载均衡文档](https://www.envoyproxy.io/zh/docs/envoy/v1.5.0/intro/arch_overview/load_balancing)获取这部分的更多信息。

### 目标规则示例 {#destination-rule-example}

在下面的示例中，目标规则为 `my-svc`目标服务配置了 3 个具有不同负载均衡策略的子集：

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

每个子集都是基于一个或多个 `labels` 定义的，在 Kubernetes 中它是附加到像 Pod 这种对象上的键/值对。这些标签应用于Kubernetes服务的部署并作为`metadata`来识别不同的版本。

除了定义子集之外，目标规则对于所有子集都有默认的流量策略，而对于该子集，则有特定于子集的策略覆盖它。定义在 `subsets` 上的默认策略，为`v1`和`v3`子集设置了一个简单的随机负载均衡器。在`v2` 策略中，轮询负载均衡器被指定在相应的子集字段上。

## 网关 {#gateways}

使用一个[网关](/zh/docs/reference/config/networking/gateway/#gateway)为网格来管理入站和出站流量，可以让您指定要进入或离开网格的流量。网关配置用于运行在网格边界的独立 Envoy 代理，而不是服务工作负载的 sidecar 代理。

与 Kubernetes Ingress API这种控制进入系统的流量的其他机制不同，Istio 网关让您充分利用它流量路由的强大能力和灵活性。你可以这么做的原因是 Istio 的网关资源可以配置 4-6层的负载均衡属性，如对外暴露的端口、TLS设置等。作为替代应用层流量路由（L7）到相同的API资源，您绑定了一个常规的 Istio [虚拟服务](#virtual-services)到网关。这让您可以像管理网格中其他数据平面流量一样去管理网关流量。

网关主要用于管理进入的流量，但你也可以配置出口网关。出口网关让您为离开网格的流量配置一个专用的出口
节点，这可以限制哪些服务可以或应该访问外部网络，或者启用[出口流量安全控制](/zh/blog/2019/egress-traffic-control-in-istio-part-1/)为您的网格添加安全性。你也可以使用网关配置一个纯粹的内部代理。

Istio提供一些预先配置好的网关代理部署（istio-ingressgateway 和 istio-egressgateway）供你使用——如果使用我们的[演示安装](/zh/docs/setup/install/kubernetes/)它们都已经部署好了；如果使用[默认或sds配置文件](/zh/docs/setup/additional-setup/config-profiles/)则只部署了入口网关。可以将您自己的网关配置应用到这些部署或部署配置您自己的网关代理。

### Gateway 示例 {#gateway-example}

下面的示例展示了一个为外部HTTPS入口流量的网关配置：

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

这个网关配置让 HTTPS 流量从 `ext-host.example.com` 通过443端口流入网格，但没有为请求指定任何路由规则。为想要工作的网关指定路由，你必须把网关绑定到虚拟服务上。正如下面的示例所示，使用虚拟服务的`gateways`字段进行设置：

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

然后就可以为出口流量配置带有路由规则的虚拟服务。

## 服务入口 {#service-entries}

使用[服务入口](/zh/docs/reference/config/networking/service-entry/#ServiceEntry)来添加一个入口到 Istio 内部维护的服务注册中心。在你添加了服务入口后，Envoy 代理可以向服务发送流量，就好像它是网格内部的服务一样。配置服务入口允许您管理运行在网格外的服务的流量，它包括以下几种任务：

-   为外部目标 redirect 和转发请求，例如来着web端的API调用，或者流向遗留老系统的服务。
-   为外部目标定义[重试](#retries)，[超时](#timeouts)和[故障注入](#fault-injection)策略。 
-   添加一个运行在虚拟机的服务来[扩展你的网格](/zh/docs/examples/virtual-machines/single-network/#running-services-on-the-added-vm)。
-   从逻辑上添加来自不同集群的服务到网格，在 Kubernetes 上实现一个[多集群 Istio 网格](/zh/docs/setup/install/multicluster/gateways/#configure-the-example-services)。

您不需要为网格服务要使用的每个外部服务都添加服务入口。默认情况下，Istio 配置 Envoy 代理将请求传递给未知服务。然而，您不能使用 Istio 的特性来控制没有在网格中注册的目标流量。

### 服务入口示例 {#service-entry-example}

下面示例的 mesh-external 服务入口将`ext-resource`外部依赖项添加到 Istio 的服务注册中心：

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

你指定的外部资源使用 `hosts` 字段。 您可以使用完全限定名或使用通配符作为前缀的域名。

您可以配置虚拟服务和目标规则，以更细粒度的方式控制到服务入口的流量，这与网格中的任何其他服务配置流量的方式相同。例如，下面的目标规则配置流量路由以使用双向TLS来保护到`ext-svc.example.com`外部服务的连接，我们使用服务入口配置了该外部服务：

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

查看[服务入口参考](/zh/docs/reference/config/networking/service-entry)获取更多可能的配置项。

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
