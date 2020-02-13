---
title: 延长 Istio 自签名根证书的有效期
description: 了解如何延长 Istio 自签名根证书的有效期。
publishdate: 2019-06-07
attribution: Oliver Liu
keywords: [security, PKI, certificate, Citadel]
target_release: 1.1
---

Istio 自签名证书的默认有效期为 1 年。如果您正在使用 Istio 自签名证书，您需要在到期前安排定期根转换。根证书到期可能会导致整个群集意外中断。此问题会影响使用 1.0.7 和 1.1.7 版本创建的新群集。

有关如何判断证书年龄和如何执行轮换的信息，请参见[延长 Istio 自签名证书的有效期](/zh/docs/ops/configuration/security/root-transition/)。

{{< tip >}}
我们强烈建议您每年轮换根密钥和根证书作为最佳安全实践。我们将尽快发出有关根密钥/证书轮换的说明。
{{< /tip >}}
