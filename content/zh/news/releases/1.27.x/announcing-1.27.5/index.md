---
title: 发布 Istio 1.27.5
linktitle: 1.27.5
subtitle: 补丁发布
description: Istio 1.27.5 补丁发布。
publishdate: 2025-12-22
release: 1.27.5
aliases:
    - /zh/news/announcing-1.27.5
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.27.4 和 Istio 1.27.5 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

- [CVE-2025-62408](https://github.com/envoyproxy/envoy/security/advisories/GHSA-fg9g-pvc4-776f)
  (CVSS score 5.3, Moderate)：释放后使用漏洞可能导致 Envoy 因 DNS 故障或被入侵而崩溃。
  这是 c-ares 库中的一个堆释放后使用漏洞，攻击者可以通过控制本地
  DNS 基础设施来利用此漏洞对 Envoy 发起拒绝服务 (DoS) 攻击。

## Changes

- **修复** 修复了无头服务的 DNS 名称表创建问题，其中 Pod 条目没有考虑到 Pod 可能有多个 IP 地址。
  ([Issue #58397](https://github.com/istio/istio/issues/58397))
