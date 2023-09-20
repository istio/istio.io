---
title: 发布 Istio 1.17.6
linktitle: 1.17.6
subtitle: 补丁发布
description: Istio 1.17.6 补丁发布。
publishdate: 2023-09-19
release: 1.17.6
---

此版本包含了一些改进稳健性的漏洞修复。
此发布说明描述了 Istio 1.17.5 和 Istio 1.17.6 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了 CentOS 9/RHEL 9 上的 SELinux 问题，
  其中不允许 iptables-restore 打开 `/tmp` 中的文件。
  传递给 iptables-restore 的规则不再写入文件，而是通过 stdin 传递。
  ([Issue #42485](https://github.com/istio/istio/issues/42485))

- **修复** 修复了 Istio 应在 AWS 上尽可能使用 `IMDSv2` 的问题。
  ([Issue #45825](https://github.com/istio/istio/issues/45825))

- **修复** 修复了当只有默认提供程序时 `meshConfig.defaultConfig.sampling` 被忽略的问题。
  ([Issue #46653](https://github.com/istio/istio/issues/46653))

- **修复** 修复了在没有任何提供程序的情况下创建 Telemetry 对象会引发 IST0157 错误的问题。
  ([Issue #46510](https://github.com/istio/istio/issues/46510))
