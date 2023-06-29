---
title: Istio 1.17.0 更新说明
linktitle: 1.17.0
subtitle: 次要版本
description: Istio 1.17.0 更新说明。
publishdate: 2023-02-14
release: 1.17.0
weight: 10
---

## 弃用通知{#deprecation-notices}

以下通知说明了根据 [Istio 的弃用政策](/zh/docs/releases/feature-stages/#feature-phase-definitions)将在未来某个版本中移除的功能。
请考虑升级您的环境以移除弃用的功能。

- **弃用** 针对版本低于 1.20 的 Kubernetes 环境，
  弃用了将 `PILOT_CERT_PROVIDER` 设置为 `kubernetes` 的操作行为。
  [PR #42233](https://github.com/istio/istio/pull/42233)

- **弃用** 弃用了 Lightstep 提供程序。
  请使用 OpenTelemetry 提供程序替代 Lightstep 提供程序。
  [Issue #40027](https://github.com/istio/istio/issues/40027)

## 流量治理{#traffic-management}

- **改进** 改进了 `MostSpecificHostMatch`
  以防止在遇到通配符时执行完整扫描主机操作。
  [Issue #41453](https://github.com/istio/istio/issues/41453)

- **改进** 改进了 Gateway 的命名以 `Name` 和 `GatewayClassName` 的串联为约定。
  Deployment 现在也使用自己的 Service Account 进行部署，
  而不是使用 `default` 令牌。
  命名约定会影响 Deployment、Service 和 Service Account 的名称
  [PR #43103](https://github.com/istio/istio/pull/43103)

- **新增** 新增了双堆栈对 `statefulsets/headless`、服务入口和网关的支持，
  并使用 `getWildcardsAndLocalHost` 进行入站集群构建。
  [PR #42712](https://github.com/istio/istio/pull/42712)

- **新增** 新增了在 `EnvoyFilter` 的 `LISTENER_FILTER` 中对 `ADD`、`REMOVE`、
  `REPLACE`、`INSERT_FIRST`、`INSERT_BEFORE`、`INSERT_AFTER` 操作的支持。
  [Issue #41445](https://github.com/istio/istio/issues/41445)

- **新增** 新增了验证 `Gateway` 和 `Sidecar`
  以防止主机名中出现 Envoy 不支持的部分通配符。
  [Issue #42094](https://github.com/istio/istio/issues/42094)

- **新增** 新增了对 k8s `ServiceInternalTrafficPolicy` 的支持
  （不考虑 `ProxyTerminatingEndpoints`）。
  [Issue #42377](https://github.com/istio/istio/issues/42377)

- **新增** 新增了 `excludeInterfaces` 对 CNI 插件的支持。
  [Issue #42381](https://github.com/istio/istio/pull/42381)

- **新增** 新增了在 `/config_dump` API 中对缺少的资源类型进行支持。
  [PR #42658](https://github.com/istio/istio/pull/42658)

- **修复** 新增了当 `InboundInterceptionMode` 为 TPROXY 时正确清理
  `istio-clean-iptables` 的问题。
  [PR #41431](https://github.com/istio/istio/pull/41431)

- **修复** 修复了使用代理配置不会对 `PrivateKeyProvider` 进行修改的问题。
  [Issue #41760](https://github.com/istio/istio/issues/41760)

- **修复** 修复了当发现选择器或命名空间标签（`ENABLE_ENHANCED_RESOURCE_SCOPING=true`）时，
  选择或取消选择命名空间时 Istio 和 K8S Gateway API 的资源未被正确处理的问题。
  [Issue #42173](https://github.com/istio/istio/issues/42173)

- **修复** 修复了 ServiceEntries 通过使用 `DNS_ROUND_ROBIN`
  能够指定 0 个端点的问题。
  [Issue #42184](https://github.com/istio/istio/issues/42184)

- **修复** 修复了具有不同版本标签（与安装的 Istio 版本不同）的 ServiceEntries
  创建后被处理并为其创建端点的问题。
  [Issue #42212](https://github.com/istio/istio/issues/42212)

- **修复** 修复了同步超时设置在从集群上不起作用的问题。
  [PR #42252](https://github.com/istio/istio/pull/42252)

- **修复** 通过修复网关服务依赖关系，修复了 Kubernetes 服务中 `exportTo`
  注解在网关上不起作用的问题。
  [Issue #42400](https://github.com/istio/istio/issues/42400)

- **修复** 修复了 Sidecar 没有选择服务时缺少的固定位置标签的问题。
  [PR #42412](https://github.com/istio/istio/pull/42412)

- **修复** 修复了网络网关变更时错误计算网络端点的问题。
  [Issue #42818](https://github.com/istio/istio/issues/42818)

- **修复** 修复了当 `PILOT_FILTER_GATEWAY_CLUSTER_CONFIG`
  被启用时自动直通网关无法获得 XDS 推送服务更新的问题。
  [PR #42721](https://github.com/istio/istio/pull/42721)

- **修复** 修复了 VirtualService 委托行为针对
  `defaultVirtualServiceExportTo: ["."]` 设置不工作的问题。
  [Issue #42602](https://github.com/istio/istio/issues/42602)

- **修复** 修复了 `PortLevelSettings[].Port` 为 nil 时
  Pilot 推送 XDS Panic 导致 Pilot 异常退出的问题。
  [Issue #42598](https://github.com/istio/istio/issues/42598)

- **修复** 修复了导致 Namespace 的网络标签比 Pod
  的网络标签具有更高优先级的问题。
  [Issue #42675](https://github.com/istio/istio/issues/42675)

- **修复** 修复了当 `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING` 被启用时，
  Pilot 状态不会记录过多错误的问题。
  [Issue #42612](https://github.com/istio/istio/issues/42612)

## 安全性{#security}

- **新增** 新增了 L7 拒绝规则的验证警告消息将阻止具有该规则策略范围内的所有 TCP 流量。
  [PR #41802](https://github.com/istio/istio/pull/41802)

- **新增** 新增了对在 SDS 中使用
  QAT（`QuickAssist Technology`）`PrivateKeyProvider` 的支持。
  [PR #42203](https://github.com/istio/istio/pull/42203)

- **新增** 新增了用于为网关和边车选择 QAT 私钥提供程序的配置。
  [PR #2565](https://github.com/istio/api/pull/2565)

- **新增** 新增了支持将 JWT 声明复制到 HTTP 请求头中的功能。
  [Issue #39724](https://github.com/istio/istio/issues/39724)

- **修复** 修复了当 `automountServiceAccountToken` 为 `false` 且
  `PILOT_CERT_PROVIDER` 为 `kubernetes` 时阻止
  istio-proxy 访问根 CA 的问题。
  [PR #42233](https://github.com/istio/istio/pull/42233)

## 遥测{#telemetry}

- **更新** 更新了 Telemetry API 使用新的原生扩展（stats）来获取
  Prometheus 统计信息，而不是基于 Wasm 的扩展。
  此举改善了该功能的 CPU 开销和内存使用。
  自定义维度不再需要正则表达式和引导注解。
  如果自定义内容使用带有 Wasm 属性的 CEL 表达式，
  它们很可能会受到影响。
  [PR #41441](https://github.com/istio/istio/pull/41441)

- **新增** 新增了针对 Telemetry 资源的分析器。
  [Issue #41170](https://github.com/istio/istio/issues/41170)
  [PR #41785](https://github.com/istio/istio/pull/41785)

- **新增** 新增了针对 `reporting_interval` 的支持。
  这将允许最终用户通过 Telemetry API 配置
  `tcp_reporting_duration`（配置调用之间的时间）以进行指标报告。
  该功能目前仅支持 TCP 指标，但将来我们可能会将其用于持续时间较长的 HTTP 流中。
  [Issue #41763](https://github.com/istio/istio/issues/41763)

- **修复** 修复了配置 `Datadog` 链路提供程序时，Telemetry API
  中的错误请求 `malformed Host header` 存在的问题。
  [Issue #41829](https://github.com/istio/istio/issues/41829)

- **修复** 修复了由于缺少服务名称，OpenTelemetry 链路跟踪器无法正常工作的问题。
  [Issue #42080](https://github.com/istio/istio/issues/42080)

## 安装{#installation}

- **更新** 更新了 Kiali 插件版本由 `1.55.1` 至 `1.63.1`。
  [PR #43052](https://github.com/istio/istio/pull/43052)，
  [PR #42193](https://github.com/istio/istio/pull/42193)，
  [PR #41984](https://github.com/istio/istio/pull/41984)

- **更新** 更新了支持的最低 Kubernetes 版本为 `1.23.x`。
  [PR #43252](https://github.com/istio/istio/pull/43252)

- **新增** 新增了在 `istioctl operator remove` 命令中使用 `--purge` 标志后，
  将删除 Istio Operator 的所有修订。
  [Issue #41547](https://github.com/istio/istio/issues/41547)

- **新增** 新增了支持通过 Helm 安装允许 CSR 签名者的功能。
  [PR #41923](https://github.com/istio/istio/pull/41923)

- **新增** 新增了 Gateway 通过 Helm 部署的输入项，
  用于显式设置网关 Deployment 的 `imagePullPolicy`。
  [Issue #42852](https://github.com/istio/istio/issues/42852)

- **修复** 修复了指定 `--revision default` 时 `istioctl install` 会失败的问题。
  [PR #41912](https://github.com/istio/istio/pull/41912)

- **修复** 修复了当未指定 `--revision` 或使用 `default` 设置时，
  `istioctl verify-install` 的行为不一致的问题。
  [PR #41912](https://github.com/istio/istio/pull/41912)

- **修复** 修复了设置多个修订标签时，`mutatingwebhook` 不会被拆分的问题。
  [Issue #42234](https://github.com/istio/istio/issues/42234)

- **修复** 修复了为 Pilot 的安全 gRPC 服务器在默认位置提供服务证书初始化的问题。
  [Issue #42249](https://github.com/istio/istio/issues/42249)

- **修复** 修复了 `appProtocol` 字段在 IstioOperator
  `ServicePort` 中没有生效的问题。
  [Issue #42759](https://github.com/istio/istio/issues/42759)

- **修复** 修复了网关 Pod 不遵守 Helm Values 中设定的
  `global.imagePullPolicy` 的问题。
  [PR #42026](https://github.com/istio/istio/pull/42026)

- **移除** 移除了当 CNI 用作独立插件时，如果 istio-cni
  不是默认的 CNI 插件会发出警告的机制。
  [PR #41858](https://github.com/istio/istio/pull/41858)

- **移除** 移除了从 istio-operator 的 URL 中获取图表的能力。
  [Issue #41704](https://github.com/istio/istio/issues/41704)

## istioctl

- **新增** 新增了在 `Istiods` 之间切换控制时，
  管理日志中具有 `revision` 标志。
  [PR #41321](https://github.com/istio/istio/pull/41321)

- **更新** 更新了 `admin log` 命令中的 `-r` 标志为 `--revision`
  的简写，以与其他命令保持一致（最初 `-r` 是 `--reset` 的简写）。
  [PR #41321](https://github.com/istio/istio/pull/41321)

- **更新** 更新了 `client-go` 到 `v1.26.1`，
  同时移除了对 `azure` 和 `gcp` 授权插件的支持。
  [PR #43101](https://github.com/istio/istio/pull/43101)

- **新增** 新增了 `istioctl proxy-config ecds` 从
  Envoy 中为指定的 Pod 检索类型扩展配置。
  [PR #42365](https://github.com/istio/istio/pull/42365)

- **新增** 新增了能够使用 `istioctl proxy-config log`
  命令为 Deployment 的所有 Pod 设置代理日志级别。
  [Issue #42919](https://github.com/istio/istio/issues/42919)

- **新增** 新增了 `istioctl analyze` 命令中
  `--revision` 标志，以指定特定的修订版。
  [Issue #38148](https://github.com/istio/istio/issues/38148)

- **修复** 修复了清单 URL 路径（用于从 `Github`
  版本下载 Istio 版本）以支持多架构而不使用硬编码的问题。
  [PR #41483](https://github.com/istio/istio/pull/41483)

- **修复** 修复了在不使用 `--cluster-specific` 选项的情况下，
  使用 `istioctl` 通过 Helm Chart 库生成清单的默认行为，
  替代使用 `istioctl` 定义的最低 Kubernetes 版本的问题。
  [Issue #42441](https://github.com/istio/istio/issues/42441)

- **修复** 修复了在 `EnvoyFilter.ListenerMatch.FilterChainMatch`
  下缺少可选字段 `filter` 时 `istioctl analyze` 抛出 `SIGSEGV` 的问题。
  [Issue #42831](https://github.com/istio/istio/issues/42831)

- **修复** 修复了当用户使用 `--proxy-admin-port` 指定自定义代理管理端口时，
  `istioctl proxy-config` 失败的问题。
  [Issue #43063](https://github.com/istio/istio/issues/43063)

- **修复** 修复了 `istioctl version` 与自定义版本不兼容的问题。
  [PR #41650](https://github.com/istio/istio/pull/41650)

- **修复** 修复了 `istioctl validate` 未检测到服务端口 `appProtocol` 的问题。
  [PR #41517](https://github.com/istio/istio/pull/41517)

- **修复** 修复了 `istioctl proxy-config endpoint -f -`
  返回 `Error: open -: no such file or directory` 的问题。
  [Issue #43045](https://github.com/istio/istio/issues/43045)

## 文档变更{#documentation-changes}

- **修复** 修复了 `pilot-discovery` 环境变量名称由
  `VERIFY_CERT_AT_CLIENT` 变更为 `VERIFY_CERTIFICATE_AT_CLIENT`。
  [PR #2596](https://github.com/istio/api/pull/2596)

- **移除** 移除了关于不支持委托 VirtualService 正则表达式的评论。
  [Issue #2527](https://github.com/istio/api/issues/2527)
