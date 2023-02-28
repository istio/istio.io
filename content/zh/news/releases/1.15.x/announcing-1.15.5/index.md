---
title: 发布 Istio 1.15.5
linktitle: 1.15.5
subtitle: 补丁发布
description: Istio 1.15.5 补丁发布。
publishdate: 2023-01-30
release: 1.15.5
aliases:
    - /zh/news/announcing-1.15.5
---

此版本包含了一些改进稳健性的漏洞修复。本发布说明描述了 Istio 1.15.4 和 Istio 1.15.5 之间的不同之处。

{{< relnote >}}

## 变更{#changes}

- **新增** 在 `istioctl analyze` 命令中加入 `--revision` 参数，使其可以指定一个版本。
  ([Issue #38148](https://github.com/istio/istio/issues/38148))

- **新增** 缓解由 Go http2 库中的问题引起的请求偷渡漏洞。
  ([Issue #56352](https://github.com/golang/go/issues/56352))

- **修复** 修复了当 DestinationRule `PortLevelSettings[].Port` 为 nil 时，导致 istiod 异常退出的问题。
  ([Issue #42598](https://github.com/istio/istio/issues/42598))

- **修复** 修复了一个导致命名空间级网络标签（`topology.istio.io/network`）优先于 Pod 标签的问题。
  ([Issue #42675](https://github.com/istio/istio/issues/42675))
