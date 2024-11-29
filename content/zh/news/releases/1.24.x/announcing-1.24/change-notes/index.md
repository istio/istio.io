---
title: Istio 1.24.0 更新说明
linktitle: 1.24.0
subtitle: 主要版本
description: Istio 1.24.0 更新说明。
publishdate: 2024-11-07
release: 1.24.0
weight: 10
aliases:
    - /zh/news/announcing-1.24.0
---

## Ambient 模式 {#ambient-mode}

- **新增** 添加了对将策略附加到 waypoint 的 `ServiceEntry` 的支持。

- **新增** 添加了新的注解 `ambient.istio.io/bypass-inbound-capture`，
  可应用于使 ztunnel 仅捕获出站流量。
  这对于仅接受来自网格外客户端（例如面向互联网的 Pod）的流量的工作负载跳过不必要的跳跃非常有用。

- **新增** 添加了新的注解 `networking.istio.io/traffic-distribution`，
  可应用于使 ztunnel 优先将流量发送到本地 Pod。
  其行为与 `Service` 上的 [`spec.trafficDistribution`](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#traffic-distribution)
  字段相同，但允许在较旧的 Kubernetes 版本上使用（因为该字段是在 Kubernetes 1.31 中作为测试版添加的）。
  请注意，航点会自动设置此项。

- **修复** 修复了阻止[服务器优先协议](/zh/docs/ops/deployment/application-requirements/#server-first-protocols)与 waypoint 协同工作的问题。

- **改进** 当 Ambient 模式下发生连接失败时，改进来自 Envoy 的日志以显示更多错误详细信息。

- **新增** 添加了对 waypoint 代理中的 `Telemetry` 定制的支持。

- **新增** 添加了编写状态条件，用于将 AuthorizationPolicy 绑定到 waypoint 代理。
  条件的格式是**实验性的**，将会发生变化。具有多个 `targetRefs` 的策略目前接收单个条件。
  一旦上游 Kubernetes Gateway API 采用具有多个引用的条件模式，
  Istio 将采用该惯例，在使用多个 `targetRefs` 时提供更详细的信息。
  ([Issue #52699](https://github.com/istio/istio/issues/52699))

- **修复** 修复了导致 `hostNetwork` Pod 在 Ambient 模式下无法正常运行的问题。

- **改进** 改进了 ztunnel 如何确定其代表哪个 Pod 的逻辑。
  之前，这依赖于 IP 地址，但在某些情况下并不可靠。

- **修复** 修复了导致 waypoint 中的 `DestinationRule` 中的任何 `portLevelSettings` 被忽略的问题。
  ([Issue #52532](https://github.com/istio/istio/issues/52532))

- **修复** 修复了使用带有 waypoint 的镜像策略时出现的问题。
  ([Issue #52713](https://github.com/istio/istio/issues/52713))

- **新增** 添加了对应用于 waypoint 的 `AuthorizationPolicy` 中的 `connection.sni` 规则的支持。
  ([Issue #52752](https://github.com/istio/istio/issues/52752))

- **更新** 更新了 Ambient 中使用的重定向方法，从 `TPROXY` 改为 `REDIRECT`。
  对于大多数用户来说，这应该没有影响，但修复了一些与 `TPROXY` 的兼容性问题。
  ([Issue #52260](https://github.com/istio/istio/issues/52260)),([Issue #52576](https://github.com/istio/istio/issues/52576))

## 流量治理 {#traffic-management}

- **提升** 提升 Istio 双栈支持至 Alpha 版本。
  ([Issue #47998](https://github.com/istio/istio/issues/47998))

- **新增** 添加了向 `DestinationRule` 添加 `warmup.aggression`、
  `warmup.duration`、`warmup.minimumPercent` 参数，
  以对预热行为提供更多控制。
  ([Issue #3215](https://github.com/istio/api/issues/3215))

- **新增** 添加了入站请求重试策略，可自动重置服务未看到/处理的请求。
  可以通过将 `ENABLE_INBOUND_RETRY_POLICY` 设置为 false 来恢复。
  ([Issue #51704](https://github.com/istio/istio/issues/51704))

- **修复** 修复了默认重试策略，以排除 503 重试，这对于幂等请求来说可能不安全。
  可以使用 `EXCLUDE_UNSAFE_503_FROM_DEFAULT_RETRY=false` 暂时恢复此行为。
  ([Issue #50506](https://github.com/istio/istio/issues/50506))

- **更新** 更新了 XDS 生成行为，以便在用户配置了 `Sidecar`
  和未配置 `Sidecar` 时保持一致。有关更多信息，请参阅升级说明。

- **改进** 改进了 Istiod 的验证 webhook，以接受它不知道的版本。
  这确保较旧的 Istio 可以验证较新的 CRD 创建的资源。

- **改进** 通过将多个 IP 与一个端点关联起来，而不是将它们视为两个不同的端点，改进对双栈服务的支持。
  ([Issue #40394](https://github.com/istio/istio/issues/40394))

- **新增** 添加了对 HTTP 路由中匹配多个 IP（用于双栈服务）的支持。

- **新增** 添加了在过滤不需要的配置时将考虑 `VirtualService` `sourceNamespaces`。

- **新增** 添加了通过传递静态侦听器的过载管理器来支持。
  可以通过在代理 Deployment 中将 `BYPASS_OVERLOAD_MANAGER_FOR_STATIC_LISTENERS` 设置为 false 来恢复。
  ([Issue #41859](https://github.com/istio/istio/issues/41859)),([Issue #52663](https://github.com/istio/istio/issues/52663))

- **新增** 添加了新的 istiod 环境变量 `ENVOY_DNS_JITTER_DURATION`，
  默认值为 `100ms`，用于设置定期 DNS 解析的抖动。
  请参阅 `https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto`。
  这有助于减少集群 DNS 服务器上的负载。
  ([Issue #52877](https://github.com/istio/istio/issues/52877))

- **新增** 添加了通过新的 `ProxyConfig` 字段 `proxyHeaders.setCurrentClientCertDetails`
  填充 XFCC 标头时配置证书详细信息的支持。

- **新增** 添加了允许用户在 `networking.istio.io/exportTo` 注释中的命名空间之间放置额外的空格。
  ([Issue #53429](https://github.com/istio/istio/issues/53429))

- **新增** 添加了一项实验性功能，用于启用延迟创建 Envoy 统计信息子集。
  如果这些统计信息在整个过程的生命周期中从未被引用，
  这将在创建拥有这些统计信息的对象时节省内存和 CPU 周期。
  可以通过在代理 Deployment 中将 `ENABLE_DEFERRED_STATS_CREATION` 设置为 false 来禁用此功能。

- **修复** 修复了 ServiceEntry 中多个服务 VIP 的匹配问题。有关更多信息，请参阅升级说明。
  ([Issue #51747](https://github.com/istio/istio/issues/51747)),([Issue #30282](https://github.com/istio/istio/issues/30282))

- **修复** 修复了 `MeshConfig` 的 `serviceSettings.settings.clusterLocal`，
  以支持更精确的主机名，允许主机排除。

- **修复** 修复了同一主机上的 `DestinationRules`
  如果具有不同的 `exportTo` 值则不会合并。
  可以使用 `ENABLE_ENHANCED_DESTINATIONRULE_MERGE=false` 暂时恢复保持行为。
  ([Issue #52519](https://github.com/istio/istio/issues/52519))

- **修复** 修复了控制器分配的 IP 不像临时自动分配的 IP 那样尊重每个代理 DNS 捕获的问题。
  ([Issue #52609](https://github.com/istio/istio/issues/52609))

- **修复** 修复了在某些情况下导致 waypoint 忽略 `ServiceEntry` 的自动分配 IP 的问题。
  ([Issue #52746](https://github.com/istio/istio/issues/52746))

- **修复** 修复了使用 `pilot-agent istio-clean-iptables`
  命令无法删除 `ISTIO_OUTPUT` `iptables` 链的问题。
  ([Issue #52835](https://github.com/istio/istio/issues/52835))

- **修复** 修复了在高数据包丢失网络等缓慢请求场景中使用 HTTPS 可能导致 Envoy 内存泄漏的问题。
  ([Issue #52850](https://github.com/istio/istio/issues/52850))

- **修复** 修复了 DNS 代理包含无头服务未准备好的端点的错误。

- **移除** 删除了弃用的 `istio.io/gateway-name` 标签，
  请改用 `gateway.networking.k8s.io/gateway-name` 标签。

- **移除** 删除了将 `kubeconfig` 写入 CNI 网络目录。
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

- **移除** 从 `istio-cni` 配置映射中删除了 `CNI_NET_DIR`，因为它现在不执行任何操作。
  ([Issue #52315](https://github.com/istio/istio/issues/52315))

## 遥测 {#telemetry}

- **更新** 更新了遥测 API 和扩展中使用的 CEL 词汇表。有关更多信息，请参阅升级说明。

- **新增** 为统计前缀添加新的模式变量 (`%SERVICE_NAME%`)
  ([Issue #52177](https://github.com/istio/istio/issues/52177))

- **新增** 向 ztunnel Helm Chart 添加了 `logAsJson` 值
  ([Issue #52631](https://github.com/istio/istio/issues/52631))

- **新增** 添加了守护指标的统计标签配置。
  ([Issue #52731](https://github.com/istio/istio/issues/52731))

- **新增** 将跟踪导出到 OpenTelemetry Collector 时，添加了支持 gRPC 请求的标头和超时配置。
  ([Issue #52873](https://github.com/istio/istio/issues/52873))

- **新增** 添加了在 `meshConfig.extensionProviders.zipkin.path` 下支持自定义 Zipkin 收集器端点。
  ([Issue #53086](https://github.com/istio/istio/issues/53086))

- **修复** 修复了将指标端口添加到由
  [`Gateway` 自动部署](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)创建的 Pod。

- **修复** 修复了当加载新证书时，
  `citadel_server_root_cert_expiry_timestamp`、`citadel_server_root_cert_expiry_seconds`、
  `citadel_server_cert_chain_expiry_timestamp` 和 `citadel_server_cert_chain_expiry_seconds` 会更新的问题。

- **新增** 添加了 `SECRET_GRACE_PERIOD_RATIO_JITTER`，
  默认值为 `0.01`，以在 `SECRET_GRACE_PERIOD_RATIO` 中引入随机偏移量。
  如果没有此配置，同时部署的代理将同时请求更新证书，这可能会导致 CA 服务器负载过大。
  每 12 小时更新一次证书的新默认行为通过此值增加到 +/- 大约 15 分钟。
  ([Issue #52102](https://github.com/istio/istio/issues/52102))

## 安装 {#installation}

- **更新** 更新了 istio-cni 的 `securityContext.privileged` 为 false，
  以支持特定于功能的权限。istio-cni 仍然是[根据 Kubernetes Pod 安全标准的“特权”容器](https://kubernetes.io/zh-cn/docs/concepts/security/pod-security-standards/#privileged)，
  因为即使没有此标志，它也具有特权功能，即 `CAP_SYS_ADMIN`。
  ([Issue #52558](https://github.com/istio/istio/issues/52558))

- **改进** 改进了现在可以使用 `global.waypoint.resources` 配置 waypoint `resources`。
  ([Issue #51496](https://github.com/istio/istio/issues/51496))

- **改进** 改进了 waypoint Pod `affinity` 现在可以使用 `waypoint.affinity` 进行配置。
  ([Issue #52883](https://github.com/istio/istio/issues/52883))

- **改进** 改进了 waypoint Pod `topologySpreadConstraints`
  现在可以使用 `global.waypoint.topologySpreadConstraints` 进行配置。
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **改进** 改进了 waypoint Pod `tolerations` 现在可以使用 `global.waypoint.tolerations` 进行配置。
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **改进** 改进了 waypoint Pod `nodeSelector` 现在可以使用 `global.waypoint.nodeSelector` 进行配置。
  ([Issue #52901](https://github.com/istio/istio/issues/52901))

- **改进** 改进了 `istio-cni-node` DaemonSet 的内存占用。
  在许多情况下，这可以减少高达 80% 的内存。
  ([Issue #53493](https://github.com/istio/istio/issues/53493))

- **更新** 更新了 Kiali 插件示例至 [v2.0 版](https://medium.com/kialiproject/kiali-2-0-for-istio-2087810f337e)。

- **更新** 更新了所有 Istio 组件以读取 `v1` CRD（如适用）。
  这应该不会产生影响，除非集群使用的是 1.21 或更早版本的 Istio CRD（这不是受支持的版本偏差）。

- **新增** 向几乎所有资源添加了 `app.kubernetes.io/name`、
  `app.kubernetes.io/instance`、`app.kubernetes.io/part-of`、
  `app.kubernetes.io/version`、`app.kubernetes.io/managed-by` 和 `helm.sh/chart` 标签。
  ([Issue #52034](https://github.com/istio/istio/issues/52034))

- **新增** 添加了 Helm 安装的平台特定配置。
  示例：`helm install istio-cni --set profile=ambient --set global.platform=k3s`
  `helm install istiod --set profile=ambient --set global.platform=k3s`
  有关当前支持的平台覆盖列表，请参阅 `manifests/charts/platform-xxx.yaml` 文件。

- **移除** 删除了 `openshift` 配置文件变体，并用 `global.platform` 覆盖替换。
  示例：`helm install istio-cni --set profile=ambient-openshift`
  现在是 `helm install istio-cni --set profile=ambient --set global.platform=openshift`

- **新增** 为 Istiod 添加配置 `initContainers` 的功能。
  ([Issue #53120](https://github.com/istio/istio/issues/53120))

- **新增** 添加了设置（`strategy`、`minReadySeconds` 和 `terminationGracePeriodSeconds`）以稳定高流量网关。
  ([Issue #53121](https://github.com/istio/istio/issues/53121))

- **新增** 向 `istio-cni` Chart 添加了值 `seLinuxOptions`。
  在某些平台（例如 OpenShift）上，需要将 `seLinuxOptions.type` 设置为 `spc_t`，
  以解决与 `hostPath` 卷相关的一些 SELinux 约束。
  如果没有此设置，`istio-cni-node` Pod 可能无法启动。
  ([Issue #53558](https://github.com/istio/istio/issues/53558))

- **新增** 向 `istio-cni` Chart 添加了提供任意环境变量的支持。

- **新增** 添加了新的注解 `sidecar.istio.io/nativeSidecar`，
  允许用户在每个 Pod 上控制本机 Sidecar 注入。此注释可以设置为 `true` 或 `false`，
  以启用或禁用 Pod 的本机 Sidecar 注入。此注解优先级高于全局 `ENABLE_NATIVE_SIDECARS` 环境变量。
  ([Issue #53452](https://github.com/istio/istio/issues/53452))

- **新增** 添加了允许用户通过 Helm Chart 为修订标签的 `MutatingWebhookConfiguration` 添加自定义注解。

- **修复** 修复了 `kube-virt-interfaces` 规则未被 `istio-clean-iptables` 工具删除的问题。
  ([Issue #48368](https://github.com/istio/istio/issues/48368))

- **修复** 修复了如果现有规则兼容，则允许通过跳过应用步骤重新执行 istio-iptables。

- **修复** 修复了某些安装状态行未正确完成的问题，这会在调整终端窗口大小时导致奇怪的渲染。
  ([Issue #52525](https://github.com/istio/istio/issues/52525))

- **修复** 在 ztunnel 中将 `allowPrivilegeEscalation` 设置为 `true` - 实际上它一直被强制为 `true`，
  但 K8S 没有正确验证这一点：<https://github.com/kubernetes/kubernetes/issues/119568>。

- **修复** 修复了从 `base` Chart 中删除非关键组件，
  并从 `istiod-remote` 和 `istio-discovery` Chart 中删除 `pilot.enabled`。

- **修复** 默认情况下，修复了 `base` Chart 中的模板化 CRD 安装。
  以前，这仅在某些条件下有效，并且当使用某些安装标志时，
  可能会导致只能通过手动 `kubectl` 干预升级 CRD。有关更多信息，请参阅升级说明。

- **弃用** 弃用了 `Values.base.enableCRDTemplates`。
  此选项现在默认为 `true`，并将在未来版本中删除。
  在此之前，可以通过将其设置为 `false` 来启用旧行为。
  ([Issue #43204](https://github.com/istio/istio/issues/43204))

- **移除** 删除了 Helm Values API 中一些无效且已弃用的字段。
  删除的字段包括：`pilot.configNamespace`、`pilot.configSource`、
  `pilot.enableProtocolSniffingForOutbound`、`pilot.enableProtocolSniffingForInbound`、
  `pilot.useMCP`、`global.autoscalingV2API`、`global.configRootNamespace`、
  `global.defaultConfigVisibilitySettings`、`global.useMCP`、
  `sidecarInjectorWebhook.objectSelector` 和 `sidecarInjectorWebhook.useLegacySelectors`。
  ([Issue #51987](https://github.com/istio/istio/issues/51987))

- **移除** 删除了 2 个版本之前标记为弃用的 `istiod` Chart 中未使用的 `istio_cni` 值（#49290）。
  ([Issue #52645](https://github.com/istio/istio/issues/52645))

- **移除** 删除了 `istiod-remote` Chart，
  改为使用 `helm install istio-discovery --set profile=remote`。

- **移除** 删除了对 `1.20` `compatibilityProfile` 的支持。
  这配置了以下设置：`ENABLE_EXTERNAL_NAME_ALIAS`、
  `PERSIST_OLDEST_FIRST_HEURISTIC_FOR_VIRTUAL_SERVICE_HOST_MATCHING`、
  `VERIFY_CERTIFICATE_AT_CLIENT` 和 `ENABLE_AUTO_SNI`。
  除 `ENABLE_AUTO_SNI` 之外，所有这些标志也已从 Istio 中完全删除。

- **移除** 删除了 `sidecar.istio.io/enableCoreDump` 注解。
  请参阅 `samples/proxy-coredump` 中提供的示例，了解启用核心转储的更多首选方法。

- **移除** 删除了旧版 `--log_rotate_*` 标志选项。希望使用日志轮换的用户应使用外部日志轮换工具。

## istioctl

- **新增** 添加了在安装过程中自动检测各种特定于平台的不兼容性。

- **新增** 添加了一个新命令 `istioctl manifest translate`，以帮助从 `istioctl install` 迁移到 `helm`。

- **新增** 在 `istioctl analyze` 命令中添加了一个新标志 `remote-contexts`，
  以在多集群分析期间指定远程集群上下文。
  ([Issue #51934](https://github.com/istio/istio/issues/51934))

- **新增** 向 `istioctl x envoy-stats` 添加了通过标签选择器过滤 Pod 的支持。

- **新增** 向 `istioctl experimental injector list` 添加了按命名空间过滤资源的支持。

- **新增** 添加了对 istioctl 中的 `--impersonate` 标志的支持。
  ([Issue #52285](https://github.com/istio/istio/issues/52285))

- **修复** 修复了 istioctl 分析报告带有通配符主机和特定子域的 IST0145 错误。
  ([Issue #52413](https://github.com/istio/istio/issues/52413))

- **修复** 修复了 `istioctl experiments injection list` 打印与 istio 不相关的 webhook。

- **移除** 删除了 `istioctl manifest diff` 和 `istioctl manifest profile diff` 命令。
  想要比较清单的用户可以使用通用 YAML 比较工具。

- **移除** 删除了 `istioctl profile` 命令。可以在 Istio 文档中找到相同的信息。

## 文档变更 {#documentation-changes}

- **改进** 通过将 `sleep` 示例重命名为 `curl`，提高了 Istio 文档的可读性。
  ([Issue #15725](https://github.com/istio/istio.io/issues/15725))
