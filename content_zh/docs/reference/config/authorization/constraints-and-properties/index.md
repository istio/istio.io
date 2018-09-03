---
title: 约束和属性
description: 描述所支持的约束和属性。
weight: 10
---

本页列举了在`约束`和`属性`中所使用到的 key 值。`约束`可用于在 `ServiceRole` 中指定额外的定制条件，`属性`可用于在 `ServiceRoleBinding` 中指定额外的定制条件。了解更多信息，请参阅[授权的概念页面](/zh/docs/concepts/security/#认证)。

## 约束

下表列举了`约束`中当前支持的键值：

| 名称 | 描述 | 键值示例 | 值示例 |
|------|-------------|-------------|----------------|
| `destination.ip` | 目标工作负载实例 IP 地址，支持单 IP 或 CIDR | `destination.ip` |  `["10.1.2.3", "10.2.0.0/16"]` |
| `destination.port` | 服务器 IP 地址的接收者端口，必须是 0 到 65535 中的随机数 | `destination.port` | `["80", "443"]` |
| `destination.labels` | 链接到服务器实例的键值对的映射 | `destination.labels[version]` | `["v1", "v2"]` |
| `destination.name` | 目标工作负载实例名 | `destination.name` | `["productpage*", "*-test"]` |
| `destination.namespace` | 目标工作负载实例命名空间 | `destination.namespace` | `["default"]` |
| `destination.user` | 目标工作负载实例的标识 | `destination.user` | `["bookinfo-productpage"]` |
| `request.headers` | HTTP 请求头, 实际的请求头名称包含在括号中 | `request.headers[X-Custom-Token]` | `["abc123"]` |

## 属性

下表列举了`属性`中当前支持的键值：

| 名称 | 描述 | 键值示例 | 值示例 |
|------|-------------|-------------|---------------|
| `source.ip`  | 源工作负载实例 IP 地址，支持单 IP 或 CIDR | `source.ip` | `"10.1.2.3"` |
| `source.namespace`  | 源工作负载实例命名空间 | `source.namespace` | `"default"` |
| `source.principal` | 源工作负载实例标识 | `source.principal` | `"cluster.local/ns/default/sa/productpage"` |
| `request.headers` | HTTP 请求头, 实际的请求头名称包含在括号中 | `request.headers[User-Agent]` | `"Mozilla/*"` |
| `request.auth.principal` | 请求中最重要的认证 | `request.auth.principal` | `"accounts.my-svc.com/104958560606"` |
| `request.auth.audiences` | 认证信息的预期受众 | `request.auth.audiences` | `"my-svc.com"` |
| `request.auth.presenter` | 被授权的授权人 | `request.auth.presenter` | `"123456789012.my-svc.com"` |
| `request.auth.claims` | 原始 JWT 断言。实际的断言名称包含在括号中 | `request.auth.claims[iss]` | `"*@foo.com"` |
