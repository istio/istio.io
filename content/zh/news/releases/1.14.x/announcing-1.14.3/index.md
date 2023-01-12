---
title: Istio 1.14.3 发布公告
linktitle: 1.14.3
subtitle: 补丁发布
description: Istio 1.14.3 补丁发布。
publishdate: 2022-08-01
release: 1.14.3
---

此版本包括对 [CVE-2022-31045](/zh/news/security/istio-security-2022-005/#cve-2022-31045) 和其它有助于改善稳定性的修复。
我们推荐用户安装这个版本来替代未包含上述 CVE 修复的 Istio 1.14.2。
此发布说明描述了 Istio 1.14.2 和 1.14.3 之间的不同之处。

还有一条信息供参考，[Go 1.18.4 已发布](https://groups.google.com/g/golang-announce/c/nqrv9fbR0zE)，
包含了 9 个安全修复。如果您正在本地使用 Go，我们推荐您升级到这个更新的 Go 版本。

{{< relnote >}}

## 变更  {#changes}

- **修复** 修复了在 `Sidecar` 中一个在改变 `outboundTrafficPolicy` 后有时设置改变不能生效的问题。([Issue #39794](https://github.com/istio/istio/issues/39794))

- **移除** 从 `istio-ingress/egress` helm 值模板中移除了 `archs` 和有条件填充 `nodeAffinity` 的设置。

## 安全更新  {#security-updates}

- **修复** 修复了 [CVE-2022-31045](/zh/news/security/istio-security-2022-005/#cve-2022-31045)。
