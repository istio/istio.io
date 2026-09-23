---
title: 发布 Istio 1.28.1
linktitle: 1.28.1
subtitle: 补丁发布
description: Istio 1.28.1 补丁发布。
publishdate: 2025-12-03
release: 1.28.1
aliases:
    - /zh/news/announcing-1.28.1
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.28.0 和 Istio 1.28.1 之间的区别。

本次发布实现了 12 月 3 日公布的安全更新
[`ISTIO-SECURITY-2025-003`](/zh/news/security/istio-security-2025-003)。

{{< relnote >}}

## 变更 {#changes}

- **新增** 添加了对 `InferencePool` 中多个 `targetPorts` 的支持。
  GIE v1.1.0 版本新增了拥有多个 `targetPort` 的功能。
  ([Issue #57638](https://github.com/istio/istio/issues/57638))

- **修复** 修复了安装多个 Istio 版本时路由资源的状态冲突的问题。
  ([Issue #57734](https://github.com/istio/istio/issues/57734))

- **修复** 修复了同一命名空间内主机名重叠的 `ServiceEntry` 资源在 Ambient 模式下导致不可预测的行为。
  ([Issue #57291](https://github.com/istio/istio/issues/57291))

- **修复** 修复了在使用 TPROXY 模式的原生 nftables 且 `traffic.sidecar.istio.io/includeInboundPorts`
  注解为空时 `istio-init` 出现的故障。
  ([Issue #58135](https://github.com/istio/istio/issues/58135))

- **修复** 修复了 EDS 生成代码未考虑服务范围的问题，导致不应可访问的远程集群端点被包含在 waypoint 配置中。
  ([Issue #58139](https://github.com/istio/istio/issues/58139))

- **修复** 修复了由于试点中 EDS 缓存不正确，导致 Ambient E/W 网关或 waypoint 配置了无法使用的 EDS 端点的问题。
  ([Issue #58141](https://github.com/istio/istio/issues/58141))

- **修复** 修复了当使用 `secret-name` 和 `namespace/secret-name` 格式从
  Istio Gateway 对象引用同一个 Kubernetes Secret 时，
  Envoy Secret 资源可能会卡在 `WARMING` 状态的问题。
  ([Issue #58146](https://github.com/istio/istio/issues/58146))

- **修复** 修复了在 Ambient 模式下明确禁用 IPv6 时，IPv6 nftables 规则被编程的问题。
  ([Issue #58249](https://github.com/istio/istio/issues/58249))

- **修复** 修复无头服务的 DNS 名称表创建问题，其中 Pod 条目没有考虑 Pod 具有多个 IP 地址的情况。
  ([Issue #58397](https://github.com/istio/istio/issues/58397))

- **修复** 修复了使用自定义信任域时导致 Ambient 多网络连接失败的问题。
  ([Issue #58427](https://github.com/istio/istio/issues/58427))

- **修复** 修复了 HTTPS 服务器优先处理导致 HTTP 服务器无法在同一端口上使用不同的绑定地址创建路由的问题。
  ([Issue #57706](https://github.com/istio/istio/issues/57706))

- **修复** 修复了一个导致实验性 `XListenerSet` 资源无法访问 TLS 密钥的错误。
