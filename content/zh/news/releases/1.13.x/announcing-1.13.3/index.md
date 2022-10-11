---
title: Istio 1.13.3 发布公告
linktitle: 1.13.3
subtitle: 补丁发布
description: Istio 1.13.3 补丁发布。
publishdate: 2022-04-18
release: 1.13.3
aliases:
    - /zh/news/announcing-1.13.3
---

此版本包含部分 bug 修复，用以提高健壮性，另外还提供了一些额外的配置支持。
本发行说明描述了 Istio 1.13.2 和 1.13.3 之间的区别。

{{< relnote >}}

## 变化{#changes}

- **新增** 新增了在初始安装时跳过全部 CNI 的支持。

- **新增** 为 Istio Pilot Helm charts 添加了 values，用于在 Deployment 上配置负载亲和及容忍规则。
  可以用于更好地调度 Istio 试点工作负载。

- **修复** 修复了在 Minikube 上运行 Istio 1.13 时，所有代理在启动时有 5 秒延迟的问题。
  ([Issue #37832](https://github.com/istio/istio/issues/37832))

- **修复**修复了删除 HTTP 过滤器时 Istio 不能正常工作的问题。

- **修复** 修复了升级到 Istio 1.12+ 后，某些跨命名空间的 VirtualService 被忽略的问题。
  ([Issue #37691](https://github.com/istio/istio/issues/37691))
