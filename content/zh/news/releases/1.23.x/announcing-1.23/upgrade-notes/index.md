---
title: Istio 1.23 升级说明
description: 升级到 Istio 1.23.0 时要考虑的重要变更。
weight: 20
publishdate: 2024-08-14
---

当您从 Istio 1.22.x 升级到 Istio 1.23.x 时，您需要考虑本页所述的变更。
这些说明详述了故意打破 Istio 1.22.x 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
这里仅包含出乎 Istio 1.22.x 用户意料的新特性变更。

## 内部 API Protobuf 变更 {#internal-api-protobuf-changes}

如果您不使用来自 Go（通过 `istio.io/api` 或 `istio.io/client-go`）或
Protobuf（来自 `istio.io/api`）的 Istio API，则此更改不会对您造成影响。

在以前的版本中，Istio API 具有在多个版本之间复制的相同内容。
例如，相同的 `VirtualService` Protobuf 消息被定义了 3 次（`v1alpha3`、`v1beta1` 和 `v1`）。
这些定义除了所在的包之外都是相同的。

在此版本的 Istio 中，这些已合并为一个版本。对于具有多个版本的资源，将保留最旧的版本。

* 如果您仅通过 Kubernetes（YAML）使用 Istio API，则完全不会产生影响。
* 如果您使用 Go 类型的 Istio API，则基本上没有影响。
  每个删除的版本都已替换为剩余版本的类型别名，以确保向后兼容性。但是，
  小众用例（反射等）可能会产生一些影响。
* 如果您直接通过 Protobuf 使用 Istio API，并使用较新的版本，
  这些 API 将不再包含在 API 中。如果您受到影响，请联系团队。
