---
title: 发布 Istio 1.17.1
linktitle: 1.17.1
subtitle: 补丁发布
description: Istio 1.17.1 补丁发布。
publishdate: 2023-02-23T09:00:00-06:00
release: 1.17.1
---

此版本包含了一些改进稳健性的漏洞修复。
此发布说明描述了 Istio 1.17.0 和 Istio 1.17.1 之间的不同之处。

此版本包括（2023-02-14 发布的）Go 1.20.1 中对 `crypto/tls`，`mime/multipart`，`net/http` 和 `path/filepath` 包的安全修复。

{{< relnote >}}

## 变更{#changes}

- **新增** 支持修改 gRPC keepalive 环境变量的值。
  ([Issue #42398](https://github.com/istio/istio/pull/42398))

- **修复** `ALL_METRICS` 不能够按照预期禁用 Metrics 的问题。
  ([Issue #43178](https://github.com/istio/istio/issues/43178))

- **修复** 当 `PeerCertificateVerifier` 被创建时忽略默认 CA 证书。
  ([PR #43337](https://github.com/istio/istio/pull/43337))

- **修复** istiod 不会在 Kubernetes Gateway 的 Deployment 和 Service 发生更改时对其进行调协。
  ([Issue #43332](https://github.com/istio/istio/issues/43332))

- **修复** 上报 Gateway API 中 Gateway 资源的 `Programmed` 条件。
  ([Issue #43498](https://github.com/istio/istio/issues/43498))

- **修复** 更新服务的 `ExternalName` 不生效的问题。
  ([Issue #43440](https://github.com/istio/istio/issues/43440))
