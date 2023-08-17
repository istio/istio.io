---
title: ISTIO-SECURITY-2021-006
subtitle: 安全公告
description: 当网关配置了 AUTO_PASSTHROUGH 路由配置时，外部客户端可以绕过授权检查访问集群中的意外服务。
cves: [CVE-2021-31921]
cvss: "10"
vector: "AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H"
releases: ["All releases prior to 1.8.6", "1.9.0 to 1.9.4"]
publishdate: 2021-05-11
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## 问题{#issue}

Istio 包含一个远程可利用的漏洞，当网关配置了 `AUTO_PASSTHROUGH` 路由配置时，外部客户端可以绕过授权检查访问集群中的意外服务。

## 对我的影响？{#am-i-impacted}

此漏洞仅影响 `AUTO_PASSTHROUGH` 类型网关的使用，该类型通常仅用于多网络多集群部署。

可以使用以下命令检测集群中所有网关的 TLS 模式：

    {{< text bash >}}
    $ kubectl get gateways.networking.istio.io -A -o "custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,TLS_MODE:.spec.servers[*].tls.mode"
    {{< /text >}}

如果输出显示任何 `AUTO_PASSTHROUGH` 类型的网关，您可能会受到影响。

## 防范{#mitigation}

将您的集群更新到支持的最新版本：

* 如果使用的 Istio 版本为 1.8.x，请升级到 Istio 1.8.6
* 升级到 Istio 1.9.5 或更高版本
* 您的云提供商指定的补丁版本

## 鸣谢{#credit}

我们要感谢 John Howard（谷歌）报告了此问题。
