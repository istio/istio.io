---
title: 发布 Istio 1.24.5
linktitle: 1.24.5
subtitle: 补丁发布
description: Istio 1.24.5 补丁发布。
publishdate: 2025-04-14
release: 1.24.5
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.24.4 和 Istio 1.24.5 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 `istio-cni` 可能阻止其自身升级的极端情况。
  添加了回退日志（以防代理程序关闭）到固定大小的节点本地日志文件。
  ([Issue #55215](https://github.com/istio/istio/issues/55215))

- **修复** 修复了当 `ServiceEntry` 使用 DNS 解析配置 `workloadSelector` 时，
  验证 Webhook 错误地报告警告的问题。
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

- **修复** 修复了 gRPC 流服务导致代理内存增加的问题。

- **修复** 修复了由于缓存驱逐错误导致对 `ExternalName`
  服务的更改有时会被跳过的问题。

- **修复** 修复了 SDS `ROOTCA` 资源仅包含单个根证书的回归问题，
  即使控制平面配置了 1.24.4 中引入的主动根证书和被动根证书。
  ([Issue #55793](https://github.com/istio/istio/issues/55793))
