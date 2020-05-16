---
title: 基于 Istio 授权的 Micro-Segmentation
description: 描述 Istio 的授权功能以及如何在各种用例中使用它。
publishdate: 2018-07-20
subtitle:
attribution: Limin Wang
keywords: [authorization,rbac,security]
target_release: 0.8
---

Micro-Segmentation 是一种安全技术，可在云部署中创建安全区域，并允许各组织将工作负载彼此隔离以单独保护它们。
 [Istio 的授权功能](/zh/docs/concepts/security/#authorization)也称为 Istio 基于角色的访问控制，为 Istio 网格中的服务提供
  Micro-Segmentation。它的特点是：

* 不同粒度级别的授权，包括命名空间级别、服务级别和方法级别。
* 服务间和最终用户到服务授权。
* 高性能，因为它在 Envoy 上本地执行。
* 基于角色的语义，使其易于使用。
* 灵活性高，因为它允许用户使用[组合属性](/zh/docs/reference/config/security/constraints-and-properties)定义条件。

在这篇博客文章中，您将了解主要授权功能以及如何在不同情况下使用它们。

## 特点{#characteristics}

### RPC 级别授权{#RPC-level-authorization}

授权在各个 RPC 级别执行。具体来说，它控制“谁可以访问我的 `bookstore` 服务”，或者“谁可以在我的 `bookstore` 服务中访问
 `getBook` 方法 ”。它不是为了控制对于应用程序具体资源实例的访问而设计的，例如访问“存储桶 X ”或访问“第二层架上的第 3 本书”。目前这种应用特定的访问控制逻辑需要由应用程序本身处理。

### 具有条件的基于角色的访问控制{#role-based-access-control-with-conditions}

授权是[基于角色的访问控制（RBAC）](https://en.wikipedia.org/wiki/Role-based_access_control) 系统，
将此与[基于属性的访问控制（ABAC）](https://en.wikipedia.org/wiki/Attribute-based_access_control) 系统对比。
与 ABAC 相比，RBAC 具有以下优势：

* **角色允许对属性进行分组。** 角色是权限组，用于指定允许的操作在系统上执行。用户根据组织内的角色进行分组。
您可以针对不同的情况定义角色并重用他们。

* **关于谁有权访问，更容易理解和推理。** RBAC 概念自然地映射到业务概念。例如，数据库管理员可能拥有对数据库后端服务的所有访问权限，
而 Web 客户端可能只能查看数据库后端服务前端服务。

* **它减少了无意的错误。** RBAC 策略使得复杂的安全更改变得更加容易。你不会有在多个位置重复配置，以后在需要进行更改时忘记更新其中一些配置。

另一方面，Istio 的授权系统不是传统的 RBAC 系统。它还允许用户使用定义**条件**[属性组合](/zh/docs/reference/config/security/constraints-and-properties)。这给了 Istio 表达复杂的访问控制策略的灵活性。实际上，**Istio 授权采用“RBAC + 条件”模型，具有 RBAC 系统的所有优点，并支持通常是 ABAC 系统提供的灵活性。**你会在下面看到一些[示例](#examples)。

### 高性能{#high-performance}

由于其简单的语义，Istio 授权直接在 Envoy 本地执行。在运行时，授权决策完全在 Envoy 过滤器内部完成，不依赖于任何外部模块。
这允许 Istio 授权实现高性能和可用性。

### 使用/不使用主要标识{#work-with-without-primary-identities}

与任何其他 RBAC 系统一样，Istio 授权具有身份识别功能。在 Istio 授权政策中，有一个主要的
身份称为 `user`，代表客户的主体。

除主要标识外，您还可以自己定义标识。例如，您可以将客户端标识指定为“用户 `Alice` 从 `Bookstore` 前端服务调用”，在这种情况下，
你有一个调用服务（`Bookstore frontend`）和最终用户（`Alice`）的组合身份。

要提高安全性，您应该启用[认证功能](/zh/docs/concepts/security/#authentication), 并在授权策略中使用经过验证的身份。但是，
使用授权不强迫一定要有身份验证。Istio 授权可以使用或不使用身份。如果您正在使用遗留系统，您可能没有网格的双向 TLS 或 JWT 身份验证
设置。在这种情况下，识别客户端的唯一方法是，例如，通过 IP。您仍然可以使用 Istio 授权来控制允许哪些 IP 地址或 IP 范围访问您的服务。

## 示例{#examples}

[授权任务](/zh/docs/tasks/security/authorization/authz-http)通过 [Bookinfo 应用](/zh/docs/examples/bookinfo)向您展示如何使用 Istio 的授权功能来控制命名空间级别
和服务级别的访问。在本节中，您将看到更多使用 Istio 授权进行权限细分的示例。

### 通过 RBAC + 条件进行命名空间级别细分{#namespace-level-segmentation-via-rbac-conditions}

假设你在 `frontend` 和 `backend` 命名空间中有服务。您想要允许所有在 `frontend` 命名空间中的服务访问 `backend` 命名空间中标记
为 `external` 的所有服务。

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

上面的 `ServiceRole` 和 `ServiceRoleBinding` 表示“允许*谁* 在 *什么条件* （RBAC + 条件）下执行*什么* ”。其中：

* **“谁”** 是 `frontend` 命名空间中的服务。
* **“什么”** 是在 `backend` 命名空间中调用服务。
* **“条件”** 是具有值 `external` 的目标服务的 `visibility` 标签。

### 具有/不具有主要身份的服务/方法级别隔离{#service-method-level-isolation-with-without-primary-identities}

这是演示另一个服务/方法级别的细粒度访问控制的示例。第一步是定义一个 `book-reader` `ServiceRole`，它允许对 `bookstore` 服务中的 `/books/*` 资源进行 READ 访问。

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

#### 使用经过身份验证的客户端身份{#using-authenticated-client-identities}

假设你想把这个 `book-reader` 角色授予你的 `bookstore-frontend` 服务。如果您已启用
您的网格的[双向 TLS 身份验证](/zh/docs/concepts/security/#mutual-TLS-authentication), 您可以使用服务帐户，以识别您的 `bookstore-frontend` 服务。授予 `book-reader` 角色到 `bookstore-frontend` 服务可以通过创建一个 `ServiceRoleBinding` 来完成，如下所示：

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

您可能希望通过添加“仅属于 `qualified-reviewer` 组的用户的条件来进一步限制此操作允许阅读书籍“。`qualified-reviewer` 组是经过身份验证的最终用户身份 [JWT 身份验证](/zh/docs/concepts/security/#authorization)。在这种情况下，客户端服务标识（`bookstore-frontend`）和最终用户身份（`qualified-reviewer`）的组合将用于授权策略。

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

#### 无身份客户{#client-does-not-have-identity}

强烈建议在授权策略中使用经过身份验证的身份以确保安全性。但是，如果你有一个如果遗留系统不支持身份验证，您可能没有经过身份验证的身份验证。即使没有经过身份验证的身份，您仍然可以使用 Istio 授权来保护您的服务。以下示例表明您可以在授权策略中指定允许的源 IP 范围。

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

## 概要{#summary}

Istio 在命名空间级别，服务级别和方法级别粒度上提供授权功能。它采用“ RBAC + 条件”模型，使其成为易于使用和理解的 RBAC 系统，同时提供 ABAC 系统级别的灵活性。由于 Istio 授权在 Envoy 上本地运行，它有很高的性能。Istio 授权既可以与 [Istio 认证功能](/zh/docs/concepts/security/#authentication)一起提供最佳的安全性，也可以用于为没有身份验证的旧系统提供访问控制。
