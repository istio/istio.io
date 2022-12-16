---
title: Istio 1.16 升级说明
description: 升级到 Istio 1.16.0 时要考虑的重要变更。
publishdate: 2022-11-15
weight: 20
---

当您从 Istio 1.15.x 升级到 Istio 1.16.0 时，需要考虑此页面上所描述的变更。
这些说明详述了有意破坏 Istio 1.15.0 向后兼容性的变更，还提到了在引入新行为的同时保留向后兼容性的变更。
只有当新的行为对 Istio `1.15.x` 的用户来说是意想不到的时候，才会包含这些更改。
从 Istio 1.14.x 升级到 1.16.0 的用户还应参考 [1.15 变更日志](/zh/news/releases/1.15.x/announcing-1.15/change-notes/)。

## Gateway API 资源{#gateway-api-resources}

Gateway API 集成已升级为读取 `v1beta1` 版本的 `HTTPRoute`、`Gateway` 和 `GatewayClass` 资源。
如果使用目前处于 Beta 阶段的 Gateway API 新特性进行流量管理，则此项更改将要求 gateway-api 为 0.5.0 或更高版本。
有关详细信息，请参阅 Kubernetes Gateway API [入门指南](/zh/docs/setup/additional-setup/getting-started)。
