---
title: 基于 Istio 授权的微分段
description: 描述 Istio 的授权功能以及如何在各种用例中使用它。
publishdate: 2018-07-20
subtitle:
attribution: Limin Wang
weight: 87
keywords: [authorization,Role Based Access Control,security]
---

微分段是一种安全技术，可在云部署中创建安全区域，并允许组织使用
将工作负载彼此隔离并单独保护它们。
[Istio 的授权功能](/docs/concepts/security/#authorization),也称为 Istio Role Based Access Control，
为 Istio 网格中的服务提供微分段。它的特点是：

* 不同粒度级别的授权，包括命名空间级别，服务级别和方法级别。
* 服务到服务和最终用户到服务授权。
* 高性能，因为它在 Envoy 上本地执行。
* 基于角色的语义，使其易于使用。
* 灵活性高，因为它允许用户使用定义条件
[属性组合](/docs/reference/config/authorization/constraints-and-properties/).

在这篇博客文章中，您将了解主要授权功能以及如何在不同情况下使用它们。

## 特点

### RPC 级别授权

授权在各个 RPC 级别执行。具体来说，它控制“谁可以访问我的`书店`服务”，
或者“谁可以在我的 `bookstore` 服务中访问方法 `getBook` ”。它不是为了控制对特定于应用程序的访问而设计的
资源实例，例如访问“存储桶 X ”或访问“第二层架上的第 3 本书”。今天这种应用
特定的访问控制逻辑需要由应用程序本身处理。

### 具有条件的基于角色的访问控制

授权是[基于角色的访问控制（RBAC）]（https://en.wikipedia.org/wiki/Role-based_access_control）系统，
将此与[基于属性的访问控制（ABAC）]对比（https://en.wikipedia.org/wiki/Attribute-based_access_control）
系统。与 ABAC 相比，RBAC 具有以下优势：

* **角色允许对属性进行分组。** 角色是权限组，用于指定允许的操作
在系统上执行。用户根据组织内的角色进行分组。您可以定义角色并重用
他们针对不同的情况。

* **关于谁有权访问更容易理解和推理。** RBAC 概念自然地映射到业务概念。
例如，数据库管理员可能拥有对数据库后端服务的所有访问权限，而 Web 客户端可能只能查看数据库后端服务
前端服务。

* **它减少了无意的错误。** RBAC 策略使得复杂的安全更改变得更加容易。你不会有
在多个位置重复配置，以后在需要进行更改时忘记更新其中一些配置。

另一方面，Istio 的授权系统不是传统的 RBAC 系统。它还允许用户使用定义**条件**
[属性组合](/docs/reference/config/authorization/constraints-and-properties/)。这给了 Istio
灵活地表达复杂的访问控制策略。实际上，**“RBAC +条件”模型
Istio 授权采用，具有 RBAC 系统的所有优点，并支持灵活性
通常是 ABAC 系统提供的。**你会在下面看到一些[示例]（#示例）。

### 高性能

由于其简单的语义，Istio 授权在 Envoy 上作为本机授权支持强制执行。在运行时，
授权决策完全在 Envoy 过滤器内部完成，不依赖于任何外部模块。
这允许 Istio 授权实现高性能和可用性。

### 使用/不使用主要身份

与任何其他 RBAC 系统一样，Istio 授权具有身份识别功能。在 Istio 授权政策中，有一个主要的
身份称为 `user`，代表客户的主体。

除主要标识外，您还可以指定定义标识的任何条件。例如，
您可以将客户端标识指定为“用户 Alice 从 Bookstore 前端服务调用”，在这种情况下，
你有一个调用服务（`Bookstore frontend`）和最终用户（`Alice`）的组合身份。

要提高安全性，您应该启用[身份验证功能](/docs/concepts/security/#authentication),
并在授权策略中使用经过身份验证的身份。但是，不需要强认证身份
使用授权。 Istio 授权可以使用或不使用身份。如果您正在使用遗留系统，
您可能没有网格的相互 TLS 或 JWT 身份验证设置。在这种情况下，识别客户端的唯一方法是，例如，
通过 IP。您仍然可以使用 Istio 授权来控制允许哪些 IP 地址或 IP 范围访问您的服务。

## 示例

[授权任务](/docs/tasks/security/role-based-access-control/)向您展示如何操作
使用 Istio 的授权功能来控制命名空间级别和服务级别访问
[Bookinfo 应用](/docs/examples/bookinfo/)。在本节中，您将看到有关如何实现的更多示例
使用 Istio 授权进行微分割。

### 通过 RBAC + 条件进行命名空间级别分段

假设你在 `frontend` 和 `backend` 命名空间中有服务。您想要允许所有服务
在 `frontend` 命名空间中访问 `backend` 命名空间中标记为 `external` 的所有服务。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: external-api-caller
  namespace: backend
spec:
  rules:
  - services: ["*"]
    methods: ["*”]
    constraints:
    - key: "destination.labels[visibility]”
      values: ["external"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: external-api-caller
  namespace: backend
spec:
  subjects:
  - properties:
      source.namespace: "frontend”
  roleRef:
    kind: ServiceRole
    name: "external-api-caller"
{{< /text >}}

上面的 `ServiceRole` 和 `ServiceRoleBinding` 表示“* * *允许在*条件*下执行* * *
（RBAC +条件）。特别：

* **"who”** 是 `frontend` 命名空间中的服务。
* **"what”** 是在 `backend` 命名空间中调用服务。
* **"conditions”** 是具有值 `external` 的目标服务的 `visibility` 标签。

### 具有/不具有主要身份的服务/方法级别隔离

这是另一个演示服务/方法级别的细粒度访问控制的示例。第一步是定义一个 `book-reader` `ServiceRole`，它允许对 `bookstore` 服务中的`/books/*`资源进行 READ 访问。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: book-reader
  namespace: default
spec:
  rules:
  - services: ["bookstore.default.svc.cluster.local"]
    paths: ["/books/*”]
    methods: ["GET”]
{{< /text >}}

#### 使用经过身份验证的客户端身份

假设你想把这个 `book-reader` 角色授予你的 `bookstore-frontend` 服务。如果您已启用
您的网格的[相互 TLS 身份验证](/docs/concepts/security/#mutual-tls-authentication),您可以使用
服务帐户，以识别您的 `bookstore-frontend` 服务。授予 `book-reader` 角色到 `bookstore-frontend`
服务可以通过创建一个 `ServiceRoleBinding` 来完成，如下所示：

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: book-reader
  namespace: default
spec:
  subjects:
  - user: "cluster.local/ns/default/sa/bookstore-frontend”
  roleRef:
    kind: ServiceRole
    name: "book-reader"
{{< /text >}}

您可能希望通过添加“仅属于 `qualified-reviewer` 组的用户”的条件来进一步限制此操作
允许阅读书籍“。 `qualified-reviewer` 组是经过身份验证的最终用户身份
[JWT 身份验证](/docs/concepts/security/#authentication）。在这种情况下，客户端服务标识的组合
（`bookstore-frontend`）和最终用户身份（`qualified-reviewer`）在授权策略中使用。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: book-reader
  namespace: default
spec:
  subjects:
  - user: "cluster.local/ns/default/sa/bookstore-frontend”
    properties:
      request.auth.claims[group]: "qualified-reviewer”
  roleRef:
    kind: ServiceRole
    name: "book-reader"
{{< /text >}}

#### 客户没有身份

强烈建议在授权策略中使用经过身份验证的身份以确保安全性。但是，如果你有一个
如果遗留系统不支持身份验证，您可能没有经过身份验证的身份验证。
即使没有经过身份验证的身份，您仍然可以使用 Istio 授权来保护您的服务。以下示例
表明您可以在授权策略中指定允许的源 IP 范围。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: book-reader
  namespace: default
spec:
  subjects:
  - properties:
      source.ip: 10.20.0.0/9
  roleRef:
    kind: ServiceRole
    name: "book-reader"
{{< /text >}}

## 概要

Istio 的授权功能在命名空间级别，服务级别和方法级别粒度上提供授权。
它采用“ RBAC +条件”模型，使其易于使用和理解为 RBAC 系统，同时提供级别
ABAC 系统通常提供的灵活性。 Istio 授权在强制执行时实现了高性能
本地特使。虽然它通过与...一起提供最好的安全性 [Istio 认证功能](/docs/concepts/security/#认证),也可以使用 Istio 授权
为没有身份验证的旧系统提供访问控制。
