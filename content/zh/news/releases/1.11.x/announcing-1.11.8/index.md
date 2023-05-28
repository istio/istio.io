---
title: Istio 1.11.8 发布公告
linktitle: 1.11.8
subtitle: 补丁发布
description: Istio 1.11.8 补丁发布。
publishdate: 2022-03-09
release: 1.11.8
aliases:
    - /zh/news/announcing-1.11.8
---

此版本修复了我们 3 月 9 日的帖子
[ISTIO-SECURITY-2022-004](/zh/news/security/istio-security-2022-004)
中描述的安全漏洞。本发布说明描述了 Istio 1.11.7 和
Istio 1.11.8 之间的不同之处。

{{< relnote >}}

## 安全更新{#security-update}

- __[CVE-2022-24726](https://github.com/istio/istio/security/advisories/GHSA-8w5h-qr4r-2h6g)__:
  (CVSS Score 7.5, High)：由于堆栈耗尽导致未经身份验证的控制平面拒绝服务攻击。

### Envoy CVE 漏洞{#envoy-cves}

目前不认为 Istio 容易受到 Envoy 中这些 CVE 漏洞的攻击。
然而，它们被列出是为了披露。

- __[CVE-2022-21657](https://github.com/envoyproxy/envoy/security/advisories/GHSA-837m-wjrv-vm5g)__
  (CVSS Score 3.1, Low)：X.509 扩展密钥使用和信任目的旁路。
