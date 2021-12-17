---
title: Istio 1.4.10 发布公告
linktitle: 1.4.10
subtitle: 补丁发布
description: Istio 1.4.10 安全版本。
publishdate: 2020-06-22
release: 1.4.10
aliases:
    - /zh/news/announcing-1.4.10
---

这是 Istio 1.4 的最终版本。

该版本修复了[我们在 2020 年 6 月 11 日新闻报道](/zh/news/security/istio-security-2020-006)中描述的安全漏洞
以及 bug 的修复以提高健壮性和用户体验。

这个版本说明描述了 Istio 1.4.9 和 Istio 1.4.10 之间的区别。

{{< relnote >}}

## 安全更新{#security-update}

- **ISTIO-SECURITY-2020-006** 当处理带有大量参数的 HTTP/2 SETTINGS 帧时，会引发 CPU 占用过多，导致服务被拒绝。

__[CVE-2020-11080](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-11080)__: 通过发送一个特制的数据包，攻击者可以使 CPU 达到 100% 的峰值。并且这可以发送到入口网关或边车。

## Bug 修复{#bug-fixes}

- **修复** 修复了在 Google Kubernetes Engine 上运行 `COS_CONTAINERD` 和 Istio CNI 时 `istio-cni-node` 崩溃的问题 ([Issue 23643](https://github.com/istio/istio/issues/23643))。
- **修复** 修复了当 DNS 不通时，Istio CNI 会导致 pod 的初始化在启动时经历 30-40 秒的延迟 ([Issue 23770](https://github.com/istio/istio/issues/23770))。

## Bookinfo 示例应用程序的安全性修复{#bookinfo-sample-application-security-fixes}

我们已经更新了 Bookinfo 示例应用中使用的 Node.js 和 jQuery 的版本。
Node.js 已经从 12.9 的版本升级到 12.18 的版本。jQuery 也从 2.1.4 的版本更新到 3.5.0 版本。最高评级的漏洞修复为：
*HTTP request smuggling using malformed Transfer-Encoding header (Critical) (CVE-2019-15605)*
