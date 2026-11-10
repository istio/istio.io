---
title: Istio 1.32.0 更新说明
linktitle: 1.32.0
subtitle: 主要版本
description: Istio 1.32.0 更新说明。
publishdate: 2026-11-09
release: 1.32.0
weight: 10
aliases:
    - /zh/news/announcing-1.32.0
---

## 流量治理 {#traffic-management}

- **改进** 改进了增量 xDS 的内存使用：通配符 WDS 订阅不再累积后续请求中的资源名称，
  并且对于不使用重连时所发送的 `initial_resource_versions` 映射的类型，
  该映射会在生成响应之前被释放。

- **改进** 改进了针对 `DestinationRule` 变更的增量 EDS 处理，现在通过 Sidecar 作用域识别受影响的服务，
  与 CDS 保持一致，并避免了按集群查找 `DestinationRule`。

- **改进** 改进了为指定工作负载获取 `PeerAuthentication` 资源时的性能。

- **改进** 改进了 Sidecar RDS 生成的性能，现在会在构建 `VirtualHostWrapper`/路由 proto 之前先检查 RDS 缓存，
  因此缓存命中时不再需要付出生成路由的开销。为实现这一点，RDS 缓存键现在基于可能影响该路由的
  `DestinationRule` 的保守超集来计算（而不是仅基于最终过滤后的构建所使用的精确集合）。
  因此，一些无关的 `DestinationRule` 变更（尤其是带有通配符主机的变更）现在可能会触发 RDS 缓存失效
  （以及一次额外的推送），而这在以前是可以避免的。这不会影响正确性，只会影响原本不必要的缓存失效的频率。

- **更新** 更新了 OpenShift 平台配置文件，对于 Sidecar 和 Ambient 模式安装，
  `global.nativeNftables` 默认均为 `true`。仍可以通过显式设置 `global.nativeNftables=false` 来覆盖。

