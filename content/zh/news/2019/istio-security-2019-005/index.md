---
title: 安全更新 - ISTIO-SECURITY-2019-005
description: 安全漏洞披露 CVE-2019-15226。
publishdate: 2019-10-08
attribution: Istio 团队
---

今天，我们发布了三个新的 Istio 版本: 1.1.16、1.2.7 和 1.3.2。 这些新的 Istio 版本解决了一些漏洞，这些漏洞可用于使用 Istio 发起针对服务的拒绝服务（DoS）攻击。

__ISTIO-SECURITY-2019-005__: Envoy 和后面的 Istio 容易受到以下 DoS 攻击：
* __[CVE-2019-15226](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-15226)__: 收到每个传入的请求后, Envoy 将遍历请求标头，以验证请求头的总大小保持在最大限制以下。远程攻击者可能会制作一个请求，该请求的 header 的大小不会超过最大限制，但包含成千上万个小的 header ，来消耗 CPU 并导致拒绝服务攻击。

## 受影响的 Istio 版本{#affected-istio-releases}

以下 Istio 版本容易受到攻击：

* 1.1, 1.1.1, 1.1.2, 1.1.3, 1.1.4, 1.1.5, 1.1.6, 1.1.7, 1.1.8, 1.1.9, 1.1.10, 1.1.11, 1.1.12, 1.1.13, 1.1.14, 1.1.15
* 1.2, 1.2.1, 1.2.2, 1.2.3, 1.2.4, 1.2.5, 1.2.6
* 1.3, 1.3.1

## 影响评测{#impact-score}

CVSS 总体得分: 7.5 [CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator?vector=CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H)

## 漏洞影响和检测{#vulnerability-impact-and-detection}

Istio 网关和 sidecars 都容易受到此问题的影响。 如果您正在运行上面列出的版本之一，则您的群集很容易受到攻击。

## 迁移{#mitigation}

* 对于 Istio 1.1.x 部署: 更新所有控制平面组件 (Pilot, Mixer, Citadel, and Galley) 然后 [更新数据平面](/zh/docs/setup/upgrade/cni-helm-upgrade/#sidecar-upgrade) 的版本不低于 [Istio 1.1.16](/zh/news/releases/1.1.x/announcing-1.1.16)。
* 对于 Istio 1.2.x 部署: 更新所有控制平面组件 (Pilot, Mixer, Citadel, and Galley) 然后 [更新数据平面](/zh/docs/setup/upgrade/cni-helm-upgrade/#sidecar-upgrade) 的版本不低于 [Istio 1.2.7](/zh/releases/1.2.x/announcing-1.2.7)。
* 对于 Istio 1.3.x 部署: 更新所有控制平面组件 (Pilot, Mixer, Citadel, and Galley) 然后 [更新数据平面](/zh/docs/setup/upgrade/cni-helm-upgrade/#sidecar-upgrade) 的版本不低于 [Istio 1.3.2](/news/releases/1.3.x/announcing-1.3.2)。

我们想提醒我们的社区关注 [漏洞报告流程](/zh/about/security-vulnerabilities/) 报告可能导致安全漏洞的任何错误。


