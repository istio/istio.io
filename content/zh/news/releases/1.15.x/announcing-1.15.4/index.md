---
title: 发布 Istio 1.15.4
linktitle: 1.15.4
subtitle: 补丁发布
description: Istio 1.15.4 补丁发布。
publishdate: 2022-12-12
release: 1.15.4
---

此版本包含了一些改进稳健性的漏洞修复。本发布说明描述了 Istio 1.15.3 和 Istio 1.15.4 之间的不同之处。

此版本包含 Go 1.19.4（发布于 2022 年 12 月 6 日）中针对 `os` 和 `net/http` 包的安全修复。

{{< relnote >}}

## 变更{#changes}

- **改进** 当 Wasm 模块下载失败且 `fail_open` 值为 true 时，一个允许所有流量的
  RBAC 过滤器会被传递给 Envoy，而不是原来的 Wasm 过滤器。
  之前，在这种情况下，给定的 Wasm 过滤器本身被传递给 Envoy，但它可能会导致错误，
  因为 Wasm 配置的某些字段在 Istio 中是可选的，但在 Envoy 中不是。

- **修复** 修复了当使用 Istio Operator 资源删除一个自定义网关时，其他网关会被重新启动的问题。
  ([Issue #40577](https://github.com/istio/istio/issues/40577))

- **修复** 修复了当 `cni.resourceQuotas` 被启用时，Istio Operator 无法正确创建 CNI 的问题。
  ([Issue #41159](https://github.com/istio/istio/issues/41159))

- **修复** 修复了 `istiod` 以 `PILOT_ENABLE_STATUS=true` 启动时，缺乏清理分发报告 ConfigMap 的权限的问题。

- **修复** 修复了 `pilotExists` 总是返回 `false`的问题。
  ([Issue #41631](https://github.com/istio/istio/issues/41631))

- **修复** 修复了 Gateway Pod 不遵守 Helm 值中指定的 `global.imagePullPolicy`。
