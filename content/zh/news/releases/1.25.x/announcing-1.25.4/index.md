---
title: 发布 Istio 1.25.4
linktitle: 1.25.4
subtitle: 补丁发布
description: Istio 1.25.4 补丁发布。
publishdate: 2025-08-08
release: 1.25.4
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.25.3 和 Istio 1.25.4 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 Istio 从 1.24 升级到 1.25 时，由于预先存在的 iptables 规则而导致服务中断的问题。
  iptables 二进制检测逻辑已得到改进，以验证是否存在一定程度的基线内核支持，并在 `tie` 情况下优先使用 `nft`。

- **修复** 修复了即使将 `PILOT_ENABLE_IP_AUTOALLOCATE` 设置为 `true`，
  `istioctl analyze` 仍会引发 IST0134 的误报问题。
  ([Issue #56083](https://github.com/istio/istio/issues/56083))

- **修复** 修复了当 IstioOperator 配置包含多个网关时，
  `istioctl manifest translation` 中出现的异常。
  ([Issue #56223](https://github.com/istio/istio/issues/56223))

- **修复** 修复了 Ambient 索引以按修订过滤配置。
  ([Issue #56477](https://github.com/istio/istio/issues/56477))

- **修复** 修复了启用 TPROXY 模式时 OpenShift 上 `istio-proxy`
  和 `istio-validation` 容器的 UID 和 GID 分配不正确的问题。

- **修复** 修复了逻辑，以便在使用 `discoverySelectors`
  时正确忽略系统命名空间上的 `topology.istio.io/network` 标签。
  ([Issue #56687](https://github.com/istio/istio/issues/56687))

- **修复** 修复了当引用的服务晚于 Telemetry 资源创建时访问日志未更新的问题。
  ([Issue #56825](https://github.com/istio/istio/issues/56825))
