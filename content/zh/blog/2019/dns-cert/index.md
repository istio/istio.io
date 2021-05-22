---
title: DNS 证书管理
description: 在 Istio 中配置和管理 DNS 证书。
publishdate: 2019-11-14
attribution: Lei Tang (Google)
keywords: [security, kubernetes, certificates, DNS]
target_release: 1.4
---

默认情况下, `Istio` 的 `DNS` 证书是由 `Citadel` 来管理的。`Citadel` 是一个功能强大的组件，不仅维护自己的私有签名密钥，而且充当证书颁发机构（CA）。

在 `Istio` 的 1.4 版本中，我们引入了一项新功能，可以安全地配置和管理由 `Kubernetes CA` 签名的 `DNS` 证书，它具有以下优点。

* 轻量级 `DNS` 证书管理，不依赖于 `Citadel`。

* 与 `Citadel` 不同的是，此功能不维护私有签名密钥，从而增强了安全性。

* 简化了向 `TLS` 客户端分发根证书。客户不再需要等待 `Citadel` 生成和分发其 `CA` 证书。

下图显示了在 `Istio` 中配置和管理 `DNS` 证书的体系结构。`Chiron` 是在 `Istio` 中配置和管理 `DNS` 证书的组件。

{{< image width="50%"
    link="./architecture.png"
    caption="在 Istio 中配置和管理 DNS 证书的架构"
    >}}

要尝试此新功能，请参阅 [DNS 证书管理内容](/zh/docs/tasks/security/cert-management/dns-cert)。
