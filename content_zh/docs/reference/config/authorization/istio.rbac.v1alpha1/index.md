---
title: RBAC
description: 配置基于角色的访问控制。
weight: 20
---

Istio RBAC（Role Based Access Control）定义了 `ServiceRole` 和 `ServiceRoleBinding` 对象。

`ServiceRole` 声明里包含一个规则列表（权限）。每个规则有如下的标准字段：

- services: services 列表。
- methods: HTTP methods。在 gRPC 场景下，由于值总是 `POST`，该字段会被忽略。
- paths: HTTP paths 或 gRPC methods。 注意 gRPC methods 的格式应为 `/packageName.serviceName/methodName`，并且是大小写敏感的。

除了标准字段，操作人员也可以在 `constraints` 字段中使用自定义 key，“约束和属性”页中列出了被支持的 key。

如下是一个名为 `product-viewer` 的 `ServiceRole` 对象，在服务 `products.svc.cluster.local` 的 `v1` 和 `v2` 版本上，它具有 `read`（`GET` 和 `HEAD`）权限。由于没有指定 `path`，它将作用于这个服务的所有 path 上。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: products-viewer
  namespace: default
spec:
  rules:
  - services: ["products.svc.cluster.local"]
    methods: ["GET", "HEAD"]
    constraints:
    - key: "destination.labels[version]"
      value: ["v1", "v2"]
{{< /text >}}

`ServiceRoleBinding` 对象的声明包含两部分：

- `roleRef` 字段引用相同 namespace 下的 `ServiceRole` 对象。
- 被分配到该角色的 `subjects` 列表。

除了一个简单的 `user` 字段，操作人员也可以在 `properties` 字段中使用自定义 key，“约束和属性” 页列出了被支持的 key。

如下是一个名为 `test-binding-products` 的 `ServiceRoleBinding` 对象，将两个 subjects 绑定到了名为 `product-viewer` 的 `ServiceRole` 上。

- `alice@yahoo.com` 用户
- `abc` namespace 下的所有 Service。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: test-binding-products
  namespace: default
spec:
  subjects:
  - user: alice@yahoo.com
  - properties:
      source.namespace: "abc"
  roleRef:
    kind: ServiceRole
    name: "products-viewer"
{{< /text >}}

## `AccessRule`

`AccessRule` 定义了一个访问一系列 services 的权限。

