---
title: 发布公告 Istio 1.1.6
linktitle: 1.1.6
subtitle: 补丁发布
description: Istio 1.1.6 补丁发布。
publishdate: 2019-05-11
release: 1.1.6
aliases:
    - /zh/about/notes/1.1.6
    - /zh/blog/2019/announcing-1.1.6
    - /zh/news/2019/announcing-1.1.6
    - /zh/news/announcing-1.1.6
---

我们非常高兴的宣布 Istio 1.1.6 已经可用。请浏览下面的变更说明。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复 Galley Helm charts 使得 `validatingwebhookconfiguration` 可以部署到其它命名空间（非 `istio-system`）中（[Issue 13625](https://github.com/istio/istio/issues/13625)）。
- 为反亲和性支持提供额外的 Helm chart 修复：修复 `gatewaypodAntiAffinityRequiredDuringScheduling` 和 `podAntiAffinityLabelSelector` 匹配表达式以及修复 `podAntiAffinityLabelSelector` 的默认值（[Issue 13892](https://github.com/istio/istio/issues/13892)）。
- 使 Pilot 处理以下情况：在侦听器还在回收时，Envoy 持续请求已删除网关的路由（[Issue 13739](https://github.com/istio/istio/issues/13739)）。

## 小改进{#small-enhancements}

- 如果启用了访问日志，`passthrough` 侦听器的请求将被记录。
- 使 Pilot 容忍未知的 JSON 字段，以便在升级过程中更轻松地回滚到旧版本。
- `SDS` 增加对后备 secrets 的支持，使得 Envoy 可以使用它而不是在启动过程中无限期地等待最新或不存在的 secret（[Issue 13853](https://github.com/istio/istio/issues/13853)）。
