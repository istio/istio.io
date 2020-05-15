---
title: Istio 1.0.8 发布公告
linktitle: 1.0.8
subtitle: 补丁发布
description: Istio 1.0.8 补丁发布。
publishdate: 2019-06-07
release: 1.0.8
aliases:
    - /zh/about/notes/1.0.8
    - /zh/blog/2019/announcing-1.0.8
    - /zh/news/2019/announcing-1.0.8
    - /zh/news/announcing-1.0.8
---

我们很高兴的宣布 Istio 1.0.8 现已正式发布。下面是更新详情。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- 修复了 Citadel 如果无法联系 Kubernetes API 服务器可能会生成新的根 CA 的问题，该问题会导致双向 TLS 验证失败（[Issue 14512](https://github.com/istio/istio/issues/14512)）。

## 小的改进{#small-enhancements}

- 将 Citadel 默认根 CA 证书的 TTL 从 1 年更新为 10 年。
