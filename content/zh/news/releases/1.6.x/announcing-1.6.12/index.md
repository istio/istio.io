---
title: 发布 Istio 1.6.12
linktitle: 1.6.12
subtitle: 补丁更新
description: Istio 1.6.12 补丁更新。
publishdate: 2020-10-06
release: 1.6.12
aliases:
    - /news/announcing-1.6.12
---


此版本包含修复错误以提高健壮性。本版本说明介绍了 Istio 1.6.11 和 Istio 1.6.12 之间的差异。

{{< relnote >}}

## 变更

- **添加** 在多集群安装中配置域后缀的能力 ([Issue #27300](https://github.com/istio/istio/issues/27300))

- **添加** 支持 Kubernetes 设置运算符 API 中的 `securityContext`。 ([Issue #26275](https://github.com/istio/istio/issues/26275))

- **修复** `Host` 标头中设置端口时，解决了防止对通配符 (如 `*.example.com`) 域的调用的问题。([Issue＃25350](https://github.com/istio/istio/issues/25350))