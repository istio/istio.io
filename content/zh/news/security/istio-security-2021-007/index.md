---
title: ISTIO-SECURITY-2021-007
subtitle: 安全公告
description: Istio 包含一个可远程利用的漏洞，可以从不同的命名空间访问 Gateway 和 DestinationRule credentialName 字段中指定的身份凭据。
cves: [CVE-2021-34824]
cvss: "9.1"
vector: "AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:L/A:L"
releases: ["All 1.8 patch releases", "1.9.0 to 1.9.5", "1.10.0 to 1.10.1"]
publishdate: 2021-06-24
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## 问题{#issue}

Istio [`Gateway`](/zh/docs/tasks/traffic-management/ingress/secure-ingress/) 和 [`DestinationRule`](/zh/docs/reference/config/networking/destination-rule/) 可以通过 `credentialName` 配置从 Kubernetes 密钥中加载私钥和证书。
对于 Istio 1.8 及更高版本，密钥通过 XDS API 从 Istiod 传送到网关或工作负载。

在上述方法中，网关或工作负载部署应该只能访问存储在其命名空间内的 Kubernetes 密钥中的凭证（TLS 证书和私钥）。
但是，Istiod 中的一个错误允许授权客户端访问和检索缓存在 Istiod 中的任何 TLS 证书和私钥。

## 对我的影响？{#am-i-impacted}

如果您的集群符合以下所有条件，您的集群就会受到影响：

* 集群使用的 Istio 版本为 Istio 1.10.0 到 1.10.1、Istio 1.9.0 到 1.9.5 或 Istio 1.8.x。
* 在集群中定义了带有指定 `credentialName` 字段的 [`Gateways`](/zh/docs/tasks/traffic-management/ingress/secure-ingress/) 或 [`DestinationRules`](/zh/docs/reference/config/networking/destination-rule/)。
* 集群没有指定 Istiod 的 `PILOT ENABLE XDS CACHE=false` 标签。

{{< warning >}}
如果您使用的是 Istio 1.8，请联系您的 Istio 提供商以检查更新。否则，请升级到 Istio 1.9 或 1.10 的最新补丁版本。
{{< /warning >}}

## 防范{#mitigation}

将您的集群更新到支持的最新版本：

* Istio 1.9.6 或更高版本，如果使用 1.9.x
* Istio 1.10.2 或更高版本，如果使用 1.10.x
* 您的云提供商指定的补丁版本

如果升级不可行，可以通过禁用 Istiod 缓存来缓解此漏洞。
通过设置 Istiod 环境变量 `PILOT ENABLE XDS CACHE=false` 禁用缓存。
系统和 Istiod 的性能可能会受到影响，因为这禁用了 XDS 缓存。

## 鸣谢{#credit}

我们要感谢 `Sopra Banking Software`（`Nishant Virmani`, `Stephane Mercier` 和 `Antonin Nycz`）以及 John Howard（谷歌）报告了这个问题。
