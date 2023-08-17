---
title: Istio 1.14 变更说明
linktitle: 1.14.0
subtitle: 次要版本
description: Istio 1.14.0 次要版本。
publishdate: 2022-05-24
release: 1.14.0
weight: 10
aliases:
- /zh/news/announcing-1.14.0
---

## 流量管理{#traffic-management}

- **新增** 支持将未准备好的端点发送到 Envoy，当 Envoy 启用慢启动模式时，这将非常有用。
  这可以通过将 `PILOT_SEND_UNHEALTHY_ENDPOINTS` 设置为 false 来禁用。

- **新增** 新的配置选项 `istio-iptables` 和 `istio-clean-iptables`
  用于包括/排除某些用户组不拦截流出的流量生成。

  该特性主要用于系统管理员需要的虚拟机将传出流量的拦截限制在少数几个应用程序上拦截所有对外通讯。

  默认情况下，Istio Sidecar 将拦截来自所有进程的输出流量，
  不管它们在什么用户组下运行。

  为了改变这种行为，系统管理员现在可以使用两个新的环境变量 `istio-iptables` 和 `istio-clean-iptables` 支持: `ISTIO_OUTBOUND_OWNER_GROUPS` 和 `ISTIO_OUTBOUND_OWNER_GROUPS_EXCLUDE`。

