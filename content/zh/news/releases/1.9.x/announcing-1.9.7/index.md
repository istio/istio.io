---
title: 发布 Istio 1.9.7 版本
linktitle: 1.9.7
subtitle: 补丁发布
description: Istio 1.9.7 补丁发布。
publishdate: 2021-07-22
release: 1.9.7
aliases:
    - /zh/news/announcing-1.9.7
---

这个版本说明描述了 Istio 1.9.6 和 Istio 1.9.7 之间的区别。

{{< relnote >}}

## 变化{#changes}

- **新增** 空正则表达式匹配的验证器。([Issue 34065](https://github.com/istio/istio/issues/34065))

- **修复** `EndpointSlice` 竞赛导致错误状态。([Issue 33672](https://github.com/istio/istio/issues/33672))

- **修复** `EndpointSlice` 在服务更新时创建重复的 IP。