- **新增** 新增了一项可选启用的无头 TCP 服务监听器生成优化：Istio 可以生成单个通配符 `0.0.0.0:Port` 监听器，
  并为每个 Pod 配置 `/32` CIDR 过滤器链，而不是为每个 Pod IP 创建一个监听器。
  这减少了大型无头服务（例如 `StatefulSet` 资源）的 xDS 监听器数量和负载大小。
  此功能默认禁用；可在 istiod 上将 `PILOT_ENABLE_HEADLESS_FILTER_CHAIN_LISTENER` 环境变量设置为 `true` 来启用。
  ([Issue #60552](https://github.com/istio/istio/issues/60552))

- **新增** 在 `DestinationRule.OutlierDetection` 中新增了 `outlierDetectionHttpErrorCodes` 字段，
  允许用户指定在异常值检测中哪些 HTTP 状态码被视为错误。如果指定了该字段，
  则只有带有这些状态码之一的响应才会被计为错误，并计入 `consecutive5xxErrors`
  和 `consecutiveGatewayErrors` 驱逐阈值。如果未指定，则只有 5xx 响应会被计为错误。
  ([Issue #60828](https://github.com/istio/istio/issues/60828))

- **新增** 新增了对 Gateway API `XBackend` 资源的实验性支持，该资源用于描述客户端连接到特定目标时必须采用的行为。
  对 `ClientAndServer` Backend TLS 模式的支持目前处于禁用状态。
  ([Issue #60747](https://github.com/istio/istio/issues/60747))

- **新增** 新增了针对以下 `ServiceEntry` 地址的验证警告：全匹配地址（`0.0.0.0`、`::`）、
  未指定网络的地址（`0.0.0.0/N`、`::/N`），或前缀短于 `/8` 的 CIDR。
  这样的 `ServiceEntry` 如果使用 `resolution: NONE` 和默认的 `exportTo`，
  可能会使网格中的每个 Sidecar 透传其端口上的流量，从而绕过 `outboundTrafficPolicy` `REGISTRY_ONLY`。
  请使用范围更窄的 CIDR 和 `exportTo: ["."]`。如需强制执行出口控制，请将出口网关与 `NetworkPolicy` 结合使用。

- **新增** 在 `/debug/adsz` 端点中新增了按类型划分的监视摘要（资源名称数量和通配符标志），
  以及一个 `?brief` 参数，用于省略被监视的资源名称列表，因为在大型网格中这些列表可能非常大。

- **新增** 新增了在使用 `agentgateway` 时对 Gateway API 客户端证书 TLS 配置的支持。
  `Gateway` 资源现在会遵循前端客户端证书验证（`spec.tls.frontend`，包括 `AllowInsecureFallback` 模式）
  和后端客户端证书（`spec.tls.backend.clientCertificateRef`），
  并在状态中报告相应的 `ResolvedRefs` 和 `InsecureFrontendValidationMode` 条件。

- **新增** 在 `DestinationRule` 中新增了 `backendUtilization` 负载均衡策略。
  该策略使用后端通过 ORCA 负载报告上报的利用率来动态设置端点权重，
  使上报利用率较高的端点按比例接收较少的请求。
  此功能基于 Envoy 的 `client_side_weighted_round_robin` 负载均衡策略实现。
  ([Issue #60814](https://github.com/istio/istio/issues/60814))

- **新增** 新增了通过 `ProxyConfig` 中的 `connectionSettings` 配置集群级连接缓冲区限制
  （`clusterPerConnectionBufferLimitBytes`）的支持，包括网关代理的 `EDGE` 配置文件默认值。

- **新增** 新增了 `defaultInboundHttpRetryPolicy` 网格配置字段，用于配置应用于 Sidecar 入站路由的默认重试策略。
  以前，该策略被硬编码为在 `reset-before-request` 时重试 2 次，并且无法调整或关闭。
  只有 `attempts`、`retryOn` 和 `backoff` 会生效；设置 `defaultInboundHttpRetryPolicy: {}` 会在整个网格范围内禁用入站重试。

- **新增** 为 `EnvoyFilter` 新增了 `MERGE_AND_REPLACE_LIST` 补丁操作。其行为与 `MERGE` 类似，
  不同之处在于补丁中出现的重复（列表）字段会完全替换所生成配置中的对应列表，而不是追加到该列表中。
  此操作适用于 `CLUSTER`、`LISTENER`、`FILTER_CHAIN`、`ROUTE_CONFIGURATION`、`VIRTUAL_HOST`、
  `HTTP_ROUTE`、`NETWORK_FILTER`、`HTTP_FILTER` 和 `LISTENER_FILTER` 补丁目标，
  包括嵌套在 `Any` 类型配置（例如过滤器的 `typed_config`）中的列表。

- **新增** 新增了在 `EnvoyFilter` 过滤器链匹配中对 `transportSocket` 字段的支持，
  允许补丁根据过滤器链所配置的传输套接字来选择过滤器链，
  例如针对终止 TLS 的过滤器链使用 `envoy.transport_sockets.tls`。
  与匹配过滤器链所接受流量的 `transportProtocol` 不同，该字段匹配的是处理连接字节的扩展。

- **新增** 新增了在 Ambient 东西向网关（`istio-east-west` `GatewayClass`）上对 `AUTO_PASSTHROUGH` 监听器的支持。
  端口 15443 上的 TLS 透传监听器（或任何使用 `gateway.istio.io/listener-protocol: auto-passthrough` 选项的端口）
  现在会与 HBONE 监听器一起为 Sidecar 多网络流量提供服务，
  因此 Ambient 和 Sidecar 混合网格不再需要在每个集群中部署两个东西向网关。
  此功能要求启用 `AMBIENT_ENABLE_MULTI_NETWORK`。
  ([Issue #60887](https://github.com/istio/istio/issues/60887))

- **新增** 在 `DestinationRule.OutlierDetection` 中新增了 `failurePercentageThreshold` 字段，
  允许根据主机在分析 `interval` 内的失败率来驱逐主机，而不要求连续失败。
  与 `consecutive5xxErrors` 和 `consecutiveGatewayErrors` 不同，主机的错误不需要连续发生，
  因此即使失败请求与成功请求交替出现，失败率较高的主机仍会被驱逐。

- **新增** 新增了通过 `Gateway` 资源的 `alpnProtocols` 字段覆盖终止 TLS 的网关所通告的 ALPN 协议的支持。

- **新增** 新增了在 `ProxyConfig.connectionSettings` 中对 `globalDownstreamConnectionLimit` 的支持，
  为配置全局下游连接限制提供了一等 API 字段。
  该字段的优先级高于现有的 `ISTIO_META_GLOBAL_DOWNSTREAM_MAX_CONNECTIONS` 元数据
  以及已弃用的 `overload.global_downstream_max_connections` 运行时标志。
  ([Issue #57973](https://github.com/istio/istio/issues/57973))

- **新增** 新增了将网格根命名空间中带有工作负载选择器的 `ProxyConfig` 资源应用于所有命名空间中匹配工作负载的支持。
  工作负载自身命名空间中匹配的工作负载级 `ProxyConfig` 优先于根命名空间中的配置。

- **新增** 新增了在 Sidecar 上为通过 HBONE 到达的流量合成 `x-forwarded-client-cert` 的功能。

- **修复** 修复了 Ambient 节点去污点控制器在仅 `istio-cni` 就绪时就移除 `cni.istio.io/not-ready` 污点的问题。
  现在该控制器还会等待节点上的 ztunnel 就绪，从而避免将 Pod 调度到 ztunnel 仍处于卡死状态的节点上。
  可以通过设置 `PILOT_NODE_UNTAINT_CHECK_ZTUNNEL=false` 禁用此行为，并且仅在启用 Ambient 时适用。
  ([Issue #52073](https://github.com/istio/istio/issues/52073))

- **修复** 修复了为入口网关启用 Ambient 多网络后，入口网关到 Sidecar Pod 的路由被破坏的问题；
  该问题导致 Sidecar 和 Ambient 无法在同一个 Istio 多网络部署中共存。
  ([Issue #60609](https://github.com/istio/istio/issues/60609))

- **修复** 修复了使用 `OPTIONAL_MUTUAL` TLS 终止模式的 Gateway API 监听器无法为 SDS 授权客户端 CA Secret，
  导致验证上下文卡在 WARMING 状态的问题。现在对于 `OPTIONAL_MUTUAL`，
  CA 证书引用的授权方式与 `MUTUAL` 已有的授权方式相同。
  ([Issue #60618](https://github.com/istio/istio/issues/60618))

- **修复** 修复了地址为 CIDR 的 `ServiceEntry` 会在 0.0.0.0 通配符上为保留的代理端口
  （例如出站捕获端口 15001）生成出站监听器的问题。该通配符监听器与 `virtualOutbound` 监听器冲突，
  导致整个监听器更新被拒绝，Sidecar 无法启动。现在会跳过此类端口，与具有具体地址的服务的行为保持一致。
  ([Issue #60666](https://github.com/istio/istio/issues/60666))

- **修复** 修复了 Ambient 模式下 CNI 节点代理自动检测到的 `iptables` 后端（`legacy` 与 `nft`）
  可能会在代理重启之间来回切换，从而导致向已加入的 Pod 写入重复重定向规则的问题。
  ([Issue #61020](https://github.com/istio/istio/issues/61020))

- **修复** 修复了无头服务的 NDS 名称表生成，现在会包含所有服务端口的端点，而不仅仅是第一个端口的端点。
  以前，当 Kubernetes 按端口子集拆分 `EndpointSlice` 资源时（例如不同 Pod 池中的 `targetPort` 名称不同），
  只有出现在第一个端口切片中的 Pod 才会被包含在 DNS 名称表中，
  导致远程集群上其他 Pod 的逐 Pod 主机名返回 `NXDOMAIN`。
  ([Issue #61038](https://github.com/istio/istio/issues/61038))

- **修复** 修复了 istiod CPU 使用率随 `AuthorizationPolicy` 资源数量增加而上升的问题。
  ([Issue #61254](https://github.com/istio/istio/issues/61254))

- **修复** 修复了在仅 IPv6 的集群中 `ALLOW_ANY_DYNAMIC_DNS` 流量失败的问题，
  原因是 Envoy 使用 IPv4 环回地址访问 DNS 代理。
  ([Issue #61330](https://github.com/istio/istio/issues/61330))

- **修复** 修复了将 `outlierDetection` 应用于 DNS 代理（DFP）通配符集群时发生 Panic 的问题。
  由 `buildDFPCluster` 构建的集群上的 `CommonLbConfig` 为 nil，因此设置 `HealthyPanicThreshold` 时会解引用空指针。
  现在会为 DFP 集群和 allow-any DFP 集群都初始化该字段，并在赋值前进行 nil 检查。
  ([Issue #61450](https://github.com/istio/istio/issues/61450))

- **修复** 修复了 istiod 在向 Envoy 代理推送工作负载元数据时重复序列化同一工作负载的问题。
  ([Issue #61502](https://github.com/istio/istio/issues/61502))

- **修复** 修复了带有多个 `InferencePool` `backendRefs` 的 `HTTPRoute` 规则只配置了一个端点选择器的问题。
  列出的最后一个 `backendRef` 的选择器会对该规则上的每个请求进行评分，因此其他池的选择器永远不会被调用，
  并且没有就绪端点的池会导致整个规则失败，而不仅仅是其自身的加权份额失败。
  现在每个池都有自己的选择器，并挂接到其自己的加权集群上。
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **修复** 修复了同一网关上共享相同 `rules[].name` 的两个 `HTTPRoute` 会相互覆盖端点选择器的问题。
  规则名称只需要在单个 `HTTPRoute` 内唯一，但选择器在所有 `HTTPRoute` 中按名称作为键，
  因此一个路由可能会由另一个路由的选择器提供服务。现在选择器会按 `backendRef` 解析，
  因此共享名称不会再将一个路由的选择器转移到另一个路由上。
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **修复** 修复了路由规则在同时带有 CORS 过滤器时会丢失其 `InferencePool` 端点选择器的问题。
  两者会被写入同一个逐过滤器配置中，而 CORS 路径会替换该映射，而不是向其中添加内容。
  ([Issue #61594](https://github.com/istio/istio/issues/61594))

- **修复** 修复了当 Pod 状态中包含无效 IP 地址时 Istio CNI 代理发生 Panic 的问题。
  现在会记录并跳过无效地址。

- **修复** 修复了带有 HBONE 监听器的 `Gateway` 资源被作为 mTLS 网关发送给 Sidecar 的问题。
  ([Issue #61618](https://github.com/istio/istio/issues/61618))

- **修复** 修复了在启用 `AMBIENT_SCOPED_ADDRESS_PUSHES`（默认启用）时，
  订阅工作负载元数据发现（MDS）的 Envoy 代理无法收到仅 Address 变更的增量工作负载更新的问题。

- **修复** 修复了 istiod 在以下情况下发生 `panic` 的问题：为 `resolution: DNS` 且 `endpoints`
  跨越多个 `locality` 的 `ServiceEntry` 生成 `STRICT_DNS`/`LOGICAL_DNS` 集群，
  同时存在设置了 `trafficPolicy.loadBalancer.localityLbSetting.failoverPriority` 的 `DestinationRule`。
  以前，一旦受影响的代理连接，istiod 就会崩溃并陷入崩溃循环，导致任何配置都无法推送。
  ([Issue #61857](https://github.com/istio/istio/issues/61857))

- **修复** 修复了 `istio-cni` Helm Chart 中的若干问题。它不遵循 `istioOwnedCNIConfigFileName` 值，
  配置变更时不会重启 `istio-cni`，卸载时不会移除自有的 CNI 配置或主 CNI 配置中的 `istio-cni` 插件，
  启用自有配置时不会清理主 CNI 配置，并且在自有配置文件名变更时不会移除之前的文件。
  ([Issue #61890](https://github.com/istio/istio/issues/61890))

- **修复** 修复了禁用 EDS 防抖时推送上下文的并发初始化问题。
  ([Issue #61924](https://github.com/istio/istio/issues/61924))

- **修复** 修复了在启用 `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` 时，增量 CDS 推送会移除
  `EnvoyFilter` 的 `envoyfilter.istio.io/referenced-services` 注解中所列 `Service` 资源对应的网关集群的问题。
  这些集群只有在下一次全量推送时才会恢复。
  ([Issue #62067](https://github.com/istio/istio/issues/62067))

- **修复** 修复了获取 JWKS 可能会阻塞 xDS 生成的问题。
  ([PR #62486](https://github.com/istio/istio/pull/62486))

- **修复** 修复了当某个服务仅通过 `istio.io/use-waypoint-canary` 标签将 `agentgateway` waypoint
  引用为其金丝雀时，该 waypoint 不会被下发挂接到该服务的路由和策略的问题。
  转移到金丝雀 waypoint 的连接会被拒绝，因为该 waypoint 没有其所代理服务的配置。
  ([Issue #61036](https://github.com/istio/istio/issues/61036))

- **修复** 修复了多个 `TCPRoute` 或 `TLSRoute` 挂接到同一 `agentgateway` `Gateway` 监听器时路由选择不确定的问题。
  现在会遵循 Gateway API 冲突解决规则，始终选择最早的路由（先按创建时间戳，再按命名空间/名称排序）。
  以前绑定到该监听器的路由是不确定的，因此流量可能会到达错误的后端。

- **修复** 修复了在 Ambient 中，当工作负载拥有多个服务时，用于变更检测和版本控制的预序列化工作负载不稳定的问题。
  这会导致未变更的工作负载在每次重新计算时看起来都已被修改，并使未变更的工作负载在客户端重连时无法被跳过。

- **修复** 修复了 CNI 不会移除在创建期间发生失败的 Pod 的 ipset 条目的问题。
  现在会移除与该 Pod 关联的所有 ipset 条目。

- **修复** 修复了在 Ambient 多网络模式下，`kubernetes.default` 服务可能会被 `serviceScopeConfigs`
  标记为全局作用域，从而导致 API 服务器服务在集群之间共享的问题。
  现在 `kubernetes.default` 服务始终被视为集群本地服务。

- **修复** 修复了当一个网络有多个网关条目时，为工作负载选择网络网关的顺序是随机的问题。
  这会导致每次重新计算时都产生不必要的工作负载（WDS）推送，并可能使工作负载使用的网关地址来回切换。

- **修复** 修复了影响 istiod Ambient 多集群模式的内存泄漏问题：
  轮换远程集群的凭据会泄漏该集群的全部缓存状态。
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **修复** 修复了 `istio.io/use-waypoint-canary` 标签绕过 `serviceEntryVisibility` NAMESPACE 隔离的问题：
  NAMESPACE 可见性的 `ServiceEntry` 可以将其金丝雀份额的流量路由到另一个命名空间中的 waypoint。
  现在金丝雀 waypoint 受到与主 waypoint 相同的跨命名空间拒绝限制。

  此问题由 Raphael Zanarelli 报告。

- **修复** 修复了当 Ambient Pod 与其命名空间一起被删除时，`istio-cni` 跳过清理，
  从而遗留其 ztunnel 代理和主机探针 ipset 条目的问题。

- **修复** 修复了 Istio 1.31 中引入的一个问题：对包含 CA 证书的 `ConfigMap`
  （例如 Kubernetes 在每个命名空间中创建的 `kube-root-ca.crt` `ConfigMap`）的更改
  会向每个代理触发 CDS、LDS、RDS 和 NDS 推送。集群会被完全重建，而不是增量构建。
  与 `Secret` 更新一样，这些更改现在只会触发 SDS 推送。对于这些更新，现在也会跳过 EDS。
  ([Issue #62523](https://github.com/istio/istio/issues/62523))

- **修复** 修复了 istiod 会为每个发送了 `initial_resource_versions` 的 Envoy MDS
  （WDS，用于遥测元数据查找）连接永久保留一份所有工作负载资源名称副本的问题。

- **修复** 修复了对 `EndpointSlice` 仅元数据的更新（例如 GitOps 工具写入注解）会触发 EDS 推送的问题，
  对于带有非 HTTP 端口的无头 `Service` 资源，即使端点没有变化，也会向每个代理推送。

- **修复** 修复了 `EnvoyFilter` `LISTENER_FILTER` `MERGE` 补丁会破坏所有代理共享的监听器过滤器，
  并且会被应用到与 `match.listener.listenerFilter` 不匹配的监听器过滤器上的问题。

- **修复** 修复了网关的配置依赖过滤，现在会排除无关的配置更新。
  网关作用域构建也会跳过收集仅用于 waypoint 路由的网格 `VirtualService` 资源。

- **修复** 修复了 Gateway API 中跨命名空间 TLS `certificateRef` 或 `caCertificateRef` 在
  `ReferenceGrant` 授权检查之前被解析的问题。因此，即使没有任何授权允许该引用，
  监听器的 `ResolvedRefs` 状态也能区分所引用的 `Secret` 或 `ConfigMap` 是否存在。
  现在会先执行授权，对于任何未获授权的跨命名空间引用都会返回 `RefNotPermitted`。

  此问题由 Darryl Jaskolski 报告。

- **修复** 通过本版本包含的 Envoy 更新，修复了 Ambient 模式下的 HBONE 流泄漏问题：
  在对端完全关闭连接后，`connect_originate` 流可能会永远保持打开状态。
  ([Issue #60074](https://github.com/istio/istio/issues/60074))

  此问题由 Torben Strüver 报告。

- **修复** 修复了从基于 CRD 的 Informer 中移除单个事件处理程序时，会移除该 Informer 上所有处理程序的问题。
  在 Ambient 多集群模式下，每次远程集群凭据轮换都会触发此问题，导致 istiod 永远等待新集群的集合同步，
  因此远程网络网关会丢失，并且工作负载索引可能会停止更新，直到重启为止。
  ([Issue #61827](https://github.com/istio/istio/issues/61827))

- **修复** 修复了 Ambient 多集群模式下的内存泄漏问题：集合会注册到 krt 调试器，
  但在远程集群被移除或其配置变更时从未注销，导致调试器注册随时间不断累积。
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **修复** 修复了 Ambient 多集群在远程集群的逐集群集合被替换时（例如凭据轮换时）丢弃该集群配置的问题。
  该替换被视为移除了一个集群并添加了一个无关的集群，因此来自该集群的服务、waypoint 和工作负载
  可能会短暂地从下发给代理的配置中消失，并且替换期间发生的事件可能会被完全遗漏。
  ([Issue #61348](https://github.com/istio/istio/issues/61348))

- **修复** 修复了当 Kubernetes API 请求没有收到响应时（例如负载均衡器或代理静默丢弃了返回路径），
  Istio 组件会无限期挂起的问题。以前，此类请求可能会永远保持打开状态，
  使发出该请求的控制器停滞，直到进程重启为止。现在请求会在客户端超时，
  因此卡住的请求会被取消，组件会自行恢复。每次超时都会被记录为警告，
  并由 `kube_client_deadline_fired_total` 指标计数。

- **修复** 修复了监听器冲突跟踪将具有相同命名空间和名称的 `Gateway` 和 `ListenerSet` 视为同一对象的问题。
  这会导致为其中一个对象记录的冲突把另一个对象中胜出的监听器标记为 `Conflicted`，并使其停止被下发。

- **修复** 修复了 `ListenerSet` 针对主机名和协议冲突的冲突解决。
  现在会正确拒绝冲突的监听器，并且 `ListenerSet` 状态条件的报告符合 Gateway API 1.5。
  ([PR #60775](https://github.com/istio/istio/pull/60775))

- **修复** 修复了对 Istio 配置资源仅元数据的更新（例如 GitOps 工具写入注解）时，
  只要该资源带有任何 `istio.io` 标签或注解（例如 `istio.io/rev`），就会触发推送的问题。
  现在，只有当 spec 或 `istio.io` 标签或注解的值发生变化时才会触发推送。

- **修复** 修复了与端点更新合并在一起的、与 EDS 无关的配置更新会导致全量 EDS 生成，
  而不是仅更新受影响的端点分配的问题。

- **修复** 修复了带有存在但为空的工作负载选择器的 `ServiceEntry` 资源会错误匹配其命名空间中所有工作负载的问题。

- **修复** 修复了被 `ServiceEntry` 选中的远程集群中的 Pod 在成为该服务端点时不会被重新计算的问题。
  重新计算的目标是 istiod 所在的集群，而不是该 Pod 所属的集群。

- **修复** 修复了被 `Service` 选中的 `WorkloadEntry` 在成为该服务端点时，其对应代理不会被重新计算的问题。

- **修复** 修复了当一个资源在先前的状态写入仍在排队时再次被修改，`observedGeneration` 会卡在过时值上的问题。

- **修复** 修复了当以 IP 地址寻址的 waypoint 的地址同时被另一个服务
  （例如另一个命名空间中的 `ServiceEntry`）声明时 istiod 发生崩溃的问题。
  现在冲突的地址会被跳过并记录一条警告，而不是发生 Panic；以前，低权限租户可以借此使控制平面崩溃。
  请参阅 [GHSA-7p2q-4xvg-vxc6](https://github.com/istio/istio/security/advisories/GHSA-7p2q-4xvg-vxc6)。
  由 [@yshch](https://github.com/yshch) 报告。

- **修复** 修复了启用 `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` 或 `PILOT_SEND_UNHEALTHY_ENDPOINTS`
  时不健康端点的传播问题。由 `ServiceEntry` 资源选中的未就绪 Pod，
  以及由 Kubernetes `Service` 资源或 `ServiceEntry` 资源选中、经过健康检查且不健康的 `WorkloadEntry` 资源，
  现在会连同其健康状态一起保留，而不再被省略。

- **修复** 修复了 `VirtualService` 验证在 `gateways` 以及 HTTP/TLS/TCP 匹配的 `gateways` 中
  遇到不带命名空间的条目后会跳过其余网关名称的问题。现在会拒绝此类条目之后列出的无效网关名称。

- **修复** 修复了 `VirtualService` 验证接受 `fault.abort.httpStatus` 和 `directResponse.status` 中 HTTP 状态码 `600` 的问题。
  Envoy 仅允许这些字段使用 200-599 范围内的状态码，因此现在验证会拒绝此类值。

- **修复** 修复了导致 WDS 推送无法跳过防抖的回归问题。新的 `PILOT_ENABLE_WDS_DEBOUNCE` 环境变量用于控制此行为，
  默认启用。将其设置为 `false` 可允许 WDS 推送独立于 EDS 推送跳过防抖。
  ([Issue #62125](https://github.com/istio/istio/issues/62125))

- **优化** 优化了 `EnvoyFilter` 合并补丁处理，现在会缓存已解码的类型化配置，
  避免在生成 xDS 配置期间重复反序列化。

- **优化** 优化了向网关推送配置。istiod 现在会跟踪绑定到每个入口网关或 Ambient 东西向网关所服务的
  `Gateway` 资源的 `VirtualService` 资源，并且仅将 `VirtualService` 变更推送到其所绑定的网关，
  而不是推送到网格中的每个网关。这也优化了网关的 CDS 和 RDS 生成。

- **优化** 优化了无代理 gRPC 的路由生成，对于不影响路由的更新（例如仅端点变更）会跳过重新构建。

## 安全 {#security}

- **改进** 改进了对被 `AuthorizationPolicy` 作为目标的路由上 `ALLOW` 策略的评估。
  路由作用域的 `ALLOW` 策略会与网关自身的 `ALLOW` 策略一起评估，因此请求只要匹配其中任意一个即被允许。
  因此，路由作用域的 `ALLOW` 策略会放宽该路由上的访问权限，而不是对其进行限制，
  这与根命名空间和工作负载命名空间中的 `ALLOW` 策略已有的组合方式一致。
  路由作用域的 `DENY` 策略是叠加的，无法覆盖为网关或在根命名空间中定义的 `DENY` 策略。
  ([Issue #60964](https://github.com/istio/istio/issues/60964))

- **更新** 将 `distroless` 镜像更新为基于带有最新 CA 捆绑包的 `cgr.dev/chainguard/static` 基础镜像，
  由于 eMudhra 中间 CA 私钥泄露，该捆绑包移除了 `emSign ECC Root CA - G3`。

- **新增** 新增了通过 `targetRefs` 从 `AuthorizationPolicy` 将 Gateway API `HTTPRoute` 资源作为目标的实验性支持，
  允许将 `ALLOW` 和 `DENY` 规则的作用域限定到单个路由，而不是整个网关。
  此功能默认禁用，可在 `istiod` 上设置 `ENABLE_GATEWAY_API_HTTPROUTE_AUTH=true` 来启用。
  策略必须与其所指向的 `HTTPRoute` 位于同一命名空间中，并且仅支持入口网关；
  waypoint 和 Sidecar 会忽略这些策略。`CUSTOM` 和 `AUDIT` 操作不能以 `HTTPRoute` 为目标，
  并且在同一策略中，`HTTPRoute` 目标引用不能与其他类型的目标引用组合使用。
  ([Issue #60964](https://github.com/istio/istio/issues/60964))

- **新增** 新增了分析器消息 `IST0178`，当存在以 `HTTPRoute` 为目标的 `AuthorizationPolicy` 时，
  如果 `EnvoyFilter` 插入了 HTTP 过滤器，则会发出警告。
  在依赖路由的过滤器运行之后清除路由缓存的 `EnvoyFilter` 资源，
  可能会导致请求被路由到与评估该过滤器时不同的位置。
  ([Issue #60964](https://github.com/istio/istio/issues/60964))

- **新增** 为 `pilot-agent` 新增了 `WORKLOAD_IDENTITY_SOCKET_TIMEOUT` 环境变量，
  用于配置启动时等待外部 SDS 提供程序（例如 SPIRE）创建工作负载身份套接字并开始在其上提供服务的时长。
  如果不配置该超时，则只会在启动时检查一次套接字，
  因此在 `pilot-agent` 启动之后才绑定套接字的提供程序可能会导致代理从外部 SDS 提供程序请求系统根 CA，
  从而导致上游 TLS 验证失败。默认值为 `0s`，保留现有的单次检查行为。
  ([Issue #61343](https://github.com/istio/istio/issues/61343))

- **新增** 为 istiod 新增了 `PILOT_DISABLE_SELF_SIGNED_CA` 环境变量。设置为 `true` 时，
  如果不存在插入的 `cacerts` 捆绑包，istiod 将无法启动其 CA，而不是生成或重用自签名根 CA（`istio-ca-secret`）。
  这使得必须仅使用插入式 CA 的部署能够以失败关闭的方式运行，而不是回退到非预期的自签名根证书。
  默认值为 `false`。

- **新增** 新增了通过 `Gateway` 资源的 `ecdhCurves` 字段为终止 TLS 的网关配置 ECDH 曲线的支持。

- **新增** 在 `RequestAuthentication` 的 `JWTRule` 中新增了 `presence` 字段。
  设置为 `REQUIRED` 时，该规则对应的 JWT 令牌必须存在且有效；不带该令牌的请求会以 `401 Unauthorized` 被拒绝。
  以前，配置多个 `jwtRules` 时会独立验证每个令牌，但仅带有一个有效令牌的请求也能通过。
  在每个规则上设置 `presence: REQUIRED` 可以强制要求所有已配置的令牌都必须存在且在密码学上有效。
  当工作负载必须在不同标头上接收来自多个签发者的令牌时，这非常有用，
  例如在 `Authorization` 中携带身份令牌，在自定义标头中携带作用域令牌。
  该字段默认为 `OPTIONAL`，保留现有 `RequestAuthentication` 资源的行为。
  配置多个 `REQUIRED` 规则时，可以在 `AuthorizationPolicy` 中通过 `request.auth.claims` 访问所有已验证令牌中的声明。
  每个提供程序的负载存储在其自己的元数据键下，因此授权规则可以引用任意一个必需令牌中的声明。
  ([Issue #60823](https://github.com/istio/istio/issues/60823))

- **修复** 修复了通过将 `ca-crl.pem` 指定为空字符串或将其移除来清除证书吊销列表（CRL）的功能。
  ([Issue #61073](https://github.com/istio/istio/issues/61073))

- **修复** 修复了 Ambient 模式下仅带有 HTTP 属性的 `DENY` `AuthorizationPolicy` 资源的状态消息不正确的问题。
  这些策略不会由 ztunnel 强制执行（空匹配会被跳过），因此现在状态会报告这些策略不起作用，
  并建议部署带有 `targetRef` 的 waypoint 代理。
  ([Issue #61126](https://github.com/istio/istio/issues/61126))

- **修复** 修复了 JWKS 解析器强制所有公钥获取都使用 HTTP/1.1 的问题。
  用于 TLS 固定和 CIDR 阻止的自定义 `TLSClientConfig` 和 `DialContext` 导致 Go 的 `net/http` 禁用了自动 HTTP/2，
  因此 ALPN 从未协商到 h2。现在重新启用了 HTTP/2（与 `http.DefaultTransport` 一致），
  修复了通过某些 HTTP CONNECT 代理以 HTTP/1.1 获取 JWKS 时失败的问题。
  ([Issue #61250](https://github.com/istio/istio/issues/61250))

- **修复** 修复了 waypoint 和 Sidecar 的 HBONE 内部监听器上 `AuthorizationPolicy` 的 `ipBlocks` 和 `notIpBlocks` 匹配问题，
  现在会使用下游客户端的直接远程 IP 地址，而不是 Envoy 内部地址。
  ([Issue #62522](https://github.com/istio/istio/issues/62522))

- **修复** 修复了 Ambient 模式下当 `AuthorizationPolicy` 包含空的 `to` 或 `from` 条目时 istiod 发生崩溃的问题。
  现在此类条目会被视为空的 `operation` 或 `source`，与 Sidecar 的行为一致。

- **修复** 修复了 Ambient 模式下的 mTLS 绕过问题：当工作负载级模式为 `PERMISSIVE` 或 `DISABLE`
  且网格范围模式为 `STRICT` 时，端口级别的 `STRICT` `PeerAuthentication` 不会被强制执行，
  明文流量可以到达该端口。

- **修复** 修复了通过更改主机名大小写可以绕过针对 `request.headers[:authority]` 和
  `request.headers[host]` 的 `AuthorizationPolicy` 条件的问题。
  现在，这些条件与 `hosts` 一样以不区分大小写的方式进行匹配。

- **修复** 修复了在 HTTP/2 上通过更改方法的大小写（例如使用 `post` 代替 `POST`）
  可以绕过 `AuthorizationPolicy` 方法规则的问题。现在方法匹配不区分大小写。
  请参阅 [GHSA-w44g-8m76-8gc5](https://github.com/istio/istio/security/advisories/GHSA-w44g-8m76-8gc5)。
  由 [@izzysec](https://github.com/izzysec) 报告。

- **修复** 修复了 `BackendTLSPolicy` 中的失效放行（fail-open）问题：当策略的 `caCertificateRefs` 无法解析时，
  Sidecar 代理会以明文发送上游流量，而不是以失败关闭的方式处理。

- **修复** 修复了 JWKS 解析器的周期性后台刷新在缓存获取到的响应时，不验证该响应看起来是否为 JWKS 的问题。
  同步获取路径已经会拒绝格式不像 JWKS（`{"keys": [...]}`）的响应，但后台刷新不会，
  因此当 `RequestAuthentication` 的 `jwksUri` 指向非预期的内部端点时，
  该端点的响应可能会被缓存并被当作 JWKS 返回。现在，后台刷新路径也会应用相同的检查。

  此漏洞由 Anthropic 和 Ada Logics 发现并报告。

- **修复** 修复了 istiod 获取 `RequestAuthentication` `jwksUri` 时存在的 SSRF 缺陷。
  `istiod` 现在默认会在拨号层面阻止链路本地地址和已知的云元数据地址（例如 `169.254.169.254`），
  并拒绝获取到的非有效 JWKS 响应。私有地址和环回地址范围仍然可以访问，
  并可以通过 `BLOCKED_CIDRS_IN_JWKS_URIS` 进行阻止。

- **修复** 修复了 OIDC/JWT 身份验证器收到 `sub` 声明格式错误的令牌时 istiod 发生 Panic 的问题。
  现在在使用主体之前会验证其格式必须严格为 `system:serviceaccount:<namespace>:<serviceaccount>`。

  此问题由 Kaizhe Huang 报告。

- **修复** 修复了在实验性的 Kubernetes CSR RA 路径（`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`）上，
  `CreateCertificate` 会向调用方返回原始 Kubernetes API 错误文本，从而泄露 CSR 名称、签名者名称和 istiod 身份的问题。
  现在完整的错误仅在服务端记录。
  由 Juno Im 报告。

- **修复** 修复了在实验性的 Kubernetes CSR RA 路径（`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`）上，
  Kubernetes CSR 监视循环使用了被遗弃的 `time.After` 计时器，可能会在请求完成后仍留下一个运行中的 goroutine 的问题。
  现在该循环受正确作用域的 `context.WithTimeout` 约束，并会在超时或取消时被可靠地清理。
  由 Juno Im 报告。

- **修复** 修复了在实验性的 Kubernetes CSR RA 路径（`EXTERNAL_CA=ISTIOD_RA_KUBERNETES_API`）上，
  客户端请求的 `ValidityDuration` 最高可被接受到 `MAX_WORKLOAD_CERT_TTL`（默认 `90d`）的问题。
  新的 `MAX_RA_WORKLOAD_CERT_TTL` 环境变量（默认 `48h`）现在会限制 TTL 上限，
  从而限制 `istio-token` 被盗时的影响范围。通过此路径合法请求 TTL 大于 `48h` 证书的部署，
  应在升级后调高 `MAX_RA_WORKLOAD_CERT_TTL`。
  由 Juno Im 报告。

- **修复** 修复了当 `istio-ca-secret` 中的自签名 CA 证书已过期时 istiod 无法启动的问题。
  当 Deployment 缩容到零的时间超过证书 TTL 时，就可能出现这种情况。
  现在会使用现有私钥自动续期已过期的证书。

- **修复** 修复了网关 Secret 访问的授权检查未包含服务账号的 Kubernetes 组的问题。
  因此，向 `system:serviceaccounts:<namespace>` 等组授予 Secret 访问权限的 `RoleBinding` 和 `ClusterRoleBinding` 规则会被忽略，
  网关会被拒绝访问已授予其访问权限的凭据。
  ([Issue #58120](https://github.com/istio/istio/issues/58120))

- **修复** 修复了若干 `sidecar.istio.io/*` 注解（`proxyImage`、`bootstrapOverride`、
  `logLevel`、`componentLogLevel`、`agentLogLevel`）在插入 Sidecar/网关注入模板时没有进行输出转义的问题，
  精心构造的注解值可能会借此向生成的 Pod 或 Deployment 规约中注入额外字段。
  现在这些注解会在每个模板输出点被一致地转义。

  此漏洞由 localhost-detect 发现并报告。

- **修复** 修复了复用已拆除连接四元组的新入站连接可能会匹配到过时的 `conntrack` `ESTABLISHED` 条目，
  从而绕过 Sidecar 代理的问题。现在在 `iptables` 和 `nftables` 模式下，
  仅匹配 `SYN` 数据包的规则都会在 `ESTABLISHED` 转向规则之前进行评估。

- **修复** 修复了 Wasm 模块获取（`pkg/wasm`）中的 SSRF 防护缺陷。以前 HTTP 获取器对目标 IP 完全没有限制，
  而 OCI 镜像获取器的 SSRF 防护仅检查 `401` bearer-realm 响应，
  不检查实际 manifest/blob 获取过程中的 `3xx` 重定向。
  现在两个获取器都会在拨号层面阻止到链路本地地址（包括 `169.254.169.254` 等云实例元数据端点）的连接，
  因此无论重定向目标是 IP 字面量还是解析为此类地址的主机名，该阻止都会应用于原始请求和每一跳重定向。
  新的 `BLOCKED_CIDRS_IN_WASM_FETCH` 环境变量允许运维人员根据需要额外阻止私有地址范围或特定的集群内地址。

  镜像获取器重定向绕过问题由 박현범 报告，并由 Svpernova 独立报告。HTTP 获取器无限制问题由 Aser Ahmed 报告。

- **修复** 修复了当 `RequestAuthentication` 策略使用服务 `targetRef` 时 waypoint 代理无法收到远程 JWKS 集群的问题。

- **修复** 修复了 istiod 接受与验证代理令牌所用集群不同的节点元数据 `CLUSTER_ID` 的问题。

- **修复** 修复了 istiod 调试端点（`/debug/config_dump`、`/debug/edsz` 和 xDS `istio.io/debug/config_dump` 类型）
  将 `proxyID` 作为子字符串进行匹配，使调用方可以通过传入部分 ID 读取其所在命名空间中其他代理配置的问题。
  现在 `proxyID` 必须是精确的 `<pod>.<namespace>`（或完整的连接 ID）；
  `proxyID=istio-ingressgateway` 等简写形式不再匹配。

  此问题由 박현범 报告。

- **修复** 修复了带有格式错误资源名称的 `istio.io/debug` xDS 请求导致空指针解引用，从而使 istiod 崩溃的问题。
  现在此类请求会以 `InvalidArgument` 被拒绝。

- **修复** 修复了带有格式错误的 `traceparent` 标头的入站 HBONE 请求导致索引越界 Panic，
  从而使 ztunnel 崩溃并丢弃该连接上所有流的问题。
  现在，无效的 `traceparent` 标头会被忽略，并生成新的追踪 ID。

## 可观测 {#telemetry}

- **改进** 改进了网格配置加载失败的报告，新增了按来源区分的错误和回退日志，
  以及新的 `istiod_mesh_config_load_errors_total` 计数器。
  ([Issue #61563](https://github.com/istio/istio/issues/61563))

- **新增** 新增了通过 `pilot-agent` 的指标合并器对原生 Prometheus protobuf 的透传支持。
  当 Prometheus 抓取器发送 `Accept: application/vnd.google.protobuf; proto=io.prometheus.client.MetricFamily; encoding=delimited` 时，
  Envoy 的原生（稀疏）直方图现在会原样到达抓取器，而不会因文本格式重新编码而被静默降级。
  已有的 text/OpenMetrics 抓取路径逐字节保持不变。
  ([Issue #49950](https://github.com/istio/istio/issues/49950))

- **新增** 为 `pilot-agent` 新增了 `istio_agent_scrape_format_total{format,downgrade}` 计数器，
  用于报告每次抓取的格式协商结果（`text` / `openmetrics` / `protobuf`，并在上游不一致时带有降级标识）。
  ([Issue #49950](https://github.com/istio/istio/issues/49950))

- **新增** 新增了在启用 `AMBIENT_ENABLE_MULTI_NETWORK` 和 `AMBIENT_ENABLE_TLS_PROXY_HTTP_METRICS` 时，
  waypoint 为使用 TLS 或 PROXY 等协议的跨集群流量记录 HTTP 指标的支持。

- **修复** 修复了 `source_app` 和 `destination_app` 指标标签的问题：当 Pod 同时带有
  `app.kubernetes.io/name` 标签时，现在会使用 Pod 的 `app` 标签。从 1.29.1 开始，这些指标标签使用的是 `app.kubernetes.io/name`，
  这是一个偏离预期行为的回归问题。
  ([Issue #62280](https://github.com/istio/istio/issues/62280))

- **修复** 修复了 `sidecar.istio.io/statsFlushInterval` 注解在值为一分钟或以上以及亚秒级时
  会生成无效的 Envoy 引导配置，从而导致代理无法启动的问题。

- **修复** 修复了 `sidecar.istio.io/statsEvictionInterval` 注解会静默截断亚秒级精度的问题。

- **修复** 修复了一个回归问题：当 waypoint 为另一个命名空间中的 `Service` 提供服务时，
  位于 waypoint 自身命名空间中、通过 `targetRefs` 或 `selector` 选中的 `Telemetry` 资源未被应用。
  以这种方式配置的访问日志、指标和追踪，对于该 waypoint 处理的每个跨命名空间 `Service` 都会被静默丢弃。
  ([Issue #61538](https://github.com/istio/istio/issues/61538))

## 可扩展性 {#extensibility}

- **修复** 修复了 Wasm OCI 镜像获取器根据镜像仓库返回的错误来决定是否通过明文 HTTP 重试失败的 HTTPS 获取的问题。
  由于镜像仓库属于不受信任的输入，中间人攻击者或恶意镜像仓库可以按需触发此回退，强制使用明文传输，
  并且在未固定可选模块摘要的情况下提供任意 Wasm 二进制文件。
  现在仅对运维人员通过 `WASM_INSECURE_REGISTRIES` 显式加入允许列表的镜像仓库尝试明文重试。

  此漏洞由 Adam Korczynski 发现并报告。

## 安装 {#installation}

- **更新** 将 Kiali 插件更新至 v2.34.1 版本。

- **新增** 在 istiod（Pilot）Helm 值中新增了 `terminationGracePeriodSeconds` 字段，
  允许配置 istiod `Deployment` 的 Pod 终止宽限期。默认值为 30 秒，与以前的行为一致。

- **新增** 为 `istio-cni` Chart 新增了 `daemonSetAnnotations` 值，用于为 CNI `DaemonSet` 对象本身设置注解。
  该 Chart 已经支持用于标签的 `daemonSetLabels` 和用于 Pod 的 `podAnnotations`，
  但无法设置 `DaemonSet` 自身的注解。

- **新增** 新增了在网络网关配置中为每个端口指定自定义 `nodePort` 的支持。
  ([Issue #61569](https://github.com/istio/istio/issues/61569))

- **新增** 新增了 `values.sidecarInjectorWebhook.revisionLabelPrecedence`，用于配置 Sidecar 注入时修订版标签的优先级。

  默认值为 `namespace`，保留现有行为。将其设置为 `pod` 后，
  Pod 的 `istio.io/rev` 标签可以覆盖命名空间的 `istio.io/rev` 标签。
  ([Issue #48316](https://github.com/istio/istio/issues/48316)), ([Issue #48317](https://github.com/istio/istio/issues/48317))

- **修复** 修复了当两者都存在时，istiod 优先使用单独挂载且始终存在的 `istio-ca-root-cert` `ConfigMap`
  （`/var/run/secrets/istiod/ca/root-cert.pem`）中的 CA 证书，
  而不是与 DNS 服务证书放在一起的 CA 证书（`/var/run/secrets/istiod/tls/ca.crt`）的问题。
  当 DNS 服务证书由外部提供（例如由 cert-manager istio-csr 或手动创建的 `Secret` 提供）后，
  这可能会导致 `MutatingWebhookConfiguration`/`ValidatingWebhookConfiguration` 的 `caBundle` 与 CA 不匹配，
  即使 istiod 本身已经正确地使用新证书提供 TLS 服务。
  ([Issue #60774](https://github.com/istio/istio/issues/60774))

- **修复** 修复了网关 Helm Chart 的 `NetworkPolicy` 资源名称包含修订版的问题，
  该问题导致网关修订版变更时 `NetworkPolicy` 会被删除并重新创建，而不是原地更新。
  ([Issue #61016](https://github.com/istio/istio/issues/61016))

- **修复** 修复了 OpenShift 上绑定到自定义 `SecurityContextConstraint` 的工作负载的 Sidecar 代理 UID/GID 解析问题，
  这些 `SecurityContextConstraint` 具有较窄或显式配置的 UID 范围，而命名空间预分配的 UID 范围注解并不会通告该范围。
  ([Issue #61791](https://github.com/istio/istio/issues/61791))

- **修复** 修复了 `istioctl install` 和 `istioctl manifest generate` 拒绝 `cni.ambient.enablementSelectors`、
  `cni.ambient.shareHostNetworkNamespace` 和 `cni.ambient.enableAmbientDetectionRetry` 值的问题。
  `istio-cni` Chart 支持这些值，但 `IstioOperator` 值模式中缺少它们，因此只能通过直接使用 Helm 安装 Chart 来设置。
  ([Issue #61180](https://github.com/istio/istio/issues/61180))

- **修复** 修复了 `default` Chart 的 `ValidatingWebhookConfiguration` 仍然硬编码 `failurePolicy: Ignore` 的问题，
  该问题导致使用服务端应用执行 `helm upgrade` 时出现与之前在 `base` 和 `istiod` Chart 中已修复的相同的字段管理器冲突。
  ([Issue #61613](https://github.com/istio/istio/issues/61613))

- **修复** 修复了 Sidecar 注入器不验证 `traffic.sidecar.istio.io/includeOutboundPorts` 注解的问题。
  现在格式错误的值会在准入时被拒绝，与同类的流量端口注解以及 CNI 重定向路径保持一致。

- **修复** 修复了 istiod 仅容忍默认的 `cni.istio.io/not-ready` 污点的问题。
  当 `taint.name` 设置为自定义污点时，istiod `Deployment` 现在会容忍该污点，
  从而使 istiod 可以被调度到仍带有该污点的节点上。
  ([Issue #52073](https://github.com/istio/istio/issues/52073))

- **移除** 从所有 Istio Chart 中移除了 `GOMAXPROCS` 环境变量。
  Go 1.25 会自动将 `GOMAXPROCS` 设置为与 CPU 限制相匹配。
  ([Issue #60235](https://github.com/istio/istio/issues/60235))

## istioctl

- **改进** 改进了当显式指定的 `--meshConfigFile` 无法读取或解析时 `istioctl analyze` 的错误报告。

- **更新** 将最低支持的 Kubernetes 版本更新为 1.33.x。

- **修复** 修复了 `istioctl` 在使用服务账号令牌连接到 xDS 时跳过 istiod 证书验证的问题
  （涉及 `istioctl proxy-status`、`istioctl x internal-debug` 以及所有使用 `--xds-address` 的情况）。
  `istioctl` 现在会根据 `istio-ca-root-cert` `ConfigMap` 中的 Istio 根证书和预期的服务器名称来验证服务器：
  如果设置了 `--authority`，则使用该值；如果 `--xds-address` 的主机是 DNS 名称，则使用该主机；
  如果连接的是 IP 地址或 localhost，则使用 `istiod.<istio-namespace>.svc`。
  传递 `--insecure`（或设置 `ISTIOCTL_INSECURE=true`）可显式跳过验证。
  ([Issue #41937](https://github.com/istio/istio/issues/41937))

  此问题由 [Leon Zlobecki](https://leonz.is) 报告。

- **修复** 修复了 `istioctl analyze` 直接根据 `istio-system` 中的多集群 Secret 构建 Kubernetes 客户端，
  而不对 kubeconfig 进行清理的问题。精心构造的 Secret 可能会借此在运行 `istioctl` 的机器上执行 `exec` 凭据插件
  （或通过其他不安全的认证字段读取本地文件）。现在 kubeconfig 会以与 istiod 清理这些 Secret 相同的方式进行清理。

  此漏洞由 Adam Korczynski 发现并报告。

- **修复** 修复了 `istioctl install --set values.base.validationFailurePolicy` 被作为未知字段拒绝的问题。
  `base` 和 `istiod` Chart 已经支持该值，但 operator 的 `values_types.proto` 模式中缺少该值。

- **修复** 修复了当包含或排除过滤器的字段过多时 `istioctl bug-report` 崩溃的问题。

- **修复** 修复了 `istioctl bug-report --duration` 在未与 `--end-time` 一起使用时不会过滤日志的问题。

- **修复** 修复了 `istioctl install --set` 不支持若干 Helm Chart 值的问题，
  这些值在 operator 的 `values_types.proto` 模式中缺失。现在可以设置以下值：
  `cni.terminationGracePeriodSeconds`、`cni.updateStrategy`、
  `cni.seLinuxOptions`、`cni.tolerations`、`pilot.initContainers`、`pilot.pdb`、
  `pilot.deploymentAnnotations`、`pilot.sidecarInjectorWebhookAnnotations`、
  `pilot.trustedZtunnelName`、`global.proxy_init.forceApplyIptables` 和
  `global.waypoint.tolerations`。

- **修复** 修复了 `istioctl manifest translate` 将来自 `IstioOperator` 输入的值（例如命名空间和发布名称）
  不加引号地写入所生成的安装 Shell 脚本的问题。运行这些脚本时，精心构造的值可能会注入额外的 Shell 命令。
  现在，参数会使用 `shellescape.Quote` 进行转义。

  此漏洞由 OpenSec Intelligence 发现并报告。

- **修复** 修复了 `istioctl analyze`，使 `VirtualService` 对 Kubernetes Gateway API `Gateway` 资源的引用
  不再产生错误的 `ReferencedResourceNotFound` 报错。
  ([Issue #60708](https://github.com/istio/istio/issues/60708))
