---
title: Istio 1.3.3 发布公告
linktitle: 1.3.3
subtitle: 补丁发布
description: Istio 1.3.3 补丁发布。
publishdate: 2019-10-14
release: 1.3.3
aliases:
    - /zh/news/2019/announcing-1.3.3
    - /zh/news/announcing-1.3.3
---

此版本包含一些错误修复程序，以提高稳定性。此发行说明描述了 Istio 1.3.2 和 Istio 1.3.3 之间的区别。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- **Fixed** 当使用 `istioctl x manifest apply` 时导致 Prometheus 安装不正确的问题。（[Issue 16970](https://github.com/istio/istio/issues/16970)）
- **Fixed** 本地负载均衡不能从本地节点读取位置信息的错误。（[Issue 17337](https://github.com/istio/istio/issues/17337)）
- **Fixed** 当侦听器在没有任何用户配置更改的情况下进行重新配置时，Envoy 代理会删除长连接。（[Issue 17383](https://github.com/istio/istio/issues/17383)，[Issue 17139](https://github.com/istio/istio/issues/17139)）
- **Fixed** `istioctl x analyze` 命令的崩溃问题。（[Issue 17449](https://github.com/istio/istio/issues/17449)）
- **Fixed** `istioctl x manifest diff` 命令中 ConfigMaps 中的差异文本块。（[Issue 16828](https://github.com/istio/istio/issues/16828)）
- **Fixed** Envoy proxy 的分段错误崩溃问题。（[Issue 17699](https://github.com/istio/istio/issues/17699)）
