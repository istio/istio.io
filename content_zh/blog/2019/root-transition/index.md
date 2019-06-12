---
title: 延长 Istio 自签发根证书的有效期
description: 学习延长 Istio 自签发根证书的有效期的方法。
publishdate: 2019-06-07
attribution: Oliver Liu
keywords: [security, PKI, certificate, Citadel]
---

Istio 的自签发证书只有一年的有效期。如果你选择使用 Istio 的自签发证书，就需要在它们过期之前订好计划进行根证书的更迭。根证书过期可能会导致集群范围内的意外中断。这一问题的影响范围涵盖了 1.0.7、1.1.7 及之前的所有版本。

阅读[《延长自签发证书的有效期》](/zh/help/ops/security/root-transition/)一文，其中包含了获取证书有效期以及完成证书轮换的方法。

{{< tip >}}

我们认为每年更换根证书和密钥是一个安全方面的最佳实践，我们会在后续内容中介绍根证书和密钥的轮换方法。

{{< /tip >}}
