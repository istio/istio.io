---
title: 发布 Istio 1.15.7
linktitle: 1.15.7
subtitle: 补丁发布
description: Istio 1.15.7 补丁发布。
publishdate: 2023-04-04T07:00:00-06:00
release: 1.15.7
---

此版本修复了我们 4 月 4 日发布的帖子
[ISTIO-SECURITY-2023-001](/zh/news/security/istio-security-2023-001)
中描述的安全漏洞。本发布说明描述了
Istio 1.15.6 和 Istio 1.15.7 之间的不同之处。

{{< relnote >}}

## 安全更新{#security-updates}

- __[CVE-2023-27487](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5375-pq35-hf2g)__:
  (CVSS Score 8.2, High)：客户端可能会伪造 `x-envoy-original-path` 头信息。

- __[CVE-2023-27488](https://github.com/envoyproxy/envoy/security/advisories/GHSA-9g5w-hqr3-w2ph)__:
  (CVSS Score 5.4, Moderate)：当收到具有非 UTF8 值的 HTTP 头信息时，
  gRPC 客户端会生成无效的 protobuf。

- __[CVE-2023-27491](https://github.com/envoyproxy/envoy/security/advisories/GHSA-5jmv-cw9p-f9rp)__:
  (CVSS Score 5.4, Moderate)：Envoy 将转发无效的 HTTP/2 和 HTTP/3 下游头信息。

- __[CVE-2023-27492](https://github.com/envoyproxy/envoy/security/advisories/GHSA-wpc2-2jp6-ppg2)__:
  (CVSS Score 4.8, Moderate)：在 Lua 过滤器中处理大请求体时导致崩溃。

- __[CVE-2023-27493](https://github.com/envoyproxy/envoy/security/advisories/GHSA-w5w5-487h-qv8q)__:
  (CVSS Score 8.1, High)：Envoy 不会转义 HTTP 头信息的值。

- __[CVE-2023-27496](https://github.com/envoyproxy/envoy/security/advisories/GHSA-j79q-2g66-2xv5)__:
  (CVSS Score 6.5, Moderate)：在 OAuth 过滤器中收到没有 state
  参数的重定向 URL 时导致崩溃。

## 变更{#changes}

- **修复** 修复了无法使用 proxy-config 更改 `PrivateKeyProvider` 的问题。
  ([Issue #41760](https://github.com/istio/istio/issues/41760))

- **修复** 修复了当 `EnvoyFilter.ListenerMatch.FilterChainMatch`
  部分缺少 'filter' 可选字段时 `istioctl analyze` 会抛出 SIGSEGV 的问题。
  ([Issue #42831](https://github.com/istio/istio/issues/42831))

- **修复** 修复了 `Cluster.ConnectTimeout`
  类型的 `EnvoyFilter` 影响不相关 `Clusters` 的问题。
  ([Issue #43435](https://github.com/istio/istio/issues/43435))
