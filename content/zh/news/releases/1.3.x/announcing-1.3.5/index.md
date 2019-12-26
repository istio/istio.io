---
title: Istio 1.3.5 发布公告
linktitle: 1.3.5
description: Istio 1.3.5 补丁发布。
publishdate: 2019-11-11
subtitle: 补丁发布
release: 1.3.5
aliases:
    - /zh/news/2019/announcing-1.3.5
    - /zh/news/announcing-1.3.5
---

此版本包含[我们在 2019 年 11 月 11 日的新闻中](/zh/news/security/istio-security-2019-006)描述的安全漏洞修复程序以及提高健壮性的程序。此发行说明描述了 Istio 1.3.4 和 Istio 1.3.5 之间的区别。

{{< relnote >}}

## 安全更新{#security-update}

- **ISTIO-SECURITY-2019-006** 在 Envoy 中发现了一个 DoS 漏洞。

__[CVE-2019-18817](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-18817)__：在 Istio 中存在这种情况，如果将 `continue_on_listener_filters_timeout` 选项设置为 True，则可导致 Envoy 陷入死循环。可以利用此漏洞进行 DoS 攻击。如果应用了[我们在 2019 年 11 月 11 日的新闻中](/zh/news/security/istio-security-2019-006)提到的防范措施，则在升级到 Istio 1.3.5 或更高版本后，可以删除该防范措施。

## Bug 修复{#bug-fixes}

- **修复** TCP headless 服务的 Envoy 监听器配置。（[Issue #17748](https://github.com/istio/istio/issues/17748)）
- **修复** 即使将 deployment 缩放到 0 个副本，过时的 endpoint 也会保留的问题。（[Issue #14436](https://github.com/istio/istio/issues/14336)）
- **修复** 生成无效的 Envoy 配置时，Pilot 不会再崩溃。（[Issue 17266](https://github.com/istio/istio/issues/17266)）
- **修复** 没有为与 BlackHole/Passthrough 集群相关的 TCP 指标填充 `destination_service_name` 标签的问题。（[Issue 17271](https://github.com/istio/istio/issues/17271)）
- **修复** 调用遥测过滤器链时遥测不报告 BlackHole/Passthrough 群集指标的问题。集群指标的问题。该问题会在为外部服务配置显示的 `ServiceEntries` 时发生的。
（[Issue 17759](https://github.com/istio/istio/issues/17759)）

## 小的增强{#minor-enhancements}

- **添加** 支持 Citadel 定期检查根证书的剩余寿命并轮换即将到期的根证书。（[Issue 17059](https://github.com/istio/istio/issues/17059)）
- **添加** 为 Pilot 添加布尔型环境变量 `PILOT_BLOCK_HTTP_ON_443`。如果启用，此标志将阻止 HTTP 服务在端口 443 上运行，以防止与外部 HTTP 服务发生冲突。默认情况下禁用此功能。（[Issue 16458](https://github.com/istio/istio/issues/16458)）
