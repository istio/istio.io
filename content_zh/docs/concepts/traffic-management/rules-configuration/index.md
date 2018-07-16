---
title: 规则配置
description:  这里对一个配置模型进行概要介绍，Istio 使用该模型对网格内的流量管理规则进行配置。
weight: 50
keywords: [traffic-management,rules]
---

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

规则可以使用 [istioctl 客户端工具](/docs/reference/commands/istioctl/) 进行配置，如果是 Kubernetes 部署，还可以使用 `kubectl` 命令完成同样任务，但是只有 `istioctl` 会在这个过程中对模型进行检查，所以我们推荐使用 `istioctl`。在[配置请求路由任务](/docs/tasks/traffic-management/request-routing/)中包含有配置示例。

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

**3. 根据 HTTP Header 选择规则。**下面的规则只会对包含了 `cookie` 头，且值为 `user=jason` 的请求生效：

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
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
    ...
~~~

多个 Header 之间是“与”关系。

可以同时设置多个标准，在这个例子中，还包含了 AND 或 OR 的语义，这要根据具体嵌套情况进行判断。如果多个标准嵌套在同一个 match 中，这些条件就是 AND 关系。例如下面的规则的限制条件要求的是同时符合下面两个条件：

- 来源于 `reviews:v2` 服务
- "cookie" 头中包含 “user=jason”

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
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
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
        cookie:
          regex: "^(.*?;)?(user=jason)(;.*)?$"
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

## 目标规则

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

## Service Entries

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

## Gateway

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