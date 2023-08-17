---
title: 发布 Istio 1.13.6
linktitle: 1.13.6
subtitle: 补丁发布
description: Istio 1.13.6 补丁发布。
publishdate: 2022-07-25
release: 1.13.6
---

{{< warning >}}
Istio 1.13.6 不包含对 [CVE-2022-31045](/zh/news/security/istio-security-2022-005/#cve-2022-31045) 的修复。我们建议用户暂时不要安装 Istio 1.13.6，推荐使用的版本是 Istio 1.13.5。
Istio 1.13.7 将于本周晚些时候发布。
{{< /warning >}}

此版本包含错误修复，以提高稳健性。
本发行说明描述了 Istio 1.13.5 和 1.13.6 之间的不同之处。

仅供参考，[Go 1.18.4 已经发布](https://groups.google.com/g/golang-announce/c/nqrv9fbR0zE)，
其中包括 9 个安全修复程序。如果您在本地使用 Go，我们建议您升级到这个较新的 Go 版本。

{{< relnote >}}

## 变化{#changes}

- **修复** 修复了构建路由器的路由命令 `catch all` 不会短路它后面的其他路由的问题。([Issue #39188](https://github.com/istio/istio/issues/39188))

- **修复** 修复了当更新一个多集群密钥时，前一个集群不会被停止的问题。即使删除密钥也不会停止前一个集群的问题。([Issue #39366](https://github.com/istio/istio/issues/39366))

- **修复** 修复了在发送访问日志到注入 `OTel-collector` 的 Pod 时抛出 `http2.invalid.header.field` 的错误。([Issue #39196](https://github.com/istio/istio/issues/39196))

- **修复** 修复了导致服务合并时只考虑第一个和最后一个服务，而不是所有服务的问题。
