---
title: Configuration Validation Webhook
description: 描述 Istio 使用 Kubernetes webhook 来进行服务端配置。
weight: 40
aliases:
  - /zh/help/ops/setup/validation
  - /zh/docs/ops/setup/validation
---

Galley 的配置验证可确保用户编写的 Istio 配置在语法和语义上均有效。它使用了 Kubernetes 的 `ValidatingWebhook`。`istio-galley` 的 `ValidatingWebhookConfiguration` 配置有两个 webhook 。

* `pilot.validation.istio.io` - 它通过 `/admitpilot` 路径提供服务，并负责验证 Pilot 使用的配置 (例如 `VirtualService`, Authentication)。

* `mixer.validation.istio.io` - 它通过 `/admitmixer` 路径提供服务，并负责验证 Mixer 使用的配置。

这两个 webhook 都经 `istio-galley` 在 443 端口提供服务， 每个 webhook 都有自己的 `clientConfig`、`namespaceSelector` 和  `rules` 部分，作用于所有命名空间，其中 `namespaceSelector` 应该为空， 所有 `rules` 都适用于 Istio Custom Resource Definitions (CRD)。

