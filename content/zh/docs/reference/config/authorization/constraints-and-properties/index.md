---
title: 约束和属性
description: 描述所支持的约束和属性。
weight: 10
---

本节包含所支持的键和值格式，您可以用作服务角色和服务角色绑定配置对象中的约束和属性。约束和属性是可以在配置对象中作为字段添加的额外条件，通过 `ServiceRole` 和 `ServiceRoleBinding` 中的 `kind:` 值来指定详细的访问控制要求。

具体来说，您可以使用约束在服务角色的访问规则字段中指定额外条件。您可以使用属性在服务角色绑定的主题字段中指定额外条件。对于 HTTP 协议，Istio 支持此页面列出的所有键，但对于普通 TCP 协议仅支持其中一部分。

{{< warning >}}
不支持的键和值将被默默忽略。
{{< /warning >}}

了解更多信息，请参阅[授权概念页面](/zh/docs/concepts/security/#authorization).

## 支持的约束{#supported-constraints}

下表列出了 `constraints` 字段当前所支持的键:

| 名称 | 描述 | 是否支持 TCP 服务 | 键示例 | 值示例 |
|------|-------------|----------------------------|-------------|----------------|
| `destination.ip` | 目标工作负载实例 IP 地址，支持单个 IP 或 CIDR | YES | `destination.ip` |  `["10.1.2.3", "10.2.0.0/16"]` |
| `destination.port` | 服务器 IP 地址的接收端口，必须在[0, 65535]范围内 | YES | `destination.port` | `["80", "443"]` |
| `destination.labels` | 附属于服务器实例的键值对映射 | YES | `destination.labels[version]` | `["v1", "v2"]` |
| `destination.namespace` | 目标工作负载实例的命名空间 | YES | `destination.namespace` | `["default"]` |
| `destination.user` | 目标工作负载的身份 | YES | `destination.user` | `["bookinfo-productpage"]` |
| `experimental.envoy.filters.*` | 用于过滤器的实验性元数据匹配，包含在`[]`中的值作为列表被匹配 | YES | `experimental.envoy.filters.network.mysql_proxy[db.table]` | `["[update]"]` |
| `request.headers` | HTTP 请求头，实际的头名称包含在括号中 | NO | `request.headers[X-Custom-Token]` | `["abc123"]` |

{{< warning >}}
请注意，对于 `experimental.*` 的键不能保证向后兼容。它们可能随时被移除，建议用户自行承担使用它们的风险。
{{< /warning >}}

## 支持的属性{#supported-properties}

下表列出了 `properties` 字段当前所支持的键:

| 名称 | 描述 | 是否支持 TCP 服务 | 键示例 | 值示例 |
|------|-------------|----------------------------|-------------|---------------|
| `source.ip`  | 源工作负载实例 IP 地址，支持单个 IP 或 CIDR | YES | `source.ip` | `"10.1.2.3"` |
| `source.namespace`  | 源工作负载实例的命名空间 | YES | `source.namespace` | `"default"` |
| `source.principal` | 源工作负载的身份 | YES | `source.principal` | `"cluster.local/ns/default/sa/productpage"` |
| `request.headers` | HTTP 请求头，实际的头名称包含在括号中 | NO | `request.headers[User-Agent]` | `"Mozilla/*"` |
| `request.auth.principal` | 请求的认证主体 | NO | `request.auth.principal` | `"accounts.my-svc.com/104958560606"` |
| `request.auth.audiences` | 此认证信息的目标受众 | NO | `request.auth.audiences` | `"my-svc.com"` |
| `request.auth.presenter` | 证书的合法授权人 | NO | `request.auth.presenter` | `"123456789012.my-svc.com"` |
| `request.auth.claims` | 原始 JWT 断言。实际的断言名称包含在括号中 | NO | `request.auth.claims[iss]` | `"*@foo.com"` |
