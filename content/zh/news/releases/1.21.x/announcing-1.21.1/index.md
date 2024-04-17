---
title: 发布 Istio 1.21.1
linktitle: 1.21.1
subtitle: 补丁发布
description: Istio 1.21.1 补丁发布。
publishdate: 2024-04-08
release: 1.21.1
---

本次发布实现了 4 月 8 日公布的安全更新 [`ISTIO-SECURITY-2024-002`](/zh/news/security/istio-security-2024-002)
并修复了一些错误，提高了稳健性。

本发布说明描述了 Istio 1.21.0 和 Istio 1.21.1 之间的不同之处。

{{< relnote >}}

## 变更 {#changes}

- **修复** 修复了当 `VirtualService` 包含不同大小写的重复主机将导致路由被 Envoy 拒绝的错误。
  ([Issue #49638](https://github.com/istio/istio/issues/49638))

- **修复** 修复了由于存在 ECDS 配置使得依赖 Envoy 配置转储的命令无法工作的问题。

- **修复** 修复了在安装过程中观测 `EnvoyFilter` 资源未被正确修剪的问题。
  ([Issue #48126](https://github.com/istio/istio/issues/48126))

- **修复** 修复了启用集群内分析时， CPU 消耗异常高的问题。
  ([Issue #49340](https://github.com/istio/istio/issues/49340))

- **修复** 修复了更新 `ServiceEntry` 的 `TargetPort` 不会触发 xDS 推送的问题。
  ([Issue #49878](https://github.com/istio/istio/issues/49878))