`ISTIO_OUTBOUND_OWNER_GROUPS` 是一个以逗号分隔的组列表，其输出流量
  应该重定向到 Envoy (sidecar)。
  可以通过名称或数字 GID 指定组。
  通配符 `*` 可用于配置来自所有组的流量重定向。
  （默认）。

  `ISTIO_OUTBOUND_OWNER_GROUPS_EXCLUDE` 是一个逗号分隔的组列表，其传出
  流量应从重定向到 Envoy (sidecar)中排除。
  可以通过名称或数字 GID 指定组。
  仅当来自所有组（即 `*`）的流量被重定向到 Envoy（sidecar）时才适用。

  `ISTIO_OUTBOUND_OWNER_GROUPS` 和 `ISTIO_OUTBOUND_OWNER_GROUPS_EXCLUDE` 是相互的专属，只使用其中之一。

  例如，`ISTIO_OUTBOUND_OWNER_GROUPS=101,java` 指示仅拦截来自
    那些在用户组 `101` (`GID`)或 `java` (名称)下运行的进程。
  `ISTIO_OUTBOUND_OWNER_GROUPS_EXCLUDE=root,202` 指示拦截传出流量
    来自所有进程，除了用户组 `202` 下的进程(通过 `GID`)或者 `root` (按名称)。
    ([Issue #37057](https://github.com/istio/istio/issues/37057))

- **新增** 基于下游HTTP主机/机构报头执行自动SAN验证的能力
  当启用 `ENABLE_AUTO_SNI` 和 `VERIFY_CERTIFICATE_AT_CLIENT` 功能标志时。

- **新增** 能够在 `DestinationRules` 时自动设置 SNI
  不指定它并且启用 `ENABLE_AUTO_SNI`。

- **新增** 设置基于 `credentialName` 的机密配置的能力
  当在 `WorkloadSelector` 中指定 `DestinationRule` 时，
  前提是 sidecar 有权在其所在的命名空间中列出机密。

- **新增** `DestinationRule` 支持 `WorkloadSelector`。

- **新增** 在 `VirtualService.TLSRoute.Match.SniHosts` 中尝试使用IP地址作为SNI值的用户警告消息。
  ([Issue #33401](https://github.com/istio/istio/issues/33401))

- **新增** 支持在 Envoy 过滤器中替换虚拟主机。

- **新增** 在 [Proxy Config](/zh/docs/reference/config/istio.mesh.v1alpha1/#ProxyConfig) 中新增了 API `runtimeValues` 来
  配置 Envoy 运行时。  ([Issue #37202](https://github.com/istio/istio/issues/37202))

- **新增** 设置上游 TLS 最高版本为 TLS 1.3。  ([Issue #36271](https://github.com/istio/istio/issues/36271))

- **修复** 如果一个服务的多个 `destinationRules` 被合并，xDS 可能不会更新的问题。
  在这种情况下，合并规则仅记录所有 `destinationRules` 中的一个名称/命名空间对。
  但是，此元数据用于记录 sidecar 的配置依赖关系。

  在这个修复中，我们引入了一个新的结构 `consolidatedDestRule` 并记录了所有的 `destinationrules` 元数据
  以避免丢失任何  `destinationRule` 依赖项。  ([Issue #38082](https://github.com/istio/istio/issues/38082))

- **修复** 删除内联网络和 HTTP 过滤器无法正常工作的问题。

- **修复** 导致从网关到服务的流量 [undeclared protocol](/zh/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection) 被视为TCP流量而不是HTTP流量的问题。
  ([Issue #37196](https://github.com/istio/istio/issues/37196))

- **修复** 当 DNS 查找失败时， `DNS` 类型 `ServiceEntry` 会导致过多的 DNS 请求。
  ([Issue #35603](https://github.com/istio/istio/issues/35603))

- **修复** 使用 CNI 时的 IP 系列检测与不使用 CNI 时的行为方式相同。
  ([Issue #36871](https://github.com/istio/istio/issues/36871))

- **修复** 在具有 IPv4 NAT 实施的集群上进行 IPv6 检测，例如 Amazon EKS，通过从检测中排除链接本地地址。
  ([Issue #36961](https://github.com/istio/istio/issues/36961))

- **改进** XDS 生成尽可能发送更少的资源，有时完全忽略响应。
  这可以通过  `PILOT_PARTIAL_FULL_PUSHES=false` 环境变量禁用。
  ([Issue #37989](https://github.com/istio/istio/issues/37989)),([Issue #37974](https://github.com/istio/istio/issues/37974))

- **更新** Istio 的默认负载均衡算法从 `ROUND_ROBIN` 改为 `LEAST_REQUEST`。
  `ROUND_ROBIN` 算法可能会导致端点负载过重，尤其是当权重时被使用。`LEAST_REQUEST` 算法更均匀地分配负载并且更少可能会使端点负担过重。大量实验（Istio 和
  Envoy 团队）已经表明，`LEAST_REQUEST` 在几乎所有方面都优于  `ROUND_ROBIN` ，很少/没有缺点。它通常被认为是替代
  `ROUND_ROBIN`。
  如果明确指定，将继续支持 `ROUND_ROBIN`。恢复
  `ROUND_ROBIN` 作为默认值，设置 istiod 环境变量
  `ENABLE_LEGACY_LB_ALGORITHM_DEFAULT=true`。

## 安全{#security}

- **新增** 通过 Envoy SDS API 进行 CA 集成的新方法。
  ([usage]( https://istio.io/latest/docs/ops/integrations/spire/))([design]( https://docs.google.com/document/d/1zJP6QJukLzckTbdY42ZMLkulGXz4gWzH9SwOh4xoe0A)) ([Issue #37183](https://github.com/istio/istio/issues/37183))

- **新增** Istio 外部授权的 `allowed_client_headers_on_success` 功能。
  ([Issue #36950](https://github.com/istio/istio/issues/36950))

- **新增** 支持在 SDS 中使用  `PrivateKeyProvider`。 ([Issue #35809](https://github.com/istio/istio/issues/35809))

- **新增** 支持工作负载的 TLS 配置 API。  ([Issue #2285](https://github.com/istio/api/issues/2285))

- **修复** 请求身份验证策略始终允许 CORS 预检请求。
  ([Issue #36911](https://github.com/istio/istio/issues/36911))

## 遥测{#telemetry}

- **新增** OpenTelemetry 访问日志的实现。

- **新增** 通过 WasmPlugin API 中的 VM 配置在 Wasm 扩展中支持环境变量。

- **新增** `WorkloadMode` 选择到 Logging。

- **新增** 支持在 Telemetry API 中跟踪 `WorkloadMode`。这将允许基于流量方向自定义跟踪行为。

- **新增** 为具有 `MESH_EXTERNAL` 位置的 ServiceEntry 资源导出规范服务标签的初始标志保护支持。

## 可扩展性{#extensibility}

- **新增** 当环境变量 `WASM_INSECURE_REGISTRIES` 中的主机名之一是 * 时，允许所有不安全的服务器。

- **新增** 支持 `ImagePullPolicy` API 的 `WasmPlugin`。

- **新增** 支持使用 `imagePullSecret` 从私有存储库中提取镜像的 `WasmPlugin`。

- **改进** 使用标签剥离的 URL + 校验和作为 Wasm 模块缓存键，标签 URL 单独缓存。
  这可能会增加缓存命中的机会（例如，尝试使用标记 URL 和摘要 URL 查找相同的图像。）
  此外，这将是实现  `ImagePullPolicy` 的基础。

## 安装{#installation}

- **新增** 支持将网关 helm chart 安装为 `daemonset`。
  ([Issue #37610](https://github.com/istio/istio/issues/37610))

- **新增** 支持 policy/v1 PDB。  ([Issue #32005](https://github.com/istio/istio/issues/32005))

- **修复** 在 `istio-ca-root-cert` 更改后 Envoy 失去连接的问题。
  ([Issue #36723](https://github.com/istio/istio/issues/36723))

- **修复** 当 `.autoscaleEnabled` 为 `true` 且 `.k8s.replicaCount` 非零时，阻止操作员更新部署的问题。
  当 `autoscale` 都启用且 `replicaCount` 非零时，验证期间将生成警告消息。

- **修复**  `customService` 中的未知字段 `v1alpha1.EgressGatewayConfig`。
  ([Issue #37260](https://github.com/istio/istio/issues/37260))

- **修复** 有多个容器时的默认容器注解。
  ([Issue #38060](https://github.com/istio/istio/pull/38060))

- **修复** `istioctl` 应该在运行分析时在所有修订中添加 Kubernetes 资源。
  ([Issue #38148](https://github.com/istio/istio/issues/38148))

- **修复** 更改为 Istio 默认部署的 `EnvoyFilters` 添加优先级 -1 以在首次安装时从 `istioctl` `EnvoyFilter` 分析器中删除警告。
  ([Issue #38676](https://github.com/istio/istio/issues/38676))

- **修复** 集群内操作员无法在重新创建相同的 `IstioOperator` 资源时创建资源。
  ([Issue #35657](https://github.com/istio/istio/issues/35657))

- **Removed** Chart 中的 `caBundle` 默认值以允许 GitOps 方法。
  ([Issue #33052](https://github.com/istio/istio/issues/33052))

## istioctl{#istioctl}

- **新增** 分析间隔，以减少浪费的分析仪重新运行。
  ([Issue #30200](https://github.com/istio/istio/issues/30200))

- **新增** `istioctl experimental ps` 的集群 ID。
  ([Issue #36290](https://github.com/istio/istio/issues/36290))

- **新增** 用于 Envoy 过滤器补丁操作的新分析器。
  ([Issue #37415](https://github.com/istio/istio/issues/37415))

- **新增** IST0103 分析消息的 pod 全名。

- **新增** `istioctl ps` 支持 ECDS。

- **修复** `istioctl install --dry-run` 的意外警告日志。
  ([Issue #37084](https://github.com/istio/istio/issues/37084))

- **修复** 使用 `kube-inject` 时出现 nil 指针，取消引用恐慌，没有通过所需的修订，但也传递了 `injectConfigMapName`。
  ([Issue #38083](https://github.com/istio/istio/issues/38083))

- **修复** Kubernetes 1.24+ 上 `istioctl create-remote-secret` 的行为。在这些版本中，
  不再自动创建包含 `ServiceAccount` API 令牌的 Secret，因此  `istioctl`
  将要 [创建一个服务账号令牌](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-service-account/#manually-create-an-api-token-for-a-serviceaccount)。
