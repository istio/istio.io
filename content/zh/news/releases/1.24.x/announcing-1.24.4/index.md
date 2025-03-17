---
title: 发布 Istio 1.24.4
linktitle: 1.24.4
subtitle: 补丁发布
description: Istio 1.24.4 补丁发布。
publishdate: 2025-03-17
release: 1.24.4
---

此版本包含一些错误修复，以提高稳定性。
本发行说明描述了 Istio 1.24.3 和 Istio 1.24.4 之间的区别。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了由于 Envoy 引导程序未更新，导致通过
  `WORKLOAD_IDENTITY_SOCKET_FILE` 自定义工作负载身份 SDS 套接字名称不起作用的问题。
  ([Issue #51979](https://github.com/istio/istio/issues/51979))

- **修复** 修复了 `istio-cni` 中的一个问题，
  如果在 Ambient 网格中注册的 Pod 有多个网络命名空间，
  我们（错误地）选择了属于最新 PID 的网络，而不是最旧的 PID。
  ([Issue #55139](https://github.com/istio/istio/issues/55139))

- **修复** 修复了网关注入模板不遵循 `kubectl.kubernetes.io/default-logs-container`
  和 `kubectl.kubernetes.io/default-container` 注解的问题。

- **修复** 修复了 `IstioOperator` 中某些用户指定的值被默认值覆盖的情况。

- **修复** 修复了导致 VirtualService 标头名称验证拒绝有效标头名称的问题。

- **修复** 修复了验证 webhook 拒绝原本有效的 `connectionPool.tcp.IdleTimeout=0s`。
  ([Issue #55409](https://github.com/istio/istio/issues/55409))

- **修复** 修复了 `IstioCertificateService`，以确保 `IstioCertificateResponse.CertChain`
  每个数组元素仅包含一个证书。
  ([Issue #1061](https://github.com/istio/ztunnel/issues/1061))
