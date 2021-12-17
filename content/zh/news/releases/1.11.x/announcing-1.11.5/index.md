---
title: 发布 Istio 1.11.5 版本
linktitle: 1.11.5
subtitle: 补丁发布
description: Istio 1.11.5 补丁发布。
publishdate: 2021-12-02
release: 1.11.5
aliases:
    - /zh/news/announcing-1.11.5
---

此版本包含一些漏洞修复，从而提高了系统的稳健性。这个版本说明主要描述了 Istio 1.11.4 和 Istio 1.11.5 之间的不同之处。

{{< relnote >}}

## 改变{#changes}

- **修复** 修复了 Istiod 部署遵循 `values.pilot.nodeSelector` 参数的问题。
  ([Issue #36110](https://github.com/istio/istio/issues/36110))

- **修复** 修复了当 Istio 控制平面有活动的代理连接时，集群内的 Operator 不能削减资源的问题。
  ([Issue #35657](https://github.com/istio/istio/issues/35657))

- **修复** 修复了通过添加补丁版本来获取释放 tar URL 的问题。

- **修复** 修复了在 Envoy 中当通过 `MeshNetworks` 配置多网络网关时， `LbEndpointValidationError.LoadBalancingWeight: value must be greater than or equal to 1` 的问题。

- **修复** 修复了在 k8s 1.21+ 版本时，工作负载名称监控指标标签没有正确填充 `CronJob` 的问题。
  ([Issue #35563](https://github.com/istio/istio/issues/35563))
