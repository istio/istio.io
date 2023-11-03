---
title: 发布 Istio 1.16.3
linktitle: 1.16.3
subtitle: 补丁发布
description: Istio 1.16.3 补丁发布。
publishdate: 2023-02-21T08:00:00-06:00
release: 1.16.3
aliases:
    - /zh/news/announcing-1.16.3
---

此版本包含了一些改进稳健性的漏洞修复。
此发布说明描述了 Istio 1.16.2 和 Istio 1.16.3 之间的不同之处。

此版本包括（2023-02-14 发布的）Go 1.19.6 中对 `path/filepath`、`net/http`、
`mime/multipart` 和 `crypto/tls` 包的安全修复。

{{< relnote >}}

## 变更{#changes}

- **修复** 修复了在默认位置提供证书时 Pilot 的安全 gRPC 服务器的初始化问题。
  ([Issue #42249](https://github.com/istio/istio/issues/42249))

- **修复** 修复了使用 Helm Chart 库生成清单时，
  如果使用 `istioctl` 而没有使用 `--cluster-specific` 选项，
  则默认行为改为使用 `istioctl` 定义的最小 Kubernetes 版本的问题。
  ([Issue #42441](https://github.com/istio/istio/issues/42441))

- **修复** 修复了自定义标题值格式时准入 Webhook 失败的问题。
  ([Issue #42749](https://github.com/istio/istio/issues/42749))

- **修复** 修复了当用户使用 `--proxy-admin-port` 指定自定义代理管理端口时
  `istioctl proxy-config` 失败的问题。
  ([Issue #43063](https://github.com/istio/istio/issues/43063))

- **修复** 修复了 `ALL_METRICS` 不能如预期般禁用 Metrics 的问题。

- **修复** 修复了在创建 `PeerCertificateVerifier` 时忽略默认 CA 证书的问题。

- **修复** 修复了 istiod 在更改 Kubernetes Gateway 部署和服务时无法调节的问题。
  ([Issue #43332](https://github.com/istio/istio/issues/43332))

- **修复** 修复了当未启用 `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING` 时，
  Pilot 状态会记录过多错误的问题。
  ([Issue #42612](https://github.com/istio/istio/issues/42612))
