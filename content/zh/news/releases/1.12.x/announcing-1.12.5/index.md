---
title: Istio 1.12.5 发布说明
linktitle: 1.12.5
subtitle: Patch Release
description: Istio 1.12.5 补丁发布。
publishdate: 2022-03-09
release: 1.12.5
aliases:
    - /zh/news/announcing-1.12.5
---

此版本修复了 3 月 9 日帖子中所述的安全漏洞 [ISTIO-SECURITY-2022-004](/zh/news/security/istio-security-2022-004)。此发布说明描述了 Istio 1.12.4 和 1.12.5 之间的不同之处。

{{< relnote >}}

## 安全更新 {#security-update}

- __[CVE-2022-24726](https://github.com/istio/istio/security/advisories/GHSA-8w5h-qr4r-2h6g)__:
  (CVSS Score 7.5, High)：由于堆栈耗尽而导致控制平面不能拒绝未经身份验证的服务攻击。

## 变更 {#changes}

- **修复** 修复了 Delta CDS 的一个问题，即更新后一个被移除的服务端口会持续存在。
  ([Pull Request #37454](https://github.com/istio/istio/pull/37454))

- **修复** 修复了 CNI 忽略流量注解的问题。
  ([Issue #37637](https://github.com/istio/istio/issues/37637))

- **修复** 修复了从未更新缓存条目的漏洞。
  ([Pull Request #37578](https://github.com/istio/istio/pull/37578))

### Envoy CVE {#envoy-cves}

目前，人们认为 Istio 不会受到 Envoy 中这些 CVE 的攻击。然而还是将它们在下面列举出来，
以让 Istio 的使用者们都能够知道。

- __[CVE-2022-21656](https://github.com/envoyproxy/envoy/security/advisories/GHSA-c9g7-xwcv-pjx2)__
  (CVSS Score 3.1, Low)：X.509 证书的错误格式导致 `subjectAltName` 匹配 （和 `nameConstraints`）绕过配置的约束。

- __[CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g)__
  (CVSS Score 3.1, Low): X.509 证书 Extended Key Usage 和 Trust Purposes 绕过审计或监督。
