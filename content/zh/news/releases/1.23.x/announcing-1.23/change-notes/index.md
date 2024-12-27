---
title: Istio 1.23.0 更新说明
linktitle: 1.23.0
subtitle: 主要版本
description: Istio 1.23.0 更新说明。
publishdate: 2024-08-14
release: 1.23.0
weight: 10
aliases:
    - /zh/news/announcing-1.23.0
---

## 弃用 {#deprecations}

- **弃用** 弃用了 In-Cluster Operator。
  请查看[我们的弃用公告博客文章](/zh/blog/2024/in-cluster-operator-deprecation-announcement/)了解有关此变更的更多详细信息。

## 流量治理 {#traffic-management}

- **新增** 添加了对代理 `100 Continue` 标头的支持。
  可以通过将 `ENABLE_100_CONTINUE_HEADERS` 设置为 `false` 来禁用此功能。

- **新增** 添加了一种从父 Gateway Class 上的 `istio.io/waypoint-for` 标签读取 waypoint 流量类型的方法。
  此值将覆盖全局默认值，如果将标签应用于 waypoint 资源，则将被覆盖。
  ([Issue #50933](https://github.com/istio/istio/issues/50933))

- **新增** 添加了对在 waypoint 代理中匹配多个服务 VIP 的支持。
  ([Issue #51886](https://github.com/istio/istio/issues/51886))

- **新增** 添加了一项实验性功能，可在请求期间启用工作线程内联集群创建。
  如果存在大量非活动集群和 > 1 个工作线程，这将节省内存和 CPU 周期。
  可以通过在代理 Deployment 中将 `ENABLE_DEFERRED_CLUSTER_CREATION` 设置为 `false` 来禁用此功能。

- **新增** 添加了对 Envoy 1.31 中添加的新 `reset-before-request` 重试策略的支持。
  ([Issue #51704](https://github.com/istio/istio/issues/51704))

- **修复** 修复了 `ISTIO_OUTPUT` iptables 链中的 UDP 流量提前退出的错误。
  ([Issue #51377](https://github.com/istio/istio/issues/51377))

- **修复** 修复了 `ServiceEntry` 状态地址字段不支持将 IP 地址分配给单个主机的问题，
  这导致新旧自动分配实现之间的行为出现不良差异。在地址中添加了“Host”字段，以支持将分配的 IP 映射到主机。

- **修复** 修复了如果来源不允许，CORS 过滤器会转发预检请求的问题。

- **修复** 修复了重试逻辑，使得在 `EXIT_ON_ZERO_ACTIVE_CONNECTIONS` 模式下获取 Envoy 指标更加安全。
  ([Issue #50596](https://github.com/istio/istio/issues/50596))

- **修复** 修复了 IPv6 配置传播到 `istio-cni` 的问题。请注意，IPv6 支持仍然不稳定。
  ([Issue #50162](https://github.com/istio/istio/issues/50162))

- **修复** 修复了 ZDS 未传递 `trust_domain` 的问题。
  ([Issue #51182](https://github.com/istio/istio/issues/51182))

- **修复** 修复了处理 IPv6 时 iptables 规则的 Ambient 问题。

- **修复** 修复了 `ServiceEntry` 的 IP 自动分配问题，改为按主机分配，而不是按每个 `ServiceEntry` 分配。
  ([Issue #52319](https://github.com/istio/istio/issues/52319))

- **修复** 修复了 `ServiceEntry` 验证以抑制使用自动 IP 分配控制器时出现的“address required”警告。
  ([Issue #52422](https://github.com/istio/istio/issues/52422))

- **修复** 修复了从网关或边车连接到使用 Ambient 模式注册的后端时不遵守 `DestinationRule` 中的 TLS 设置的问题。

- **修复** 修复了当 TLS 被禁用时，`DestinationRule` `proxyProtocol` 无法工作的问题。

- **移除** 删除了 `ISTIO_ENABLE_OPTIMIZED_SERVICE_PUSH` 功能标志。

- **移除** 删除了 `ENABLE_OPTIMIZED_CONFIG_REBUILD` 功能标志。

- **移除** 删除了实验性的 `PILOT_ENABLE_CONFIG_DISTRIBUTION_TRACKING`
  功能标志和相应的 `istioctl experimental wait` 命令。

- **更新** 更新了 `istio-cni` ConfigMap 以仅公开用户可配置的环境变量。

## 安全性 {#security}

- **新增** 当 Istio 作为 RA 运行并配置外部 CA 进行工作负载证书签名时，添加了更严格的 CSR 验证。
  ([Issue #51966](https://github.com/istio/istio/issues/51966))

- **改进** 通过允许自定义服务器套接字文件名，改进了使用 SPIRE 进行 SDS 的能力。
  以前，SPIRE 文档强制将 SPIRE SDS 服务器配置为使用 Istio 默认 SDS 套接字名称。
  此版本引入了 `WORKLOAD_IDENTITY_SOCKET_FILE` 作为代理环境变量。
  如果设置为非默认值，代理将期望在硬编码路径 `WorkloadIdentityPath/WORKLOAD_IDENTITY_SOCKET_FILE`
  处找到非 Istio SDS 服务器套接字，如果未找到健康套接字，则会抛出错误。
  否则，会对其进行监听。如果未设置，代理将启动 Istio 默认 SDS 服务器实例，
  并使用硬编码路径和硬编码套接字文件：`WorkloadIdentityPath/DefaultWorkloadIdentitySocketFile` 并监听它。
  这将删除/替换代理环境变量 `USE_EXTERNAL_WORKLOAD_SDS`（在 #45941 中添加）
  ([Issue #48845](https://github.com/istio/istio/issues/48845))

## 遥测 {#telemetry}

- **新增** 添加了[访问日志格式化程序](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/formatter/formatter)对 OpenTelemetry 的支持。
  所有代理升级到 Istio 1.23+ 后，用户可以添加 `CEL`/`METADATA`/`REQ_WITHOUT_QUERY` 命令。

- **修复** 修复了使用 OpenTelemetry 链路追踪时状态代码未设置的问题。
  ([Issue #50195](https://github.com/istio/istio/issues/50195))

- **修复** 修复了使用 OpenTelemetry 链路追踪提供程序时未设置跨度名称的问题。

- **修复** 修复了 `statsMatcher` 的正则表达式与路由的 `stat_prefix` 不匹配的问题。

- **修复** 修复了对于没有 `.svc.cluster.local` 后缀的服务，
  `cluster_name` 和 `http_conn_manager_prefix` 标签被错误截断的问题。

- **移除** 从 XDS 中删除了 Istio Stackdriver 指标。
  ([Issue #50808](https://github.com/istio/istio/issues/50808))

- **移除** 从 Istio XDS 中删除了 OpenCensus 追踪器。
  ([Issue #50808](https://github.com/istio/istio/issues/50808))

- **移除** 删除了功能标志 `ENABLE_OTEL_BUILTIN_RESOURCE_LABELS`。

## 可扩展性 {#extensibility}

- **移除** 从 API 中删除了内部多版本 protobuf 文件。对于大多数用户来说，
  这是内部更改。如果您直接将 Istio API 作为 protobuf 使用，请阅读升级说明。
  ([Issue #3127](https://github.com/istio/api/issues/3127))

## 安装 {#installation}

- **新增** 添加了 `.Values.pilot.trustedZtunnelNamespace` 到 `istiod` Helm Chart。
  如果将 ztunnel 安装到与 `istiod` 不同的命名空间，请设置此项。
  此值取代 `.Values.pilot.env.CA_TRUSTED_NODE_ACCOUNTS`（如果已设置，则仍然有效）。

- **新增** 向非 GA 功能和 API 添加了 `releaseChannel:extended` 标志。
  ([Issue #173](https://github.com/istio/enhancements/issues/173))

- **新增** 在网格代理配置中添加了异常值日志路径配置，允许用户配置异常值检测日志文件的路径。
  ([Issue #50781](https://github.com/istio/istio/issues/50781))

- **新增** 添加了一个 `ambient` 伞状 Helm Chart，它包装了安装 Istio 所需的基线 Istio 组件并提供 Ambient 支持。

- **新增** 添加了对通过 https 向 istiod 进行就绪性检查的支持，
  以便在利用远程控制平面进行 Sidecar 注入的集群中使用。
  ([Issue #51506](https://github.com/istio/istio/issues/51506))

- **修复** 修复了 CNI 插件继承 CNI 代理日志级别的问题。

- **修复** 修复了服务帐户注解格式的问题，删除了破折号。
  ([Issue #51289](https://github.com/istio/istio/issues/51289))

- **修复** 修复了自定义注解未传播到 ztunnel Chart 的问题。

- **修复** 修复了网关注入期间忽略 `sidecar.istio.io/proxyImage` 注解的问题。
  ([Issue #51888](https://github.com/istio/istio/issues/51888))

- **修复** 修复了无法正确解析 netlink 错误的问题，导致 `istio-cni` 无法正确忽略剩余的 ipsets。

- **改进** 改进了 CNI 日志配置。
  ([Issue #50958](https://github.com/istio/istio/issues/50958))

- **改进** 改进了 Istiod 多集群的 Helm 安装，以实现主远程模式。
  现在，Helm 安装只需要设置 `global.externalIstiod`，
  而不需要同时设置 `pilot.env.EXTERNAL_ISTIOD`。
  ([Issue #51595](https://github.com/istio/istio/issues/51595))

- **移除** `values.cni.logLevel` 现已被弃用。请改用 `values.{cni|global}.logging.level`。

- **更新** 更新了 [`distroless`](/zh/docs/ops/configuration/security/harden-docker-images/) 镜像，
  使其基于 [Wolfi](https://wolfi.dev)。这不会对用户产生任何影响。

- **更新** 更新了 Kiali 插件至版本 1.87.0。

- **升级** 升级了基础调试镜像以使用最新的 Ubuntu LTS `ubuntu:noble`。以前使用的是 `ubuntu:focal`。

## istioctl

- **新增** 添加了一个状态子命令，用于打印出给定命名空间的网关状态。
  ([Issue #51294](https://github.com/istio/istio/issues/51294))

- **新增** 添加了用户通过在 istiod 注入配置中设置 `values.gateways.seccompProfile.type`
  来设置自动部署航点的 `seccompProfile.type`（例如 `RuntimeDefault`）的功能。

- **新增** 在 `istioctl apply` 命令中添加了一个 `overwrite` 标志，
  以允许覆盖集群中的现有资源（最初，只是命名空间 waypoint 注册）。
  ([Issue #51312](https://github.com/istio/istio/issues/51312))

- **改进** 改进了 `istioctl version` 的输出，使其更加用户友好。
  ([Issue #51296](https://github.com/istio/istio/issues/51296))

- **改进** 改进了 `istioctl proxy-status` 命令。
    - 现在每个状态都包括自上次更改以来的时间。
    - 如果代理未订阅资源，则现在将显示为 `IGNORED` 而不是 `NOT SENT`。对于已请求但从未发送的资源，将继续使用 `NOT SENT`。
    - 当配置被拒绝时，包含一个新的 `ERROR` 状态。

## 示例 {#samples}

- **改进** 改进了 Bookinfo 应用程序的外观和体验。
