---
title: 发布 Istio 1.7.6 版本
linktitle: 1.7.6
subtitle: 补丁发布
description: Istio 1.7.6 补丁发布。
publishdate: 2020-12-10
release: 1.7.6
aliases:
- /zh/news/announcing-1.7.6
---

这个版本包含了错误修复，以提高稳定性。主要说明 Istio 1.7.5 和 Istio 1.7.6 之间的不同之处。

{{< relnote >}}

## 变动#{changes}

- **修复** 导致遥测 HPA 设置被在线副本覆盖的问题。([Issue #28916](https://github.com/istio/istio/issues/28916))

- **修复** Delegate `VirtualService` 的变化不会触发 xDS 推送的问题。([Issue #29123](https://github.com/istio/istio/issues/29123))

- **修复** 导致大量 "ServiceEntry "占用大量内存的问题。([Issue #25531](https://github.com/istio/istio/issues/25531))
