---
title: Istio 1.21.0 更新说明
linktitle: 1.21.0
subtitle: 次要版本
description: Istio 1.21.0 更新说明。
publishdate: 2024-02-28
release: 1.21.0
weight: 10
aliases:
    - /news/announcing-1.21.0
---

## Traffic Management
## 流量治理 {#traffic-management}

- **Improved** pilot-agent to return the HTTP probe body and status code from the probe setting in the container.
- **改进** Pilot-agent 从容器中的探针设置返回 HTTP 探针正文和状态代码。

- **Improved** support for `ExternalName` services. See Upgrade Notes for more information.
- **改进**对“ExternalName”服务的支持。 有关详细信息，请参阅升级说明。

- **Improved** the variables `PILOT_MAX_REQUESTS_PER_SECOND` (which rate limits the incoming requests, previously defaulted to 25.0) and `PILOT_PUSH_THROTTLE` (which limits the number of concurrent responses, previously defaulted to 100) to automatically scale with the CPU size Istiod is running on if not explicitly configured.
- **改进**变量 `PILOT_MAX_REQUESTS_PER_SECOND` （限制传入请求的速率，之前默认为 25.0）和 `PILOT_PUSH_THROTTLE` （限制并发响应数量，之前默认为 100），以自动随 CPU 大小 Istiod 进行扩展 如果没有明确配置则运行。

