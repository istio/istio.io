---
title: Istio 1.2.4 发布公告
linktitle: 1.2.4
subtitle: 发布补丁
description: Istio 1.2.4 版本发布公告。
publishdate: 2019-08-13
release: 1.2.4
aliases:
    - /zh/about/notes/1.2.4
    - /zh/blog/2019/announcing-1.2.4
    - /zh/news/2019/announcing-1.2.4
    - /zh/news/announcing-1.2.4
---

我们很高兴地宣布 Istio 1.2.4 现在是可用的，详情请查看如下更改。

{{< relnote >}}

## 安全更新{#security-update}

此版本包含了在 [ISTIO-SECURITY-2019-003](/zh/news/security/istio-security-2019-003/)] 和 [ISTIO-SECURITY-2019-004](/zh/news/security/istio-security-2019-004/) 中所阐述的安全漏洞程序的修复。特别是：

__ISTIO-SECURITY-2019-003__: 一位 Envoy 用户公开报告了一个正则表达式的匹配问题 (c.f. [Envoy Issue 7728](https://github.com/envoyproxy/envoy/issues/7728))，该问题可使 Envoy 出现非常严重的 URI 崩溃。
  * __[CVE-2019-14993](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-14993)__: 经调查，Istio 小组发现，当用户正在使用 `Istio Api` 中一些像 `JWT`, `VirtualService`, `HTTPAPISpecBinding`, `QuotaSpecBinding` 的正则表达式时，会被利用而发起 `Istio DoS` 攻击。

__ISTIO-SECURITY-2019-004__: Envoy 和之后的 Istio 更容易受到一系列基于 HTTP/2 的 DoS 攻击：
  * __[CVE-2019-9512](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9512)__: 使用 `PING` 帧和响应 `PING` ACK 帧的 HTTP/2 流，会导致无限的内存增长（这可能导致内存不足的原因）。
  * __[CVE-2019-9513](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9513)__: 使用 PRIORITY 帧的 HTTP/2 流会导致其他客户端的 CPU 使用率过低。
  * __[CVE-2019-9514](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9514)__: 使用具有无效的 HTTP header 的 `HEADERS` 帧和 `RST_STREAM` 帧的 HTTP/2 流，会导致无限的内存增长（这可能导致内存不足的原因）。
  * __[CVE-2019-9515](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9515)__: 使用 `SETTINGS` 帧和 `SETTINGS`  ACK 帧的 HTTP/2 流，会导致无限的内存增长（这可能导致内存不足的原因）。
  * __[CVE-2019-9518](https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-9518)__: 使用具有空负载帧的 HTTP/2 流会导致其他客户端的 CPU 使用率过低。

除上述修复的程序之外，此版本中不包含其他任何内容。
