---
title: Istio 1.25.0 更新说明
linktitle: 1.25.0
subtitle: 主要版本
description: Istio 1.25.0 更新说明。
publishdate: 2025-03-03
release: 1.25.0
weight: 10
aliases:
    - /zh/news/announcing-1.25.0
---

## 弃用通知 {#deprecation-notices}

这些通知描述了根据 [Istio 的弃用政策](/zh/docs/releases/feature-stages/#feature-phase-definition)将在未来版本中删除的功能。
请考虑升级您的环境以删除已弃用的功能。

- **弃用** 弃用了 `proxyMetadata` 中 `ISTIO_META_DNS_AUTO_ALLOCATE` 的使用，
  转而使用较新版本的 [DNS 自动分配](/zh/docs/ops/configuration/traffic-management/dns-proxy#address-auto-allocation)。
  Istio IP `auto-allocation` 的新用户应采用新的基于状态的控制器。
  现有用户可以继续使用较旧的实现。
  ([Issue #53596](https://github.com/istio/istio/issues/53596))

- **弃用** 弃用了 `traffic.sidecar.istio.io/kubevirtInterfaces`，改用 `istio.io/reroute-virtual-interfaces`。
  ([Issue #49829](https://github.com/istio/istio/issues/49829))

## 流量治理 {#traffic-management}

- **提升** 将 `cni.ambient.dnsCapture` 值默认提升为 `true`。
  这将默认启用 Ambient 网格中工作负载的 DNS 代理，从而提高安全性和性能并启用多项功能。
  可以明确禁用此功能，也可以使用 `compatibilityVersion=1.24` 禁用。
  注意：只有新 Pod 才会启用 DNS。要为现有 Pod 启用此功能，必须手动重新启动 Pod，
  或者必须使用 `--set cni.ambient.reconcileIptablesOnStartup=true` 启用 iptables 协调功能。

- **提升** 将 `PILOT_ENABLE_IP_AUTOALLOCATE` 值默认提升为 `true`。
  这将启用 [IP 自动分配](/zh/docs/ops/configuration/traffic-management/dns-proxy/#address-auto-allocation)的新迭代，
  解决分配不稳定、Ambient 支持和提高可见性等长期存在的问题。
  未设置 `spec.address` 的 `ServiceEntry` 对象现在将看到一个新字段 `status.addresses`，
  该字段会被自动设置。注意：除非代理配置为执行 DNS 代理（默认情况下保持关闭状态），否则不会使用这些。

- **更新** 更新了 `PILOT_SEND_UNHEALTHY_ENDPOINTS` 功能（默认情况下处于关闭状态），
  以不包括终止端点。这可确保在缩减或推出事件期间服务不会被视为不健康。

- **更新** 更新了 DNS 代理算法，随机选择将 DNS 请求转发到哪个上游。
  ([Issue #53414](https://github.com/istio/istio/issues/53414))

- **新增** 添加了新的 istiod 环境变量 `PILOT_DNS_JITTER_DURATION`，
  用于设置定期 DNS 解析的抖动。请参阅 `https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/cluster/v3/cluster.proto` 中的 `dns_jitter`。
  ([Issue #52877](https://github.com/istio/istio/issues/52877))

- **新增** 添加了 `ObservedGeneration` 到 Ambient 状态条件。此字段将显示生成条件时控制器观察到的对象的生成。
  ([Issue #53331](https://github.com/istio/istio/issues/53331))

- **新增** 添加了 istiod 环境变量 `PILOT_DNS_CARES_UDP_MAX_QUERIES`，
  用于控制 Envoy 默认 Cares DNS 解析器的 `udp_max_queries` 字段。
  未设置时，此值默认为 100。有关更多信息，
  请参阅 [Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/api-v3/extensions/network/dns_resolver/cares/v3/cares_dns_resolver.proto#envoy-v3-api-field-extensions-network-dns-resolver-cares-v3-caresdnsresolverconfig-udp-max-queries)。
  ([Issue #53577](https://github.com/istio/istio/issues/53577))

- **新增** 添加了在 `istio-cni` 升级时协调上一版本中现有 Ambient Pod 的 Pod 内 iptables 规则的支持。
  可以使用 `--set cni.ambient.reconcileIptablesOnStartup=true` 切换该功能，并将在未来版本中默认启用。
  ([Issue #1360](https://github.com/istio/istio/issues/1360))

- **新增** 添加了 `istio.io/reroute-virtual-interfaces` 注解，
  这是一个逗号分隔的虚拟接口列表，其入站流量将无条件视为出站。
  这允许使用虚拟网络（KubeVirt、VM、docker-in-docker 等）的工作负载在
  Sidecar 和 Ambient 网格流量捕获中正常运行。

- **新增** 添加了通过定位 `GatewayClass` 为 istio-waypoint 附加策略默认值的支持。
  ([Issue #54696](https://github.com/istio/istio/issues/54696))

- **新增** 添加了 `ambient.istio.io/dns-capture` 注解，
  可以取消设置，也可以设置为 `true` 或 `false`。
  在 Ambient 网格中注册的 `Pod` 上指定时，控制是否在 Ambient 中捕获和代理 DNS 流量（端口 53 上的 TCP 和 UDP）。
  如果此 Pod 级注解存在于 Pod 上，它将覆盖全局 `istio-cni` `AMBIENT_DNS_CAPTURE` 设置，
  该设置从 1.25 开始默认为 `true`。注意：将其设置为 `false` 将破坏某些 Istio 功能，
  例如 `ServiceEntry` 和出口 waypoint，但对于与 DNS 代理交互较差的工作负载来说可能是可取的。
  ([Issue #49829](https://github.com/istio/istio/issues/49829))

- **新增** 添加了在命名空间级别配置 `istio.io/ingress-use-waypoint` 标签的支持。

- **新增** 添加了对保留 HTTP/1.x 标头的原始大小写的支持。
  ([Issue #53680](https://github.com/istio/istio/issues/53680))

- **新增** 添加了对 `Service.spec.trafficDistribution` 字段和 `networking.istio.io/traffic-distribution` 注解的支持，
  允许使用更简单的机制使流量优先选择地理位置较近的端点。
  注意：此功能以前仅适用于 ztunnel，但现在所有数据平面均支持此功能。

- **修复** 修复了网关和 TLS 重定向中混合大小写主机的错误，该错误导致 RDS 过时。
  ([Issue #49638](https://github.com/istio/istio/issues/49638))

- **修复** 修复了在 `VirtualService` 中，匹配器指定 `sourceLabels` 的 `HTTPRoute` 会应用于 waypoint 的问题。
  ([Issue #51565](https://github.com/istio/istio/issues/51565))

- **修复** 修复了如果 WASM 镜像提取失败，则使用允许所有 RBAC 过滤器的问题。
  现在，如果将 `failStrategy` 设置为 `FAIL_CLOSE`，则将使用 DENY-ALL RBAC 过滤器。
  ([Issue #53279](https://github.com/istio/istio/issues/53279)),
  ([Issue #23624](https://github.com/istio/istio/issues/23624))

- **修复** 修复了 waypoint 代理以遵循信任域。

- **修复** 修复了在 `EnvoyFilter` 中合并 `Duration` 可能导致所有侦听器相关属性被意外修改的问题，
 因为所有侦听器共享相同的指针类型（`listener_filters_timeout`）。

- **修复** 修复了在清理有条件的 iptables 规则时出现错误的问题。

- **修复** 修复了配置问题，DNS 流量（UDP 和 TCP）现在受流量注解（如 `traffic.sidecar.istio.io/excludeOutboundIPRanges` 和 `traffic.sidecar.istio.io/excludeOutboundPorts`）的影响。
  之前，由于规则结构的原因，即使指定了 DNS 端口，UDP/DNS 流量也会唯一地忽略这些流量注解。
  行为变化实际上发生在 1.23 版本系列中，但未包含在 1.23 的发行说明中。
  ([Issue #53949](https://github.com/istio/istio/issues/53949))

- **修复** 修复了 istiod 无法正确处理跨命名空间 waypoint 代理的 `RequestAuthentication` 的问题。
  ([Issue #54051](https://github.com/istio/istio/issues/54051))

- **修复** 修复了升级到 1.24 版期间导致托管网关/waypoint 部署补丁失败的问题。
  ([Issue #54145](https://github.com/istio/istio/issues/54145))

- **修复** 修复了控制网关的非默认修订版缺少 `istio.io/rev` 标签的问题。
  ([Issue #54280](https://github.com/istio/istio/issues/54280))

- **修复** 修复了当 L7 规则存在于与 ztunnel 绑定的 `AuthorizationPolicy` 中时状态消息的措辞，使其更加清晰。
  ([Issue #54334](https://github.com/istio/istio/issues/54334))

- **修复** 修复了请求镜像过滤器错误计算百分比的错误。
  ([Issue #54357](https://github.com/istio/istio/issues/54357))

- **修复** 修复了在网关上使用 `istio.io/rev` 标签中的标记导致网关编程不当和缺少状态的问题。
  ([Issue #54458](https://github.com/istio/istio/issues/54458))

- **修复** 修复了无序 ztunnel 断开连接可能导致 `istio-cni` 处于认为没有连接的状态的问题。
  ([Issue #54544](https://github.com/istio/istio/issues/54544)),
  ([Issue #53843](https://github.com/istio/istio/issues/53843))

- **修复** 修复了规则检查和删除的过多 iptables 信息级别日志条目问题。
  如有必要，可以通过切换到调试级别日志来重新启用详细日志记录。
  ([Issue #54644](https://github.com/istio/istio/issues/54644))

- **修复** 修复了使用 Ambient 模式和 DNS 代理时导致 `ExternalName` 服务无法解析的问题。

- **修复** 修复了当多个服务的 IP 地址部分重叠时导致配置被拒绝的问题。
  例如，一个服务有 `[IP-A]`，另一个服务有 `[IP-B, IP-A]`。
  ([Issue #52847](https://github.com/istio/istio/issues/52847))

- **修复** 修复了导致 `VirtualService` 标头名称验证拒绝有效标头名称的问题。

- **修复** 修复了将 waypoint 代理从 Istio 1.23.x 升级到 Istio 1.24.x 时出现的问题。
  ([Issue #53883](https://github.com/istio/istio/issues/53883))

## 安全性 {#security}

- **新增** 向 `istio-cni-node` `DaemonSet` 添加 `DAC_OVERRIDE` 功能。
  这解决了在某些文件由非 root 用户拥有的环境中运行时出现的问题。
  注意：在 Istio 1.24 之前，`istio-cni-node` 以 `privileged` 身份运行。
  Istio 1.24 删除了此功能，但删除了一些必需的权限，现在已重新添加。
  相对于 Istio 1.23，`istio-cni-node` 的权限仍然比此更改后的权限少。

- **新增** 向 `istio-cni-node` `DaemonSet` 添加不受限制的 AppArmor 注解，
  以避免与阻止某些特权 Pod 功能的 AppArmor 配置文件发生冲突。
  以前，由于在 `SecurityContext` 中将特权设置为 true，
  因此 `istio-cni-node` `DaemonSet` 会绕过 AppArmor（启用时）。
  此更改可确保将 `istio-cni-node` `DaemonSet` 的 AppArmor 配置文件设置为不受限制。

- **修复** 修复了 Ambient `PeerAuthentication` 策略过于严格的问题。
  ([Issue #53884](https://github.com/istio/istio/issues/53884))

- **修复** 修复了 JWT 策略的 JWK 解析缓存中可能出现的竞争条件，
  当触发该条件时，会导致缓存未命中和轮换时更新签名密钥失败。
  ([Issue #52121](https://github.com/istio/istio/issues/52121))

-**修复** 修复了仅存在于 Ambient 中的一个错误，
  其中 `PeerAuthentication` 策略中的多个 `STRICT` 端口级 mTLS
  规则会由于不正确的评估逻辑（`AND` 与 `OR`）而有效地导致宽松的策略。
  ([Issue #54146](https://github.com/istio/istio/issues/54146))

- **修复** 修复了入口网关未使用 WDS 发现来检索 Ambient 目标元数据的问题。

## 遥测 {#telemetry}

- **新增** 添加了对 Sidecar 模式下遥测的附加标签交换的支持。
  ([Issue #54000](https://github.com/istio/istio/issues/54000))

- **新增** 添加了新的 `service.istio.io/workload-name` 标签，
  可以将其添加到 `Pod` 或 `WorkloadEntry` 以覆盖遥测中报告的“工作负载名称”。

- **新增** 添加了一个后备方案，使用 `WorkloadGroup` 名称作为由
  `WorkloadGroup` 创建的 `WorkloadEntry` 的“工作负载名称”（如遥测中所报告的）。

- **修复** 修复了当在 IPv6 集群上启用 Datadog 跟踪时，`$(HOST_IP)` 插值会导致 istio-proxy 失败。
  ([Issue #54267](https://github.com/istio/istio/issues/54267))

- **修复** 修复了访问日志顺序不稳定导致连接耗尽的问题。
  ([Issue #54672](https://github.com/istio/istio/issues/54672))

- **修复** 修复了如果 Prometheus 的抓取间隔配置大于 `15s`，
  Grafana 仪表板中的许多面板会显示**无数据**的问题。
  （[背景信息](https://grafana.com/blog/2020/09/28/new-in-grafana-7.2-__rate_interval-for-prometheus-rate-queries-that-just-work/)和[使用](/zh/docs/tasks/observability/metrics/using-istio-dashboard/)）

- **移除** 删除了对 OpenCensus 的支持。

## 安装 {#installation}

- **改进** 改进了 `platform` 和 `profile` Helm 值覆盖现在等效地支持全局或本地覆盖形式，例如
    - `--set global.platform=foo`
    - `--set global.profile=bar`
    - `--set platform=foo`
    - `--set profile=bar`

- **改进** 改进了 ztunnel Helm Chart，将资源名称设置为 `.Release.Name`，而不是硬编码为 ztunnel。

- **新增** 向 `WaypointBound` 条件添加了新消息，以表示服务绑定到入口的 waypoint 代理。

- **新增** 添加了 ‘istioctl install’ 在 Windows 上不起作用的问题。

- **新增** 当 `istio-cni` 以 `hostNetwork=true` 运行时（即 Ambient 模式），
  向 `istio-cni` 添加 `dnsPolicy` 为 `ClusterFirstWithHostNet` 的 Pod。

- **新增** 添加了用于 Ambient 模式的 GKE 平台配置文件。
  在 GKE 上安装时，使用 `--set global.platform=gke`（Helm）或 `--set values.global.platform=gke`（istioctl）来应用特定于 GKE 的值进行覆盖。
  这取代了之前基于 `istio-cni` Chart 中使用的 K8S 版本的 GKE 自动检测。

- **新增** 添加了对 Envoy 配置参数的支持以跳过弃用的日志，默认设置为 true。
  将 `ENVOY_SKIP_DEPRECATED_LOGS` 环境变量设置为 false 将启用弃用的日志。

- **新增** 默认情况下，向 Istio 发布的网关添加 Ambient 数据平面排除标签，
  以避免在 `istio-system` 之外安装网关时出现开箱即用的混乱行为。
  ([Issue #54824](https://github.com/istio/istio/issues/54824))

- **修复** 修复了在某些基于 Docker 的 Kubernetes 节点上创建 `ipset` 条目失败的问题。
  ([Issue #53512](https://github.com/istio/istio/issues/53512))

- **修复** 修复了 Helm 渲染以正确在 Pilot `serviceAccount` 上应用注解的问题。
  ([Issue #51289](https://github.com/istio/istio/issues/51289))

- **修复** 修复了当启用 `istio-cni` 时 `includeInboundPorts: ""` 不起作用的问题。
  ([Issue #54288](https://github.com/istio/istio/issues/54288))

- **修复** 修复了在二进制复制过程中反复终止容器时，
  CNI 安装在二进制复制过程中留下临时文件的问题，这些临时文件可能会填满存储空间。
  ([Issue #54311](https://github.com/istio/istio/issues/54311))

- **修复** 修复了网关 Chart 中 `--set platform` 有效但 `--set global.platform` 无效的问题。

- **修复** 修复了 `gateway` 注入模板不尊重 `kubectl.kubernetes.io/default-logs-container`
  和 `kubectl.kubernetes.io/default-container` 注解的问题。

- **修复** 修复了当系统中存在非内置表时导致 `istio-iptables` 命令失败的问题。

- **修复** 修复了阻止 `PodDisruptionBudget` `maxUnavailable` 字段可定制的问题。
  ([Issue #54087](https://github.com/istio/istio/issues/54087))

- **修复** 修复了当 Sidecar 注入器无法处理 Sidecar 配置时，
  注入配置错误被忽略（即记录但未返回）的问题。此更改现在会将错误传播给用户，而不是继续处理错误的配置。
  ([Issue #53357](https://github.com/istio/istio/issues/53357))

## istioctl

- **改进** 改进了 `istioctl proxy-config secret` 的输出以显示 Spire 提供的信任包。

- **新增** 在 `istioctl analyze` 中为 `--revision` 标志添加别名 `-r`。

- **新增** 在 `istioct x authz check` 命令中添加对具有 `CUSTOM` 操作的 `AuthorizationPolicies` 支持。

- **新增** 添加了对 `istioctl experiments load group create` 命令的 `--network` 参数的支持。
  ([Issue #54022](https://github.com/istio/istio/issues/54022))

- **新增** 添加了安全地就地重启/升级 `system-node-critical` `istio-cni` 节点代理 `DaemonSet` 的功能。
  此功能通过防止在 `istio-cni` 重启或升级时在节点上启动新 Pod 来实现。
  此功能默认启用，可通过在 `istio-cni` 中设置环境变量 `AMBIENT_DISABLE_SAFE_UPGRADE=true` 来禁用。
  ([Issue #49009](https://github.com/istio/istio/issues/49009))

- **新增** 添加了 `rootca-compare` 命令的变更，以处理 Pod 具有多个根 CA 的情况。
  ([Issue #54545](https://github.com/istio/istio/issues/54545))

- **新增** 添加了对 `istioctl waypoint delete` 的支持，以删除指定的修订 waypoint。

- **新增** 添加了对分析器的支持，以报告选定的 Istio 和 Kubernetes Gateway API 资源的负面状态情况。
  ([Issue #55055](https://github.com/istio/istio/issues/55055))

- **改进** 改进了 `istioctl proxy-config secret` 和 `istioctl proxy-config` 的性能。
  ([Issue #53931](https://github.com/istio/istio/issues/53931))

- **修复** 修复了 `rootca-compare` 命令中的问题，以处理 Pod 具有多个根 CA 的情况。
  ([Issue #54545](https://github.com/istio/istio/issues/54545))

- **修复** 修复了如果在 `IstioOperator` 文件中指定了多个入口网关，则 `istioctl install` 会死锁的问题。
  ([Issue #53875](https://github.com/istio/istio/issues/53875))

- **修复** 修复了 `istioctl waypoint delete --all` 会删除所有网关资源（甚至非 waypoint）的问题。
  ([Issue #54056](https://github.com/istio/istio/issues/54056))

- **修复** 修复了 `istioctl experiments injection engine list` 命令不打印注入器 webhook 的冗余命名空间。

- **修复** 当使用具有不同端口和多个网关的同一主机时，`istioctl analyze` 报告 `IST0145` 错误。
  ([Issue #54643](https://github.com/istio/istio/issues/54643))

- **修复** 修复了当使用 `--as` 而不使用 `--as-group` 时，`istioctl --as` 会隐式设置 `--as-group=""` 的问题。

- **移除** 删除了 `--recursive` 标志并将 `istioctl analyze` 的递归设置为 true。

- **移除** 从 `istioctl proxy-status` 命令中删除了实验标志 `--xds-via-agents`。
