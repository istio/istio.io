---
title: Istio 1.30.0 更新说明
linktitle: 1.30.0
subtitle: 主要版本
description: Istio 1.30.0 更新说明。
publishdate: 2026-05-18
release: 1.30.0
weight: 10
aliases:
    - /zh/news/announcing-1.30.0
---

## 流量治理 {#traffic-management}

- **改进** 改进了多网络环境下的端点选择机制：当本地代理网络未设置时，将通过网关访问特定于该网络的端点。

- **改进** 改进了 Sidecar 代理服务的命名空间选择机制。
  在配置 Sidecar 代理时，如果某个主机名存在于多个命名空间中，
  Istio 现在会优先选择 Kubernetes 服务；若无 Kubernetes 服务可用，
  则会回退选择创建时间最早的非 Kubernetes 服务（例如 `ServiceEntry`）。
  在此之前，系统会选择按字母顺序排列时排在首位的可见命名空间。

- **新增** 在 Ambient 模式的 waypoint 上，可选择性地合成 `x-forwarded-client-cert` 标头。
  若在 waypoint 的 `Gateway` 资源（或其对应的 `GatewayClass`）上设置注解
  `ambient.istio.io/xfcc-include-client-identity: "true"`，
  该 waypoint 便会在转发请求时重写 XFCC 头部，将其替换为由 ztunnel
  提供的源工作负载 SPIFFE 身份信息；如此一来，上游应用程序便能识别出原始客户端的身份。
  任何入站的 XFCC 值都将被替换。未设置该注解的 waypoint 则不受影响。
  ([Issue #54995](https://github.com/istio/istio/issues/54995))

- **新增** 添加了对 `TLSRoute` 终止及混合模式的支持。
  ([Issue #55728](https://github.com/istio/istio/issues/55728))

- **新增** 添加了环境变量 `PILOT_GATEWAY_TRANSPORT_SOCKET_CONNECT_TIMEOUT`，
  用于配置网关监听器上的传输套接字连接超时时间。默认值仍为 15 秒。
  对于需要较长 TLS 握手时间的负载，可将其设置为 `0s` 以禁用超时。
  ([Issue #56320](https://github.com/istio/istio/issues/56320))

- **新增** 添加了 pilot-agent HTTP 服务器的 HTTP 压缩能力（`gzip`、`zstd`）。
  ([Issue #58697](https://github.com/istio/istio/issues/58697))

- **新增** 添加了对 `traffic.sidecar.istio.io/excludeInterfaces` 注解的输入校验，
  以确保仅接受有效的 Linux 接口名称，从而防止 `iptables` 参数注入。
  ([Issue #58781](https://github.com/istio/istio/issues/58781))

- **新增** 支持从由 `PILOT_MULTICLUSTER_KUBECONFIG_PATH` 指定的本地文件系统路径加载多集群远程 Secret。
  设置该参数后，Istiod 将监视挂载的目录（查找 `.yaml` 或 `.yml` 格式的密钥文件），
  并动态更新远程集群注册信息。如果同时设置了 `PILOT_MULTICLUSTER_KUBECONFIG_PATH` 和 `LOCAL_CLUSTER_SECRET_WATCHER`，
  则 `PILOT_MULTICLUSTER_KUBECONFIG_PATH` 具有优先权。
  ([Issue #58927](https://github.com/istio/istio/issues/58927))

- **新增** 添加了 Istio 中对 Agentgateway 的实验性支持。
  可通过 `PILOT_ENABLE_AGENTGATEWAY` 特性标志启用 Agentgateway 配置。
  Istio 支持通过 Gateway API 资源进行 Agentgateway 配置。
  ([Issue #59209](https://github.com/istio/istio/issues/59209))

- **新增** 添加了在 Ambient 模式下对 `ServiceEntry` 的 CIDR 地址支持。
  包含 CIDR 地址（例如 `10.0.0.0/24`）的 `ServiceEntry` 现已同步至 ztunnel，
  从而为流向特定 IP 地址范围的流量启用最长前缀匹配路由。
  ([Issue #59797](https://github.com/istio/istio/issues/59797))

- **新增** 添加了通过特性标志 `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE`
  和 `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE`，可配置 HBONE CONNECT
  上游集群（专为 waypoint 和东西向网关生成）的初始 HTTP/2
  流窗口大小及连接窗口大小的功能。利用此功能，可有效减少不必要的缓冲。
  ([Issue #59961](https://github.com/istio/istio/issues/59961))

- **新增** 添加了一个 `istio.io/connect-strategy` 注解至 `ServiceEntries`，
  以支持不同的 DNS 连接语义。当 DNS 服务器返回多个 A 记录，
  且客户端需要逐一测试各个端点并选取首个成功建立 TCP 连接的端点时，
  用户可将此注解设置为 `RACE_FIRST_TCP_CONNECT`。
  ([Issue #59083](https://github.com/istio/istio/issues/59083))

- **新增** 添加了 DNS 集群的故障转移优先级支持。
  ([Issue #58674](https://github.com/istio/istio/issues/58674))

- **新增** 添加了可通过 `DNS_FORWARD_TIMEOUT` 环境变量配置 DNS 上游服务器的超时时间。
  默认超时时间仍为 5 秒。用户可以针对高延迟的 DNS 服务器适当增加超时时间；
  也可以在 DNS 服务器无响应时缩短超时时间，从而减少对用户体验造成的影响（即“快速失败”，以便更快地尝试下一个服务器）。
  该参数可在 `istio-proxy` 容器中通过设置 `DNS_FORWARD_TIMEOUT=10s` 进行配置，
  或通过 `proxyMetadata` 在整个服务网格范围内进行统一配置。
  ([Issue #59813](https://github.com/istio/istio/issues/59813))

- **新增** 添加了对东西向网关上 TLS 透传监听器的支持，
  允许通过 Gateway API 暴露非 HBONE 端口（例如，跨网络边界将流量路由至
  Kubernetes API 服务器）。此功能要求启用 `AMBIENT_ENABLE_MULTI_NETWORK`。
  ([Issue #59223](https://github.com/istio/istio/issues/59223))

- **新增** 添加了命名空间级别的流量分配注解。当服务未显式设置流量分配时，将继承命名空间注解中的配置。
  ([Issue #58701](https://github.com/istio/istio/issues/58701))

- **新增** 添加了对 Sidecar 代理的 `DYNAMIC_DNS` 通配符 `ServiceEntry` 支持，
  适用于 `MESH_INTERNAL` 和 `MESH_EXTERNAL` 两种位置。
  这使得在传统的 Sidecar 模式下，能够针对通配符主机（例如 `*.example.com`）
  实现 L7 HTTP 路由（通过 Host 标头）和 L4 TLS 路由（通过 SNI），
  并提供相应的可观测性。请注意，对于匹配该通配符主机的 TLS 连接，
  存在 SNI 欺骗的可能性。例如，一个连接至 `foo.example.com` 的客户端，
  可能通过 `*.example.com` 这一 `ServiceEntry` 建立连接，
  但其 SNI 字段却被设置为 `bar.example.com`。
  ([Issue #58244](https://github.com/istio/istio/issues/58244))

- **新增** 添加了 `TrafficExtension` API 至扩展包，为 Lua 扩展能力提供了第一流的支持。

- **启用** 默认启用了 `protocol: TLS` 的 Gateway 监听器。
  现在，配置了 `protocol: TLS` 的 Gateway 监听器（用于通过 `TLSRoute` 实现 TLS 透传）无需设置
  `PILOT_ENABLE_ALPHA_GATEWAY_API=true` 即可被接纳，
  因为在 Gateway API `v1.5.0` 版本中，`TLSRoute` 已正式升级为 GA（通用可用）状态。

- **修复** 修复了一个导致无法将 Kubernetes 用户命名空间（`hostUsers: false`）Pod
  与 istio-cni 配合使用的问题。目前仅支持包含 `nsenter` 二进制文件的操作系统。
  ([Issue #58750](https://github.com/istio/istio/issues/58750))

- **修复** 修复了 Gateway API 的 CORS 处理：在使用通配符源时正确解析 `Origin` 标头，
  忽略不匹配的预检请求，并全面实施更严格的 `Origin` 标头解析规则。
  ([Issue #59018](https://github.com/istio/istio/issues/59018),
  [Issue #59026](https://github.com/istio/istio/issues/59026))

- **修复** 修复了一个问题：当仅存在 TLS 端口时，waypoint 未能添加 TLS 检查器监听器过滤器，
  导致针对 `resolution: DYNAMIC_DNS` 的通配符 `ServiceEntry` 资源，基于 SNI 的路由失效。
  ([Issue #59024](https://github.com/istio/istio/issues/59024))

- **修复** 修复了基于文件的配置存储中错误封装的问题，
  现改用 `%w` 动词，从而实现了通过 `errors.Is()` 和 `errors.As()` 进行正确的错误链传播。
  ([Issue #59078](https://github.com/istio/istio/issues/59078))

- **修复** 修复了 Gateway API `tls.Options[gateway.istio.io/tls-terminate-mode]`，
  使其能够在 `CACertificateRefs` 处理完成后正确覆盖 TLS 模式。
  ([Issue #59098](https://github.com/istio/istio/issues/59098))

- **修复** 修复了 `ServiceEntry` 验证（针对 `DYNAMIC_DNS` 解析）中一处空指针解引用问题，该问题可能导致 istiod 崩溃。
  ([Issue #59171](https://github.com/istio/istio/issues/59171))

- **修复** 修复了 `cni` 代理的行为，使其遵循 `excludeNamespaces` 配置，
  从而确保插件与代理之间的行为保持一致。
  ([Issue #59295](https://github.com/istio/istio/issues/59295))

- **修复** 修复了当 `PILOT_ENABLE_AMBIENT=true` 但未设置
  `AMBIENT_ENABLE_MULTI_NETWORK`，且存在一个网络配置与本地集群不同的
  `WorkloadEntry` 资源时，istiod 发生崩溃的问题。
  ([Issue #59321](https://github.com/istio/istio/issues/59321))

- **修复** 修复了一个导致单网络环境下（无东西向网关）多集群 waypoint 路由失效的问题。
  ([Issue #58133](https://github.com/istio/istio/issues/58133))

- **修复** 修复了一个问题：当 `HTTPRoute` 未指定 `backendRefs` 时，
  本应返回 HTTP 404 状态码，却错误地返回了 500。根据 Gateway API 规范，
  未包含任何后端引用的路由应返回 404；而包含后端引用、但所有引用权重均为零的路由，才应返回 500。
  ([Issue #59356](https://github.com/istio/istio/issues/59356))

- **修复** 修复了在控制平面未更新 `istio-reader` `ClusterRole` 导致无法从远程 `ConfigMap` 读取信任域时，
  多集群安装过程中会尝试验证错误的信任域的问题。现在，
  istiod 将回退使用本地网格配置中指定的信任域，直至其能够成功读取远程信任域为止。
  ([Issue #59474](https://github.com/istio/istio/issues/59474))

- **修复** 修复了将多个针对同一主机名的 `VirtualService` 资源应用到 waypoint 的问题。
  ([Issue #59483](https://github.com/istio/istio/issues/59483))

- **修复** 修复了一个 Bug：由于 Envoy 中的连接池配置有误，
  E/W 网关偶尔会将 HBONE 连接路由至错误的服务。
  ([Issue #58630](https://github.com/istio/istio/issues/58630))

- **修复** 修复了网关部署控制器在协调过程中拒绝 `DaemonSet` 类型的问题。
  ([Issue #59498](https://github.com/istio/istio/issues/59498))

- **修复** 修复了 istiod 重启后，所有 `Gateways` 均被重启的问题。
  ([Issue #59709](https://github.com/istio/istio/issues/59709))

- **修复** 修复了在 AWS EKS 上使用“Pod 安全组”（即分支 ENI）时，
  Ambient Mesh Pod 出现 kubelet 健康探针失败的问题。
  Istio-CNI 现在能够识别分支 ENI Pod，并添加 IP 规则，
  将探针流量通过 veth 对进行路由，而非经由 VPC 网络结构。
  此功能受 `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` 标志控制（默认启用）。

- **修复** 修复了在包含双栈东西向网关负载均衡器的多网络网格中，
  istiod 会向仅支持 IPv4 的代理推送不可达的 IPv6 网关端点（反之亦然）的问题。

- **修复** 修复了一个竞态条件问题：当 `HTTPRoutes` 被添加后随即被移除时，
  会导致程序发生 Panic。这种情况通常发生在用户应用了 `HTTPRoute`，
  但在控制器尚未有机会对其进行处理之前，便将其删除了。

- **修复** 修复了一个导致 `HTTPRoute` 和 `GRPCRoute` 无法在同一网关主机名上无冲突共存的问题。
  ([Issue #59222](https://github.com/istio/istio/issues/59222))

- **修复** 修复了当 `DefaultAddress` 的 IP 族与代理所支持的 IP 族不匹配时，
  `GetAllAddressesForProxy` 会向代理返回不可达的服务地址的问题。

- **修复** 修复了 `ReferenceGrant` 的 `to` 字段，使其能够正确处理多个条目；
  此前仅最后一个条目生效，导致对于匹配了较早条目的引用，会错误地判定为 `RefNotPermitted`。

- **修复** 修复了 `Gateway` 和 `ListenerSet` 资源的状态报告机制，
  使其符合 Gateway API `v1.5.0` 规范。具体而言，它将 `Gateway` 的状态报告内容进行了调整：
  在 `Gateway` 资源的 `AttachedListenerSets` 字段中，
  现在显示的是 `ListenerSet` 的数量，而非 Listener 的数量。
  此外，它还修改了 `ListenerSet` 的状态报告方式，使其能够报告该
  `ListenerSet` 内每个 Listener 所关联的路由数量。

- **修复** 修复了一个 Bug：`DestinationRule` 中 `retryBudget`
  的默认 `percent` 值被错误地设置为 0.2%，而非预期的 20%。
  ([Issue #59504](https://github.com/istio/istio/issues/59504))

- **修复** 修复了一个 Bug：当目标服务（Destination）包含定义了独立
  `trafficPolicy` 的子集（Subset）时，在 `DestinationRule`
  的顶层 `trafficPolicy` 中设置的 `retryBudget` 会被静默丢弃；
  此外，在子集层级定义的 `retryBudget` 也同样会被忽略。
  ([Issue #59667](https://github.com/istio/istio/issues/59667))

- **修复** 修复了当 `ServiceEntry` 更新后不再符合 IP 自动分配条件时，
  陈旧的 `status.addresses` 未被清除的问题。
  ([Issue #58974](https://github.com/istio/istio/issues/58974))

- **修复** 修复了一个导致间歇性出现 `proxy::h2 ping error: broken pipe` 错误日志的竞态条件。
  ([Issue #59192](https://github.com/istio/istio/issues/59192)),
  ([Issue #1346](https://github.com/istio/ztunnel/issues/1346))

## 安全性 {#security}

- **新增** 添加了对每个工作负载配置多个 CUSTOM 授权提供者的支持，
  从而允许针对不同的 API 路径应用不同的认证方案（如 OAuth、LDAP、API 密钥）。
  ([Issue #57933](https://github.com/istio/istio/issues/57933)),
  ([Issue #55142](https://github.com/istio/istio/issues/55142)),
  ([Issue #34041](https://github.com/istio/istio/issues/34041))

- **新增** 添加了当 `ENABLE_DEBUG_ENDPOINT_AUTH=true` 时，允许为调试端点指定授权的命名空间的功能。
  可通过将 `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` 设置为以逗号分隔的授权命名空间列表来启用此功能。
  系统命名空间（通常为 `istio-system`）始终拥有授权。

- **修复** 修复了 `meshConfig.tlsDefaults.minProtocolVersion`
  在下游 TLS 上下文中被错误映射至 `tls_minimum_protocol_version` 的问题。
  ([Issue #58912](https://github.com/istio/istio/issues/58912))

- **修复** 修复了 `AuthorizationPolicy` 中的 `serviceAccount` 匹配正则表达式，
  现可正确引用服务账号名称，从而确保能够正确匹配名称中包含特殊字符的服务账号。
  （[CVE-2026-39350](https://nvd.nist.gov/vuln/detail/CVE-2026-39350)）
  ([Issue #59700](https://github.com/istio/istio/issues/59700))

  **致谢**：此漏洞由 Wernerina (<https://github.com/Wernerina>) 发现并报告。

- **修复** 修复了一个问题：istiod 可能会签发其 `NotAfter` 时间晚​​于签发证书过期时间的叶证书。
  ([Issue #59768](https://github.com/istio/istio/issues/59768))

- **修复** 修复了 `AuthorizationPolicy` 在匹配 SPIFFE 身份和命名空间时存在的授权绕过漏洞。
  在生成的 Envoy 配置中，`source.principals`（后缀匹配）和 `source.namespaces`
  等字段中的正则表达式元字符未被正确转义，这可能导致非预期的身份意外匹配到策略规则。
  ([Issue #59992](https://github.com/istio/istio/issues/59992))

  **致谢**：此漏洞由 Alex (<https://github.com/Alex0Young>) 发现并报告。

- **修复** 修复了一个 Bug：当证书顺序不同时，CA 捆绑包（CA bundle）的轮换操作无法正常触发。
  在进行比对时，仅考量标准的 `CERTIFICATE` PEM 块；
  其他类型的块（例如 `TRUSTED CERTIFICATE`）将被忽略，
  这与 Istio 中现有的 CA 捆绑包处理机制保持一致。
  ([Issue #59909](https://github.com/istio/istio/issues/59909))

- **修复** 修复了一个严重的安全漏洞：Istio 的 JWKS 回退机制存在 RSA 私钥泄露风险，
  导致攻击者在 JWKS 获取失败时能够伪造 JWT 令牌并绕过身份验证。
  详情请参阅 [CVE-2026-31837](https://nvd.nist.gov/vuln/detail/CVE-2026-31837)。
  ([Advisory GHSA-v75c-crr9-733c](https://github.com/istio/istio/security/advisories/GHSA-v75c-crr9-733c))

  **致谢**：此漏洞由 1seal (<https://github.com/1seal>) 发现并报告。

- **修复** 修复了 JWKS URI 的 CIDR 阻断问题：通过在自定义的 `DialContext`
  中使用自定义控制函数来实现。该控制函数会在 DNS 解析完成后、
  实际发起连接（dialing）之前对连接进行过滤，从而确保阻断策略能够跟随重定向及签发者（issuer）的发现路径。
  此外，此方案还保留了默认 `DialContext` 中的各项特性，
  例如“Happy Eyeballs”机制以及 `dialSerial`（按顺序逐一尝试已解析的 IP 地址）功能。
  ([CVE-2026-41413](https://nvd.nist.gov/vuln/detail/CVE-2026-41413))

  **致谢**：此漏洞由 KoreaSecurity (<https://github.com/KoreaSecurity>)、1seal (<https://github.com/1seal>) 和 AKiileX (<https://github.com/AKiileX>) 发现并报告。

- **修复** 修复了 XDS 调试端点（`syncz`、`config_dump`）以强制要求身份验证。
  此前，在明文 XDS 端口 15010 上无需身份验证即可访问。
  此行为由 `ENABLE_DEBUG_ENDPOINT_AUTH` 标志控制（与 HTTP 调试端点使用同一标志）。
  ([CVE-2026-31838](https://nvd.nist.gov/vuln/detail/CVE-2026-31838))

  **致谢**：此漏洞由 1seal (<https://github.com/1seal>) 发现并报告。

- **修复** 修复了由 `StatusGen` 提供的 XDS 调试端点（`istio.io/debug/syncz`、
  `istio.io/debug/config_dump`）现已强制执行同命名空间授权策略，
  以限制非系统调用方。此前，来自任意命名空间的已认证工作负载均可枚举代理，
  并获取其他命名空间内工作负载的配置转储。

  **致谢**：此漏洞由 1seal (<https://github.com/1seal>) 发现并报告。

- **修复** 修复了通过验证 Bearer Token 领域（Realm）URL，
  修复了 `WasmPlugin` 图像获取过程中潜在的 SSRF 漏洞。

  **致谢**：此漏洞由 Luntry 的 Sergey Kanibor（<https://github.com/r0binak>）发现并报告。

- **修复** 修复了 istiod webhook HTTPS 服务器（端口 15017）缺失
  `ReadHeaderTimeout` 和 `IdleTimeout` 的问题，
  使其与 HTTP 服务器（端口 8080）现有的超时设置保持一致。

- **修复** 修复了 XDS 调试端点，使其传递调用方命名空间，以确保正确的授权检查。

## 遥测 {#telemetry}

- **新增** 添加了在填充 `source_app` 和 `destination_app` 指标标签时，
  使用 `app.kubernetes.io/name` 和 `service.istio.io/canonical-name` 标签的支持。
  其优先级顺序为：`app`（用于向后兼容），其次是 `app.kubernetes.io/name`，
  最后是 `service.istio.io/canonical-name`。这一改进确保了仅配置了
  `app.kubernetes.io/name` 标签的用户，其指标数据也能得到正确填充。
  ([Issue #58436](https://github.com/istio/istio/issues/58436))

- **新增** 添加了 Telemetry Tracing API 中的 `disableContextPropagation` 字段，
  允许用户独立于 Span 上报功能，禁用追踪上下文头（例如 `X-B3-*`、`traceparent`）的传播。
  这有助于在维持内部可观测性的同时，防止追踪上下文在出口网关处发生泄漏。
  ([Issue #58871](https://github.com/istio/istio/issues/58871))

- **新增** 添加了支持对追踪 Span 进行符合 OpenTelemetry 语义约定的服务属性丰富。
  当 `MeshConfig` 中的 `OpenTelemetryTracingProvider` 配置项设置为
  `serviceAttributeEnrichment: OTEL_SEMANTIC_CONVENTIONS` 时，
  `service.name` 将依据 OTel K8s 服务属性规范的回退链进行计算。
  此外，`service.namespace`、`service.version` 和 `service.instance.id`
  会在 Sidecar 注入时作为 `OTEL_RESOURCE_ATTRIBUTES` 注入到 Sidecar 中，
  同时自动启用环境资源探测器（Environment resource detector），
  从而确保 Envoy 在启动时能够获取到这些属性。
  ([Issue #55026](https://github.com/istio/istio/issues/55026))

- **新增** 添加了资源使用面板至 ztunnel Grafana 仪表板，
  用于叠加显示每个实例的活跃 TCP 连接、打开的文件描述符及打开的套接字数量。

- **修复** 修复了一个问题，基于 Baggage 的对等元数据发现机制干扰了
  TLS 或 PROXY 流量策略的正常运行。作为一项短期修复措施，
  我们针对配置了 TLS 或 PROXY 流量策略的路由禁用了基于 Baggage 的元数据发现功能；
  这可能导致在多集群部署环境中，遥测数据出现不完整的情况。
  我们正致力于在未来的版本中解决这一局限性。
  ([Issue #59117](https://github.com/istio/istio/issues/59117))

## 可扩展性 {#extensibility}

- **新增** 添加了支持通过 `ISTIO_WASM_MAX_BINARY_SIZE_BYTES` 环境变量配置 Wasm 二进制文件大小限制。
  ([Issue #59322](https://github.com/istio/istio/issues/59322))

- **修复** 修复了针对通过 HTTP 获取的经 gzip 解压后的 WASM 二进制文件，
  修复了缺失大小限制的问题，使其与已应用于其他获取路径的限制保持一致。

## 安装 {#installation}

- **新增** 添加了 `istio-cni` Helm Chart 中的 `useAppArmorAnnotation` 值。
  其默认值为 `true`。当该值为 `true` 时，AppArmor 配置文件将通过
  `container.apparmor.security.beta.kubernetes.io` 注解进行设置（该注解在 Kubernetes 1.30 版本中已被弃用）；
  否则，将使用 `securityContext` 中的 `appArmorProfile` 字段。
  ([Issue #54721](https://github.com/istio/istio/issues/54721))

- **新增** 添加了 `values.global.enableReaderRBAC`（默认值：`true`），
  用于控制 `istio-reader-service-account` 及其相关的 `istio-reader`
  `ClusterRole`/`ClusterRoleBinding` 的安装，以支持多集群远程 Secret 工作流。
  将其设置为 `false` 即可禁用这些资源的安装。若使用 Helm 进行安装，
  请务必在 `base` 和 `istiod` 这两个 Chart 中均设置 `global.enableReaderRBAC=false`，
  因为 `ServiceAccount` 是由 `base` Chart 渲染的，
  而相关的 `ClusterRole`/`ClusterRoleBinding` 则是由 `istiod` Chart 渲染的。
  ([Issue #56326](https://github.com/istio/istio/issues/56326))

- **新增** 添加了对 Helm v4（服务器端应用）的支持。
  修复了 Webhook `failurePolicy` 字段的所有权冲突，
  该冲突曾导致使用 SSA 执行 `helm upgrade` 时失败。
  ([Issue #58302](https://github.com/istio/istio/issues/58302)),
  ([Issue #59367](https://github.com/istio/istio/issues/59367))

- **新增** 添加了通过 `networkGatewayPorts` 值，为网络网关服务添加了可配置的端口覆盖功能。
  ([Issue #59072](https://github.com/istio/istio/issues/59072))

- **新增** 添加了模板验证：当 `service.ports` 为空且未设置 `networkGateway` 时，提前报错。
  ([Issue #59072](https://github.com/istio/istio/issues/59072))

- **新增** 添加了在 istiod 日志中记录所有 Istio 资源类型（如 `DestinationRule`、
  `EnvoyFilter`、`Sidecar` 等）的配置分析警告与错误，
  从而使运维人员无需再逐一检查各个资源的状态字段即可发现配置错误。
  ([Issue #59105](https://github.com/istio/istio/issues/59105))

- **新增** 添加了 `WaypointBound` 状态条件至 `WorkloadEntry` 资源，
  用于报告工作负载是否已成功连接至其 waypoint 代理，或在绑定过程中是否发生了错误。
  ([Issue #59993](https://github.com/istio/istio/issues/59993))

- **新增** 添加了 `pilot-discovery` 的 `--tls-min-version` 标志，
  用于配置 istiod 服务器和 Webhook 的最低 TLS 版本。支持的值包括 `1.2`（默认值）和 `1.3`。
  ([Issue #58789](https://github.com/istio/istio/issues/58789))

- **新增** 添加了 `registry.istio.io` 作为 Istio 镜像的默认注册表。

- **新增** 添加了 `ztunnel` Helm Chart 中的 `dnsPolicy` 和 `dnsConfig` 字段，
  用于在具有非标准 DNS 需求的环境中进行自定义 DNS 配置。

- **修复** 添加了 CNI 配置文件权限设置：为符合 CIS Kubernetes 基准测试 `v1.12` 的要求，
  默认权限现已更改为 `0600`，而非此前的 `0644`。若需启用组读取权限，
  可在 `istio-cni-node` DaemonSet 上设置环境变量 `values.cni.env.CNI_CONF_GROUP_READ=true`，
  此时权限将被设置为 `0640`。
  ([Issue #59071](https://github.com/istio/istio/issues/59071))

- **修复** 修复了多主部署升级过程中发生的空指针解引用问题。
  ([Issue #59153](https://github.com/istio/istio/issues/59153))

- **修复** 修复了一个问题：将资源限制或请求设置为 `null` 时，
  会导致验证错误（提示“CPU 请求必须小于或等于 0 的 CPU 限制”）。
  此问题影响了代理注入、网关生成以及 Helm Chart 部署。
  ([Issue #58805](https://github.com/istio/istio/issues/58805))

- **修复** 修复了启用 Untaint 控制器时，`istiod`
  部署中缺失 `PILOT_ENABLE_NODE_UNTAINT_CONTROLLERS` 环境变量的问题。
  ([Issue #52050](https://github.com/istio/istio/issues/52050))

- **修复** 修复了因 `NetworkPolicy` 入站规则中的 `from: []` 导致的不必要 Helm 协调问题。

- **修复** 修复了一个问题：在使用支持 `.Release.IsUpgrade`
  的工具（如 Helm 4 和 Flux）执行 `helm upgrade` 并启用服务器端应用（SSA）时，
  `ValidatingWebhookConfiguration` 资源上出现的字段管理器冲突。
  现在，在执行升级操作时，Webhook 模板中将省略 `failurePolicy` 字段，
  从而保留 Webhook 控制器在运行时设置的实际值。对于那些结合 SSA 使用 `helm template` 的工具，
  请将配置项 `base.validationFailurePolicy` 设置为 `Fail`，以避免此类冲突。

## istioctl

- **改进** 改进了 `istioctl bug-report` 命令的性能。

- **新增** 添加了 `--skip-cluster-dump`、`--skip-analyze`、
  `--skip-proxy-debug`、`--skip-netstat` 和 `--skip-coredumps`
  标志至 `istioctl bug-report` 命令，允许跳过报告中耗时较长的部分。

- **修复** 修复了日志获取功能，现支持通过包含和排除规则筛选 Pod。

- **新增** 添加了 `--tail` 标志，用于设置每个容器获取的日志行数上限。默认值仍为无限制。

- **变更** 更新了最低支持的 Kubernetes 版本至 `1.32.x`。

- **新增** 添加了 `istioctl` 命令的端口验证功能，以防止输入超出 1-65535 范围的无效值。
  ([Issue #58584](https://github.com/istio/istio/issues/58584))

- **新增** 添加了对 `istioctl proxy-status -oyaml/json` 的支持，用于列出单个命名空间的代理状态。
  ([Issue #59377](https://github.com/istio/istio/issues/59377))

- **新增** 添加了一项 `istioctl analyze` 警告 (IST0175)，
  用于提示当存在 `RequestAuthentication` 资源，但 istiod 上未配置
  `BLOCKED_CIDRS_IN_JWKS_URIS` 的情况。
  ([Issue #59523](https://github.com/istio/istio/issues/59523))

- **新增** 添加了 `istioctl proxy-status` 子命令的 JSON 和 YAML 输出选项。
  ([Issue #56880](https://github.com/istio/istio/issues/56880))

- **新增** 添加了支持按工作负载 Pod 名称过滤 `istioctl ztunnel-config workload`
  和 `istioctl ztunnel-config connections` 的输出。

- **修复** 修复了一个问题：当 `EnvoyFilter` 对 `VIRTUAL_HOST`
  执行 `REPLACE` 操作时，`istioctl` 会错误地报告错误。
  ([Issue #59495](https://github.com/istio/istio/issues/59495))

- **修复** 修复了 `istioctl ztunnel-config connections`
  中的一个排序错误，该错误导致输出排序结果不确定。
  ([Issue #59775](https://github.com/istio/istio/pull/59775))

- **修复** 修复了一个问题：`istioctl ztunnel-config service`
  命令的 JSON 和 YAML 输出中，未包含来自 ztunnel 配置转储的 `canonical` 字段。
  ([Issue #59962](https://github.com/istio/istio/issues/59962))

- **修复** 修复了一个问题：`istioctl ztunnel-config service`
  的 JSON 和 YAML 输出中未包含来自 ztunnel 配置转储的 `cidrVips`。
  ([Issue #59962](https://github.com/istio/istio/issues/59962))

- **修复** 修复了一个问题，即无发行版（distroless）的
  `istioctl` 容器使用了错误的基础镜像进行构建。

## 文档变更 {#documentation-changes}

- **变更** 更新了 Gateway API 推理扩展文档的位置；现已移至“架构”部分。
  ([Issue #56948](https://github.com/istio/istio/issues/56948))
