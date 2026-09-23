---
title: Istio 1.28.0 更新说明
linktitle: 1.28.0
subtitle: 主要版本
description: Istio 1.28.0 更新说明。
publishdate: 2025-11-05
release: 1.28.0
weight: 10
aliases:
    - /zh/news/announcing-1.28.0
---

## 流量治理 {#traffic-management}

- **升级** 将 Istio 双栈支持提升至 Beta 版。
  ([Issue #54127](https://github.com/istio/istio/issues/54127))

- **更新** 更新了每个套接字事件的最大接受连接数的默认值。现在，
  对于显式绑定到 Sidecar 端口的入站和出站监听器，默认值为 1。
  在连接频繁切换的情况下，未进行 iptables 拦截的监听器将受益于更佳的性能。
  要恢复旧的行为，您可以将 `MAX_CONNECTIONS_PER_SOCKET_EVENT_LOOP` 设置为零。

- **新增** 添加了对一致性哈希负载均衡中 Cookie 属性的支持。
  现在您可以指定其他属性，例如 `SameSite`、`Secure` 和 `HttpOnly`。
  这使得在负载均衡场景中能够更安全、更合规地处理 Cookie。
  ([Issue #56468](https://github.com/istio/istio/issues/56468)),
  ([Issue #49870](https://github.com/istio/istio/issues/49870))

- **新增** 添加了 `DISABLE_SHADOW_HOST_SUFFIX` 环境变量，
  用于控制镜像策略中的影子主机后缀行为。设置为 `true`（默认值）时，
  会在镜像请求的主机名中添加影子主机后缀。设置为 `false` 时，
  则不会添加影子主机后缀。这为从旧版本 Istio 升级的用户提供了向后兼容性，
  因为旧版本默认通过兼容性配置文件添加影子主机后缀。
  ([Issue #57530](https://github.com/istio/istio/issues/57530))

- **新增** 添加了 Gateway API `BackendTLSPolicy` 中的 `sectionName` 支持，
  以启用端口特定的 TLS 配置。这允许按名称指定服务的特定端口，
  从而为每个端口启用不同的 TLS 设置。例如，
  现在您可以仅为服务的 `https` 端口配置 TLS 设置，而其他端口保持不变。

- **新增** 添加了对 `BackendTLSPolicy` 中 `targetRef` 的 `ServiceEntry` 支持。
  这允许用户将 TLS 设置应用于由 `ServiceEntry` 资源定义的外部服务。
  ([Issue #57521](https://github.com/istio/istio/issues/57521))

- **新增** 添加了对使用 Istio Ambient 模式时原生 nftables 的支持。
  此次更新使得可以使用 nftables 代替 iptables 来管理网络规则。
  要启用 nftables 模式，请在安装 Istio 时使用 `--set values.global.nativeNftables=true` 参数。
  ([Issue #57324](https://github.com/istio/istio/issues/57324))

- **新增** 添加了对使用 `DYNAMIC_DNS` 解析的 `ServiceEntry` 资源中的通配符主机的支持。
  目前仅支持 HTTP 流量。需要 Ambient 模式以及配置为出口网关的 waypoint。
  ([Issue #54540](https://github.com/istio/istio/issues/54540))

- **新增** 添加了对 `ProxyConfig.ProxyHeaders` 中 `X-Forwarded` 标头的支持。

- **启用** 启用了 waypoint，以便在 Ambient 多集群中将流量路由到远程网络。
  ([Issue #57537](https://github.com/istio/istio/issues/57537))

- **修复** 修复了 ztunnel 在引用 `Service` 端口名称时无法正确使用 `WorkloadEntry` 端口映射的错误。
  ([Issue #56251](https://github.com/istio/istio/issues/56251))

- **修复** 修复了标签监视器将默认版本与默认标签不一致的问题。这会导致 Kubernetes 网关无法编程。
  ([Issue #56767](https://github.com/istio/istio/issues/56767))

- **修复** 修复了一个错误，即 `InferencePool` 的影子 `Service` 端口号会以 543210 而不是 54321 开头。
  ([Issue #57472](https://github.com/istio/istio/issues/57472))

- **修复** 修复了 Ambient 数据平面无法正确处理解析设置为 `NONE`
  的 `ServiceEntries` 的问题。此前，该配置会有一个虚拟 IP 地址 (VIP) 但没有端点，
  从而导致 "no healthy upstream" 错误。现在，这种情况已配置为 `PASSTHROUGH` 服务，
  这意味着客户端调用的地址将用作后端。
  ([Issue #57656](https://github.com/istio/istio/issues/57656))

- **修复** 修复了启用 HTTP/2 升级时 HTTP/2 连接池设置未应用的问题。
  ([Issue #57583](https://github.com/istio/istio/issues/57583))

- **修复** 修复了 waypoint 部署，使其使用默认的 Kubernetes
  `terminationGracePeriodSeconds`（30 秒），而不是硬编码的 2 秒。

- **新增** 添加了对 `InferencePool` v1 的支持。
  ([Issue #57219](https://github.com/istio/istio/issues/57219))

- **移除** 移除了对 `InferencePool` Alpha 和候选发布版本的支持。

## 安全性 {#security}

- **改进** 改进了根证书解析，当某些证书无效时，
  Istio 现在会过滤掉格式错误的证书，而不是拒绝整个证书包。

- **新增** 在 `ServerTLSSettings` 中添加了 `caCertCredentialName` 字段，
  用于引用保存 mTLS CA 证书的 `Secret`/`ConfigMap`。有关更多信息，
  请参阅[用法](/zh/docs/tasks/traffic-management/ingress/secure-ingress/#key-formats)或[参考](/zh/docs/reference/config/networking/gateway/#ServerTLSSettings-ca_cert_credential_name)。
  ([Issue #43966](https://github.com/istio/istio/issues/43966))

- **新增** 添加了 istiod 的可选 `NetworkPolicy` 部署。
  您可以设置 `global.networkPolicy.enabled=true` 为 istiod 和网关部署默认的 `NetworkPolicy`。
  我们计划稍后将其扩展到 istio-cni 和 ztunnel 的 `NetworkPolicy` 部署。
  ([Issue #56877](https://github.com/istio/api/issues/56877))

- **新增** 添加了对在 Sidecar 注入模板中的 `istio-validation`
  和 `istio-proxy` 容器中配置 `seccompProfile` 的支持。
  用户现在可以将 `seccompProfile.type` 设置为 `RuntimeDefault` 以增强安全合规性。
  ([Issue #57004](https://github.com/istio/istio/issues/57004))

- **新增** 添加了对 Gateway API 中 `FrontendTLSValidation` (GEP-91) 的支持。
  有关更多信息，请参阅[用法](/zh/docs/tasks/traffic-management/ingress/secure-ingress/#configure-a-mutual-tls-ingress-gateway)和[参考](https://gateway-api.sigs.k8s.io/reference/spec/#frontendtlsvalidation)。
  ([Issue #43966](https://github.com/istio/istio/issues/43966))

- **修复** 修复了 JWT 过滤器配置，使其支持自定义空格分隔声明。
  JWT 过滤器配置现在除了默认声明（“scope” 和 “permission”）之外，
  还能正确包含用户指定的自定义空格分隔声明。
  这确保 Envoy JWT 过滤器将这些声明视为空格分隔字符串，
  从而能够正确验证包含这些声明的 JWT 令牌。要设置自定义空格分隔声明，
  请在 `RequestAuthentication` 资源中的 JWT 规则配置中使用 `spaceDelimitedClaims` 字段。
  ([Issue #56873](https://github.com/istio/istio/issues/56873))

- **移除** 移除了使用 MD5 来优化比较。Istio 现在和过去都没有将 MD5 用于加密目的。
  此更改仅仅是为了使代码更易于审计，并能在
  [FIPS 140-3 模式](https://go.dev/doc/security/fips140)下运行。

## 遥测 {#telemetry}

- **更新** 更新了环境变量 `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY`
  的默认值为 `true`，默认情况下启用网关请求的上游 Span 生成。

- **新增** 添加了对注解 `sidecar.istio.io/statsFlushInterval`
  和 `sidecar.istio.io/statsEvictionInterval` 的支持。

- **新增** 添加了对 Zipkin 的 `TraceContextOption` 配置的支持，
  以启用 B3/W3C 双标头传播。在 MeshConfig 的 `extensionProviders` 中配置
  `trace_context_option: USE_B3_WITH_W3C_PROPAGATION`，即可优先提取 B3 标头，
  回退到 W3C `traceparent` 标头，并将两种标头类型注入上游，
  以提高追踪互操作性。有关更多信息，
  请参阅 [Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/trace/v3/zipkin.proto#envoy-v3-api-enum-config-trace-v3-zipkinconfig-tracecontextoption)和
  [`MeshConfig` 参考](/zh/docs/reference/config/istio.mesh.v1alpha1/)和[用法](/zh/docs/tasks/observability/distributed-tracing/)。

- **移除** 移除了指标过期支持。请改用 Bootstrap 配置中的 `StatsEviction`。

## 扩展性 {#extensibility}

- **修复** 修复了根命名空间中使用 `targetRef` 且类型为 `GatewayClass`、
  组为 `gateway.networking.k8s.io` 的 `EnvoyFilter` 没有正确传播的问题。

## 安装 {#installation}

- **更新** 更新 istiod Helm Chart，为远程 istiod 安装创建 `EndpointSlice`
  资源而不是 `Endpoints` 资源，因为从 Kubernetes 1.33 开始，`Endpoints` 已被弃用。
  ([Issue #57037](https://github.com/istio/istio/issues/57037))

- **更新** 已将 Kiali 插件更新至 v2.17.0 版本。

- **新增** 添加了可以完全取消Gateway Chart 中的资源限制或请求的功能。

- **新增** 添加了对 Helm Chart 基于“角色”安装的支持，该安装基于生成/应用的资源的范围。
    - 如果没有设置 `resourceScope`，则会安装所有资源。这与用户对 1.27 版本 Chart 的预期行为一致。
    - 如果将 `resourceScope` 设置为 `namespace`，则只会安装命名空间范围的资源。
    - 如果将 `resourceScope` 设置为 `cluster`，则只会安装集群范围的资源。这样，Kubernetes 管理员可以管理集群中的资源，而网格管理员可以管理网格中的资源。
  对于 ztunnel Chart，`resourceScope` 是一个顶级字段。
  对于所有其他 Chart，它是 `global` 下的一个字段。
  ([Issue #57530](https://github.com/istio/istio/issues/57530))

- **新增** 添加了对环境变量 `FORCE_IPTABLES_BINARY` 的支持，
  以覆盖 iptables 后端检测并使用特定的二进制文件。
  ([Issue #57827](https://github.com/istio/istio/issues/57827))

- **新增** 已将 `.Values.podLabels` 和 `.Values.daemonSetLabels` 添加到 istio-cni Helm Chart 中。

- **新增** 添加了 Gateway Chart 中的 `service.clusterIP` 配置，
  以支持覆盖 `Service` 资源的 `spec.clusterIP` 设置。
  这在用户希望为 Gateway 服务设置特定集群 IP 而不是依赖自动分配的情况下非常有用。

- **新增** 添加了一种使用集群 IP 服务表示修订标签的新方法，
  旨在停止在 Ambient 模式下使用变更 Webhook。`istioctl tag set <tag> --revision <rev>`
  命令和 `revisionTags` Helm 值都会使用当前规范创建一个 `MutatingWebhook`，
  以及一个类似于 istiod `Service` 的 `Service`，但包含 `istio.io/tag` 标签以存储映射关系。

- **新增** 添加了 `internalTrafficPolicy` 选项，
  用于 Gateway 服务（例如，当使用网关作为内部应用程序安装 ArgoCD 时需要此选项）。

- **修复** 修复了默认安装创建的 PDB 阻止 Kubernetes 节点排空的问题。
  ([Issue #12602](https://github.com/istio/istio/issues/12602))

- **升级** Gateway API 支持至 v1.4。这引入了对 `BackendTLSPolicy` v1 的支持。

## istioctl

- **新增** 添加了 `istioctl` 命令默认版本自动检测功能。
  当未显式指定 `--revision` 参数时，将自动使用默认版本（由 `istioctl tag set default` 配置）。
  ([Issue #54518](https://github.com/istio/istio/issues/54518))

- **新增** 添加了对 `istioctl admin log` 参数同时指定 `--level` 和 `--stack-trace-level` 的支持。
  ([Issue #57007](https://github.com/istio/istio/issues/57007))

- **新增** 添加了支持使用 `--proxy-admin-port` 标志为 `istioctl experimental authz`、
  `istioctl proxystatus`、`istioctl bug-report` 和 `istioctl experimental describe` 指定代理管理端口。

- **新增** 添加了标志以支持 `istioctl experimental internal-debug` 的列表调试类型。
  ([Issue #57372](https://github.com/istio/istio/issues/57372))

- **新增** 添加了对显示 `istioctl ztunnel-config all` 连接信息的支持。

- **修复** 修复了 IST0173 分析器 (`DestinationRuleSubsetNotSelectPods`)
  错误地将使用拓扑标签的 `DestinationRule` 子集标记为未选择任何 Pod。
