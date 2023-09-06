---
title: Istio 1.19.0 更新说明
linktitle: 1.19.0
subtitle: 次要版本
description: Istio 1.19.0 更新说明。
publishdate: 2023-09-05
release: 1.19.0
weight: 20
---

## 弃用通知 {#deprecation-notices}

These notices describe functionality that will be removed in a future release according to [Istio's deprecation policy](/docs/releases/feature-stages/#feature-phase-definitions). Please consider upgrading your environment to remove the deprecated functionality.
以下通知说明了根据 [Istio 的弃用政策](/zh/docs/releases/feature-stages/#feature-phase-definitions)将在未来某个版本中移除的功能。
请考虑升级您的环境以移除弃用的功能。

### Artifacts
### 制品 {#artifacts}

The macOS and Windows artifacts without an architecture specified in the name (ex: `istio-1.18.0-osx.tar.gz`). They will be removed in several releases. They have been replaced by artifacts containing the architecture in the name (ex: `istio-1.18.0-osx-amd64.tar.gz`). ([Issue #45677](https://github.com/istio/istio/issues/45677))
名称中未指定架构的 macOS 和 Windows 制品
（例如：`istio-1.18.0-osx.tar.gz`）。它们将在几个版本中被删除。
它们已被名称中包含架构的制品所取代（例如：`istio-1.18.0-osx-amd64.tar.gz`）。
[Issue #45677](https://github.com/istio/istio/issues/45677)

## 流量治理 {#traffic-management}

- **Improved** JWT claim based routing to support using `[]` as a separator for nested claim names.
  [Issue #44228](https://github.com/istio/istio/issues/44228)
- **改进** 改进了 JWT 基于声明的路由，支持使用 `[]` 作为嵌套声明名称的分隔符。
  [Issue #44228](https://github.com/istio/istio/issues/44228)

- **Improved** performance of sidecar injection, in particular with pods with a large number of environment variables.
- **改进** 改进了 Sidecar 注入的性能，特别是对于具有大量环境变量的 Pod。

- **Updated** DNS resolution when using `ServiceEntries` so that DNS for multi-network gateways will be resolved at the proxy instead of in the control plane.
- **更新** 更新了使用 `ServiceEntries` 时的 DNS 解析，
  以便多网络网关的 DNS 将被在代理而不是在控制平面中解析。

- **Added** support for `traffic.sidecar.istio.io/excludeInterfaces` annotation in proxy.
  [Issue #41271](https://github.com/istio/istio/issues/41271)
- **新增** 添加了对代理中 `traffic.sidecar.istio.io/excludeInterfaces` 注解的支持。
  [Issue #41271](https://github.com/istio/istio/issues/41271)

- **Added** initial ambient support for `WorkloadEntry`.
  [Issue #45472](https://github.com/istio/istio/issues/45472)
- **新增** 添加了在初始化 Ambient 中对 `WorkloadEntry` 的支持。
  [Issue #45472](https://github.com/istio/istio/issues/45472)

- **Added** ambient support for `WorkloadEntry` resources without an address.
  [Issue #45758](https://github.com/istio/istio/issues/45758)
- **新增** 添加了在 Ambient 中国对没有地址的 `WorkloadEntry` 资源的支持。
  [Issue #45758](https://github.com/istio/istio/issues/45758)

- **Added** initial ambient support for ServiceEntry.
- **新增** 添加了在初始化 Ambient 中对 ServiceEntry 的支持。

- **Added** support for regex rewrite in VirtualService `HTTPRewrite`.
  [Issue #22290](https://github.com/istio/istio/issues/22290)
- **新增** 在 VirtualService `HTTPRewrite` 中添加了对正则表达式重写的支持。
  [Issue #22290](https://github.com/istio/istio/issues/22290)

- **Added** a new TLS mode `OPTIONAL_MUTUAL` in `ServerTLSSettings` of Gateway that will validate client certificate if presented.
- **新增** 在网关的 `ServerTLSSettings` 中添加了新的 TLS 模式 `OPTIONAL_MUTUAL`，
  该模式将验证客户端证书（如果存在）。

- **Added** enhancement for Dual Stack to set up the correct DNS family type. `CheckIPFamilyTypeForFirstIPs` has been added to help confirm the IP family type based on the first IP address. Changed the `ISTIO_DUAL_STACK` environment variable to be uniform the for both control and data plane. 
  ([Issue #41462](https://github.com/istio/istio/issues/41462))
- **新增** 添加了对双栈设置正确的 DNS 系列类型的增强。
  添加了 `CheckIPFamilyTypeForFirstIPs`，以帮助根据第一个 IP 地址确认 IP 系列类型。
  将 `ISTIO_DUAL_STACK` 环境变量更改为控制平面和数据平面的统一变量。
  [Issue #41462](https://github.com/istio/istio/issues/41462)

- **Fixed** `WorkloadEntry` resources on different networks to not require an address to be specified.
  ([Issue #45150](https://github.com/istio/istio/issues/45150))
- **修复** 修复了不同网络上的 `WorkloadEntry` 资源不需要指定地址的问题。
  [Issue #45150](https://github.com/istio/istio/issues/45150)

- **Fixed** Istio's Gateway API implementation to adhere to the Gateway API requirement that a `group: ""` field must be set for a `parentRef` of `kind: Service`. Istio previously tolerated the missing group for Service-kind parent references. This is a breaking change; see the upgrade notes for details.
  ([Issue #2309](https://github.com/kubernetes-sigs/gateway-api/issues/2309))
- **修复** 修复了 Istio Gateway API 实现遵循 Gateway API 要求，
  即必须为 `kind: Service` 的 `parentRef` 设置 `group: ""` 字段。Istio 之前容忍了服务类父引用的缺失组。这是一个重大改变；详细信息请参见升级说明。
  [Issue #2309](https://github.com/kubernetes-sigs/gateway-api/issues/2309)

- **Fixed** configuring `istio.alpn` filter for non-Istio mTLS.
  ([Issue #40680](https://github.com/istio/istio/issues/40680))
- **修复** 修复了为非 Istio mTLS 配置 `istio.alpn` 过滤器。
  [Issue #40680](https://github.com/istio/istio/issues/40680)
- **Fixed** the bug where patching `http_route` affects other `virtualhosts`.
  ([Issue #44820](https://github.com/istio/istio/issues/44820))
- **修复**修补“http_route”会影响其他“virtualhosts”的错误。
  [Issue #44820](https://github.com/istio/istio/issues/44820)

- **Fixed** EnvoyFilter operation orders so that deleted and re-added resources don't get deleted.
  ([Issue #45089](https://github.com/istio/istio/issues/45089))
- **修复** EnvoyFilter 操作顺序，以便删除和重新添加的资源不会被删除。
  [Issue #45089](https://github.com/istio/istio/issues/45089)

- **Fixed** `VirtualMachine` `WorkloadEntry` auto register failing with invalid `istio-locality` label when user specified `istio-locality` in `./etc/istio/pod/labels`. 
  ([Issue #45413](https://github.com/istio/istio/issues/45413))
- **修复** 当用户在 `./etc/istio/pod/labels` 中指定 `istio-locality` 时，`VirtualMachine` `WorkloadEntry` 自动注册失败，并出现无效的 `istio-locality` 标签。
  [Issue #45413](https://github.com/istio/istio/issues/45413)

- **Fixed** an issue in dual stack meshes where `virtualHost.Domains` was missing the second IP address from dual stack services.
  ([Issue #45557](https://github.com/istio/istio/issues/45557))
- **修复**双堆栈网格中的一个问题，其中“virtualHost.Domains”缺少双堆栈服务中的第二个 IP 地址。
  [Issue #45557](https://github.com/istio/istio/issues/45557)

- **Fixed** a bug where route configuration is rejected with duplicate domains when `VirtualService` has the same hosts with different case. 
  ([Issue #45719](https://github.com/istio/istio/issues/45719))
- **修复**当“VirtualService”具有不同大小写的相同主机时，路由配置因重复域而被拒绝的错误。
  [Issue #45719](https://github.com/istio/istio/issues/45719)

- **Fixed** an issue where Istiod might crash when a cluster is deleted if the xDS cache is disabled.
  ([Issue #45798](https://github.com/istio/istio/issues/45798))
- **修复**如果禁用 xDS 缓存，删除集群时 Istiod 可能会崩溃的问题。
  [Issue #45798](https://github.com/istio/istio/issues/45798)

- **Fixed** creating `istioin` and `istioout` `geneve` links on nodes which already have configured an external `geneve` link or another `geneve` link for the same VNI and remote IP. To avoid getting errors in these cases, istio-cni dynamically determines available destination ports for created `geneve` links.
- **修复**在已为同一 VNI 和远程 IP 配置外部“geneve”链接或另一个“geneve”链接的节点上创建“istioin”和“istioout”“geneve”链接。 为了避免在这些情况下出现错误，istio-cni 动态确定创建的“geneve”链接的可用目标端口。

- **Fixed** an issue where Istiod can't auto-detect the service port change when the service is referred to by ingress using service port name.
  ([Issue #46035](https://github.com/istio/istio/issues/46035))
- **修复**当入口使用服务端口名称引用服务时，Istiod 无法自动检测服务端口更改的问题。
  [Issue #46035](https://github.com/istio/istio/issues/46035)

- **Fixed** an issue where HTTP probe's `request.host` was not well propagated.
  ([Issue #46087](https://github.com/istio/istio/issues/46087))
- **修复** HTTP 探针的 `request.host` 传播不畅的问题。
  [Issue #46087](https://github.com/istio/istio/issues/46087)

- **Fixed** ambient `WorkloadEntry` xDS events to fire on updates to spec.
  ([Issue #46267](https://github.com/istio/istio/issues/46267))
- **修复**环境`WorkloadEntry` xDS 事件以在规范更新时触发。
  [Issue #46267](https://github.com/istio/istio/issues/46267)

- **Fixed** `health_checkers` EnvoyFilter extensions not being compiled into the proxy.
  ([Issue #46277](https://github.com/istio/istio/issues/46277))
- **修复** `health_checkers` EnvoyFilter 扩展未编译到代理中。
  [Issue #46277](https://github.com/istio/istio/issues/46277)

- **Fixed** crash when `LoadBalancer.Ingress.IP` was not present or was unset to not include empty IP strings in VIPs.
- **修复**当“LoadBalancer.Ingress.IP”不存在或未设置为在 VIP 中不包含空 IP 字符串时崩溃。

- **Fixed** regression in `HTTPGet` `healthcheck` probe translation.
  ([Issue #45632](https://github.com/istio/istio/issues/45632))
- **修复** `HTTPGet` `healthcheck` 探针翻译中的回归。
  [Issue #45632](https://github.com/istio/istio/issues/45632)

- **Removed** the `CNI_ENABLE_INSTALL`, `CNI_ENABLE_REINSTALL`, `SKIP_CNI_BINARIES`, and `UPDATE_CNI_BINARIES` feature flags.
- **删除了** `CNI_ENABLE_INSTALL`、`CNI_ENABLE_REINSTALL`、`SKIP_CNI_BINARIES` 和 `UPDATE_CNI_BINARIES` 功能标志。

- **Removed** the support for deprecated EnvoyFilter names in Envoy API name matches. EnvoyFilter will only be matched with canonical naming standard. See the [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.14.0#deprecated) for more details.
- **删除**对 Envoy API 名称匹配中已弃用的 EnvoyFilter 名称的支持。 EnvoyFilter 将仅与规范命名标准匹配。 有关更多详细信息，请参阅 [Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.14.0#deprecated)。

- **Removed** the `ISTIO_DEFAULT_REQUEST_TIMEOUT` feature flag. Please use timeout in VirtualService API.
- **删除** `ISTIO_DEFAULT_REQUEST_TIMEOUT` 功能标志。 请在 VirtualService API 中使用超时。

- **Removed** the `ENABLE_AUTO_MTLS_CHECK_POLICIES` feature flag.
- **删除** `ENABLE_AUTO_MTLS_CHECK_POLICIES` 功能标志。

- **Removed** the `PILOT_ENABLE_LEGACY_AUTO_PASSTHROUGH` feature flag.
- **删除** `PILOT_ENABLE_LEGACY_AUTO_PASSTHROUGH` 功能标志。

- **Removed** the `PILOT_ENABLE_LEGACY_ISTIO_MUTUAL_CREDENTIAL_NAME` feature flag.
- **删除** `PILOT_ENABLE_LEGACY_ISTIO_MUTUAL_CREDENTIAL_NAME` 功能标志。

- **Removed** the `PILOT_LEGACY_INGRESS_BEHAVIOR` feature flag.
- **删除** `PILOT_LEGACY_INGRESS_BEHAVIOR` 功能标志。

- **Removed** the `PILOT_ENABLE_ISTIO_TAGS` feature flag.
- **删除** `PILOT_ENABLE_ISTIO_TAGS` 功能标志。

- **Removed** the `ENABLE_LEGACY_LB_ALGORITHM_DEFAULT` feature flag.
- **删除** `ENABLE_LEGACY_LB_ALGORITHM_DEFAULT` 功能标志。

- **Removed** the `PILOT_PARTIAL_FULL_PUSHES` feature flag.
- **删除** `PILOT_PARTIAL_FULL_PUSHES` 功能标志。

- **Removed** the `PILOT_INBOUND_PROTOCOL_DETECTION_TIMEOUT` feature flag. This can be configured in MeshConfig if needed.
- **删除** `PILOT_INBOUND_PROTOCOL_DETECTION_TIMEOUT` 功能标志。 如果需要，可以在 MeshConfig 中进行配置。

- **Removed** the `AUTO_RELOAD_PLUGIN_CERTS` feature flag.
- **删除** `AUTO_RELOAD_PLUGIN_CERTS` 功能标志。

- **Removed** the `PRIORITIZED_LEADER_ELECTION` feature flag.
- **删除** `PRIORITIZED_LEADER_ELECTION` 功能标志。

- **Removed** the `SIDECAR_IGNORE_PORT_IN_HOST_MATCH` feature flag.
- **删除** `SIDECAR_IGNORE_PORT_IN_HOST_MATCH` 功能标志。

- **Removed** the `REWRITE_TCP_PROBES` feature flag.
- **删除** `REWRITE_TCP_PROBES` 功能标志。

- **Removed** support for xDS v2 types in `EnvoyFilter`s. These should use the v3 interface. This has been a warning for multiple releases and is now upgraded to an error.
- **删除了** `EnvoyFilter` 中对 xDS v2 类型的支持。 这些应该使用 v3 接口。 这一直是多个版本的警告，现在已升级为错误。

- **Removed** the `PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_OUTBOUND` and `PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_INBOUND` feature flags. These have been enabled by default since Istio 1.5.
- **删除了** `PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_OUTBOUND` 和 `PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_INBOUND` 功能标志。 自 Istio 1.5 起，这些功能已默认启用。

- **Removed** support for looking up Envoy extensions in `EnvoyFilter` configuration by name without the typed config URL.
- **删除**支持在“EnvoyFilter”配置中按名称查找 Envoy 扩展，无需输入配置 URL。

- **Optimized** EnvoyFilter index generation to avoid rebuilding all `EnvoyFilters` every time one has changed, instead only rebuilding the changed `EnvoyFilter` and updating it in place.
- **优化** EnvoyFilter 索引生成，以避免每次发生更改时重建所有“EnvoyFilter”，而是仅重建已更改的“EnvoyFilter”并就地更新。

## 安全性 {#security}

- **Added** `insecureSkipVerify` implementation from DestinationRule. Setting `insecureSkipVerify` to `true` will disable CA certificate and Subject Alternative Names verification for the host.
  ([Issue #33472](https://github.com/istio/istio/issues/33472))
- **添加了** DestinationRule 的“insecureSkipVerify”实现。 将“insecureSkipVerify”设置为“true”将禁用主机的 CA 证书和主题备用名称验证。
  ([Issue #33472](https://github.com/istio/istio/issues/33472))

- **Added** support for PeerAuthentication policies in ambient.
  ([Issue #42696](https://github.com/istio/istio/issues/42696))
- **添加了**对环境中 PeerAuthentication 策略的支持。
  ([Issue #42696](https://github.com/istio/istio/issues/42696))

- **Added** `cipher_suites` support for non `ISTIO_MUTUAL` traffic through MeshConfig API.
  ([Issue #28996](https://github.com/istio/istio/issues/28996))
- **添加** 通过 MeshConfig API 对非“ISTIO_MUTUAL”流量的“cipher_suites”支持。
  ([Issue #28996](https://github.com/istio/istio/issues/28996))

- **Added** Certificate Revocation List (CRL) support for peer certificate validation.
- **添加** 对对等证书验证的证书吊销列表 (CRL) 支持。

- **Added** support for a flag called `USE_EXTERNAL_WORKLOAD_SDS`. When set to true, it will require an external SDS workload socket and it will prevent the istio-proxy from starting if the workload SDS socket is not found.
  ([Issue #45534](https://github.com/istio/istio/issues/45534))
- **添加**对名为“USE_EXTERNAL_WORKLOAD_SDS”的标志的支持。 当设置为 true 时，它将需要外部 SDS 工作负载套接字，并且如果未找到工作负载 SDS 套接字，它将阻止 istio-proxy 启动。
  ([Issue #45534](https://github.com/istio/istio/issues/45534))

- **Fixed** an issue where `jwk` issuer was not resolved correctly when having a trailing slash in the issuer URL.
  ([Issue #45546](https://github.com/istio/istio/issues/45546))
- **修复**当颁发者 URL 中包含尾部斜杠时，无法正确解析“jwk”颁发者的问题。
  ([Issue #45546](https://github.com/istio/istio/issues/45546))

- **Removed** the `SPIFFE_BUNDLE_ENDPOINTS` feature flag.
- **删除** `SPIFFE_BUNDLE_ENDPOINTS` 功能标志。

## 遥测 {#telemetry}

- **Added** new metric named `provider_lookup_cluster_failures` for lookup cluster failures.
- **添加**名为“provider_lookup_cluster_failures”的新指标，用于查找集群故障。

- **Added** support for K8s controller queue metrics, enabled by setting env variable `ISTIO_ENABLE_CONTROLLER_QUEUE_METRICS` to `true`. 
  ([Issue #44985](https://github.com/istio/istio/issues/44985))
- **添加了**对 K8s 控制器队列指标的支持，通过将环境变量“ISTIO_ENABLE_CONTROLLER_QUEUE_METRICS”设置为“true”来启用。
  ([Issue #44985](https://github.com/istio/istio/issues/44985))

- **Added** a flag to disable `OTel` builtin resource labels.
- **添加**一个标志来禁用“OTel”内置资源标签。

- **Added** `cluster` label for `remote_cluster_sync_timeouts_total` metric. 
  ([Issue #44489](https://github.com/istio/istio/issues/44489))
- **为“remote_cluster_sync_timeouts_total”指标添加了**“cluster”标签。
  ([Issue #44489](https://github.com/istio/istio/issues/44489))

- **Added** support for annotation `sidecar.istio.io/statsHistogramBuckets` to customize the histogram buckets in the proxy.
- **添加了**对注释“sidecar.istio.io/statsHistogramBuckets”的支持，以自定义代理中的直方图存储桶。

- **Added** HTTP metadata exchange filter to support a fallback to xDS workload metadata discovery in addition to the metadata HTTP headers. The discovery method is off by default.
- **添加了** HTTP 元数据交换过滤器，除了元数据 HTTP 标头之外，还支持回退到 xDS 工作负载元数据发现。 默认情况下，发现方法处于关闭状态。

- **Added** an option to configure Envoy to report load stats to the Load Reporting Service (LRS) server.
- **添加**一个选项来配置 Envoy 以向负载报告服务 (LRS) 服务器报告负载统计信息。

- **Fixed** an issue where disabling a log provider through Istio telemetry API would not work.
- **修复**通过 Istio 遥测 API 禁用日志提供程序不起作用的问题。

- **Fixed** an issue where `Telemetry` would not be fully disabled unless `match.metric=ALL_METRICS` was explicitly specified; matching all metrics is now correctly considered as the default.
- **修复**除非明确指定“match.metric=ALL_METRICS”，否则“遥测”不会完全禁用的问题； 匹配所有指标现在被正确地视为默认值。

## 可扩展性 {#extensibility}

- **Added** an option to fail open on fetch failure and VM fatal errors.
- **添加**一个在获取失败和 VM 致命错误时无法打开的选项。

## 安装 {#installation}

- **Improved** usage on OpenShift clusters by removing the need to manually create a `NetworkAttachmentDefinition` resource in every application namespace.
- 通过消除在每个应用程序命名空间中手动创建“NetworkAttachmentDefinition”资源的需要，**改进**在 OpenShift 集群上的使用。

- **Updated** Kiali addon to version `v1.72.0`.
- **更新** Kiali 插件至版本“v1.72.0”。

- **Added** support for `PodDisruptionBudget` (PDB) in the Gateway chart.
  ([Issue #44469](https://github.com/istio/istio/issues/44469))
- **在网关图表中添加了**对“PodDisruptionBudget”(PDB) 的支持。
  ([Issue #44469](https://github.com/istio/istio/issues/44469))

- **Added** the Helm value of setting CNI ambient `configDir` path.
  ([Issue #45400](https://github.com/istio/istio/issues/45400))
- **添加**设置 CNI 环境 `configDir` 路径的 Helm 值。
  ([Issue #45400](https://github.com/istio/istio/issues/45400))

- **Added** `amd64` named artifacts for macOS and Windows. The `amd64` flavor of the artifacts did not contain the architecture in the name as we do for the other operating systems. This makes the artifact naming consistent.
- **添加** macOS 和 Windows 的“amd64”命名工件。 工件的“amd64”风格并不像我们为其他操作系统所做的那样在名称中包含体系结构。 这使得工件命名保持一致。

- **Added** `rollingUpdate` `maxUnavailable` setting to the CNI deployment Helm chart to speed up deployments.
- **在 CNI 部署 Helm 图表中添加** `rollingUpdate` `maxUnavailable` 设置以加快部署速度。

- **Added** an automatically set `GOMEMLIMIT` and `GOMAXPROCS` to all deployments to improve performance.
- **添加**自动设置“GOMEMLIMIT”和“GOMAXPROCS”到所有部署以提高性能。

- **Added** configurable scaling behavior for Istiod's HPA in Helm chart
 ([usage](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior)). ([Issue #42634](https://github.com/istio/istio/issues/42634))
- **添加了** Helm 图表中 Istiod 的 HPA 的可配置缩放行为
  ([usage](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior)).
  ([Issue #42634](https://github.com/istio/istio/issues/42634))

- **Added** values to the Istio Pilot Helm charts for configuring additional container arguments: `volumeMounts` and `volumes`. Can be used in conjunction with cert-manager `istio-csr`.
  ([Issue #113](https://github.com/cert-manager/istio-csr/issues/113))
- **向 Istio Pilot Helm 图表添加了**值，用于配置其他容器参数：“volumeMounts”和“volumes”。 可以与证书管理器“istio-csr”结合使用。
  ([Issue #113](https://github.com/cert-manager/istio-csr/issues/113))

- **Added** values to the Istiod Helm chart for configuring [topologySpreadConstraints](https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/) on the Deployment. Can be used for better placement of Istiod workloads.
  ([Issue #42938](https://github.com/istio/istio/issues/42938))
- **向 Istiod Helm 图表添加**值，用于在部署上配置 [topologySpreadConstraints](https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/)。 可用于更好地放置 Istiod 工作负载。
  ([Issue #42938](https://github.com/istio/istio/issues/42938))

- **Added** Allow setting `terminationGracePeriodSeconds` for ztunnel pod via Helm chart.
- **添加** 允许通过 Helm 图表为 ztunnel pod 设置 `terminationGracePeriodSeconds`。

- **Fixed** an issue where removing field(s) from IstioOperator and re-installing did not reflect changes in existing IstioOperator spec. 
  ([Issue #42068](https://github.com/istio/istio/issues/42068))
- **修复**从 IstioOperator 中删除字段并重新安装未反映现有 IstioOperator 规范中的更改的问题。
  ([Issue #42068](https://github.com/istio/istio/issues/42068))

- **Fixed** `ValidatingWebhookConfiguration` not being generated correctly with operator installation when the revision is not set.
  ([Issue #43893](https://github.com/istio/istio/issues/43893))
- **修复** 当未设置修订版时，操作员安装时无法正确生成“ValidatingWebhookConfiguration”。
  ([Issue #43893](https://github.com/istio/istio/issues/43893))

- **Fixed** an issue where the operator did not reject invalid CIDR entries that included spaces.
  ([Issue #45338](https://github.com/istio/istio/issues/45338))
- **修复**操作员未拒绝包含空格的无效 CIDR 条目的问题。
  ([Issue #45338](https://github.com/istio/istio/issues/45338))

- **Fixed** an issue where the hostname package is not listed as a dependency for the VM packages.
  ([Issue #45866](https://github.com/istio/istio/issues/45866))
- **修复**主机名包未列为 VM 包的依赖项的问题。
  ([Issue #45866](https://github.com/istio/istio/issues/45866))

- **Fixed** an issue preventing the Gateway chart from being used with a custom `HorizontalPodAutoscaler` resource.
- **修复**阻止网关图表与自定义“HorizontalPodAutoscaler”资源一起使用的问题。

- **Fixed** an issue that Istio should using `IMDSv2` as possible on AWS.
  ([Issue #45825](https://github.com/istio/istio/issues/45825))
- **修复** Istio 应在 AWS 上尽可能使用“IMDSv2”的问题。
  ([Issue #45825](https://github.com/istio/istio/issues/45825))

- **Fixed** OpenShift profile setting `sidecarInjectorWebhook` causing `k8s.v1.cni.cncf.io/networks` to be overwritten when using multiple networks.
  ([Issue #43632](https://github.com/istio/istio/issues/43632)),([Issue #45034](https://github.com/istio/istio/issues/45034))
- **修复** OpenShift 配置文件设置 `sidecarInjectorWebhook` 导致使用多个网络时`k8s.v1.cni.cncf.io/networks` 被覆盖。
  ([Issue #43632](https://github.com/istio/istio/issues/43632)),([Issue #45034](https://github.com/istio/istio/issues/45034))

- **Fixed** a null traversal issue when using `datadog` or `stackdriver` with no tracing options.
  ([Issue #45855](https://github.com/istio/istio/issues/45855))
- **修复**使用没有跟踪选项的“datadog”或“stackdriver”时的空遍历问题。
  ([Issue #45855](https://github.com/istio/istio/issues/45855))

- **Fixed** an issue preventing the ports of waypoint and ztunnel ports from being exposed. Scraped configuration files can be created for ambient components, too.
  ([Issue #45093](https://github.com/istio/istio/issues/45093))
- **修复**阻止航路点和 ztunnel 端口暴露的问题。 也可以为环境组件创建抓取的配置文件。
  ([Issue #45093](https://github.com/istio/istio/issues/45093))

- **Removed** the following experimental `istioctl` commands: `add-to-mesh`, `remove-from-mesh` and `kube-uninject`. Usage of automatic sidecar injection is recommended instead.
- **删除**以下实验性 `istioctl` 命令：`add-to-mesh`、`remove-from-mesh` 和 `kube-uninject`。 建议使用自动 sidecar 注入。

- **Removed** the `ENABLE_LEGACY_FSGROUP_INJECTION` feature flag. This was intended to support Kubernetes 1.18 and older, which are out of support.
- **删除** `ENABLE_LEGACY_FSGROUP_INJECTION` 功能标志。 其目的是支持 Kubernetes 1.18 及更早版本，但这些版本已不再受支持。

- **Removed** obsolete manifests from the `base` Helm chart. See Upgrade Notes for more information.
- **从“基本”Helm 图表中删除了**过时的清单。 有关详细信息，请参阅升级说明。

## istioctl

- **Improved** IST0123 warning message description.
- **改进** IST0123 警告消息描述。

- **Updated** `istioctl experimental workload configure` command to accept IPv6 address passed with `--ingressIP`.
- **更新** `istioctl 实验工作负载配置` 命令以接受通过 `--ingressIP` 传递的 IPv6 地址。

- **Added** config type and endpoint configuration summaries to `istioctl proxy-config all`.
  ([Issue #43807](https://github.com/istio/istio/issues/43807))
- **添加了**配置类型和端点配置摘要到“istioctl proxy-config all”。
  ([Issue #43807](https://github.com/istio/istio/issues/43807))

- **Added** directory support for `istioctl validate`. Now, the `-f` flag accepts both file paths and directory paths.
- **添加了**对 `istioctl validate` 的目录支持。 现在，“-f”标志接受文件路径和目录路径。

- **Added** support for YAML output to `istioctl admin log`.
- **添加了**对 YAML 输出到“istioctl 管理日志”的支持。

- **Added** support for checking telemetry labels, which now includes Istio canonical labels and Kubernetes recommended labels.
- **添加了**对检查遥测标签的支持，现在包括 Istio 规范标签和 Kubernetes 推荐标签。

- **Added** support for namespace filtering for proxy statuses. Note: please ensure that both istioctl and istiod are upgraded for this feature to work.
- **添加**对代理状态的名称空间过滤的支持。 注意：请确保 istioctl 和 istiod 均已升级才能使此功能正常工作。

- **Added** support for validating JSON files to `istioctl validate`.
  ([Issue #46136](https://github.com/istio/istio/issues/46136)),([Issue #46136](https://github.com/istio/istio/issues/46136))
- **添加了**对验证 JSON 文件到“istioctl validate”的支持。
  ([Issue #46136](https://github.com/istio/istio/issues/46136)),([Issue #46136](https://github.com/istio/istio/issues/46136))

- **Added** warning if user specifies more than one Istio label in the same namespace. Including `istio-injection`, `istio.io/rev`, `istio.io/dataplane-mode`.
- 如果用户在同一命名空间中指定多个 Istio 标签，**添加**警告。 包括 `istio-injection`、`istio.io/rev`、`istio.io/dataplane-mode`。

- **Added** support for displaying multiple addresses of listeners in `istioctl proxy-config listeners`.
- **添加**支持在“istioctl proxy-configlisteners”中显示多个侦听器地址。

- **Fixed** `verify-install` failing to detect `DaemonSet` component statuses.
- **修复** `verify-install` 无法检测到 `DaemonSet` 组件状态。

- **Fixed** an issue where the cert validity was not accurate in the `istioctl proxy-config secret` command.
- **修复** `istioctl proxy-config Secret` 命令中的证书有效性不准确的问题。

- **Fixed** an issue where xDS `proxy-status` was showing inaccurate Istio version. Note: please ensure that both istioctl and istiod are upgraded for this fix to work.
- **修复** xDS `proxy-status` 显示不准确的 Istio 版本的问题。 注意：请确保 istioctl 和 istiod 均已升级，此修复程序才能发挥作用。

- **Fixed** an issue where ztunnel pods could be compared to Envoy configuration files in `istioctl proxy-status` and `istioctl experimental proxy-status`. They are now excluded from the comparison.
- **修复** ztunnel pod 可以与 `istioctl proxy-status` 和 `istioctl Experimental proxy-status` 中的 Envoy 配置文件进行比较的问题。 他们现在被排除在比较之外。

- **Fixed** an issue where there was a parse error when performing `rootCA` comparison for ztunnel pods.
- **修复**对 ztunnel pod 执行“rootCA”比较时出现解析错误的问题。

- **Fixed** an issue where analyzers were reporting messages for the gateway-managed services.
- **修复**分析器报告网关管理服务消息的问题。

- **Fixed** an issue where specifying multiple include conditions by `--include` in `istioctl bug-report` didn't work as expected.
  ([Issue #45839](https://github.com/istio/istio/issues/45839))
- **修复了**在“istioctl bug-report”中通过“--include”指定多个包含条件无法按预期工作的问题。
  ([Issue #45839](https://github.com/istio/istio/issues/45839))

- **Fixed** an issue where Kubernetes resources with revision labels were being filtered out by `istioctl analyze` when the `--revision` flag was not used.
  ([Issue #46239](https://github.com/istio/istio/issues/46239))
- **修复**当未使用 `--revision` 标志时，带有修订标签的 Kubernetes 资源会被 `istioctlanalyze` 过滤掉的问题。
  ([Issue #46239](https://github.com/istio/istio/issues/46239))

- **Fixed** an issue where the creation of a Telemetry object without any providers throws the IST0157 error.
  ([Issue #46510](https://github.com/istio/istio/issues/46510))
- **修复**在没有任何提供程序的情况下创建遥测对象会引发 IST0157 错误的问题。
  ([Issue #46510](https://github.com/istio/istio/issues/46510))

- **Fixed** an issue where the analyzer produced incorrect results for `GatewayPortNotOnWorkload` when there was an incorrect association of `Gateway.Spec.Servers[].Port.Number` with a Service's `Port` instead of its `TargetPort`.
- **修复**当“Gateway.Spec.Servers[].Port.Number”与服务的“Port”而不是“TargetPort”的关联不正确时，分析器为“GatewayPortNotOnWorkload”生成不正确的结果 。

- **Fixed** `revision` flag missing in `istioctl experimental precheck`.
- **修复** `istioctl 实验性预检查`中缺少`revision`标志。

- **Removed** `uninstall` command from `istioctl experimental`. Use `istioctl uninstall` instead.
- **从“istioctl Experimental”中删除了**“uninstall”命令。 请改用“istioctl uninstall”。

- **Removed** the following experimental `istioctl` commands: `create-remote-secret` and `remote-clusters`. They have been moved to the top level `istioctl` command.
- **删除**以下实验性 `istioctl` 命令：`create-remote-secret` 和 `remote-clusters`。 它们已移至顶级“istioctl”命令。

## 文档变更 {#documentation-changes}

- **Improved** Bookinfo samples so they can now be used in OpenShift without the `anyuid` SCC privilege.
- **改进** Bookinfo 示例，现在可以在 OpenShift 中使用它们，而无需“anyuid” SCC 权限。
