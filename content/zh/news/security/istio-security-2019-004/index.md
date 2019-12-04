---
title: ISTIO-SECURITY-2019-004
subtitle: 安全公告
description: 披露了多个CVE的安全漏洞。
cve: [CVE-2019-9512, CVE-2019-9513, CVE-2019-9514, CVE-2019-9515, CVE-2019-9518]
publishdate: 2019-08-13
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin
        cves="CVE-2019-9512, CVE-2019-9513, CVE-2019-9514, CVE-2019-9515, CVE-2019-9518"
        cvss="7.5"
        vector="CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
        releases="1.1 to 1.1.12, 1.2 to 1.2.3" >}}

## 内容{#context}

Envoy 和 Istio 容易受到一系列基于 HTTP/2 的DoS攻击：

* 使用 PING frames 和排队响应的 PING ACK frames 发起 HTTP/2 flood，这会导致内存的无限制增长(可能导致内存不足的情况)。
* 使用 PRIORITY frames 发起 HTTP/2 flood，这会导致过多的使用 CPU 和其他客户端空闲。
* 使用带有无效 HTTP headers 的 HEADERS frames 和排队响应 `RST_STREAM` frames 发起 HTTP/2 flood，这会导致内存的无限制增长(可能导致内存不足的情况)。
* 使用 SETTINGS frames 和排队的 SETTINGS ACK frames 发起 HTTP/2 flood ，这会导致内存的无限制增长(可能导致内存不足的情况)。
* 使用包含空 payload 的 frames 发起 HTTP/2 flood，这会导致过多的使用 CPU 和 其他客户端空闲。

这些漏洞是从外部报告的，并影响多个代理的实现。更多信息请查看[安全公告](https://github.com/Netflix/security-bulletins/blob/master/advisories/third-party/2019-002.md)。

## 影响范围{#impact-and-detection}

如果 Istio 终止来自外部的 HTTP，则它很容易受到攻击。如果终止 HTTP 的是 Istio 前面的 Intermediary (例: HTTP 负载均衡)，那 Intermediary 就可以保护 Istio，前提是 Intermediary 本身不容易受到相同的 HTTP2 攻击。

## 防范{#mitigation}

* 对于 Istio 1.1.x 部署：更新至[Istio 1.1.13](/zh/news/releases/1.1.x/announcing-1.1.13)或者更新的版本。
* 对于 Istio 1.2.x 部署：更新至[Istio 1.2.4](/zh/news/releases/1.2.x/announcing-1.2.4)或者更新的版本。

{{< boilerplate "security-vulnerability" >}}
