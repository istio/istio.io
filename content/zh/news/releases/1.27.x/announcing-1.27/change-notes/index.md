---
title: Istio 1.27.0 Change Notes
linktitle: 1.27.0
subtitle: Minor Release
description: Istio 1.27.0 release notes.
publishdate: 2025-08-11
release: 1.27.0
weight: 10
aliases:
    - /zh/news/announcing-1.27.0
    - /zh/news/announcing-1.27.x
---

## 流量治理 {#traffic-management}

- **更新** 当 Kubernetes 服务 `trafficDistribution` 字段设置为
  `PreferClose` 时，更新了流量分布以忽略子区域。
  ([Issue #55848](https://github.com/istio/istio/issues/55848))

- **新增** 添加了对网关（istio 和 Gateway API）中的多个服务器证书的支持。
  ([Issue #36181](https://github.com/istio/istio/issues/36181))

- **新增** 添加了 Alpha 版本支持在 Ambient 多集群配置的 MeshConfig
  中指定 `ServiceScope`。`ServiceScope` 允许选择单个服务或命名空间中的服务为全局或本地服务。
  本地服务只能由与其位于同一集群的数据平面发现。本地服务无法被其他集群中的数据平面发现。
  全局服务可被所有集群中的数据平面发现。定义 `serviceScopeConfigs` 的选择器可确定哪些服务和工作负载与数据平面共享，
  以及为网格中的 waypoint（包括东西向网关）配置哪些集群和侦听器。

- **新增** 添加了功能标志 `EnableGatewayAPICopyLabelsAnnotations`，
  允许用户选择部署资源是否从父 Gateway API 资源继承属性。此功能默认启用。

- **新增** 添加了对 Kubernetes 服务 `trafficDistribution` 字段上的
  `PreferSameNode` 和 `PreferSameZone` 的支持。
  ([Issue #55848](https://github.com/istio/istio/issues/55848))

- **新增** 添加了 Pilot 环境变量 `PILOT_IP_AUTOALLOCATE_IPV4_PREFIX` 和 `PILOT_IP_AUTOALLOCATE_IPV6_PREFIX`，
  用于配置自动分配 IP 的 IP CIDR 前缀。这允许用户设置用于自动分配的特定 IP 范围，
  从而更好地控制 ipallocate 控制器用于 VIP 的 IP 地址空间。

- **新增** 当证书无效时，添加了对 Secret 的命名空间和名称的日志。
  ([Issue #56651](https://github.com/istio/istio/issues/56651))

- **新增** 添加了对 [Gateway API 推理扩展](https://gateway-api-inference-extension.sigs.k8s.io/)
  的支持。此功能默认关闭，可通过 `SUPPORT_GATEWAY_API_INFERENCE_EXTENSION` 环境变量开启。
  ([Issue #55768](https://github.com/istio/istio/issues/55768))

- **新增** 添加了在应用于 EnvoyFilter 中的 `LISTENER_FILTER` 时对合并操作的支持。

- **新增** 添加了功能 `ENABLE_LAZY_SIDECAR_EVALUATION`，
  允许启用 Sidecar 资源的延迟初始化，仅在代理实际使用 `SidecarScopes` 时才计算内部索引。
  此功能取代了之前的 `PILOT_CONVERT_SIDECAR_SCOPE_CONCURRENCY`，
  后者允许使用指定的并发度进行并发转换，而 `ENABLE_LAZY_SIDECAR_EVALUATION`
  将使用与 `PILOT_PUSH_THROTTLE` 相同的并发度。

- **新增** 添加了使用 Istio Sidecar 模式时对原生 `nftables` 的支持。
  此更新使得可以使用 `nftables` 替代 iptables 来管理网络规则成为可能，
  从而为 Pod 和服务提供更高效的流量重定向方法。要启用 `nftables` 模式，
  请在安装时使用 `--set values.global.nativeNftables=true`。
  ([Issue #56487](https://github.com/istio/istio/issues/56487))

- **新增** 添加了对指定服务流量分配模式的支持。
  ([Issue #53354](https://github.com/istio/istio/issues/53354))

- **新增** 添加了 `ENABLE_PROXY_FIND_POD_BY_IP` 功能，
  如果通过名称和命名空间的关联失败，则允许通过 IP 地址将 Pod 与代理关联。

- **新增** 添加了对 `DestinationRule` 资源中重试预算的支持。

- **修复** 修复了网关状态控制器领导者选举未按修订版本运行的问题，
  该问题可能导致多修订版本设置出现问题。现在，领导者选举已正确限定在每个修订版本内，
  确保网关状态控制器在每个修订版本中独立运行。
  ([Issue #55717](https://github.com/istio/istio/issues/55717))

- **修复** 修复了当虚拟服务配置了包含混合大小写字母的主机时虚拟服务路由被忽略的问题。
  ([Issue #55767](https://github.com/istio/istio/issues/55767))

- **修复** 修复了 Istio 1.26.0 中的一个回归问题，该问题在处理 Gateway API 主机名时导致 istiod 出现混乱。
  ([Issue #56300](https://github.com/istio/istio/issues/56300))

- **修复** 修复了当 `PILOT_ENABLE_TELEMETRY_LABEL` 或 `PILOT_ENDPOINT_TELEMETRY_LABEL`
  设置为 `false` 时意外禁用 mTLS 的问题。
  ([Issue #56352](https://github.com/istio/istio/issues/56352))

- **修复** 修复了由于某些部署中优先级较高的 CNI 规则而跳过 Ambient 主机网络 iptables 规则的问题。
  ([Issue #56414](https://github.com/istio/istio/issues/56414))

- **修复** 修复了 `EnvoyFilter` 与 `targetRefs` 匹配不正确资源的问题。
  ([Issue #56417](https://github.com/istio/istio/issues/56417))

- **修复** 修复了 Ambient 索引，以便根据修订版本过滤配置。
  ([Issue #56477](https://github.com/istio/istio/issues/56477))

- **修复** 修复了使用 `discoverySelectors` 时系统命名空间中未正确跳过
  `topology.istio.io/network` 标签的问题。
  ([Issue #56687](https://github.com/istio/istio/issues/56687))

- **修复** 修复了 CNI 插件在 Pod 尚未被标记为已注册到网格中时错误处理 Pod 删除的问题。
  在某些情况下，这可能会导致已删除的 Pod 被包含在 ZDS 快照中，
  并且永远不会被清理。如果发生这种情况，ztunnel 将无法准备就绪。
  ([Issue #56738](https://github.com/istio/istio/issues/56738))

- **修复** 修复了 Istio 出站路由配置未在
  `VirtualHost` 条目的域列表中包含绝对域名（以点结尾的完全限定域名）的问题。
  此更改可确保使用绝对域名（以点结尾，例如 `my-service.my-ns.svc.cluster.local.`）
  的请求正确路由到目标服务，而不是回退到 `PassthroughCluster`。
  ([Issue #56007](https://github.com/istio/istio/issues/56007))

## 安全性 {#security}

- **新增** 添加了支持省略 JWT 令牌中的颁发者声明。
  颁发者声明或 `JWKSUri` 是必需的，但不能同时使用。
  这使得在使用 JWT 令牌进行身份验证时配置更加灵活，尤其是在颁发者声明可能动态的情况下。
  ([Issue #14400](https://github.com/istio/istio/issues/14400))

- **新增** 添加了在 Ambient 模式下使用 istio-cni 时可选功能，
  用于创建 Istio 拥有的 CNI 配置文件，其中包含主 CNI 配置文件和 Istio CNI 插件的内容。
  此可选功能旨在解决当 Istio CNI `DaemonSet` 未就绪、
  Istio CNI 插件未安装或未调用该插件配置从 Pod 到其节点 ztunnel 的流量重定向时，
  节点重启时流量绕过网格的问题。此功能可通过在 istio-cni Helm Chart 值中将 `cni.istioOwnedCNIConfig` 设置为 true 来启用。
  如果未设置 `cni.istioOwnedCNIConfigFilename` 的值，
  则 Istio 拥有的 CNI 配置文件将被命名为 `02-istio-cni.conflist`。
  `istioOwnedCNIConfigFilename` 值的字典优先级必须高于主 CNI。
  必须启用环境和链式 CNI 插件才能使此功能正常工作。

- **新增** 添加了 istioctl `--clusterAliases` 命令参数的验证。每个集群不应拥有多于一个别名。
  ([Issue #56022](https://github.com/istio/istio/issues/56022))

- **新增** 添加了对 `ClusterTrustBundle` 的支持，
  并将 API 从 `certificates.k8s.io/v1alpha1` 迁移到 Kubernetes 1.33+
  版本中稳定的 `v1beta1`。这提高了兼容性，并使 Istio 的证书分发机制更具前瞻性。
  ([Issue #56306](https://github.com/istio/istio/issues/56306))

- **新增** 在网关 TLS 配置中添加了对外部密钥发现服务 (SDS) 提供商的支持。
  Istio 现在改进了与外部 SDS 提供商的集成，以便在网关上进行 TLS 证书管理。
  ([Issue #56522](https://github.com/istio/istio/issues/56522))

- **新增** 添加了对插件 CA 的证书吊销列表 (CRL) 支持，
  使 Istio 能够监视 `ca-crl.pem` 文件并自动在集群中的所有命名空间中分发 CRL。
  此增强功能允许代理验证并拒绝已吊销的证书，从而增强了使用插件 CA 进行服务网格部署的安全性。
  ([Issue #56529](https://github.com/istio/istio/issues/56529))

- **新增** 已将 Post-Quantum Cryptography (PQC) 选项添加到 `COMPLIANCE_POLICY`。
  此策略强制执行 TLS `v1.3`、密码套件 `TLS_AES_128_GCM_SHA256` 和
  `TLS_AES_256_GCM_SHA384` 以及 post-quantum-safe 密钥交换 `X25519MLKEM768`。
  要在 Ambient 模式下启用此合规性策略，必须在 pilot 和 ztunnel 容器中进行设置。
  此策略适用于以下数据路径：
    - Envoy 代理和 ztunnel 之间的 mTLS 通信；
    - Envoy 代理（例如网关）的下游和上游的常规 TLS；
    - Istio xDS 服务器。
  ([Issue #56330](https://github.com/istio/istio/issues/56330))

- **修复** 修复了使用 `--clusterAliases` 命令参数时，
  具有旧 `CLUSTER_ID` 设置的 Sidecar 无法连接到具有新 `CLUSTER_ID` 设置的 istiod 的问题。
  ([Issue #56022](https://github.com/istio/istio/issues/56022))

- **修复** 修复了 `pluginca` 功能中的一个问题：如果提供的 `cacerts` 软件包不完整，
  `istiod` 会静默回退到自签名 CA。现在，系统可以正确验证所有必需的
  CA 文件是否存在，如果软件包不完整，则会失败并显示错误。

## 遥测 {#telemetry}

- **修复** 修复了 Grafana 仪表板使用基于路径的链接链接到 Istio Mesh 仪表板时不再起作用的问题。
  工作负载和服务链接现在使用仪表板 UID。
  ([Issue #50124](https://github.com/istio/istio/issues/50124))

- **修复** 修复了当引用的服务创建时间晚于遥测资源时，访问日志未更新的问题。
  ([Issue #56825](https://github.com/istio/istio/issues/56825))

- **移除** 删除了对 `Lightstep` 链路追踪提供程序的支持。
  ([Issue #54002](https://github.com/istio/istio/issues/54002))

## 扩展性 {#extensibility}

- **新增** 添加了如果 VM 出现故障，则在新的请求上重新加载 Wasm VM 的选项。

## 安装 {#installation}

- **提升** 已将环境变量 `ENABLE_NATIVE_SIDECARS` 升级为默认值 `true`。
  这意味着，除非明确禁用，否则原生 Sidecar 将被注入到所有符合条件的 Pod 中。
  您可以通过在各个 Pod 或 Pod 模板中添加注释 `sidecar.istio.io/native-side: "false"`
  来明确禁用此功能，或针对特定工作负载禁用此功能。
  ([Issue #48794](https://github.com/istio/istio/issues/48794))

- **新增** 添加了一个设置 `values.global.trustBundleName`，
  用于配置 istiod 用于在集群中传播其根 CA 证书的 ConfigMap 的名称。
  这允许在同一集群中运行具有重叠命名空间的多个控制平面。

- **新增** 添加了对自定义 Ambient 启用标签的支持。
  ([Issue #53578](https://github.com/istio/istio/issues/53578))

- **新增** 添加了在 Gateway Helm Chart 上配置 `additionalContainers` 和 `initContainers` 的支持。

- **新增** 添加了通过 Helm Chart Value 配置 ztunnel 容忍度的支持。
  ([Issue #56086](https://github.com/istio/istio/issues/56086))

- **新增** 添加了通过 Helm Chart Value 配置 istio-cni 容忍度的支持。
  ([Issue #56087](https://github.com/istio/istio/issues/56087))

- **新增** 添加了 `GOMEMLIMIT` 和 `GOMAXPROCS` 除数的定义默认值，以修复 Argo 永久不同步问题。

- **新增** 添加了 `gateway-injection-template` 的引导覆盖配置。
  ([Issue #28302](https://github.com/istio/istio/issues/28302))

- **新增** 在 Istio 1.24、1.25 和 1.26 的兼容性配置文件中添加了
  `ENABLE_NATIVE_SIDECARS` Helm Value，允许用户禁用原生 Sidecar 的默认启用。

- **新增** 添加了对状态端口的代理协议支持。
  ([引用](/zh/docs/reference/commands/pilot-agent/#envvars))
  ([Issue #39868](https://github.com/istio/istio/issues/39868))

- **新增** 添加了 Helm Value `.Values.istiodRemote.enabledLocalInjectorIstiod`，
  以支持远程集群中的 Sidecar 注入。当 `profile=remote`、`.Values.istiodRemote.enabledLocalInjectorIstiod=true`
  和 `.Values.global.remotePilotAddress="${DISCOVERY_ADDRESS}"` 时，
  远程工作集群会安装 `istiod` 以进行本地 Sidecar 注入，而 XDS 仍由远程主集群提供服务。
  ([Issue #56328](https://github.com/istio/istio/issues/56328))

- **新增** 启用 `istiodRemote` 时，向 istio 远程服务添加 `istio.io/rev` 标签
  ([Issue #56142](https://github.com/istio/istio/issues/56142))

- **新增** 在 istiod Helm Chart 中添加了对 `deploymentAnnotations` 的支持。
  除了现有的 `podAnnotations` 支持之外，用户现在还可以指定要应用于 istiod Deployment 对象的自定义注解。
  这对于与在部署级别运行的监控工具、GitOps 工作流和策略执行系统的集成非常有用。

- **修复** 修复了重新调用 Istio Webhook 时未设置用于探测重写的 `ISTIO_KUBE_APP_PROBERS` 环境变量的问题。
  ([Issue #56102](https://github.com/istio/istio/issues/56102))

- **修复** 修复了 `istio/gateway` Helm Chart 环境中的 Secret 引用被错误地呈现为字符串的问题。
  ([Issue #55141](https://github.com/istio/istio/issues/55141))

- **修复** 修复了当 `gateway` 模板与另一个模板（如 `spire`）结合时发生的注入失败的问题，
  该模板覆盖了 `workload-socket`，导致 Kubernetes 无法创建其他卷，例如具有 `emptyDir` 和 `csi` 设置的卷。

- **修复** 修复了当 `IstioOperator` 配置包含多个网关时，
  `istioctl manifest translate` 中出现的异常。
  ([Issue #56223](https://github.com/istio/istio/issues/56223))

- **修复** 修复了启用 TPROXY 模式时 OpenShift 集群上的 `istio-proxy`
  和 `istio-validation` 容器分配不正确的 UID 和 GID 的问题。

- **修复** 修复了启用 `ENABLE_CLUSTER_TRUST_BUNDLE_API` 时 `ClusterTrustBundle` 未正确配置的问题。

- **移除** 删除了未使用的与多集群相关的 Helm Value。

## istioctl

- **新增** 添加了 `--kubeclient-timeout` 标志到 `istioctl` 根标志。
  可以取消设置，或设置为有效的 `time.Duration` 字符串。
  指定后，它将覆盖所有使用 Kubernetes 客户端的 `istioctl` 命令的默认 `15s` 超时。
  这对于 Kubernetes API 服务器速度较慢的环境（例如高延迟或低带宽的环境）非常有用。
  请注意，此标志仅适用于 Kubernetes 客户端，不会影响 `istioctl` 中的其他超时设置，例如安装超时。
  ([Issue #54962](https://github.com/istio/istio/issues/54962))

- **新增** 为 `istioctl dashboard controlz`
  和 `istioctl dashboard istiod-debug` 添加 `--revision` 标志。

- **新增** 在 `istioctl proxy-status` 命令中添加了支持将所有 xDS/CRD 类型动态显示为输出表中的列。
  ([Issue #56005](https://github.com/istio/istio/issues/56005))

- **新增** 添加了对自定义 `istioctl waypoint status` 和 `istioctl waypoint apply` 超时的支持。
  ([Issue #56453](https://github.com/istio/istio/issues/56453))

-**新增** 添加了在命令 `istioctl admin log` 中显示 `stack-trace-level` 的支持。
  ([Issue #56465](https://github.com/istio/istio/issues/56465))

- **新增** 添加了在命令 `istioctl waypoint list` 中显示 `traffic type` 的支持。

- **新增** 添加了对命令 `istioctl experimental workload group create` 中的 `--weight` 参数的支持。

- **新增** 添加了在 `istioctl admin log` 中配置 `ip-autoallocate` 日志级别的支持。
  ([Issue #55741](https://github.com/istio/istio/issues/55741))

- **修复** 修复了在安装过程中，当修订版本不是默认值时，
  不会创建 `istio-revision-tag-default` 和 `MutatingWebhookConfiguration` 的问题。
  ([Issue #55980](https://github.com/istio/istio/issues/55980))

- **修复** 修复了当 `PILOT_ENABLE_IP_AUTOALLOCATE` 设置为 `true` 时，
  `istioctl analyze` 中出现 IST0134 误报的问题。
  ([Issue #56083](https://github.com/istio/istio/issues/56083))

- **修复** 修复了分析包含 Kubernetes 系统命名空间（例如 `kube-system`、`kube-node-lease`）的问题。
  ([Issue #55022](https://github.com/istio/istio/issues/55022))

- **修复** 修复了 `create-remote-secret` 创建冗余 RBAC 资源的问题。
  ([Issue #56558](https://github.com/istio/istio/issues/56558))
