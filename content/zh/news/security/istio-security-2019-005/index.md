---
title: ISTIO-SECURITY-2019-005
subtitle: 安全公告
description: 由于客户端请求中存在大量 HTTP header 而导致的拒绝服务。
cves: [CVE-2019-15226]
cvss: "7.5"
vector: "CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.1 to 1.1.15", "1.2 to 1.2.6", "1.3 to 1.3.1"]
publishdate: 2019-10-08
keywords: [CVE]
skip_seealso: true
aliases:
    - /zh/news/2019/istio-security-2019-005
---

{{< security_bulletin >}}

## 内容{#context}

Envoy 和 Istio 容易受到以下 DoS 攻击。收到每个传入的请求后,Envoy 将遍历请求标头，以保证请求头的总大小保持在最大限制以下。远程攻击者可能会制作一个请求，该请求的 header 的大小不会超过最大限制，但包含成千上万个小的 header，来消耗 CPU 并导致拒绝服务攻击。

## 影响范围{#impact-and-detection}

Istio gateway 和 sidecar 都容易受到此问题的影响。如果您运行的 Istio 是受影响的发行版本，那么您的集群容易受到攻击。

## 防范{#mitigation}

* 对于 Istio 1.1.x 部署: 更新所有控制平面组件(Pilot、Mixer、Citadel、和 Galley)然后[更新数据平面](/zh/docs/setup/upgrade/cni-helm-upgrade/#sidecar-upgrade)的版本不低于[Istio 1.1.16](/zh/news/releases/1.1.x/announcing-1.1.16)。
* 对于 Istio 1.2.x 部署: 更新所有控制平面组件(Pilot、Mixer、Citadel、和 Galley)然后[更新数据平面](/zh/docs/setup/upgrade/cni-helm-upgrade/#sidecar-upgrade)的版本不低于[Istio 1.2.7](/zh/news/releases/1.2.x/announcing-1.2.7)。
* 对于 Istio 1.3.x 部署: 更新所有控制平面组件(Pilot、Mixer、Citadel、和 Galley)然后[更新数据平面](/zh/docs/setup/upgrade/cni-helm-upgrade/#sidecar-upgrade)的版本不低于[Istio 1.3.2](/zh/news/releases/1.3.x/announcing-1.3.2)。

{{< boilerplate "security-vulnerability" >}}