|字段|类型|描述|
|---|---|---|
|services|string[]|必填。service 名称的列表。支持 service 名称的精确匹配、前缀匹配和后缀匹配。例如，要匹配到 `bookstore.mtv.cluster.local`，可以使用 `bookstore.mtv.cluster.local`（精确匹配），或者 `bookstore`（前缀匹配），或者 `.mtv.cluster.local`（后缀匹配）。如果设置为 `["*"]`，则表示该 namespace 下的所有 Service。|
|paths|string[]|可选项。HTTP paths 列表或 gRPC methods 列表。gRPC methods 必须提供如 `/packageName.serviceName/methodName` 格式的完成名称，并且是大小写敏感的。HTTP paths 支持精确匹配、前缀匹配和后缀匹配。例如，要匹配 `/books/review` 这个 path，可以使用 `/books/review`（精准匹配），或 `/books/`（前缀匹配），或 `/review`（后缀匹配）。若不指定，则作用于所有 path。|
|methods|string[]|可选项。HTTP methods（如 `GET`，`POST`）列表。在 gRPC 场景下，由于值总是 `POST`，该选项将被忽略。如果设置为 `["*"]` 或者没有指定，它将应用于所有 Method。|
|constraints|[`AccessRule.Constraint[]`](#accessrule-constraint)|可选项。`ServiceRole` 定义中指定的其它约束。前面 `ServiceRole` 的定义中展示了关于“版本”的约束。|

## `AccessRule.Constraint`

自定义约束的声明，“约束和属性” 页列出了被支持的 key。

|字段|类型|描述|
|---|---|---|
|key|string|约束的 key。|
|values|string[]|约束的有效值列表。支持精确匹配、前缀匹配、后缀匹配。例如，`v1alpha2`（精确匹配）、`v1`（前缀匹配）或 `alpha2`（后缀匹配）都能匹配到值 `v1alpha2`。|

## `RbacConfig`

`RbacConfig` 定义了控制 Istio RBAC 行为的全局配置。这种类型的 Custom Resource 是独占的，在整个 mesh 中只能全局性创建一次，并且要跟其它 Istio 组件的 namespace 相同，通常为 `istio-system`。注意：这点在 `istioctl` 和 server 端都是强制的，如果已经存在了，创建新的 Custom Resource 会被拒绝，用户只能删掉或者修改已存在的定义。

如下是一个名为 `istio-rbac-config` 的 `RbacConfig` 对象的例子，允许 Istio RBAC 控制 `default` namespace 下的全部 Service。

{{< text yaml >}}
apiVersion: "rbac.istio.io/v1alpha1"
kind: RbacConfig
metadata:
  name: default
  namespace: istio-system
spec:
  mode: ON_WITH_INCLUSION
  inclusion:
    namespaces: [ "default" ]
{{< /text >}}

|字段|类型|描述|
|---|---|---|
|mode|[`RbacConfig.Mode`](#rbacconfig-mode)|Istio RBAC 模式|
|inclusion|[`RbacConfig.Target`](#rbacconfig-target)|强制执行 Istio RBAC Policies 的 services 或 namespaces 列表。注意：该字段仅在 mode 配置为 `ON_WITH_INCLUSION` 时有效，其它 mode 值情况下，该字段将被忽略。|
|exclusion|[`RbacConfig.Target`](#rbacconfig-target)|强制执行 Istio RBAC Policies 的 services 或 namespaces 列表。注意：该字段仅在 mode 配置为 `ON_WITH_EXCLUSION` 时有效，其它 mode 值情况下，该字段将被忽略。|

## `RbacConfig.Mode`

|名称|描述|
|---|---|
|OFF|关闭 Istio RBAC，`RbacConfig` 的所有配置将会失效，且 Istio RBAC Policies 不会执行。|
|ON|为所有 services 和 namespaces 启用 Istio RBAC。|
|`ON_WITH_INCLUSION`|仅针对 inclusion 字段中指定的 services 和 namespaces 启用 Istio RBAC。其它不在 inclusion 字段中的 services 和 namespaces 将不会被 Istio RBAC Policies 强制执行。|
|`ON_WITH_EXCLUSION`|针对除了 exclusion 字段中指定的 services 和 namespaces，启用 Istio RBAC。其它不在 exclusion 字段中的 services 和 namespaces 将按照 Istio RBAC Policies 执行。|

## `RbacConfig.Target`

Target 定义了一个 services 或 namespaces 列表。

|字段|类型|描述|
|---|---|---|
|services|string[]|services 列表。|
|namespaces|string[]|namespaces 列表。|

## `RoleRef`

`RoleRef` 引用一个 role 对象。

|字段|类型|描述|
|---|---|---|
|kind|string|必填。引用的 role 类型。目前仅支持 `ServiceRole` 类型。|
|name|string|必填。引用的 `ServiceRole` 对象名称。该 `ServiceRole` 对象必须跟 `ServiceRoleBinding` 对象在同一个 namespace 下。|

## `ServiceRole`

`ServiceRole` 的声明中包含一个访问规则（权限）列表。它在 `ServiceRole` 对象的 `spec` 部分表示。`ServiceRole` 的名称和 namespace 在 metadata 部分指定。

|字段|类型|描述|
|---|---|---|
|rules|[`AccessRule[]`](#accessrule)|必填。该 role 所拥有的访问权限规则集合。|

## `ServiceRoleBinding`

`ServiceRoleBinding` 向 `ServiceRole` 对象分配 subjects 列表。它在 `ServiceRoleBinding` 对象的 `spec` 部分表示。 `ServiceRoleBinding` 的 名称 and namespace 在 `metadata` 部分指定。

|字段|类型|描述|
|---|---|---|
|subjects|<a href="">[Subject[]](#subject)|必填。分配给 `ServiceRole` 对象的 subjects 列表。|
|`roleRef`|[`RoleRef`](#roleref)|必填。要绑定的 `ServiceRole` 对象。|

## `Subject`

Subject 定义了一个身份。 这个身份可以是一个用户，也可以通过一组 `properties` 来识别。`properties` 中支持的 keys 已经在“约束和属性”页列出。

|字段|类型|描述|
|---|---|---|
|user|string|可选项。代表一个 subject 的用户 name/ID。|
|properties|`map<string,string>`|可选项。一组标识 subject 的属性。前面的 `ServiceRoleBinding` 例子展示了一个 `source.namespace` 属性的例子。|

