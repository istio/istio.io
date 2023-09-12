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

以下通知说明了根据 [Istio 的弃用政策](/zh/docs/releases/feature-stages/#feature-phase-definitions)将在未来某个版本中移除的功能。
请考虑升级您的环境以移除弃用的功能。

### 制品 {#artifacts}

名称中未指定架构的对于 macOS 和 Windows 的制品
（例如：`istio-1.18.0-osx.tar.gz`）将在多个版本中被删除。
它们已被名称中包含架构的制品所取代（例如：`istio-1.18.0-osx-amd64.tar.gz`）。
([Issue #45677](https://github.com/istio/istio/issues/45677))

## 流量治理 {#traffic-management}

- **改进** 改进了基于路由的 JWT 声明，支持使用 `[]` 作为嵌套声明名称的分隔符。
  ([Issue #44228](https://github.com/istio/istio/issues/44228))

- **改进** 改进了 Sidecar 注入的性能，特别是对于具有大量环境变量的 Pod。

- **更新** 更新了使用 `ServiceEntry` 时的 DNS 解析，
  以便多网络网关的 DNS 将被在代理而不是在控制平面中解析。

- **新增** 添加了对代理中 `traffic.sidecar.istio.io/excludeInterfaces` 注解的支持。
  ([Issue #41271](https://github.com/istio/istio/issues/41271))

- **新增** 添加了在初始化 Ambient 中对 `WorkloadEntry` 的支持。
  ([Issue #45472](https://github.com/istio/istio/issues/45472))

- **新增** 添加了在 Ambient 中对没有地址的 `WorkloadEntry` 资源的支持。
  ([Issue #45758](https://github.com/istio/istio/issues/45758))

- **新增** 添加了在初始化 Ambient 中对 `ServiceEntry` 的支持。

- **新增** 在 VirtualService `HTTPRewrite` 中添加了对正则表达式重写的支持。
  ([Issue #22290](https://github.com/istio/istio/issues/22290))

- **新增** 在 Gateway 的 `ServerTLSSettings` 中添加了新的 TLS 模式 `OPTIONAL_MUTUAL`，
  如果存在客户端证书，该模式将对其进行验证。

- **新增** 添加了在双栈中设置正确 DNS 系列类型的增强。
  增加了 `CheckIPFamilyTypeForFirstIPs`，以帮助根据第一个 IP 地址确认 IP 系列类型。
  并将 `ISTIO_DUAL_STACK` 环境变量更改为控制平面和数据平面的统一变量。
  ([Issue #41462](https://github.com/istio/istio/issues/41462))

- **修复** 修复了不同网络上的 `WorkloadEntry` 资源不需要指定地址的问题。
  ([Issue #45150](https://github.com/istio/istio/issues/45150))

- **修复** 修复了 Istio Gateway API 的实现需要遵循 Gateway API 要求，
  即必须为 `kind: Service` 的 `parentRef` 设置 `group: ""` 字段。
  Istio 之前容忍了 Service-kind 父引用中组的缺失。这是一个重大改变；详细信息请参见升级说明。
  ([Issue #2309](https://github.com/kubernetes-sigs/gateway-api/issues/2309))

- **修复** 修复了为非 Istio mTLS 设置 `istio.alpn` 过滤器的问题。
  ([Issue #40680](https://github.com/istio/istio/issues/40680))

- **修复** 修复了 `http_route` 会影响其他 `virtualhosts` 的错误。
  ([Issue #44820](https://github.com/istio/istio/issues/44820))

- **修复** 修复了 EnvoyFilter 的操作顺序，以便被移除并被重新添加的资源不会被误删除。
  ([Issue #45089](https://github.com/istio/istio/issues/45089))

- **修复** 修复了当用户在 `./etc/istio/pod/labels` 中指定 `istio-locality` 时，
  `VirtualMachine` `WorkloadEntry` 自动注册失败，并出现无效的 `istio-locality` 标签的问题。
  ([Issue #45413](https://github.com/istio/istio/issues/45413))

- **修复** 修复了在双栈网格中 `virtualHost.Domains` 缺少双栈服务中的第二个 IP 地址的问题。
  ([Issue #45557](https://github.com/istio/istio/issues/45557))

- **修复** 修复了当 `VirtualService` 具有不同大小写的相同主机时，路由配置因重复域名而被拒绝的错误。
  ([Issue #45719](https://github.com/istio/istio/issues/45719))

- **修复** 修复了如果禁用 xDS 缓存，删除集群时 Istiod 可能会崩溃的问题。
  ([Issue #45798](https://github.com/istio/istio/issues/45798))

- **修复** 修复了在已经为同一 VNI 和远程 IP 配置外部 `geneve` 链接或为另一个
  `geneve` 链接的节点上创建 `istioin` 和 `istioout` `geneve` 链接的问题。
  用于避免在这些情况下出现错误，istio-cni 动态确定创建的 `geneve` 链接的可用目标端口。

- **修复** 修复了当入口中使用服务端口名称引用服务时，Istiod 无法自动检测服务端口更改的问题。
  ([Issue #46035](https://github.com/istio/istio/issues/46035))

- **修复** 修复了 HTTP 探针的 `request.host` 传播不畅的问题。
  ([Issue #46087](https://github.com/istio/istio/issues/46087))

- **修复** 修复了 Ambient `WorkloadEntry` xDS 事件在更新时触发的问题。
  ([Issue #46267](https://github.com/istio/istio/issues/46267))

- **修复** 修复了 `health_checkers` EnvoyFilter 扩展未编译到代理中的问题。
  ([Issue #46277](https://github.com/istio/istio/issues/46277))

- **修复** 修复了当 `LoadBalancer.Ingress.IP` 不存在或未设置为在 VIP 中不包含空 IP 字符串时产生崩溃的问题。

- **修复** 修复了 `HTTPGet` `healthcheck` 探针翻译中的回归问题。
  ([Issue #45632](https://github.com/istio/istio/issues/45632))

- **移除** 移除了 `CNI_ENABLE_INSTALL`、`CNI_ENABLE_REINSTALL`、
  `SKIP_CNI_BINARIES` 和 `UPDATE_CNI_BINARIES` 功能标志。

- **移除** 移除了对 Envoy API 名称匹配中已弃用的 EnvoyFilter 名称的支持。
  EnvoyFilter 将仅与规范命名标准匹配。有关更多详细信息，请参阅
  [Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.14.0#deprecated)。

- **移除** 移除了 `ISTIO_DEFAULT_REQUEST_TIMEOUT` 功能标志。
  请在 VirtualService API 中使用超时设置。

- **移除** 移除了 `ENABLE_AUTO_MTLS_CHECK_POLICIES` 功能标志。

- **移除** 移除了 `PILOT_ENABLE_LEGACY_AUTO_PASSTHROUGH` 功能标志。

- **移除** 移除了 `PILOT_ENABLE_LEGACY_ISTIO_MUTUAL_CREDENTIAL_NAME` 功能标志。

- **移除** 移除了 `PILOT_LEGACY_INGRESS_BEHAVIOR` 功能标志。

- **移除** 移除了 `PILOT_ENABLE_ISTIO_TAGS` 功能标志。

- **移除** 移除了 `ENABLE_LEGACY_LB_ALGORITHM_DEFAULT` 功能标志。

- **移除** 移除了 `PILOT_PARTIAL_FULL_PUSHES` 功能标志。

- **移除** 移除了 `PILOT_INBOUND_PROTOCOL_DETECTION_TIMEOUT` 功能标志。
  如果仍然需要，可以在 MeshConfig 中进行配置。

- **移除** 移除了 `AUTO_RELOAD_PLUGIN_CERTS` 功能标志。

- **移除** 移除了 `PRIORITIZED_LEADER_ELECTION` 功能标志。

- **移除** 移除了 `SIDECAR_IGNORE_PORT_IN_HOST_MATCH` 功能标志。

- **移除** 移除了 `REWRITE_TCP_PROBES` 功能标志。

- **移除** 移除了 `EnvoyFilter` 中对 xDS v2 类型的支持。
  这些应该使用 v3 接口。这一直是很多版本中的警告，现在已升级为错误。

- **移除** 移除了 `PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_OUTBOUND`
  和 `PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_INBOUND` 功能标志。
  自 Istio 1.5 起，这些功能已默认启用。

- **移除** 移除了在 `EnvoyFilter` 配置中无需输入配置 URL 按名称查找 Envoy 扩展的支持。

- **优化** 优化了 EnvoyFilter 索引生成，以避免每次发生更改时重建所有`EnvoyFilter`，
  而是仅重建已更改的 `EnvoyFilter` 并就地更新。

## 安全性 {#security}

- **新增** 添加了 DestinationRule 的 `insecureSkipVerify` 实现。
  将 `insecureSkipVerify` 设置为 `true` 将禁用主机的 CA
  证书和 Subject Alternative Name 验证。
  ([Issue #33472](https://github.com/istio/istio/issues/33472))

- **新增** 添加了对 Ambient 中 PeerAuthentication 策略的支持。
  ([Issue #42696](https://github.com/istio/istio/issues/42696))

- **新增** 添加了通过 MeshConfig API 对非 `ISTIO_MUTUAL` 流量的 `cipher_suites` 支持。
  ([Issue #28996](https://github.com/istio/istio/issues/28996))

- **新增** 添加了对 Certificate Revocation List（CRL）的支持。

- **新增** 添加了对名为 `USE_EXTERNAL_WORKLOAD_SDS` 标志的支持。
  当设置为 true 时，它将需要外部 SDS 工作负载套接字，
  并且如果未找到工作负载 SDS 套接字，它将阻止 istio-proxy 启动。
  ([Issue #45534](https://github.com/istio/istio/issues/45534))

- **修复** 修复了当颁发者 URL 中包含尾部斜杠时，无法正确解析 `jwk` 颁发者的问题。
  ([Issue #45546](https://github.com/istio/istio/issues/45546))

- **移除** 移除了 `SPIFFE_BUNDLE_ENDPOINTS` 功能标志。

## 遥测 {#telemetry}

- **新增** 添加了名为 `provider_lookup_cluster_failures` 的新指标，用于查找集群故障。

- **新增** 添加了对 K8s 控制器队列指标的支持，通过将环境变量
  `ISTIO_ENABLE_CONTROLLER_QUEUE_METRICS` 设置为 `true` 来启用。
  ([Issue #44985](https://github.com/istio/istio/issues/44985))

- **新增** 添加了一个标志来禁用 `OTel` 内置资源标签。

- **新增** 为 `remote_cluster_sync_timeouts_total` 指标添加了 `cluster` 标签。
  ([Issue #44489](https://github.com/istio/istio/issues/44489))

- **新增** 添加了对 `sidecar.istio.io/statsHistogramBuckets` 注解的支持，
  用于自定义代理中的直方图存储桶。

- **新增** 添加了 HTTP 元数据交换过滤器，除了元数据 HTTP 头之外，
  还支持回退到 xDS 工作负载元数据发现。默认情况下，发现方法处于关闭状态。

- **新增** 添加了一个选项来配置 Envoy 用于向 Load Reporting Service
  （LRS）服务器报告负载统计信息。

- **修复** 修复了通过 Istio 遥测 API 禁用日志提供程序不起作用的问题。

- **修复** 修复了除非明确指定 `match.metric=ALL_METRICS`，
  否则 `Telemetry` 不会完全禁用的问题；匹配所有指标现在被正确地视为默认值。

## 可扩展性 {#extensibility}

- **新增** 添加了一个在获取失败和 VM 致命错误时无法打开的选项。

## 安装 {#installation}

- **改进** 改进了在使用 OpenShift 集群时需要针对每个应用程序命名空间中手动创建
  `NetworkAttachmentDefinition` 资源情况。

- **更新** 更新了 Kiali 插件至 `v1.72.0` 版。

- **新增** 在 Gateway Chart 中添加了对 `PodDisruptionBudget`（PDB）的支持。
  ([Issue #44469](https://github.com/istio/istio/issues/44469))

- **新增** 添加了设置 CNI Ambient `configDir` 路径的 Helm 值。
  ([Issue #45400](https://github.com/istio/istio/issues/45400))

- **新增** 添加了针对 macOS 和 Windows 的名为 `amd64` 的制品。
  `amd64` 的制品并不像我们为其他操作系统所做的在名称中包含架构信息那样。这使得制品命名保持一致。

- **新增** 在 CNI 部署 Helm Chart 中添加 `rollingUpdate` `maxUnavailable` 设置以加快部署速度。

- **新增** 添加了自动设置 `GOMEMLIMIT` 和 `GOMAXPROCS` 到所有部署以提高性能。

- **新增** 添加了 Helm Chart [使用](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#configurable-scaling-behavior)中
  Istiod 的 HPA 的可配置缩放行为。
  ([Issue #42634](https://github.com/istio/istio/issues/42634))

- **新增** 向 Istio Pilot Helm Chart 中添加了值，用于配置其他容器参数：
  `volumeMounts` 和 `volumes`。可以与证书管理器 `istio-csr` 结合使用。
  ([Issue #113](https://github.com/cert-manager/istio-csr/issues/113))

- **新增** 向 Istiod Helm Chart 中添加了值，用于在部署上配置
  [topologySpreadConstraints](https://kubernetes.io/docs/concepts/workloads/pods/pod-topology-spread-constraints/)。
  可用于更好地放置 Istiod 工作负载。
  ([Issue #42938](https://github.com/istio/istio/issues/42938))

- **新增** 添加了允许通过 Helm Chart 为 ztunnel Pod 设置 `terminationGracePeriodSeconds`。

- **修复** 修复了从 IstioOperator 中删除字段并重新安装未反映现有 IstioOperator 规范中的更改的问题。
  ([Issue #42068](https://github.com/istio/istio/issues/42068))

- **修复** 修复了当未设置修订版时，Operator 安装时无法正确生成 `ValidatingWebhookConfiguration` 的问题。
  ([Issue #43893](https://github.com/istio/istio/issues/43893))

- **修复** 修复了 Operator 未拒绝包含空格的无效 CIDR 条目的问题。
  ([Issue #45338](https://github.com/istio/istio/issues/45338))

- **修复** 修复了主机名包未被列为 VM 包依赖项的问题。
  ([Issue #45866](https://github.com/istio/istio/issues/45866))

- **修复** 修复了阻止 Gateway Chart 与自定义 `HorizontalPodAutoscaler` 资源一起使用的问题。

- **修复** 修复了 Istio 应在 AWS 上尽可能使用 `IMDSv2` 的问题。
  ([Issue #45825](https://github.com/istio/istio/issues/45825))

- **修复** 修复了 OpenShift 配置文件设置 `sidecarInjectorWebhook`
  导致使用多个网络时 `k8s.v1.cni.cncf.io/networks` 被覆盖的问题。
  ([Issue #43632](https://github.com/istio/istio/issues/43632))、([Issue #45034](https://github.com/istio/istio/issues/45034))

- **修复** 修复了使用没有跟踪选项的 `datadog` 或 `stackdriver` 时产生空遍历问题。
  ([Issue #45855](https://github.com/istio/istio/issues/45855))

- **修复** 修复了阻止路点和 ztunnel 端口暴露的问题。也可以为 Ambient 组件创建抓取的配置文件。
  ([Issue #45093](https://github.com/istio/istio/issues/45093))

- **移除** 移除了以下实验性 `istioctl` 命令：`add-to-mesh`、`remove-from-mesh` 和 `kube-uninject`。
  建议使用自动 Sidecar 注入。

- **移除** 移除了 `ENABLE_LEGACY_FSGROUP_INJECTION` 功能标志。
  其目的是支持 Kubernetes 1.18 及更早版本，但这些版本已不再受支持。

- **移除** 从 `base` Helm Chart 中移除了过时的清单。有关详细信息，请参阅升级说明。

## istioctl

- **改进** 改进了 IST0123 警告消息描述。

- **更新** 更新了 `istioctl experimental workload configure`
  命令以接受通过 `--ingressIP` 传递的 IPv6 地址。

- **新增** 添加了配置类型和端点配置摘要到 `istioctl proxy-config all`。
  ([Issue #43807](https://github.com/istio/istio/issues/43807))

- **新增** 添加了对 `istioctl validate` 的目录支持。
  现在，`-f` 标志接受文件路径和目录路径。

- **新增** 添加了对 YAML 输出到 `istioctl admin log` 的支持。

- **新增** 添加了对检查遥测标签的支持，现在包括 Istio 规范标签和 Kubernetes 推荐标签。

- **新增** 添加了对代理状态的命名空间过滤的支持。注意：
  请确保 istioctl 和 istiod 均已升级才能使此功能正常工作。

- **新增** 添加了对验证 JSON 文件到 `istioctl validate` 的支持。
  ([Issue #46136](https://github.com/istio/istio/issues/46136))、([Issue #46136](https://github.com/istio/istio/issues/46136))

- **新增** 如果用户在同一命名空间中指定多个 Istio 标签，
  对其添加了警告。包括 `istio-injection`、`istio.io/rev`、`istio.io/dataplane-mode`。

- **新增** 添加了支持在 `istioctl proxy-config listeners` 中显示多个侦听器地址。

- **修复** 修复了 `verify-install` 无法检测到 `DaemonSet` 组件状态的问题。

- **修复** 修复了 `istioctl proxy-config Secret` 命令中的证书有效性不准确的问题。

- **修复** 修复了 xDS `proxy-status` 显示不准确的 Istio 版本的问题。
  注意：请确保 istioctl 和 istiod 均已升级，此修复程序才能发挥作用。

- **修复** 修复了 ztunnel Pod 可以与 `istioctl proxy-status`
  和 `istioctl Experimental proxy-status` 中的 Envoy
  配置文件进行比较的问题。他们现在被排除在比较之外。

- **修复** 修复了对 ztunnel Pod 执行 `rootCA` 比较时出现解析错误的问题。

- **修复** 修复了分析器报告网关管理服务消息的问题。

- **修复** 修复了在 `istioctl bug-report` 中通过 `--include`
  指定多个包含条件无法按预期工作的问题。
  ([Issue #45839](https://github.com/istio/istio/issues/45839))

- **修复** 修复了当未使用 `--revision` 标志时，带有修订标签的 Kubernetes
  资源会被 `istioctlanalyze` 过滤掉的问题。
  ([Issue #46239](https://github.com/istio/istio/issues/46239))

- **修复** 修复了在没有任何提供程序的情况下创建 Telemetry 对象会引发 IST0157 错误的问题。
  ([Issue #46510](https://github.com/istio/istio/issues/46510))

- **修复** 修复了当 `Gateway.Spec.Servers[].Port.Number` 与服务的 `Port`
  而不是 `TargetPort` 关联时，分析器为 `GatewayPortNotOnWorkload` 生成不正确结果的问题。

- **修复** 修复了 `istioctl experimental precheck` 中缺少`revision` 标志的问题。

- **移除** 从 `istioctl experimental` 中移除了 `uninstall` 命令。
  请改用 `istioctl uninstall` 替代。

- **移除** 移除了以下实验性 `istioctl` 命令：`create-remote-secret` 和 `remote-clusters`。
  它们已移至顶级 `istioctl` 命令。

## 文档变更 {#documentation-changes}

- **改进** 改进了 Bookinfo 示例，现在可以直接在 OpenShift 中使用它们，而无需 `anyuid` SCC 权限。
