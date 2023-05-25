---
title: 发布 Istio 1.16.2
linktitle: 1.16.2
subtitle: 补丁发布
description: Istio 1.16.2 补丁发布。
publishdate: 2023-01-30
release: 1.16.2
---

此版本包含了一些改进稳健性的漏洞修复。
此发布说明描述了 Istio 1.16.1 和 Istio 1.16.2 之间的不同之处。

{{< relnote >}}

## 变更{#changes}

- **新增** 新增了 `--revision` 参数到 `istioctl analyze`，便于指定具体的版本。
  ([Issue #38148](https://github.com/istio/istio/issues/38148))

- **修复** 修复了使用 `--revision default` 参数时 `istioctl install` 失败的问题。

- **修复** 修复了 `istioctl verify-install` 在不指定 `--revision`
  和指定为 `default` 时行为不一致的问题。

- **修复** 修复了当选择或取消选择命名空间时 Gateway API 资源处理不正确的问题，
  以及在设置 `ENABLE_ENHANCED_RESOURCE_SCOPING=true` 时更改命名空间标签时的问题。
  ([Issue #42173](https://github.com/istio/istio/issues/42173))

- **修复** 修复了启用 `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG`
  时若服务更新则自动透传网关无法获取 XDS 推送的问题。

- **修复** 修复了在设置流量策略 TLS 模式时如果 `PortLevelSettings[].Port`
  为空则 Pilot 会异常退出的问题。
  ([Issue #42598](https://github.com/istio/istio/issues/42598))

- **修复** 修复了命名空间的网络标签比 Pod 的网络标签优先级更高的错误。
  ([Issue #42675](https://github.com/istio/istio/issues/42675))
