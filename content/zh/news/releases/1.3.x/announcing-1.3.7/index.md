---
title: Istio 1.3.7 发布公告
linktitle: 1.3.7
description: Istio 1.3.7 补丁发布。
publishdate: 2020-02-04
subtitle: 补丁发布
release: 1.3.7
aliases:
    - /zh/news/announcing-1.3.7
---

此版本发布了包含提高系统稳定性的 bug 修复程序，下面是 Istio 1.3.6 和 Istio 1.3.7 之间的区别。

{{< relnote >}}

## Bug 修复{#bug-fixes}

* **修复** 修复了 Citadel 中的根证书轮换的问题，以将 value 从过期的根证书复用到新的根证书中（[Issue 19644](https://github.com/istio/istio/issues/19644)）。
* **修复** 修复了遥测的问题，以忽略网关转发属性。
* **修复** 修复了 sidecar 注入到 pod 后，出口容器无端口的问题（[Issue 18594](https://github.com/istio/istio/issues/18594)）。
* **添加** 添加了对包含点 `.` 的 pod 名的遥测支持（[Issue 19015](https://github.com/istio/istio/issues/19015)）。
* **添加** 在 Citadel 代理中，添加了对生成 `PKCS＃8` 私钥的支持 ([Issue 19948](https://github.com/istio/istio/issues/19948)).

## 次要改进{#minor-enhancements}

* **Improved** 改进注入模板，以完全指定 `securityContext`，从而允许 `PodSecurityPolicies` 正确地验证注入的 deployment（[Issue 17318](https://github.com/istio/istio/issues/17318)）。
* **添加** 添加了对代理容器设置 `lifecycle` 的支持。
* **添加** 在 Stackdriver Mixer 适配器中，添加了设置网格 UID 的支持（[Issue 17952](https://github.com/istio/istio/issues/17952)）。

## 安全更新{#security-update}

* [**ISTIO-SECURITY-2020-002**](/zh/news/security/istio-security-2020-002) 由于不正确地接受某些请求 header，导致可绕过 Mixer 策略检查。

__[CVE-2020-8843](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-8843)__：在某些情况下，可以绕过特定配置的 Mixer 策略。Istio-proxy 在 ingress 处接受 `x-istio-attributes` header，当 Mixer 策略有选择地应用至 source 时，等价于应用至 ingress，其可能会影响策略决策。Istio 1.3 到 1.3.6 容易受到攻击。
