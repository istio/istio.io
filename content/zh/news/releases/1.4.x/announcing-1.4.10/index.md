---
title: Istio 1.4.10 发布公告
linktitle: 1.4.10
subtitle: 补丁发布
description: Istio 1.4.4 安全发布。
publishdate: 2020-06-22
release: 1.4.10
aliases:
    - /zh/news/announcing-1.4.10
---

这是 Istio 1.4 的最终版本。

此版本修复了[我们 2020 年 6 月 11 日的新闻](/zh/news/security/istio-security-2020-006/index.md) 中描述的安全漏洞和和其它有助于改善稳定性的修复。

此发布说明描述了 Istio 1.4.9 和 Istio 1.4.10 之间的不同之处。

{{< relnote >}}

## 安全更新

- **ISTIO-SECURITY-2020-006** 处理了当有过多参数的 HTTP/2 SETTINGS 帧时 CPU 的使用率过高，可能导致服务禁止的问题。

__[CVE-2020-11080](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-11080)__：
通过发送特制数据包，攻击者可能会导致 CPU 峰值激增100％。 这可以发送到 Ingress 网关或 Sidecar。

## Bug 修复{#bug-fixes}

- **修复** 修复了在 Google Kubernetes Engine 上运行时启用 `COS_CONTAINERD` 和 Istio CNI 时 `istio-cni-node` 崩溃的问题。
([Issue 23643](https://github.com/istio/istio/issues/23643))
- **修复** 修复了当 DNS 不可访问时，Istio CNI 导致 pod 初始化时花费 30-40 秒的延迟的问题。
([Issue 23770](https://github.com/istio/istio/issues/23770))

## 安全修复 Bookinfo 示例应用程序{#Bookinfo sample application security fixes}

我们更新了 Bookinfo 示例应用程序中使用的 Node.js 和 jQuery 的版本。 Node.js 已经从 12.9 版本升级到 12.18 版本。jQuery 已经从 2.1.4 版本升级到 3.5.0。评分最高的漏洞已修复：*HTTP 请求夹带使用 Transfer-Encoding 头   (Critical) (CVE-2019-15605)*
