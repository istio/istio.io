---
title: Trust Domain
---

信任域是 Istio 用于在网格中创建所有 [身份](/docs/zh/reference/glossary/#identity)) 的唯一名称。每个网格都有一个专用的信任域。

例如在 `spiffe://mytrustdomain.com/ns/default/sa/myname` 中标示网格的是：`mytrustdomain.com`。 此子字符串是网格的信任域。
