---
title: 安全
description: 描述 Istio 的授权与鉴权功能。
weight: 30
keywords: [安全,认证,鉴权,rbac,访问控制]
---

在不修改代码的情况下，增强微服务自身以及微服务之间通信的安全性，是 Istio 的重要目标。它负责提供以下功能：

* 为每个服务提供强认证，认证身份和角色相结合，能够在不同的集群甚至不同云上进行互操作
* 加密服务和服务之间、最终用户和服务之间的通信
* 提供密钥管理系统，完成密钥和证书的生成、分发、轮转以及吊销操作

下图展示了 Istio 安全相关的架构，其中包含了三个主要的组件：认证、密钥管理以及通信安全。图中的 `frontend` 服务以 Service account `frontend-team` 的身份运行；`backend` 服务以 Service account `backend-team` 的身份运行，Istio 会对这两个服务之间的通信进行加密。除了运行在 Kubernetes 上的服务之外，Istio 还能为虚拟机和物理机上的服务提供支持。

{{< image width="80%" ratio="56.25%"
    link="/docs/concepts/security/auth.svg"
    alt="Istio 安全模型的组件构成。"
    caption="Istio 安全架构"
    >}}

如图所示，Istio 的 Citadel 用加载 Secret 卷的方式在 Kubernetes 容器中完成证书和密钥的分发。如果服务运行在虚拟机或物理机上，则会使用运行在本地的 Node agent，它负责在本地生成私钥和 CSR（证书签发申请），把 CSR 发送给 Citadel 进行签署，并把生成的证书和私钥分发给 Envoy。

## 双向 TLS 认证

### 身份

Istio 使用 [Kubernetes service account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) 来识别谁在运行服务：

* Istio 中的 Service account 表达格式为 `spiffe://<domain>/ns/<namespace>/sa/<serviceaccount>`

    * _domain_ 目前是 `cluster.local` ，我们将很快支持域的定制化。
    * _namespace_ 是 Kubernetes service account 所在的命名空间。
    * _serviceaccount_ 是 Kubernetes service account 的名称。

* Service account 是**工作负载运行的身份（或角色）**，表示该工作负载的权限。对于需要强大安全性的系统，工作负载的权限不应由随机字符串（如服务名称，标签等）或部署的二进制文件来标识。例如，假设有一个从多租户数据库中提取数据的工作负载。Alice 和 Bob 都能运行这个工作负载，从中获取数据，但是两个用户最终得到的数据是不同的。

* Service account 能够灵活的识别机器、用户、工作负载或一组工作负载（不同的工作负载可以使用同一 Service account 运行），从而实现强大的安全策略。

* Service account 在工作负载的整个生命周期中不会发生变化。

* 结合域名的约束，能保证 Service account 的唯一性。

### 通信安全

