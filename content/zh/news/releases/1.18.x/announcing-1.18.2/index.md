---
title: 发布 Istio 1.18.2
linktitle: 1.18.2
subtitle: 补丁发布
description: Istio 1.18.2 补丁发布。
publishdate: 2023-07-25
release: 1.18.2
---

该版本修复了于 7 月 25 日发布的 [ISTIO-SECURITY-2023-003](/zh/news/security/istio-security-2023-003)
中阐述的安全漏洞。

本发布说明描述了 Istio 1.18.1 和 Istio 1.18.2 之间的不同之处。

{{< relnote >}}

## 安全更新 {#security-update}

- __[CVE-2023-35941](https://github.com/envoyproxy/envoy/security/advisories/GHSA-7mhv-gr67-hq55)__:
  (CVSS Score 8.6, High)：OAuth2 凭证滥用永久有效性。
- __[CVE-2023-35942](https://github.com/envoyproxy/envoy/security/advisories/GHSA-69vr-g55c-v2v4)__:
  (CVSS Score 6.5, Moderate)：由于侦听器耗尽而导致 gRPC 访问日志崩溃。
- __[CVE-2023-35943](https://github.com/envoyproxy/envoy/security/advisories/GHSA-mc6h-6j9x-v3gq)__:
  (CVSS Score 6.3, Moderate)：删除原始头信息时，CORS 过滤器发生段错误。
- __[CVE-2023-35944](https://github.com/envoyproxy/envoy/security/advisories/GHSA-pvgm-7jpg-pw5g)__:
  (CVSS Score 8.2, High)：Envoy 中大小写混合情况的 HTTP 请求和响应处理不正确。

## 变更 {#changes}

- **新增** 添加了对名为 `USE_EXTERNAL_WORKLOAD_SDS` 标志的支持。
  当设置为 true 时，它将需要一个外部 SDS 工作负载套接字，如果找不到工作负载
  SDS 套接字，则将阻止 istio-proxy 启动。
  ([Issue #45534](https://github.com/istio/istio/issues/45534))
