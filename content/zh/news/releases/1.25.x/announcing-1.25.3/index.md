---
title: 发布 Istio 1.25.3
linktitle: 1.25.3
subtitle: 补丁发布
description: Istio 1.25.3 补丁发布。
publishdate: 2025-05-13
release: 1.25.3
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.25.2 和 Istio 1.25.3 之间的区别。
{{< relnote >}}

## 安全更新 {#security-updates}

- [CVE-2025-46821](https://nvd.nist.gov/vuln/detail/CVE-2025-46821)
  (CVSS 评分 5.3，中)：绕过 RBAC `uri_template` 权限。

如果您在 `AuthorizationPolicy` 的路径字段中使用 `**`，建议您升级到 Istio 1.24.6。

## 变更 {#changes}

- **移除** 移除了仅在 istiod Helm Chart 中未启用 `istiodRemote`
  时修订标签才有效的限制。现在，只要指定了 `revisionTags`，
  修订标签就可以正常工作，无论 `istiodRemote` 是否启用。
  ([Issue #54743](https://github.com/istio/istio/issues/54743))
