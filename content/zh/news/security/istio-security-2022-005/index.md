---
title: ISTIO-SECURITY-2022-005
subtitle: Security Bulletin
description: 在某些配置中，发送给 Envoy 的格式错误的请求头可能会导致意外的内存访问冲突，从而产生未定义的行为或崩溃。
cves: [CVE-2022-31045, CVE-2022-29225, CVE-2022-29224, CVE-2022-29226, CVE-2022-29228, CVE-2022-29227]
cvss: "7.5"
vector: "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["All releases prior to 1.12.0", "1.12.0 to 1.12.7", "1.13.0 to 1.13.4", "1.14.0"]
publishdate: 2022-06-09
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE{#cve}

### CVE-2022-31045{#cve-2022-31045}

- [CVE-2022-31045](https://github.com/istio/istio/security/advisories/GHSA-xwx5-5c9g-x68x) (CVSS score 5.9, Medium): 内存访问冲突：在某些配置中，发送给 Envoy 的格式错误的请求头可能导致意外的内存访问错误，从而产生未定义的行为或崩溃。

### Envoy CVEs{#envoy-cves}

这些 Envoy CVE 不会直接影响 Istio 功能，但我们仍会将它们包含在 1.12.8、1.13.5 和 1.14.1 的补丁版本中。

- [CVE-2022-29225](https://github.com/envoyproxy/envoy/security/advisories/GHSA-75hv-2jjj-89hh) (CVSS score 7.5, High): 解压器在覆盖 `decode/encodeBody` 中的主体之前将解压后的数据累积到中间缓冲区中。这可能允许攻击者通过发送一个小的高度压缩的有效载荷来压缩炸弹解压缩器。

- [CVE-2022-29224](https://github.com/envoyproxy/envoy/security/advisories/GHSA-m4j9-86g3-8f49) (CVSS score 5.9, Medium): 使用 `GrpcHealthCheckerImpl` 进行健康检查时，攻击者控制的上游服务器可以通过空指针取消引用使 Envoy 崩溃。

- [CVE-2022-29226](https://github.com/envoyproxy/envoy/security/advisories/GHSA-h45c-2f94-prxh) (CVSS score 10.0, Critical): OAuth 过滤器的实现不包括验证访问令牌的机制，因此当 HMAC 签名的 cookie 丢失时，应该触发完整的身份验证流程。然而，当前实现假设访问令牌总是经过验证，从而允许在存在附加到请求的任何访问令牌的情况下进行访问。

- [CVE-2022-29228](https://github.com/envoyproxy/envoy/security/advisories/GHSA-rww6-8h7g-8jf6) (CVSS score 7.5, High): OAuth 过滤器会在发出本地响应后尝试调用 `decodeHeaders()` 中剩余的 `continueDecoding()`，这会在较新版本中触发 ASSERT() 并破坏较早版本中的内存。

- [CVE-2022-29227](https://github.com/envoyproxy/envoy/security/advisories/GHSA-rm2p-qvf6-pvr6) (CVSS score 7.5, High): 如果重定向提示 Envoy-generated 的本地回复，则 Envoy 内部重定向带有正文或关键片段的请求是不安全的，攻击者利用该漏洞可以使服务崩溃。

## 我受到影响了吗？{#am-i-impacted?}

如果您有一个暴露于外部流量的 Istio 入口网关，那么您面临的风险最大。

## 致谢{#credit}

我们要感谢 Red Hat 的 Otto van der Schaaf 的报告。
