---
title: ISTIO-SECURITY-2026-008
subtitle: 安全公告
description: Istio 镜像、Go 和 ztunnel 不再信任私钥已泄露的 eMudhra 中间 CA 证书。
cves: [CVE-2026-111943]
cvss: "N/A"
vector: ""
releases: ["1.31.0 to 1.31.2", "1.30.0 to 1.30.6", "1.29.0 to 1.29.9"]
publishdate: 2026-10-21
keywords: [CVE]
skip_seealso: true
---

{{< security_bulletin >}}

## eMudhra 中间 CA 私钥泄露 {#emudhra-intermediate-ca-compromise}

2026 年 10 月 20 日，8 个 eMudhra 中间 CA 证书（包括其 Sectigo 交叉签名证书）的私钥
[被披露已经泄露](https://emudhra.we-have-a-problem.com/)。
任何持有其中某个私钥的人都可以为任意域名签发证书，
而这些证书的证书链可以追溯到 Istio 镜像中公共 CA 捆绑包所信任的根证书。
强制执行证书透明度（Certificate Transparency）的浏览器受到了保护，
但 Envoy、Go 和 ztunnel 不会强制执行证书透明度。

此版本移除了对这些中间证书的信任：

- 基于 `ubuntu` 的 Istio 镜像中的 CA 捆绑包已更新为 `ca-certificates` `20260816ubuntu0.24.04.1`，
  该版本移除了 `emSign ECC Root CA - G3`。

- `distroless` 镜像已基于更新后的 `cgr.dev/chainguard/static` 基础镜像重新构建，
  该基础镜像移除了 `emSign ECC Root CA - G3`。

- __[CVE-2026-111943](https://nvd.nist.gov/vuln/detail/CVE-2026-111943)__：
  istiod、`istioctl` 和 `pilot-agent` 使用 Go 1.26.10 构建（Istio 1.30 和 1.31），
  无论信任哪些根证书，Go 1.26.10 都会拒绝包含任何已泄露中间证书私钥的证书链。
  Istio 1.29 使用 Go 1.25 构建，而 Go 1.25 已不再接收修复，因此仅依赖更新后的 CA 捆绑包。
  我们鼓励 1.29 用户升级到受支持的版本，以获得该 Go 修复。

- ztunnel 已更新为使用 `rustls-webpki` 0.103.16，
  该版本会拒绝包含任何已泄露中间证书私钥的证书链。

Envoy 没有内置的不受信任密钥列表，并且除非配置了 CRL，否则不会检查证书吊销状态，
因此 Sidecar 和网关依赖于更新后的 CA 捆绑包。

## 我受到影响了吗？{#am-i-impacted}

Istio 自身的网格 mTLS 证书不受影响。如果 Istio 信任镜像中的公共 CA 捆绑包，
则您可能会受到影响，例如：

- 设置了 `tls.mode: SIMPLE` 但未设置 `caCertificates` 或 `credentialName` 的 `DestinationRule`，
  这在通过 `ServiceEntry` 访问外部 HTTPS 服务的出口流量中很常见。

- 带有 `jwksUri` 的 `RequestAuthentication`，istiod 会使用系统 CA 捆绑包获取该 `jwksUri`。

- `XDS_ROOT_CA=SYSTEM`，或 `pilot-agent` 或 ztunnel 使用系统 CA 捆绑包连接 istiod 的其他配置。

## 缓解措施 {#mitigation}

- 针对 Istio 1.31 用户：升级至 **1.31.3** 或更高版本。
- 针对 Istio 1.30 用户：升级至 **1.30.7** 或更高版本。
- 针对 Istio 1.29 用户：升级至 **1.29.10**。1.29 已于 2026 年 10 月 15 日
  [结束生命周期](/zh/news/support/announcing-1.29-eol/)，此版本是一个特例版本。
  请计划升级至 1.30 或更高版本。
- 如果无法升级，请在外部服务的 `DestinationRule` 资源上设置 `caCertificates`（或 `credentialName`），
  而不是依赖系统 CA 捆绑包；或者将 `caCrl` 设置为已吊销中间证书的 CRL。
