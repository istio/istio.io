---
title: 发布 Istio 1.14.6
linktitle: 1.14.6
subtitle: 补丁发布
description: Istio 1.14.6 补丁发布。
publishdate: 2022-12-12
release: 1.14.6
---

此版本包含了一些改进稳健性的漏洞修复。本发布说明描述了
Istio 1.14.5 和 Istio 1.14.6 之间的不同之处。

值得一提的是，此版本还包括（2022 年 12 月 6 日发布的）Go 1.18.9
中的那些安全修复。

{{< relnote >}}

## 变更{#changes}

- **修复** 修复了当使用 Istio Operator
  资源删除一个自定义网关时，其他网关会被重新启动的问题。
  ([Issue #40577](https://github.com/istio/istio/issues/40577))

- **修复** 修复了配置 Datadog 链路追踪提供程序时 Telemetry API
  中缺少 `service_name` 的问题。
  ([Issue #38573](https://github.com/istio/istio/issues/38573))

- **修复** 修复了错误的模式配置导致 Istio Operator 进入错误循环的问题。
  ([Issue #40876](https://github.com/istio/istio/issues/40876))

- **修复** 修复了 Gateway Pod 不遵守 Helm 值中指定的 `global.imagePullPolicy`。

- **添加** 为 DestinationRule 指定故障转移策略但不提供 `OutlierDetection`
  策略时添加了警告验证消息。在此之前，istiod 会默默地忽略故障转移设置。

- **改进** 当 Wasm 模块下载失败且 `fail_open` 值为 true 时，
  一个允许所有流量的 RBAC 过滤器会被传递给 Envoy，
  而不是原来的 Wasm 过滤器。之前，在这种情况下，给定的
  Wasm 过滤器本身被传递给 Envoy，但它可能会导致错误，
  因为 Wasm 配置的某些字段在 Istio 中是可选的，但在 Envoy 中不是。
