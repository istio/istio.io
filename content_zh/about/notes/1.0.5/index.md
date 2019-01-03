---
title: Istio 1.0.5
weight: 87
icon: notes
---

社区在 Istio 1.0.4 的使用过程中发现了一些严重问题，本次发布对这些问题进行了处理。本文对 Istio 1.0.4 和 1.0.5 两个版本之间的差异进行了描述。

{{< relnote_links >}}

## 修复

- 禁用 istio-policy 服务中的前置条件缓存，因为它会导致无效的结果。缓存将在以后的版本中被重新引入。

- Mixer 现在只在启用 `tracespan` 适配器时才生成 span，从而在正常情况下降低 CPU 开销。

- 修正了一个可能导致 Pilot 挂起的问题。
