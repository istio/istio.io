---
title: 安全
description: 描述 Istio 的授权与认证功能。
weight: 30
keywords: [security,authentication,authorization,rbac,access-control]
---

在不修改代码的情况下，增强微服务自身以及微服务之间通信的安全性，是 Istio 的重要目标。它负责提供以下功能：

* 为每个服务提供强认证，认证身份和角色相结合，能够在不同的集群甚至不同云上进行互操作
* 加密服务和服务之间、最终用户和服务之间的通信
* 提供密钥管理系统，完成密钥和证书的生成、分发、轮转以及吊销操作

下图展示了 Istio 安全相关的架构，其中包含了三个主要的组件：认证、密钥管理以及通信加密。图中的 `frontend` 服务以 Service account `frontend-team` 的身份运行；`backend` 服务以 Service account `backend-team` 的身份运行，Istio 会对这两个服务之间的通信进行加密。除了运行在 Kubernetes 上的服务之外，Istio 还能为虚拟机和物理机上的服务提供支持。

{{< image width="80%" ratio="56.25%"
    link="/docs/concepts/security/auth.svg"
    alt="Istio 安全模型的组件构成。"
    caption="Istio 安全架构"
    >}}

如图所示，Istio 的 Citadel 用加载 Secret 卷的方式在 Kubernetes 容器中完成证书和密钥的分发。如果服务运行在虚拟机或物理机上，则会使用运行在本地的 Node agent，它负责在本地生成私钥和 CSR(证书签发申请)，把 CSR 发送给 Citadel 进行签署，并把生成的证书和私钥分发给 Envoy。

## 双向 TLS 认证

### 身份

Istio 使用 [Kubernetes service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) 来识别谁在运行服务：

* Istio 中的 Service account 格式为 `spiffe://<domain>/ns/<namespace>/sa/<serviceaccount>`
    * _domain_ 目前是 _cluster.local_ ，我们将很快支持域的定制化。
    * _namespace_ 是 Kubernetes service account 所在的命名空间。
    * _serviceaccount_ 是 Kubernetes service account 的名称。

* Service account 是**工作负载运行的身份（或角色）**，表示该工作负载的权限。对于需要强大安全性的系统，工作负载的权限不应由随机字符串（如服务名称，标签等）或部署的二进制文件来标识。
    * 例如，假设有一个从多租户数据库中提取数据的工作负载。Alice 和 Bob 都能运行这个工作负载，从中获取数据，但是两个用户最终得到的数据是不同的。

* Service account 能够灵活的识别机器、用户、工作负载或一组工作负载（不同的工作负载可以使用同一 Service account 运行），从而实现强大的安全策略。

* Service account 在工作负载的整个生命周期中不会发生变化。

* 结合域名的约束，能保证 Service account 的唯一性。

### 通信安全

