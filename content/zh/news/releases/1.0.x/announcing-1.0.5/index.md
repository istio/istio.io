---
title: Istio 1.0.5 发布公告
linktitle: 1.0.5
subtitle: 补丁发布
description: Istio 1.0.5 补丁发布。
publishdate: 2018-12-20
release: 1.0.5
aliases:
    - /zh/about/notes/1.0.5
    - /zh/blog/2018/announcing-1.0.5
    - /zh/news/2018/announcing-1.0.5
    - /zh/news/announcing-1.0.5
---

我们很高兴的宣布 Istio 1.0.5 现已正式发布。下面是更新详情。

{{< relnote >}}

## 概况{#general}

- 禁用 `istio-policy` 服务中的前置条件缓存，因为它会导致无效的结果。缓存将在以后的版本中重新引入。

- Mixer 现在仅在启用了 `tracespan` 适配器的情况下才生成 span，从而降低了正常情况下的 CPU 开销。

- 修复了一个可能导致 Pilot 挂起的 bug。
