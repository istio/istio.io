---
title: 约束和属性
description: 描述所支持的约束和属性。
weight: 10
---

本节包含支持的键和值，你可用作服务角色和服务角色绑定配置对象中的约束和属性。约束和属性是可以作为配置对象中的字段添加的额外条件，其`kind`:值为`ServiceRole`和`ServiceRoleBinding`指定详细的访问控制要求。

具体而言，你可以使用约束在服务角色的访问规则字段中指定额外条件。你可以使用属性在服务角色绑定的主题字段中指定其他条件。Istio支持此页面上列出的HTTP协议的所有密钥，但仅支持普通TCP协议的一些密钥。

> {{< warning_icon >}} 不支持的键和值将会被默默忽略。

了解更多信息，请参阅[授权的概念页面](/zh/docs/concepts/security/#认证)。

## 支持的约束

下表列举了`约束`中当前支持的键值：

| 名称 | 描述 | 是否支持TCP服务| 键值示例 | 值示例 |
|------|-------------|--------------|-------------|----------------|
| `destination.ip` | 目标工作负载实例 IP 地址，支持单 IP 或 CIDR | 是 | `destination.ip` |  `["10.1.2.3", "10.2.0.0/16"]` |
| `destination.port` | 服务器 IP 地址的接收者端口，必须是 0 到 65535 中的随机数 | 是 |`destination.port` | `["80", "443"]` |
| `destination.labels` | 链接到服务器实例的键值对的映射 | 是 | `destination.labels[version]` | `["v1", "v2"]` |
| `destination.name` | 目标工作负载实例名 | 是 | `destination.name` |`["productpage*", "*-test"]` |
| `destination.namespace` | 目标工作负载实例命名空间 | 是 | `destination.namespace` | `["default"]` |
| `destination.user` | 目标工作负载实例的标识 | 是 | `destination.user` | `["bookinfo-productpage"]` |
| `request.headers` | HTTP 请求头, 实际的请求头名称包含在括号中 | 否 | `request.headers[X-Custom-Token]` | `["abc123"]` |

## 支持的属性

下表列举了`属性`中当前支持的键值：

| 名称 | 描述 | 是否支持TCP服务 | 键值示例 | 值示例 |
|------|-------------|-----------|-------------|---------------|
| `source.ip`  | 源工作负载实例 IP 地址，支持单 IP 或 CIDR | 是 | `source.ip` | `"10.1.2.3"` |
| `source.namespace`  | 源工作负载实例命名空间 | 是 | `source.namespace` | `"default"` |
| `source.principal` | 源工作负载实例标识 | 是 | `source.principal` | `"cluster.local/ns/default/sa/productpage"` |
| `request.headers` | HTTP 请求头, 实际的请求头名称包含在括号中 | 否 | `request.headers[User-Agent]` | `"Mozilla/*"` |
| `request.auth.principal` | 请求中最重要的认证 | 否 | `request.auth.principal` | `"accounts.my-svc.com/104958560606"` |
| `request.auth.audiences` | 认证信息的预期受众 | 否 | `request.auth.audiences` | `"my-svc.com"` |
| `request.auth.presenter` | 被授权的授权人 | 否 | `request.auth.presenter` | `"123456789012.my-svc.com"` |
| `request.auth.claims` | 原始 JWT 断言。实际的断言名称包含在括号中 | 否 | `request.auth.claims[iss]` | `"*@foo.com"` |
