---
title: Istio 1.4.9 发布公告
linktitle: 1.4.9
subtitle: 补丁发布
description: Istio 1.4.9 补丁发布。
publishdate: 2020-05-12
release: 1.4.9
aliases:
    - /zh/news/announcing-1.4.9
---

此版本包含一些错误修复，以改善健壮性和用户体验，并修复了[我们在 2020 年 5 月 12 日新闻报道](/zh/news/security/istio-security-2020-005)中描述的安全漏洞。这个版本说明描述了 Istio 1.4.9 和 Istio 1.4.8 之间的区别。

{{< relnote >}}

## 安全更新{#security-update}

- **ISTIO-SECURITY-2020-005** 启用 Telemetry V2 时拒绝服务。

__[CVE-2020-10739](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-10739)__: 通过发送一个特制的数据包，攻击者可以触发一个 Null Pointer Exception，从而导致 Denial of Service。而且这可以发送到入口网关或边车。

## Bug 修复{#bug-fixes}

- **修复** 修复了 Helm 安装程序安装 Kiali 使用动态生成的签名密钥的问题。
- **修复** 修复了 Citadel 自动忽略不属于网格的名称空间的问题。
- **修复** 修复了 Istio operator 安装程序在安装超时时打印所以未准备好的资源的名称问题。
