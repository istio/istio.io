---
title: Istio 1.5.6 发布公告
linktitle: 1.5.6
subtitle: 补丁发布
description: Istio 1.5.6 补丁发布。
publishdate: 2020-06-17
release: 1.5.6
aliases:
    - /zh/news/announcing-1.5.6
---

此版本包含一些 bug 的修复，用以提高程序的健壮性和用户体验。同时这个版本说明也描述了 Istio 1.5.5 和 Istio 1.5.6 之间的区别。

{{< relnote >}}

## 安全{#security}

- **更新** 更新了在 bookinfo 应用中的 Node.js 和 jQuery 的依赖版本。

## 改变{#changes}

- **修复** 修复了 Envoy 中 Transfer-Encoding 值的大小写敏感问题。 ([Envoy's issue 10041](https://github.com/envoyproxy/envoy/issues/10041))
- **修复** 修复了处理用户自定义的入口网关配置问题。 ([Issue 23303](https://github.com/istio/istio/issues/23303))
- **修复** 修复了在 `UpstreamTlsContext` 中为指定了 `http2_protocol_options` 的集群添加 `TCP MX ALPN` 的问题。 ([Issue 23907](https://github.com/istio/istio/issues/23907))
- **修复** 修复了在命名空间内应用配置管理控制器的选举锁问题。
- **修复** 修复了 `istioctl validate -f` 的 `networking.istio.io/v1beta1` 规则问题。 ([Issue 24064](https://github.com/istio/istio/issues/24064))
- **修复** 修复了聚合集群的配置问题。 ([Issue 23909](https://github.com/istio/istio/issues/23909))
- **修复** 修复了 Prometheus mTLS 抓取 pods 的问题。 ([Issue 22391](https://github.com/istio/istio/issues/22391))
- **修复** 修复了主机出现重叠且未匹配时入口崩溃的问题。 ([Issue 22910](https://github.com/istio/istio/issues/22910))
- **修复** 修复了 Istio 遥测 Pod 崩溃的问题。 ([Issue 23813](https://github.com/istio/istio/issues/23813))
- **移除** 移除了硬编码的 operator 命名空间。 ([Issue 24073](https://github.com/istio/istio/issues/24073))
