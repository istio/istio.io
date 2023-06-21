---
title: ISTIO-SECURITY-2022-002
subtitle: 安全公告
description: Kubernetes Gateway API 中的特权提升。
cves: [CVE-2022-21701]
cvss: "4.7"
vector: "AV:N/AC:L/PR:H/UI:N/S:U/C:L/I:L/A:L"
releases: ["1.12.0 to 1.12.1"]
publishdate: 2022-01-18
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## CVE

### CVE-2022-21701

Istio 1.12.0 和 1.12.1 版本容易受到提权攻击。
对 `gateways.gateway.networking.k8s.io` 对象具有 `CREATE`
权限的用户可以提升权限以创建他们可能无权访问的其他资源，例如 `Pod`。

## 我受到影响了吗？{#am-i-impacted?}

此漏洞仅影响 Alpha 级别的功能，即 [Kubernetes Gateway API](/zh/docs/tasks/traffic-management/ingress/gateway-api/)。
这与不存在漏洞的 Istio `Gateway` 类型（`gateways.networking.istio.io`）不同。

如果出现以下情况，您的集群可能会受到影响：

* 您已经安装了 Kubernetes Gateway CRD。可以通过
  `kubectl get crd gateways.gateway.networking.k8s.io` 进行检测。
* 您尚未在 Istiod 中设置
  `PILOT_ENABLE_GATEWAY_API_DEPLOYMENT_CONTROLLER=false` 环境变量（默认为 `true`）。
* 不受信任的用户对 `gateways.gateway.networking.k8s.io`
  对象具有 `CREATE` 权限。

## 解决方法 {#workarounds}

如果您无法进行升级，以下任何一项操作都可以防止此漏洞：

* 删除 `gateways.gateway.networking.k8s.io` `CustomResourceDefinition`。
* 在 Istiod 中设置
  `PILOT_ENABLE_GATEWAY_API_DEPLOYMENT_CONTROLLER=false` 环境变量。
* 删除不受信任的用户对 `gateways.gateway.networking.k8s.io`
  对象的 `CREATE` 权限。

## 赞扬 {#credit}

我们要感谢 Anthony Weems。
