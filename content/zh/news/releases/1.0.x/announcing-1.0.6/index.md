---
title: Istio 1.0.6 发布公告
linktitle: 1.0.6
subtitle: 补丁发布
description: Istio 1.0.6 补丁发布。
publishdate: 2019-02-12
release: 1.0.6
aliases:
    - /zh/about/notes/1.0.6
    - /zh/blog/2019/announcing-1.0.6
    - /zh/news/2019/announcing-1.0.6
    - /zh/news/announcing-1.0.6
---

我们很高兴的宣布 Istio 1.0.6 现已正式发布。下面是更新详情。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复 Galley Helm 图表，使 `validatingwebhookconfiguration` 对象现在可以部署到 `istio-system` 以外的名称空间（[Issue 13625](https://github.com/istio/istio/issues/13625)）。
- Helm 图表中其他针对反亲和性支持的修复：修复 `gatewaypodAntiAffinityRequiredDuringScheduling` 和 `podAntiAffinityLabelSelector` 匹配表达式，并修复 `podAntiAffinityLabelSelector` 的默认值（[Issue 13892](https://github.com/istio/istio/issues/13892)）。
- 让 Pilot 处理这种情况：监听器资源耗尽时，Envoy 依然继续请求已删除被 gateway 的路由（[Issue 13739](https://github.com/istio/istio/issues/13739)）。

## 小的改进{#small-enhancements}

- 如果启用了访问日志，`passthrough` 监听器的请求将被记录。
- 使 Pilot 容忍未知的 JSON 字段，以便在升级过程中可以更轻松地回滚到旧版本。
- 将备用 secret 的支持添加到 Envoy 可以使用的 `SDS` 中，而不是在启动过程中无限期地等待最新的或不存在的 secret（[Issue 13853](https://github.com/istio/istio/issues/13853)）。
