---
title: 发布 Istio 1.6.2
linktitle: 1.6.2
subtitle: 补丁更新
description: Istio 1.6.2 安全更新.
publishdate: 2020-06-11
release: 1.6.2
aliases:
    - /news/announcing-1.6.2
---

此版本解决了[我们2020年6月11日的安全公告](/news/security/istio-security-2020-006)中描述的安全漏洞。

本版本说明介绍了 Istio 1.6.2 和 Istio 1.6.1 之间的差异。

{{< relnote >}}

## 安全更新

- **ISTIO-SECURITY-2020-006**：处理带有太多参数的 HTTP/2 SETTINGS 帧时，可能会导致 CPU 使用过高，从而导致拒绝服务。

__[CVE-2020-11080](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-11080)__: 通过发送特制报文，攻击者可以使 CPU 到达100%。该包可以发送到入口网关或 sidecar。