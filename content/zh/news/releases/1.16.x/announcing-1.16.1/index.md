---
title: 发布 Istio 1.16.1
linktitle: 1.16.1
subtitle: 补丁发布
description: Istio 1.16.1 补丁发布。
publishdate: 2022-12-12
release: 1.16.1
---

此版本包含了一些改进稳健性的漏洞修复。
此发布说明描述了 Istio 1.16.0 和 Istio 1.16.1 之间的不同之处。

此版本包括（2022-12-06 发布的）Go 1.19.4 中对 `os` 和 `net/http` 包的安全修复。

{{< relnote >}}

## 变更{#changes}

- **弃用** 弃用了对 Kubernetes 1.20 之前的版本使用 `PILOT_CERT_PROVIDER=kubernetes`。

- **更新** 将 Kiali 插件版本更新为 1.59.1。

- **修复** 修复了 OpenTelemetry 跟踪器不工作的问题。
  ([Issue #42080](https://github.com/istio/istio/issues/42080))

- **修复** 修复了使用 Helm 与 istioctl 安装时 `ValidatingWebhookConfiguration` 将有所不同的问题。

- **修复** 修复了 ServiceEntries 使用 `DNS_ROUND_ROBIN` 能够指定 0 个端点的问题。
  ([Issue #42184](https://github.com/istio/istio/issues/42184))

- **修复** 修复了当 `automountServiceAccountToken` 被设置为 false 且
  `PILOT_CERT_PROVIDER` 环境变量被设置为 `kubernetes` 时阻止 `istio-proxy` 访问根 CA 的问题。

- **修复** 修复了网关 Pod 不遵守 Helm 值中所指定 `global.imagePullPolicy` 的问题。
