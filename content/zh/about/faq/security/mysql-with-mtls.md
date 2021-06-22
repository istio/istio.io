---
title: MySQL 连接故障排除
description: 解决由于 PERMISSIVE 模式导致的 MySQL 连接问题。
weight: 95
keywords: [mysql,mtls]
---

安装 Istio 后，您可能会发现 MySQL 无法连接。 这是因为 MySQL 是 [服务器优先](/zh/docs/ops/deployment/requirements/#server-first-protocols) 协议，
这会干扰 Istio 的协议检测。 特别是，使用“PERMISSIVE”mTLS 模式可能会导致问题。
您可能会看到诸如 `ERROR 2013 (HY000): Lost connection to MySQL server at
'reading initial communication packet', system error: 0` 这样的错误。

这可以通过确保使用 `STRICT` 或 `DISABLE` 模式或配置所有客户端来解决
发送 mTLS。 有关详细信息，请参阅 [服务器优先协议](/zh/docs/ops/deployment/requirements/#server-first-protocols)。
