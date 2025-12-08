---
title: 发布 Istio 1.27.4
linktitle: 1.27.4
subtitle: 补丁发布
description: Istio 1.27.4 补丁发布。
publishdate: 2025-12-03
release: 1.27.4
aliases:
    - /zh/news/announcing-1.27.4
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.27.3 和 Istio 1.27.4 之间的区别。

本次发布实现了 12 月 3 日公布的安全更新
[`ISTIO-SECURITY-2025-003`](/zh/news/security/istio-security-2025-003)。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了安装多个 Istio 版本时路由资源的状态冲突的问题。
  ([Issue #57734](https://github.com/istio/istio/issues/57734))

- **修复** 修复了 waypoint 的一个问题，即根命名空间中 `targetRef`
  类型为 `GatewayClass` 且组为 `gateway.networking.k8s.io`
  的 `EnvoyFilter` 无法正常工作。

- **修复** 修复了在使用 TPROXY 模式的原生 nftables 且 `traffic.sidecar.istio.io/includeInboundPorts`
  注解为空时 `istio-init` 出现的故障。
  ([Issue #58135](https://github.com/istio/istio/issues/58135))

- **修复** 修复了当使用 `secret-name` 和 `namespace/secret-name` 格式从
  Istio Gateway 对象引用同一个 Kubernetes Secret 时，
  Envoy Secret 资源可能会卡在 `WARMING` 状态的问题。
  ([Issue #58146](https://github.com/istio/istio/issues/58146))

- **修复** 修复无头服务的 DNS 名称表创建问题，其中 Pod 条目没有考虑 Pod 具有多个 IP 地址的情况。
  ([Issue #58397](https://github.com/istio/istio/issues/58397))

- **修复** 修复了 HTTPS 服务器优先处理导致 HTTP 服务器无法在同一端口上使用不同的绑定地址创建路由的问题。
  ([Issue #57706](https://github.com/istio/istio/issues/57706))

- **修复** 修复了一个导致实验性 `XListenerSet` 资源无法访问 TLS 密钥的错误。
