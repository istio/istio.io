---
title: Istio 1.17.1 公告
linktitle: 1.17.1
subtitle: 补丁发布
description: Istio 1.17.1 补丁发布。
publishdate: 2023-02-23T09:00:00-06:00
release: 1.17.1
aliases:
  - /zh/news/announcing-1.17.1
---

本发布包含了一些错误修复，以提高稳健性。本发布说明描述了 Istio 1.17.0 和 Istio 1.17.1 之间的不同之处。

该版本包括（2023-02-14 发布的）Go 1.20.1 中对 `crypto/tls`、`mime/multipart`、`net/http` 和 `path/filepath` 包的安全修复。

{{< relnote >}}


## 变更{#changes}

- **新增** 增加了支持修改 gRPC keepalive 值的环境变量。 [Issue #42398](https://github.com/istio/istio/pull/42398)

- **修复了** 修复了一个问题，即 `ALL_METRICS' 不能像预期那样禁用指标的问题。[Issue #43178](https://github.com/istio/istio/issues/43178)

- **修复** 修复了在创建 `PeerCertificateVerifier' 时忽略默认CA证书的问题。[PR #43337](https://github.com/istio/istio/pull/43337)

- **修复** 修复了 istiod 在 Kubernetes Gateway 部署和服务发生变化时不进行调节的问题。[Issue #43332](https://github.com/istio/istio/issues/43332)

- **修复** 报告了 Gateway API 网关资源的 "Programmed "条件。[Issue #43498](https://github.com/istio/istio/issues/43498)

- **修复** 修复了更新服务 `外部名称' 不生效的问题。[Issue #43440](https://github.com/istio/istio/issues/43440)