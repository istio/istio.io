---
title: 发布 Istio 1.30.7
linktitle: 1.30.7
subtitle: 补丁发布
description: Istio 1.30.7 补丁发布。
publishdate: 2026-10-21
release: 1.30.7
aliases:
    - /zh/news/announcing-1.30.7
---

此版本包含安全修复。本发行说明描述了 Istio 1.30.6 和 Istio 1.30.7 之间的区别。

{{< relnote >}}

## 安全更新 {#security-update}

有关更多信息，请参阅
[ISTIO-SECURITY-2026-008](/zh/news/security/istio-security-2026-008)。

- **移除** 移除了对私钥已泄露的 eMudhra 中间 CA 证书的信任。
  基于 `ubuntu` 的镜像和 `distroless` 镜像中的 CA 捆绑包不再包含 `emSign ECC Root CA - G3`。

- __[CVE-2026-111943](https://nvd.nist.gov/vuln/detail/CVE-2026-111943)__：
  将 Go 更新至 1.26.10，使 istiod、`istioctl` 和 `pilot-agent`
  会拒绝包含任何已泄露 eMudhra 中间证书私钥的证书链。

- **更新** 将 ztunnel 中的 `rustls-webpki` 更新至 0.103.16，
  该版本会拒绝包含任何已泄露 eMudhra 中间证书私钥的证书链。

## 变更 {#changes}

- **修复** 修复了 Ambient 节点去污点（node-untaint）控制器在仅 istio-cni 就绪时
  就移除 `cni.istio.io/not-ready` 污点的问题。现在该控制器还可以等待节点上的 ztunnel 就绪，
  从而避免将 Pod 调度到 ztunnel 仍处于卡死状态的节点上。
  此功能在该发布分支上默认关闭，可通过设置 `PILOT_NODE_UNTAINT_CHECK_ZTUNNEL=true` 启用。
  仅在启用 Ambient 模式时适用。
  ([Issue #52073](https://github.com/istio/istio/issues/52073))

- **修复** 修复了当 `istio-ca-secret` 中的自签名 CA 证书已过期时 istiod 无法启动的问题。
  当 Deployment 缩容到零的时间超过证书 TTL 时，就可能出现这种情况。
  现在会使用现有私钥自动续期已过期的证书。

- **修复** 修复了 `istioctl bug-report --duration` 在未与 `--end-time` 一起使用时不会过滤日志的问题。
