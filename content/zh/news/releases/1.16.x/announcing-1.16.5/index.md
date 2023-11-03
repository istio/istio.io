---
title: 发布 Istio 1.16.5
linktitle: 1.16.5
subtitle: 补丁发布
description: Istio 1.16.5 补丁发布.
publishdate: 2023-05-23
release: 1.16.5
---

本发布说明描述了 Istio 1.16.4 和 Istio 1.16.5 之间的不同之处。

{{< relnote >}}

## 变更{#changes}

- **更新** 更新了 VirtualService 验证在空头信息前缀匹配器上失败的问题。
  ([Issue #44424](https://github.com/istio/istio/issues/44424))

- **修复** 修复了在上一版本中被错误删除的 `dns_upstream_failures_total` 指标。
  ([Issue #44151](https://github.com/istio/istio/issues/44151))

- **修复** 修复了如果开启 `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG`，
  网关中服务缺失的错误。
  ([Issue #44439](https://github.com/istio/istio/issues/44439))

- **修复** 修复了与 Istio 1.18+
  [Kubernetes 网关自动部署](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)的前向兼容性问题。
  可以无缝升级到 1.18+，使用此功能的用户应首先采用此补丁版本。
  ([Issue #44164](https://github.com/istio/istio/issues/44164))
