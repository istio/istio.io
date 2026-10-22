---
title: 发布 Istio 1.29.10
linktitle: 1.29.10
subtitle: 补丁发布
description: Istio 1.29.10 补丁发布。
publishdate: 2026-10-21
release: 1.29.10
aliases:
    - /zh/news/announcing-1.29.10
---

此版本包含安全修复。本发行说明描述了 Istio 1.29.9 和 Istio 1.29.10 之间的区别。
1.29 已于 2026 年 10 月 15 日[结束生命周期](/zh/news/support/announcing-1.29-eol/)，
此版本是为解决 [ISTIO-SECURITY-2026-008](/zh/news/security/istio-security-2026-008) 而发布的特例版本。
我们鼓励您升级到受支持的版本。

{{< relnote >}}

## 安全更新 {#security-update}

有关更多信息，请参阅
[ISTIO-SECURITY-2026-008](/zh/news/security/istio-security-2026-008)。

- **移除** 移除了对私钥已泄露的 eMudhra 中间 CA 证书的信任。
  基于 `ubuntu` 的镜像和 `distroless` 镜像中的 CA 捆绑包不再包含 `emSign ECC Root CA - G3`。

- **更新** 将 ztunnel 中的 `rustls-webpki` 更新至 0.103.16，
  该版本会拒绝包含任何已泄露 eMudhra 中间证书私钥的证书链。

- Istio 1.29 使用 Go 1.25 构建，而 Go 1.25 已不再接收修复，因此此版本不包含针对
  [CVE-2026-111943](https://nvd.nist.gov/vuln/detail/CVE-2026-111943) 的 Go 修复。
  istiod、`istioctl` 和 `pilot-agent` 仅依赖更新后的 CA 捆绑包。
  如需获得该 Go 修复，请升级到 1.30.7 或 1.31.3。
