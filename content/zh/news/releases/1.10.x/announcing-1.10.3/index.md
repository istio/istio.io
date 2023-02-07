---
title: 发布 Istio 1.10.3 版本
linktitle: 1.10.3
subtitle: 补丁发布
description: Istio 1.10.3 补丁发布。
publishdate: 2021-07-16
release: 1.10.3
aliases:
    - /zh/news/announcing-1.10.3
---

此版本包含一些漏洞修复，从而提高了系统的稳健性。这个版本说明描述了 Istio 1.10.2 和 Istio 1.10.3 之间的区别。

{{< relnote >}}

## 改变{#changes}

- **修复** 修复了当 `Sidecar` 资源只指定到特定主机时，通配符主机被错误地添加的问题。  ([Issue #33387](https://github.com/istio/istio/issues/33387))

- **修复** 修复了在 `VirtualService` 上设置 `retryRemoteLocalities` 时会产生 Envoy 拒绝的配置的问题。  ([Issue #33737](https://github.com/istio/istio/issues/33737))

- **改进** 改进了在对 `meshConfig.defaultConfig.proxyMetadata` 字段重写时执行深度合并，而不是替换所有值。
