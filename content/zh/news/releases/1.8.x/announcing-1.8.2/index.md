---
title: 发布 Istio 1.8.2 版本
linktitle: 1.8.2
subtitle: 补丁发布
description: Istio 1.8.2  补丁发布。
publishdate: 2021-01-14
release: 1.8.2
aliases:
    - /zh/news/announcing-1.8.2
---

这个版本包含了错误修复，以提高稳定性。主要说明 Istio 1.8.1 和 Istio 1.8.2 之间的不同之处。

{{< relnote >}}

## 变动{#changes}

- **优化** `WorkloadEntry` 自动注册的稳定性。
  ([PR #29876](https://github.com/istio/istio/pull/29876))

- **修复** CA 的证书签名算法为默认算法，与 CA 的签名密钥类型相对应。
  ([Issue #27238](https://github.com/istio/istio/issues/27238))

- **修复** 新安装的控制机从 `istiod` 中删除了 `rbac.istio.io` 的权限，导致依赖该CRD组的旧控制机在重新启动时挂起。
  ([Issue #29364](https://github.com/istio/istio/issues/29364))

- **修复** 自定义网关的空服务端口问题。
  ([Issue #29608](https://github.com/istio/istio/issues/29608))

- **修复** 在 `EnvoyFilter` 中使用废弃的过滤器名称会覆盖其他 `EnvoyFilter` 的问题。
  ([Issue #29858](https://github.com/istio/istio/issues/29858))([Issue #29909](https://github.com/istio/istio/issues/29909))

- **修复** 导致匹配过滤器链的 `EnvoyFilter` 无法正确应用的问题。
   ([PR #29486](https://github.com/istio/istio/pull/29486))

- **修复** 导致名为 `<secret>-cacert` 的 Secret 的优先级低于名为 `<secret>` 的 Gateway Mutual TLS 的 Secret的优先级的问题。在 Istio 1.8 中，这一行为被意外地颠倒了。此更改恢复了匹配 Istio 1.7 及更早版本。
  ([Issue #29856](https://github.com/istio/istio/issues/29856))

- **修复** 导致在外部 TLS 发起过程中仅设置内部 ALPN 值的问题。
  ([Issue #24619](https://github.com/istio/istio/issues/24619))

- **修复** 导致客户端应用 TLS 请求发送到启用了 PERMISSIVE 模式的服务器上失败的问题。
  ([Issue #29538](https://github.com/istio/istio/issues/29538))

- **修复** 导致 `targetPort` 选项对有多个端口的 `WorkloadEntry` 不生效的问题。
  ([PR #29887](https://github.com/istio/istio/pull/29887))
