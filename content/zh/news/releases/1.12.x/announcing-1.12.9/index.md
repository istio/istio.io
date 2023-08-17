---
title: Istio 1.12.9 发布公告
linktitle: 1.12.9
subtitle: 补丁发布
description: Istio 1.12.9 补丁发布。
publishdate: 2022-07-12
release: 1.12.9
---

此版本包含错误修复，以提系统的高稳健性。同时本发布说明描述了 Istio 1.12.8 和 Istio 1.12.9 之间的不同之处。

{{< relnote >}}

## 改变{#changes}

- **修复** 修复了构建路由的顺序，即一条总括性的路由不再与在它之后宣布的其他路由形成短路。([Issue #39188](https://github.com/istio/istio/issues/39188))

- **修复** 修复了在更新多集群秘钥时，会更新所有注册表并停止所有的控制器。但是由控制器启动的通知器并没有停止，它们将继续在后台运行的错误。([Issue #39366](https://github.com/istio/istio/issues/39366))
