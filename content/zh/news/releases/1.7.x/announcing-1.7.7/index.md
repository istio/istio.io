---
title: Istio 1.7.7 发布公告
linktitle: 1.7.7
subtitle: 补丁发布
description: Istio 1.7.7 补丁发布。
publishdate: 2021-01-29
release: 1.7.7
aliases:
- /zh/news/announcing-1.7.7
---

此版本包含一些 bug 修复用以提高程序的健壮性。同时这个版本说明也描述了 Istio 1.7.6 和 Istio 1.7.7 之间的区别。

{{< relnote >}}

## 改变{#changes}

- **修复** 修复了在安装时使用明确为空的修订版本上安装 istioctl 失败的问题。
  ([Issue #26940](https://github.com/istio/istio/issues/26940))
- **修复** 修复了 CA 证书的签名算法为对应于 CA 签名密钥类型的默认算法问题。
  ([Issue #27238](https://github.com/istio/istio/issues/27238))
- **修复** 修复了当降级到较低版本 Istio 时显示不必要警告的问题。
  ([Issue #29183](https://github.com/istio/istio/issues/29183))
- **修复** 修复了旧的控制平面依赖的 `rbac.istio.io` CRD 组在重启时被挂起的问题，因为新的控制平面安装时默认从 istiod 中删除了这些权限。
  ([Issue #29364](https://github.com/istio/istio/issues/29364))
- **修复** 修复了在 WASM `NullPlugin` `onNetworkNewConnection` 中的内存泄漏问题。
  ([Issue #24720](https://github.com/istio/istio/issues/24720))
