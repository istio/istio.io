---
title: Istio 1.21.0 更新说明
linktitle: 1.21.0
subtitle: 次要版本
description: Istio 1.21.0 更新说明。
publishdate: 2024-02-28
release: 1.21.0
weight: 10
aliases:
    - /zh/news/announcing-1.21.0
---

## 流量治理 {#traffic-management}

- **改进** 改进了 pilot-agent ，使其能从容器中的探针设置返回 HTTP 探针的响应体和状态码。

- **改进** 改进了对 `ExternalName` 服务的支持。
  有关详细信息，请参阅升级说明。

- **改进** 改进了变量 `PILOT_MAX_REQUESTS_PER_SECOND`（限制传入请求的速率，之前默认为 25.0）
  和 `PILOT_PUSH_THROTTLE`（限制并发响应数量，之前默认为 100），
  如果没有明确配置则自动随 Istiod 所运行的 CPU 大小进行扩展。

- **新增** 添加了在各种防火墙规则中配置 `istio-iptables` 使用 IPv4 环回 CIDR 的功能。
  ([Issue #47211](https://github.com/istio/istio/issues/47211))

- **新增** 添加了当设置网络拓扑之前将工作负载添加到 Ambient 网格，自动设置工作负载默认网络的支持。
  之前，当您在 Istio 根命名空间上设置 `topology.istio.io/network` 时，
  您需要手动重新部署 Ambient 工作负载以使网络变更生效。
  现在，即使 Ambient 工作负载没有网络标签，网络也会自动被更新。
  请注意，如果您的 ztunnel 与您在 Istio 根命名空间的 `topology.istio.io/network`
  标签中设置的网络不在同一网络中，则您的 Ambient 工作负载将无法相互通信。

- **新增** 添加了网关部署控制器上的命名空间发现选择器 `discoverySelectors` 支持。
  它受到 `ENABLE_ENHANCED_RESOURCE_SCOPING` 的保护。
  启用后，网关控制器将仅监视与选择器匹配的 k8s 网关。
  请注意，它将影响网关和 waypoint 部署。

- **新增** 添加了对 delta ADS 客户端的支持。

- **新增** 添加了对并发 `SidecarScope` 转换的支持。
  您可以使用 `PILOT_CONVERT_SIDECAR_SCOPE_CONCURRENCY` 来调整并发执行的数量。
  它的默认值为 1，表示不会并发执行。当 `initSidecarScopes` 消耗大量时间，
  并且希望通过增加 CPU 消耗来减少时间消耗时，可以通过增加
  `PILOT_CONVERT_SIDECAR_SCOPE_CONCURRENCY` 的值来增加并发执行数。

- **新增** 添加了在虚拟服务的 `HTTPRouteDestination` 中设置 `:authority` 标头的支持。
  现在，我们支持 `host` 和 `:authority` 的主机重写。

- **新增** 为 `WasmPlugin` 资源名称添加了前缀。

- **新增** 添加了在出站流量的 `TcpProxy` 过滤器中设置 `idle_timeout` 的支持。

- **新增** 添加了对[集群内网关部署](https://gateway-api.sigs.k8s.io/geps/gep-1762/)的支持。
  部署的 Pod 和服务现在同时具有 `istio.io/gateway-name` 和 `gateway.networking.k8s.io/gateway-name` 标签。

- **新增** 添加了对 HTTP2 连接的 `DestinationRule` 的 HTTP 流量策略中最大并发流设置的支持。
  ([Issue #47166](https://github.com/istio/istio/issues/47166))

- **新增** 添加了为 HTTP 服务设置 TCP 空闲超时的支持。

- **新增** 对 `Sidecar` API 添加了连接池设置，以便为网格中的 Sidecar 配置入站连接池。
  之前，`DestinationRule` 的连接池设置适用于客户端和服务器 Sidecar。
  使用更新后的 `Sidecar` API，现在可以在网格中与客户端分开配置服务器的连接池。
  ([参考](/zh/docs/reference/config/networking/sidecar/#Sidecar-inbound_connection_pool))
  ([Issue #32130](https://github.com/istio/istio/issues/32130))、
  ([Issue #41235](https://github.com/istio/istio/issues/41235))

- **新增** 在 `DestinationRule` API 中的 TCP 设置中添加`idle_timeout`，
  用于为每个 `TcpProxy` 过滤器配置开启空闲超时。

- **启用** 启用了 Envoy 配置用于在集群更新时从 istiod 发送端点配置出现延迟时使用端点缓存。

- **修复** 修复了当选择通配符服务时（例如在 `ServiceEntry` 中），
  `VirtualService` 中重叠的通配符主机会产生不正确的路由配置的错误。
  ([Issue #45415](https://github.com/istio/istio/issues/45415))

- **修复** 修复了 `WasmPlugin` 资源未被正确应用于 waypoint 的问题。
  ([Issue #47227](https://github.com/istio/istio/issues/47227))

- **修复** 修复了有时 waypoint 网络配置不正确的问题。

- **修复** 修复了 `pilot-agent istio-clean-iptables`
  命令无法清理为 Istio DNS 代理生成的 iptables 规则的问题。
  ([Issue #47957](https://github.com/istio/istio/issues/47957))

- **修复** 修复了在初始 `WorkloadEntry` 创建后不久发生自动注册和清理时，
  自动注册 `WorkloadEntry` 资源清理缓慢的问题。
  ([Issue #44640](https://github.com/istio/istio/issues/44640))

- **修复** 修复了 Istio 在扩展时对 `StatefulSets` / 无头`Service` 端点执行额外的 xDS 推送的问题。
  ([Issue #48207](https://github.com/istio/istio/issues/48207))

- **修复** 修复了删除远程集群或轮换 `kubeConfig` 时导致内存泄漏的问题。
  ([Issue #48224](https://github.com/istio/istio/issues/48224))

- **修复** 修复了如果 `DestinationRule`
  的 `exportTo` 包含工作负载的当前命名空间（不是 '.'），则`exportTo` 会忽略其他命名空间的问题。
  ([Issue #48349](https://github.com/istio/istio/issues/48349))

- **修复** 修复了启用双栈时未正确创建 QUIC 侦听器的问题。
  ([Issue #48336](https://github.com/istio/istio/issues/48336))

- **修复** 修复了 `convertToEnvoyFilterWrapper`
  返回无效补丁的问题，该补丁在应用时可能会导致空指针异常。

- **修复** 修复了更新服务的 `targetPort` 不会触发 xDS 推送的问题。
  ([Issue #48580](https://github.com/istio/istio/issues/48580))

- **修复** 修复了在没有配置更改时不必要地执行集群内分析的问题。
  ([Issue #48665](https://github.com/istio/istio/issues/48665))

- **修复** 修复了一个错误，该错误会导致没有关联服务（包括同一命名空间内的所有服务）的 Pod 错误生成配置。
  这有时会导致入站侦听器冲突错误。

- **修复** 修复了新端点可能无法被发送到代理的问题。
  ([Issue #48373](https://github.com/istio/istio/issues/48373))

- **修复** 修复了 Gateway API `AllowedRoutes` 对 `NotIn` 和 `DoesNotExist` 标签选择器匹配表达式的处理问题。
  ([Issue #48044](https://github.com/istio/istio/issues/48044))

- **修复** 修复了设置 `header-name: {}` 时，`VirtualService` HTTP 标头当前匹配不起作用的问题。
  ([Issue #47341](https://github.com/istio/istio/issues/47341))

- **修复** 修复了多集群领导者选举不优先考虑本地领导者而是远程领导者的问题。
  ([Issue #47901](https://github.com/istio/istio/issues/47901))

- **修复** 修复了 `hostNetwork` Pod 扩缩时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **修复** 修复了 `WorkloadEntry` 更改其 IP 地址时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **修复** 修复了删除 `ServiceEntry` 时内存泄漏的问题。
  ([Issue #47893](https://github.com/istio/istio/issues/47893))

- **升级** 通过切换到 in-Pod 机制，提升 Ambient 流量捕获和重定向兼容性。
  ([Issue #48212](https://github.com/istio/istio/issues/48212))

- **移除** 移除了 `PILOT_ENABLE_INBOUND_PASSTHROUGH` 环境变量，该变量在过去 8 个版本中默认启用。

## 安全性 {#security}

- **改进** 改进了请求 JWT 身份验证以使用上游 Envoy JWT 过滤器而不是自定义 Istio 代理过滤器的逻辑。
  由于需要新的上游 JWT 过滤器功能，因此该功能针对支持它们的代理进设置了功能门控。
  请注意，使用 `istio_authn` 动态元数据名称的自定义 Envoy 或 Wasm
  过滤器需要更新为使用 `envoy.filters.http.jwt_authn` 动态元数据名称。

- **更新** 将功能标志 `ENABLE_AUTO_SNI` 的默认值更新为 `true`。
  如果不需要该功能，请使用新的 `compatibilityVersion` 功能回退到旧版本行为。

- **更新** 将功能标志 `VERIFY_CERT_AT_CLIENT` 的默认值更新为 `true`。
  这意味着在不使用 `DestinationRule` `caCertificates` 字段时，
  将使用操作系统 CA 证书自动验证服务器证书。如果不需要该功能，
  请使用新的 `compatibilityVersion` 功能回退到旧版本行为，
  或使用 `DestinationRule` 中的 `insecureSkipVerify` 字段来跳过验证。

- **新增** 添加了 waypoint 以非 root 身份运行的能力。
  ([Issue #46592](https://github.com/istio/istio/issues/46592))

- **新增** 为 `PrivateKeyProvider` 添加了 `fallback` 字段，
  用于支持在私钥提供程序不可用时回退到默认的 BoringSSL 实现。

- **新增** 添加了从 cookie 中检索 JWT 的支持。
  ([Issue #47847](https://github.com/istio/istio/issues/47847))

- **修复** 修复了一个导致 `PeerAuthentication` 在 Ambient 模式下过于严格的错误。

- **修复** 修复了即使在 `DestinationRule` 中显式设置 SNI 时也会启用 `auto-san-validation` 的问题。

- **修复** 修复了当启用 `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG`
  且 `PILOT_JWT_ENABLE_REMOTE_JWKS` 设置为 `hybrid` / `true` / `envoy` 时，
  网关无法从 `RequestAuthentication` 中的 `jwksUri` 获取 JWKS 的问题。

## 遥测 {#telemetry}

- **改进** 改进了 JSON 访问日志以稳定的顺序发出关键字。

- **新增** 添加了对 Envoy 统计数据端点的 `brotli`、`gzip` 和 `zstd` 压缩的支持。
  ([Issue #30987](https://github.com/istio/istio/issues/30987))

- **新增** 向所有链路 Span 添加了 `istio.cluster_id` 标签。
  ([Issue #48336](https://github.com/istio/istio/issues/48336))

- **修复** 修复了客户端代理报告的 `destination_cluster`
  在访问不同网络中的工作负载时偶尔不正确的错误。

- **移除** 移除了遥测的旧版 `EnvoyFilter` 实现。
  对于大多数用户来说，此更改没有影响，并且已经在之前的版本中启用。
  然而，以下字段将不再被遵循：`prometheus.configOverride`、`stackdriver.configOverride`、`stackdriver.disableOutbound`、`stackdriver.outboundAccessLogging`。

## 可扩展性 {#extensibility}

- **新增** 添加了使用代理协议的出站流量支持。
  通过在 `DestinationRule` `trafficPolicy` 中指定 `proxyProtocol`，
  Sidecar 将向上游服务发送 PROXY 协议标头。目前 HBONE 代理不支持此功能。

- **新增** 添加了在 `EnvoyFilter` 中匹配 `ApplicationProtocols` 的支持。

- **移除** 移除了对 `PodDisruptionBudget` 的 `policy/v1beta1` API 版本的支持。

- **移除** 移除了使用 `BOOTSTRAP_XDS_AGENT` 实验功能在启动时应用 `BOOTSTRAP` `EnvoyFilter` 补丁的功能。

## 安装 {#installation}

- **改进** 如果 Envoy 进程提前终止，则停止优雅终止逻辑。
  ([Issue #36686](https://github.com/istio/istio/issues/36686))

- **更新** 更新了 Kiali 插件至版本 v1.79.0。

- **新增** 在 Helm Chart 中添加了 Gateway HPA 的可配置扩展行为。
  ([使用方法](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior))

- **新增** 在 Gateway Chart 中添加了 `allocateLoadBalancerNodePorts` 配置选项。
  ([Issue #48751](https://github.com/istio/istio/issues/48751))

- **新增** Webhook 从修订安装转变为默认安装时，添加一条消息指示。
  ([Issue #48643](https://github.com/istio/istio/issues/48643))

- **新增** 向 Istiod 部署中添加了 `affinity` 字段。该字段用于控制 Istiod Pod 的调度。

- **新增** 向 Istiod 部署中添加了 `tolerations` 字段。该字段用于控制 Istiod Pod 的调度。

- **新增** 添加了对 Helm 安装的 `profiles` 的支持。尝试使用 `--set profile=demo`！
  ([Issue #47838](https://github.com/istio/istio/issues/47838))

- **新增** 向 ztunnel DaemonSet 模板添加了设置
  `priorityClassName: system-node-ritic` 以确保它在所有节点上运行。
  ([Issue #47867](https://github.com/istio/istio/issues/47867))

- **修复** 修复了安装程序意外删除使用 `istioctl tag set` 生成的 Webhook 的问题。
  ([Issue #47423](https://github.com/istio/istio/issues/47423))

- **修复** 修复了卸载 Istio 不会删除自定义文件创建的所有资源的问题。
  ([Issue #47960](https://github.com/istio/istio/issues/47960))

- **修复** 修复了当 Pod 或其自定义所有者的名称超过 63 个字符时注入失败的问题。

- **修复** 修复了导致 Istio CNI 在最小/锁定节点上停止运行的问题（例如没有 `sh` 二进制文件）。
  新逻辑无需任何外部依赖即可运行，并且如果遇到错误（这可能是由 SELinux 规则等原因引起的），
  它将尝试继续运行。特别指出，这修复了在 Bottlerocket 节点上运行 Istio 的问题。
  ([Issue #48746](https://github.com/istio/istio/issues/48746))

- **修复** 修复了在 OpenShift 上自定义注入`istio-proxy` 容器不起作用的问题，
  是由于 OpenShift 对 Pod 的 `SecurityContext.RunAs` 字段设置方式导致。

- **修复** 修复了 OpenShift 上 ztunnel Pod 的 veth 查找问题，
  其中默认 CNI 不会为每个 veth 接口创建路由。

- **修复** 修复了使用 Stackdriver 安装并使用自定义配置会导致 Stackdriver 无法启用的问题。

- **修复** 修复了 istiod-remote Chart 中的端点和服务不遵守修订值的问题。
  ([Issue #47552](https://github.com/istio/istio/issues/47552))

- **移除** 在安装过程中移除了对 `.Values.cni.psp_cluster_role` 的支持，
  因为 `PodSecurityPolicy` 已被[弃用](https://kubernetes.io/zh-cn/blog/2021/04/06/podsecuritypolicy-deprecation-past-present-and-future/)。

- **移除** 移除了 `istioctl experimental revision` 命令。
  可以通过稳定的 `istioctl tag list` 命令检查修订。

- **移除** 移除了运行 `istioctl install` 时创建的 `installed-state` `IstioOperator`。
  之前这仅提供了已安装内容的快照。然而，它是一个常见的混淆来源（因为用户会更改它，但什么也不会发生），
  并且不能可靠地代表当前状态。由于这些用途不再需要 `IstioOperator`，
  `istioctl install` 和 `helm install` 不再安装`IstioOperator` CRD。
  请注意，这仅影响 `istioctl install`，而不影响 in-cluster Operator。

## istioctl

- **改进** 改进了注入器列表以排除 Ambient 命名空间。

- **改进** 通过减少对 k8s API 的调用量，改进了 `istioctl bug-report` 性能。
  报告中包含的 Pod / 节点详细信息看起来会有所不同，但包含相同的信息。

- **改进** 改进了 `istioctl bug-report` 按照创建日期对收集的事件进行排序。

- **更新** 更新了 `verify-install` 不再需要 IstioOperator 文件，因为它现在已从安装过程中删除。

- **新增** 添加了支持通过
  `istioctl experimental waypoint delete <waypoint1> <waypoint2> ...` 一次删除多个 waypoint 的功能。

- **新增** 向 `istioctl experimental waypoint delete`
  添加 `--all` 标志，用于删除给定命名空间中的所有 waypoint 资源。

- **新增** 添加了一个分析器，警告用户如果为特定 Istio 资源设置了 `selector`
  字段而不是 `targetRef` 字段，这将导致资源无效。
  ([Issue #48273](https://github.com/istio/istio/issues/48273))

- **新增** 添加了消息 IST0167 以警告用户，
  Sidecar 等策略在应用于 Ambient 命名空间时不会产生任何影响。
  ([Issue #48105](https://github.com/istio/istio/issues/48105))

- **新增** 添加了引导程序摘要到所有配置转储的摘要中。

- **新增** 对某些可以选择 pod 的命令的 Kubernetes pod 的自动补全，
  例如 `istioctl proxy-status <pod>`。

- **新增** 为 `istioctl experimental waypoint apply`
  命令添加了 `--wait` 选项。
  ([Issue #46297](https://github.com/istio/istio/issues/46297))

- **新增** 在 `proxy-config routes` 命令输出中的 MATCH
  列中添加了 `path_separated_prefix`。

- **修复** 修复了有时无法在错误报告中获取控制平面修订版和代理版本的问题。

- **修复** 修复了 `istioctl tag list` 命令不接受 `--output` 标志的问题。
  ([Issue #47696](https://github.com/istio/istio/issues/47696))

- **修复** 修复了 Envoy 和代理仪表板命令的默认命名空间未设置为实际默认命名空间的问题。

- **修复** 修复了当网格配置中的 `imageType` 字段设置为 `distroless` 时，
  错误报告 IST0158 消息的问题。
  ([Issue #47964](https://github.com/istio/istio/issues/47964))

- **修复** 修复了 `istioctl experimental version` 没有显示代理信息的问题。

- **修复** 修复了当 `imageType` 字段由 `ProxyConfig`
  资源或资源注解 `proxy.istio.io/config` 设置时，错误报告 IST0158 消息的问题。

- **修复** 修复了 `proxy-config ecds` 未显示所有 `EcdsConfigDump` 的问题。

- **修复** 修复了注入器列表具有为同一注入器 Hook 显示重复命名空间的问题。

- **修复** 修复了 `analyze` 在分析包含集群中已存在资源的文件时无法正常工作的问题。
  ([Issue #44844](https://github.com/istio/istio/issues/44844))

- **修复** 修复了当分析的文件中没有内容时 `analyze` 报告错误的问题。
  ([Issue #45653](https://github.com/istio/istio/issues/45653))

- **修复** 修复了外部控制平面分析器在某些远程控制平面设置中无法工作的问题。

- **移除** 移除了 `istioctl bug-report` 的 `--rps-limit` 标志，并 **添加** `--rq-concurrency` 标志。
  错误报告者现在将限制请求并发数，而不是限制对 Kube API 的请求速率。

## 文档变更 {#documentation-changes}

- **修复** 修复了 `httpbin` 示例清单以在 OpenShift 上正确部署。
