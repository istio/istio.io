---
title: Istio 1.3.1 发布公告
linktitle: 1.3.1
subtitle: 补丁发布
description: Istio 1.3.1 补丁发布。
publishdate: 2019-09-27
release: 1.3.1
aliases:
    - /zh/news/2019/announcing-1.3.1
    - /zh/news/announcing-1.3.1
---

此版本包含一些错误修复程序，以提高稳定性。此发行说明描述了 Istio 1.3.0 和 Istio 1.3.1 之间的区别。

{{< relnote >}}

## Bug 修复{#bug-fixes}

- **修复** 在升级过程中错误的导致 secret 清理任务执行错误的问题（[Issue 16873](https://github.com/istio/istio/issues/16873)）。
- **修复** 默认配置禁用 Kubernetes Ingress 支持的问题（[Issue 17148](https://github.com/istio/istio/issues/17148)）。
- **修复** 在 Stackdriver 日志记录适配器中处理无效 `UTF-8` 字符的问题（[Issue 16966](https://github.com/istio/istio/issues/16966)）。
- **修复** HTTP 指标中没有为 `BlackHoleCluster` 和 `PassThroughCluster` 设置 `destination_service` 标签的问题（[Issue 16629](https://github.com/istio/istio/issues/16629)）。
- **修复** 由于 `destination_service` 标签问题导致 `istio_tcp_connections_closed_total` 和 `istio_tcp_connections_opened_total` 指标不能被正确设置（[Issue 17234](https://github.com/istio/istio/issues/17234)）。
- **修复** Istio 1.2.4 引入的 Envoy 崩溃问题（[Issue 16357](https://github.com/istio/istio/issues/16357)）。
- **修复** 在节点上禁用 IPv6 时，Istio CNI Sidecar 初始化的问题（[Issue 15895](https://github.com/istio/istio/issues/15895)）。
- **修复** 影响 JWT 中 RS384 和 RS512 算法支持问题（[Issue 15380](https://github.com/istio/istio/issues/15380)）。

## 小的增强{#minor-enhancements}

- **增加** `.Values.global.priorityClassName` 对遥测部署的支持。
- **增加** 对 Datadog 的支持。
- **增加** `pilot_xds_push_time` 指标以报告 Pilot xDS 推送时间。
- **增加** `istioctl experimental analyze` 以支持多资源分析和验证。
- **增加** 对在 WebAssembly 沙箱中运行元数据交换和统计信息扩展的支持。请按照[以下](/zh/docs/ops/configuration/telemetry/in-proxy-service-telemetry/)说明进行尝试。
- **删除** proxy-status 命令中的时间差异信息。
