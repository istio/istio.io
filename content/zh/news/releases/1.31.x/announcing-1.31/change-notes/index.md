---
title: Istio 1.31.0 更新说明
linktitle: 1.31.0
subtitle: 主要版本
description: Istio 1.31.0 更新说明。
publishdate: 2026-08-31
release: 1.31.0
weight: 10
aliases:
    - /zh/news/announcing-1.31.0
---

## 流量治理 {#traffic-management}

- **改进** 当集群中安装的 Gateway API CRD 低于此 Istio 版本所需的最低版本时，
  改进日志记录。该消息现在记录在 `warn` 级别，并解释说在 CRD 升级之前不会处理此类资源。
  以前，这是在 `info` 级别记录的并且很容易错过，这使得升级到 1.30 后使用过时的 CRD 很难诊断 TLS 直通破坏。

- **改进** 通过将 XDS 推送从工作负载/服务 `Address` 更改范围限定为仅受影响的 waypoint，
  而不是推送到所有 waypoint 和代理，改进 Ambient 模式下的 istiod 可扩展性。
  可以通过 `AMBIENT_SCOPED_ADDRESS_PUSHES=false` 禁用。

- **新增** 添加了通过 `PILOT_NODE_UNTAINT_CONTROLLERS_TAINT_NAME`
  环境变量对试点节点无污染控制器的自定义污染名称的支持。
  默认为 `cni.istio.io/not-ready`。
  ([Issue #57844](https://github.com/istio/istio/issues/57844))

- **新增** 添加了支持当 `BackendTLSPolicy` 或 `XBackendTrafficPolicy` 对象上的
  `istio.io/ignore-policy-attachment` 注解设置为 `true` 时从 Istio 排除策略配置。
  当特定策略用于与 Istio 不同的网关控制器时，这允许用户防止将特定策略转换为 Istio 配置。

  用法示例：

{{< text yaml >}}
apiVersion: gateway.networking.k8s.io/v1
kind: BackendTLSPolicy
metadata:
annotations:
  istio.io/ignore-policy-attachment: "true"
{{< /text >}}

  ([Issue #60122](https://github.com/istio/istio/issues/60122))

- **新增** 添加了支持使用命名空间上的 `~` 前缀从 `Sidecar` 出口侦听器的 `hosts` 中排除命名空间和主机。
  没有前缀的条目会像以前一样导入，带有 `~`  前缀的条目会从中减去：
  `~ns1/*` 排除 `ns1` 中的所有主机，`~/foo.com` 从每个命名空间中排除 `foo.com`。
  这使得大型网格可以导入除少数命名空间之外的所有内容（例如 `*/*` 加上 `~ns1/*`），而无需枚举很长的白名单。
  ([Issue #60139](https://github.com/istio/istio/issues/60139))

- **新增** 添加了初始化检查，验证捆绑的 `nft` 二进制文件是否支持 JSON 输出。
  本机 nftables 后端需要 JSON 在 Pod 删除期间读取配置。
  在 `nft` 二进制文件不支持 JSON 的主机上，每次删除时这些调用都会失败并显示
  `Error: JSON support not compiled-in`，并且 CNI 代理会无限期地重试。
  新的检查在启动时检测到此错误并回退到 `iptables` 后端。
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **新增** 向 `HTTPRedirect` 添加了 `prefix_rewrite` 字段，
  在重定向规则中启用前缀感知路径重写。这允许在重定向时剥离或替换匹配的路径前缀，
  例如将 `example.com/foo/bar` 重定向到 `foo.example.com/bar`。
  ([Issue #47500](https://github.com/istio/istio/issues/47500)),
  ([Issue #47777](https://github.com/istio/istio/issues/47777)),
  ([Issue #52521](https://github.com/istio/istio/issues/52521))

- **新增** 在 `RetryBudget` `TrafficPolicy` API 中添加了 `budget_interval` 字段，
  用于配置计算重试预算时考虑请求的时间间隔。默认值 0ms 保留仅考虑正在进行的请求的现有行为。
  ([Issue #60389](https://github.com/istio/istio/issues/60389))

- **新增** 添加了对 Ambient 模式下加权路 waypoint 金丝雀的支持。
  服务（或命名空间）现在可以通过 `istio.io/use-waypoint-canary` 和
  `istio.io/use-waypoint-canary-namespace` 标签引用主 waypoint 和金丝雀 waypoint，并使用 `istio.io/use-waypoint-canary-weight`
  注解将服务的网格内连接的可配置份额（以及 `istio.io/ingress-use-waypoint` 的入口请求）
  定向到金丝雀 waypoint，而无需任何客户变更。
  ([Issue #60801](https://github.com/istio/istio/issues/60801))

- **新增** 添加了 `meshConfig.serviceEntryVisibility`，
  让网格管理员控制 `ServiceEntry` 资源的可见性。Ambient（ztunnel 和 waypoint）默认强制可见性；
  当设置 `applyToSidecars` 时，经典的 Sidecar 也会尊重它。
  除非配置，否则该功能是惰性的，因此默认情况下现有网格不受影响。
  ([Issue #60870](https://github.com/istio/istio/issues/60870))

- **新增** 添加了 `istio-agentgateway-waypoint` `GatewayClass` 用于将代理网关部署为 waypoint。

- **新增** 添加了 `ALLOW_ANY_DYNAMIC_DNS` 出站流量策略模式。
  当在 `meshConfig.outboundTrafficPolicy.mode` 中设置时，
  到未知目的地的纯文本 HTTP 请求将通过 Envoy 的动态转发代理转发，
  在请求时从 `Host` 标头解析主机名。非 HTTP 流量（TLS 和原始 TCP）继续使用 `PassthroughCluster`。
  仅适用于 Sidecar 代理。 `Sidecar` CRD 不支持。可选的上游 TLS
  发起可以通过 `meshConfig.outboundTrafficPolicy.tls` 进行配置。

- **新增** 在 `ProxyConfig` 中添加了对 `connectionSettings` 的支持，
  允许配置侦听器缓冲区限制、HTTP 超时、HTTP/2 设置和路径/标头规范化。
  新的 `EDGE` 配置文件将固执己见的 Envoy 边缘代理默认值应用于网关代理。

- **新增** 向 `EnvoyFilter` 添加了新的 `MERGE_AND_REPLACE_LIST` 补丁操作。
  它的行为类似于 `MERGE`，只不过补丁中存在的重复（列表）字段完全替换生成的配置中的相应列表，
  而不是附加到其中。这适用于 `CLUSTER`、`LISTENER`、`FILTER_CHAIN`、
  `ROUTE_CONFIGURATION`、`VIRTUAL_HOST` 和 `HTTP_ROUTE` 补丁目标。
  嵌套在 `Any` 类型的过滤器配置（HTTP、网络和侦听器过滤器以及传输套接字）
  内的列表不受影响，并继续遵循 `MERGE` 语义。

- **新增** 在客户端证书验证逻辑中添加 Gateway API `AllowInsecureFallback` 功能的实现。
  此功能允许网关请求客户端证书并尝试验证它，但如果客户端未提供证书或证书无效，
  网关仍将允许连接。默认情况下，Istio 填充 `x-forwarded-client-cert` HTTP 标头，
  因此当启用 `AllowInsecureFallback` 时，后端可以验证证书而不是网关。
  ([Issue #60018](https://github.com/istio/istio/issues/60018))

- **新增** 添加了支持通过 `DestinationRule` 在上游连接上配置 HTTP/2 keepalive PING 设置。
  ([Issue #55640](https://github.com/istio/istio/issues/55640))

- **新增** 向 `MeshConfig` 添加了 `defaultTrafficPolicy`，
  这是出站集群继承的网格范围基线 `connectionPool` 和 `outlierDetection`。
  设置这些块之一的 `DestinationRule` 会覆盖该块的基线；
  `DestinationRule` 未设置的块现在继承网格基线，而不是 Istio 的内置默认值。
  当未配置基线时，行为不会改变。基线 `connectionPool` 也适用于入站集群和直通集群。

- **新增** 通过 `DestinationRule.TrafficPolicy.LoadBalancerSettings` 和 `MeshConfig`
  上的新 `zoneAwareLbSetting` 字段添加了对 Envoy 区域感知负载平衡的支持。
  启用后，Envoy 会自动将流量路由到与下游代理位于同一可用区域中的端点，
  仅当本地容量不足时才溢出到其他区域。这与现有的 `localityLbSetting` 不同，
  区域级路由由 Envoy 使用代理的区域分布自动处理，而不是通过静态百分比。
  可以通过 `failover` 字段配置跨区域故障转移顺序，并且可以通过
  `failoverPriority` 将基于标签的优先级分层。区域感知负载平衡需要
  `meshConfig.defaultConfig.proxyMetadata` 中的 `ISTIO_META_ENABLE_SELF_DISCOVERY: "true"`
  将自我发现 `local_cluster` 注入 Sidecar 引导程序。
  仅在 Sidecar 模式下支持，在 Ambient 模式下不支持。
  ([引用](/zh/docs/reference/config/networking/destination-rule/#ZoneAwareLoadBalancerSetting))([引用](/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig))

- **启用** 默认情况下启用发送不健康的端点，除非配置了 `OutlierDetection.minHealthPercent`。
  可以通过将 `PILOT_AUTO_SEND_UNHEALTHY_ENDPOINTS` 设置为 `false` 来禁用此功能。

- **修复** 修复了 Gateway API 处理以实现 `BackendTLSPolicy` 冲突解决。
  ([Issue #57817](https://github.com/istio/istio/issues/57817))

- **修复** 修复了当 Pod 尚未出现在 kube informer 缓存中时，
  重新连接到新 istiod 实例（例如在滚动重启期间）的代理缺少入站集群的错误。
  现在，工作负载标签是在计算服务目标之前填充的，因此 `GetProxyServiceTargets`
  中的元数据回退路径可以正确匹配服务，而不是返回空列表。
  ([Issue #58125](https://github.com/istio/istio/issues/58125))

- **修复** 修复了以下问题：启用 `PILOT_ENABLE_QUIC_LISTENERS` 时，
  生成的 Gateway API `Service` 资源未在每个 HTTPS 侦听器的相应 UDP 端口上侦听。
  ([Issue #58247](https://github.com/istio/istio/issues/58247))

- **修复** 修复了当父网关使用手动部署时，通过 `ListenerSet` 定义的
  HTTPS 侦听器无法传递 TLS 证书的问题。
  ([Issue #59535](https://github.com/istio/istio/issues/59535))

- **修复** 修复了以下问题：具有无效标头值的 `HTTPRoute` 和 `GRPCRoute`
  过滤器会从 Envoy 配置中静默删除，而不是报告 `InvalidFilter` 状态。
  ([Issue #59933](https://github.com/istio/istio/issues/59933))

- **修复** 修复了更改 Kubernetes 网关（或 `ListenerSet`）上的 `istio.io/rev`
  标签时出现的短暂流量中断。先前拥有的控制平面不再删除资源并将空的 xDS 配置推送到仍在旧版本上运行的网关 Pod。
  非拥有修订版的状态写入仍会受到抑制，因此修订版不会因彼此的状态而波动。
  ([Issue #59959](https://github.com/istio/istio/issues/59959))

- **修复** 修复了多网络 Ambient，以便当一个网络上的入口调用另一网络上的服务时，
  它现在路由到 waypoint，并且仅当 `Service` 配置为 `istio.io/ingress-use-waypoint` 时。

- **修复** 修复了以下问题：当路点范围中存在无头服务（`spec.clusterIP: None`）时，
  IPv6 集群上的路点侦听器配置包含带有空 `ranges` 字段的 `IPMatcher.RangeMatcher`。
  产生此问题的原因是，用于无头服务的 IPv4 编码的 `constants.UnspecifiedIP` 占位符 `DefaultAddress` 被 `FilterAddressesByIPFamily` 过滤掉，
  仅用于 IPv6 代理。Envoy 1.38 严格验证原型在 `IPMatcher.RangeMatcher.ranges`
  上的 `repeated.min_items=1` 规则，并拒绝 LDS 推送。现在，当没有要放入的地址时，
  waypoint 侦听器构建器会忽略 `IPRangeMatcher` 条目，与已从 `svcHostnameMap`
  中删除同一情况下的主机名一半的周围代码的现有行为相匹配。
  IPv4 集群在行为上不受影响——之前发出的占位符匹配器没有匹配任何内容。
  ([Issue #60310](https://github.com/istio/istio/issues/60310))

- **修复** 修复了由于 Envoy 回归 (`envoyproxy/envoy#45212`) 导致在批量更新期间未根据端点更改重建 RING_HASH 环，
  因此 `DestinationRule` 中的 `confirmHash` 负载平衡在扩展后不会将流量发送到新端点的问题。
  ([Issue #60312](https://github.com/istio/istio/issues/60312))

- **修复** 修复了当两个 Pod 同时添加到同一节点上的 Ambient 网格时，
  `istio-cni` 代理中出现致命的 `concurrent map writes` Panic 的问题。
  ([Issue #60328](https://github.com/istio/istio/issues/60328))

- **修复** 修复了针对同一主机的 `DestinationRule` 和 Gateway API 后端策略（`BackendTLSPolicy` 或 `XBackendTrafficPolicy`），
  以便 `DestinationRule` 字段现在优先，并且后端策略仅填充 `DestinationRule` 未设置的字段，无论哪个字段先创建。
  ([Issue #60358](https://github.com/istio/istio/issues/60358))

- **修复** 修复了一个 Ambient 模式错误，其中单个服务将 `publishNotReadyAddresses: true`
  与 `PreferSameZone` 或 `PreferSameNode` 流量分配相结合，
  导致 ztunnel 使用相同的流量分配预设为每个其他服务接收 `healthPolicy: AllowAll`，
  从而导致流量被路由到集群范围内未就绪的端点。
  ([Issue #60422](https://github.com/istio/istio/issues/60422))

- **修复** 修复了当 Envoy 管理端点不可用时，代理耗尽可能会出现 Panic 而不是返回错误的问题。

- **修复** 修复了当默认将当前命名空间包含为 `.` 时，
  `meshConfig.defaultServiceExportTo` 和 `meshConfig.defaultVirtualServiceExportTo`
  中的其他命名空间不被接受的问题。
  ([Issue #60560](https://github.com/istio/istio/issues/60560))

- **修复** 修复了从 `ListenerSet` 中删除侦听器会在资源的 `status.listeners` 中无限期留下孤立条目的错误。
  过时的条目使 `status.listeners` 比 `spec.listeners` 长，
  并且在重复侦听器添加/删除周期后，楔入 `ListenerSet` 的 `observedGeneration`，
  因此后来的规范更改不再反映在其状态中。`reportListenerSetStatus`
  现在会修剪规范中不再存在的侦听器的状态条目，以匹配 `Gateway` 资源的现有行为。
  ([Issue #60578](https://github.com/istio/istio/issues/60578))

- **修复** 修复了 `DestinationRule` 验证错误地拒绝 0 到 1 之间的预热攻击值。
  ([Issue #3395](https://github.com/istio/api/issues/3395)),
  ([Issue #55153](https://github.com/istio/istio/issues/55153))

- **修复** 修复了 istiod 在重新启动之前无法获取更新的远程集群 Secret（例如在凭证/令牌轮换期间）的错误。
  新的集群注册表可能会死锁等待同步，从而使受影响的远程集群的服务注册表陈旧。
  ([Issue #60612](https://github.com/istio/istio/issues/60612))

- **修复** 修复了 Istio 1.30 中引入的问题，其中对 `VirtualService` 资源
  （例如 Helm 注释、Argo CD 标签或 `kubectl.kubernetes.io/last-applied-configuration`）
  的仅元数据更改触发了对所有代理的不必要的 XDS 推送。这可能会导致控制平面 CPU 使用率显着增加，
  并且在具有由 GitOps 工具管理的许多 `VirtualService` 资源的集群中推送延迟。
  该修复恢复了 1.30 之前的行为，其中只有规范更改或 `istio.io` 标签/注解更改才会触发推送。
  ([Issue #60629](https://github.com/istio/istio/issues/60629))

- **修复** 修复了使用 `WasmPlugin` 资源时由于 `TrafficExtension` 转换而导致的重复和过多推送。

- **修复** 修复了 istio-cni 节点代理 Pod 可能无法启动的死锁（例如在节点重新启动后），
  因为在启用环境模式时，CNI 插件仅跳过为其自己的代理 Pod 创建 Kube 客户端。
  抢占式检查现在也在 Sidecar 模式下运行，因此代理 Pod 不再阻塞尚未写入的 kubeconfig。
  ([Issue #60668](https://github.com/istio/istio/issues/60668))

- **修复** 修复了 waypoint 入站路由的默认 HTTP 重试。
  `meshConfig.defaultHttpRetryPolicy` 设置现在适用于附加到 waypoint 的本地服务。
  ([Issue #60682](https://github.com/istio/istio/issues/60682))

- **修复** 修复了 `EXIT_ON_ZERO_ACTIVE_CONNECTIONS` 从未在 Ambient 入口网关和 waypoint 上触发的问题，
  因为 Pilot-agent 的排出循环对 Envoy HBONE 内部侦听器
  （`connect_originate`、`connect_terminate`、`main_internal` 等）
  上的进程内连接进行了计数，从而防止活动连接计数达到零并强制代理等待 `terminationGracePeriodSeconds`。
  ([Issue #60728](https://github.com/istio/istio/issues/60728))

- **修复** 修复了 `service.istio.io/canonical-name` 标签在注入模板中被截断为
  63 个字符时可能以无效的 `.` 或 `_` 结尾的问题。

- **修复** 修复了带有空或省略 `backendRefs` 的 `HTTPRoute` 返回 HTTP 404
  状态代码而不是 500 的问题。这与 v1.6.0 中引入的 `HTTPRouteNoBackendRefs`
  Gateway API 一致性测试强制执行的行为相匹配。

- **修复** 修复了宣传的 HBONE 功能未传播到非 Kubernetes 工作负载的自动注册 `WorkloadEntry` 资源上的问题。

- **修复** 修复了引用无效或不存在的 `parametersRef` 时 `Gateway` 上的 `Accepted`
  条件未设置为 `False` 的问题。这与 v1.6.0 中引入的 `GatewayInvalidParametersRef` Gateway API
  一致性测试强制执行的行为相匹配。

- **修复** 修复了当目标服务具有 L7 `AuthorizationPolicy` 资源时，
  通过东西向网关的跨网络流量被虚假拒绝所有 RBAC 过滤器阻止。
  ([Issue #60806](https://github.com/istio/istio/issues/60806))

- **修复** 修复了一个错误，即远程集群的网络网关在凭证轮换后可能会从跨网络路由中消失，
  并且直到 istiod 重新启动后才能恢复。就地注册表交换现在将新注册表重新连接到聚合控制器的处理程序，
  以便其未来的网关和服务事件传播，并重新加载网关一次以获取在预交换同步期间发现的网关。
  ([Issue #60920](https://github.com/istio/istio/issues/60920))

- **修复** 修复了多集群部署中的一个问题，即旋转远程集群的 `istio-remote-secret`
  可能会永久擦除该集群中具有稳定端点的服务的端点分片，从而使它们在重新启动 istiod 之前无法跨集群访问。
  ([Issue #61043](https://github.com/istio/istio/issues/61043))

- **修复** 修复了当不存在 `VirtualService` 时，`DestinationRule` 中的 `consistentHash`
  负载平衡对于在 Ambient 模式下通过路点代理路由的服务不起作用的问题。
  Envoy 集群正确接收了 `lb_policy: RING_HASH`，但入站路由缺少 `hash_policy`，
  导致 Envoy 回退到随机后端选择并破坏粘性会话。以前需要使用无操作直通 `VirtualService` 作为解决方法。
  ([Issue #61045](https://github.com/istio/istio/issues/61045))

- **修复** 修复了 istiod 启动时的竞争条件，其中就绪探针可以在专用注入和验证 Webhook 服务器
  （`--httpsAddr`，默认 `:15017`）接受连接之前报告准备就绪，
  从而在 istiod 准备就绪后立即创建资源时导致间歇性的 `failed calling webhook` 超时。
  这不会影响 Webhooks 共享主 HTTP 服务器（空 `--httpsAddr`）的部署。
  ([Issue #61049](https://github.com/istio/istio/issues/61049))

- **修复** 修复了当远程工作负载位于不同网络上时，入口网关绕过多集群服务的 waypoint 代理，导致授权策略无法执行的问题。
  ([Issue #61092](https://github.com/istio/istio/issues/61092))

- **修复** 修复了在 istiod 启动期间可能永久无法创建网关代理部署的问题。
  ([Issue #61095](https://github.com/istio/istio/issues/61095))

- **修复** 修复了由 `ServiceEntry` `workloadSelector` 选择的 Pod
  启动时可能会在其 Sidecar 的入站配置中缺少该服务的问题。
  到端口的流量未按照 `ServiceEntry` 中声明的协议进行处理，
  并且未应用端口级 `PeerAuthentication`。该 Pod 无法自行恢复；只有重新启动 istiod 才能修复它。
  ([Issue #61157](https://github.com/istio/istio/issues/61157))

- **修复** 修复了 `istio-cni` 认为 `hostNetwork` Pod 符合 Ambient 注册条件的问题。
  ([Issue #61168](https://github.com/istio/istio/issues/61168))

- **修复** 修复了由于存在许多问题，Pilot 在生成代理网关配置时忽略了 `ListenerSet`
  资源以及附加到它们的路由的问题。Pilot 不再过滤掉 `ListenerSet` 资源及其附加路由，
  使 Istio 中的代理网关能够正确处理 `ListenerSet` 资源。

- **修复** 修复了当代理网关的父 `Gateway` 资源不允许 `ListenerSet` 时，
  `ListenerSet` 状态报告。当父 `Gateway` 不允许`ListenerSet` 时，`Accepted` 条件状态现在报告为 `False`，
  而以前的情况并非如此。此外，由于从 Gateway API v1.5.0 开始，`ListenerSet` 功能不再是实验性的，
  因此它不再受 `PILOT_ENABLE_ALPHA_GATEWAY_API` 功能标志的保护。

- **修复** 修复了代理网关 `Gateway` 使用明文而不是 Istio 双向 TLS 连接到 Sidecar 注入（网格）后端的问题。
  以前，路由到网格后端的原始 TCP（通过 `TCPRoute` 或终止模式下的 `TLSRoute`）
  可能因服务器优先协议而挂起（其中后端首先发言，例如 SMTP 或 MySQL），
  并且强制执行 `STRICT` 双向 TLS 的后端无法访问。

- **修复** 修复了 Istiod Ambient 多集群模式中的内存和 goroutine 泄漏，
  其中每个集群节点局部性集合的范围仅限于进程生命周期而不是集群生命周期，
  因此当远程集群被删除时，它们永远不会被拆除。
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **修复** 修复了 Istiod Ambient 多集群模式中的一个错误，
  其中聚合（本地 + 远程）集合可以在发现并同步远程集群之前将自己报告为已同步。
  因此，Istiod 可以开始仅使用本地集群数据提供服务，在启动时暂时忽略远程集群中的工作负载、
  服务和端点。聚合集合现在等待多集群控制器和每个远程集群的集合同步，然后再标记为就绪。

- **修复** 修复了以下问题：在节点或 kubelet 重新启动后，Ambient 注册的 Pod
  可能会被排除在主机运行状况探测 ipset 之外，导致 kubelet 探测被重定向到 ztunnel 并被拒绝，
  直到 `istio-cni` 节点代理重新启动。启动时，节点代理可能会在其 IP 尚未可观察到时从 ipset 中逐出仍注册的 Pod，
  并且现在它会在协调期间重新断言已注册 Pod 的探测 ipset 成员身份。

- **修复** 修复了 istio-cni 节点代理中的文件描述符泄漏：
  当 procfs 扫描发现同一 Pod 的多个网络命名空间时，
  失败候选者的 netns fd 会被丢弃而不会关闭，从而将命名空间固定在内核中直到垃圾收集。

- **修复** 修复了 Ambient CNI 节点代理中的死锁，
  其中与 ztunnel（重新）连接并发的 Pod 删除事件可能会永久阻止 ZDS 服务器。
  ([Issue #1674](https://github.com/istio/ztunnel/issues/1674))

- **修复** 修复了当目标子集未指定端口的 TLS 模式时，端点 mTLS
  模式不是从 `DestinationRule` 顶级流量策略派生的问题。
  子集流量策略现在可以正确回退到 `DestinationRule` 级别 TLS 设置。

- **修复** 修复了 `Gateway` 资源中证书引用的状态报告，以符合网关 API 规范 v1.5.0。
  它更改 `Gateway` 状态以报告 `ResolvedRefs` 类型的条件，
  并且当由于证书无效或不存在而失败时，还会向 `Accepted` 条件添加额外的详细信息。

- **修复** 修复了 Kubernetes `Gateway` 上的 `Accepted` 条件以反映其侦听器的有效性。
  当一个或多个侦听器不被接受时（例如，不支持的侦听器协议），
  `Gateway` 现在会报告 `ListenersNotValid` 原因，
  并且仅在没有任何侦听器被接受时才设置为 `Accepted=False`。
  以前，无论监听者是谁，`Gateway` 总是报告为 `Accepted`。

- **修复** 修复了无代理 gRPC xDS 客户端可能从 Istiod 接收过于广泛的 RDS `RouteConfiguration` 响应的问题。

- **修复** 修复了当侦听器类型为 HTTPS 或 TLS 但未定义 TLS 部分时错误创建内部侦听器的错误。
  Gateway API 的以下版本将[防止](https://github.com/kubernetes-sigs/gateway-api/pull/4788)这种输入组合到达控制器。
  ([Issue #60562](https://github.com/istio/istio/issues/60562))

- **修复** 修复了 1.29.2 之前的 Sidecar 配置生成。

- **修复** 修复了在使用没有目标的 TCP 或 TLS 路由处理 `VirtualService` 时出现 istiod Panic，
  这种情况在未安装验证 Webhook 时可能会发生（例如，没有默认修订版的部署）。
  ([Issue #60110](https://github.com/istio/istio/issues/60110))

- **修复** 修复了当远程集群被删除或更新时，Ambient 多集群模式下 istiod 中的 goroutine 和内存泄漏。
  为每个远程集群构建的内部集合在拆除时不会释放它们在输入上注册的事件处理程序，
  导致 goroutine 和内存随着集群被删除或重新配置而随着时间的推移而累积。
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **修复** 修复了 `krt` 控制器框架中的内存泄漏，其中更改 `Fetch` 过滤器中使用的密钥
  （例如，重新标记 Pod 以指向不同的路径点）会留下从未清理过的陈旧反向索引条目。
  随着时间的推移，这可能会增加内存使用量并导致不必要的重新计算。

- **修复** 修复了 istiod 领导者选举中的一个 goroutine 泄漏，
  其中每个选举周期（领导权丢失和重新获得）都会泄漏一个 goroutine，直到进程退出。
  ([Issue #60843](https://github.com/istio/istio/issues/60843))

- **修复** 修复了 ListenerSet 状态报告，以便没有有效侦听器的 ListenerSet 现在将
  `Accepted` 和 `Programmed` 条件报告为 `False`，原因为 `ListenersNotValid`。
  以前，即使没有侦听器可用，ListenerSet 级别的条件也可以保持 `True`。

- **修复** 修复了多集群 `ClusterStore` 中的死锁，其中 `AllReady` 可以在写入者等待时递归获取存储
  `RWMutex` 以通过 `triggerRecomputeOnSync` -> `GetByID` 读取，
  从而阻止对存储的进一步读取和写入。

- **修复**修复了 Ambient 多集群在凭证轮换后提供远程集群的过时快照。
  每个集群的集合仅通过集群 ID 进行缓存，因此携带新 kubeconfig 的秘密更新会继续重用为上一代构建的集合，
  一旦新的同步，其客户端和通知程序就会关闭。它们现在按代缓存并在新客户端上重建。
  ([Issue #60033](https://github.com/istio/istio/issues/60033))

- **修复** 修复了 Istiod 中的内存泄漏，其中失败的 Pod IP 的 `needResync` 条目从未被清理。

- **修复** 修复了包含网络时的故障转移路由。在确定故障转移优先级时，
  该网络被视为首选网络，但不是必需的。例如，`PreferSameZone` 具有以下优先级顺序：
  网络+区域+区域、网络+区域、网络、区域+区域、区域，并且不匹配。

- **修复** 修复了当两个侦听器名称清理到相同的 `Service` 端口名称（名称仅句点与破折号不同，或仅超过 63 个字符限制）时，
  生成的 `Gateway` `Service` 资源被拒绝，这会阻止 `Gateway` 上的每个未发布的端口。
  现在，冲突的端口名称与侦听器的端口号已消除歧义。

- **修复** 修复了一个错误，当扫描期间第三方进程位于该命名空间内时，
  istio-cni 节点代理可以将环境 Pod 与另一个 Pod 的网络命名空间配对，
  这可能会导致流量使用错误的身份进行代理。节点代理现在会在注册 Pod 之前验证命名空间是否拥有 Pod 的 IP 之一。
  ([Issue #61211](https://github.com/istio/istio/issues/61211))

- **修复** 修复了 ztunnel 重新连接（例如从 `keepaliveMaxServerConnectionAge` 定期连接回收）
  触发完整工作负载 (WDS) 推送的错误。Istiod 现在为每个 WDS 资源分配一个基于内容的版本，
  并且当重新连接的客户端通过 `initial_resource_versions` 报告其已持有的版本时，
  仅重新发送在客户端断开连接时发生更改的资源。不报告版本的较旧 ztunnel 版本将继续接收完整集。
  ([Issue #1966](https://github.com/istio/ztunnel/issues/1966))

- **修复** 修复了 `zoneAwareLbSetting.enabled: false` 以通过发出
  `routing_enabled: 0%` 显式禁用 Envoy 的内部区域感知路由。
  以前，`enabled: false` 是一个无操作：Istio 不发出 `ZoneAwareLbConfig`，
  导致 Envoy 回退到默认的 `routing_enabled: 100%`，只要存在自我发现本地集群，
  它就会自动启用区域感知路由。这使得逐步推出变得不安全，
  因为处于混合状态的 Pod（有些具有自我发现，有些没有）会不均匀地分配流量。

- **升级** Istio distroless 镜像使用的 `nftables` 的升级版本。
  `nftables` 版本之前固定为 1.1.1，以避免在 Istio 使用打包在同一节点上的镜像中的新版本后，
  可能导致 K8s 节点上的旧版本 `nftables` 崩溃的错误。

  主要 Linux 发行版已获悉该问题并已发布修复程序。因此，Istio 正在删除 `nftables` 版本固定。
  建议用户将节点上的 `nftables` 软件包更新到最新可用版本，以确保安装修复版本。

  如果您的节点上继续遇到 `nftables` 崩溃，请降级到旧版本的 Istio，
  并联系您的节点操作系统提供商以请求将修复程序向后移植到您的操作系统版本。
  ([Issue #58492](https://github.com/istio/istio/issues/58492))

- **优化** 优化了 Sidecar 出口服务解析：仅导入精确（非通配符）、
  显式命名空间的主机的侦听器现在通过直接服务索引查找来解析服务，
  而不是扫描命名空间可见的每个服务，将每个侦听器的成本从 `O(services)` 减少到 `O(imported hosts)`，并消除完整列表分配。
  ([Issue #60473](https://github.com/istio/istio/issues/60473))

## 安全 {#security}

- **新增** 添加了 `PILOT_ENABLE_STRICT_GATEWAY_MERGING` 以防止 Istio `Gateway`
  资源与托管 Gateway API `Gateway` 资源的跨命名空间合并。启用后（默认），
  来自不同命名空间的 Istio `Gateway` CRD 不会与托管 Gateway API `Gateway` 代理合并。
  非托管（手动部署）网关 API `Gateway` 资源不受影响。`PILOT_ENABLE_STRICT_GATEWAY_MERGING` 设置为 `false` 以禁用。

- **新增** 在 `AuthorizationPolicy` 中的 `Source` 中添加了 `trustDomains`
  和 `notTrustDomains` 字段，允许用户根据从对等证书派生的信任域来匹配或排除请求。

- **新增** 添加了对 `fips-140-3` 的支持，将其作为 `COMPLIANCE_POLICY` 环境变量的新值。
  这将强制使用符合 FIPS 标准的密码套件（TLS 1.2 使用 ECDHE_[RSA|ECDSA]_WITH_AES_*_GCM_SHA*，
  TLS 1.3 使用 AES-GCM）的 TLS 1.2 或 1.3，并将密钥协商限制为 P-256 或 P-384 曲线。
  在 Envoy 代理端，这将使用原生的 `FIPS_202205` 合规性策略。
  Go 组件（istiod、istio-agent）必须使用 Go 1.24 或更高版本，
  并设置 `GOFIPS140=v1.0.0`（或更高版本的验证版本）才能启用原生的 Go FIPS 140-3 加密模块。
  当通过 Helm `env` 值配置了 `COMPLIANCE_POLICY` 时（例如，`--set pilot.env.COMPLIANCE_POLICY=fips-140-3`），
  `GODEBUG=fips140=only` 环境变量会在运行时自动注入到 sidecar、网关和 istiod 控制平面中。
  注意：`GOEXPERIMENT=boringcrypto`（用于 FIPS 140-2）与此策略不兼容，不得使用。
  BoringCrypto 仅支持 FIPS 140-2，并且与 Go 的原生 FIPS 140-3 模块冲突。

- **新增** 添加了一个新的环境变量 `PILOT_ENABLE_REMOTE_CREDENTIALS_CONTROLLER`
  （默认为 `true`），用于切换远程集群的凭据控制器。

- **修复** 修复了 pilot-agent 在第二次和后续 Kubernetes Secret 轮换中丢失文件安装证书的证书重新加载。
  ([Issue #59912](https://github.com/istio/istio/issues/59912))

- **修复** 修复了 Gateway API 前端 mTLS（`spec.tls.frontend.default.validation.caCertificateRefs`）
  中的 `caCertificateRefs[].kind: Secret` 在运行时被 SDS 拒绝，
  尽管 `Gateway` 配置有效，包括 `ReferenceGrant` 允许的相同命名空间引用和跨命名空间引用。
  ([Issue #60277](https://github.com/istio/istio/issues/60277))

- **修复** 修复了 `EnvoyFilter` 验证差距，其中无上限的 `proxyVersion`
  匹配表达式可能会在正则表达式编译期间驱动过多的 istiod 内存和 CPU。
  匹配表达式现在限制为 1024 个字符。
  
  **来源**：此问题由 [`Artem Cherezov`](https://github.com/cherez0ff) 报告。

- **修复** 修复了通过 `extensionProviders` 配置的外部 SDS 提供程序，
  以使用配置的服务主机名作为 gRPC 权限。

- **修复** 修复了外部 SDS 提供商，以便网关使用凭证名称（去除 `sds://` 前缀后）
  作为 SDS 资源名称而不是提供商名称。这允许使用同一 SDS 提供商的多个网关请求不同的证书。
  对于 `MUTUAL` TLS，CA 证书资源名称正确派生为 `<credential-name>-cacert`。
  当 UDS 套接字和 SDS 扩展提供程序均未配置时，网关现在会回退到通过
  ADS（Kubernetes Secrets）获取证书，而不是默默地失败。
  ([Issue #57080](https://github.com/istio/istio/issues/57080))

- **修复** 修复了如果证书是通过文件提供的（例如，使用 istio-csr 等外部 CA 时），
  istiod 在轮换时不会重新加载其 CA 根证书。

- **修复** 修复了 XDS `api` 生成器（MCP 配置服务）以需要经过验证的控制平面身份。
  以前，任何可以访问 istiod 的 XDS 端口的客户端都可以跨所有命名空间读取 Istio 配置。
  如果需要兼容性，请使用 `ENABLE_XDS_API_GENERATOR_AUTH=false` 禁用。

## 可观测 {#telemetry}

- **改进** 改进了 pilot-agent 的 `/stats/prometheus` 端点，
  使其能够并发抓取由 `prometheus.istio.io/scrape-targets` 注解声明的多个目标，
  并按声明顺序合并输出。单目标 Pod 保留现有的流式代码路径，逐字节执行。
  对于多目标 Pod，OpenMetrics 响应将被重写，以确保合并后的输出包含一个 `# EOF` 终止符。
  单个目标指标响应的大小上限为 10 MiB，以限制代理内存；超过此限制的响应将被丢弃并计为抓取失败。
  每个目标的抓取失败是非阻塞的，并且会增加 `istio_agent_scrape_failures_total{type="application"}` 的值。
  ([Issue #59567](https://github.com/istio/istio/issues/59567))

- **新增** 添加了一个新的环境变量 `PILOT_AGENT_MERGE_ENVOY_STATS`
  来控制 pilot-agent 是否将 Envoy 统计信息合并到其统计端点中。
  设置为 `false` 以禁用将 Envoy 统计信息与代理统计信息合并。

- **新增** 向 istio-cni 节点代理添加了一个新指标 `istio_cni_plugin_requests_total`。
  它对节点代理处理的 CNI 插件添加事件请求进行计数，标记为 `response_code`。
  ([Issue #60878](https://github.com/istio/istio/pull/60878))

- **新增** 添加了一个新的 Pod 注释 `prometheus.istio.io/scrape-targets`，
  允许用户将每个 Pod 的多个应用程序指标端点声明为逗号分隔的 `port:path` 列表。
  与代理状态端口或任何 Istio 保留的数据平面端口发生冲突的目标在注入时会被拒绝，并出现人类可读的错误。
  ([Issue #59567](https://github.com/istio/istio/issues/59567))

- **新增** 添加了两个新的选择加入环境变量 `ENVOY_SECURE_METRICS_PORT`
  和 `ENVOY_SECURE_MERGED_METRICS_PORT`，它们在每个 Envoy Sidecar
  代理上公开受 mTLS 保护的 Prometheus 抓取端点。设置后，Sidecar 会在需要相互 TLS
  的配置端口上添加静态引导侦听器，从而允许 Prometheus 安全地抓取指标，
  而无需依赖 Pod 网络级访问控制。有关详细信息，请参阅
  [RFC](https://docs.google.com/document/d/1BiBOrYU06x5xdsnU0YDlMGOV-iHjZ2m9UVcZ62wKAn8/edit?usp=sharing)。
  ([Issue #50114](https://github.com/istio/istio/issues/50114))

- **修复** 修复了当 Envoy 使用 protobuf 内容类型报告指标时，
  pilot-agent 指标合并产生错误结果的问题。Pilot-agent 中实现的逻辑无法正确处理 protobuf 内容类型，
  因此此更改将允许的内容类型仅限于 `text/plain` 和 `application/openmetrics-text`。
  ([Issue #60322](https://github.com/istio/istio/issues/60322))

- **移除** 删除了 `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY` 功能标志。
  现在始终启用为网关请求生成上游跨度的行为。之前将此设置为 `false` 的用户应删除该配置，因为它将不再产生任何效果。

## 可扩展性 {#extensibility}

- **修复** 修复了一个错误，即引用不同命名空间中的路径点的 `Service`
  没有将命名空间范围的 `Telemetry` 资源包含在其配置中。
  ([Issue #60665](https://github.com/istio/istio/issues/60665))

- **修复** 修复了一个错误，即应用程序命名空间中的 `WasmPlugin` 通过
  `targetRefs` 定位 `Service` 会导致 waypoint 代理在启动时崩溃循环。
  LDS 路径正确地包含了 waypoint 的插件，但 ECDS 查找路径将其视为跨命名空间而拒绝，
  使 Envoy 等待永远不会到达的资源。
  ([Issue #60530](https://github.com/istio/istio/issues/60530))

## 安装 {#installation}

- **更新** 更新了 Kiali 插件至版本 v2.26.0。

- **新增** 添加了 `ZTUNNEL_RESOURCE_CPU_LIMIT` 和 `ZTUNNEL_RESOURCE_CPU_REQUEST`
  环境变量到 ztunnel `DaemonSet`，设置时从配置的 `resources.limits.cpu` / `resources.requests.cpu` 填充。
  ztunnel 使用这些来派生 CPU 感知的工作线程计数。

- **新增** 添加了 istiod（pilot）容器的 `terminationMessagePolicy` Helm 字段，
  允许配置终止消息的填充方式。

- **新增** 在网关 Helm Chart 中添加 `dnsPolicy` 和 `dnsConfig` 字段，
  以便在具有非标准 DNS 要求的环境中自定义 DNS 配置。

- **新增** 向 `istioctl manifestgenerate` 添加了一个 `-o/--output` 标志，
  将生成的清单写入文件而不是 stdout。这避免了依赖 shell 重定向，
  这对于自动化来说很方便，并且在没有可用 shell 的环境中是必需的（例如，没有 shell 的强化 `istioctl` 映像）。

- **新增** 添加了 `values.global.readerServiceAccount` 以及 `name`
  和 `namespace` 字段，以将 `istio-reader` `ClusterRole` 绑定到自定义服务帐户。
  设置后，不会创建默认的 `istio-reader-service-account`，
  而是 `ClusterRoleBinding` 引用指定的服务帐户。无论 `readerServiceAccount` 设置如何，
  将 `global.enableReaderRBAC` 设置为 `false` 都会抑制 `istio-reader`、
  `ClusterRole` 和 `ClusterRoleBinding`。

- **修复** 修复了当 `global.proxy_init.image` 和 `global.proxy.image` 配置不同时，
  `istio-init` 容器会使用错误的图像。
  ([Issue #59066](https://github.com/istio/istio/issues/59066))

- **修复** waypoint 和 kube-gateway 工作负载套接字卷与 SPIRE CSI 驱动程序配置不兼容。
  ([Issue #60108](https://github.com/istio/istio/issues/60108))

- **修复** 修复了当 `global.istioNamespace` 或发布命名空​​间仅为数字（例如 `1234`）时，
  Helm Chart 呈现。渲染清单中的命名空间字段现在被引用，因此 YAML 解析器将它们视为字符串而不是数字。
  ([Issue #60239](https://github.com/istio/istio/issues/60239))

## istioctl

- **新增** 添加了对 `istioctl remote-clusters` 的支持以显示修订版本。

- **新增** 添加了当多个 `ServiceEntry` 资源定义具有冲突协议的相同主机和端口时，
  会出现 `istioctl analyze` 警告（`IST0177`）。
  ([Issue #60447](https://github.com/istio/istio/issues/60447))

- **新增** 添加了 `istioctlanalyze` 检查，`IST0176`，标记安装的 Gateway API CRD
  的版本低于当前 Istio 版本所需的最低版本。此类 CRD 支持的资源会被 istiod 静默过滤，
  此前，在升级到 Istio 1.30 后，使用过时的 Gateway API CRD 很难发现 TLS 直通破坏。

- **修复** 修复了当 Istio 使用修订标签安装在非默认命名空间（`istio-system` 除外）中时，
  `istioctl` 无法发现 istiod。`DefaultWatcher` 现在根据通过
  `-i` 标志传递的 Istio 命名空间构造预期的 Webhook 名称。
  ([Issue #60232](https://github.com/istio/istio/issues/60232))

- **修复** 修复了 `istioctl tag remove` 在删除默认修订标签时不会删除
  `istiod-default-validator` `ValidatingWebhookConfiguration`。
  ([Issue #60537](https://github.com/istio/istio/issues/60537))

- **修复** 修复了包含 `=`  的 `istioctl` 清单 `--set` 值被解析为格式错误的输入的问题。
