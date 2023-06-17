---
title: 发布 Istio 1.6.10
linktitle: 1.6.10
subtitle: 补丁更新
description: Istio 1.6.10 补丁更新。
publishdate: 2020-09-22
release: 1.6.10
aliases:
    - /news/announcing-1.6.10
---

此版本包含修复错误以提高健壮性。本版本说明介绍了 Istio 1.6.9 和 Istio 1.6.10 之间的差异。

{{< relnote >}}

## 变更

- **添加** 日志采样配置和 Stackdriver 测试中的引号
- **修复** headless 服务的网关缺少终端实例的问题([Istio #27041](https://github.com/istio/istio/issues/27041))
- **修复** 不必要地将负载均衡器设置应用于入站集群时区域负载均衡器设置([Istio #27293](https://github.com/istio/istio/issues/27293))
- **修复** `CronJob` 工作负载的 Istio 指标的无限基数 ([Istio #24058](https://github.com/istio/istio/issues/24058))
- **改进** Envoy 缓存可用性值
- **删除** `istioctl manifest migrate` 的弃用帮助消息 ([Istio #26230](https://github.com/istio/istio/issues/26230))