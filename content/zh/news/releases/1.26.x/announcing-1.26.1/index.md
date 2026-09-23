---
title: 发布 Istio 1.26.1
linktitle: 1.26.1
subtitle: 补丁发布
description: Istio 1.26.1 补丁发布。
publishdate: 2025-05-29
release: 1.26.1
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.26.0 和 Istio 1.26.1 之间的区别。

## 流量治理 {#traffic-management}

- **更新** 更新了 Gateway API 版本，从 `1.3.0-rc.1` 更新至 `1.3.0`。
  ([Issue #56310](https://github.com/istio/istio/issues/56310))

- **修复** 修复了 Istio 1.26.0 中的一个回归问题，该问题在处理 Gateway API 主机名时导致 istiod 出现混乱。
  ([Issue #56300](https://github.com/istio/istio/issues/56300))

## 安全性 {#security}

- **修复** 修复了 `pluginca` 功能中的一个问题：如果提供的 `cacerts` 软件包不完整，
  `istiod` 会静默回退到自签名 CA。现在，系统可以正确验证所有必需的 CA 文件是否存在，
  如果软件包不完整，则会失败并显示错误。

## 安装 {#installation}

- **修复** 修复了当 `IstioOperator` 配置包含多个网关时，
  `istioctl manifest translate` 中出现的混乱情况。
  ([Issue #56223](https://github.com/istio/istio/issues/56223))

## istioctl

- **修复** 修复了即使将 `PILOT_ENABLE_IP_AUTOALLOCATE` 设置为 `true`，
  `istioctl analyze` 仍会引发错误 `IST0134` 的情况。
  ([Issue #56083](https://github.com/istio/istio/issues/56083))
