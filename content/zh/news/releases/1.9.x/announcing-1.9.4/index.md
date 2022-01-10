---
title: 发布 Istio 1.9.4 版本
linktitle: 1.9.4
subtitle: 补丁发布
description: Istio 1.9.4 补丁发布。
publishdate: 2021-04-27
release: 1.9.4
aliases:
    - /zh/news/announcing-1.9.4
---

此版本包含一些错误修复以提高稳健性。此版本说明描述了 Istio 1.9.3 和 Istio 1.9.4 版本之间的区别。

{{< relnote >}}

## 变化

- **修复** Istio 操作员删除由操作员创建的所有资源（包括其自身）的问题。现在操作员将只能删除属于自定义的资源。([Issue #30833](https://github.com/istio/istio/issues/30833))

- **修复** 确保约定期限始终大于用户为 Istio 操作管理员配置的 `RENEW_DEADLINE` 的问题。([Issue #27509](https://github.com/istio/istio/issues/27509))

- **修复** Prometheus 无法使用 Sidecar 代理提供的证书的问题。([Issue #29919](https://github.com/istio/istio/issues/29919))

- **修复** 在另一个命名空间中安装 Istio 时，在 `istio-system` 下创建 IOP 的问题。([Issue #31517](https://github.com/istio/istio/issues/31517))

- **修复** 当使用多网络时，使用 `PeerAuthentication` 来关闭 mTLS 时出现的问题。现在，非 mTLS 端点将从跨网络负载平衡端点中移除，以防止 500 错误。([Issue #28798](https://github.com/istio/istio/issues/28798))

- **修复** 当 `istiod` 无法从通过远程加密配置的集群中读取资源时，它将一直不会准备就绪。在 `PILOT_REMOTE_CLUSTER_TIMEOUT` 配置的超时后（默认为 `30s`），`istiod` 将在不同步远程集群的情况下准备就绪。当发生这种情况时，`remote_cluster_sync_timeouts` 将被递增。([Issue #30838](https://github.com/istio/istio/issues/30838))

- **修复** 当 `values.global.pilotCertProvider` 为 `kubernetes` 时，`istiod` 不会创建一个自签发的根 CA 和 `istio-ca-root-cert` 配置映射的问题。([Issue #32023](https://github.com/istio/istio/issues/32023))

- **优化** 使用 `istioctl xworkload` 命令来配置 VM，使其禁用管理端口的入站 `iptables` 捕获，以匹配 Kubernetes Pod 的行为。([Issue #29412](https://github.com/istio/istio/issues/29412))

- **优化** 当在有成千上万个命名空间的集群上运行时，`istiod` 的性能优化。([Issue #32269](https://github.com/istio/istio/pull/32269)

- **优化** 在 Kubernetes 中检测服务器端应用。([Issue #32101](https://github.com/istio/istio/issues/32101))
