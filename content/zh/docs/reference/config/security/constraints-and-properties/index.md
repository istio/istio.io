---
title: RBAC 约束和属性（不建议使用）
description: 受支持的约束条件和属性。
weight: 50
aliases:
    - /zh/docs/reference/config/security/constraints-and-properties/
---

{{< warning >}}
RBAC 策略中的约束和属性已经被 `AuthorizationPolicy` 弃用。 请使用 `AuthorizationPolicy` 资源中的条件，此页面仅供参考，以后将被删除。
{{< /warning >}}

本节包含支持格式化的键和值，你可以将其用作于服务角色和服务角色绑定配置对象中的约束和属性。约束和属性是额外的条件，你可以将其添加为配置对象中的 `kind:`,`ServiceRole` 和  `ServiceRoleBinding` 作为一个值去指定详细的访问控制要求。

具体来讲，你可以使用约束在服务角色的访问规则字段中指定其他条件，你也可以使用它的属性在服务角色绑定的主题字段中指定其他条件。`Istio` 支持此在此页面上列出的所有 `HTTP` 协议密钥，但是仅支持一些简单的 `TCP` 协议密钥。

{{< warning >}}
不支持的键和值将被忽略。
{{< /warning >}}

有关更多信息，请参阅 [授权概念页面](/zh/docs/concepts/security/#authorization)。

## 支持的约束{#supported-constraints}

下表列出了该 `constraints` 字段当前支持的键：

| 名称 | 描述 | 是否支持TCP协议 | 示例键 | 示例值 |
|------|-------------|----------------------------|-------------|----------------|
| `destination.ip` | 目标IP地址，支持单个IP或CIDR | YES | `destination.ip` |  `["10.1.2.3", "10.2.0.0/16"]` |
| `destination.port` | 目标IP地址上的端口，必须在[0，65535]范围内 | YES | `destination.port` | `["80", "443"]` |
| `destination.labels` | 附加到服务器实例的键值对的映射 | YES | `destination.labels[version]` | `["v1", "v2"]` |
| `destination.namespace` | 目标负载实例命名空间 | YES | `destination.namespace` | `["default"]` |
| `destination.user` | 目标负载上的用户 | YES | `destination.user` | `["bookinfo-productpage"]` |
| `experimental.envoy.filters.*` | 用于过滤器的实验性元数据匹配，包装的值[]作为列表匹配 | YES | `experimental.envoy.filters.network.mysql_proxy[db.table]` | `["[update]"]` |
| `request.headers` | HTTP请求头，需要用[]括起来 | NO | `request.headers[X-Custom-Token]` | `["abc123"]` |

{{< warning >}}
请注意，无法保证 `experimental.*` 密钥向后的兼容性，可以随时将它们删除，须谨慎操作。
{{< /warning >}}

## 支持的属性{#supported-properties}

下表列出了该 `properties` 字段当前支持的键：

| 名称 | 描述 | 是否支持TCP协议 | 示例键 | 示例值 |
|------|-------------|----------------------------|-------------|---------------|
| `source.ip`  | 源IP地址，支持单个IP或CIDR | YES | `source.ip` | `"10.1.2.3"` |
| `source.namespace`  | 源负载实例命名空间 | YES | `source.namespace` | `"default"` |
| `source.principal` | 源负载的标识 | YES | `source.principal` | `"cluster.local/ns/default/sa/productpage"` |
| `request.headers` | HTTP请求头，需要用[]括起来 | NO | `request.headers[User-Agent]` | `"Mozilla/*"` |
| `request.auth.principal` | 对于请求已验证的主体。 | NO | `request.auth.principal` | `"accounts.my-svc.com/104958560606"` |
| `request.auth.audiences` | 此身份验证信息的目标主体 | NO | `request.auth.audiences` | `"my-svc.com"` |
| `request.auth.presenter` | 证书的授权者 | NO | `request.auth.presenter` | `"123456789012.my-svc.com"` |
| `request.auth.claims` | 请求源JWT组织。需要用[]括起来 | NO | `request.auth.claims[iss]` | `"*@foo.com"` |

