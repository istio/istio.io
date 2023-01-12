---
title: Istio 1.13.2 发布公告
linktitle: 1.13.2
subtitle: 补丁发布
description: Istio 1.13.2 补丁发布。
publishdate: 2022-03-09
release: 1.13.2
aliases:
    - /zh/news/announcing-1.13.2
---

此版本修复了我们 3 月 9 日的文章中描述的安全漏洞，[ISTIO-SECURITY-2022-004](/zh/news/security/istio-security-2022-004)。
同时此发布说明描述了 Istio 1.13.1 和 1.13.2 之间的不同之处。

{{< relnote >}}

## 安全更新{#security-update}

- __[CVE-2022-24726](https://github.com/istio/istio/security/advisories/GHSA-8w5h-qr4r-2h6g)__:
  (CVSS Score 7.5, High): Istio 控制平面容易受到请求处理错误的影响，允许未经验证的恶意攻击者发送特制或超大消息，从而堆栈耗尽造成控制平面崩溃。

## 新增{#changes}

- **新增** 新增一个 OpenTelemetry 访问日志程序。
([Issue #36637](https://github.com/istio/istio/issues/36637))

- **新增** 新增支持使用默认 JSON 访问日志格式的 Telemetry API。
  ([Issue #37663](https://github.com/istio/istio/issues/37663))

- **修复** 修复了将网关设置为 TLS 入口网关时， `describe pod` 不显示 VirtualService 信息的问题。
  ([Issue #35301](https://github.com/istio/istio/issues/35301))

- **修复** 修复了当使用 CNI 时，注解 `traffic.sidecar.istio.io/includeOutboundPorts` 不生效的问题。
  ([Issue #37637](https://github.com/istio/istio/pull/37637))

- **修复** 修复了使用 Telemetry API 启用 Stackdriver 指标收集时，在某些场景中错误地启用日志记录的问题。
  ([Issue #37667](https://github.com/istio/istio/issues/37667))

### Envoy CVEs{#envoy-cves}

目前，人们认为 Istio 不会受到 Envoy 中这些 CVE 的攻击。然而还是将它们在下面列举出来，
以让 Istio 的使用者们都能够知道。

- __[CVE-2022-21656](https://github.com/envoyproxy/envoy/security/advisories/GHSA-c9g7-xwcv-pjx2)__
  (CVSS Score 3.1, Low):X.509 证书的错误格式导致 `subjectAltName` 匹配 （和 `nameConstraints`）绕过配置的约束。

- __[CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g)__
  (CVSS Score 3.1, Low): X.509 证书 Extended Key Usage 和 Trust Purposes 绕过审计或监督。
