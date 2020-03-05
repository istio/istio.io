---
title: Istio 1.4.4 发布公告
linktitle: 1.4.4
subtitle: 补丁发布
description: Istio 1.4.4 补丁发布。
publishdate: 2020-02-11
release: 1.4.4
aliases:
    - /zh/news/announcing-1.4.4
---

此版本包含一些错误修复程序，以改善健壮性和用户体验，并修复了[我们在 2020 年 2 月 11 日新闻](/zh/news/security/istio-security-2020-001)中描述的安全漏洞。[我们在 2020 年 2 月 11 日新闻](/zh/news/security/istio-security-2020-001) 中描述的安全漏洞的修复程序。此发行说明描述了 Istio 1.4.3 和 Istio 1.3.4 之间的区别。

{{< relnote >}}

## 安全更新{#security-update}

- **ISTIO-SECURITY-2020-001** 在 `AuthenticationPolicy` 中发现了错误的输入验证。

__[CVE-2020-8595](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8595)__：Istio 的[认证策略](/zh/docs/reference/config/security/istio.authentication.v1alpha1/#Policy)精确路径匹配逻辑中的一个 bug，允许在没有效的 JWT 令牌、未经授权的情况下访问资源。

## Bug 修复{#bug-fixes}

- **修复** Debian `iptables` 脚本的包（[Issue 19615](https://github.com/istio/istio/issues/19615)）。
- **修复** 当多次使用同一端口时 Pilot 会生成错误的 Envoy 配置的问题（[Issue 19935](https://github.com/istio/istio/issues/19935)）。
- **修复** 运行多个 Pilot 实例可能导致崩溃的问题（[Issue 20047](https://github.com/istio/istio/issues/20047)）。
- **修复** 将部署规模收缩为 0 时，一个潜在的从 Pilot 到 Envoy 配置推送洪流的问题（[Issue 17957](https://github.com/istio/istio/issues/17957)）。
- **修复** 当 pod 名称中包含点 `.` 时，Mixer 无法从 request/response 中获取正确信息的问题（[Issue 20028](https://github.com/istio/istio/issues/20028)）。
- **修复** Pilot 有时候不能正确的将 pod 配置发送至 Envoy 的问题（[Issue 19025](https://github.com/istio/istio/issues/19025)）。
- **修复** 启用了 SDS 的 Sidecar 注入器，会覆盖 pod 的 `securityContext` 部分，而不是仅对其进行修补的问题（[Issue 20409](https://github.com/istio/istio/issues/20409)）。

## 改进{#improvements}

- **改进** 与 Google CA 有了更好的兼容性。（Issues [20530](https://github.com/istio/istio/issues/20530), [20560](https://github.com/istio/istio/issues/20560)）。
- **改进** 当没有正确配置使用 JWT 的策略时，添加了分析器错误消息（Issues [20884](https://github.com/istio/istio/issues/20884), [20767](https://github.com/istio/istio/issues/20767)）。
