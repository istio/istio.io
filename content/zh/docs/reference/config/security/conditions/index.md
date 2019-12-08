---
title: 授权策略
description: 授权策略中支持的条件。
weight: 30
aliases:
    - /zh/docs/reference/config/security/conditions/
---

此页面描述了可以用作[授权策略](/zh/docs/reference/config/security/authorization-policy/) `when` 字段中所支持的键和值的格式。

{{< warning >}}
不支持的键和值将被忽略。
{{< /warning >}}

有关更多信息，请参阅[授权概念页面](/zh/docs/concepts/security/#authorization)。

## 支持条件{#supported-conditions}

| 名称 | 描述 | 支持的协议 | 示例 |
|------|-------------|--------------------|---------|
| `request.headers` | `HTTP` 请求头，需要用 `[]` 括起来 | HTTP only | `key: request.headers[User-Agent]`<br/>`values: ["Mozilla/*"]` |
| `source.ip`  | 源 `IP` 地址，支持单个 `IP` 或 `CIDR` | HTTP and TCP | `key: source.ip`<br/>`values: ["10.1.2.3"]` |
| `source.namespace`  | 源负载实例命名空间 | HTTP and TCP | `key: source.namespace`<br/>`values: ["default"]` |
| `source.principal` | 源负载的标识 | HTTP and TCP | `key: source.principal`<br/>`values: ["cluster.local/ns/default/sa/productpage"]` |
| `request.auth.principal` | 已认证过 `principal` 的请求。 | HTTP only | `key: request.auth.principal`<br/>`values: ["accounts.my-svc.com/104958560606"]` |
| `request.auth.audiences` | 此身份验证信息的目标主体 | HTTP only | `key: request.auth.audiences`<br/>`values: ["my-svc.com"]` |
| `request.auth.presenter` | 证书的颁发者 | HTTP only | `key: request.auth.presenter`<br/>`values: ["123456789012.my-svc.com"]` |
| `request.auth.claims` | `Claims` 来源于 `JWT`。需要用 `[]` 括起来 | HTTP only | `key: request.auth.claims[iss]`<br/>`values: ["*@foo.com"]` |
| `destination.ip` | 目标 `IP` 地址，支持单个 `IP` 或 `CIDR` | HTTP and TCP | `key: destination.ip`<br/>`values: ["10.1.2.3", "10.2.0.0/16"]` |
| `destination.port` | 目标 `IP` 地址上的端口，必须在 `[0，65535]` 范围内 | HTTP and TCP | `key: destination.port`<br/>`values: ["80", "443"]` |
| `connection.sni` | 服务器名称指示 | HTTP and TCP | `key: connection.sni`<br/>`values: ["www.example.com"]` |
| `experimental.envoy.filters.*` | 用于过滤器的实验性元数据匹配，包装的值 `[]` 作为列表匹配 | HTTP and TCP | `key: experimental.envoy.filters.network.mysql_proxy[db.table]`<br/>`values: ["[update]"]` |

{{< warning >}}
无法保证 `experimental.*` 密钥向后的兼容性，可以随时将它们删除，但是须要谨慎操作。
{{< /warning >}}
