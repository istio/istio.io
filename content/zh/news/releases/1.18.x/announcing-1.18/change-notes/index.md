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

- **改进** 改进了 [Gateway API 自动部署](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)的管理逻辑。
  更多信息请参考升级说明。

- **更新** 更新了 VirtualService 在空前缀头匹配器中验证失败的问题。
  ([Issue #44424](https://github.com/istio/istio/issues/44424))

- **更新** 更新了仅当指定标签为 `istio.io/gateway-name` 时，
  带有工作负载选择器的 `ProxyConfig` 资源才会应用于 Kubernetes
  `Gateway` Pod。其他标签将被忽略。

- **新增** 为 `failoverPriority` 标签新提供了覆盖/显式的值。
  当为端点分配优先级时将使用这个提供的值，而不是客户端的值。
  ([Issue #39111](https://github.com/istio/istio/issues/39111))

- **新增** 为查询参数新增前缀匹配能力。
  ([Issue #43710](https://github.com/istio/istio/issues/43710))

- **新增** 为那些未使用自动注册的虚拟机新增了健康检查功能。
  ([Issue #44712](https://github.com/istio/istio/issues/44712))

- **修复** 修复了 Admission Webhook 由于自定义头信息值格式而失败的问题。
  ([Issue #42749](https://github.com/istio/istio/issues/42749))

- **修复** 修复了 Istio 无法部署在 IPv6 优先的 DS 集群上的双堆栈支持问题。
  ([优化设计](https://docs.google.com/document/d/15LP2XHpQ71ODkjCVItGacPgzcn19fsVhyE7ruMGXDyU/))
  ([原始设计](https://docs.google.com/document/d/1oT6pmRhOw7AtsldU0-HbfA0zA26j9LYiBD_eepeErsQ/))
  ([Issue #40394](https://github.com/istio/istio/issues/40394))
  ([Issue #41462](https://github.com/istio/istio/issues/41462))

- **修复** 修复了 `Cluster.ConnectTimeout` 的 `EnvoyFilter` 会影响不相关 `Clusters` 的问题。
  ([Issue #43435](https://github.com/istio/istio/issues/43435))

- **修复** 修复了 Gateway API 中 Gateway 资源的 Programmed 条件上报问题。
  ([Issue #43498](https://github.com/istio/istio/issues/43498))

- **修复** 修复了当在具有相同端口和不同协议的网关中指定不同的绑定时，无法正确生成侦听器的问题。
  ([Issue #43688](https://github.com/istio/istio/issues/43688))

- **修复** 修复了当在具有相同端口和 TCP 协议的网关中指定不同的绑定时，无法正确生成侦听器的问题。
  ([Issue #43775](https://github.com/istio/istio/issues/43775))

- **修复** 修复了在某些情况下删除 ServiceEntry 时不会删除相应端点的问题。
  ([Issue #43853](https://github.com/istio/istio/issues/43853))

- **修复** 修复了自动分配的 ServiceEntry IP 在主机重用时会发生变化的问题。
  ([Issue #43858](https://github.com/istio/istio/issues/43858))

- **修复** 修复了如果多个 `WorkloadEntry` 自动注册到相同 IP 和网络时，
  则 `WorkloadEntry` 资源永远不会被清理的问题。
  ([Issue #43950](https://github.com/istio/istio/issues/43950))

- **修复** 修复了 `dns_upstream_failures_total` 指标在之前的版本中被误删的问题。
  ([Issue #44151](https://github.com/istio/istio/issues/44151))

- **修复** 修复了 ServiceEntry 和 Service 可以具有未定义或空工作负载选择器的问题。
  如果工作负载选择器未定义或为空，则 ServiceEntry 和 Service 不应该选择任何
  `WorkloadEntry` 或端点。

- **修复** 修复了使用部分匹配主机配置的 Service Entry 在验证期间生成警告的问题，
  因为配置有时会生成无效的服务器名称匹配。
  ([Issue #44195](https://github.com/istio/istio/issues/44195))

- **修复** 修复了由于过滤器链中的 `istio_authn` 网络过滤器导致
  `Istio Gateway`（Envoy）崩溃的问题。
  ([Issue #44385](https://github.com/istio/istio/issues/44385))

- **修复** 修复了当启用 `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG` 时，网关中 Service 缺失的错误。
  ([Issue #44439](https://github.com/istio/istio/issues/44439))

- **修复** 修复了当 DestinationRule 指定的证书无效时 CPU 使用率异常高的问题。
  ([Issue #44986](https://github.com/istio/istio/issues/44986))

- **修复** 修复了无法正确删除使用先前匹配的 `ServiceEntry` 更改工作负载实例中标签的问题。
  ([Issue #42921](https://github.com/istio/istio/issues/42921))

- **修复** 修复了当 istiod 被修改时不对 k8s 网关 Deployment 和 Service 进行调谐的问题。
  ([Issue #43332](https://github.com/istio/istio/issues/43332))

- **修复** 修复了当 istiod 失败时不会重试解析东西向网关主机名的问题。
  ([Issue #44155](https://github.com/istio/istio/issues/44155))

- **修复** 修复了当 istiod 无法解析东西向网关主机名时会生成不正确端点的问题。
  ([Issue #44155](https://github.com/istio/istio/issues/44155))

- **修复** 修复了 Sidecar 无法正确代理 DNS 以获取由多个服务支持的主机名的问题。
  ([Issue #43152](https://github.com/istio/istio/pull/43152))

- **修复** 修复了更新 Service ExternalName 不生效的问题。
  ([Issue #43440](https://github.com/istio/istio/issues/43440))

- **修复** 修复了使用自动注册的虚拟机时会忽略没有在 `WorkloadGroup` 中定义的标签的问题。
  ([Issue #32210](https://github.com/istio/istio/issues/32210))

- **升级** 升级了 gateway-api 集成以读取 `ReferenceGrant`、`Gateway`
  和 `GatewayClass` 的 `v1beta1` 版本资源。用户在升级 Istio 之前，需要保证
  gateway-api 须高于 `v0.6.0+` 版。`istioctl x precheck` 可以在升级前检测到这个问题。

- **移除** 移除了针对 Kubernetes `Gateway` Pod 中 `proxy.istio.io/config` 注解的支持。

- **移除** 移除了对 `Ingress` `networking.k8s.io/v1beta1` 版本的支持。
  其 `v1` 版本从 Kubernetes 1.19 版开始可用。

- **移除** 默认移除了 Gateway API `alpha` 版类型。可以使用
  `PILOT_ENABLE_ALPHA_GATEWAY_API=true` 来显式地重新启用这些类型。

- **移除** 为 Istio CNI 移除了实验性的“污点控制器”功能。

- **移除** 移除了对 `EndpointSlice` `discovery.k8s.io/v1beta1` 版本的支持。
  其 `v1` 版本从 Kubernetes 1.21 版开始可用。`EndpointSlice` `v1` 版本在
  Kubernetes 1.21+ 版上被自动使用，而 `Endpoints` 则只使用于旧版本。
  此更改仅影响在 1.21 之前的 Kubernetes 版本上明确启用 `PILOT_USE_ENDPOINT_SLICE`
  设置的用户，在这些版本中此设置不再被支持。

- **移除** 从 Gateway API 中移除了已弃用和不受支持的 `Ready`、
  `Scheduled` 和 `Detached` 状态。

## 安全性 {#security}

- **新增** 新增了 `--profiling` 标志以允许在 pilot-agent 状态端口上启用或禁用分析能力。
  ([Issue #41457](https://github.com/istio/istio/issues/41457))

- **新增** 新增了对将额外的联邦信任域从 `caCertificates` 推送到对等 SAN 验证器的支持。
  ([Issue #41666](https://github.com/istio/istio/issues/41666))

- **新增** 新增了在使用 ECDSA 时对 P384 曲线的支持。
  ([PR #44459](https://github.com/istio/istio/pull/44459))

- **新增** 新增了在 `ecdh_curves` 通过 MeshConfig API 对非 `ISTIO_MUTUAL` 流量的支持。
  ([Issue #41645](https://github.com/istio/istio/issues/41645))

- **启用** 默认启用了 `AUTO_RELOAD_PLUGIN_CERTS` 环境变量使 istiod
  觉察通常情况下的 `cacerts` 文件更改（例如重新加载中间证书）。
  ([Issue #43104](https://github.com/istio/istio/issues/43104))

- **修复** 修复了在创建 `PeerCertificateVerifier` 时会忽略默认 CA 证书的问题。

- **修复** 修复了 Azure 平台的元数据处理问题。
  添加了对实例元数据中标签 `tagsList` 序列化的支持。
  ([Issue #31176](https://github.com/istio/istio/issues/31176))

- **修复** 修复了将 istiod 升级到 1.17 后 RBAC 更新未发送到旧代理的问题。
  ([Issue #43785](https://github.com/istio/istio/issues/43785))

- **修复** 修复了处理包含多个证书的远程 SPIFFE 信任包的问题。
  ([Issue #44831](https://github.com/istio/istio/issues/44831))

- **移除** 移除了对 `MeshConfig` 中的 `certificates` 字段的支持。
  这是在 1.15 版中已弃用的内容，并且不适用于 Kubernetes 1.22 及以上版本。
  ([Issue #36231](https://github.com/istio/istio/issues/36231))

## 遥测 {#telemetry}

- **新增** 新增了对 Zipkin 链路追踪提供程序上的 Trace ID 长度控制支持。
  ([Issue #43359](https://github.com/istio/istio/issues/43359))

- **新增** 在访问日志中新增了对 `METADATA` 命令运算符的支持。
  ([Issue #44074](https://github.com/istio/istio/issues/44074))

- **新增** 新增了当环境标志 `METRIC_ROTATION_INTERVAL` 和
  `METRIC_GRACEFUL_DELETION_INTERVAL` 启用时对指标过期的支持。

- **修复** 修复了无法在 `ProxyConfig` 中禁用链路追踪的问题。
  ([Issue #31809](https://github.com/istio/istio/issues/31809))

- **修复** 修复了使用 `ALL_METRICS` 未按预期禁用指标的问题。
  ([PR #43179](https://github.com/istio/istio/pull/43179))

- **修复** 修复了在根据流量方向应用访问日志记录配置时会导致意外行为的错误。
  通过此修复，`CLIENT` 或 `SERVER` 的访问日志记录配置将不会相互影响。

- **修复** 修复了 Pilot 有一个额外的无效网关指标的问题，该指标并非由用户创建。

- **修复** 修复了 grpc 统计信息缺失的问题。
  ([Issue #43908](https://github.com/istio/istio/issues/43908))
  ([Issue #44144](https://github.com/istio/istio/issues/44144))

## 安装 {#installation}

- **改进** 改进了 `istioctl operator remove` 命令在 dry-run 模式下无需确认即可运行的问题。
  ([PR #43120](https://github.com/istio/istio/pull/43120))

- **改进** 改进了 `downloadIstioCtl.sh` 脚本在结束时不会回到主目录的问题。
  ([Issue #43771](https://github.com/istio/istio/issues/43771))

- **改进** 改进了当高级自定义未开启时，使用 `meshConfig.defaultProviders`
  替代自定义 `EnvoyFilter` 安装默认遥测的功能，从而提高性能。

- **更新** 更新了在没有其他明确配置的情况下，代理 `concurrency`
  配置始终根据 CPU 限制进行设置。有关详细信息，请参阅升级说明。
  ([PR #43865](https://github.com/istio/istio/pull/43865))

- **更新** 更新了 `Kiali` 插件到 `v1.67.0` 版。
  ([PR #44498](https://github.com/istio/istio/pull/44498))

- **新增** 新增了支持修改 grpc keepalive 值的环境变量。
  ([Issue #43256](https://github.com/istio/istio/issues/43256))

- **新增** 新增了支持在双堆栈集群中进行指标抓取的能力。
  ([Issue #35915](https://github.com/istio/istio/issues/35915))

- **新增** 新增了入站端口可配置能力。
  ([Issue #43655](https://github.com/istio/istio/issues/43655))

- **新增** 新增了可以将 `istio.io/rev` 注解注入到 Sidecar
  和网关以实现多版本可观察性的能力。

- **新增** 新增了可以自动将 GOMEMLIMIT 设置为 `istiod`，用于降低发生内存不足所带来的风险。
  ([Issue #40676](https://github.com/istio/istio/issues/40676))

- **新增** 新增了支持通过 `.Values.labels` 将标签添加到网关 Pod 模板中的能力。
  ([Issue #41057](https://github.com/istio/istio/issues/41057))
  ([Issue #43585](https://github.com/istio/istio/issues/43585))

- **新增** 新增了通过验证 `.Values.pilot.env.EXTERNAL_CA` 和
  `.Values.global.pilotCertProvider` 参数来限制外部 CA `usecases` 的
  K8s CSR 权限的 `clusterrole` 检查能力。

- **新增** 新增了 istio-cni `values.yaml` 节点亲和力配置。
  可用于允许将 istio-cni 排除在特定节点调度之外。

- **修复** 修复了 `CentOS9`/RHEL9 上的 SELinux 问题，其中不允许
  iptables-restore 打开 `/tmp` 中的文件。以及传递给 iptables-restore
  的规则不再写入文件，而是通过 `stdin` 传递。
  ([Issue #42485](https://github.com/istio/istio/issues/42485))

- **修复** 修复了使用 istioctl 安装 Istio 时，Webhook 配置在 dry-run 模式下被修改的问题。
  ([PR #44345](https://github.com/istio/istio/pull/44345))

- **移除** 移除了用户注入功能的网关标签 `istio.io/rev`，来避免在
  `istio.io/rev=<tag>` 的情况下无限创建 Pod。
  ([Issue #33237](https://github.com/istio/istio/issues/33237))

- **移除** 移除了 Operator 中对于名称以 `installed-state` 开头的 `iop`
  资源的调谐功能。这项功能现在完全依赖于 `install.istio.io/ignoreReconcile` 注解。
  该修改不会影响 `istioctl install` 的行为。
  ([Issue #29394](https://github.com/istio/istio/issues/29394))

- **移除** 从已发布的版本中移除了 `kustomization.yaml`
  和 `pre-generated` 安装清单（`gen-istio.yaml` 等）。
  因为这些之前安装的现已不受支持的测试镜像会导致用户使用如 Argo CD 等工具时出现问题。

## istioctl

- **改进** 改进了 `istioctl pc secret` 命令的输出，以十六进制形式显示证书序列号。
  ([Issue #43765](https://github.com/istio/istio/issues/43765))

- **改进** 改进了 `istioctl analyze` 命令，将不匹配的代理镜像消息输出为命名空间级别的
  IST0158 而不是 Pod 级别的 IST0105，这样更加简洁。

- **新增** 新增了 `istioctl analyze` 命令在遇到额外两个遥测场景错误时显示这些错误。
  ([Issue #43705](https://github.com/istio/istio/issues/43705))

- **新增** 新增了 `--output-dir` 标志用于指定 `bug-report` 命令生成的存档文件的输出目录。
  ([Issue #43842](https://github.com/istio/istio/issues/43842))

- **新增** 新增了在使用 `istioctl analyze` 验证 Gateway 资源中是否使用
  `credentialName` Secret 时的凭证验证。
  ([Issue #43891](https://github.com/istio/istio/issues/43891))

- **新增** 新增了一个针对仍在使用已弃用 `lightstep` 提供程序时显示警告消息的分析器。
  ([Issue #40027](https://github.com/istio/istio/issues/40027))

- **新增** 新增了 `bug-report` 中的 istiod 指标，以及一些如 `telemetry` 之类的调试点。
  ([Issue #44062](https://github.com/istio/istio/issues/44062))

- **新增** 在 `istioctl pc route` 的输出中新增了一个“VHOST NAME”列。
  ([Issue #44413](https://github.com/istio/istio/issues/44413))

- **新增** 为不同的 `istioctl dashboard` 命令添加了本地标志 `--ui-port`
  以允许用户指定用于仪表板的 UI 组件端口。

- **修复** 修复了 Server Side Apply 应在 1.22 版本以上的 Kubernetes 集群中默认启用，
  或者如果它在 Kubernetes 1.18-1.21 版本中运行需要被检测到的问题。

- **修复** 修复了 `istioctl install --set <boolvar>=<bool>` 和
  `istioctl manifests generate --set <boolvar>=<bool>`
  错误地将布尔值转换为字符串的问题。
  ([Issue #43355](https://github.com/istio/istio/issues/43355))

- **修复** 修复了 `istioctl experimental describe` 在 VirtualService
  被定义为跨多个服务拆分流量时不显示所有加权路由的问题。
  ([Issue #43368](https://github.com/istio/istio/issues/43368))

- **修复** 修复了 `istioctl x precheck` 命令会显示由 Istio
  默认设置的但实际不需要的 IST0136 消息的问题。
  ([Issue #36860](https://github.com/istio/istio/issues/36860))

- **修复** 修复了在 `istioctl analyze` 命令中，
  当分析的命名空间中存在没有选择器的服务时，会丢失一些消息的问题。

- **修复** 修复了 `istioctl` 命令的资源命名空间解析问题。

- **修复** 修复了在使用 `istioctl bug-report` 命令时使用 `--dir`
  指定临时工件目录不起作用的问题。
  ([Issue #43835](https://github.com/istio/istio/issues/43835))

- **修复** 修复了 `istioctl experimental revision describe`
  命令在网关存在时仍会产生网关未启用警告的问题。
  ([Issue #44002](https://github.com/istio/istio/issues/44002))

- **修复** 修复了 `istioctl experimental revision describe`
  命令给出的出口网关数量不正确的问题。
  ([Issue #44002](https://github.com/istio/istio/issues/44002))

- **修复** 修复了对内容为空的配置文件进行分析时结果不准确的问题。

- **修复** 修复了 `istioctl analyze` 命令在分析文件时不需要 Pod 和运行时资源的问题。
  ([Issue #40861](https://github.com/istio/istio/issues/40861))

- **修复** 修复了 `istioctl analyze` 命令以防止当网关中的服务器端口为 nil 时出现异常的问题。
  ([Issue #44318](https://github.com/istio/istio/issues/44318))

- **修复** 修复了 `istioctl experimental revision list` 命令中
  `REQD-COMPONENTS` 列数据不完整的问题，并规范输出格式。

- **修复** 修复了 `istioctl operator remove`
  命令由于 `no Deployment detected` 错误而无法删除 Operator 控制器的问题。
  ([Issue #43659](https://github.com/istio/istio/issues/43659))

- **修复** 修复了 `istioctl verify-install` 命令在使用多个 `iops` 时失败的问题。
  ([Issue #42964](https://github.com/istio/istio/issues/42964))

- **修复** 修复了 `istioctl experimental wait` 命令在未启用
  `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING` 时出现无法辨认消息的问题。
  ([PR #43023](https://github.com/istio/istio/pull/43023))
