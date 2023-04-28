---
title: Istio 1.13 变更说明
linktitle: 1.13.0
subtitle: 次要版本
description: Istio 1.13.0 变更说明.
publishdate: 2022-02-11
release: 1.13.0
weight: 10
aliases:
    - /zh/news/announcing-1.13.0
---

## 流量管理{#traffic-management}

- **新增** 新增了包含 `MeshConfig.DefaultConfig` 配置的稳定子集，用于配置 `ProxyConfig` 值的一个 ​​API (CRD)。

- **新增** 新增了基于主机名的支持东西向流量的多网络网关。主机名将在控制平面和每个 IP 将用作端点。可以通过设置禁用此行为 istiod 的 `RESOLVE_HOSTNAME_GATEWAYS= false`。
  ([Issue #29359](https://github.com/istio/istio/issues/29359))

- **新增** 新增了对 gRPC 探针重写的支持。

- **新增** 新增了一个功能标志 `PILOT_LEGACY_INGRESS_BEHAVIOR`，默认为 false。如果设置为 true，Istio ingress 将执行不符合 [Kubernetes 规范](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/#multiple-matches)。
  ([Issue #35033](https://github.com/istio/istio/issues/35033))

- **新增** 新增了通过 `proxyMetadata` 在 Envoy 工作线程之间取得平衡监听器的支持。
  ([Issue #18152](https://github.com/istio/istio/issues/18152))

- **提升** `WorkloadGroup` 到 v1beta1。
  ([Issue #25652](https://github.com/istio/istio/issues/25652))

- **改进** 改进了 istio-agent 健康探测重写为不重用连接，反映 Kubernetes 的探测行为。
  ([Issue #36390](https://github.com/istio/istio/issues/36390))

- **改进** 默认的 `PILOT_MAX_REQUESTS_PER_SECOND` 为 25（之前为 100），它限制了每秒**创建** XDS 连接的数量。这已被证明可以提高高负载下的性能。

- **更新** 更新了控制平面读取 `EndpointSlice` 而不是 `Endpoints` 用于 Kubernetes 1.21 或更高版本的服务发现。切换回旧的 istiod 中基于 `Endpoints` 的行为设置 `PILOT_USE_ENDPOINT_SLICE=false`。

- **修复** 修复了为服务目标端口指定冲突协议的问题，将导致该端口的协议选择不稳定。
  ([Issue #36462](https://github.com/istio/istio/issues/36462))

- **修复** 修复了将服务的端点从 0 扩展到 1 可能会导致客户端服务帐户验证被错误地填充的问题。
  ([Issue #36465](https://github.com/istio/istio/issues/36465) and [#31534](https://github.com/istio/istio/issues/31534))

- **修复** 修复了网格配置中的 `TcpKeepalive` 设置不受支持的问题。
  ([Issue #36499](https://github.com/istio/istio/issues/36499))

- **修复** 修复了当服务被删除并再次创建时可以配置陈旧端点的问题。
  ([Issue #36510](https://github.com/istio/istio/issues/36510))

- **修复** 修复了如果优先领导选举（通过 `PRIORITIZED_LEADER_ELECTION` env 变量控制）被禁用时 istiod 崩溃的问题。
  ([Issue #36541](https://github.com/istio/istio/issues/36541))

- **修复** 修复了边车 iptables 会由于窗口外数据包导致间歇性连接重置的问题。引入了一个标志 `meshConfig.defaultConfig.proxyMetadata.INVALID_DROP` 来控制此设置。
  ([Issue #36566](https://github.com/istio/istio/pull/36566))

- **修复** 修复了原地升级 1.12 之前版本代理到 1.12 版本代理导致 TCP 连接失败的问题。
  ([Issue #36797](https://github.com/istio/istio/pull/36797))

- **修复** 修复了带有任何补丁上下文的 `EnvoyFilter` 将跳过在网关添加新集群和监听器的问题。

- **修复** 修复了在某些情况下导致 HTTP/1.0 请求被拒绝（出现“426 Upgrade Required”错误）的问题。
  ([Issue #36707](https://github.com/istio/istio/issues/36707))

- **修复** 修复了在网关中使用 `ISTIO_MUTUAL` TLS 模式同时设置 `credentialName` 导致无法配置双向 TLS 的问题。此配置现在被拒绝，因为 `ISTIO_MUTUAL` 旨在在未设置 `credentialName` 的情况下使用。通过在 Istiod 中配置 `PILOT_ENABLE_LEGACY_ISTIO_MUTUAL_CREDENTIAL_NAME=true` 环境变量，可以保留旧行为。

- **修复** 修复了启用 RDS 缓存时委托 VirtualService 中的更改不生效的问题。
  ([Issue #36525](https://github.com/istio/istio/issues/36525))

- **修复** 修复了导致端口 22 上的流量出现 mTLS 错误的问题，默认情况下将端口 22 包含在 iptables 中。
  ([Issue #35733](https://github.com/istio/istio/issues/35733))

- **修复** 修复了导致主机名与集群域重叠（例如 `example.local`）生成无效路由的问题。
  ([Issue #35676](https://github.com/istio/istio/issues/35676))

- **修复** 修复了如果在 Gateway 中配置了重复的密码套件，它们会被推送到 Envoy 配置的问题。通过此修复，重复密码套件将被忽略并记录。
  ([Issue #36805](https://github.com/istio/istio/issues/36805))

## 安全{#security}

- **新增** 新增了边车 API 的 TLS 设置，以便在边车代理上对来自网格外部的请求启用 TLS/mTLS 终止。
  ([Issue #35111](https://github.com/istio/istio/issues/35111))

- **提升** 将 [授权策略试运行模式](/zh/docs/tasks/security/authorization/authz-dry-run/) 提升到 Alpha。
  ([Issue #112](https://github.com/istio/enhancements/pull/112))

- **修复** 修复了 ext-authz 过滤器中影响 gRPC 检查响应 API 行为的几个问题。有关更多信息，请参阅 [Envoy 发布说明](https://www.envoyproxy.io/docs/envoy/latest/version_history/v1.20.0#bug-fixes) 如果您将授权策略与 Istio 中的 ext-authz gRPC 扩展提供程序一起使用，则可以查看错误修复的详细信息。
  ([Issue #35480](https://github.com/istio/istio/issues/35480))

## 遥测{#telemetry}

- **新增** 新增了在 Envoy-generated 的追踪跨度中选择服务名称生成方案的配置。
  ([Issue #36162](https://github.com/istio/istio/issues/36162) and [#12644](https://github.com/istio/istio/issues/12644))

- **新增** 新增了通用表达式语言 (CEL) 过滤器支持访问日志。
  ([Issue #36514](https://github.com/istio/istio/issues/36514))

- **新增** 新增了访问日志提供程序和访问日志过滤控件遥测 API。

- **新增** 新增了一个用于设置在确定跟踪的采样策略时是否应使用边车生成的请求 ID 的选项。

- **新增** 新增了可配置的服务集群命名方案支持。
  ([Issue #36162](https://github.com/istio/istio/issues/36162))

- **改进** 改进了 Istiod `JWTRule`：失败的 `JWKS` 请求现在被截断为 100 个字符。
  ([Issue #35663](https://github.com/istio/istio/issues/35663))

## 安装{#installation}

- **新增** 新增了一个 Istio-CNI Helm 图表用以设置 `securityContext` 标志的特权标志。
  ([Issue #34211](https://github.com/istio/istio/issues/34211))

- **移除** 移除了在使用多集群机密时支持许多非标准的 `kubeconfig` 身份验证方法。

- **更新** 更新了 istiod 部署以维护 `values.pilot.nodeSelector`。
  ([Issue #36110](https://github.com/istio/istio/issues/36110))

- **修复** 修复了当 Istio 控制平面连接了活动代理时集群内操作员无法修剪资源的问题。
  ([Issue #35657](https://github.com/istio/istio/issues/35657))

- **修复** 修复了在默认修订版转变 webhook 中省略了 `.Values.sidecarInjectiorWebhook.enableNamespacesByDefault` 设置，并在 `istioctl tag` 中添加了 `--auto-inject-namespaces` 标志来控制此设置。
  ([Issue #36258](https://github.com/istio/istio/issues/36258))

- **修复** 修复了使用 Helm 值设置 `includeInboundPorts` 未生效的问题。
  ([Issue #36644](https://github.com/istio/istio/issues/36644))

- **修复** 修复了阻止 Helm 图表用作图表依赖项的问题。
  ([Issue #35495](https://github.com/istio/istio/issues/35495))

- **修复** 修复了在给定环境变量的布尔值或数值时 Helm 图表生成无效清单的问题。
  ([Issue #36946](https://github.com/istio/istio/issues/36946))

- **修复** 修复了在合并指标时检测 `prometheus.io.scrape` 注释。
  ([Issue #31187](https://github.com/istio/istio/issues/31187))

## istioctl{#istioctl}

- **新增** 当 ExternalName 类型的服务具有无效的端口名称或端口名称为 tcp 时，新增了 `istioctl analyze` 显示警告。
  ([Issue #35429](https://github.com/istio/istio/issues/35429))

- **新增** 新增了 `istioctl install` 中日志选项，以防止出现意外消息。
  ([Issue #35770](https://github.com/istio/istio/issues/35770))

- **新增** 新增了 `istioctl ps` 命令的输出中 `CLUSTER` 列。

- **新增** 新增了错误报告的全局通配符模式匹配 `--include` 和 `--exclude` 标志。

- **新增** 新增了 `operator dump` 的输出格式标志。

- **新增** 新增了 `--operatorFileName` 标志到 `kube-inject`，用以支持 `IstioOperator` 文件的。
  ([Issue #36472](https://github.com/istio/istio/issues/36472))

- **新增** 新增了 `istioctl analyze` 现在支持 `--ignore-unknown`，用以抑制在文件或目录中发现非 k8s yaml 文件时出错。
  ([Issue #36471](https://github.com/istio/istio/issues/36471))

- **新增** stats 命令中新增了 `istioctl experimental envoy-stats` 用于检索 istio-proxy envoy 指标。

- **修复** 修复了 `--duration` 标志永远不会在 `istioctl bug-report` 命令中使用。

- **修复** 修复了在 `istioctl bug-report` 中使用标志会导致错误结果。
  ([Issue #36103](https://github.com/istio/istio/issues/36103))

- **修复** 修复了 `operator init --dry-run` 创建不期望的命名空间。

- **修复** 修复了虚拟机配置中 json 编组后的错误格式。
  ([Issue #36358](https://github.com/istio/istio/issues/36358))

## 文档变更{#documentation-changes}

- **修复** 修复了遥测配置参考页面的格式。
