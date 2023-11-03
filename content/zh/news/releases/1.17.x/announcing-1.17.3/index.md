---
 title: Istio 1.17.3 公告
 linktitle: 1.17.3
 subtitle: 补丁发布
 description: Istio 1.17.3 补丁发布。
 publishdate: 2023-06-06
 release: 1.17.3
---

此版本包含了一些改进稳健性的漏洞修复。
此发布说明描述了 Istio 1.17.2 和 Istio 1.17.3 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **新增** 在网关 Chart 中添加了对 `PodDisruptionBudget`（PDB）的支持。
  ([Issue #44469](https://github.com/istio/istio/issues/44469))

- **修复** 修复了与 Istio 1.18+ [Kubernetes 网关自动部署](/zh-cn/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)的向前兼容性问题。
  要无缝升级到 1.18+，使用此功能的用户应首先采用此补丁版本。
  ([Issue #44164](https://github.com/istio/istio/issues/44164))

- **修复** **修复** 修复了 `dns_upstream_failures_total` 指标在之前的版本中被错误删除的问题。
  ([PR #44176](https://github.com/istio/istio/pull/44176))

- **修复** 修复了缺少 grpc 统计信息的问题。
  ([Issue #43908](https://github.com/istio/istio/issues/43908)，
  [Issue #44144](https://github.com/istio/istio/issues/44144))

- **修复** 修复了 `Istio Gateway`（Envoy）由于 Envoy 过滤器链中重复的
  `istio_authn` 网络过滤器而崩溃的问题。
  ([Issue #44385](https://github.com/istio/istio/issues/44385))

- **修复** 修复了 VirtualService 验证在前缀标头匹配器为空时失败的问题。
  ([Issue #44424](https://github.com/istio/istio/issues/44424))

- **修复** 修复了如果启用了 `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG`，
  网关中的服务会丢失的错误。
  ([Issue #44439](https://github.com/istio/istio/issues/44439))

- **修复** `istioctl analyze` 在分析文件时不再需要 Pod 和运行时资源的问题。
  ([Issue #40861](https://github.com/istio/istio/issues/40861))

- **修复** 修复了使用多个 IOP 时 `istioctl verify-install` 失败的问题。
  ([Issue #42964](https://github.com/istio/istio/issues/42964))

- **修复** 修复了远程 SPIFFE 信任包包含多个证书时的处理问题。
  ([PR #44909](https://github.com/istio/istio/pull/44909))

- **修复** 修复了 DestinationRule 指定的证书无效时 CPU 使用率异常高的问题。
  ([Issue #44986](https://github.com/istio/istio/issues/44986))
