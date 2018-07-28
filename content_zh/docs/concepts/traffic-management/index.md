---
title: 流量管理
description: 介绍 Istio 中关于流量路由与控制的各项功能。
weight: 20
keywords: [traffic-management]
aliases:
    - /docs/concepts/traffic-management/overview
    - /docs/concepts/traffic-management/pilot
    - /docs/concepts/traffic-management/rules-configuration
    - /docs/concepts/traffic-management/fault-injection
    - /docs/concepts/traffic-management/handling-failures
    - /docs/concepts/traffic-management/load-balancing
    - /docs/concepts/traffic-management/request-routing
---

本页概述了 Istio 中流量管理的工作原理，包括流量管理原则的优点。本文假设你已经阅读了 [Istio 是什么？](/docs/concepts/what-is-istio/)并熟悉 Istio 的高级架构。有关单个流量管理功能的更多信息，您可以在本节其他指南中了解。

## Pilot 和 Envoy

Istio 流量管理的核心组件是 [Pilot](/docs/concepts/traffic-management/#pilot-and-envoy)，它管理和配置部署在特定 Istio 服务网格中的所有 Envoy 代理实例。它允许您指定在 Envoy 代理之间使用什么样的路由流量规则，并配置故障恢复功能，如超时、重试和熔断器。它还维护了网格中所有服务的规范模型，并使用这个模型通过发现服务让 Envoy 了解网格中的其他实例。

每个 Envoy 实例都会维护[负载均衡信息](/docs/concepts/traffic-management/#discovery-and-load-balancing)，负载均衡信息是基于从 Pilot 获得的信息，以及其负载均衡池中的其他实例的定期健康检查。从而允许其在目标实例之间智能分配流量，同时遵循其指定的路由规则。

## 流量管理的好处

使用 Istio 的流量管理模型，本质上是将流量与基础设施扩容解耦，让运维人员可以通过 Pilot 指定流量遵循什么规则，而不是执行哪些 pod/VM 应该接收流量——Pilot 和智能 Envoy 代理会帮我们搞定。因此，例如，您可以通过 Pilot 指定特定服务的 5％ 流量可以转到金丝雀版本，而不必考虑金丝雀部署的大小，或根据请求的内容将流量发送到特定版本。

{{< image width="85%" ratio="69.52%"
    link="/docs/concepts/traffic-management/TrafficManagementOverview.svg"
    caption="Istio 中的流量管理">}}

将流量从基础设施扩展中解耦，这样就可以让 Istio 提供各种流量管理功能，这些功能在应用程序代码之外。除了 A/B 测试的动态[请求路由](/docs/concepts/traffic-management/#request-routing)，逐步推出和金丝雀发布之外，它还使用超时、重试和熔断器处理[故障恢复](/docs/concepts/traffic-management/#handling-failures)，最后还可以通过[故障注入](/docs/concepts/traffic-management/#fault-injection)来测试服务之间故障恢复策略的兼容性。这些功能都是通过在服务网格中部署的 Envoy sidecar/代理来实现的。

Pilot 负责部署在 Istio 服务网格中的 Envoy 实例的生命周期管理。

{{<image width="60%" ratio="72.17%"
    link="/docs/concepts/traffic-management/PilotAdapters.svg"
    caption="Pilot 架构">}}

如上图所示，Pilot 维护了网格中的服务的规范表示，这个表示是独立于底层平台的。Pilot 中的平台特定适配器负责适当填充此规范模型。例如，Pilot 中的 Kubernetes 适配器实现必要的控制器来 watch Kubernetes API server 中 pod 注册信息、ingress 资源以及用于存储流量管理规则的第三方资源的更改。该数据被翻译成规范表示。Envoy 特定配置是基于规范表示生成的。

Pilot 公开了用于[服务发现](https://www.envoyproxy.io/docs/envoy/latest/api-v1/cluster_manager/sds) 、[负载均衡池](https://www.envoyproxy.io/docs/envoy/latest/configuration/cluster_manager/cds)和[路由表](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_conn_man/rds)的动态更新的 API。这些 API 将 Envoy 从平台特有的细微差别中解脱出来，简化了设计并提升了跨平台的可移植性。

运维人员可以通过 [Pilot 的 Rules API](/docs/reference/config/istio.networking.v1alpha3/)指定高级流量管理规则。这些规则被翻译成低级配置，并通过 discovery API 分发到 Envoy 实例。

## 请求路由

如 [Pilot](/docs/concepts/traffic-management/#pilot-and-envoy) 所述，特定网格中服务的规范表示由 Pilot 维护。服务的 Istio 模型和在底层平台（Kubernetes、Mesos 以及 Cloud Foundry 等）中的表达无关。特定平台的适配器负责从各自平台中获取元数据的各种字段，然后对服务模型进行填充。

Istio 引入了服务版本的概念，可以通过版本（`v1`、`v2`）或环境（`staging`、`prod`）对服务进行进一步的细分。这些版本不一定是不同的 API 版本：它们可能是部署在不同环境（prod、staging 或者 dev 等）中的同一服务的不同迭代。使用这种方式的常见场景包括 A/B 测试或金丝雀部署。Istio 的[流量路由规则](/docs/concepts/traffic-management/#rule-configuration)可以根据服务版本来对服务之间流量进行附加控制。

### 服务之间的通讯

{{< image width="60%" ratio="100.42%"
    link="/docs/concepts/traffic-management/ServiceModel_Versions.svg"
    alt="服务版本的处理。"
    caption="服务版本"
    >}}

如上图所示，服务的客户端不知道服务不同版本间的差异。他们可以使用服务的主机名或者 IP 地址继续访问服务。Envoy sidecar/代理拦截并转发客户端和服务器之间的所有请求和响应。

运维人员使用 Pilot 指定路由规则，Envoy 根据这些规则动态地确定其服务版本的实际选择。该模型使应用程序代码能够将它从其依赖服务的演进中解耦出来，同时提供其他好处（参见 [Mixer](/docs/concepts/policies-and-telemetry/)）。路由规则让 Envoy 能够根据诸如 header、与源/目的地相关联的标签和/或分配给每个版本的权重等标准来进行版本选择。

Istio 还为同一服务版本的多个实例提供流量负载均衡。可以在[服务发现和负载均衡](/docs/concepts/traffic-management/#discovery-and-load-balancing)中找到更多信息。

Istio 不提供 DNS。应用程序可以尝试使用底层平台（kube-dns，mesos-dns 等）中存在的 DNS 服务来解析 FQDN。

### Ingress 和 Egress

Istio 假定进入和离开服务网络的所有流量都会通过 Envoy 代理进行传输。通过将 Envoy 代理部署在服务之前，运维人员可以针对面向用户的服务进行 A/B 测试，部署金丝雀服务等。类似地，通过使用 Envoy 将流量路由到外部 Web 服务（例如，访问 Maps API 或视频服务 API）的方式，运维人员可以为这些服务添加超时控制、重试、断路器等功能，同时还能从服务连接中获取各种细节指标。

{{< image width="60%" ratio="28.88%"
    link="/docs/concepts/traffic-management/ServiceModel_RequestFlow.svg"
    alt="通过 Envoy 的 Ingress 和 Egress。"
    caption="请求流"
    >}}

## 服务发现和负载均衡

**服务注册**：Istio 假定存在服务注册表，以跟踪应用程序中服务的 pod/VM。它还假设服务的新实例自动注册到服务注册表，并且不健康的实例将被自动删除。诸如 Kubernetes、Mesos 等平台已经为基于容器的应用程序提供了这样的功能。为基于虚拟机的应用程序提供的解决方案就更多了。

**服务发现**：Pilot 使用来自服务注册的信息，并提供与平台无关的服务发现接口。网格中的 Envoy 实例执行服务发现，并相应地动态更新其负载均衡池。

{{<image width="80%" ratio="74.79%"
    link="/docs/concepts/traffic-management/LoadBalancing.svg"
    caption="发现与负载均衡">}}

如上图所示，网格中的服务使用其 DNS 名称访问彼此。服务的所有 HTTP 流量都会通过 Envoy 自动重新路由。Envoy 在负载均衡池中的实例之间分发流量。虽然 Envoy 支持多种[复杂的负载均衡算法](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/load_balancing)，但 Istio 目前仅允许三种负载平衡模式：轮循、随机和带权重的最少请求。

除了负载均衡外，Envoy 还会定期检查池中每个实例的运行状况。Envoy 遵循熔断器风格模式，根据健康检查 API 调用的失败率将实例分类为不健康或健康。换句话说，当给定实例的健康检查失败次数超过预定阈值时，它将从负载均衡池中弹出。类似地，当通过的健康检查数超过预定阈值时，该实例将被添加回负载均衡池。您可以在[处理故障](/docs/concepts/traffic-management/#handling-failures)中了解更多有关 Envoy 的故障处理功能。

服务可以通过使用 HTTP 503 响应健康检查来主动减轻负担。在这种情况下，服务实例将立即从调用者的负载均衡池中删除。

## 处理失败

Envoy 提供了一套开箱即用，**可选的**的故障恢复功能，对应用中的服务大有裨益。这些功能包括：

1. 超时
1. 具备超时预算，并能够在重试之间进行可变抖动（间隔）的有限重试功能
1. 并发连接数和上游服务请求数限制
1. 对负载均衡池中的每个成员进行主动（定期）运行健康检查
1. 细粒度熔断器（被动健康检查）- 适用于负载均衡池中的每个实例

这些功能可以使用 [Istio 的流量管理规则](/docs/concepts/traffic-management/#rule-configuration)在运行时进行动态配置。

对超载的上游服务来说，重试之间的抖动极大的降低了重试造成的影响，而超时预算确保调用方服务在可预测的时间范围内获得响应（成功/失败）。

主动和被动健康检查（上述 4 和 5 ）的组合最大限度地减少了在负载平衡池中访问不健康实例的机会。当与平台级健康检查（例如由 Kubernetes 或 Mesos 支持的检查）相结合时，应用程序可以确保将不健康的 Pod/容器/虚拟机 快速地从服务网格中去除，从而最小化请求失败和延迟产生影响。

总之，这些功能使得服务网格能够耐受故障节点，并防止本地故障导致的其他节点的稳定性下降。

### 微调

Istio 的流量管理规则允许运维人员为每个服务/版本设置故障恢复的全局默认值。然而，服务的消费者也可以通过特殊的 HTTP 头提供的请求级别值覆盖[超时](/docs/reference/config/istio.networking.v1alpha3/#HTTPRoute-timeout)和[重试](/docs/reference/config/istio.networking.v1alpha3/#HTTPRoute-retries)的默认值。在 Envoy 代理的实现中，对应的 Header 分别是 `x-envoy-upstream-rq-timeout-ms` 和 `x-envoy-max-retries`。

### FAQ

Q: *在 Istio 中运行的应用程序是否仍需要处理故障？*

是的。Istio可以提高网格中服务的可靠性和可用性。但是，**应用程序仍然需要处理故障（错误）并采取适当的回退操作**。例如，当负载均衡池中的所有实例都失败时，Envoy 将返回 HTTP 503。，应用程序有责任实现必要的逻辑，对这种来自上游服务的 HTTP 503 错误做出合适的响应。

Q: *已经使用容错库（例如 [Hystrix](https://github.com/Netflix/Hystrix)）的应用程序，是否会因为 Envoy 的故障恢复功能受到破坏？*

不会。Envoy对应用程序是完全透明的。在进行服务调用时，由 Envoy 返回的故障响应与上游服务返回的故障响应不会被区分开来。

Q: *同时使用应用级库和 Envoy 时，怎样处理故障？*

假如对同一个目的服务给出两个故障恢复策略（例如，两次超时设置——一个在 Envoy 中设置，另一个在应用程序库中设置），**当故障发生时，两个限制都将被触发**。例如，如果应用程序为服务的 API 调用设置了 5 秒的超时时间，而运维人员配置了 10 秒的超时时间，那么应用程序的超时将会首先启动。同样，如果 Envoy 的熔断器在应用熔断器之前触发，对该服务的 API 调用将从 Envoy 收到 503 错误。

## 故障注入

虽然 Envoy sidecar/proxy 为在 Istio 上运行的服务提供了大量的[故障恢复机制](/docs/concepts/traffic-management/#handling-failures)，但测试整个应用程序端到端的故障恢复能力依然是必须的。错误配置的故障恢复策略（例如，跨服务调用的不兼容/限制性超时）可能导致应用程序中的关键服务持续不可用，从而破坏用户体验。

Istio 能在不杀死 Pod 的情况下，将协议特定的故障注入到网络中，在 TCP 层制造数据包的延迟或损坏。我们的理由是，无论网络级别的故障如何，应用层观察到的故障都是一样的，并且可以在应用层注入更有意义的故障（例如，HTTP 错误代码），以检验和改善应用的弹性。

运维人员可以为符合特定条件的请求配置故障，还可以进一步限制遭受故障的请求的百分比。可以注入两种类型的故障：延迟和中断。延迟是计时故障，模拟网络延迟上升或上游服务超载的情况。中断是模拟上游服务的崩溃故障。中断通常以 HTTP 错误代码或 TCP 连接失败的形式表现。

有关详细信息，请参阅 [Istio 的流量管理规则](/docs/concepts/traffic-management/#rule-configuration)。

## 规则配置

Istio 提供了一个简单的配置模型，用来控制 API 调用以及应用部署内多个服务之间的四层通信。运维人员可以使用这个模型来配置服务级别的属性，这些属性可以是断路器、超时、重试，以及一些普通的持续发布任务，例如金丝雀发布、A/B 测试、使用百分比对流量进行控制，从而完成应用的逐步发布等。

例如，将 `reviews` 服务 100％ 的传入流量发送到 `v1` 版本，这一需求可以用下面的规则来实现：

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
~~~

这个配置的用意是，发送到 `reviews` 服务（在 `host` 字段中标识）的流量应该被路由到 `reviews` 服务实例的 `v1` 子集中。路由中的 `subset` 制定了一个预定义的子集名称，子集的定义来自于目标规则配置：

~~~yaml
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
  - name: v2
    labels:
      version: v2
~~~

子集中会指定一或多个标签，用这些标签来区分不同版本的实例。假设在 Kubernetes 上的 Istio 服务网格之中有一个服务，`version: v1` 代表只有标签中包含 "version:v1" 的 Pod 才会收到流量。

规则可以使用 [`istioctl` 客户端工具](/docs/reference/commands/istioctl/) 进行配置，如果是 Kubernetes 部署，还可以使用 `kubectl` 命令完成同样任务，但是只有 `istioctl` 会在这个过程中对模型进行检查，所以我们推荐使用 `istioctl`。在[配置请求路由任务](/docs/tasks/traffic-management/request-routing/)中包含有配置示例。

Istio 中包含有四种流量管理配置资源，分别是 `VirtualService`、`DestinationRule`、`ServiceEntry`、以及 `Gateway`。下面会讲一下这几个资源的一些重点。在[网络参考](/docs/reference/config/istio.networking.v1alpha3/)中可以获得更多这方面的信息。

## Virtual Services

是在 Istio 服务网格内对服务的请求如何进行路由控制？[`VirtualService`](/docs/reference/config/istio.networking.v1alpha3/#VirtualService) 中就包含了这方面的定义。例如一个 Virtual Service 可以把请求路由到不同版本，甚至是可以路由到一个完全不同于请求要求的服务上去。路由可以用很多条件进行判断，例如请求的源和目的、HTTP 路径和 Header 以及各个服务版本的权重等。

### 规则的目标描述

路由规则对应着一或多个用 `VirtualService` 配置指定的请求目的主机。这些主机可以是、也可以不是实际的目标负载，甚至可以不是一个网格内可路由的服务。例如要给到 `reviews` 服务的请求定义路由规则，可以使用内部的名称 `reviews`，也可以用域名 `bookinfo.com`，`VirtualService` 可以这样使用 `host` 字段：

~~~yaml
hosts:
  - reviews
  - bookinfo.com
~~~

`host` 字段用显示或者隐式的方式定义了一或多个完全限定名（FQDN）。上面的 `reviews`，会隐式的扩展成为特定的 FQDN，例如在 Kubernetes 环境中，全名会从 `VirtualService` 所在的集群和命名空间中继承而来（比如说 `reviews.default.svc.cluster.local`）。

### 根据来源或 Header 制定规则

可以选择让规则只对符合某些要求的请求生效：

**1. 根据特定用户进行限定。**例如，可以制定一个规则，只对来自 `reviews` 服务的 Pod 生效：

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
      sourceLabels:
        app: reviews
    ...
~~~

`sourceLabels` 的值依赖于服务的实现。比如说在 Kubernetes 中，跟服务的 Pod 选择标签一致。

**2. 根据调用方的特定版本进行限定。**例如下面的规则对前一个例子进行修改，`reviews` 服务的 `v2` 版本发出的请求才会生效：

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
    ...
~~~

**3. 根据 HTTP Header 选择规则。**下面的规则只会对包含了 `end-user` 头，且值为 `jason` 的请求生效：

~~~yaml
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
    ...
~~~

多个 Header 之间是"与”关系。

可以同时设置多个标准，在这个例子中，还包含了 AND 或 OR 的语义，这要根据具体嵌套情况进行判断。如果多个标准嵌套在同一个 match 中，这些条件就是 AND 关系。例如下面的规则的限制条件要求的是同时符合下面两个条件：

- 来源于 `reviews:v2` 服务
- "end-user" 头中包含 “jason”

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
      headers:
        end-user:
          exact: jason
    ...
~~~

但如果这些标准存在于不同的 `match` 子句中，就会变成 OR 逻辑：

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - match:
    - sourceLabels:
        app: reviews
        version: v2
    - headers:
        end-user:
          exact: jason
    ...
~~~

### 在服务之间分拆流量

每个路由规则都需要对一或多个有权重的后端进行甄别并调用合适的后端。每个后端都对应一个特定版本的目标服务，服务的版本是依靠标签来区分的。如果一个服务版本包含多个注册实例，那么会根据为该服务定义的负载均衡策略进行路由，缺省策略是 `round-robin`。

例如下面的规则会把 25% 的 `reviews` 服务流量分配给 `v2` 标签；其余的 75% 流量分配给 `v1`：

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
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
~~~

### 超时和重试

缺省情况下，HTTP 请求的超时设置为 15 秒，可以使用路由规则来覆盖这个限制：

~~~yaml
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
~~~

还可以用路由规则来指定某些 http 请求的重试次数。下面的代码可以用来设置最大重试次数，或者在规定时间内一直重试，时间长度同样可以进行覆盖：

~~~yaml
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
~~~

注意请求的重试和超时还可以[针对每个请求分别设置](/docs/concepts/traffic-management/#fine-tuning)。

[请求超时任务](/docs/tasks/traffic-management/request-timeouts/)中展示了超时控制的相关示例。

### 在请求中进行错误注入

在根据路由规则向选中目标转发 http 请求的时候，可以向其中注入一或多个错误。错误可以是延迟，也可以是退出。

下面的例子在目标为 `ratings:v1` 服务的流量中，对其中的 10% 注入 5 秒钟的延迟。

~~~yaml
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
        percent: 10
        fixedDelay: 5s
    route:
    - destination:
        host: ratings
        subset: v1
~~~

接下来，在目标为 `ratings:v1` 服务的流量中，对其中的 10% 注入 HTTP 400 错误。

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      abort:
        percent: 10
        httpStatus: 400
    route:
    - destination:
        host: ratings
        subset: v1
~~~

有时会把延迟和退出同时使用。例如下面的规则对从 `reviews:v2` 到 `ratings:v1` 的流量生效，会让所有的请求延迟 5 秒钟，接下来把其中的 10% 退出：

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings
spec:
  hosts:
  - ratings
  http:
  - fault:
      abort:
        percent: 10
        httpStatus: 400
    route:
    - destination:
        host: ratings
        subset: v1
~~~

可以参考[错误注入任务](/docs/tasks/traffic-management/fault-injection/)，进行这方面的实际体验。

### HTTP 路由的优先级

当对同一目标有多个规则时，会按照在 `VirtualService` 中的顺序进行应用，换句话说，列表中的第一条规则具有最高优先级。

**为什么优先级很重要：**当对某个服务的路由是完全基于权重的时候，他就可以在单一规则中完成。另一方面，如果有多重条件（例如来自特定用户的请求）用来进行路由，就会需要不止一条规则。这样就出现了优先级问题，需要通过优先级来保证根据正确的顺序来执行规则。

常见的路由模式是提供一或多个高优先级规则，这些优先规则使用源服务以及 Header 来进行路由判断，然后才提供一条单独的基于权重的规则，这些低优先级规则不设置匹配规则，仅根据权重对所有剩余流量进行分流。

例如下面的 `VirtualService` 包含了两个规则，所有对 `reviews` 服务发起的请求，如果 Header 包含 `Foo=bar`，就会被路由到 `v2` 实例，而其他请求则会发送给 `v1` ：

~~~yaml
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
        Foo:
          exact: bar
    route:
    - destination:
        host: reviews
        subset: v2
  - route:
    - destination:
        host: reviews
        subset: v1
~~~

注意，基于 Header 的规则具有更高优先级。如果降低它的优先级，那么这一规则就无法生效了，这是因为那些没有限制的权重规则会首先被执行，也就是说所有请求及时包含了符合条件的 `Foo` 头，也都会被路由到 `v1`。流量特征被判断为符合一条规则的条件的时候，就会结束规则的选择过程，这就是在存在多条规则时，需要慎重考虑优先级问题的原因。

### 目标规则

在请求被 `VirtualService` 路由之后，[`DestinationRule`](/docs/reference/config/istio.networking.v1alpha3/#DestinationRule) 配置的一系列策略就生效了。这些策略由服务属主编写，包含断路器、负载均衡以及 TLS 等的配置内容。

`DestinationRule` 还定义了对应目标主机的可路由 `subset`（例如有命名的版本）。`VirtualService` 在向特定服务版本发送请求时会用到这些子集。

下面是 `reviews` 服务的 `DestinationRule` 配置策略以及子集：

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
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
~~~

注意在单个 `DestinationRule` 配置中可以包含多条策略（比如 default 和 v2）。

### 断路器

可以用一系列的标准，例如连接数和请求数限制来定义简单的断路器。

例如下面的 `DestinationRule` 给 `reviews` 服务的 `v1` 版本设置了 100 连接的限制：

~~~yaml
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
~~~

### `DestinationRule` 的评估

和路由规则类似，这些策略也是和特定的 `host` 相关联的，如果指定了 `subset`，那么具体生效的 `subset` 的决策是由路由规则来决定的。

规则评估的第一步，是确认 `VirtualService` 中所请求的主机相对应的路由规则（如果有的话），这一步骤决定了将请求发往目标服务的哪一个 `subset`（就是特定版本）。下一步，被选中的 `subset` 如果定义了策略，就会开始是否生效的评估。

**注意：**这一算法需要留心是，为特定 `subset` 定义的策略，只有在该 `subset` 被显式的路由时候才能生效。例如下面的配置，只为 `review` 服务定义了规则（没有对应的 `VirtualService` 路由规则）。

~~~yaml
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
~~~

既然没有为 `reviews` 服务定义路由规则，那么就会使用缺省的 `round-robin` 策略，偶尔会请求到 `v1` 实例，如果只有一个 `v1` 实例，那么所有请求都会发送给它。然而上面的策略是永远不会生效的，这是因为，缺省路由是在更底层完成的任务，策略引擎无法获知最终目的，也无法为请求选择匹配的 `subset` 策略。

有两种方法来解决这个问题。可以把路由策略提高一级，要求他对所有版本生效：

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
  subsets:
  - name: v1
    labels:
      version: v1
~~~

还有一个更好的方法，就是为服务定义路由规则，例如给 `reviews:v1` 加入一个简单的路由规则：

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
~~~

虽然 Istio 在没有定义任何规则的情况下，能将所有来源的流量发送给所有版本的目标服务。然而一旦需要对版本有所区别，就需要制定规则了。从一开始就给每个服务设置缺省规则，是 Istio 世界里推荐的最佳实践。

### Service Entries

Istio 内部会维护一个服务注册表，可以用 [`ServiceEntry`](/docs/reference/config/istio.networking.v1alpha3/#ServiceEntry) 向其中加入额外的条目。通常这个对象用来启用对 Istio 服务网格之外的服务发出请求。例如下面的 `ServiceEntry` 可以用来允许外部对 `*.foo.com` 域名上的服务主机的调用。

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: foo-ext-svc
spec:
  hosts:
  - *.foo.com
  ports:
  - number: 80
    name: http
    protocol: HTTP
  - number: 443
    name: https
    protocol: HTTPS
~~~

`ServiceEntry` 中使用 `hosts` 字段来指定目标，字段值可以是一个完全限定名，也可以是个通配符域名。其中包含的白名单，包含一或多个允许网格中服务访问的服务。

`ServiceEntry` 的配置不仅限于外部服务，他可以有两种类型：网格内部和网格外部。网格内的条目和其他的内部服务类似，用于显式的将服务加入网格。可以用来把服务作为服务网格扩展的一部分加入不受管理的基础设置（例如加入到基于 Kubernetes 的服务网格中的虚拟机）中。网格外的条目用于表达网格外的服务。对这种条目来说，mTLS 认证是禁止的，策略实现需要在客户端执行，而不像内部服务请求中的服务端执行。

只要 `ServiceEntry` 涉及到了匹配 `host` 的服务，就可以和 `VirtualService` 以及 `DestinationRule` 配合工作。例如下面的规则可以和上面的 `ServiceEntry` 同时使用，在访问 `bar.foo.com` 的外部服务时，设置一个 10 秒钟的超时。

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bar-foo-ext-svc
spec:
  hosts:
    - bar.foo.com
  http:
  - route:
    - destination:
        host: bar.foo.com
    timeout: 10s
~~~

流量的重定向和转发、定义重试和超时以及错误注入策略都支持外部目标。然而由于外部服务没有多版本的概念，因此权重（基于版本）路由就无法实现了。

参照 [egress 任务](https://preliminary.istio.io/docs/tasks/traffic-management/egress/)可以了解更多的访问外部服务方面的知识。

### Gateway

[Gateway](/docs/reference/config/istio.networking.v1alpha3/#Gateway) 为 HTTP/TCP 流量配置了一个负载均衡，多数情况下在网格边缘进行操作，用于启用一个服务的 Ingress 流量。

和 Kubernetes Ingress 不同，Istio `Gateway` 只配置四层到六层的功能（例如开放端口或者 TLS 配置）。绑定一个 `VirtualService` 到 `Gateway` 上，用户就可以使用标准的 Istio 规则来控制进入的 HTTP 和 TCP 流量。

例如下面提供一个简单的 `Gateway` 代码，配合一个负载均衡，允许外部针对主机 `bookinfo.com` 的 https 流量：

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - bookinfo.com
    tls:
      mode: SIMPLE
      serverCertificate: /tmp/tls.crt
      privateKey: /tmp/tls.key
~~~

要为 `Gateway` 配置对应的路由，必须为定义一个同样 `host` 定义的 `VirtualService`，其中用 `gateways` 字段来绑定到定义好的 `Gateway` 上：

~~~yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
    - bookinfo.com
  gateways:
  - bookinfo-gateway # <---- 绑定到 Gateway
  http:
  - match:
    - uri:
        prefix: /reviews
    route:
    ...
~~~

在 [Ingress 任务](/docs/tasks/traffic-management/ingress/) 中有完整的 Ingress Gateway 例子。

虽然主要用于管理 Ingress 流量，`Gateway` 还可以用在纯粹的内部服务之间或者 egress 场景下使用。不管处于什么位置，所有的网关都可以以同样的方式进行配置和控制。[Gateway 参考](/docs/reference/config/istio.networking.v1alpha3/#Gateway) 中包含更多细节描述。
