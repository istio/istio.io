---
title: ISTIO-SECURITY-2019-004
subtitle: 安全公告
description: 与 Envoy 中的 HTTP2 支持相关的多个拒绝服务的漏洞。
cve: [CVE-2019-9512, CVE-2019-9513, CVE-2019-9514, CVE-2019-9515, CVE-2019-9518]
cvss: "7.5"
vector: "CVSS:3.0/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H"
releases: ["1.1 to 1.1.12", "1.2 to 1.2.3"]
publishdate: 2019-08-13
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

Envoy 和 Istio 容易受到一系列基于 HTTP/2 的 DoS 攻击：

* 利用 HTTP/2 的 PING 帧及 PING ACK 帧响应队列发起的洪水攻击，这会导致内存的无限制增长(可能导致内存不足的情况)。
* 利用 HTTP/2 的 PRIORITY 帧发起的洪水攻击，这会导致 CPU 使用率过高、不能及时响应其它正常的客户端。
* 利用 HTTP/2 的 HEADERS 帧(带有无效 HTTP Header) 和 `RST_STREAM` 帧响应队列发起的洪水攻击，这会导致内存的无限制增长(可能导致内存不足的情况)。
* 利用 HTTP/2 的 SETTINGS 帧及 SETTINGS ACK 帧响应队列发起的洪水攻击，这会导致内存的无限制增长(可能导致内存不足的情况)。
* 利用 HTTP/2 的 空荷载帧发起的洪水攻击，这会导致 CPU 使用率过高、不能及时响应其它正常的客户端。

这些漏洞是从外部报告的，并影响多个代理的实现。更多信息请查看[安全公告](https://github.com/Netflix/security-bulletins/blob/master/advisories/third-party/2019-002.md)。

## 影响范围{#impact-and-detection}

如果 Istio 终止来自外部的 HTTP，则会使 Istio 容易受到攻击。如果终止 HTTP 的是 Istio 前面的 Intermediary (例: HTTP 负载均衡)，那 Intermediary 就可以保护 Istio，前提是 Intermediary 本身不容易受到相同的 HTTP/2 攻击。

## 防范{#mitigation}

* 对于 Istio 1.1.x 部署：更新至 [Istio 1.1.13](/zh/news/releases/1.1.x/announcing-1.1.13) 或者更新的版本。
* 对于 Istio 1.2.x 部署：更新至 [Istio 1.2.4](/zh/news/releases/1.2.x/announcing-1.2.4) 或者更新的版本。

{{< boilerplate "security-vulnerability" >}}
