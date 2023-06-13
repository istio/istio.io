---
title: Istio 1.18.0 更新说明
linktitle: 1.18.0
subtitle: 次要版本
description: Istio 1.18.0 更新说明。
publishdate: 2023-06-07
release: 1.18.0
weight: 20
---

## 弃用通知 {#deprecation-notices}

以下通知说明了根据 [Istio 的弃用政策](/zh/docs/releases/feature-stages/#feature-phase-definitions)将在未来某个版本中移除的功能。
请考虑升级您的环境以移除弃用的功能。

- Istio 1.18.0 版中没有新的弃用内容

## 流量治理 {#traffic-management}

- **Improved** [Gateway API Automated Deployment](/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment) management logic. See Upgrade Notes for more information.
- **改进** 改进了 [Gateway API 自动部署](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)管理逻辑。
  更多信息请参考升级说明。

- **Updated** the VirtualService validation to fail on empty prefix header matcher. ([Issue #44424](https://github.com/istio/istio/issues/44424))
- **更新** 更新了 VirtualService 在空前缀头匹配器中验证失败的问题。
  ([Issue #44424](https://github.com/istio/istio/issues/44424))

- **Updated** `ProxyConfig` resources with workload selector will be applied to Kubernetes `Gateway` pods only if the specified label is `istio.io/gateway-name`. Other labels are ignored.
- **更新** 更新了仅当指定标签为 `istio.io/gateway-name` 时，
  带有工作负载选择器的 `ProxyConfig` 资源才会应用于 Kubernetes
  `Gateway` Pod。其他标签将被忽略。

- **Added** provision to provide overridden/explicit value for `failoverPriority` label. This provided value is used while assigning priority for endpoints instead of the client's value.
  ([Issue #39111](https://github.com/istio/istio/issues/39111))
- **新增** 为 `failoverPriority` 标签新增了覆盖/显式值的规定。
  该值用于在为端点分配优先级时替代客户端设置的值。
  ([Issue #39111](https://github.com/istio/istio/issues/39111))

- **Added** prefix matching on query parameter. ([Issue #43710](https://github.com/istio/istio/issues/43710))
- **新增** 为查询参数新增了前缀匹配。
  ([Issue #43710](https://github.com/istio/istio/issues/43710))

- **Added** health checks for those VMs that are not using auto-registration.
  ([Issue #44712](https://github.com/istio/istio/issues/44712))
- **新增** 为那些未使用自动注册的虚拟机新增了健康检查功能。
  ([Issue #44712](https://github.com/istio/istio/issues/44712))

- **Fixed** admission webhook fails with custom header value format.
  ([Issue #42749](https://github.com/istio/istio/issues/42749))
- **修复** 修复了 Admission Webhook 因自定义头信息的值格式而失败的问题。
  ([Issue #42749](https://github.com/istio/istio/issues/42749))

- **Fixed** fixed bug of Istio cannot be deployed on IPv6-first DS clusters for Dual Stack support in Istio.
 ([Optimized Design]( https://docs.google.com/document/d/15LP2XHpQ71ODkjCVItGacPgzcn19fsVhyE7ruMGXDyU/))([Original Design]( https://docs.google.com/document/d/1oT6pmRhOw7AtsldU0-HbfA0zA26j9LYiBD_eepeErsQ/)) ([Issue #40394](https://github.com/istio/istio/issues/40394))([Issue #41462](https://github.com/istio/istio/issues/41462))
- **修复** 修复了 Istio 无法部署在 IPv6 优先的 DS 集群上的双堆栈支持问题。
  ([优化设计](https://docs.google.com/document/d/15LP2XHpQ71ODkjCVItGacPgzcn19fsVhyE7ruMGXDyU/))
  ([原始设计](https://docs.google.com/document/d/1oT6pmRhOw7AtsldU0-HbfA0zA26j9LYiBD_eepeErsQ/))
  ([Issue #40394](https://github.com/istio/istio/issues/40394))
  ([Issue #41462](https://github.com/istio/istio/issues/41462))

- **Fixed** an issue where `EnvoyFilter` for `Cluster.ConnectTimeout` was affecting unrelated `Clusters`.
  ([Issue #43435](https://github.com/istio/istio/issues/43435))
- **修复** 修复了 `Cluster.ConnectTimeout` 的 `EnvoyFilter` 影响不相关 `Clusters` 的问题。
  ([Issue #43435](https://github.com/istio/istio/issues/43435))

- **Fixed** reporting Programmed condition on Gateway API Gateway resources.
  ([Issue #43498](https://github.com/istio/istio/issues/43498))
- **修复** 修复了 Gateway API 中 Gateway 资源的 Programmed 条件上报问题。
  ([Issue #43498](https://github.com/istio/istio/issues/43498))

- **Fixed** an issue that when there are different Binds specified in the Gateways with the same port and different protocols, listeners are not generated correctly.
  ([Issue #43688](https://github.com/istio/istio/issues/43688))
- **修复** 修复了当在具有相同端口和不同协议的网关中指定不同的绑定时，无法正确生成侦听器的问题。
  ([Issue #43688](https://github.com/istio/istio/issues/43688))

- **Fixed** an issue that when there are different Binds specified in the Gateways with the same port and TCP protocol, listeners are not generated correctly.
  ([Issue #43775](https://github.com/istio/istio/issues/43775))
- **修复** 修复了当在具有相同端口和 TCP 协议的网关中指定不同的绑定时，无法正确生成侦听器的问题。
  ([Issue #43775](https://github.com/istio/istio/issues/43775))

- **Fixed** an issue with service entry deletion not deleting the corresponding endpoints in some cases.
  ([Issue #43853](https://github.com/istio/istio/issues/43853))
- **修复** 修复了在某些情况下删除服务入口时不会删除相应端点的问题。
  ([Issue #43853](https://github.com/istio/istio/issues/43853))

- **Fixed** an issue where auto allocated service entry IPs change on host reuse.
  ([Issue #43858](https://github.com/istio/istio/issues/43858))
- **修复** 修复了自动分配的服务入口 IP 在主机重用时发生变化的问题。
  ([Issue #43858](https://github.com/istio/istio/issues/43858))

- **Fixed** `WorkloadEntry` resources never being cleaned up if multiple `WorkloadEntries` were auto-registered with the same IP and network.
  ([Issue #43950](https://github.com/istio/istio/issues/43950))
- **修复** 修复了如果多个 `WorkloadEntry` 自动注册到相同的 IP 和网络时，
  则 `WorkloadEntry` 资源永远不会被清理的问题。
  ([Issue #43950](https://github.com/istio/istio/issues/43950))

- **Fixed** the `dns_upstream_failures_total` metric was mistakenly deleted in the previous release.
  ([Issue #44151](https://github.com/istio/istio/issues/44151))
- **修复** 修复了 `dns_upstream_failures_total` 指标在之前的版本中被误删的问题。
  ([Issue #44151](https://github.com/istio/istio/issues/44151))

- **Fixed** an issue where ServiceEntry and Service had undefined or empty workload selectors. If the workload selector is undefined or empty, ServiceEntry and Service should not select any `WorkloadEntry` or endpoint.
- **修复** 修复了 ServiceEntry 和 Service 具有未定义或空的工作负载选择器的问题。
  如果工作负载选择器未定义或为空，则 ServiceEntry 和服务不应该选择任何 `WorkloadEntry` 或端点。

- **Fixed** An issue where a Service Entry configured with partial wildcard hosts generates a warning during validation as the config can some times generate invalid server name match. ([Issue #44195](https://github.com/istio/istio/issues/44195))
- **修复** 修复了使用部分通配符主机配置的 Service Entry 在验证期间生成警告的问题，
  因为配置有时会生成无效的服务器名称匹配。
  ([Issue #44195](https://github.com/istio/istio/issues/44195))

- **Fixed** an issue where `Istio Gateway` (Envoy) would crash due to a duplicate `istio_authn` network filter in the Envoy filter chain.
  ([Issue #44385](https://github.com/istio/istio/issues/44385))
- **修复** 修复了由于过滤器链中的 `istio_authn` 网络过滤器导致
  `Istio Gateway`（Envoy）崩溃的问题。
  ([Issue #44385](https://github.com/istio/istio/issues/44385))

- **Fixed** a bug where services are missing in gateways if `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` is enabled.  ([Issue #44439](https://github.com/istio/istio/issues/44439))
- **修复** 修复了当启用 `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` 时，网关中服务缺失的错误。
  ([Issue #44439](https://github.com/istio/istio/issues/44439))

- **Fixed** CPU usage abnormally high when cert specified by DestinationRule are invalid.
  ([Issue #44986](https://github.com/istio/istio/issues/44986))
- **修复** 修复了当 DestinationRule 指定的证书无效时 CPU 使用率异常高的问题。
  ([Issue #44986](https://github.com/istio/istio/issues/44986))

- **Fixed** an issue where changing a label on a workload instance with a previously matched `ServiceEntry` would not properly get removed.
  ([Issue #42921](https://github.com/istio/istio/issues/42921))
- **修复** 修复了无法正确删除使用先前匹配的 `ServiceEntry` 更改工作负载实例中标签的问题。
  ([Issue #42921](https://github.com/istio/istio/issues/42921))

- **Fixed** istiod not reconciling k8s gateway deployments and services when they are changed.
  ([Issue #43332](https://github.com/istio/istio/issues/43332))
- **修复** 修复了当 istiod 被修改时不调谐 k8s 网关 Deployment 和 Service 的问题。
  ([Issue #43332](https://github.com/istio/istio/issues/43332))

- **Fixed** an issue where istiod does not retry resolving east-west gateway hostnames on failure.
  ([Issue #44155](https://github.com/istio/istio/issues/44155))
- **修复** 修复了当 istiod 失败时不重试解析东西向网关主机名的问题。
  ([Issue #44155](https://github.com/istio/istio/issues/44155))

- **Fixed** an issue where istiod generates incorrect endpoints when it fails to resolve east-west gateway hostnames.
  ([Issue #44155](https://github.com/istio/istio/issues/44155))
- **修复** 修复了当 istiod 无法解析东西向网关主机名时生成不正确端点的问题。
  ([Issue #44155](https://github.com/istio/istio/issues/44155))

- **Fixed** an issue where sidecars do not proxy DNS properly for a hostname backed by multiple services.
  ([Issue #43152](https://github.com/istio/istio/pull/43152))
- **修复** 修复了 Sidecar 无法正确代理 DNS 以获取由多个服务支持的主机名的问题。
  ([Issue #43152](https://github.com/istio/istio/pull/43152))

- **Fixed** an issue where updating Service ExternalName does not take effect.
  ([Issue #43440](https://github.com/istio/istio/issues/43440))
- **修复** 修复了更新 Service ExternalName 不生效的问题。
  ([Issue #43440](https://github.com/istio/istio/issues/43440))

- **Fixed** an issue causing VMs using auto-registration to ignore labels other than those defined in a `WorkloadGroup`.
  ([Issue #32210](https://github.com/istio/istio/issues/32210))
- **修复** 修复了导致使用自动注册的虚拟机忽略没有在 `WorkloadGroup` 中定义的标签的问题。
  ([Issue #32210](https://github.com/istio/istio/issues/32210))

- **Upgraded** the gateway-api integration to read `v1beta1` resources for `ReferenceGrant`, `Gateway`, and `GatewayClass`. Users of the gateway-api must be on `v0.6.0+` before upgrading Istio. `istioctl x precheck` can detect this issue before upgrading.
- **升级** 升级了 gateway-api 集成以读取 `ReferenceGrant`、`Gateway`
  和 `GatewayClass` 的 `v1beta1` 版本资源。用户在升级 Istio 之前，需要保证
  gateway-api 须高于 `v0.6.0+`。`istioctl x precheck` 可以在升级前检测到这个问题。

- **Removed** support for `proxy.istio.io/config` annotation applied to Kubernetes `Gateway` pods.
- **移除** 移除了对应用于 Kubernetes `Gateway` Pod 中 `proxy.istio.io/config` 注释的支持。

- **Removed** support for `Ingress` version `networking.k8s.io/v1beta1`. The `v1` version has been available since Kubernetes 1.19.
- **移除** 移除了对 `Ingress` `networking.k8s.io/v1beta1` 版本的支持。
  其 `v1` 版本从 Kubernetes 1.19 版开始可用。

- **Removed** `alpha` Gateway API types by default. They can be explicitly re-enabled with `PILOT_ENABLE_ALPHA_GATEWAY_API=true`.
- **移除** 默认移除了 Gateway API `alpha` 版类型。可以使用
  `PILOT_ENABLE_ALPHA_GATEWAY_API=true` 来显式的重新启用它们。

- **Removed** the experimental "taint controller" for Istio CNI.
- **移除** 为 Istio CNI 移除了实验性的“污点控制器”功能。

- **Removed** support for `EndpointSlice` version `discovery.k8s.io/v1beta1`. The `v1` version has been available since Kubernetes 1.21. `EndpointSlice` `v1` is automatically used on Kubernetes 1.21+, while `Endpoints` is used on older versions. This change only impacts users explicitly enabling `PILOT_USE_ENDPOINT_SLICE` on Kubernetes versions older than 1.21, which is no longer supported.
- **移除** 移除了对 `EndpointSlice` `discovery.k8s.io/v1beta1` 版本的支持。
  其 `v1` 版本从 Kubernetes 1.21 版开始可用。`EndpointSlice` `v1` 版本在
  Kubernetes 1.21+ 版上被自动使用，而 `Endpoints` 则只用于旧版本。
  此更改仅影响用户在 1.21 之前的 Kubernetes 版本上明确启用 `PILOT_USE_ENDPOINT_SLICE`
  设置，在这些版本中此设置不再被支持。

- **Removed** deprecated and unsupported status conditions `Ready`, `Scheduled`, and `Detached` from Gateway API.
- **移除** 从 Gateway API 中移除了已弃用和不受支持的 `Ready`、
  `Scheduled` 和 `Detached` 状态。

## 安全性 {#security}

- **Added** `--profiling` flag to allow enabling or disabling profiling on pilot-agent status port.
  ([Issue #41457](https://github.com/istio/istio/issues/41457))
- **新增** 新增了 `--profiling` 标志以允许在 pilot-agent 状态端口上启用或禁用分析能力。
  ([Issue #41457](https://github.com/istio/istio/issues/41457))

- **Added** support for pushing additional federated trust domains from `caCertificates` to the peer SAN validator.
  ([Issue #41666](https://github.com/istio/istio/issues/41666))
- **新增** 新增了对将额外的联邦信任域从 `caCertificates` 推送到对等 SAN 验证器的支持。
  ([Issue #41666](https://github.com/istio/istio/issues/41666))

- **Added** support for using P384 curves when using ECDSA ([PR #44459](https://github.com/istio/istio/pull/44459))
- **新增** 新增了使用 ECDSA 中 P384 曲线的支持
  ([PR #44459](https://github.com/istio/istio/pull/44459))

- **Added** `ecdh_curves` support for non `ISTIO_MUTUAL` traffic through MeshConfig API.
  ([Issue #41645](https://github.com/istio/istio/issues/41645))
- **新增** 新增了在 `ecdh_curves` 通过 MeshConfig API 对非 `ISTIO_MUTUAL` 流量的支持。
  ([Issue #41645](https://github.com/istio/istio/issues/41645))

- **Enabled** the `AUTO_RELOAD_PLUGIN_CERTS` env var by default for istiod to notice `cacerts` file changes in common cases (e.g. reload intermediate certs).
  ([Issue #43104](https://github.com/istio/istio/issues/43104))
- **启用** 默认启用了 `AUTO_RELOAD_PLUGIN_CERTS` 环境变量使 istiod
  注意到常见情况下的 `cacerts` 文件更改（例如重新加载中间证书）。
  ([Issue #43104](https://github.com/istio/istio/issues/43104))

- **Fixed** ignoring default CA certificate when `PeerCertificateVerifier` is created.
- **固定**在创建“PeerCertificateVerifier”时忽略默认 CA 证书。

- **Fixed** issue with metadata handling for Azure platform. Support added for `tagsList` serialization of tags on instance metadata.
  ([Issue #31176](https://github.com/istio/istio/issues/31176))
- **修复** Azure 平台的元数据处理问题。 添加了对实例元数据上标签的“tagsList”序列化的支持。
  ([Issue #31176](https://github.com/istio/istio/issues/31176))

- **Fixed** an issue where RBAC updates were not sent to older proxies after upgrading istiod to 1.17.
  ([Issue #43785](https://github.com/istio/istio/issues/43785))
- **修复** 将 istiod 升级到 1.17 后 RBAC 更新未发送到旧代理的问题。
  ([Issue #43785](https://github.com/istio/istio/issues/43785))

- **Fixed** handling of remote SPIFFE trust bundles containing multiple certs.
  ([Issue #44831](https://github.com/istio/istio/issues/44831))
- **固定**处理包含多个证书的远程 SPIFFE 信任包。
  ([Issue #44831](https://github.com/istio/istio/issues/44831))

- **Removed** support for the `certificates` field in `MeshConfig`. This was deprecated in 1.15, and does not work on Kubernetes 1.22+.
  ([Issue #36231](https://github.com/istio/istio/issues/36231))
- **删除**对“MeshConfig”中的“证书”字段的支持。 这在 1.15 中已弃用，并且不适用于 Kubernetes 1.22+。
  ([Issue #36231](https://github.com/istio/istio/issues/36231))

## 遥测 {#telemetry}

- **Added** support to control trace id length on Zipkin tracing provider.
  ([Issue #43359](https://github.com/istio/istio/issues/43359))
- **添加**支持以控制 Zipkin 跟踪提供程序上的跟踪 ID 长度。
  ([Issue #43359](https://github.com/istio/istio/issues/43359))

- **Added** support for `METADATA` command operator in access log.
  ([Issue #44074](https://github.com/istio/istio/issues/44074))
- **在访问日志中添加了对“METADATA”命令运算符的支持。
  ([Issue #44074](https://github.com/istio/istio/issues/44074))

- **Added** metric expiry support, when env flags `METRIC_ROTATION_INTERVAL` and `METRIC_GRACEFUL_DELETION_INTERVAL` are enabled.
- **添加**指标过期支持，当环境标志“METRIC_ROTATION_INTERVAL”和“METRIC_GRACEFUL_DELETION_INTERVAL”启用时。

- **Fixed** an issue where you could not disable tracing in `ProxyConfig`.
  ([Issue #31809](https://github.com/istio/istio/issues/31809))
- **修复**无法在 `ProxyConfig` 中禁用跟踪的问题。
  ([Issue #31809](https://github.com/istio/istio/issues/31809))

- **Fixed**  an issue where `ALL_METRICS` does not disable metrics as expected. ([PR #43179](https://github.com/istio/istio/pull/43179))
- **修复** `ALL_METRICS` 未按预期禁用指标的问题。
  ([PR #43179](https://github.com/istio/istio/pull/43179))

- **Fixed** a bug that would cause unexpected behavior when applying access logging configuration based on the direction of traffic. With this fix, access logging configuration for `CLIENT` or `SERVER` will not affect each other.
- **修复** 在根据流量方向应用访问日志记录配置时会导致意外行为的错误。 通过此修复，“CLIENT”或“SERVER”的访问日志记录配置将不会相互影响。

- **Fixed** pilot has an additional invalid gateway metric that was not created by the user.
- **修复** 修复了 Pilot 有一个额外的无效网关指标的问题，该指标并不是由用户创建。

- **Fixed** an issue where grpc stats are absent.
  ([Issue #43908](https://github.com/istio/istio/issues/43908)),([Issue #44144](https://github.com/istio/istio/issues/44144))
- **修复** 修复了 grpc 统计信息缺失的问题。
  ([Issue #43908](https://github.com/istio/istio/issues/43908))
  ([Issue #44144](https://github.com/istio/istio/issues/44144))

## 安装 {#installation}

- **Improved** `istioctl operator remove` command to run without the confirmation in the dry-run mode. ([PR #43120](https://github.com/istio/istio/pull/43120))
- **改进** 改进了 `istioctl operator remove` 命令在试运行模式下无需确认即可运行的问题。
  ([PR #43120](https://github.com/istio/istio/pull/43120))

- **Improved** the `downloadIstioCtl.sh` script to not change to the home directory at the end. ([Issue #43771](https://github.com/istio/istio/issues/43771))
- **改进** 改进了 `downloadIstioCtl.sh` 脚本在结束时不回到主目录的问题。
  ([Issue #43771](https://github.com/istio/istio/issues/43771))

- **Improved** the default telemetry installation to configure `meshConfig.defaultProviders` instead of custom `EnvoyFilter`s when advanced customizations are not used, improving performance.
- **改进** 改进了默认遥测安装以在不使用高级自定义时配置 `meshConfig.defaultProviders` 
  而不是自定义 `EnvoyFilter`，从而提高性能。

- **Updated** the proxies `concurrency` configuration to always be detected based on CPU limits, unless explicitly configured. See upgrade notes for more info. ([PR #43865](https://github.com/istio/istio/pull/43865))
- **更新**代理“并发”配置始终根据 CPU 限制进行检测，除非明确配置。 有关详细信息，请参阅升级说明。
  ([PR #43865](https://github.com/istio/istio/pull/43865))

- **Updated** `Kiali` addon to version `v1.67.0`. ([PR #44498](https://github.com/istio/istio/pull/44498))
- **更新** `Kiali` 插件到版本 `v1.67.0`。
  ([PR #44498](https://github.com/istio/istio/pull/44498))

- **Added** env variables to support modifying grpc keepalive values.
  ([Issue #43256](https://github.com/istio/istio/issues/43256))
- **添加**环境变量以支持修改 grpc keepalive 值。
  ([Issue #43256](https://github.com/istio/istio/issues/43256))

- **Added** support for scraping metrics in dual stack clusters.
  ([Issue #35915](https://github.com/istio/istio/issues/35915))
- **添加**支持在双堆栈集群中抓取指标。
  ([Issue #35915](https://github.com/istio/istio/issues/35915))

- **Added** make inbound port configurable.
  ([Issue #43655](https://github.com/istio/istio/issues/43655))
- **添加**使入站端口可配置。
  ([Issue #43655](https://github.com/istio/istio/issues/43655))

- **Added** injection of `istio.io/rev` annotation to sidecars and gateways for multi-revision observability.
- **添加** 将 `istio.io/rev` 注释注入 sidecars 和网关以实现多版本可观察性。

- **Added** an automatically set GOMEMLIMIT to `istiod` to reduce the risk of out-of-memory issues.
  ([Issue #40676](https://github.com/istio/istio/issues/40676))
- **添加** 自动将 GOMEMLIMIT 设置为 istiod 以降低内存不足问题的风险。
  ([Issue #40676](https://github.com/istio/istio/issues/40676))

- **Added** support for labels to be added to the Gateway pod template via `.Values.labels`.
  ([Issue #41057](https://github.com/istio/istio/issues/41057)),([Issue #43585](https://github.com/istio/istio/issues/43585))
- **添加**支持通过“.Values.labels”将标签添加到网关 pod 模板。
  ([Issue #41057](https://github.com/istio/istio/issues/41057))
  ([Issue #43585](https://github.com/istio/istio/issues/43585))

- **Added** check to limit the `clusterrole` for k8s CSR permissions for external CA `usecases` by verifying `.Values.pilot.env.EXTERNAL_CA` and `.Values.global.pilotCertProvider` parameters.
- **添加**检查以通过验证 `.Values.pilot.env.EXTERNAL_CA` 和 `.Values.global.pilotCertProvider` 参数来限制外部 CA `usecases` 的 k8s CSR 权限的 `clusterrole`。

- **Added** configurable node affinity to istio-cni `values.yaml`. Can be used to allow excluding istio-cni from being scheduled on specific nodes.
- **添加**可配置的节点亲和力到 istio-cni `values.yaml`。 可用于允许将 istio-cni 排除在特定节点上的调度之外。

- **Fixed** SELinux issue on `CentOS9`/RHEL9 where iptables-restore isn't allowed to open files in `/tmp`. Rules passed to iptables-restore are no longer written to a file, but are passed via `stdin`.
  ([Issue #42485](https://github.com/istio/istio/issues/42485))
- **修复** `CentOS9`/RHEL9 上的 SELinux 问题，其中不允许 iptables-restore 打开 `/tmp` 中的文件。 传递给 iptables-restore 的规则不再写入文件，而是通过“stdin”传递。
  ([Issue #42485](https://github.com/istio/istio/issues/42485))

- **Fixed** an issue where webhook configuration was being modified in dry-run mode when installing Istio with istioctl. ([PR #44345](https://github.com/istio/istio/pull/44345))
- **修复** 使用 istioctl 安装 Istio 时，webhook 配置在空运行模式下被修改的问题。
  ([PR #44345](https://github.com/istio/istio/pull/44345))

- **Removed** injecting label `istio.io/rev` to gateways to avoid creating pods indefinitely when `istio.io/rev=<tag>`.
  ([Issue #33237](https://github.com/istio/istio/issues/33237))
- **删除** 将标签 `istio.io/rev` 注入网关以避免在 `istio.io/rev=<tag>` 时无限期地创建 pod。
  ([Issue #33237](https://github.com/istio/istio/issues/33237))

- **Removed** operator skip reconcile for `iop` resources with names starting with `installed-state`. It now relies solely on the annotation `install.istio.io/ignoreReconcile`. This won't affect the behavior of `istioctl install`.
  ([Issue #29394](https://github.com/istio/istio/issues/29394))
- **删除**运算符跳过名称以“已安装状态”开头的“iop”资源的协调。 它现在完全依赖于注释 `install.istio.io/ignoreReconcile`。 这不会影响 istioctl install 的行为。
  ([Issue #29394](https://github.com/istio/istio/issues/29394))

- **Removed** `kustomization.yaml` and `pre-generated` installation manifests (`gen-istio.yaml`, etc) from published releases. These previously installed unsupported testing images, which led to accidental usage by users and tools such as Argo CD.
- **从已发布的版本中删除**`kustomization.yaml` 和`pre-generated` 安装清单（`gen-istio.yaml` 等）。这些先前安装的不受支持的测试图像，导致用户和 Argo CD 等工具的意外使用。

## istioctl

- **Improved** the `istioctl pc secret` output to display the certificate serial number in HEX. ([Issue #43765](https://github.com/istio/istio/issues/43765))
- **改进** `istioctl pc secret` 输出以十六进制显示证书序列号。
  ([Issue #43765](https://github.com/istio/istio/issues/43765))

- **Improved** the `istioctl analyze` to output mismatched proxy image messages as IST0158 on namespace level instead of IST0105 on pod level, which is more succinct.
- **改进** `istioctl analyze` 将不匹配的代理图像消息输出为命名空间级别的 IST0158 而不是 Pod 级别的 IST0105，这样更简洁。

- **Added** `istioctl analyze` will display a error when encountering two additional erroneous Telemetry scenarios.
  ([Issue #43705](https://github.com/istio/istio/issues/43705))
- **添加** `istioctl analyze` 将在遇到另外两个错误的遥测场景时显示错误。
  ([Issue #43705](https://github.com/istio/istio/issues/43705))

- **Added** `--output-dir` flag to specify the output directory for the `bug-report` command's generated archive file.
  ([Issue #43842](https://github.com/istio/istio/issues/43842))
- **添加** `--output-dir` 标志以指定 `bug-report` 命令生成的存档文件的输出目录。
  ([Issue #43842](https://github.com/istio/istio/issues/43842))

- **Added** credential validation when using `istioctl analyze` to validate the secrets specified with `credentialName` in Gateway resources.
  ([Issue #43891](https://github.com/istio/istio/issues/43891))
- 在使用 istioctl analyze 验证网关资源中使用 `credentialName` 指定的秘密时**添加**凭证验证。
  ([Issue #43891](https://github.com/istio/istio/issues/43891))

- **Added** an analyzer for showing warning messages when the deprecated `lightstep` provider is still being used.
  ([Issue #40027](https://github.com/istio/istio/issues/40027))
- **添加**一个分析器，用于在仍在使用已弃用的 `lightstep` 提供程序时显示警告消息。
  ([Issue #40027](https://github.com/istio/istio/issues/40027))

- **Added** istiod metrics to `bug-report`, and a few more debug points like `telemetryz`.
  ([Issue #44062](https://github.com/istio/istio/issues/44062))
- **向 `bug-report` 添加了 ** istio 指标，还有一些调试点，如 `telemetry`。
  ([Issue #44062](https://github.com/istio/istio/issues/44062))

- **Added** a "VHOST NAME" column to the output of `istioctl pc route`.
  ([Issue #44413](https://github.com/istio/istio/issues/44413))
- **在 istioctl pc route 的输出中添加了一个“VHOST NAME”列。
  ([Issue #44413](https://github.com/istio/istio/issues/44413))

- **Added** local flags `--ui-port` for different `istioctl dashboard` commands to allow users to specify the component UI port to use for the dashboard.
- **为不同的 `istioctl dashboard` 命令添加了 ** 本地标志 `--ui-port` 以允许用户指定用于仪表板的组件 UI 端口。

- **Fixed** Server Side Apply is enabled by default for Kubernetes cluster versions above 1.22 or be detected if it can be run in Kubernetes versions 1.18-1.21.
- **已修复**服务器端应用默认为 1.22 以上的 Kubernetes 集群版本启用，或者如果它可以在 Kubernetes 1.18-1.21 版本中运行则被检测到。

- **Fixed** `istioctl install --set <boolvar>=<bool>` and `istioctl manifests generate --set <boolvar>=<bool>` improperly converting a boolean into a string. ([Issue #43355](https://github.com/istio/istio/issues/43355))
- **固定** `istioctl install --set <boolvar>=<bool>` 和 `istioctl manifests generate --set <boolvar>=<bool>` 不正确地将布尔值转换为字符串。
  ([Issue #43355](https://github.com/istio/istio/issues/43355))

- **Fixed** `istioctl experimental describe` not showing all weighted routes when the VirtualService is defined to split traffic across multiple services.
  ([Issue #43368](https://github.com/istio/istio/issues/43368))
- **固定** `istioctl experimental describe` 在 VirtualService 被定义为跨多个服务拆分流量时不显示所有加权路由。
  ([Issue #43368](https://github.com/istio/istio/issues/43368))

- **Fixed** `istioctl x precheck` displays unwanted IST0136 messages which are set by Istio as default.
  ([Issue #36860](https://github.com/istio/istio/issues/36860))
- **固定** `istioctl x precheck` 显示不需要的 IST0136 消息，这些消息由 Istio 设置为默认消息。
  ([Issue #36860](https://github.com/istio/istio/issues/36860))

- **Fixed** a bug in `istioctl analyze` where some messages are missed when there are services with no selector in the analyzed namespace.
- **修复** `istioctl analyze` 中的错误，当分析的命名空间中存在没有选择器的服务时，会丢失一些消息。

- **Fixed** resource namespace resolution for `istioctl` commands.
- **固定** `istioctl` 命令的资源命名空间解析。

- **Fixed** an issue where specifying the directory for temporary artifacts with `--dir` when using `istioctl bug-report` did not work.
  ([Issue #43835](https://github.com/istio/istio/issues/43835))
- **修复** 在使用 istioctl bug-report 时使用 `--dir` 指定临时工件目录不起作用的问题。
  ([Issue #43835](https://github.com/istio/istio/issues/43835))

- **Fixed** `istioctl experimental revision describe` warning gateway is not enabled when gateway exists.
  ([Issue #44002](https://github.com/istio/istio/issues/44002))
- **已修复** `istioctl experimental revision describe` 网关存在时未启用警告网关。
  ([Issue #44002](https://github.com/istio/istio/issues/44002))

- **Fixed** `istioctl experimental revision describe` has incorrect number of egress gateways.
  ([Issue #44002](https://github.com/istio/istio/issues/44002))
- **已修复** `istioctl experimental revision describe` 的出口网关数量不正确。
  ([Issue #44002](https://github.com/istio/istio/issues/44002))

- **Fixed** inaccuracies in analysis results when analyzing configuration files with empty content.
- **修复**分析内容为空的配置文件时分析结果不准确的问题。

- **Fixed** `istioctl analyze` no longer expects pods and runtime resources when analyzing files.
  ([Issue #40861](https://github.com/istio/istio/issues/40861))
- **已修复** `istioctl analyze` 在分析文件时不再需要 pod 和运行时资源。
  ([Issue #40861](https://github.com/istio/istio/issues/40861))

- **Fixed** `istioctl analyze` to prevent panic when the server port in Gateway is nil.  ([Issue #44318](https://github.com/istio/istio/issues/44318))
- **固定** `istioctl analyze` 以防止当网关中的服务器端口为 nil 时出现恐慌。
  ([Issue #44318](https://github.com/istio/istio/issues/44318))

- **Fixed** the `istioctl experimental revision list` `REQD-COMPONENTS` column data being incomplete and general output format.
- **修复** `istioctl experimental revision list` `REQD-COMPONENTS` 列数据不完整和通用输出格式。

- **Fixed** `istioctl operator remove` cannot remove the operator controller due to a `no Deployment detected` error.
  ([Issue #43659](https://github.com/istio/istio/issues/43659))
- **已修复** `istioctl operator remove` 由于“未检测到部署”错误而无法删除操作员控制器。
  ([Issue #43659](https://github.com/istio/istio/issues/43659))

- **Fixed** `istioctl verify-install` fails when using multiple `iops`.
  ([Issue #42964](https://github.com/istio/istio/issues/42964))
- **固定** `istioctl verify-install` 在使用多个 `iops` 时失败。
  ([Issue #42964](https://github.com/istio/istio/issues/42964))

- **Fixed** `istioctl experimental  wait` has undecipherable message when `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING` is not enabled. ([PR #43023](https://github.com/istio/istio/pull/43023))
- **固定** `istioctl experimental wait` 在未启用 `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING` 时出现无法辨认的消息。
  ([PR #43023](https://github.com/istio/istio/pull/43023))
