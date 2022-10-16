---
title: 发布 Istio 1.8.4 版本
linktitle: 1.8.4
subtitle: 补丁发布
description: Istio 1.8.4 补丁发布。
publishdate: 2021-03-10
release: 1.8.4
aliases:
    - /news/announcing-1.8.4
---

这个版本包含了错误修复，以提高稳定性。主要说明 Istio 1.8.3 和 Istio 1.8.4 之间的不同之处。

{{< relnote >}}

## 变更

- **修复** Aurara 平台的元数据处理问题。支持 `tagsList` 序列化实例元数据上的标签。
  ([Issue #31176](https://github.com/istio/istio/issues/31176))

- **修复** 一个导致Envoy二进制文件被包含在docker镜像中的问题，这些二进制文件在功能上是等效的。
  ([Issue #31038](https://github.com/istio/istio/issues/31038))

- **修复** 一个导致使用 Istio 探针重写时 HTTP 头部被复制的问题。
  ([Issue #28466](https://github.com/istio/istio/issues/28466))