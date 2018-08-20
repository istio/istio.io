---
title: 通信路由
description: 流量路由配置。
weight: 50
# keywords: [kubernetes,helm]
---

路由方面的配置，下面列出的是与该配置上下文有关的词汇。

`Service（服务）`：服务注册表中的一个单位，具备唯一名称，代表了一个应用。一个服务是由多个网络端点构成的，这些端点是由运行在 Pod、容器或者虚拟机上的工作负载实例实现的。

`Service versions（也叫做 subset/子集）`：在持续部署的场景中，一个服务可能会有多个子集在同时运行。子集之间的通常会有 API 版本方面的区别。不同的子集可能是同一服务的不同迭代阶段，或者不同环境的部署（生产、预发布以及开发等）。子集的存在，对于 A/B 测试、金丝雀发布等场景都是必要的。可以使用多种条件（Header、URL 等）来为流量选择对应的子集。每个服务都有一个缺省的版本，其中包含了该服务的所有实例。

`Source（源）`：调用某服务的下游客户端。

`Host（主机）`：客户端尝试连接到服务时所使用的地址。

`Access model（访问模型）`：应用仅关注目标服务（主机），而对于服务的版本或者子集一无所知。版本选择的决策过程由代理（Sidecar）完成，如此一来，应用代码就可以脱离对服务具体版本的依赖了。

## `ConnectionPoolSettings`

上游主机的连接池设置。这一设置会应用到上游服务中的每个主机上。可以参考 Envoy 的[断路器文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/circuit_breaking)获取更多信息。这一设置在 TCP 和 HTTP 级别都是有效的。

