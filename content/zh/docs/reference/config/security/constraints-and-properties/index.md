---
title: RBAC 约束和属性（不建议使用）
description: 受支持的约束条件和属性。
weight: 50
aliases:
    - /zh/docs/reference/config/security/constraints-and-properties/
---

{{< warning >}}
RBAC 策略中的约束和属性已经被 `AuthorizationPolicy` 中的条件取代。 请使用 `AuthorizationPolicy` 资源中的条件，此页面仅供参考，以后将被删除。
{{< /warning >}}

本节包含支持格式化的键和值，你可以将其用作于服务角色和服务角色绑定配置对象中的约束和属性。约束和属性是额外的条件，你可以指定配置对象 `kind:` 字段的值为 `ServiceRole` 或 `ServiceRoleBinding`，以指定详细的访问控制要求。

具体来讲，你可以使用 `service role` 中 `access rule` 字段的 `constraints` 来指定额外的条件，也可以使用 `service role binding` 中 `subject` 字段的 `properties` 来指定额外的条件。`Istio` 支持此在此页面上列出的所有 `HTTP` 协议密钥，但是仅支持一些简单的 `TCP` 协议密钥。

{{< warning >}}
不支持的键和值将被忽略。
{{< /warning >}}

有关更多信息，请参阅 [授权概念页面](/zh/docs/concepts/security/#authorization)。

## 支持的约束{#supported-constraints}

下表列出了该 `constraints` 字段当前支持的键：

| 名称 | 描述 | 是否支持 `TCP` 协议 | 示例键 | 示例值 |
|------|-------------|----------------------------|-------------|----------------|
| `destination.ip` | 目标 `IP` 地址，支持单个 `IP` 或 `CIDR` | YES | `destination.ip` |  `["10.1.2.3", "10.2.0.0/16"]` |
| `destination.port` | 目标 `IP` 地址上的端口，必须在 `[0，65535]` 范围内 | YES | `destination.port` | `["80", "443"]` |
| `destination.labels` | 附加到服务器实例的键值对的映射 | YES | `destination.labels[version]` | `["v1", "v2"]` |
| `destination.namespace` | 目标负载实例命名空间 | YES | `destination.namespace` | `["default"]` |
| `destination.user` | 目标负载上的标识 | YES | `destination.user` | `["bookinfo-productpage"]` |
| `experimental.envoy.filters.*` | 用于过滤器的实验性元数据匹配，包裹在 `[]` 列表中的值被用于匹配 | YES | `experimental.envoy.filters.network.mysql_proxy[db.table]` | `["[update]"]` |
| `request.headers` | `HTTP` 请求头，需要用 `[]` 括起来 | NO | `request.headers[X-Custom-Token]` | `["abc123"]` |

{{< warning >}}
请注意，无法保证 `experimental.*` 密钥向后的兼容性，可以随时删除它们，但是须要谨慎操作。
{{< /warning >}}

## 支持的属性{#supported-properties}

下表列出了该 `properties` 字段当前支持的键：

| 名称 | 描述 | 是否支持 `TCP` 协议 | 示例键 | 示例值 |
|------|-------------|----------------------------|-------------|---------------|
| `source.ip`  | 源 `IP` 地址，支持单个 `IP` 或 `CIDR` | YES | `source.ip` | `"10.1.2.3"` |
| `source.namespace`  | 源负载实例命名空间 | YES | `source.namespace` | `"default"` |
| `source.principal` | 源负载的标识 | YES | `source.principal` | `"cluster.local/ns/default/sa/productpage"` |
| `request.headers` | `HTTP` 请求头，需要用 `[]` 括起来 | NO | `request.headers[User-Agent]` | `"Mozilla/*"` |
| `request.auth.principal` | 已认证过 `principal` 的请求。 | NO | `request.auth.principal` | `"accounts.my-svc.com/104958560606"` |
| `request.auth.audiences` | 此身份验证信息的目标主体 | NO | `request.auth.audiences` | `"my-svc.com"` |
| `request.auth.presenter` | 证书的颁发者 | NO | `request.auth.presenter` | `"123456789012.my-svc.com"` |
| `request.auth.claims` | `Claims` 来源于 `JWT`。需要用 `[]` 括起来 | NO | `request.auth.claims[iss]` | `"*@foo.com"` |
