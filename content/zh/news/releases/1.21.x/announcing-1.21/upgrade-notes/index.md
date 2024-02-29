---
title: Istio 1.21 升级说明
description: Important changes to consider when upgrading to Istio 1.21.x.升级到 Istio 1.20 时要考虑的重要变更。
weight: 20
publishdate: 2024-02-28
---

When you upgrade from Istio 1.20.x to Istio 1.21.0, you need to consider the changes on this page. These notes detail the changes which purposefully break backwards compatibility with Istio 1.20.x. The notes also mention changes which preserve backwards compatibility while introducing new behavior. Changes are only included if the new behavior would be unexpected to a user of Istio 1.20.x.
当您从 Istio 1.20.x 升级到 Istio 1.21.0 时，您需要考虑此页面上的更改。 这些注释详细介绍了故意破坏 Istio 1.20.x 向后兼容性的更改。 这些注释还提到了在引入新行为的同时保留向后兼容性的更改。 仅当 Istio 1.20.x 用户无法预料到新行为时，才会包含更改。

## Default value of the feature flag `ENABLE_AUTO_SNI` to true
## 功能标志 `ENABLE_AUTO_SNI` 的默认值为 true

[auto-sni](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/protocol.proto#envoy-v3-api-field-config-core-v3-upstreamhttpprotocoloptions-auto-sni) is enabled by default. This means SNI will be set automatically based on the downstream HTTP host/authority header if `DestinationRule` does not explicitly set the same.
[auto-sni](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/protocol.proto#envoy-v3-api-field-config-core-v3- uploadhttpprotocoloptions-auto-sni) 默认情况下启用。 这意味着如果“DestinationRule”未显式设置相同的内容，SNI 将根据下游 HTTP 主机/权限标头自动设置。

If this is not desired, use the new `compatibilityVersion` feature to fallback to old behavior.
如果不需要，请使用新的“compatibilityVersion”功能回退到旧行为。

## Default value of the feature flag `VERIFY_CERT_AT_CLIENT` is set to true
## 功能标志 `VERIFY_CERT_AT_CLIENT` 的默认值设置为 true

This means server certificates will be automatically verified using the OS CA certificates when not using a DestinationRule `caCertificates` field. If this is not desired, use the new `compatibilityVersion` feature to fallback to old behavior, or use the `insecureSkipVerify` field in DestinationRule to skip the verification.
这意味着在不使用 DestinationRule“caCertificates”字段时，将使用操作系统 CA 证书自动验证服务器证书。 如果不需要，请使用新的“compatibilityVersion”功能回退到旧行为，或使用 DestinationRule 中的“insecureSkipVerify”字段跳过验证。

## `ExternalName` support changes
## `ExternalName` 支持更改

Kubernetes `ExternalName` `Service`s allow users to create new DNS entries. For example, you can create an `example` service that points to `example.com`. This is implemented by a DNS `CNAME` redirect.
Kubernetes `ExternalName` 服务允许用户创建新的 DNS 条目。 例如，您可以创建指向“example.com”的“example”服务。 这是通过 DNS“CNAME”重定向实现的。

In Istio, the implementation of `ExternalName`, historically, was substantially different. Each `ExternalName` represented its own service, and traffic matching the service was sent to the configured DNS name.
在 Istio 中，“ExternalName”的实现在历史上有很大不同。 每个“ExternalName”代表其自己的服务，与该服务匹配的流量被发送到配置的 DNS 名称。

This caused a few issues:
这导致了一些问题：
* Ports are required in Istio, but not in Kubernetes. This can result in broken traffic if ports are not configured as Istio expects, despite them working without Istio.
* Istio 中需要端口，但 Kubernetes 中不需要。 如果端口没有按照 Istio 的预期进行配置，则可能会导致流量中断，尽管它们在没有 Istio 的情况下也能工作。
* Ports not declared as `HTTP` would match *all* traffic on that port, making it easy to accidentally send all traffic on a port to the wrong place.
* 未声明为“HTTP”的端口将匹配该端口上的“所有”流量，从而很容易意外地将端口上的所有流量发送到错误的位置。
* Because the destination DNS name is treated as opaque, we cannot apply Istio policies to it as expected. For example, if I point an external name at another in-cluster Service (for example, `example.default.svc.cluster.local`), mTLS would not be used.
* 由于目标 DNS 名称被视为不透明，因此我们无法按预期对其应用 Istio 策略。 例如，如果我将外部名称指向另一个集群内服务（例如“example.default.svc.cluster.local”），则不会使用 mTLS。

`ExternalName` support has been revamped to fix these problems. `ExternalName`s are now simply treated as aliases. Wherever we would match `Host: <concrete service>` we additionally will match `Host: <external name service>`. Note that the primary implementation of `ExternalName` -- DNS -- is handled outside of Istio in the Kubernetes DNS implementation, and remains unchanged.
对“ExternalName”支持进行了改进以解决这些问题。 `ExternalName` 现在被简单地视为别名。 无论我们在哪里匹配“Host: <concrete service>”，我们都会额外匹配“Host: <external name service>”。 请注意，“ExternalName”的主要实现（DNS）是在 Kubernetes DNS 实现中的 Istio 外部处理的，并且保持不变。

If you are using `ExternalName` with Istio, please be advised of the following behavioral changes:
如果您将 `ExternalName` 与 Istio 一起使用，请注意以下行为变化：
* The `ports` field is no longer needed, matching Kubernetes behavior. If it is set, it will have no impact.
* 不再需要 `ports` 字段，以匹配 Kubernetes 行为。 如果设置了，则不会产生任何影响。
* `VirtualServices` that route to an `ExternalName` service will no longer work unless the referenced service exists (as a Service or ServiceEntry).
* 路由到“ExternalName”服务的“VirtualServices”将不再工作，除非引用的服务存在（作为 Service 或 ServiceEntry）。
* `DestinationRule` can no longer apply to `ExternalName` services. Instead, create rules where the `host` references service.
* `DestinationRule` 不再适用于 `ExternalName` 服务。 相反，创建“主机”引用服务的规则。

To opt-out, the `ENABLE_EXTERNAL_NAME_ALIAS=false` environment variable can be set.
要选择退出，可以设置“ENABLE_EXTERNAL_NAME_ALIAS=false”环境变量。

Note: the same change was introduced in the previous release, but off by default. This release turns the flag on by default.
注意：之前的版本中引入了相同的更改，但默认情况下处于关闭状态。 此版本默认打开该标志。

## Gateway Name label modified
## 网关名称标签已修改

If you are using the [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1.Gateway) to manage your Istio gateways, the label key used to identify the gateway name is changing from `istio.io/gateway-name` to `gateway.networking.k8s.io/gateway-name`. The old label will continue to be appended to the relevant label sets for backwards compatibility, but it will be removed in a future release. Furthermore, istiod's gateway controller will automatically detect and continue to use the old label for label selectors belonging to existing `Deployment` and `Service` resources.
如果您使用 [Kubernetes Gateway](https://gateway-api.sigs.k8s.io/references/spec/#gateway.networking.k8s.io%2fv1.Gateway) 来管理 Istio 网关，则标签密钥 用于标识网关名称的名称从 `istio.io/gateway-name` 更改为 `gateway.networking.k8s.io/gateway-name`。 旧标签将继续附加到相关标签集以实现向后兼容性，但将在未来版本中删除。 此外，istiod 的网关控制器将自动检测并继续使用旧标签作为属于现有 Deployment 和 Service 资源的标签选择器。

Therefore, once you've completed your Istio upgrade, you can change the label selector in `Deployment` and `Service` resources whenever you are ready to use the new label.
因此，完成 Istio 升级后，只要准备好使用新标签，就可以更改“部署”和“服务”资源中的标签选择器。

Additionally, please upgrade any other policies, resources, or scripts that rely on the old label.
此外，请升级依赖于旧标签的任何其他策略、资源或脚本。