例如下面的规则为 Redis 服务设置了一个名为 `myredissrv` 的规则，限制连接数上限为 100，连接超时限制为 30 毫秒。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-redis
spec:
  host: myredissrv.prod.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
        connectTimeout: 30ms
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`tcp`|[`ConnectionPoolSettings.TCPSettings`](#ConnectionPoolSettings-TCPSettings)|连接数限制，对 HTTP 和 TCP 都有效。|
|`http`|[`ConnectionPoolSettings.HTTPSettings`](#ConnectionPoolSettings-HTTPSettings)|HTTP 连接池设置。|

## `ConnectionPoolSettings.HTTPSettings`

针对 HTTP1.1/HTTP2/GRPC 连接的设置项目。

|字段|类型|描述|
|---|---|---|
|`http1MaxPendingRequests`|`int32`|针对一个目标的 HTTP 请求的最大排队数量，缺省值为 1024。|
|`http2MaxRequests`|`int32`|对一个后端的最大请求数，缺省值为 1024。|
|`maxRequestsPerConnection`|`int32`|对某一后端的请求中，一个连接内能够发出的最大请求数量。如果将这一参数设置为 1 则会禁止 `keep alive` 特性。|
|`maxRetries`|`int32`|在给定时间内，集群中所有主机可以执行的最大重试次数。|

## `ConnectionPoolSettings.TCPSettings`

对 TCP 和 HTTP 都有效的的通用连接设置。

|字段|类型|描述|
|---|---|---|
|`maxConnections`|`int32`|到目标主机的 HTTP1/TCP 最大连接数。|
|`connectTimeout`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|TCP 连接超时|

## `CorsPolicy`

为服务定义跨来源资源共享（[Cross-Origin Resource Sharing](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Access_control_CORS)，缩写为 CORS）策略。例如下面的规则对来自 `example.com` 域的跨来源请求进行了限制：

- 仅允许 `POST` 和 `GET` 操作。
- 设置 `Access-Control-Allow-Credentials` Header 的值为 False。
- 只开放 `X-Foo-bar` Header。
- 设置过期时间为 1 天。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-route
spec:
  hosts:
  - ratings.prod.svc.cluster.local
  http:
  - route:
    - destination:
        host: ratings.prod.svc.cluster.local
        subset: v1
    corsPolicy:
      allowOrigin:
      - example.com
      allowMethods:
      - POST
      - GET
      allowCredentials: false
      allowHeaders:
      - X-Foo-Bar
      maxAge: "1d"
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`allowOrigin`|`string[]`|允许发起 CORS 请求的来源列表。这一字段的内容会被序列化之后保存到 `Access-Control-Allow-Origin header` Header 之中。使用通配符 `*` 会允许所有来源。|
|`allowMethods`|`string[]`|允许访问资源的 HTTP 方法，字段内容会进行序列化之后保存到 `Access-Control-Allow-Methods` Header 之中。|
|`allowHeaders`|`string[]`|在请求资源时可以使用的 HTTP Header 列表，会被序列化后保存到 `Access-Control-Allow-Methods` Header 之中。 |
|`exposeHeaders`|`string[]`|一个允许浏览器访问的 HTTP Header 白名单，会被序列化后保存到 `Access-Control-Expose-Headers` Header 之中。|
|`maxAge`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|可以缓存预检请求结果的有效期。保存到 `Access-Control-Max-Age` Header 之中。|
|`allowCredentials`|[`google.protobuf.BoolValue`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|是否允许调用者携带认证信息对资源发起实际请求（非预检）。会保存到 `Access-Control-Allow-Credentials` Header 之中。|

## `Destination`

`Destination` 用于定义在网络中可寻址的服务，请求或连接在经过路由规则的处理之后，就会被发送给 `Destination`。`destination.host` 应该明确指向服务注册表中的一个服务。Istio 的服务注册表除包含平台服务注册表中的所有服务（例如 Kubernetes 服务、Consul 服务）之外，还包含了 [`ServiceEntry`](#ServiceEntry) 资源所定义的服务。

> Kubernetes 用户注意：当使用服务的短名称时（例如使用 `reviews`，而不是 `reviews.default.svc.cluster.local`），Istio 会根据规则所在的命名空间来处理这一名称，而非服务所在的命名空间。假设 “default” 命名空间的一条规则中包含了一个 `reviews` 的 `host` 引用，就会被视为 `reviews.default.svc.cluster.local`，而不会考虑 `reviews` 服务所在的命名空间。**为了避免可能的错误配置，建议使用 FQDN 来进行服务引用。**

下面的 Kubernetes 实例，缺省把所有的流量路由到 `reviews` 服务中具有标签 `version: v1`（也就是 `v1` 子集）的 Pod 中，另外还有一部分会路由到 `v2` 子集之中。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews-route
  namespace: foo
spec:
  hosts:
  - reviews # 等价于 reviews.foo.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: "/wpcatalog"
    - uri:
        prefix: "/consumercatalog"
    rewrite:
      uri: "/newcatalog"
    route:
    - destination:
        host: reviews # 和 reviews.foo.svc.cluster.local 等价
        subset: v2
  - route:
    - destination:
        host: reviews # 和 reviews.foo.svc.cluster.local 等价
        subset: v1
{{< /text >}}

下面是相关的 `DestinationRule`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews-destination
  namespace: foo
spec:
  host: reviews # 等价于 reviews.foo.svc.cluster.local
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
{{< /text >}}

接下来的 `VirtualService` 在 Kubernetes 中为所有对 `productpage.prod.svc.cluster.local` 服务的调用都设置了一个 5 秒钟的超时。注意这里的规则中没有子集的定义。Istio 会从服务注册表中抓取 `productpage.prod.svc.cluster.local` 服务所有实例，据此生成 Envoy 的负载均衡池。同时需要注意的是，这个规则是在 `istio-system` 命名空间中设置的，但是使用的是 `productpage` 服务的 FQDN：`productpage.prod.svc.cluster.local`。这样规则所处的命名空间就不会对 `prodcutpage` 服务的解析过程造成影响了。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-productpage-rule
  namespace: istio-system
spec:
  hosts:
  - productpage.prod.svc.cluster.local # 无视规则所在的命名空间
  http:
  - timeout: 5s
    route:
    - destination:
        host: productpage.prod.svc.cluster.local
{{< /text >}}

要控制向网格之外发出的流量，外部服务首先要以 `ServiceEntry` 资源的形式在 Istio 内部的服务注册表中进行定义。定义完成之后，就可以使用 `ServiceEntry` 资源来控制到这些外部服务的流量了。例如下面的规则为 `wikipedia.org` 定义了一个服务，并为 http 请求设置了一个 5 秒钟的超时。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-wikipedia
spec:
  hosts:
  - wikipedia.org
  location: MESH_EXTERNAL
  ports:
  - number: 80
    name: example-http
    protocol: HTTP
  resolution: DNS

apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: my-wiki-rule
spec:
  hosts:
  - wikipedia.org
  http:
  - timeout: 5s
    route:
    - destination:
        host: wikipedia.org
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`host`|`string`|必要字段。目标服务的名称。流量目标对应的服务，会在平台的服务注册表（例如 Kubernetes 服务和 Consul 服务）以及 [`ServiceEntry`](#ServiceEntry) 资源中进行查找，如果查找失败，则丢弃流量。**Kubernetes 用户注意：当使用服务的短名称时（例如使用 `reviews`，而不是 `reviews.default.svc.cluster.local`），Istio 会根据规则所在的命名空间来处理这一名称，而非服务所在的命名空间。假设 “default” 命名空间的一条规则中包含了一个 `reviews` 的 `host` 引用，就会被视为 `reviews.default.svc.cluster.local`，而不会考虑 `reviews` 服务所在的命名空间。为了避免可能的错误配置，建议使用 FQDN 来进行服务引用。**|
|`subset`|`string`|服务子集的名称。仅对网格中的服务有效。必须在 `DestinationRule` 中定义子集。|
|`port`|[`PortSelector`](#PortSelector)|指定目标主机的端口。如果一个服务只暴露了一个端口，那么就无需显式的进行端口选择。|

## `DestinationRule`

`DestinationRule` 所定义的策略，决定了经过路由处理之后的流量的访问策略。这些策略中可以定义负载均衡配置、连接池尺寸以及外部检测（用于在负载均衡池中对不健康主机进行识别和驱逐）配置。例如给 `ratings` 服务定义一个简单的负载均衡策略：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN
{{< /text >}}

可以将策略指派给服务的特定版本，要完成这一操作需要定义一个 `subset`，并且在 `subset` 中对服务级定义的规则进行覆盖。下文规则的定义中，缺省的负载均衡方式是 `LEAST_CONN`；而在下面定义了一个名称为 `testversion` 的 `subset`，这个子集的 Pod 特征是 `version` 标签取值为 `v3`，该子集的负载均衡模式为 `ROUND_ROBIN`。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN
  subsets:
  - name: testversion
    labels:
      version: v3
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
{{< /text >}}

> 注意：只有在流量被显式的发送给某一子集的时候，指派给该子集的策略才会生效。

流量策略还可以根据端口来进行定义。接下来的规则，要求所有使用 `80` 端口的流量使用 `LEAST_CONN` 方式的负载均衡；而使用 `9080` 端口的流量则使用 `ROUND_ROBIN` 方式。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings-port
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy: # 对所有端口生效
    portLevelSettings:
    - port:
        number: 80
      loadBalancer:
        simple: LEAST_CONN
    - port:
        number: 9080
      loadBalancer:
        simple: ROUND_ROBIN
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`host`|`string`|必要字段。目标服务的名称。流量目标对应的服务，会在在平台的服务注册表（例如 Kubernetes 服务和 Consul 服务）以及 [`ServiceEntry`](#ServiceEntry) 注册中进行查找，如果查找失败，则丢弃流量。**Kubernetes 用户注意：当使用服务的短名称时（例如使用 `reviews`，而不是 `reviews.default.svc.cluster.local`），Istio 会根据规则所在的命名空间来处理这一名称，而非服务所在的命名空间。假设 `default` 命名空间的一条规则中包含了一个 `reivews` 的 `host` 引用，就会被视为 `reviews.default.svc.cluster.local`，而不会考虑 `reviews` 服务所在的命名空间。为了避免可能的错误配置，建议使用 FQDN 来进行服务引用。**|
|`trafficPolicy`|[`TrafficPolicy`](#TrafficPolicy)|流量策略（负载均衡策略、间接池尺寸和外部检测）。|
|`subsets`|[`Subset`](#Subset)|一个或多个服务版本。在子集的级别可以覆盖服务一级的流量策略定义。|

## `DestinationWeight`

每一条路由规则都会对应到一个或多个服务版本上（可以参考本文顶端的名词解释）。每个版本的权重决定了这一版本会收到的流量的多少。例如下面的规则会将 `reviews` 服务的流量进行拆分，其中 25% 进入 `v2` 版本，其余部分（也就是 75%）进入 `v1`。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews-route
spec:
  hosts:
  - reviews.prod.svc.cluster.local
  http:
  - route:
    - destination:
        host: reviews.prod.svc.cluster.local
        subset: v2
      weight: 25
    - destination:
        host: reviews.prod.svc.cluster.local
        subset: v1
      weight: 75
{{< /text >}}

对应的 `DestinationRule`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews-destination
spec:
  host: reviews.prod.svc.cluster.local
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
{{< /text >}}

除了服务内的按版本拆分，流量和可以在不同的服务间进行拆分。例如下面的规则把 25% 的流量分配给了 `dev.reviews.com`，剩余的 75% 则流向 `reviews.com`。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews-route-two-domains
spec:
  hosts:
  - reviews.com
  http:
  - route:
    - destination:
        host: dev.reviews.com
      weight: 25
    - destination:
        host: reviews.com
      weight: 75
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`destination`|[`Destination`](#Destination)|必要字段。流量将会被导入这一字段所指代的服务。|
|`weight`|`int32`|必要字段。转发给一个服务版本的流量占总流量的百分比。几个目标的**百分比之和必须等于 100**。如果一条规则中只有一个目标，会假设其权重为 100。|

## `EnvoyFilter`

`EnvoyFilter` 对象描述了针对代理服务的过滤器，这些过滤器可以定制由 Istio Pilot 生成的代理配置。这一功能一定要谨慎使用。错误的配置内容一旦完成传播，可能会令整个服务网格进入瘫痪状态。

注 1：这一配置十分脆弱，因此不会有任何的向后兼容能力。这一配置是用于对 Istio 网络系统的内部实现进行变更的。

注 2：如果有多个 `EnvoyFilter` 绑定在同一个工作负载上，所有的配置会按照创建时间的顺序进行处理。如果多个配置之间存在冲突，会产生不可预知的后果。

下面的 Kubernetes 例子，是针对 `reviews` 服务（也就是带有标签 `app:reviews` 的 Pod）的 8080 端口上的所有入站调用工作的，这一段配置启用了 Envoy 的 `Lua` 过滤器。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: reviews-lua
spec:
  workloadLabels:
    app: reviews
  filters:
  - listenerMatch:
      portNumber: 8080
      listenerType: SIDECAR_INBOUND # 匹配到 reviews:8080 的入站监听器
    filterName: envoy.lua
    filterType: HTTP
    filterConfig:
      inlineCode: |
        ... lua code .
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`workloadLabels`|`map<string, string>`|一个或多个标签，用于标识一组 Pod/虚拟机。这一组工作负载实例中的代理会被配置使用附加的过滤器配置。标签的搜索范围是平台相关的。例如在 Kubernetes 中，生效范围会包括所有可达的命名空间。如果省略这一字段，配置将会应用到网格中的所有 Envoy 代理实例中。注意：一个工作负载只应该使用一个 `EnvoyFilter`。如果多个 `EnvoyFilter` 被绑定到同一个工作负载上，会产生不可预测的行为。|
|`filters`|[`EnvoyFilter.Filter[]`](#EnvoyFilter-Filter)|必要字段。要加入指定监听器之中的 Envoy 网络过滤器/HTTP 过滤器配置信息。当给 http 连接加入网络过滤器的时候，应该注意确保该过滤器应早于 `envoy.httpconnectionmanager`。|

## `EnvoyFilter.Filter`

要加入过滤器链条的 Envoy 过滤器。

|字段|类型|描述|
|---|---|---|
|`listenerMatch`|[`EnvoyFilter.ListenerMatch`](#EnvoyFilter-ListenerMatch)|只有在符合匹配条件的情况下，过滤器才会加入这一监听器之中。如果没有指定该字段，会在所有监听器中加入这一过滤器。|
|`insertPosition`|[`EnvoyFilter.InsertPosition`](#EnvoyFilter-InsertPosition)|在过滤器链条中的插入位置，缺省为 `FIRST`。|
|`filterType`|[`EnvoyFilter.Filter.FilterType`](#EnvoyFilter-Filter-FilterType)|必要字段。要实例化的过滤器的类型。|
|`filterName`|`string`|必要字段。要初始化的过滤器的名称。名字必须能够匹配到支持的编译进 Envoy 的过滤器。|
|`filterConfig`|[`google.protobuf.Struct`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|必要字段。为实例化的过滤器指定配置内容。|

## `EnvoyFilter.Filter.FilterType`

|字段|描述|
|---|---|
|`INVALID`|占位符。|
|`HTTP`|Http 过滤器。|
|`NETWORK`|网络过滤器。|

## `EnvoyFilter.InsertPosition`

在过滤器链条中指定位置，用于插入新的 Envoy 过滤器配置。

|字段|类型|描述|
|---|---|---|
|`index`|[`EnvoyFilter.InsertPosition.Index`](#EnvoyFilter-InsertPosition-Index)|过滤器在链条中的位置。|
|`relativeTo`|`string`|如果指定了 `BEFORE` 或者 `AFTER`，这里就要输入相对位置所参考的过滤器名称。|

## `EnvoyFilter.InsertPosition.Index`

过滤器链条中的索引或位置。

|字段|描述|
|---|---|
|`FIRST`|插入首位。|
|`LAST`|插入末尾。|
|`BEFORE`|指定过滤器之前。|
|`AFTER`|指定过滤器之后。|

## `EnvoyFilter.ListenerMatch`

选择一个监听器，在符合条件的情况下加入过滤器配置。`ListenerMatch` 中列出的所有条件全部符合（逻辑与）的情况下才能进行插入。

|字段|类型|描述|
|---|---|---|
|`portNumber`|`uint32`|进行通信的服务或网关端口。如果没有指定这一字段，则匹配所有的监听器。即使是为实例或者 Pod 生成的入站连接监听器，也只应该使用服务端口进行匹配。|
|`portNamePrefix`|`string`|除了用具体端口之外，还可以用端口名称的前缀进行大小写无关的匹配。例如 `mongo` 前缀可以匹配 `mongo-port`、`mongo`、`mongoDB` 以及 `MONGO` 等。|
|`listenerType`|[`EnvoyFilter.ListenerMatch.ListenerType`](#EnvoyFilter-ListenerMatch-ListenerType)|入站和出站两种类型。如果没有指定，则匹配所有监听器。|
|`listenerProtocol`|[`EnvoyFilter.ListenerMatch.ListenerProtocol`](#envoyfilter-listenermatch-listenerprotocol)|为同一协议指定监听器。如果没有指定，会把监听器应用到所有协议上。协议选择可以是所有 HTTP 监听器（包括 HTTP2/gRPC/HTTPS（Envoy 作为 TLS 终结器） ）或者所有 TCP 监听器（包括利用 SNI 进行的 HTTPS 透传）。|
|`address`|`string[]`|监听器绑定的一个或多个 IP 地址。如果不为空，应该至少匹配其中一个地址。|

## `EnvoyFilter.ListenerMatch.ListenerProtocol`

|字段|描述|
|---|---|
|`ALL`|所有协议。|
|`HTTP`|HTTP 或者 HTTPS（由 Envoy 完成终结）/HTTP2/gRPC。|
|`TCP`|任意非 HTTP 监听器。|

## `EnvoyFilter.ListenerMatch.ListenerType`

|字段|描述|
|---|---|
|`ANY`|所有监听器。|
|`SIDECAR_INBOUND`|Sidecar 中的入站监听器。|
|`SIDECAR_OUTBOUND`|Sidecar 中的出站监听器。|
|`GATEWAY`|网关监听器。|

## `Gateway`

`Gateway` 描述了一个负载均衡器，用于承载网格边缘的进入和发出连接。这一规范中描述了一系列开放端口，以及这些端口所使用的协议、负载均衡的 SNI 配置等内容。

例如下面的 `Gateway` 配置设置了一个代理服务器，用来开放 80 和 9090 两个 http 端口，443 的 https 端口以及 2379 的 TCP 端口，这些端口都用于入站连接。标签为 `app: my-gateway-controller` 的 Pod 充当了代理服务器的角色，示例定义会发送给这些 Pod。Istio 通过这样的配置，要求代理服务器监听这些端口，另外用户应该确保外部流量能够顺利到达网格边缘的这些开放端口。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: my-gateway
spec:
  selector:
    app: my-gatweway-controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - uk.bookinfo.com
    - eu.bookinfo.com
    tls:
      httpsRedirect: true # 用 301 重定向指令响应 http 协议的请求。
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - uk.bookinfo.com
    - eu.bookinfo.com
    tls:
      mode: SIMPLE # 在这一端口开放 https 服务。
      serverCertificate: /etc/certs/servercert.pem
      privateKey: /etc/certs/privatekey.pem
  - port:
      number: 9080
      name: http-wildcard
      protocol: HTTP
    hosts:
    - "*"
  - port:
      number: 2379 # 用外部端口 2379 来开放内部服务。
      name: mongo
      protocol: MONGO
    hosts:
    - "*"
{{< /text >}}

上面的 `Gateway` 定义了四层到六层的负载均衡属性。而 `VirtualService` 会绑定到一个 `Gateway`，来控制到达指定主机或者网关端口的流量转发行为。

例如下面的 `VirtualService` 的定义，流量分别来自四个来源（`https://uk.bookinfo.com/reviews`、 `https://eu.bookinfo.com/reviews`、`http://uk.bookinfo.com:9080/reviews` 以及  `http://eu.bookinfo.com:9080/reviews`）；而内部服务 `reviews` 开放了 9080 端口，分为两个版本，分别是 `prod` 和 `qa`，`VirtualService` 对象在来源和内部服务的版本之间建立了路由规则。

另外包含 cookie `user: dev-123` 的请求会发送给 `qa` 版本中的特殊端口 7777。同样的规则在网格内部对 `reviews.prod.svc.cluster.local` 的调用中也是成立的。该规则适用于 443 和 9080 两个端口，而对 80 端口的访问会被重定向到 443 端口——也就是说 `http://uk.bookinfo.com` 会转向 `https://uk.bookinfo.com`。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo-rule
spec:
  hosts:
  - reviews.prod.svc.cluster.local
  - uk.bookinfo.com
  - eu.bookinfo.com
  gateways:
  - my-gateway
  - mesh # 代表网格中的所有 Sidecar
  http:
  - match:
    - headers:
        cookie:
          user: dev-123
    route:
    - destination:
        port:
          number: 7777
        host: reviews.qa.svc.cluster.local
  - match:
      uri:
        prefix: /reviews/
    route:
    - destination:
        port:
          number: 9080 # 如果 reviews 服务中只有这一个端口，可以省略这一字段。
        host: reviews.prod.svc.cluster.local
      weight: 80
    - destination:
        host: reviews.qa.svc.cluster.local
      weight: 20
{{< /text >}}

下面的 `VirtualService` 定义将外部对 27017 端口的访问重定向到内部的 `Mongo` 服务的 5555 端口。这一规则对网格内的调用是无效的，这是因为 `Gateway` 列表中没有包含 `mesh` 网关。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo-Mongo
spec:
  hosts:
  - mongosvr.prod.svc.cluster.local # 内部的 Mongo 服务
  gateways:
  - my-gateway
  tcp:
  - match:
    - port: 27017
    route:
    - destination:
        host: mongo.prod.svc.cluster.local
        port:
          number: 5555
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`servers`|[`Server`](#Server)|必要字段。`Server` 定义列表。|
|`selector`|`map<string, string>`|必要字段。用一个或多个标签来选择一组 Pod 或虚拟机，用于应用 `Gateway` 配置。标签选择的范围是平台相关的。例如在 Kubernetes 上，选择范围包含所有可达的命名空间。|

## `HTTPFaultInjection`

|字段|类型|描述|
|---|---|---|
|`delay`|[`HTTPFaultInjection.Delay`](#HTTPFaultInjection-Delay)|转发之前加入延迟，用于模拟网络故障、上游服务过载等故障。|
|`abort`|[`HTTPFaultInjection.Abort`](#HTTPFaultInjection-Abort)|终止请求并向下游服务返回错误代码，模拟上游服务出错的状况。|

## `HTTPFaultInjection.Abort`

这个配置会提前终止请求，并返回预定义的错误码。下面的例子中，`ratings:v1` 服务的请求中，有 10% 会被中断并得到一个 400 的错误码：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-route
spec:
  hosts:
  - ratings.prod.svc.cluster.local
  http:
  - route:
    - destination:
        host: ratings.prod.svc.cluster.local
        subset: v1
    fault:
      abort:
        percent: 10
        httpStatus: 400
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`percent`|`int32`|取值范围在 0 和 100 之间，用来指定中断请求的比例。如果没有指定 `percent`，则中断所有请求。|
|`httpStatus`|`int32`|必要字段。用来定义返回给客户端服务的**有效的 HTTP 错误代码**。|

## `HTTPFaultInjection.Delay`

`Delay` 配置用来在请求的转发路径上注入延迟。下面的例子中的流量，来源于标签 `env: prod` 的 Pod，目标服务为 `reviews` 的 `v1` 版本，我们会在其中的 10% 注入 5 秒钟的延迟。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews-route
spec:
  hosts:
  - reviews.prod.svc.cluster.local
  http:
  - match:
    - sourceLabels:
        env: prod
    route:
    - destination:
        host: reviews.prod.svc.cluster.local
        subset: v1
    fault:
      delay:
        percent: 10
        fixedDelay: 5s
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`percent`|`int32`|取值范围在 0 和 100 之间，用来指定注入延迟的比例。如果没有指定 `percent`，为所有请求进行延迟注入。|
|`fixedDelay`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|必要字段。在请求转发之前加入的固定延迟。可选单位包括小时（`h`）、分钟（`m`）、秒钟（`s`）以及毫秒（`ms`），允许的最小值是 `1ms`。|

## `HTTPMatchRequest`

`HttpMatchRequest` 包含一系列的筛选条件，给规则提供对 HTTP 请求的选择能力。例如下面文档中的匹配条件，要求请求 URL 前缀为 `/ratings/v2/`，并且 `end-user` Header 的值为 `jason`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-route
spec:
  hosts:
  - ratings.prod.svc.cluster.local
  http:
  - match:
    - headers:
        end-user:
          exact: jason
      uri:
        prefix: "/ratings/v2/"
    route:
    - destination:
        host: ratings.prod.svc.cluster.local
{{< /text >}}

在 `VirtualService` 定义中，`HTTPMatchRequest` 不可为空。

|字段|类型|描述|
|---|---|---|
|`uri`|[`StringMatch`](#StringMatch)|URI 的匹配要求，大小写敏感。|
|`scheme`|[`StringMatch`](#StringMatch)|URI 模式的匹配要求，大小写敏感。|
|`method`|[`StringMatch`](#StringMatch)|HTTP 方法的匹配条件，大小写敏感。|
|`authority`|[`StringMatch`](#StringMatch)|HTTP 认证值的匹配要求，大小写敏感。|
|`headers`|`map<string,` [`StringMatch`](#StringMatch)`>`|Header 的键必须是小写的，使用连字符作为分隔符，例如 `x-request-id`。Headers 的匹配同样是大小写敏感的。**注意在 Header 中的 `uri`、`shceme`、`method` 以及 `authority` 会被忽略。**|
|`port`|`uint32`|指定主机上的端口。有的服务只开放一个端口，有的服务会用协议作为前缀给端口命名，这两种情况下，都不需要显式的指明端口号。|
|`sourceLabels`|`map<string, string>`|用一个或多个标签选择工作负载，应用到规则之中。如果 `VirtualService` 中指定了 `gateways` 字段，需要将保留的 `mesh` 也加入列表，才能让这一字段生效。|
|`gateways`|`string[]`|规则所涉及的 `Gateway` 的名称列表。这一字段会覆盖 `VirtualService` 自身的 `gateways` 设置。`gateways` 匹配是独立于 `sourceLabels` 的。|

## `HTTPRedirect`

`HTTPReidrect` 用来向下游服务发送 301 转向响应，并且能够用特定值来替换响应中的认证/主机以及 URI 部分。例如下面的规则会把向 `ratings` 服务的 `/v1/getProductRatings` 路径发送的请求重定向到 `bookratings` 服务的 `/v1/bookRatings`。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-route
spec:
  hosts:
  - ratings.prod.svc.cluster.local
  http:
  - match:
    - uri:
        exact: /v1/getProductRatings
  redirect:
    uri: /v1/bookRatings
    authority: newratings.default.svc.cluster.local
  ..
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`uri`|`string`|在转发时用这个字段的值来替换 URL 的路径部分。注意不管条件是前缀匹配还是完全匹配，整个路径都会被完全替换。|
|`authority`|`string`|在转发时把认证和主机部分用这一字段的值进行替换。|

## `HTTPRetry`

用于定义 HTTP 请求失败时的重试策略。例如下面的配置，对 `ratings:v1` 的流量进行了重试设置，最大重试测试为 3，每次重试的超时时间为 2 秒钟。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-route
spec:
  hosts:
  - ratings.prod.svc.cluster.local
  http:
  - route:
    - destination:
        host: ratings.prod.svc.cluster.local
        subset: v1
    retries:
      attempts: 3
      perTryTimeout: 2s
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`attempts`|`uint32`|必要字段。为特定请求设置重试次数。重试之间的间隔是自动决定的（最少 25 毫秒）。实际重试次数还受[路由规则](#HTTPRoute)中 `timeout` 设置的限制。|
|`perTryTimeout`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|每次重试的超时时间。可选单位包括小时（`h`）、分钟（`m`）、秒钟（`s`）以及毫秒（`ms`），允许的最小值是 `1ms`。|

## `HTTPRewrite`

`HTTPRewrite` 用来在 HTTP 请求被转发到目标之前，对请求内容进行部分改写。`Rewrite` 原语只能用在 `DestinationWrights` 中。下面的例子演示了如何在进行对 `ratings` 服务的 API 调用之前，对 URL 前缀（`/ratings`）进行改写：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ratings-route
spec:
  hosts:
  - ratings.prod.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /ratings
    rewrite:
      uri: /v1/bookRatings
    route:
    - destination:
        host: ratings.prod.svc.cluster.local
        subset: v1
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`uri`|`string`|重写 URI 的路径（或前缀）部分。如果原始 URI 是基于前缀的，这里的值就会对匹配的前缀进行替换。|
|`authority`|`string`|用这个值重写认证/主机部分。|

## `HTTPRoute`

为 HTTP/1.1、HTTP2 以及 gRPC 流量描述匹配条件和对应动作。可以参考 [`VirtualService`](#VirtualService) 查看使用方法。

|字段|类型|描述|
|---|---|---|
|`match`|[`HTTPMatchRequest[]`](#HTTPMatchRequest)|激活规则所需的匹配条件。一个 `match` 块内条件之间都是逻辑与关系；`match` 块之间是逻辑或关系。任何一个 `match` 块匹配成功，都会激活规则。|
|`route`|[`DestinationWeight[]`](#DestinationWeight)|HTTP 规则对流量可能进行重定向或者转发（缺省）。转发目标可以是服务的多个版本中的一个。服务版本所关联的 [`DestinationWeight`](#DestinationWeight) 则决定了不同目标之间的流量分配比重。|
|`redirect`|[`HTTPRedirect`](#HTTPRedirect)|HTTP 规则对流量可能进行重定向或者转发（缺省）。如果启用了流量透传选项，会无视 `route` 以及 `redirect` 设置。重定向原语会发送 HTTP 301 指令指向不同的 URI 或认证部分。|
|`rewrite`|[`HTTPRewrite`](#HTTPRewrite)|`Rewrite` HTTP URI 和认证部分。`rewrite` 不能和 `redirect` 共用，并且会在转发之前生效。|
|`timeout`|[`google.protobuf.Duration`]()|HTTP 请求的超时设置。|
|`retries`|[`HTTPRetry`](#HTTPRetry)|HTTP 请求的重试设置。|
|`fault`|[`HTTPFaultInjection`](#HTTPFaultInjection)|应用到 HTTP 请求客户端的故障注入策略。**注意：客户端启用了故障注入之后，超时和重试会被忽略。**|
|`mirror`|[`mirror`](#Destination)|在把 HTTP 请求转发给预期目标的同时，对流量进行镜像并发送给其他目标。出于性能方面的考虑，Sidecar/Gateway 在返回预期目标的响应之前不会等待镜像目标的响应。被镜像的目标同样也会生成统计信息。|
|`corsPolicy`|[`CorsPolicy`](#CorsPolicy)|跨来源资源共享（[CORS](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Access_control_CORS)）。|
|`appendHeaders`|`map<string, string>`|在向目标服务转发请求之前，加入额外的 HTTP Header。|

## `L4MatchAttributes`

四层连接匹配的属性。

> 注意：四层连接的匹配属性支持尚未完成。

|字段|类型|描述|
|---|---|---|
|`destinationSubnets`|`string[]`|目标的 `IPv4` 或者 `IPv6` 地址，可能带有子网标识，`a.b.c.d/xx` 或者 `a.b.c.d` 都有可能。|
|`port`|`uint32`|指定主机上的端口。有的服务只开放一个端口，有的服务会用协议作为前缀给端口命名，这两种情况下，都不需要显式的指明端口号。|
|`sourceLabels`|`map<string, string>`|用一个或多个标签选择工作负载，应用到规则之中。如果 `VirtualService` 中指定了 `gateways` 字段，需要将保留的 `mesh` 也加入列表，才能让这一字段生效。|
|`gateways`|`string[]`|规则所涉及的 `Gateway` 的名称列表。这一字段会覆盖 `VirtualService` 自身的 `gateways` 设置。`gateways` 匹配是独立于 `sourceLabels` 的。|

## `LoadBalancerSettings`

特定目标的负载均衡策略。阅读 [Envoy 负载均衡文档](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/load_balancing.html)能够获得更多这方面的信息。

例如下面的例子中，为所有指向 `ratings` 服务的流量指定了轮询调度算法负载均衡。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
{{< /text >}}

而接下来例子，则为 `ratings` 设置了会话粘连（Soft session affinity）模式的负载均衡，粘连模式所使用的哈希根据 Cookie 中的 `user` 数据得来。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
   name: bookinfo-ratings
spec:
   host: ratings.prod.svc.cluster.local
   trafficPolicy:
      loadBalancer:
       consistentHash:
         httpCookie:
           name: user
           ttl: 0s
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`simple`|[`LoadBalancerSettings.SimpleLB`](#LoadBalancerSettings-SimpleLB)||
|`consistentHash`|[`LoadBalancerSettings.ConsistentHashLB`](#LoadBalancerSettings-ConsistentHashLB)||

## `LoadBalancerSettings.ConsistentHashLB`

基于一致性哈希的负载均衡可以根据 HTTP Header、Cookie 以及其他属性来提供会话粘连（Soft session affinity）功能。这种负载均衡策略只对 HTTP 连接有效。某一目标的粘连关系，会因为负载均衡池中的节点数量的变化而被重置。

|字段|类型|描述|
|---|---|---|
|`httpHeaderName`|`string`|根据 HTTP Header 获得哈希。|
|`httpCookie`|[`LoadBalancerSettings.ConsistentHashLB.HTTPCookie`](#LoadBalancerSettings-ConsistentHashLB-HTTPCookie)|根据 HTTP Cookie 获得哈希。|
|`useSourceIp`|`bool`|根据源 IP 获得哈希。|
|`minimumRingSize`|`uint64`|哈希环所需的最小虚拟节点数量。缺省值为 1024。较大的值会获得较粗糙的负载分布。如果负载均衡池中的主机数量大于虚拟节点数量，每个主机都会被分配一个虚拟节点。|

## `LoadBalancerSettings.ConsistentHashLB.HTTPCookie`

描述用于在一致性哈希负载均衡器中用于生成哈希值的 HTTP Cookie。如果指定的 Cookie 不存在则会被生成。

|字段|类型|描述|
|---|---|---|
|`name`|`string`|必要字段。Cookie 的名称。|
|`path`|`string`|设置 Cookie 的路径。|
|`ttl`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|必要字段。Cookie 的生命期。|

## `LoadBalancerSettings.SimpleLB`

标准负载均衡算法的调整选项。

|字段|描述|
|---|---|
|`ROUND_ROBIN`|轮询调度策略。缺省。|
|`LEAST_CONN`|使用一个 O(1) 复杂度的算法：随机选择两个健康主机，从中选择一个较少请求的主机提供服务。|
|`RANDOM`|随机的负载均衡算法会随机选择一个健康主机。在没有健康检查策略的情况下，随机策略通常会比轮询调度策略更加高效。|
|`PASSTHROUGH`|这个策略会直接把请求发给客户端要求的地址上。这个选项需要慎重使用。这是一种高级用例。参考 [Envoy 的 Original destination 负载均衡](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/load_balancing#original-destination) 一文进一步了解其应用方式。|

## `OutlierDetection`

熔断器的实现需要对每个上游服务主机进行跟踪。对 HTTP 和 TCP 服务都可以生效。对 HTTP 服务来说，如果有主机持续返回 `5xx` 给 API 调用，会被踢出服务池，并持续一个预定义的时间长度；而对于 TCP 服务，到指定主机的连接超时和连接失败都会被记为错误次数，作为持续失败的指标进行统计。参考 Envoy 的 [outlier detection](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/outlier) 可以获取更多信息。

下面的规则为 `reviews` 服务设置了一个 100 个 TCP 连接，以及 1000 个 HTTP2 并发请求同时每个连接不能超过 10 请求的连接池。另外其中还配置了每五分钟扫描一次上游服务主机，连续失败 7 次返回 `5xx` 错误码的主机会被移出连接池 15 分钟。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews-cb-policy
spec:
  host: reviews.prod.svc.cluster.local
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http2MaxRequests: 1000
        maxRequestsPerConnection: 10
    outlierDetection:
      consecutiveErrors: 7
      interval: 5m
      baseEjectionTime: 15m
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`consecutiveErrors`|`int32`|超过这一错误数量之后，主机将会被移出连接池。缺省值为 5。当上游服务是 HTTP 服务时，`5xx` 的返回码会被记为错误；当上游主机提供的是 TCP 服务时，TCP 连接超时和连接错误/故障事件会被记为错误。|
|`interval`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|在移除检测之间的时间间隔。缺省值为 `10s`，必须大于或等于 `1ms`。|
|`baseEjectionTime`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|最小的移除时间长度。主机每次被移除后的隔离时间等于被移除的次数和最小移除时间的乘积。这样的实现，让系统能够自动增加不健康上游服务实例的隔离时间。缺省为值为 `30s`。|
|`maxEjectionPercent`|`int32`|上游服务的负载均衡池中允许被移除的主机的最大百分比。缺省值为 `10%`|

## `Port`

|字段|类型|描述|
|---|---|---|
|`number`|`uint32`|必要字段。一个有效的正整数代表的端口号。|
|`protocol`|`string`|必要字段。该端口开放的服务协议，必须是 `HTTP`、`HTTPS`、`GRPC`、`HTTP2`、`MONGO`、`TCP` 以及 `TLS` 中的一个。TLS 用来指示与非 HTTP 服务的安全连接。|
|`name`|`string`|分配给这一端口的标签。|

## `PortSelector`

`PortSelector` 指定一个端口号，用于匹配或选择最终路由。

|字段|类型|描述|
|---|---|---|
|`number`|`uint32`|有效的端口号。|

## `Server`

`Server` 描述了指定负载均衡端口上的代理服务器属性，例如：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: my-ingress
spec:
  selector:
    app: my-ingress-gateway
  servers:
  - port:
      number: 80
      name: http2
      protocol: HTTP2
    hosts:
    - "*"
{{< /text >}}

另外一个例子：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: my-tcp-ingress
spec:
  selector:
    app: my-tcp-ingress-gateway
  servers:
  - port:
      number: 27018
      name: mongo
      protocol: MONGO
    hosts:
    - "*"
{{< /text >}}

接下来的例子是一个 443 端口上的 TLS 配置：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: my-tls-ingress
spec:
  selector:
    app: my-tls-ingress-gateway
  servers:
  - port:
      number: 443
      name: https
      protocol: HTTPS
    hosts:
    - "*"
    tls:
      mode: SIMPLE
      serverCertificate: /etc/certs/server.pem
      privateKey: /etc/certs/privatekey.pem
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`port`|[`Port`](#Port)|必要字段。代理服务器监听的端口，用于接收连接。|
|`hosts`|`string[]`|必要字段。`Gateway` 公开的主机名列表。最少要有一条记录。在通常的 HTTP 服务之外，也可以用于带有 SNI 的 TLS 服务。可以使用包含通配符前缀的域名，例如 `*.foo.com` 匹配 `bar.foo.com`，`*.com` 匹配 `bar.foo.com` 以及 `example.com`。**注意**：绑定在 `Gateway` 上的 `VirtualService` 必须有一个或多个能够和 `Server` 中的 `hosts` 字段相匹配的主机名。匹配可以是完全匹配或是后缀匹配。例如 `server` 的 `hosts` 字段为 `*.example.com`，如果 `VirtualService` 的 `hosts` 字段定义为 `dev.example.com` 和 `prod.example.com`，就是可以匹配的；而如果`VirtualService` 的 `hosts` 字段是 `example.com` 或者 `newexample.com` 则无法匹配。|
|`tls`|[`Server.TLSOptions`](#Server-TLSOptions)|一组 TLS 相关的选项。这些选项可以把 http 请求重定向为 https，并且设置 TLS 的模式。|

## `Server.TLSOptions`

|字段|类型|描述|
|---|---|---|
|`httpsRedirect`|`bool`|如果设置为真，负载均衡器会给所有 http 连接发送 301 转向指令，要求客户端使用 HTTPS。|
|`mode`|[`Server.TLSOptions.TLSmode`](#Server-TLSOptions-TLSmode)|可选字段：这一字段的值决定了如何使用 TLS。|
|`serverCertificate`|`string`|必要字段。如果 `mode` 设置为 `SIMPLE` 或者 `MUTUAL`，这一字段指定了服务端的 TLS 证书。|
|`privateKey`|`string`|必要字段。如果 `mode` 设置为 `SIMPLE` 或者 `MUTUAL`，这一字段指定了服务端的 TLS 密钥。|
|`caCertificates`|`string`|必要字段。如果 `mode` 设置为 `MUTUAL`，这一字段包含了用于验证客户端证书的 ca 证书。|
|`subjectAltNames`|`string[]`|用于验证客户端证书的一组认证主体名称。|

## `Server.TLSOptions.TLSmode`

代理服务器使用的 TLS 模式。

|字段|描述|
|---|---|
|`PASSTHROUGH`|基于客户端提供的SNI字符串选择上游服务器进行转发。|
|`SIMPLE`|用标准 TLS 加密连接。|
|`MUTUAL`|通过提供客户端证书进行身份验证，并使用双向 TLS 加密与上游的连接。|

## `ServiceEntry`

`ServiceEntry` 能够在 Istio 内部的服务注册表中加入额外的条目，从而让网格中自动发现的服务能够访问和路由到这些手工加入的服务。`ServiceEntry` 描述了服务的属性（DNS 名称、VIP、端口、协议以及端点）。这类服务可能是网格外的 API，或者是处于网格内部但却不存在于平台的服务注册表中的条目（例如需要和 Kubernetes 服务沟通的一组虚拟机服务）。

### 示例：加入外部服务

下面的配置把一组运行在非托管虚拟机上的 MongoDB 加入到 Istio 的服务注册表之中，这样这些服务就可以和其他网格内的服务一样进行使用。对应的 `DestinationRule` 用来初始化到数据库实例的双向 TLS 连接。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-mongocluster
spec:
  hosts:
  - mymongodb.somedomain # 无用
  addresses:
  - 192.192.192.192/24 # VIPs
  ports:
  - number: 27018
    name: mongodb
    protocol: MONGO
  location: MESH_INTERNAL
  resolution: STATIC
  endpoints:
  - address: 2.2.2.2
  - address: 3.3.3.3
{{< /text >}}

相关的 `DestinationRule`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: mtls-mongocluster
spec:
  host: mymongodb.somedomain
  trafficPolicy:
    tls:
      mode: MUTUAL
      clientCertificate: /etc/certs/myclientcert.pem
      privateKey: /etc/certs/client_private_key.pem
      caCertificates: /etc/certs/rootcacerts.pem
{{< /text >}}

### 示例：TLS 透传

下面的例子中，会用到一个 `ServiceEntry` 以及 `VirtualService` 的组合来进行演示，把来自应用的未终结 TLS 流量经过 Sidecar 转发给外部服务。Sidecar 观察 `ClientHello` 消息中的 SNI 值，然后把流量转发给合适的外部服务。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-https
spec:
  hosts:
  - api.dropboxapi.com
  - www.googleapis.com
  - api.facebook.com
  location: MESH_EXTERNAL
  ports:
  - number: 443
    name: https
    protocol: HTTPS
  resolution: DNS
{{< /text >}}

相关的 `VirtualService`，根据 SNI 进行路由：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: tls-routing
spec:
  hosts:
  - api.dropboxapi.com
  - www.googleapis.com
  - api.facebook.com
  tls:
  - match:
    - port: 443
      sniHosts:
      - api.dropboxapi.com
    route:
    - destination:
        host: api.dropboxapi.com
  - match:
    - port: 443
      sniHosts:
      - www.googleapis.com
    route:
    - destination:
        host: www.googleapis.com
  - match:
    - port: 443
      sniHosts:
      - api.facebook.com
    route:
    - destination:
        host: api.facebook.com
{{< /text >}}

### 转发所有外部流量

再来一个例子，演示一个独立的外发流量网关，用于所有外部服务流量的转发：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-httpbin
spec:
  hosts:
  - httpbin.com
  location: MESH_EXTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: DNS
{{< /text >}}

定义一个 `Gateway` 对象来处理所有的外发流量：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
 name: istio-egressgateway
spec:
 selector:
   istio: egressgateway
 servers:
 - port:
     number: 80
     name: http
     protocol: HTTP
   hosts:
   - "*"
{{< /text >}}

相关的 `VirtualService` 会进行从 Sidecar 到网关服务的路由（`istio-egressgateway.istio-system.svc.cluster.local`）以及从网关到外部服务的路由：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: gateway-routing
spec:
  hosts:
  - httpbin.com
  gateways:
  - mesh
  - istio-egressgateway
  http:
  - match:
    - port: 80
      gateways:
      - mesh
    route:
    - destination:
        host: istio-egressgateway.istio-system.svc.cluster.local
  - match:
    - port: 80
      gateway:
      - istio-egressgateway
    route:
    - destination:
        host: httpbin.com
{{< /text >}}

### 示例：通配符域名

下面的例子演示了在外部服务定义中如何使用通配符定义 `hosts`。如果连接必须被路由到应用请求的 IP（例如应用解析 DNS 之后尝试连接到特定 IP 的情况），那么 `resolution` 需要设置为 `NONE`：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-wildcard-example
spec:
  hosts:
  - "*.bar.com"
  location: MESH_EXTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: NONE
{{< /text >}}

### Unix Socket 连接

这个例子中演示的服务，可以用客户端所在主机的 Unix Socket 进行连接。这里的 `resolution` 必须设置为 `STATIC`，注意下面的 `endpoints` 定义：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: unix-domain-socket-example
spec:
  hosts:
  - "example.unix.local"
  location: MESH_EXTERNAL
  ports:
  - number: 80
    name: http
    protocol: HTTP
  resolution: STATIC
  endpoints:
  - address: unix:///var/run/example/socket
{{< /text >}}

### 代理服务器

对基于 HTTP 的服务来说，可以创建一个具有多个 DNS 地址作为后端的 `VirtualService`。在这种场景里，应用可以使用 `HTTP_PROXY` 环境变量来把 API 调用路由到指定后端。例如下面的配置创建了一个不存在的外部服务，命名为 `foo.bar.com`，三个后端进行支撑：`us.foo.bar.com:8080`、`uk.foo.bar.com:9080` 以及 `in.foo.bar.com:7080`。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: ServiceEntry
metadata:
  name: external-svc-dns
spec:
  hosts:
  - foo.bar.com
  location: MESH_EXTERNAL
  ports:
  - number: 80
    name: https
    protocol: HTTP
  resolution: DNS
  endpoints:
  - address: us.foo.bar.com
    ports:
      https: 8080
  - address: uk.foo.bar.com
    ports:
      https: 9080
  - address: in.foo.bar.com
    ports:
      https: 7080
{{< /text >}}

如此定义之后，如果设置了 `HTTP_PROXY=http://localhost/`，从应用到 `http://foo.bar.com` 的访问会到达上面的三个端点组成的负载均衡。换句话说，对 `http://foo.bar.com/baz` 会被翻译为 `http://uk.foo.bar.com/baz`。

|字段|类型|描述|
|---|---|---|
|`hosts`|`string[]`|必要字段。绑定到 `ServiceEntry` 上的主机名。可以是一个带有通配符前缀的 DNS 名称。如果服务不是 HTTP 协议的，例如 `mongo`、TCP 以及 HTTPS 中，`hosts` 中的 DNS 名称会被忽略，这种情况下会使用 `endpoints` 中的 `address` 以及 `port` 来甄别调用目标。|
|`addresss`|`string[]`|服务相关的虚拟 IP。可以是 CIDR 前缀。对 HTTP 服务来说，这一字段会被忽略，而会使用 HTTP 的 `HOST/Authority` Header。而对于非 HTTP 服务，例如 `mongo`、TCP 以及 HTTPS 中，这些主机会被忽略。如果指定了一个或者多个 IP 地址，对于在列表范围内的 IP 的访问会被判定为属于这一服务。如果地址字段为空，服务的鉴别就只能靠目标端口了。在这种情况下，被访问服务的端口一定不能和其他网格内的服务进行共享。换句话说，这里的 Sidecar 会简单的做为 TCP 代理，将特定端口的访问转发到指定目标端点的 IP、主机上去。就无法支持 Unix socket 了。|
|`ports`|[`Port[]`](#Port)|必要字段。和外部服务关联的端口。如果 `endpoints` 是 Unix socket 地址，这里必须只有一个端口。|
|`location`|[`ServiceEntry.Location`](#ServiceEntry-Location)|用于指定该服务的位置，属于网格内部还是外部。|
|`resolution`|[`ServiceEntry.Resolution`](#ServiceEntry-Resolution)|必要字段。主机的服务发现模式。在没有附带 IP 地址的情况下，为 TCP 端口设置解析模式为 NONE 时必须小心。在这种情况下，对任何 IP 的指定端口的流量都是允许的（例如 `0.0.0.0:`）。|
|`endpoints`|[`ServiceEntry.Endpoint[]`](#ServiceEntry-Endpoint)|一个或者多个关联到这一服务的 `endpoint`。|

## `ServiceEntry.Endpoint`

`Endpoint` 为网格内的服务定义了一个网络地址（IP 或者主机名）。

|字段|类型|描述|
|---|---|---|
|`address`|`string`|必要字段。和网络端点关联的地址，不包括端口部分。只有在 `resolution` 设置为 DNS 的时候，才能使用域名，并且其中不可以包含通配符。还可以用 `unix:///absolute/path/to/socket` 的形式使用 Unix socket。|
|`ports`|`map<string, uint32>`|关联到本端点的一系列端口。端口必须和服务中声明的端口相关联。不能使用 `unix://` 地址。|
|`labels`|`map<string, string>`|和端点相关联的一个或多个标签。|

## `ServiceEntry.Location`

`Location` 用于标识这一服务是否处于网格内部。`Location` 决定了很多方面的特性，例如服务间的双向 TLS 认证，策略实施等。当和外部服务通信时，Istio 会停用双向 TLS 认证，策略实施过程也会从服务端改为客户端执行。

|字段|描述|
|---|---|
|`MESH_EXTERNAL`|服务处于网格之外。一般用于提供 API 的外部服务。|
|`MESH_INTERNAL`|服务处于网格之内。典型的情况是用于把非托管环境（加入基于 Kubernetes 的服务网格的虚拟机）中的服务加入网格。|

## `ServiceEntry.Resolution`

`Resolution` 确定代理如何解析服务端点所代表的 IP 地址，从而完成路由过程。应用程序的 IP 地址解析是不受这一字段影响的。应用本身还是会使用 DNS 完成服务到 IP 的解析，这样外发流量才能够被代理捕获。另外对于 HTTP 服务来说，应用可以直接和代理服务器通信，从而间接的完成和服务的通信。

|字段|描述|
|---|---|
|`NONE`|假设进入连接已经被解析为一个特定的目标 IP 地址。这种连接通常是由代理使用 IP table REDIRECT 或者 eBPF 之类的机制转发而来的。完成路由相关的转换之后，代理服务器会将连接转发到该 IP 地址。|
|`STATIC`|使用 `endpoints` 中指定的静态 IP 地址作为服务后端。（参见下一条）|
|`DNS`|处理请求时尝试向 DNS 查询 IP 地址。如果没有指定 `endpoints`，并且没有使用通配符。代理服务器会使用 DNS 解析 `hosts` 字段中的地址。如果指定了 `endpoints`，那么指定的地址就会作为目标 IP 地址。DNS 解析不能用在 Unix domain 端点上。|

## `StringMatch`

描述如何进行字符串匹配，匹配过程是大小写敏感的。

|字段|类型|描述|
|---|---|---|
|`extract`|`string`|完全匹配。|
|`prefix`|`string`|前缀匹配。|
|`regex`|`string`|`ECMAscript` 风格的正则表达式匹配。|

## `subset`

`Subset` 是服务端点的一个成员，可以用于 A/B 测试或者分版本路由等场景。参考 [`VirtualService`](#VirtualService) 文档，其中会有更多这方面应用的例子。另外服务级的流量策略可以在 `subset` 级中进行覆盖。下面的规则针对的是一个名为 `testversion` 的子集，这个子集是根据标签（`version: v3`）选出的，为这个子集使用了轮询调度的负载均衡策略。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN
  subsets:
  - name: testversion
    labels:
      version: v3
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN

{{< /text >}}

> 注意：在路由规则显式引用一个 `Subset` 的时候，该 `Subset` 定义的策略才会生效。

|字段|类型|描述|
|---|---|---|
|`name`|`string`|必要字段。服务名和 `subset` 名称可以用于路由规则中的流量拆分。|
|`labels`|`map<string, string>`|必要字段。使用标签对服务注册表中的服务端点进行筛选。|
|`trafficPolicy`|[`TrafficPolicy`](#TrafficPolicy)|应用到这一子集的流量策略。缺省情况下子集会继承 `DestinationRule` 级别的策略，这一字段的定义则会覆盖缺省的继承策略。|

## `TCPRoute`

描述 TCP 流量的特征匹配和相关动作。下面的路由规则会把到达 27017 端口的流量转发给 `mongo.prod.svc.cluster.local` 这一服务的 5555 端口。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo-Mongo
spec:
  hosts:
  - mongo.prod.svc.cluster.local
  tcp:
  - match:
    - port: 27017
    route:
    - destination:
        host: mongo.backup.svc.cluster.local
        port:
          number: 5555
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`match`|[`L4MatchAttributes[]`](#L4MatchAttributes)|激活规则所需的匹配条件。一个 `match` 块内条件之间都是逻辑与关系；`match` 块之间是逻辑或关系。任何一个 `match` 块匹配成功，都会激活规则。|
|`route`|[`DestinationWeight[]`](#DestinationWeight)|流量的转发目标。目前 TCP 服务只允许一个转发目标。当 Envoy 支持 TCP 权重路由之后，这里就可以使用多个目标了。|

## `TLSMatchAttributes`

TLS 连接属性匹配。

|字段|类型|描述|
|---|---|---|
|`sniHosts`|`string[]`|必要字段。要匹配的 SNI（服务器名称指示）。可以在 SNI 匹配值中使用通配符。比如 `*.com` 可以同时匹配 `foo.example.com` 和 `example.com`。|
|`destinationSubnets`|`string[]`|`IPv4` 或者 `IPv6` 的目标地址，可能带有子网信息，例如 `a.b.c.d` 形式或者 `a.b.c.d`。|
|`port`|`uint32`|指定主机服务的监听端口。很多服务只暴露一个端口，或者用协议前缀给端口命名，这种情况下就都不需要显式的指定端口号。|
|`sourceLabels`|`map<string, string>`|一个或多个标签用于指示规则在工作负载中的的适用范围。如果 `VirtualService` 中指定了 `gateway`，要使用标签过滤，还要加入 `mesh` 这一缺省网关才能生效。|
|`gateways`|`string[]`|规则所涉及的 `Gateway` 的名称列表。这一字段会覆盖 `VirtualService` 自身的 `gateways` 设置。`gateways` 匹配是独立于 `sourceLabels` 的。|

## `TLSRoute`

描述透传 TLS 流量的特征匹配和相关动作。下面的例子将到达 `mygateway` 网关 443 端口的透传 TLS 流量根据 SNI 值转发给网格内部的服务。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo-sni
spec:
  hosts:
  - "*.bookinfo.com"
  gateways:
  - mygateway
  tls:
  - match:
    - port: 443
      sniHosts:
      - login.bookinfo.com
    route:
    - destination:
        host: login.prod.svc.cluster.local
  - match:
    - port: 443
      sniHosts:
      - reviews.bookinfo.com
    route:
    - destination:
        host: reviews.prod.svc.cluster.local
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`match`|[`TLSMatchAttributes[]`](#TLSMatchAttributes)|必要字段。激活规则所需的匹配条件。一个 `match` 块内条件之间都是逻辑与关系；`match` 块之间是逻辑或关系。任何一个 `match` 块匹配成功，都会激活规则。|
|`route`|[`DestinationWeight[]`](#DestinationWeight)|流量的转发目标。目前 TLS 服务只允许一个转发目标。当 Envoy 支持 TCP 权重路由之后，这里就可以使用多个目标了。|

## `TLSSettings`

SSL/TLS 相关的上游服务设置。参考 Envoy 的 [TLS 上下文](https://www.envoyproxy.io/docs/envoy/latest/api-v1/cluster_manager/cluster_ssl.html#config-cluster-manager-cluster-ssl)来获取更多细节。这些设置对 HTTP 和 TCP 上游服务都有效。

例如下面的规则配置，要求客户端使用双向 TLS 连接上游的数据库集群。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: db-mtls
spec:
  host: mydbserver.prod.svc.cluster.local
  trafficPolicy:
    tls:
      mode: MUTUAL
      clientCertificate: /etc/certs/myclientcert.pem
      privateKey: /etc/certs/client_private_key.pem
      caCertificates: /etc/certs/rootcacerts.pem
{{< /text >}}

接下来的规则配置，如果连接外部服务的域名能够匹配到 `*.foo.com`，就需要使用 TLS。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: tls-foo
spec:
  host: "*.foo.com"
  trafficPolicy:
    tls:
      mode: SIMPLE
{{< /text >}}

下面的规则配置客户端，在访问 `ratings` 服务的时候使用双向 TLS。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: ratings-istio-mtls
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy:
    tls:
      mode: ISTIO_MUTUAL
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`mode`|[`TLSSettings.TLSmode`](#TLSSettings-TLSmode)|必要字段。连接该端口是否需要使用 TLS。这个字段的值决定了端口的加密要求。|
|`clientCertificate`|`string`|`mode` 字段为 `MUTUAL` 的情况下，该字段为必要字段。字段值代表用于客户端 TLS 认证的证书。如果 `mode` 取值为 `ISTIO_MUTUAL`，该字段应该为空。|
|`privateKey`|`string`|`mode` 字段为 `MUTUAL` 的情况下，该字段为必要字段。该字段的值代表客户端私钥文件。如果 `mode` 取值为 `ISTIO_MUTUAL`，该字段应该为空。|
|`caCertificates`|`string`|可选字段。这一字段包含了用于验证服务端证书的 ca 证书。如果省略该字段，则不会对服务端证书进行校验。如果 `mode` 取值为 `ISTIO_MUTUAL`，该字段应该为空。|
|`subjectAltNames`|`string[]`|一个可选名称列表，用于校验证书中的主体标识。如果该字段有赋值，代理服务器会检查服务器证书中的记录是否在该字段的范围之内。如果 `mode` 取值为 `ISTIO_MUTUAL`，该字段应该为空。|
|`sni`|`string`|TLS 握手过程中使用的 SNI 字符串。如果 `mode` 取值为 `ISTIO_MUTUAL`，该字段应该为空。|

## `TLSSettings.TLSmode`

TLS 连接模式。

|字段|描述|
|---|---|
|`DISABLE`|不要为上游端点使用 TLS。|
|`SIMPLE`|向上游端点发起 TLS 连接。|
|`MUTUAL`|发送客户端证书进行验证，用双向 TLS 连接上游端点。|
|`ISTIO_MUTUAL`|发送客户端证书进行验证，用双向 TLS 连接上游端点。和 `MUTUAL` 相比，这种方式使用的双向 TLS 证书系统是由 Istio 生成的。如果使用这种模式，`TLSSettings` 中的其他字段应该留空。|

## `TrafficPolicy`

特定目标的流量策略，对所有目标端口生效。参考 `DestinationRule`。

|字段|类型|描述|
|---|---|---|
|`loadBalancer`|[`LoadBalancerSettings`](#LoadBalancerSettings)|设置负载均衡算法。|
|`connectionPool`|[`ConnectionPoolSettings`](#ConnectionPoolSettings)|设置上游服务的连接池。|
|`outlierDetection`|[`OutlierDetection`](#OutlierDetection)|从负载均衡池中移除不健康主机的设置。|
|`tls`|[`TLSSettings`](#TLSSettings)|和上游服务进行 TLS 连接的相关设置。|
|`portLevelSettings`|[`TrafficPolicy.PortTrafficPolicy[]`](#TrafficPolicy-PortTrafficPolicy)|针对单独端口设置的流量策略。端口级别的策略设置会覆盖目标级别的策略，另外在端口级别策略中省略的字段会以缺省值进行工作，而不会继承目标级策略中的设置。|

## `TrafficPolicy.PortTrafficPolicy`

应用到服务端口的流量策略。

|字段|类型|描述|
|---|---|---|
|`port`|[`PortSelector`](#PortSelector)||
|`loadBalancer`|[`LoadBalancerSettings`](#LoadBalancerSettings)|设置负载均衡算法。|
|`connectionPool`|[`ConnectionPoolSettings`](#ConnectionPoolSettings)|设置上游服务的连接池。|
|`outlierDetection`|[`OutlierDetection`](#OutlierDetection)|从负载均衡池中移除不健康主机的设置。|
|`tls`|[`TLSSettings`](#TLSSettings)|和上游服务进行 TLS 连接的相关设置。|

## `VirtualService`

`VirtualService` 定义了一系列针对指定服务的流量路由规则。每个路由规则都针对特定协议的匹配规则。如果流量符合这些特征，就会根据规则发送到服务注册表中的目标服务（或者目标服务的子集或版本）。

匹配规则中还包含了对流量发起方的定义，这样一来，规则还可以针对特定客户上下文进行定制。

接下来是一个 Kubernetes 上的例子，缺省把所有的 HTTP 流量发送给 `reviews` 服务中标签为 `version: v1` 的 Pod。另外包含 `/wpcatalog/` 或 `/consumercatalog/` URL 前缀的请求会被重写为 `/newcatalog` 并发送给标签为 `version: v2` 的 Pod。

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews-route
spec:
  hosts:
  - reviews.prod.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: "/wpcatalog"
    - uri:
        prefix: "/consumercatalog"
    rewrite:
      uri: "/newcatalog"
    route:
    - destination:
        host: reviews.prod.svc.cluster.local
        subset: v2
  - route:
    - destination:
        host: reviews.prod.svc.cluster.local
        subset: v1
{{< /text >}}

目标的的子集或者说版本是通过 `DestinationRule` 中的定义得来的：

{{< text yaml >}}
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews-destination
spec:
  host: reviews.prod.svc.cluster.local
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|`hosts`|`string[]`|必要字段：流量的目标主机。可以是带有通配符前缀的 DNS 名称，也可以是 IP 地址。根据所在平台情况，还可能使用短名称来代替 FQDN。这种场景下，短名称到 FQDN 的具体转换过程是要靠下层平台完成的。**一个主机名只能在一个 `VirtualService` 中定义。**同一个 `VirtualService` 中可以用于控制多个 HTTP 和 TCP 端口的流量属性。 Kubernetes 用户注意：当使用服务的短名称时（例如使用 `reviews`，而不是 `reviews.default.svc.cluster.local`），Istio 会根据规则所在的命名空间来处理这一名称，而非服务所在的命名空间。假设 “default” 命名空间的一条规则中包含了一个 `reviews` 的 `host` 引用，就会被视为 `reviews.default.svc.cluster.local`，而不会考虑 `reviews` 服务所在的命名空间。**为了避免可能的错误配置，建议使用 FQDN 来进行服务引用。** `hosts` 字段对 HTTP 和 TCP 服务都是有效的。网格中的服务也就是在服务注册表中注册的服务，必须使用他们的注册名进行引用；只有 `Gateway` 定义的服务才可以使用 IP 地址。|
|`gateways`|`string[]`|`Gateway` 名称列表，Sidecar 会据此使用路由。`VirtualService` 对象可以用于网格中的 Sidecar，也可以用于一个或多个 `Gateway`。这里公开的选择条件可以在协议相关的路由过滤条件中进行覆盖。保留字 `mesh` 用来指代网格中的所有 Sidecar。当这一字段被省略时，就会使用缺省值（`mesh`），也就是针对网格中的所谓 Sidecar 生效。如果提供了 `gateways` 字段，这一规则就只会应用到声明的 `Gateway` 之中。要让规则同时对 `Gateway` 和网格内服务生效，需要显式的将 `mesh` 加入 `gateways` 列表。|
|`http`|[`HTTPRoute[]`](#HTTPRoute)|HTTP 流量规则的有序列表。这个列表对名称前缀为 `http-`、`http2-`、`grpc-` 的服务端口，或者协议为 `HTTP`、`HTTP2`、`GRPC` 以及终结的 TLS，另外还有使用 `HTTP`、`HTTP2` 以及 `GRPC` 协议的 `ServiceEntry` 都是有效的。进入流量会使用匹配到的第一条规则。|
|`tls`|[`TLSRoute[]`](#TLSRoute)|一个有序列表，对应的是透传 TLS 和 HTTPS 流量。路由过程通常利用 `ClientHello` 消息中的 SNI 来完成。TLS 路由通常应用在 `https-`、`tls-` 前缀的平台服务端口，或者经 `Gateway` 透传的 HTTPS、TLS 协议 端口，以及使用 HTTPS 或者 TLS 协议的 `ServiceEntry` 端口上。**注意：没有关联 `VirtualService` 的 `https-` 或者 `tls-` 端口流量会被视为透传 TCP 流量。**|
|`tcp`|[`TCPRoute[]`](#TCPRoute)|一个针对透传 TCP 流量的有序路由列表。TCP 路由对所有 HTTP 和 TLS 之外的端口生效。进入流量会使用匹配到的第一条规则。|
