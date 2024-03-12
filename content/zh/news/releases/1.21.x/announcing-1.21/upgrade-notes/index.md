---
title: Istio 1.21 升级说明
description: 升级到 Istio 1.21.x 时要考虑的重要变更。
weight: 20
publishdate: 2024-03-11
---

当您从 Istio 1.20.x 升级到 Istio 1.21.x 时，您需要考虑本页所述的变更。
这些说明详述了故意打破 Istio `1.20.x` 向后兼容性的一些变更。
这些说明还提到了在引入新特性的同时保持向后兼容性的一些变更。
这里仅包含出乎 Istio `1.20.x` 用户意料的新特性变更。

## 功能标志 `ENABLE_AUTO_SNI` 的默认值为启用 {#default-value-of-the-feature-flag-enable_auto_sni-to-true}

[auto-sni](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/protocol.proto#envoy-v3-api-field-config-core-v3-upstreamhttpprotocoloptions-auto-sni)
默认情况下被启用。这意味着如果 `DestinationRule`
未显式设置相同的内容，SNI 将根据下游 HTTP 主机/权限标头被自动设置。

如果不需要该功能，请使用新的 `compatibilityVersion` 功能回退到旧版本行为。

## 功能标志 `VERIFY_CERT_AT_CLIENT` 的默认值被设置为启用 {#default-value-of-the-feature-flag-verify_cert_at_client-is-set-to-true}

这意味着在不设置 DestinationRule `caCertificates` 字段时，
将使用操作系统 CA 证书自动验证服务器证书。
如果不需要该功能，请使用新的 `compatibilityVersion` 功能回退到旧版本行为，
或使用 DestinationRule 中的 `insecureSkipVerify` 字段跳过验证。

## `ExternalName` 支持变更 {#externalname-support-changes}

Kubernetes `ExternalName` 服务允许用户创建新的 DNS 条目。
例如，您可以创建指向 `example.com` 的 `example` 服务。
这是通过 DNS `CNAME` 重定向实现的。

在 Istio 中，`ExternalName` 的实现在历史上有很大不同。
每个 `ExternalName` 代表其自身的服务，与该服务匹配的流量会被发送到所配置的 DNS 名称中。

这导致了一些问题：
* Istio 中需要端口，但在 Kubernetes 中并不关心。
  尽管这些端口在没有 Istio 的情况下也能工作，
  但如果没有按照 Istio 的预期进行配置，则可能会导致流量中断。
* 未声明为 `HTTP` 的端口将匹配该端口上的**所有**流量，
  从而容易导致意外地将端口上所有流量发送到错误的位置。
* 由于目标 DNS 名称被视为不透明，因此我们无法按预期对其应用 Istio 策略。
  例如，如果我将外部名称指向另一个集群内 Service
  （如 `example.default.svc.cluster.local`），则不会使用 mTLS。

现已对 `ExternalName` 支持进行了改进以解决这些问题。`ExternalName` 现在被简单地视为别名。
无论我们在哪里匹配 `Host: <concrete service>`，
我们都会额外匹配 `Host: <external name service>`。
请注意，`ExternalName` 的主要实现（DNS）是在 Kubernetes DNS
实现中的 Istio 外部处理的，并且保持不变。

如果您将 `ExternalName` 与 Istio 一起使用，请注意以下行为变化：
* 不再需要 `ports` 字段，以匹配 Kubernetes 行为。
  如果设置了该字段，也不会产生任何影响。
* 路由到 `ExternalName` 服务的 `VirtualServices` 将不再工作，
  除非被引用的服务确定存在（作为 Service 或 ServiceEntry）。
* `DestinationRule` 不再适用于 `ExternalName` 服务。
  而被创建 `host` 引用服务的规则所替代。

要选择禁用，可以设置 `ENABLE_EXTERNAL_NAME_ALIAS=false` 环境变量。

注意：之前的版本中引入了相同的变更，但默认情况下处于关闭状态。
此版本中默认开启该标志。

## 网关名称标签已修改 {#gateway-name-label-modified}

如果您使用 [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1.Gateway)
来管理 Istio 网关，则用于标识网关名称的标签名称从
`istio.io/gateway-name` 更改为 `gateway.networking.k8s.io/gateway-name`。
旧标签将继续附加到相关标签集以实现向后兼容性，但将在未来版本中移除。
此外，istiod 的网关控制器将自动检测并继续使用旧标签作为属于现有 Deployment 和 Service 资源的标签选择器。

因此，完成 Istio 升级后，只要准备好使用新标签，
就可以更改 `Deployment` 和 `Service` 资源中的标签选择器。

此外，请升级依赖于旧标签的任何其他策略、资源或脚本。