Istio 中，客户端和服务端的 [Envoy](https://envoyproxy.github.io/envoy/) 形成通信隧道，服务间的的通信就是通过这些隧道完成的。端到端通信通过以下方式加密：

* 服务与 Envoy 之间的本地 TCP 连接

* 代理之间的双向 TLS 连接

* 安全命名：在握手过程中，客户端 Envoy 检查服务器端证书提供的 Service account 是否允许运行目标服务

### 密钥管理

Istio 从 0.2 版本开始支持运行于 Kubernetes、虚拟机以及物理机之上的服务。对于每个场景，会使用不同的密钥配置机制。

对于运行在 Kubernetes 集群中的服务，每个集群的 Citadel（证书颁发机构）负责自动化执行密钥和证书管理流程。它主要执行四个关键操作：

* 为每个 Service account 生成一个 [SPIFFE](https://spiffe.github.io/docs/svid) 密钥和证书

* 根据 Service account 将密钥和证书分发给每个 Pod

* 定期轮换密钥和证书

* 必要时撤销特定的密钥和证书对

对于运行在虚拟机或裸机上的服务，上述四个操作会由 Citadel 和 Node agent 协作完成。

### 工作流

这里主要讨论安全工作流，Istio 安全工作流由部署和运行两阶段组成。Kubernetes 和虚拟机/裸机两种情况下的部署阶段是不一致的，因此我们需要分别讨论；然而一旦证书和密钥部署完成，运行阶段就是一致的了。

#### Kubernetes 的部署阶段

1. Citadel 观察 Kubernetes API Server，为每个现有和新的 Service account 创建一个 [SPIFFE](https://spiffe.github.io/docs/svid) 密钥和证书对，并将其发送到 API Server。

1. 当创建 Pod 时，API Server 会根据 Service account 使用 [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/) 来挂载密钥和证书对。

1. [Pilot](/docs/concepts/traffic-management/pilot/) 使用适当的密钥和证书以及安全命名信息生成配置，该信息定义各个 Service account 的可运行服务，并将其传递给 Envoy。

### 虚拟机/物理机的部署阶段

1. Citadel 创建 gRPC 服务来处理 CSR 请求。

1. Node agent 创建私钥和 CSR，发送 CSR 到 Citadel 进行签署。

1. Citadel 验证 CSR 中携带的证书，并签署 CSR 以生成证书。

1. Node agent 将从 Citadel 接收到的证书和私钥发送给 Envoy。

1. 上述 CSR 流程定期重复，从而完成证书的轮转过程。

### 运行时阶段

1. 来自客户端服务的出站流量被重新路由到它本地的 Envoy。

1. 客户端 Envoy 与服务器端 Envoy 开始进行双向 TLS 的握手。在握手期间，它还进行安全的命名检查，以验证服务器证书中显示的服务帐户是否可以运行这一服务。

1. mTLS 连接成功以后，流量将转发到服务器端 Envoy，然后通过本地 TCP 连接转发到服务器服务。

### 最佳实践

在本节中，我们提供一些部署指南，然后讨论一个现实世界的场景。

### 部署指南

* 如果有多个服务运维人员（也称为 [SRE](https://en.wikipedia.org/wiki/Site_reliability_engineering)）在集群中部署不同的服务（通常在中型或大型集群中），我们建议为每个 SRE 团队创建一个单独的 [namespace](https://en.wikipedia.org/wiki/Site_reliability_engineering)，来进行访问隔离。例如，您可以为 team1 创建一个 "team1-ns" 命名空间，为 team2 创建 "team2-ns" 命名空间，这样两个团队就无法访问对方的服务。

* 如果 Citadel 受到威胁，则可能会在集群中暴露它管理的所有密钥和证书。我们**强烈**建议在专门的只有集群管理员才能访问的命名空间（例如 `istio-citadel-ns`）上运行 Citadel。

#### 示例

我们设想一个三层的应用程序，其中有三个服务：`photo-frontend`、`photo-backend` 以及 `datastore`。`photo-frontend` 和 `photo-backend` 由 photo SRE 团队管理，而 `datastore` 服务由 datastore SRE 团队管理。`photo-frontend` 可以访问 `photo-backend`，`photo-backend` 可以访问 `datastore`。但是，`photo-frontend` 无法访问 `datastore`。

在这种情况下，集群管理员创建 3 个命名空间：`istio-citadel-ns`、`photo-ns` 以及 `datastore-ns`。管理员可以访问所有命名空间，每个团队只能访问自己的命名空间。photo SRE 团队创建了两个 Service account，在命名空间 `photo-ns` 中运行 `photo-frontend` 和 `photo-backend`。数据存储 SRE 团队创建一个 Service account 以在命名空间 `datastore-ns` 中运行 `datastore` 服务。此外，我们需要在 [Istio Mixer](/docs/concepts/policies-and-telemetry/) 中使用服务访问控制，以使 `photo-frontend` 无法访问 `datastore`。

在这里，Citadel 为所有的命名空间提供了密钥和证书的管理功能，并在微服务之间进行了隔离。

## 认证策略

Istio 的认证策略让运维人员有机会为一或多个服务指定认证策略。Istio 的认证策略由两部分组成：

* 点对点认证：验证直接连接客户端的身份。通常使用的认证机制就是 [双向 TLS](/docs/concepts/security/mutual-tls/)。
* 来源认证：验证发起请求的原始客户端（例如最终用户、设备等）。目前源认证仅支持 JWT 方式。

Istio 对服务端进行配置，从而完成认证过程，然而他并不会在客户端做这些工作。对于双向 TLS 认证来说，用户可以使用[目标规则](/docs/concepts/traffic-management/#destination-rules)来配置客户端使用这些协议。其他情况下，应用程序需要自行负责获取用户凭据（也就是 JWT），并将获取到的凭据附加到请求之上。

两种认证方式下的身份，通常都会输出给下一层（也就是 Citadel、Mixer）。为了简化认证规则，可以指定生效的认证规则（点对点认证或者来源认证），缺省情况下使用的是点对点认证。

认证策略保存在 Istio 的配置存储中（0.7 中使用的是 Kubernetes CRD 来实现的），控制平面来负责认证策略的分发。传播速度跟集群规模有关，从几秒钟到几分钟都有可能。在这一过程中，通信可能会有中断，也可能出现非预期的认证结果。

{{< image width="80%" ratio="75%"
    link="/docs/concepts/security/authn.svg"
    caption="认证策略架构"
    >}}

策略的的生效范围是在命名空间一级的，还可以在这一命名空间内，用目标选择器来进一步选择服务来确定策略的应用范围。这一行为是和 Kubernetes RBAC 的访问控制模型相一致的。特别需要提出的是，只有命名空间的管理员才能在为该命名空间内的服务设置策略。

认证功能是使用 Istio sidecar 实现的。例如在使用 Envoy sidecar 的情况下，就会落地为一组 SSL 设置和 HTTP filter。如果验证失败，请求就会被拒绝（可能是 SSL 握手失败的错误码、或者 http 401，依赖具体实现机制）。如果验证成功，会生成下列的认证相关属性：

* `source.principal`: 认证方式。如果使用的不是点对点认证，这一属性为空。
* `request.auth.principal`: 绑定的认证方式，可选的取值范围包括 `USE_PEER` 以及 `USE_ORIGIN`。
* `request.auth.audiences`: JWT 中的受众（`aud`）声明（使用 JWT 进行源认证）。
* `request.auth.presenter`: 和上一则类似，指的是 JWT 中的授权者（`azp`）。
* `request.auth.claims`: 原 JWT 中的所有原始报文。

来自认证源的 Principle 不会显式的输出。通常可以通过把 `iss` 和 `sub` 使用 `/` 进行拼接而来（例如 `iss` 和 `sub` 分别是 "*googleapis.com*" 和 "*123456*"，那么源 Principal 就是 "*googleapis.com/123456*"）。另外如果 Principal 设置为 USE_ORIGIN，`request.auth.principal` 的值是和源 Principal 一致的。

### 策略剖析

#### 目标筛选器

策略生效服务范围的定义。如果没有提供选择规则，那么对应策略所在的命名空间中的所有服务都会应用该策略，因此称之为命名空间级别的策略（与此相对应的还有一个服务级别的策略，这种策略的选择规则不允许为空）。Istio 会优先选择服务级的策略，否则会回退到命名空间的策略。如果两个都没有指定，就会使用服务网格中配置的缺省策略或者/以及服务注解中的配置，这些配置只能设置双向 TLS（这是 Istio 0.7 版本之前用于配置双向 TLS 的办法）。参考阅读 [测试 Istio 双向 TLS](/docs/tasks/security/mutual-tls/)

> 0.8 开始，推荐使用认证策略来启用或者禁用各个服务的双向 TLS。未来版本中会移除对服务注解方式的支持。

可能存在多个服务级策略匹配到同一个服务的情况，还可能出现同一个命名空间中创建了多个命名空间级的服务策略的情况，运维人员应负责防止出现这种冲突。

示例：选择 `product-page` 服务（的任何端口），以及 `reviews` 服务的 9000 端口。

{{< text yaml >}}
targets:
- name: product-page
- name: reviews
  ports:
  - number: 9000
{{< /text >}}

#### 点对点认证

定义了点对点认证采用的方式以及对应的参数。可以列出一个或多个方法，选择其中一个即可满足认证要求。然而从 0.7 开始，只支持双向 TLS，如果不需要点对点认证，可以完全省略。

{{< text yaml >}}
peers:
- mtls:
{{< /text >}}

> 从 Istio 0.7 开始，`mtls` 设置不需要任何参数（因此 `-mtls: {}`、`- mtls:` 或者 `- mtls: null` 就足够了）。未来会加入参数，用以提供不同的双向 TLS 实现。

#### 来源认证

定义了来源认证方法以及对应的参数。目前只支持 JWT 认证，然而这个策略可以包含多个不同提供者的不同实现。跟点对点认证类似，只需一个就可以满足认证需求。

{{< text yaml >}}
origins:
- jwt:
    issuer: "https://accounts.google.com"
    jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
{{< /text >}}

### Principal 的绑定

从认证过程中提取数据生成 Principal 的方法定义。缺省情况下会沿用点的 Principal（如果没有使用点对点认证，就会留空）。策略的编写者可以选择使用 `USE_ORIGIN` 进行替换。将来我们还会支持 *conditional-binding* （例如优先选择 `USE_PEER`，如果不可用，则采用 `USE_PRIGIN` ）。

## 基于角色的访问控制（RBAC）

Istio 基于角色的访问控制（RBAC）为 Istio 网格中的服务提供命名空间级、服务级、方法级访问控制。它的特点:

* 简单易用的基于角色的语义
* 服务到服务以及用户端到服务的授权。
* 在角色和角色绑定中可以通过自定义属性保证灵活性。

下面的图表显示了 Istio RBAC 体系结构。操作者可以指定 Istio RBAC 策略。策略则保存在 Istio 配置存储中。

{{< image width="80%" ratio="56.25%"
    link="/docs/concepts/security/IstioRBAC.svg"
    alt="Istio RBAC"
    caption="Istio RBAC 架构"
    >}}

Istio 的 RBAC 引擎做了下面两件事：

* **获取 RBAC 策略**：Istio RBAC 引擎关注 RBAC 策略的变化。如果它看到任何更改，将会获取更新后的 RBAC 策略。
* **授权请求**：在运行时，当一个请求到来时，请求上下文会被传递给 Istio RBAC 引擎。RBAC 引擎根据传递的内容对环境进行评估，并返回授权结果（允许或拒绝）。

### 请求上下文

在当前版本中，Istio RBAC 引擎被实现为一个 [Mixer 适配器](/docs/concepts/policies-and-telemetry/#adapters)。请求上下文则作为[授权模板](/docs/reference/config/policy-and-telemetry/templates/authorization/)的实例。请求上下文中包含了认证模块所需的请求和环境的所有信息。特别是其中的两个部分：

* **subject**：包含调用者标识的属性列表，包括`"user"`（名称/ID），`“group”`（主体所属的组），或者关于主体的任意附加属性，比如命名空间、服务名称。

* **action**：指定访问服务的方法。它包括`“命名空间”`、`“服务”`、`“路径”`、`“方法”`，以及该操作的任何附加属性。

下面我们展示一个请求上下文的例子。

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: authorization
metadata:
  name: requestcontext
  namespace: istio-system
spec:
  subject:
    user: source.user | ""
    groups: ""
    properties:
      service: source.service | ""
      namespace: source.namespace | ""
  action:
    namespace: destination.namespace | ""
    service: destination.service | ""
    method: request.method | ""
    path: request.path | ""
    properties:
      version: request.headers["version"] | ""
{{< /text >}}

### Istio RBAC 策略

Istio RBAC 引入了 `ServiceRole` 和 `ServiceRoleBinding` 两个概念，两者都实现为 Kubernetes 自定义资源（CRD）的形式。

* **`ServiceRole`** 定义了在网格中访问服务的角色。
* **`ServiceRoleBinding`** 将角色绑定到主体（例如，用户、组、服务）之上。

#### `ServiceRole`

一个 `ServiceRole` 包括一个规则列表。每个规则都有以下标准字段：

* **services**：服务名称列表，与请求上下文的 `action.service` 字段匹配。
* **methods**：方法名列表，对应请求上下文的 `action.method`。在上面的 “requestcontext” 中，是 HTTP 或 gRPC 方法。请注意，gRPC 方法是以 “packageName.serviceName/methodName”（区分大小写）的形式进行格式化的。
* **paths**：与请求上下文中 `action.path` 字段相匹配的 HTTP 路径列表。它在 gRPC 的案例中被省略了。

一个 `ServiceRole` 的作用范围只限于 `"metadata"` 字段中所指定的 `namespace` 之中。`services` 和 `method` 在规则中是必需的字段。`path` 是可选项。如果没有指定为 “*”，代表任意实例。

这里有一个简单的角色 `service-admin` 的例子，它可以在 `default` 命名空间中完全访问所有服务。

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRole
metadata:
  name: service-admin
  namespace: default
spec:
  rules:
  - services: ["*"]
    methods: ["*"]
{{< /text >}}

这里是另一个角色 “products-viewer”，它具有对 `default` 命名空间中的服务 `products.default.svc.cluster.local` 进行读取（“GET”和“HEAD”）的权限：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRole
metadata:
  name: products-viewer
  namespace: default
spec:
  rules:
  - services: ["products.default.svc.cluster.local"]
    methods: ["GET", "HEAD"]
{{< /text >}}

此外，规则中所有字段都支持**前缀匹配**和**后缀匹配**。例如可以定义一个 `tester` 角色，该角色在 `default` 命名空间中具有下列权限：

* 对所有前缀为 `test-` 的服务的完全访问（例如：`test-bookstore`、`test-performance`、以及`test-api.default.svc.cluster.local`）。
* 对所有 `/reviews` 后缀的所有路径的读取（"GET"）访问（例如服务 `bookstore.default.svc.cluster.local` 中的：`/books/reviews`、`/events/booksale/reviews` 以及 `/reviews`）。

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRole
metadata:
  name: tester
  namespace: default
spec:
  rules:
  - services: ["test-*"]
    methods: ["*"]
  - services: ["bookstore.default.svc.cluster.local"]
    paths: ["*/reviews"]
    methods: ["GET"]
{{< /text >}}

在 `ServiceRole` 之中，“命名空间”+“服务”+“路径”+“方法”的组合解答了“允许如何访问服务”的问题。在某些情况下，可能要为规则加入附加限制。例如，一条规则可能只适用于服务的某个版本，或者只适用于带有标签 “foo” 的服务。可以使用定制字段轻松地指定这些约束。

例如，下面的 `ServiceRole` 定义扩展了先前的 “products-viewer” 角色：在服务版本中添加了一个约束，即 “v1” 或 “v2”。注意，`version` 属性是由 `requestcontext` 的 `action.properties.version` 字段所提供的。

For example, the following `ServiceRole` definition extends the previous "products-viewer" role by adding a constraint on service "version"
being "v1" or "v2". Note that the "version" property is provided by `"action.properties.version"` in "requestcontext".

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRole
metadata:
  name: products-viewer-version
  namespace: default
spec:
  rules:
  - services: ["products.default.svc.cluster.local"]
    methods: ["GET", "HEAD"]
    constraints:
    - key: "version"
      values: ["v1", "v2"]
{{< /text >}}