Istio 中，客户端和服务端的 [Envoy](https://envoyproxy.github.io/envoy/) 形成通信隧道，服务间的的通信就是通过这些隧道完成的。端到端通信通过以下方式加密：

* 服务与 Envoy 之间的本地 TCP 连接

* 代理之间的双向 TLS 连接

* 安全命名：在握手过程中，客户端 Envoy 检查服务器端证书提供的 Service account 是否允许运行目标服务

### 密钥管理

Istio 支持运行于 Kubernetes、虚拟机以及物理机之上的服务。对于每个场景，会使用不同的密钥配置机制。

对于运行在 Kubernetes 集群中的服务，每个集群的 Citadel 会扮演证书颁发机构的角色，负责自动化执行密钥和证书管理流程。它主要执行四个关键操作：

* 为每个 Service account 生成一个 [SPIFFE](https://spiffe.github.io/docs/svid) 密钥和证书

* 根据 Service account 将密钥和证书分发给每个 Pod

* 定期轮换密钥和证书

* 必要时撤销特定的密钥和证书对

对于运行在虚拟机或物理机上的服务，上述四个操作会由 Citadel 和 Node agent 协作完成。

### 工作流

Istio 安全工作流由部署和运行两阶段组成。Kubernetes 和虚拟机/裸机两种情况下的部署阶段是不一致的，因此我们需要分别讨论；然而一旦证书和密钥部署完成，接下来的运行阶段就是一致的了。

#### Kubernetes 的部署阶段

1. Citadel 观察 Kubernetes API Server。

1. Citadel 为每个现有和新的 Service account 创建一个 [SPIFFE](https://spiffe.github.io/docs/svid) 密钥和证书对。

1. Citadel 将上一步新建的内容其发送到 API Server。

1. 当创建 Pod 时，API Server 会根据 Service account 使用 [Kubernetes secret](https://kubernetes.io/docs/concepts/configuration/secret/) 来挂载密钥和证书对。

1. [Pilot](/zh/docs/concepts/traffic-management/#pilot-和-envoy) 使用适当的密钥和证书以及安全命名信息生成配置文件，其中定义了各个 Service account 的可运行服务，并将其传递给 Envoy。

#### 虚拟机/物理机的部署阶段

1. Citadel 创建 gRPC 服务来处理 CSR 请求。

1. Node agent 创建私钥和 CSR。

1. Node agent 发送 CSR 到 Citadel 进行签署。

1. Citadel 验证 CSR 中携带的证书。

1. Citadel 签署 CSR 以生成证书。

1. Node agent 将从 Citadel 接收到的证书和私钥发送给 Envoy。

1. 上述 CSR 流程定期重复，从而完成证书的轮转过程。

#### 运行时阶段

1. 来自客户端服务的出站流量被重新路由到它本地的 Envoy。

1. 客户端 Envoy 与服务器端 Envoy 开始进行双向 TLS 的握手。在握手期间，它还进行安全的命名检查，以验证服务器证书中显示的服务帐户是否可以运行这一服务。

1. 客户端 Envoy 和服务端 Envoy 建立双向 TLS 连接。

1. 客户端 Envoy 把流量转发给服务端的 Envoy。

1. 服务端 Envoy 通过本地 TCP 连接把流量转发给服务进程。

### 最佳实践

在本节中，我们提供一些部署指南，然后讨论一个现实世界的场景。

#### 部署指南

如果有多个服务运维人员（也称为 [SRE](https://en.wikipedia.org/wiki/Site_reliability_engineering)）在集群中部署不同的服务（通常在中型或大型集群中），我们建议为每个 SRE 团队创建一个单独的 [namespace](https://en.wikipedia.org/wiki/Site_reliability_engineering)，来进行访问隔离。例如，您可以为 team1 创建一个 "team1-ns" 命名空间，为 team2 创建 "team2-ns" 命名空间，这样两个团队就无法访问对方的服务。

> {{< warning_icon >}} 如果 Citadel 受到威胁，则可能会在集群中暴露它管理的所有密钥和证书。我们**强烈**建议在专门的只有集群管理员才能访问的命名空间（例如 `istio-citadel-ns`）上运行 Citadel。

#### 示例

我们设想一个三层的应用程序，其中有三个服务：`photo-frontend`、`photo-backend` 以及 `datastore`。`photo-frontend` 和 `photo-backend` 由 photo SRE 团队管理，而 `datastore` 服务由 datastore SRE 团队管理。`photo-frontend` 可以访问 `photo-backend`，`photo-backend` 可以访问 `datastore`。但是，`photo-frontend` 无法访问 `datastore`。

在这种情况下，集群管理员创建 3 个命名空间：`istio-citadel-ns`、`photo-ns` 以及 `datastore-ns`。管理员可以访问所有命名空间，每个团队只能访问自己的命名空间。photo SRE 团队创建了两个 Service account，在命名空间 `photo-ns` 中运行 `photo-frontend` 和 `photo-backend`。数据存储 SRE 团队创建一个 Service account 以在命名空间 `datastore-ns` 中运行 `datastore` 服务。此外，我们需要在 [Istio Mixer](/zh/docs/concepts/policies-and-telemetry/) 中使用服务访问控制，以使 `photo-frontend` 无法访问 `datastore`。

在这里，Citadel 为所有的命名空间提供了密钥和证书的管理功能，并在微服务之间进行了隔离。

## 认证

Istio 提供了两种认证方式：

* 传输认证，或者说服务间认证：校验发起连接的直接客户端。Istio 提供了双向 TLS（`mTLS`）作为传输认证的全栈解决方案。可以方便的在不变更服务代码的条件下启用这一功能，该方案：

    * 为每个服务提供强认证，认证身份和角色相结合，能够在不同的集群甚至不同云上进行互操作
    * 加密服务和服务之间、最终用户和服务之间的通信
    * 提供密钥管理系统，完成密钥和证书的生成、分发、轮转以及吊销操作

* 最终用户认证，也称为来源认证：发起请求的客户端是一个最终用户或者设备，对其身份进行校验。Istio 支持 JSON Web Token（JWT）形式的认证。

### 认证架构

在 Istio 服务网格中处理请求的服务，可以使用认证策略来为其指定认证需求。网格运维人员使用 `.yaml` 文件来配置这些策略。这些策略一经上传，会被保存到 Istio 的配置存储中。作为 Istio 的控制器，Pilot 会对配置存储进行监控。任何的策略变化，Pilot 都会把新的策略翻译为对应的配置格式，并告知 Sidecar 代理如何应用所需的认证机制。另外，Pilot 提供了 Istio 管理的密钥和证书的路径，并把他们安装到应用 Pod 中以便进行双向 TLS 连接。可以在 [PKI 和认证](/zh/docs/concepts/security/#认证)一节中找到更多相关信息。Istio 会将配置异步的发送给目标端点。Sidecar 收到配置之后，Pod 就会立即启用新的认证需求。

发送请求的客户端服务，要负责完成必要的认证机制。对于 JWT 认证来说，应用应该获取 JWT 凭据，并把凭据附加到请求上进行传播。Istio 提供了[目标规则](/zh/docs/concepts/traffic-management/#目标规则)用于应对双向 TLS 认证。运维人员可以使用目标规则来要求客户端 Sidecar 使用 TLS 证书向服务器发起连接。[PKI 和认证](/zh/docs/concepts/security/#认证)一节中介绍了更多双向 TLS  的相关内容。

{{< image width="80%" ratio="75%"
    link="/docs/concepts/security/authn.svg"
    caption="认证策略架构"
    >}}

这两种认证信息都会被 Istio 输出，如果有其他申明也会在凭据中一起输出到下一层：[鉴权](/zh/docs/concepts/security/#授权和鉴权)，另外运维人员还可以在双向 TLS 和最终用户两个甚至中选择一个提供给 Istio 用作认证主体（`principal`）。

### 认证策略

本节中提供了更多 Istio 认证策略方面的细节。正如[认证架构](#认证架构)中所说的，认证策略是对服务收到的请求生效的。要在双向 TLS 中指定客户端认证策略，需要在 `DetinationRule` 中设置 `TLSSettings`。[TLS 设置参考文档](/docs/reference/config/istio.networking.v1alpha3/#TLSSettings)中有更多这方面的信息。和其他的 Istio 配置一样，可以用 `.yaml` 文件的形式来编写认证策略，然后使用 `istioctl` 进行部署。

下面例子中的认证策略要求 `reviews` 服务必须使用双向 TLS：

{{< text yaml >}}
apiVersion: "authentication.istio.io/v1alpha1"
kind: "Policy"
metadata:
  name: "reviews"
spec:
  targets:
  - name: reviews
    peers:
  - mtls: {}
{{< /text >}}

#### 策略的存储范围

Istio 可以在命名空间范围或者服务网格范围内保存认证策略：

* 要制定网格范围的策略，要把 `kind` 字段设置为 `MeshPolicy`，`name` 字段设置为 `default`：

    {{< text yaml >}}
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "MeshPolicy"
    metadata:
      name: "default"
    spec:
      peers:
      - mtls: {}
    {{< /text >}}

* 命名空间范围的策略，`kind` 取值为 `Policy`，并且需要指定命名空间。如果没有指定，会使用缺省命名空间，例如下面的策略应用到 `ns1` 命名空间：

    {{< text yaml >}}
    apiVersion: "authentication.istio.io/v1alpha1"
    kind: "Policy"
    metadata:
      name: "default"
      namespace: "ns1"
    spec:
      peers:
      - mtls: {}
    {{< /text >}}

命名空间范围的策略的影响范围仅限于同一命名空间。网格范围的策略会作用在网格中所有服务上。为了杜绝冲突和误用，网格范围的策略智能定义一条，名字必须是 `default`，`targets` 必须为空。[目标选择器](#目标选择器) 一节讲述了 `targets` 的相关内容。

目前在 Kubernetes 中使用了 CRD 来实现 Istio 配置。这些 CRD 自然也是受到 Kubernetes RBAC 制约的。可以阅读 [Kubernetes 文档](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions) 来了解 Kubernetes 的 RBAC 机制。

#### 目标选择器

认证策略的目标指定了策略影响的服务范围。下面的例子展示的是 `targets` 如何指定如下的生效范围：

* `product-page` 服务的任何端口。
* `reviews` 服务的 `9000` 端口。

{{< text yaml >}}
targets:
 - name: product-page
 - name: reviews
   ports:
   - number: 9000
{{< /text >}}

如果没有 `targets` 一节，Istio 认为这一策略匹配生效范围内的所有服务。`targets` 一节能用于指定策略的生效范围：

* 网格范围的策略：网格范围内的策略无需目标选择器，网格之内最多只能有一条网格范围的策略。

* 命名空间范围的策略：在命名空间范围内存储的策略命名为 `default`，同样没有目标选择器，一个命名空间之内最多有一条命名空间范围的策略。

* 针对服务的策略：保存在命名空间之内，具有目标选择器。一个命名空间之内可以有任意多条服务级的策略。

Istio 为服务选择策略的时候，按照 **服务级 > 命名空间级 > 网格级** 的优先级来选择要应用的策略。如果多个服务级策略匹配到同一个服务，Istio 就会进行随机选择。运维人员在配置策略时候应该避免这种情况的发生。

为了确保网格和命名空间一级的策略的唯一性，Istio 每个网格/命名空间之内仅接受一条网格/命名空间级别的策略，并且要求这两种策略的名称为 `default`。

#### 传输认证

`peers` 一节为传输认证策略定义了认证方法及其相关参数。这一节中可以列出多个方法，其中的方法至少要有一个通过才能完成认证。然而在 0.7 版本中，唯一的传输认证方法就是双向 TLS。如果无需传输认证，跳过这节即可。

下面的代码段展示了使用 `peers` 启用基于双向 TLS 进行传输认证的方法：

{{< text yaml >}}
peers:
  - mtls: {}
{{< /text >}}

目前双向 TLS  的设置不需要任何参数，`-mtls: {}`、`- mtls` 或者 `- mtls: null` 都是等价的。未来 双向 TLS 设置可能会加入参数用来提供不同的双向 TLS 支持。

#### 最终用户认证

`origins` 一节定义了源认证的方法及其相关参数。Istio 只支持 JWT 认证。然而一条策略可以包含多个来源的不同 JWT。和前面的传输认证类似，只有其中一个方法通过之后才能完成认证过程。

下面的示例策略设置了一节 `origins` 内容，用于接收 Google 的 JWT 认证：

{{< text yaml >}}
origins:
- jwt:
    issuer: "https://accounts.google.com"
    jwksUri: "https://www.googleapis.com/oauth2/v3/certs"
{{< /text >}}

#### 主认证绑定

主认证关系用键值对的方式存储绑定关系，其中定义了策略和主认证选择的关系。缺省情况下，Istio 使用 `peers` 中配置的认证方式。如果 `peers` 中没有定义认证，Istio 会保留未设置认证的状态。策略中可以使用 `USER_ORIGIN` 来修改这一行为，可以设置最终用户认证作为主认证。未来会支持条件绑定，例如：如果 peer 为 X  的情况下使用 `USE_PEER`；否则使用 `USE_ORIGIN`。

接下来的例子中 `principalBinding` 键赋值为 `USE_PRIGIN`：

{{< text yaml >}}
principalBinding: USE_ORIGIN
{{< /text >}}

### 更新认证策略

可以再任何时间对认证策略进行修改，Istio 会用近乎实时的的效率把变更推送给端点。然而 Istio 无法保证所有端点能够同时收到新策略。下面提供一些建议，以避免更新认证策略造成的服务中断。

* 双向 TLS 的启用和禁用：使用一个临时策略，其中的 `mode` 字段设置为 `PERISSIVE`。这个配置让服务同时接受 双向 TLS 和明文通信。这样就不会丢失请求。一旦所有客户端都完成协议转换之后，就可以将 `PERMISSIVE` 策略切换到期望值了。[双向 TLS 的迁移](/zh/docs/tasks/security/mtls-migration)任务中介绍了更多这一方式的细节。

{{< text yaml >}}
peers:
- mTLS:
    mode: PERMISSIVE
{{< /text >}}

* JWT 认证的迁移：在变更策略之前，首先要在请求中包含新的 JWT 内容。一旦服务端完全切换到新策略，如果存在旧有 JWT，就可以移除了。客户端应用需要根据需要进行变更。

## 授权和鉴权

Istio 的授权，也就是基于角色的访问控制（RBAC），为 Istio 网格中的服务提供命名空间级、服务级以及方法级访问控制。他的功能包括：

* 简单易用的基于角色的语义。
* 服务到服务以及用户端到服务的授权。
* 支持自定义属性的弹性实施，例如在角色和角色绑定中使用条件判断。
* Istio 鉴权在 Envoy 本地执行，具备较高性能。

### 授权架构

{{< image width="80%" ratio="56.25%"
    link="/docs/concepts/security/authz.svg"
    alt="Istio RBAC"
    caption="Istio RBAC 架构"
    >}}

上图表现了基本的 Istio RBAC 架构。运维人员使用 `.yaml` 文件定制 Istio 的 RBAC 策略。策略部署之后就会被保存到 `Istio 配置存储`之中。

Pilot 监控 Istio 授权策略的变化。授权更新之后 Pilot 就会重新抓取，然后把更新的策略分发给 Envoy sidecar。

每个 Envoy sidecar 都会运行一个运行时鉴权引擎。当一个请求到达时，健全引擎会根据当前策略对请求的上下文进行评估，最终返回 `ALLOW` 或者 `DENY` 的鉴权结果。

### 启用 RBAC

可以使用 `RbacConfig` 启用 RBAC，这个对象是一个网格范围内的单例对象，名称固定为 `default`。和其他 Istio 配置对象类似，`RbacConfig` 也是以 Kubernetes `CustomResourceDefinition`（[CRD](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)）的形式进行定义的。

`RbacConfig` 对象中，运维人员可以给 `mode` 字段赋值，可选范围包括：

* **`OFF`**: 停用 RBAC。
* **`ON`**: 为网格中的所有服务启用 RBAC。
* **`ON_WITH_INCLUSION`**: 只对 `inclusion` 字段中包含的命名空间和服务启用 RBAC。
* **`ON_WITH_EXCLUSION`**: 对网格内的所有服务启用 RBAC，除 `exclusion` 字段中包含的命名空间和服务之外。

下面的例子为 `default` 命名空间启用了 RBAC：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: RbacConfig
metadata:
  name: default
  namespace: istio-system
spec:
  mode: ON_WITH_INCLUSION
  inclusion:
    namespaces: ["default"]
{{< /text >}}

### 授权策略

要配置 Istio 授权策略，需要编写两个 `CRD` 对象，分别是 `ServiceRole` 和 `ServiceRoleBinding`：

* **`ServiceRole`** 定义了一组用于访问服务的权限。
* **`ServiceRoleBinding`** 把 `ServiceRole` 角色授予制定主体，例如用户、群组或者服务。

`ServiceRole` 和 `ServiceRoleBinding` 联合起来定义了：允许 **谁** 在 **什么条件下** 可以 **做什么**，展开来说：

* **谁**：对应的是 `ServiceRoleBinding` 对象中的 `subjects` 一节。
* **做什么**：也就是 `ServiceRole` 对象中的 `permissions` 字段。
* **什么条件下**：匹配条件，由 Istio [属性](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/)构成，在 `ServiceRole` 和 `ServiceRoleBinding` 中都可以使用。

#### `ServiceRole`

`ServiceRole` 中包含了一系列的 `rules`，也就是权限。每个 `rule` 都有几个标准字段：

* **`services`**： 服务名列表，如果使用 `*`，就代表包含特定命名空间里的所有服务。

* **`methods`**： HTTP 方法名列表，如果是 gRPC 请求的话，就只能是 `POST` 了。可以设置为 `*` 来包含所有 HTTP 方法。
* **`paths`**：HTTP 路径或者 gRPC 方法。gRPC 方法必须是 `/packageName.serviceName/methodName` 的格式，并且区分大小写。

`ServiceRole` 只对 `metadata` 中指定的命名空间有效。在 `rule` 中，`services` 和 `methods` 字段是必选字段，而 `paths` 是可选的。

下面的例子中是一个简单的角色：`service-admin`，这一角色能够用所有方法访问 `default` 命名空间内的所有服务

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: service-admin
  namespace: default
spec:
  rules:
  - services: ["*"]
    methods: ["*"]
{{< /text >}}

接下来是另外一个角色 `products-viewer`，能够对 `default` 命名空间内的  `products.default.svc.cluster.local` 服务执行 `GET`、`HEAD` 操作。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: products-viewer
  namespace: default
spec:
  rules:
  - services: ["products.default.svc.cluster.local"]
    methods: ["GET", "HEAD"]
{{< /text >}}

除此之外，Istio 的 `rule` 中的所有字段还支持前后缀的匹配。比如说可以定义一个 `tester` 角色，并在 `default` 命名空间中为其赋予以下权限：

* 对名称中带有 `test-*` 前缀的服务能够进行完全访问，例如 `test-bookstore`、`test-performance` 以及 `test-api.default.svc.cluster.local`。

* 对所有具备 `*/reviews` 后缀的 path，都能够进行读取（`GET`）访问，例如服务 `bookstore.default.svc.cluster.local` 中的 `/books/reviews`、 `/events/booksale/reviews` 或者 `/reviews`。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
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

在 `ServiceRole` 中，`namespace` + `services` + `paths` + `methods` 的组合定义了 **服务的访问方法**。有时可能需要为规则制定额外的条件。例如某条规则只适用于服务的某个版本，或者只适用于带有某个标签（例如 `foo`）的服务。使用 `constraints` 可以轻易地完成这些条件的设置。

例如下面的 `ServiceRole` 定义，在 `products-viewer` 的基础上加入了一个约束，要求 `request.headers["version"]` 的值是 `v1` 或者 `v2`。[约束和属性](/docs/reference/config/authorization/constraints-and-properties/) 中列出了约束可以选择 `key` 的范围。这个例子中的键是一个 map 类型（`request.headers["version"]`）。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: products-viewer-version
  namespace: default
spec:
  rules:
  - services: ["products.default.svc.cluster.local"]
    methods: ["GET", "HEAD"]
    constraints:
    - key: request.headers[version]
      values: ["v1", "v2"]
{{< /text >}}

#### `ServiceRoleBinding`

`ServiceRoleBinding` 由几个部分组成：

* **`roleRef`**：引用在统一命名空间内的 `ServiceRole` 资源。
* **`subjects`** 列表将会分配给这个角色。

为 `subejct` 赋值，可以显式的赋值为一个 `user`，也可以使用一组 `property`。`ServiceRoleBinding` 中，`subject` 的 `property` 可以类比为 `ServiceRole` 中的 `constraint`。`property` 也可以用来筛选一系列的账号用来进行授权。同样的，这里的 `key` 和 `value` 也有可选范围的问题，同样可以查阅[约束和属性](/docs/reference/config/authorization/constraints-and-properties/)页面。

下面的例子中有一个叫做 `test-binding-products` 的 `ServiceRoleBinding`，他会把两个主体绑定到名为 `product-viewer` 的 `ServiceRole` 上，两个主体分别是：

* 服务 `a` 的 Service account：`service-account-a`。
* Ingress 服务的 Service account `istio-ingress-service-account` **并且** JWT `email` 为 `a@foo.com`。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: test-binding-products
  namespace: default
spec:
  subjects:
  - user: "service-account-a"
  - user: "istio-ingress-service-account"
    properties:
    - request.auth.claims[email]: "a@foo.com"
    roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

如果想要一个服务能够被公开访问，可以把 `subject` 设置为 `user:*`。这样就会把 `ServiceRole` 授予给所有用户和服务，例如：

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: binding-products-allusers
  namespace: default
spec:
  subjects:
  - user: "*"
    roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}
