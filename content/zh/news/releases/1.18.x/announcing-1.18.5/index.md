---
title: 发布 Istio 1.18.5
linktitle: 1.18.5
subtitle: 补丁发布
description: Istio 1.18.5 补丁发布。
publishdate: 2023-10-11
release: 1.18.5
---

该版本修复了于 10 月 11 日发布的 [`ISTIO-SECURITY-2023-004`](/zh/news/security/istio-security-2023-004)
中阐述的安全漏洞。

本发布说明描述了 Istio 1.18.3 和 Istio 1.18.5 之间的不同之处。
请注意，此版本取代了未发布的 1.18.4 版本。
1.18.4 仅在内部发布并已被跳过，因此，其他安全修复内容也被包含在此版本中。

{{< relnote >}}

## 安全更新 {#security-update}

- __[`CVE-2023-44487`](https://nvd.nist.gov/vuln/detail/CVE-2023-44487)__: (CVSS Score 7.5, High)：
  HTTP/2 拒绝服务
- __[`CVE-2023-39325`](https://github.com/golang/go/issues/63417)__: (CVSS Score 7.5, High)：
  HTTP/2 拒绝服务