- **Added** the ability to configure the IPv4 loopback CIDR used by `istio-iptables` in various firewall rules.
([Issue #47211](https://github.com/istio/istio/issues/47211))
- **添加**在各种防火墙规则中配置“istio-iptables”使用的 IPv4 环回 CIDR 的功能。
  ([Issue #47211](https://github.com/istio/istio/issues/47211))

- **Added** support for automatically setting default network for workloads if they are added to the ambient mesh before the network topology is set. Before, when you set `topology.istio.io/network` on your Istio root namespace, you needed to manually rollout the ambient workloads to make the network change take effect. Now, the network of ambient workloads will be automatically updated even if they do not have a network label. Note that if your ztunnel is not in the same network as what you set in the `topology.istio.io/network` label in your Istio root namespace, your ambient workloads will not be able to communicate with each other.
- **添加**支持自动设置工作负载的默认网络（如果在设置网络拓扑之前将工作负载添加到环境网格）。 之前，当您在 Istio 根命名空间上设置“topology.istio.io/network”时，您需要手动部署环境工作负载以使网络更改生效。 现在，即使环境工作负载没有网络标签，网络也会自动更新。 请注意，如果您的 ztunnel 与您在 Istio 根命名空间的“topology.istio.io/network”标签中设置的网络不在同一网络中，则您的环境工作负载将无法相互通信。

- **Added** namespace discovery selector support on gateway deployment controller. It is protected under `ENABLE_ENHANCED_RESOURCE_SCOPING`. When enabled, the gateway controller will only watch the k8s gateways that match the selector. Note it will affect both gateway and waypoint deployment.
- **添加了**网关部署控制器上的命名空间发现选择器支持。 它受到“ENABLE_ENHANCED_RESOURCE_SCOPING”的保护。 启用后，网关控制器将仅监视与选择器匹配的 k8s 网关。 请注意，它将影响网关和航路点部署。

- **Added** support for the delta ADS client.
- **添加**对 delta ADS 客户端的支持。

- **Added** support for concurrent `SidecarScope` conversion. You can use `PILOT_CONVERT_SIDECAR_SCOPE_CONCURRENCY` to adjust the number of concurrent executions. Its default value is 1 and will not be executed concurrently. When `initSidecarScopes` consumes a lot of time and you want to reduce time consumption by increasing CPU consumption, you can increase the number of concurrent executions by increasing the value of `PILOT_CONVERT_SIDECAR_SCOPE_CONCURRENCY`.
- **添加**对并发 `SidecarScope` 转换的支持。 您可以使用`PILOT_CONVERT_SIDECAR_SCOPE_CONCURRENCY`来调整并发执行的数量。 它的默认值为1，并且不会并发执行。 当 initSidecarScopes 消耗大量时间，并且希望通过增加 CPU 消耗来减少时间消耗时，可以通过增加 PILOT_CONVERT_SIDECAR_SCOPE_CONCURRENCY 的值来增加并发执行数。

- **Added** support for setting the `:authority` header in virtual service's `HTTPRouteDestination`. Now, we support host rewrite for both `host` and `:authority`.
- **添加**支持在虚拟服务的“HTTPRouteDestination”中设置“:authority”标头。 现在，我们支持 `host` 和 `:authority` 的主机重写。

- **Added** prefixes to the `WasmPlugin` resource name.
- **为“WasmPlugin”资源名称添加**前缀。

- **Added** support for setting `idle_timeout` in `TcpProxy` filters for outbound traffic.
- **添加**支持在出站流量的“TcpProxy”过滤器中设置“idle_timeout”。

- **Added** support for [In-Cluster Gateway Deployments](https://gateway-api.sigs.k8s.io/geps/gep-1762/). Deployments now have both `istio.io/gateway-name` and `gateway.networking.k8s.io/gateway-name` labels like Pods and Services.
- **添加**对[集群内网关部署](https://gateway-api.sigs.k8s.io/geps/gep-1762/)的支持。 部署现在同时具有 `istio.io/gateway-name` 和 `gateway.networking.k8s.io/gateway-name` 标签，例如 Pod 和服务。

- **Added** support for max concurrent streams settings in the `DestinationRule`s HTTP traffic policy for HTTP2 connections.
([Issue #47166](https://github.com/istio/istio/issues/47166))
- **添加了**对 HTTP2 连接的“DestinationRule”HTTP 流量策略中的最大并发流设置的支持。
  ([Issue #47166](https://github.com/istio/istio/issues/47166))

- **Added** support for setting TCP idle timeout for HTTP services.
- **添加**支持为 HTTP 服务设置 TCP 空闲超时。

- **Added** connection pool settings to the `Sidecar` API to enable configuring the inbound connection pool for sidecars in the mesh. Previously, the `DestinationRule`'s connection pool settings applied to both client and server sidecars. Using the updated `Sidecar` API, it's now possible to configure the server's connection pool separately from the clients' in the mesh. ([reference]( https://istio.io/latest/docs/reference/config/networking/sidecar/#Sidecar-inbound_connection_pool)) ([Issue #32130](https://github.com/istio/istio/issues/32130)),([Issue #41235](https://github.com/istio/istio/issues/41235))
- **向“Sidecar” API 添加了**连接池设置，以便为网格中的 sidecar 配置入站连接池。 以前，“DestinationRule”的连接池设置适用于客户端和服务器 sidecar。 使用更新的“Sidecar” API，现在可以在网格中与客户端分开配置服务器的连接池。 ([参考]( https://istio.io/latest/docs/reference/config/networking/sidecar/#Sidecar-inbound_connection_pool)) ([问题 #32130](https://github.com/istio/istio/ issues/32130)),([问题 #41235](https://github.com/istio/istio/issues/41235))

- **Added** `idle_timeout` to the TCP settings in the `DestinationRule` API to enable configuring idle timeout per `TcpProxy` filter.
- **在“DestinationRule” API 中的 TCP 设置中添加**“idle_timeout”，以启用每个“TcpProxy”过滤器配置空闲超时。

- **Enabled** the Envoy configuration to use an endpoint cache when there is a delay in sending endpoint configurations from Istiod when a cluster is updated.
- **启用** Envoy 配置以在集群更新时从 Istiod 发送端点配置出现延迟时使用端点缓存。

- **Fixed** a bug where overlapping wildcard hosts in a `VirtualService` would produce incorrect routing configuration when wildcard services were selected (e.g. in `ServiceEntries`).
([Issue #45415](https://github.com/istio/istio/issues/45415))
- **修复**一个错误，当选择通配符服务时（例如在“ServiceEntries”中），“VirtualService”中重叠的通配符主机会产生不正确的路由配置。
  ([Issue #45415](https://github.com/istio/istio/issues/45415))

- **Fixed** an issue where the `WasmPlugin` resource was not correctly applied to the waypoint.
([Issue #47227](https://github.com/istio/istio/issues/47227))
- **修复**“WasmPlugin”资源未正确应用于航路点的问题。
  ([Issue #47227](https://github.com/istio/istio/issues/47227))

- **Fixed** an issue where sometimes the network of waypoint was not properly configured.
- **修复**有时航路点网络配置不正确的问题。

- **Fixed** an issue where the `pilot-agent istio-clean-iptables` command was not able to clean up the iptables rules generated for the Istio DNS proxy.
([Issue #47957](https://github.com/istio/istio/issues/47957))
- **修复** `pilot-agent istio-clean-iptables` 命令无法清理为 Istio DNS 代理生成的 iptables 规则的问题。
  ([Issue #47957](https://github.com/istio/istio/issues/47957))

- **Fixed** slow cleanup of auto-registered `WorkloadEntry` resources when auto-registration and cleanup would occur shortly after the initial `WorkloadGroup` creation.
([Issue #44640](https://github.com/istio/istio/issues/44640))
- **修复**在初始“WorkloadGroup”创建后不久发生自动注册和清理时，自动注册“WorkloadEntry”资源清理缓慢的问题。
  ([Issue #44640](https://github.com/istio/istio/issues/44640))

- **Fixed** an issue where Istio was performing additional XDS pushes for `StatefulSets`/headless `Service` endpoints while scaling.  ([Issue #48207](https://github.com/istio/istio/issues/48207))
- **修复** Istio 在扩展时对“StatefulSets”/无头“Service”端点执行额外的 XDS 推送的问题。 （[问题 #48207](https://github.com/istio/istio/issues/48207))

- **Fixed** a memory leak caused when a remote cluster is deleted or `kubeConfig` is rotated.
([Issue #48224](https://github.com/istio/istio/issues/48224))
- **修复**删除远程集群或轮换“kubeConfig”时导致的内存泄漏。
  ([Issue #48224](https://github.com/istio/istio/issues/48224))

- **Fixed** an issue where if a `DestinationRule`'s `exportTo` includes a workload's current namespace (not '.'), other namespaces are ignored from `exportTo`.
([Issue #48349](https://github.com/istio/istio/issues/48349))
- **修复**以下问题：如果“DestinationRule”的“exportTo”包含工作负载的当前命名空间（不是“.”），则“exportTo”会忽略其他命名空间。
  ([Issue #48349](https://github.com/istio/istio/issues/48349))

- **Fixed** an issue where the QUIC listeners were not correctly created when dual-stack is enabled.
([Issue #48336](https://github.com/istio/istio/issues/48336))
- **修复**启用双栈时未正确创建 QUIC 侦听器的问题。
  ([Issue #48336](https://github.com/istio/istio/issues/48336))

- **Fixed** an issue where `convertToEnvoyFilterWrapper` returned an invalid patch that could cause a null pointer exception when it was applied.
- **修复** `convertToEnvoyFilterWrapper` 返回无效补丁的问题，该补丁在应用时可能会导致空指针异常。

- **Fixed** an issue where updating a Service's `targetPort` does not trigger an xDS push.
([Issue #48580](https://github.com/istio/istio/issues/48580))
- **修复**更新服务的“targetPort”不会触发 xDS 推送的问题。
  ([Issue #48580](https://github.com/istio/istio/issues/48580))

- **Fixed** an issue where in-cluster analysis was unnecessarily performed when there was no configuration change.
([Issue #48665](https://github.com/istio/istio/issues/48665))
- **修复**在没有配置更改时不必要执行集群内分析的问题。
  ([Issue #48665](https://github.com/istio/istio/issues/48665))

- **Fixed** a bug that results in the incorrect generation of configurations for pods without associated services, which includes all services within the same namespace. This can occasionally lead to conflicting inbound listeners error.
- **修复了**一个错误，该错误会导致没有关联服务（包括同一命名空间内的所有服务）的 Pod 错误生成配置。 这有时会导致入站侦听器冲突错误。

- **Fixed** an issue where new endpoints may not be sent to proxies.
([Issue #48373](https://github.com/istio/istio/issues/48373))
- **修复**新端点可能无法发送到代理的问题。
  ([Issue #48373](https://github.com/istio/istio/issues/48373))

- **Fixed** Gateway API `AllowedRoutes` handling for `NotIn` and `DoesNotExist` label selector match expressions.
([Issue #48044](https://github.com/istio/istio/issues/48044))
- **修复**网关 API `AllowedRoutes` 对 `NotIn` 和 `DoesNotExist` 标签选择器匹配表达式的处理。
  ([Issue #48044](https://github.com/istio/istio/issues/48044))

- **Fixed** `VirtualService` HTTP header present match not working when `header-name: {}` is set.
([Issue #47341](https://github.com/istio/istio/issues/47341))
- **修复** 设置 `header-name: {}` 时，`VirtualService` HTTP 标头当前匹配不起作用。
  ([Issue #47341](https://github.com/istio/istio/issues/47341))

- **Fixed** multi-cluster leader election not prioritizing local over remote leader.
([Issue #47901](https://github.com/istio/istio/issues/47901))
- **修复**多集群领导者选举不优先考虑本地领导者而不是远程领导者。
  ([Issue #47901](https://github.com/istio/istio/issues/47901))

- **Fixed** a memory leak when `hostNetwork` Pods scale up and down.
([Issue #47893](https://github.com/istio/istio/issues/47893))
- **修复**`hostNetwork` Pod 扩展和缩小时的内存泄漏。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **Fixed** a memory leak when `WorkloadEntries` change their IP address.
([Issue #47893](https://github.com/istio/istio/issues/47893))
- **修复**`WorkloadEntries` 更改其 IP 地址时的内存泄漏。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **Fixed** a memory leak when a `ServiceEntry` is removed.
([Issue #47893](https://github.com/istio/istio/issues/47893))
- **修复**删除 `ServiceEntry` 时的内存泄漏。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **Upgraded** ambient traffic capture and redirection compatibility by switching to an in-pod mechanism.
([Issue #48212](https://github.com/istio/istio/issues/48212))
- 通过切换到 Pod 内机制，**升级**环境流量捕获和重定向兼容性。
  ([Issue #48212](https://github.com/istio/istio/issues/48212))

- **Removed** the `PILOT_ENABLE_INBOUND_PASSTHROUGH` environment variable, which has been enabled-by-default for the past 8 releases.
- **删除了** `PILOT_ENABLE_INBOUND_PASSTHROUGH` 环境变量，该变量在过去 8 个版本中默认启用。

## Security
## 安全性 {#security}

- **Improved** request JWT authentication to use the upstream Envoy JWT filter instead of the custom Istio Proxy filter. Because the new upstream JWT filter capabilities are needed, the feature is gated for the proxies that support them. Note that a custom Envoy or Wasm filter that used `istio_authn` dynamic metadata key needs to be updated to use `envoy.filters.http.jwt_authn` dynamic metadata key.
- **改进**请求 JWT 身份验证以使用上游 Envoy JWT 过滤器而不是自定义 Istio 代理过滤器。 由于需要新的上游 JWT 过滤器功能，因此该功能针对支持它们的代理进行了门禁。 请注意，使用“istio_authn”动态元数据密钥的自定义 Envoy 或 Wasm 过滤器需要更新为使用“envoy.filters.http.jwt_authn”动态元数据密钥。

- **Updated** the default value of the feature flag `ENABLE_AUTO_SNI` to `true`. If undesired, please use the new `compatibilityVersion` feature to fallback to old behavior.
- **将**功能标志“ENABLE_AUTO_SNI”的默认值更新为“true”。 如果不需要，请使用新的“compatibilityVersion”功能回退到旧行为。

- **Updated** the default value of the feature flag `VERIFY_CERT_AT_CLIENT` to `true`. This means server certificates will be automatically verified using the OS CA certificates when not using a `DestinationRule` `caCertificates` field. If undesired, please use the new `compatibilityVersion` feature to fallback to old behavior, or `insecureSkipVerify` field in `DestinationRule` to skip the verification.
- **将**功能标志“VERIFY_CERT_AT_CLIENT”的默认值更新为“true”。 这意味着在不使用“DestinationRule”“caCertificates”字段时，将使用操作系统 CA 证书自动验证服务器证书。 如果不需要，请使用新的“compatibilityVersion”功能回退到旧行为，或使用“DestinationRule”中的“insecureSkipVerify”字段来跳过验证。

- **Added** the ability for waypoints to run as non-root.
([Issue #46592](https://github.com/istio/istio/issues/46592))
- **添加**航路点以非 root 身份运行的能力。
  ([Issue #46592](https://github.com/istio/istio/issues/46592))

- **Added** a `fallback` field for `PrivateKeyProvider` to support falling back to the default BoringSSL implementation if the private key provider isn’t available.
- **为“PrivateKeyProvider”添加了“后备”字段，以支持在私钥提供程序不可用时回退到默认的 BoringSSL 实现。

- **Added** support to retrieve JWT from cookies.
([Issue #47847](https://github.com/istio/istio/issues/47847))
- **添加**支持从 cookie 检索 JWT。
  ([Issue #47847](https://github.com/istio/istio/issues/47847))

- **Fixed** a bug that made `PeerAuthentication` too restrictive in ambient mode.
- **修复**一个导致“PeerAuthentication”在环境模式下过于严格的错误。

- **Fixed** an issue where `auto-san-validation` was enabled even when SNI was explicitly set in the `DestinationRule`.
- **修复**即使在“DestinationRule”中显式设置 SNI 时也会启用“auto-san-validation”的问题。

- **Fixed** an issue where gateways were unable to fetch JWKS from `jwksUri` in `RequestAuthentication` when `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` was enabled and `PILOT_JWT_ENABLE_REMOTE_JWKS` was set to `hybrid`/`true`/`envoy`.
- **修复**当启用“PILOT_FILTER_GATEWAY_CLUSTER_CONFIG”且“PILOT_JWT_ENABLE_REMOTE_JWKS”设置为“hybrid”/“true”/“envoy”时，网关无法从“RequestAuthentication”中的“jwksUri”获取 JWKS 的问题。

## Telemetry
## 遥测 {#telemetry}

- **Improved** JSON access logs to emit keys in a stable ordering.
- **改进** JSON 访问日志以稳定的顺序发出密钥。

- **Added** support for `brotli`, `gzip`, and `zstd` compression for the Envoy stats endpoint.
([Issue #30987](https://github.com/istio/istio/issues/30987))
- **添加了**对 Envoy stats 端点的 `brotli`、`gzip` 和 `zstd` 压缩的支持。
  ([Issue #30987](https://github.com/istio/istio/issues/30987))

- **Added** the `istio.cluster_id` tag to all tracing spans.
([Issue #48336](https://github.com/istio/istio/issues/48336))
- **向所有跟踪范围添加** `istio.cluster_id` 标签。
  ([Issue #48336](https://github.com/istio/istio/issues/48336))

- **Fixed** a bug where `destination_cluster` reported by client proxies was occasionally incorrect when accessing workloads in a different network.
- **修复**客户端代理报告的“destination_cluster”在访问不同网络中的工作负载时偶尔不正确的错误。

- **Removed** legacy `EnvoyFilter` implementation for Telemetry. For the majority of users, this change has no impact, and was already enabled in previous releases. However, the following fields are no longer respected: `prometheus.configOverride`, `stackdriver.configOverride`, `stackdriver.disableOutbound`, `stackdriver.outboundAccessLogging`.
- **删除了**遥测的旧版“EnvoyFilter”实现。 对于大多数用户来说，此更改没有影响，并且已经在之前的版本中启用。 但是，不再考虑以下字段：`prometheus.configOverride`、`stackdriver.configOverride`、`stackdriver.disableOutbound`、`stackdriver.outboundAccessLogging`。

## Extensibility
## 可扩展性 {#extensibility}

- **Added** support for outbound traffic using the PROXY Protocol. By specifying `proxyProtocol` in a `DestinationRule` `trafficPolicy`, the sidecar will send PROXY Protocol headers to the upstream service. This feature is not supported for HBONE proxy at the present time.
- **添加**使用代理协议的出站流量支持。 通过在“DestinationRule”“trafficPolicy”中指定“proxyProtocol”，sidecar 将向上游服务发送 PROXY 协议标头。 目前 HBONE 代理不支持此功能。

- **Added** support for matching `ApplicationProtocols` in an `EnvoyFilter`.
- **添加**对在“EnvoyFilter”中匹配“ApplicationProtocols”的支持。

- **Removed** support for the `policy/v1beta1` API version of `PodDisruptionBudget`.
- **删除**对“PodDisruptionBudget”的“policy/v1beta1” API 版本的支持。

- **Removed** using the `BOOTSTRAP_XDS_AGENT` experimental feature to apply `BOOTSTRAP` `EnvoyFilter` patches at startup.
- **删除**使用“BOOTSTRAP_XDS_AGENT”实验功能在启动时应用“BOOTSTRAP”“EnvoyFilter”补丁。

## Installation
## 安装 {#installation}

- **Improved** aborting graceful termination logic if the Envoy process terminates early.
([Issue #36686](https://github.com/istio/istio/issues/36686))
- 如果 Envoy 进程提前终止，**改进**中止优雅终止逻辑。
  ([Issue #36686](https://github.com/istio/istio/issues/36686))

- **Updated** Kiali addon to version v1.79.0.
- **更新** Kiali 插件至版本 v1.79.0。

- **Added** configurable scaling behavior for Gateway HPA in the Helm chart. ([usage]( https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior))
- **在 Helm 图表中添加了** Gateway HPA 的可配置扩展行为。 （[用法]（https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior））

- **Added** `allocateLoadBalancerNodePorts` config option to the Gateway chart.
([Issue #48751](https://github.com/istio/istio/issues/48751))
- **添加** `allocateLoadBalancerNodePorts` 配置选项到网关图表。
  ([Issue #48751](https://github.com/istio/istio/issues/48751))

- **Added** a message to indicate the default webhook shifting from a revisioned installation to a default installation.
([Issue #48643](https://github.com/istio/istio/issues/48643))
- **添加**一条消息，指示默认 Webhook 从修订安装转变为默认安装。
  ([Issue #48643](https://github.com/istio/istio/issues/48643))

- **Added** the `affinity` field to Istiod Deployment. This field is used to control the scheduling of Istiod pods.
- **向 Istiod 部署添加** `affinity` 字段。 该字段用于控制 Istiod pod 的调度。

- **Added** `tolerations` field to Istiod Deployment. This field is used to control the scheduling of Istiod pods.
- **向 Istiod 部署添加** `tolerations` 字段。 该字段用于控制 Istiod pod 的调度。

- **Added** support for "profiles" to Helm installation. Try it out with `--set profile=demo`!
  ([Issue #47838](https://github.com/istio/istio/issues/47838))
- **添加了**对 Helm 安装“配置文件”的支持。 使用“--set profile=demo”尝试一下！
  ([Issue #47838](https://github.com/istio/istio/issues/47838))

- **Added** the setting `priorityClassName: system-node-critical` to the ztunnel DaemonSet template to ensure it is running on all nodes.
([Issue #47867](https://github.com/istio/istio/issues/47867))
- **向 ztunnel DaemonSet 模板添加**设置 `priorityClassName: system-node-ritic` 以确保它在所有节点上运行。
  ([Issue #47867](https://github.com/istio/istio/issues/47867))

- **Fixed** an issue where the webhook generated with `istioctl tag set` is unexpectedly removed by the installer.
([Issue #47423](https://github.com/istio/istio/issues/47423))
- **修复**安装程序意外删除使用“istioctl tag set”生成的 webhook 的问题。
  ([Issue #47423](https://github.com/istio/istio/issues/47423))

- **Fixed** an issue where uninstalling Istio didn't prune all the resources created by custom files.
([Issue #47960](https://github.com/istio/istio/issues/47960))
- **修复**卸载 Istio 不会删除自定义文件创建的所有资源的问题。
  ([Issue #47960](https://github.com/istio/istio/issues/47960))

- **Fixed** an issue where injection failed when the name of the Pod or its custom owner exceeded 63 characters.
- **修复**当 Pod 或其自定义所有者的名称超过 63 个字符时注入失败的问题。

- **Fixed** an issue causing Istio CNI to stop functioning on minimal/locked down nodes (such as no `sh` binary). The new logic runs with no external dependencies, and will attempt to continue if errors are encountered (which could be caused by things like SELinux rules). In particular, this fixes running Istio on Bottlerocket nodes.
([Issue #48746](https://github.com/istio/istio/issues/48746))
- **修复**导致 Istio CNI 在最小/锁定节点上停止运行的问题（例如没有“sh”二进制文件）。 新逻辑在没有外部依赖的情况下运行，并且如果遇到错误（这可能是由 SELinux 规则等原因引起的），它将尝试继续。 特别是，这修复了在 Bottlerocket 节点上运行 Istio 的问题。
  ([Issue #48746](https://github.com/istio/istio/issues/48746))

- **Fixed** custom injection of the `istio-proxy` container not working on OpenShift because of the way OpenShift sets pods' `SecurityContext.RunAs` field.
- **修复**“istio-proxy”容器的自定义注入在 OpenShift 上不起作用，因为 OpenShift 设置 pod 的“SecurityContext.RunAs”字段的方式。

- **Fixed** veth lookup for ztunnel pod on OpenShift where default CNIs do not create routes for each veth interface.
- **修复** OpenShift 上 ztunnel pod 的 veth 查找，其中默认 CNI 不会为每个 veth 接口创建路由。

- **Fixed** an issue where installing with Stackdriver and having custom configs would lead to Stackdriver not being enabled.
- **修复了**使用 Stackdriver 安装并使用自定义配置会导致 Stackdriver 无法启用的问题。

- **Fixed** an issue where Endpoint and Service in the istiod-remote chart did not respect the revision value.
([Issue #47552](https://github.com/istio/istio/issues/47552))
- **修复** istiod-remote 图表中的端点和服务不遵守修订值的问题。
  ([Issue #47552](https://github.com/istio/istio/issues/47552))

- **Removed** support for `.Values.cni.psp_cluster_role` as part of installation, as `PodSecurityPolicy` was [deprecated](https://kubernetes.io/blog/2021/04/06/podsecuritypolicy-deprecation-past-present-and-future/).
- **在安装过程中删除**对 `.Values.cni.psp_cluster_role` 的支持，因为 `PodSecurityPolicy` 已[弃用](https://kubernetes.io/blog/2021/04/06/podsecuritypolicy-deprecation- 过去-现在-未来/）。

- **Removed** the `istioctl experimental revision` command. Revisions can be inspected by the stable `istioctl tag list` command.
- **删除** `istioctl 实验修订版`命令。 可以通过稳定的“istioctl tag list”命令检查修订。

- **Removed** the `installed-state` `IstioOperator` that was created when running `istioctl install`. This previously provided only a snapshot of what was installed. However, it was a common source of confusion (as users would change it and nothing would happen), and did not reliably represent the current state. As there is no `IstioOperator` needed for these usages anymore, `istioctl install` and `helm install` no longer install the `IstioOperator` CRD. Note this only impacts `istioctl install`, not the in-cluster operator.
- **删除**运行“istioctl install”时创建的“已安装状态”“IstioOperator”。 之前这仅提供了已安装内容的快照。 然而，它是一个常见的混乱来源（因为用户会更改它，但什么也不会发生），并且不能可靠地代表当前状态。 由于这些用途不再需要“IstioOperator”，“istioctl install”和“helm install”不再安装“IstioOperator” CRD。 请注意，这仅影响“istioctl install”，而不影响集群内的操作员。

## istioctl

- **Improved** injector list to exclude ambient namespaces.
- **改进**注入器列表以排除环境命名空间。

- **Improved** `bug-report` performance by reducing the amount of calls to the k8s API. The pod/node details included in the report will look different, but contain the same information.
- 通过减少对 k8s API 的调用量，**改进**“错误报告”性能。 报告中包含的 Pod/节点详细信息看起来会有所不同，但包含相同的信息。

- **Improved** `istioctl bug-report` to sort gathered events by creation date.
- **改进** `istioctl bug-report` 按创建日期对收集的事件进行排序。

- **Updated** `verify-install` to not require a IstioOperator file, since it is now removed from the installation process.
- **更新** `verify-install` 不再需要 IstioOperator 文件，因为它现在已从安装过程中删除。

- **Added** support for deleting multiple waypoints at once via `istioctl experimental waypoint delete <waypoint1> <waypoint2> ...`.
- **添加**支持通过“istioctl Experimental waypoint delete <waypoint1> <waypoint2> ...”一次删除多个航点。

- **Added** the `--all` flag to `istioctl experimental waypoint delete` to delete all waypoint resources in a given namespace.
- **向“istioctl 实验性航点删除”添加**“--all”标志，以删除给定命名空间中的所有航点资源。

- **Added** an analyzer to warn users if they set the `selector` field instead of the `targetRef` field for specific Istio resources, which will cause the resource to be ineffective.
  ([Issue #48273](https://github.com/istio/istio/issues/48273))
- **添加**一个分析器，警告用户如果为特定 Istio 资源设置了 `selector` 字段而不是 `targetRef` 字段，这将导致资源无效。
  ([Issue #48273](https://github.com/istio/istio/issues/48273))

- **Added** message IST0167 to warn users that policies, such as Sidecar, will have no impact when applied to ambient namespaces.
  ([Issue #48105](https://github.com/istio/istio/issues/48105))
- **添加**消息 IST0167 以警告用户，Sidecar 等策略在应用于环境命名空间时不会产生任何影响。
  ([Issue #48105](https://github.com/istio/istio/issues/48105))

- **Added** bootstrap summary to all config dumps' summary.
- **添加了**引导程序摘要到所有配置转储的摘要中。

- **Added** completion for Kubernetes pods for some commands that can select pods, such as `istioctl proxy-status <pod>`.
- **为 Kubernetes Pod 添加了一些可以选择 Pod 的命令的完成功能，例如 `istioctl proxy-status <pod>`。

- **Added** `--wait` option to the `istioctl experimental waypoint apply` command.
([Issue #46297](https://github.com/istio/istio/issues/46297))
- **为“istioctl Experimental waypoint apply”命令添加了**“--wait”选项。
  ([Issue #46297](https://github.com/istio/istio/issues/46297))

- **Added** `path_separated_prefix` to the MATCH column in the output of `proxy-config routes` command.
- **在“proxy-config paths”命令输出中的 MATCH 列中添加了**“path_separated_prefix”。

- **Fixed** an issue where sometimes control plane revisions and proxy versions were not obtained in the bug report.
- **修复**有时无法在错误报告中获取控制平面修订版和代理版本的问题。

- **Fixed** an issue where `istioctl tag list` command didn't accept `--output` flag.
  ([Issue #47696](https://github.com/istio/istio/issues/47696))
- **修复** `istioctl tag list` 命令不接受 `--output` 标志的问题。
  ([Issue #47696](https://github.com/istio/istio/issues/47696))

- **Fixed** an issue where the default namespace of Envoy and proxy dashboard command was not set to the actual default namespace.
- **修复** Envoy 和代理仪表板命令的默认命名空间未设置为实际默认命名空间的问题。

- **Fixed** an issue where the IST0158 message was incorrectly reported when the `imageType` field was set to `distroless` in mesh config.
  ([Issue #47964](https://github.com/istio/istio/issues/47964))
- **修复**当网格配置中的“imageType”字段设置为“distroless”时，错误报告 IST0158 消息的问题。
  ([Issue #47964](https://github.com/istio/istio/issues/47964))

- **Fixed** an issue where `istioctl experimental version` has no proxy info shown.
- **修复**“istioctl 实验版本”没有显示代理信息的问题。

- **Fixed** an issue where the IST0158 message was incorrectly reported when the `imageType` field was set by the `ProxyConfig` resource, or the resource annotation `proxy.istio.io/config`.
- **修复**当“imageType”字段由“ProxyConfig”资源或资源注释“proxy.istio.io/config”设置时，错误报告 IST0158 消息的问题。

- **Fixed** an issue where `proxy-config ecds` didn't show all of `EcdsConfigDump`.
- **修复了** `proxy-config ecds` 未显示所有 `EcdsConfigDump` 的问题。

- **Fixed** injector list having duplicated namespaces shown for the same injector hook.
- **修复**注入器列表具有为同一注入器挂钩显示的重复名称空间。

- **Fixed** `analyze` not working correctly when analyzing files containing resources that already exist in the cluster.
([Issue #44844](https://github.com/istio/istio/issues/44844))
- **修复**“分析”在分析包含集群中已存在资源的文件时无法正常工作。
  ([Issue #44844](https://github.com/istio/istio/issues/44844))

- **Fixed** `analyze` where it was reporting errors for empty files.
([Issue #45653](https://github.com/istio/istio/issues/45653))
- **修复**“分析”报告空文件错误的问题。
  ([Issue #45653](https://github.com/istio/istio/issues/45653))

- **Fixed** an issue where the External Control Plane Analyzer was not working in some remote control plane setups.
- **修复**外部控制平面分析器在某些远程控制平面设置中无法工作的问题。

- **Removed** the `--rps-limit` flag for `istioctl bug-report` and **added** the `--rq-concurrency` flag. The bug reporter will now limit request concurrency instead of limiting request rate to the Kube API.
- **删除了** `istioctl bug-report` 的 `--rps-limit` 标志，并 **添加了** `--rq-concurrency` 标志。 错误报告者现在将限制请求并发数，而不是限制对 Kube API 的请求速率。

## Documentation changes
## 文档变更

- **Fixed** `httpbin` sample manifests to deploy correctly on OpenShift.
- **修复** `httpbin` 示例清单以在 OpenShift 上正确部署。
