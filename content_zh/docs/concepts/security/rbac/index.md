---
title: 基于角色的访问控制
description: Istio 基于角色的访问控制（RBAC）为 Istio 网格中的服务提供命名空间级、服务级、方法级访问控制。
keywords: [security,rbac]
weight: 10
---

## 综述

Istio 基于角色的访问控制（RBAC）为 Istio 网格中的服务提供命名空间级、服务级、方法级访问控制。它的特点:

* 基于角色的语义，简单易用。
* 服务到服务以及用户端到服务的授权。
* 在角色和角色绑定中可以通过自定义属性保证灵活性。

## 架构

下面的图表显示了 Istio RBAC 体系结构。操作者可以指定 Istio RBAC 策略。策略则保存在 Istio 配置存储中。

{{< image width="80%" ratio="56.25%"
    link="/docs/concepts/security/IstioRBAC.svg"
    alt="Istio RBAC"
    caption="Istio 的 RBAC 架构"
    >}}

Istio 的 RBAC 引擎做了下面两件事：

* **获取 RBAC 策略.** Istio RBAC 引擎关注 RBAC 策略的变化。如果它看到任何更改，将会获取更新后的 RBAC 策略。
* **授权请求.** 在运行时，当一个请求到来时，请求上下文会被传递给 Istio RBAC 引擎。RBAC 引擎根据传递的内容对环境进行评估，并返回授权结果（允许或拒绝）。

### 请求上下文

在当前版本中，Istio RBAC 引擎被实现为一个 [Mixer 适配器](/docs/concepts/policies-and-telemetry/#adapter)。请求上下文则作为[授权模板](https://github.com/istio/istio/blob/master/mixer/template/authorization/template.proto)的实例。请求上下文包含请求和授权模块需要环境的所有信息。特别是两个部分：

* 主题 包含调用者标识的属性列表，包括`"user"` name/ID，主题属于`“group”`，或者关于主题的任意附加属性，比如命名空间、服务名称。

* 动作 指定“如何访问服务”。它包括`“命名空间”`、`“服务”`、`“路径”`、`“方法”`，以及该操作的任何附加属性。

下面我们展示一个例子“请求内容”。

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

## Istio RBAC 策略

Istio RBAC 介绍 `ServiceRole` 和 `ServiceRoleBinding`，两者都被定义为 Kubernetes 自定义资源（CRD）对象。

* `ServiceRole` 定义了在网格中访问服务的角色。
* `ServiceRoleBinding` 绑定主题（例如，用户、组、服务）的角色。

### `ServiceRole`

一个 `ServiceRole` 规范包括一个规则列表。每个规则都有以下标准字段：

* **服务**：服务名称列表，与 `action.service` 匹配 “requestcontext” 的服务字段。
* **方法**：方法名列表。与 `action.method` 相匹配的 “requestcontext” 的方法字段。在上面的 “requestcontext” 中，是 HTTP 或 gRPC 方法。请注意，gRPC 方法是以 “packageName.serviceName/methodName” (区分大小写)的形式进行格式化的。
* **路径**：与 `action.path` 相匹配的 HTTP 路径列表。“requestcontext” 的路径字段。它在 gRPC 的案例中被忽略了。

一个 `ServiceRole` 规范只适用于**命名空间**指定在 `"metadata"` 选项。“服务”和“方法”在规则中是必需的字段。“路径”是可选项。如果没有指定为“*”，会被用于任意实体。

这里有一个简单的角色“服务管理员”的例子，它可以在“默认”命名空间中完全访问所有服务。

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

这里是另一个角色 “products-viewer”，它已经读取（“GET”和“HEAD”）授权访问服务 “products.default.svc.cluster.local” 在 “default” 命名空间中。

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

此外，我们支持规则中所有字段的**前缀匹配**和**后缀匹配**。例如，您可以定义一个“测试人员”角色，该角色在 “default” 命名空间中具有下列权限：

* 对所有带有前缀 “test-”的服务的完全访问，例如（“test-书店”，“test-performance”，“test-api.default.svc.cluster.local”）
* 读取（“GET”）对所有路径的访问，使用 “/reviews” 后缀，在 “bookstore.default.svc.cluster.local” 的服务中，例如（"/books/reviews", "/events/booksale/reviews", "/reviews"）。

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

在 `ServiceRole` “命名空间”+“服务”+“路径”+“方法”的组合定义了“如何允许访问服务（服务们）”。在某些情况下，您可能需要指定规则所应用的附加约束。例如，一条规则可能只适用于某一服务的某个“版本”，或者只适用于标记为“foo”的服务。您可以使用定制字段轻松地指定这些约束。

例如，下面的 `ServiceRole` 定义扩展了先前的 “products-viewer” 角色，在服务“版本”中添加了一个约束，即 “v1” 或 “v2”。注意，“版本”属性是由 “action.属性”提供的在 “requestcontext”。

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

### `ServiceRoleBinding`

一个 `ServiceRoleBinding` 规范包括两个部分:

* **roleRef** 指**同一命名空间**中的 `ServiceRole` 资源。
* 被分配角色的**主题**列表.

一个主题可以是“用户”，也可以是“组”，也可以用一组“属性”表示。每一个条目（“用户”或“组”或“属性”中的条目）必须在 “requestcontext” 实例的 “subject” 部分中匹配一个字段（“用户”或“组”或“属性”中的条目）。

这里有一个 `ServiceRoleBinding` 资源 “test-binding-products” 的例子，它将两个主题绑定到 ServiceRole “product-viewer”：

* user "alice@yahoo.com".
* "reviews.abc.svc.cluster.local" service in "abc" namespace.

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: ServiceRoleBinding
metadata:
  name: test-binding-products
  namespace: default
spec:
  subjects:
  - user: "alice@yahoo.com"
  - properties:
      service: "reviews.abc.svc.cluster.local"
      namespace: "abc"
  roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

在您想要使服务公开访问的情况下，您可以使用设置主题为`“user：“*”`。这将为所有用户/服务分配一个 `ServiceRole`。

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
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

## 开启 Istio RBAC

可以通过添加以下 Mixer 适配器规则来启用 Istio RBAC。这条规则有两个部分。第一部分定义了 RBAC 处理程序。它有两个参数，`“config_store_url”`和`“cache_duration”`。

* `"config_store_url"` 参数指定 RBAC 引擎在何处获取 RBAC 策略。`"config_store_url"` 默认是 `“k8s://”`，这意味着 Kubernetes 的 API 服务器。或者，如果您在本地测试 RBAC 策略，您可以将它设置为一个本地目录，例如`"fs:///tmp/testdata/configroot"`。
* `"cache_duration"` 参数指定在混合器客户端上缓存授权结果的持续时间（例如，Istio  代理)。默认值 `“cache_duration”` 是1分钟。

第二部分定义了一条规则，该规则指定 RBAC 处理程序应该用[之前的文档](#请求上下文)定义的 “requestcontext” 实例来调用。

在下面的例子中，Istio RBAC 启用了 “default” 命名空间。缓存的持续时间设置为30秒。

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: rbac
metadata:
  name: handler
  namespace: istio-system
spec:
  config_store_url: "k8s://"
  cache_duration: "30s"
---
apiVersion: "config.istio.io/v1alpha2"
kind: rule
metadata:
  name: rbaccheck
  namespace: istio-system
spec:
  match: destination.namespace == "default"
  actions:
  # handler and instance names default to the rule's namespace.
  - handler: handler.rbac
    instances:
    - requestcontext.authorization
{{< /text >}}

