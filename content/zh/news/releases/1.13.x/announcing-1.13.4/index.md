---
title: Istio 1.13.4 发布公告
linktitle: 1.13.4
subtitle: 补丁发布
description: Istio 1.13.4 补丁发布。
publishdate: 2022-05-17
release: 1.13.4
aliases:
    - /zh/news/announcing-1.13.4
---

此版本包含错误修复，用以提高系统的稳健性。本发行说明描述了 Istio 1.13.3 和 1.13.4 之间的不同之处。

{{< relnote >}}

## 变化{#changes}

- **修复** 修复了一些 `ServiceEntry` 主机名可能引起不确定的 Envoy 路由的问题。
  ([Issue #38678](https://github.com/istio/istio/issues/38678))

- **修复** 修复了在执行 `istioctl experimental describe pod` 命令时，返回 `failed to fetch mesh config` 报错信息的问题。
  ([Issue #38636](https://github.com/istio/istio/issues/38636))
