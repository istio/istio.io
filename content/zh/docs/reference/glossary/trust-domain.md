---
title: Trust Domain
---

[信任域](https://spiffe.io/spiffe/concepts/#trust-domain)对应于系统的信任根，并且是工作负载标识的一部分。

Istio 使用信任域在网格中创建所有[身份](/zh/docs/reference/glossary/#identity)。每个网格都有一个专用的信任域。

例如在 `spiffe://mytrustdomain.com/ns/default/sa/myname` 中标示网格的子字符串是：`mytrustdomain.com`。此子字符串是此网格的信任域。
