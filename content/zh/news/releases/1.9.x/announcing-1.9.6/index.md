---
title: 发布 Istio 1.9.6 版本
linktitle: 1.9.6
subtitle: 补丁发布
description: Istio 1.9.6 补丁发布。
publishdate: 2021-06-24
release: 1.9.6
aliases:
    - /zh/news/announcing-1.9.6
---

此版本修复了在 6 月 24 日发布的帖子 [ISTIO-SECURITY-2021-007](/zh/news/security/istio-security-2021-007) 中描述的安全问题以及一些小漏洞，提高了稳健性。本次发布说明主要描述 Istio 1.9.5 和 1.9.6 版本之间的区别。

{{< relnote >}}

## 安全更新{#security-update}

- __[CVE-2021-34824](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-34824)__：
Istio 包含一个可远程利用的漏洞，在 `Gateway` 和 `DestinationRule` `credentialName` 字段中指定的凭证可以从不同的命名空间访问。有关更多详细信息，请参阅 [ISTIO-SECURITY-2021-007 bulletin](/zh/news/security/istio-security-2021-007)。
    - __CVSS Score__： 9.1 [CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:L](https://www.first.org/cvss/calculator/3.1#CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:L)

## 变化{#changes}

- **修复** 当使用 `traffic.sidecar.istio.io/includeOutboundPorts` 注释时，IPv6 的 Iptables 规则不正确的问题。
 ([Issue #30868](https://github.com/istio/istio/issues/30868))

- **修复** 导致合并 `transport_socket` 字段并具有自定义传输套接字名称的 Envoy 过滤器被忽略的问题。
