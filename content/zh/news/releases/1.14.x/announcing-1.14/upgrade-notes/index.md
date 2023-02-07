---
title: Istio 1.14 更新说明
description: 升级到 Istio 1.14.0 时需要考虑的重要变化。
publishdate: 2022-05-24
weight: 20
---

当您从 Istio 1.13.x 升级到 Istio 1.14.0 时，您需要考虑此页面上所描述的变化。
这些说明详细介绍了有意地破坏与 Istio 1.14.0 的向后兼容性所带来的变化。
说明中还提到了在引入新行为的同时保留向后兼容性的变化。
只有当新的行为对 Istio `1.13.x` 的用户来说是意想不到的时候，才会包括这些变化。
从 1.12.x 升级到 Istio 1.14.0 的用户还应该参考 [1.13.0 变更日志](/zh/news/releases/1.13.x/announcing-1.13/change-notes/)。

## 从 `gogo/protobuf` 库迁移{#gogo-protobuf-library-migration }

`istio.io/api` 和 `istio.io/client-go` 库已经从使用 [`gogo/protobuf`](https://github.com/gogo/protobuf) 库
切换到使用 API 类型的 [`golang/protobuf`](https://github.com/golang/protobuf) 库。

这个变化对典型的 Istio 用户没有任何影响，但会影响将 Istio 作为 Go 库导入的用户。

对于这些用户，升级 Istio 库可能会导致编译产生问题。这些问题通常很容易解决，而且主要是语法问题。
关于新的 protobuf API，在 [Go 博客](https://go.dev/blog/protobuf-apiv2) 可以查看到相关的迁移帮助。
