---
title: 发布 Istio 1.23.2
linktitle: 1.23.2
subtitle: 补丁发布
description: Istio 1.23.2 补丁发布。
publishdate: 2024-09-19
release: 1.23.2
---

本次发布实现了 9 月 19 日公布的安全更新 [ISTIO-SECURITY-2024-006](/zh/news/security/istio-security-2024-006)
并修复了一些错误，提高了稳健性。
本发布说明描述了 Istio 1.23.1 和 Istio 1.23.2 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 Sidecar 上的 `PILOT_SIDECAR_USE_REMOTE_ADDRESS` 功能，
  支持将内部地址设置为网格网络而不是本地主机，以防止在启用
  `envoy.reloadable_features.explicit_internal_address_config` 时进行标头清理。
