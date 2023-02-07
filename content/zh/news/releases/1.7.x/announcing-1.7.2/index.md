---
title: 发布 Istio 1.7.2 版本
linktitle: 1.7.2
subtitle: 补丁发布
description: Istio 1.7.2 补丁发布。
publishdate: 2020-09-18
release: 1.7.2
aliases:
    - /zh/news/announcing-1.7.2
---

这个版本包含了错误修复，以提高稳定性。主要说明 Istio 1.7.1 和 Istio 1.7.2 之间的不同之处。

{{< relnote >}}

## 变动{#changes}

- **修复** 本地负载均衡器设置被不必要地应用到入站集群。([Issue #27293](https://github.com/istio/istio/issues/27293))

- **修复** `CronJob` 工作负载的 Istio 指标的无限制基数。([Issue #24058](https://github.com/istio/istio/issues/24058))

- **修复** 为代理设置 `ISTIO_META_REQUESTED_NETWORK_VIEW` 环境变量，将会过滤掉不在逗号分隔的网络列表的 Endpoint。应该设置为用于跨网络流量的入口网关，以防止奇怪的负载均衡行为。([Issue #26293](https://github.com/istio/istio/issues/26293))

- **修复** 当 Service 或 `WorkloadEntry` 在创建后更新时，`WorkloadEntry` 会出现问题。([Issue #27183](https://github.com/istio/istio/issues/27183)),([Issue #27151](https://github.com/istio/istio/issues/27151)),([Issue #27185](https://github.com/istio/istio/issues/27185))
