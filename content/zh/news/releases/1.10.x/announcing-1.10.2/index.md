---
title: 发布 1.10.2 版本
linktitle: 1.10.2
subtitle: 补丁发布
description: Istio 1.10.2 补丁发布。
publishdate: 2021-06-24
release: 1.10.2
aliases:
    - /zh/news/announcing-1.10.2
---

这个版本修复了我们 6 月 24 日的文章 [ISTIO-SECURITY-2021-007](/zh/news/security/istio-security-2021-007) 中描述的安全漏洞，以及一些小错误修复，
从而提高了系统的健壮性。这个版本说明描述了 Istio 1.10.1 和 Istio 1.10.2 之间的区别。

{{< relnote >}}

## 安全更新{#security-update}

- __[CVE-2021-34824](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2021-34824)__:
Istio 包含一个远程可利用的漏洞，其中 `Gateway` 和 `DestinationRule` `credentialName` 字段中指定的凭据可以从不同的命名空间中访问。更多的细节请查看 [ISTIO-SECURITY-2021-007 公报](/zh/news/security/istio-security-2021-007)。
    - __CVSS Score__: 9.1 [CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:L](https://www.first.org/cvss/calculator/3.1#CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:L)

## 改变{#changes}

- **修复** 修复了当使用 `traffic.sidecar.istio.io/includeOutboundPorts` 注释时，出现 IPv6 iptables 规则错误的问题。 ([Issue #30868](https://github.com/istio/istio/issues/30868))

- **修复** 修复了当一个 secret 文件被删除又恢复后，没有被监控发现的错误。 ([Issue #33293](https://github.com/istio/istio/issues/33293))

- **修复** 修复了一个导致 Envoy Filters 合并 `transport_socket` 字段和自定义传输套接字名称被忽略的问题。
