---
title: Istio 1.12.8 发布说明
linktitle: 1.12.8
subtitle: Patch Release
description: Istio 1.12.8 补丁发布。
publishdate: 2022-06-09
release: 1.12.8
aliases:
    - /zh/news/announcing-1.12.8
---

此版本修复了我们在 6 月 9 日的文章[ISTIO-SECURITY-2022-005](/zh/news/security/istio-security-2022-005)中描述的安全漏洞。此发布说明并描述了 Istio 1.12.7 和 1.12.8 之间的不同之处。

{{< relnote >}}

## 变化{#changes}

- **修复** 修复了 `PILOT_ENABLE_METADATA_EXCHANGE` 设置为 `false` 时不会移除 TCP MX 过滤器的问题。
  ([Issue #38520](https://github.com/istio/istio/issues/38520))

- **修复** 修复了在一个集群中删除多集群服务后，集群 VIP 不正确及 IP 地址过期的问题。这将导致 DNS 代理返回陈旧的 IP 以进行服务解析，从而导致流量中断的问题。
  ([Issue #39039](https://github.com/istio/istio/issues/39039))

- **修复** 修复了当 `WorkloadEntry.Annotations` 为 `nil` 时会导致 istiod 异常退出的问题。
  ([Issue #39201](https://github.com/istio/istio/issues/39201))
