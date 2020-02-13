---
title: ISTIO-SECURITY-2019-006
subtitle: 安全公告
description: 拒绝服务。
cve: [CVE-2019-18817]
publishdate: 2019-11-07
keywords: [CVE]
skip_seealso: true
aliases:
    - /zh/news/2019/istio-security-2019-006
---

{{< security_bulletin
        cves="CVE-2019-18817"
        cvss="7.5"
        vector="CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H/E:H/RL:O/RC:C"
        releases="1.3 to 1.3.4" >}}

## 内容{#context}

Envoy 以及随后的 Istio 容易受到以下 DoS 攻击。
如果选项 `continue_on_listener_filters_timeout` 设置为 `True`，则可以在 Envoy 中触发无限循环。自从 Istio 1.3 中引入协议检测功能以来，Istio 就是这种情况。
远程攻击者可能会轻易触发该漏洞，从而有效耗尽 Envoy 的 CPU 资源并造成拒绝服务攻击。

## 影响范围{#impact-and-detection}

Istio gateway 和 sidecar 都容易受到此问题的影响。如果您运行的 Istio 是受影响的发行版本，那么您的集群容易受到攻击。

## 防范{#mitigation}

* 解决方法: 通过自定义安装 Istio 可以防止对该漏洞的利用(如[安装选项](/zh/docs/reference/config/installation-options/#pilot-options)中所述)，在使用 Helm 时添加以下选项:

    {{< text plain >}}
    --set pilot.env.PILOT_INBOUND_PROTOCOL_DETECTION_TIMEOUT=0s --set global.proxy.protocolDetectionTimeout=0s
    {{< /text >}}

* 对于 Istio 1.3.x 部署: 更新至[Istio 1.3.5](/zh/news/releases/1.3.x/announcing-1.3.5)或者更新的版本。

{{< boilerplate "security-vulnerability" >}}
