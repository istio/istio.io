---
title: Istio 0.7 发布公告
linktitle: 0.7
subtitle: 重大更新
description: Istio 0.7 发布公告。
publishdate: 2018-03-28
release: 0.7.0
aliases:
    - /zh/about/notes/0.7
    - /zh/about/notes/0.7/index.html
    - /zh/news/2018/announcing-0.7
    - /zh/news/announcing-0.7
---

这次发布的版本，我们专注于改进构建和测试基础架构并提高测试质量。因此，本月没有新功能。

{{< relnote >}}

请注意，此版本包括对新的 v1alpha3 流量管理功能的初步支持。此功能仍在不断变化中，0.8 可能会有一些重大变化。
因此，如果您想探索，请继续前进，但它可能会在 0.8 或更高的版本有变化。

已知问题：

我们的 [Helm chart](/zh/docs/setup/install/helm) 现在必须使用一些变通的方法才能正确运行，查看 [4701](https://github.com/istio/istio/issues/4701) 获取详情。
