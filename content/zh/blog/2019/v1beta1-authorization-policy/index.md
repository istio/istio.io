---
title: Istio v1beta1 授权策略概述
description: Istio v1beta1 授权策略的设计原则、基本概述及迁移操作。
publishdate: 2019-11-14
subtitle:
attribution: Yangmin Zhu (Google)
keywords: [security, RBAC, access control, authorization]
target_release: 1.4
---

Istio 1.4 引入了 [`v1beta1` 授权策略](/zh/docs/reference/config/security/authorization-policy/)，这是对
以前 `v1alpha1` 的基于角色的访问控制（RBAC）策略的重要更新。包括以下改进：

* 符合 Istio 配置模型。
* 通过简化 API 改善用户体验。
* 支持更多用例（例如，Ingress/Egress 网关支持），而不会增加复杂性。

该 `v1beta1` 策略不向后兼容，需要一次转换。Istio 提供了一个工具来自动执行此过程。
Istio 1.6 以后将不再支持先前的配置资源 `ClusterRbacConfig`、`ServiceRole` 和 `ServiceRoleBinding`。

本文描述了新的 `v1beta1` 授权策略模型、设计目标和从 `v1alpha1` RBAC 策略的迁移。
有关 `v1beta1` 授权策略的详细说明，请参见 [authorization concept](/zh/docs/concepts/security/#authorization) 页面。

我们欢迎您在 [discuss.istio.io](https://discuss.istio.io/c/security) 上反馈有关 `v1beta1` 授权策略的相关信息。

## 背景{#background}

迄今为止，Istio 提供了 RBAC 策略，以便使用 `ClusterRbacConfig`、`ServiceRole` 和 `ServiceRoleBinding` 配置资源
对 {{< gloss "service" >}}服务{{< /gloss >}} 实施访问控制。使用此 API，用户可以在网格级别、命名空间级别和服务级别强
制实施访问控制。与其他 RBAC 策略一样，Istio RBAC 使用相同的角色和绑定概念来授予身份权限。

尽管 Istio RBAC 一直稳定可靠的工作着，但我们还是发现了许多改进空间。

例如，用户错误地假定访问控制实施发生在服务级别，因为 `ServiceRole` 使用服务指定在何处应用策略，但是，策略实际上应用于
{{< gloss "workload" >}}工作负载{{< /gloss >}}，该服务仅用于查找相应的工作负载。当多个服务引用相同的工作负载时，
这种细微差别非常重要。如果两个服务引用相同的工作负载，则服务 A 的 `ServiceRole` 也会影响服务 B，这可能会导致混淆和不
正确的配置。

另一个示例是，由于需要深入了解三个相关资源，用户很难维护和管理 Istio RBAC 配置。

## 设计目标{#design-goals}

新的 `v1beta1` 授权策略具有几个设计目标：

* 与 [Istio 配置模型](https://goo.gl/x3STjD)保持一致，以便更清楚地了解策略目标。
  配置模型提供统一的配置层次结构、解决方案和目标选择。

* 通过简化 API 改善用户体验。管理一个包含所有访问控制规范的 CRD（自定义资源定义）比管理多个 CRD 更容易。

* 支持更多用例，而不会增加复杂性。例如，允许在 Ingress/Egress 网关上应用策略，以对进出网格的流量实施访问控制。

## `AuthorizationPolicy`{#authorization-policy}

通过 [`AuthorizationPolicy` 自定义资源](/zh/docs/reference/config/security/authorization-policy/)启用对工作
负载的访问控制。本节介绍 `v1beta1` 授权策略中的变化。

`AuthorizationPolicy` 包括 `selector` 和一个 `rule` 列表。`selector` 指定应用策略的工作负载，`rule` 列表指定工作
负载的详细访问控制规则。

`rule` 是累加的，这意味着如果任何 `rule` 允许请求，则请求将被允许。每个 `rule` 都包含 `from`、`to` 和 `when` 的定义，
其指定了允许**谁**在哪些**条件**下执行哪些**操作**。

`selector` 将替换 `ClusterRbacConfig` 和 `ServiceRole` 中的 `services` 字段提供的功能。
`rule` 将替换 `ServiceRoleBinding` 和 `ServiceRole` 中的其他字段。

### 示例{#example}

以下授权策略适用于 `foo` 命名空间中含有 `app: httpbin` 和 `version: v1` 标签的工作负载：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: httpbin
 namespace: foo
spec:
 selector:
   matchLabels:
     app: httpbin
     version: v1
 rules:
 - from:
   - source:
       principals: ["cluster.local/ns/default/sa/sleep"]
   to:
   - operation:
       methods: ["GET"]
   when:
   - key: request.headers[version]
     values: ["v1", "v2"]
{{< /text >}}

当来自 `cluster.local/ns/default/sa/sleep` 的请求头中包含值为 `v1` 或 `v2` 的 `version` 字段时，
该策略将允许其通过 `GET` 请求访问工作负载。默认情况下，任何与策略不匹配的请求都将被拒绝。

假设 `httpbin` 服务定义为：

{{< text yaml >}}
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  namespace: foo
spec:
  selector:
    app: httpbin
    version: v1
  ports:
    # omitted
{{< /text >}}

如果要在 `v1alpha1` 中实现相同的目的，您需要配置三个资源：

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ClusterRbacConfig
metadata:
  name: default
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    services: ["httpbin.foo.svc.cluster.local"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: httpbin
  namespace: foo
spec:
  rules:
  - services: ["httpbin.foo.svc.cluster.local"]
    methods: ["GET"]
    constraints:
    - key: request.headers[version]
      values: ["v1", "v2"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: httpbin
  namespace: foo
spec:
  subjects:
  - user: "cluster.local/ns/default/sa/sleep"
  roleRef:
    kind: ServiceRole
    name: "httpbin"
{{< /text >}}

### 工作负载选择器{#workload-selector}

`v1beta1` 授权策略中的一个主要更改是，它现在使用工作负载选择器指定应该在何处应用策略。
这与 `Gateway`、`Sidecar` 和 `EnvoyFilter` 配置中使用的工作负载选择器相同。

工作负载选择器显式的表明，策略是在工作负载（而不是服务）上应用和强制执行的。
如果策略适用于由多个不同服务使用的工作负载，则同一策略将影响所有不同服务的流量。

只需将 `selector` 留空，即可将策略应用于命名空间中的所有工作负载。以下策略适用于命名空间 `bar` 中的所有工作负载：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: policy
 namespace: bar
spec:
 rules:
 # omitted
{{< /text >}}

### 根命名空间{#root-namespace}

根命名空间中的策略应用于网格中每个命名空间中的所有工作负载。
根命名空间可在 [`MeshConfig`](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig) 中配置，
其默认值为 `istio-system`。

例如，您在 `istio-system` 命名空间中安装了 Istio，并在 `default` 和 `bookinfo` 命名空间中部署了工作负载。
把根命名空间从默认值更改为 `istio-config` 后，以下策略将应用于每个命名空间中的工作负载，
包括 `default`、`bookinfo` 和 `istio-system`：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: policy
 namespace: istio-config
spec:
 rules:
 # omitted
{{< /text >}}

### Ingress/Egress 网关支持{#ingress-egress-gateway-support}

`v1beta1` 授权策略也可以应用于 ingress/egress 网关，以对进入或离开网格的流量实施访问控制，
您只需更改 `selector` 即可选择入口或出口工作负载。

以下策略适用于具有 `app: istio-ingressgateway` 标签的工作负载：

{{< text yaml >}}
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
 name: ingress
 namespace: istio-system
spec:
 selector:
   matchLabels:
     app: istio-ingressgateway
 rules:
 # omitted
{{< /text >}}

请注意，授权策略仅适用于与策略相同的命名空间中的工作负载，除非在根命名空间中应用该策略：

* 如果不更改根命名空间的默认值（即 `istio-system`），上述策略将应用于**每个**命名空间中
  含有 `app: istio-ingressgateway` 标签的工作负载。

* 如果将根命名空间更改为其他值，则上述策略将**仅适用**于 `istio-system` 命名空间中
  含有 `app: istio-ingressgateway` 标签的工作负载。

### 比较{#comparison}

下表突出显示了旧的 `v1alpha1` RBAC 策略和新的 `v1beta1` 授权策略之间的主要区别。

#### 特性{#feature}

| 特性 | `v1alpha1` RBAC 策略 | `v1beta1` 授权策略 |
|---------|------------------------|--------------------------------|
| API 稳定性 | `alpha`：**不** 向后兼容 | `beta`：**确保**向后兼容 |
| CRD 数量 | 三个：`ClusterRbacConfig`、`ServiceRole` 和 `ServiceRoleBinding` | 一个：`AuthorizationPolicy` |
| 策略目标 | **service** | **workload** |
| 默认拒绝行为 | 通过**显式**的配置 `ClusterRbacConfig` 启用 | **隐式**的通过 `AuthorizationPolicy` 启用 |
| Ingress/Egress 网关支持 | 不支持 | 支持 |
| 策略中的 `"*"` 值 | 匹配所有内容（空和非空） | 仅匹配非空内容 |

下表显示了 `v1alpha1` 和 `v1beta1` API 之间的关系。

#### `ClusterRbacConfig`

| `ClusterRbacConfig.Mode` | `AuthorizationPolicy` |
|---------------------|-----------------------|
| `OFF` | 未应用策略 |
| `ON` | 在根命名空间中应用的全部拒绝策略 |
| `ON_WITH_INCLUSION` | 策略应用于 `ClusterRbacConfig` 中包含的命名空间或工作负载  |
| `ON_WITH_EXCLUSION` | 策略应用于 `ClusterRbacConfig` 中包含的命名空间或工作负载  |

#### `ServiceRole`

| `ServiceRole` | `AuthorizationPolicy` |
|---------------|-----------------------|
| `services` | `selector` |
| `paths` | `to` 字段下的 `paths` |
| `methods` | `to` 字段下的 `methods` |
| 在约束中的 `destination.ip` | 不支持 |
| 在约束中的 `destination.port` |  `to` 字段下的 `ports` |
| 在约束中的 `destination.labels` | `selector` |
| 在约束中的 `destination.namespace` | 替换为策略的命名空间，即元数据中的 `namespace` |
| 在约束中的 `destination.user` | 不支持 |
| 在约束中的 `experimental.envoy.filters` | `when` 字段下的 `experimental.envoy.filters` |
| 在约束中的 `request.headers` | `when` 字段下的 `request.headers` |

#### `ServiceRoleBinding`

| `ServiceRoleBinding` | `AuthorizationPolicy` |
|----------------------|-----------------------|
| `user`  | `from` 字段下的 `principals`  |
| `group` | `to` 字段下的 `paths` |
| `source.ip` 属性 | `from` 字段下的 `ipBlocks` |
| `source.namespace` 属性 | `from` 字段下的 `namespaces` |
| `source.principal` 属性 | `from` 字段下的 `principals`  |
| `request.headers` 属性 | `when` 字段下的 `request.headers` |
| `request.auth.principal` 属性 | `from` 字段下的 `requestPrincipals` 或 `when` 字段下的 `request.auth.principal` |
| `request.auth.audiences` 属性 | `when` 字段下的 `request.auth.audiences` |
| `request.auth.presenter` 属性 | `when` 字段下的 `request.auth.presenter` |
| `request.auth.claims` 属性 | `when` 字段下的 `request.auth.claims` |

除了所有差异之外，与 `v1alpha1` 类似，`v1beta1` 策略也由 Envoy 引擎强制执行，并支持同样的身份验证（双向 TLS 或 JWT）、条件和其他基元（如 IP、端口等）。

## 未来的 `v1alpha1` 策略{#future-of-the-v1alpha1-policy}

`v1alpha1` RBAC 策略（`ClusterRbacConfig`、`ServiceRole` 和 `ServiceRoleBinding`）将被 `v1beta1` 授权策略替代并弃用。

Istio 1.4 继续支持 `v1alpha1` RBAC 策略，以便使您有足够的时间完成迁移。

## 从 `v1alpha1` 策略迁移{#migration-from-the-v1alpha1-policy}

对于给定的工作负载，Istio 仅支持两个版本之一：

* 如果仅为工作负载配置 `v1beta1` 策略，则 `v1beta1` 策略生效。
* 如果仅为工作负载配置 `v1alpha1` 策略，则 `v1alpha1` 策略生效。
* 如果同时为工作负载配置 `v1beta1` 和 `v1alpha1` 策略，则仅 `v1beta1` 策略生效，`v1alpha1` 策略将被忽略。

### 一般准则{#general-guideline}

{{< warning >}}
迁移时，对给定工作负载使用 `v1beta1` 策略时，请确保新的 `v1beta1` 策略涵盖应用于工作负载的所有现有 `v1alpha1` 策略，
因为在应用 `v1beta1` 后，将忽略应用于工作负载的 `v1alpha1` 策略。
{{< /warning >}}

迁移到 `v1beta1` 策略的典型流程是首先检查 `ClusterRbacConfig`，以确定哪些命名空间或服务启用了 RBAC。

对于启用了 RBAC 的每个服务：

1. 从服务定义中获取工作负载选择器。
1. 使用工作负载选择器创建一个 `v1beta1` 策略。
1. 根据应用与服务的每个 `ServiceRole` 和 `ServiceRoleBinding` 更新 `v1beta1` 策略。
1. 应用该 `v1beta1` 策略并监视流量，以确保该策略按预期工作。
1. 对启用了 RBAC 的下一个服务重复该过程。

对于启用了 RBAC 的每个命名空间：

1. 把拒绝所有流量的 `v1beta1` 策略应用到给定的命名空间。

### 迁移示例{#migration-example}

假设在 `foo` 命名空间中您有以下 `v1alpha1` 策略用于 `httpbin` 服务：

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ClusterRbacConfig
metadata:
  name: default
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["foo"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: httpbin
  namespace: foo
spec:
  rules:
  - services: ["httpbin.foo.svc.cluster.local"]
    methods: ["GET"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: httpbin
  namespace: foo
spec:
  subjects:
  - user: "cluster.local/ns/default/sa/sleep"
  roleRef:
    kind: ServiceRole
    name: "httpbin"
{{< /text >}}

以下述方式将上面的策略迁移到 `v1beta1`：

1. 假设 `httpbin` 服务具有以下工作负载选择器：

    {{< text yaml >}}
    selector:
      app: httpbin
      version: v1
    {{< /text >}}

1. 通过工作负载创建 `v1beta1` 策略：

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
     name: httpbin
     namespace: foo
    spec:
     selector:
       matchLabels:
         app: httpbin
         version: v1
    {{< /text >}}

1. 根据服务所应用的 `ServiceRole` 和 `ServiceRoleBinding` 更新 `v1beta1` 策略：

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
     name: httpbin
     namespace: foo
    spec:
     selector:
       matchLabels:
         app: httpbin
         version: v1
     rules:
     - from:
       - source:
           principals: ["cluster.local/ns/default/sa/sleep"]
       to:
       - operation:
           methods: ["GET"]
    {{< /text >}}

1. 应用 `v1beta1` 策略并监视流量，以确保该策略按预期工作。

1. 应用下面的 `v1beta1` 策略，该策略拒绝所有到达 `foo` 命名空间的流量，因为命名空间 `foo` 启用了 RBAC：

    {{< text yaml >}}
    apiVersion: security.istio.io/v1beta1
    kind: AuthorizationPolicy
    metadata:
     name: deny-all
     namespace: foo
    spec:
     {}
    {{< /text >}}

确保 `v1beta1` 策略按预期工作，然后可以从集群中删除 `v1alpha1` 策略。

### 自动化迁移{#automation-of-the-migration}

为了帮助简化迁移，可通 `istioctl experimental authz convert` 转换命令自动将 `v1alpha1` 策略
转换为 `v1beta1` 策略。

迁移时您可以考虑该命令，但它在 Istio 1.4 中是实验性的，并且截至此博客文章发布，其还不能够完整支持 v1alpha1 的全部语义。

支持完整 v1alpha1 语义的命令预计在 Istio 1.4 之后的修补程序版本中发布。
