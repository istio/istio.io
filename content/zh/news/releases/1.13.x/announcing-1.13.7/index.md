---
title: Istio 1.13.7 发布公告
linktitle: 1.13.7
subtitle: 补丁发布
description: Istio 1.13.7 补丁发布。
publishdate: 2022-08-01
release: 1.13.7
aliases:
    - /zh/news/announcing-1.13.7
---

此版本包含针对 [CVE-2022-31045](/zh/news/security/istio-security-2022-005/#cve-2022-31045) 所做的修复和其他漏洞修复，以提高稳健性。我们建议用户安装此版本来替代未包含上述 CVE 修复的 Istio 1.13.6。
这个发布说明描述了 Istio 1.13.6 和 Istio 1.13.7 之间的区别。

仅供参考，[Go 1.18.4 已发布](https://groups.google.com/g/golang-announce/c/nqrv9fbR0zE)，
其中包括 9 个安全修复。如果您在本地使用 Go，我们建议您升级到这个较新的 Go 版本。

{{< relnote >}}

## 变化{#changes}

- **修复** 修复了导致 `Sidecar` 中的 `outboundTrafficPolicy` 更改并不总是生效的问题。  ([Issue #39794](https://github.com/istio/istio/issues/39794))

- **移除** 从 `istio-ingress/egress` helm 值模板中移除了 `archs`，还移除了有条件填充 `nodeAffinity` 的设置。

# 安全更新{#security-update}

- **修复** 修复了 [CVE-2022-31045](/zh/news/security/istio-security-2022-005/#cve-2022-31045)。
