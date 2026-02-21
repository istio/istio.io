---
title: 发布 Istio 1.27.7
linktitle: 1.27.7
subtitle: 补丁发布
description: Istio 1.27.7 补丁发布。
publishdate: 2026-02-16
release: 1.27.7
aliases:
    - /zh/news/announcing-1.27.7
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.27.6 和 Istio 1.27.7 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

- [CVE-2025-61732](https://github.com/advisories/GHSA-8jvr-vh7g-f8gx)
  (CVSS score 8.6, High)：Go 和 C/C++ 注释解析方式的差异使得代码可以偷偷潜入生成的 cgo 二进制文件中。
- [CVE-2025-68121](https://github.com/advisories/GHSA-h355-32pf-p2xm)
  (CVSS score 4.8, Moderate)：`crypto/tls` 会话恢复机制存在一个缺陷，如果客户端证书颁发机构 (ClientCAs) 或根证书颁发机构 (RootCAs) 在初始握手和恢复握手之间发生变更，
  则本应失败的恢复握手可能会成功。这种情况在使用带有变更的 `Config.Clone` 或 `Config.GetConfigForClient` 时可能会发生。
  因此，客户端可能会与非预期的服务器恢复会话，服务器也可能与非预期的客户端恢复会话。

## 变更 {#changes}

除了上述安全更新之外，本次版本更新没有引入其他任何更改。
