---
title: Istio 1.26.0 更新说明
linktitle: 1.26.0
subtitle: 主要版本
description: Istio 1.26.0 更新说明。
publishdate: 2025-05-08
release: 1.26.0
weight: 10
aliases:
    - /zh/news/announcing-1.26.0
    - /zh/news/announcing-1.26.x
---

## 流量治理 {#traffic-management}

* **改进** 改进了 CNI 代理，使其不再需要 `hostNetwork`，从而增强了兼容性。
  现在可以根据需要动态切换到主机网络。可以通过设置 `istio-cni` Chart 中的
  `ambient.shareHostNetworkNamespace` 字段暂时恢复之前的行为。
  ([Issue #54726](https://github.com/istio/istio/issues/54726))

* **改进** 改进了 iptables 二进制检测，以验证基线内核支持，
  并在旧版和 `nft` 都存在但未指定规则时优先选择 `nft`。

* **更新** 更新了每个套接字事件接受的最大连接数默认值为 1，以提高性能。
  要恢复到之前的行为，请将 `MAX_CONNECTIONS_PER_SOCKET_EVENT_LOOP` 设置为 0。

* **新增** 添加了 `EnvoyFilter` 通过域名匹配 `VirtualHost` 的功能。

* **新增** 添加了对实验性 Gateway API 功能 `BackendTLSPolicy` 和 `XBackendTrafficPolicy` 的初始支持。
  这些功能默认处于禁用状态，需要设置 `PILOT_ENABLE_ALPHA_GATEWAY_API=true`。
  ([Issue #54131](https://github.com/istio/istio/issues/54131)),
  ([Issue #54132](https://github.com/istio/istio/issues/54132))

* **新增** 添加了在 `SIMPLE` 模式下，除了 `Secret` 之外，
  还支持引用 `ConfigMap`，用于 `DestinationRule` TLS - 当只需要 CA 证书时很有用。
  ([Issue #54131](https://github.com/istio/istio/issues/54131)),
  ([Issue #54132](https://github.com/istio/istio/issues/54132))

* **新增** 添加了 [Gateway API 自动化部署](/zh/docs/tasks/traffic-management/ingress/gateway-api/#automated-deployment)的自定义支持。
  这适用于 Istio `Gateway` 类型（入口和出口）以及
  Istio waypoint `Gateway` 类型（Ambient waypoint）。
  用户现在可以自定义生成的资源，例如 `Service`、`Deployment`、
  `ServiceAccount`、`HorizontalPodAutoscaler` 和 `PodDisruptionBudget`。

* **新增** 为 `istiod` 添加了新的环境变量 `ENABLE_GATEWAY_API_MANUAL_DEPLOYMENT`。
  设置为 `false` 时，将禁用 Gateway API 资源自动附加到现有网关部署的功能。
  默认情况下，该变量为 `true`，以维持当前行为。

* **新增** 添加了使用 Retry API（`retry_ignore_previous_hosts`）配置重试主机谓词的功能。

* **新增** 添加了对重试期间指定退避间隔的支持。

* **新增** 添加了在 waypoint 代理中使用 `TCPRoute` 的支持。

* **修复** 修复了当 `ServiceEntry` 配置了带有 DNS 解析的 `workloadSelector` 时，
  验证 webhook 错误地报告警告的问题。
  ([Issue #50164](https://github.com/istio/istio/issues/50164))

* **修复** 修复了使用 Ambient 模式时 FQDN 无法在 `WorkloadEntry` 中工作的问题。

* **修复** 修复了在 Gateway 侦听器上启用 mTLS 时 `ReferenceGrants` 不起作用的情况。
  ([Issue #55623](https://github.com/istio/istio/issues/55623))

* **修复** 修复了 Istio 无法正确检索沙盒 waypoint 的 `allowedRoutes` 的问题。
  ([Issue #56010](https://github.com/istio/istio/issues/56010))

* **修复** 修复了当 Pod 被驱逐时 `ServiceEntry` 端点泄漏的错误。
  ([Issue #54997](https://github.com/istio/istio/issues/54997))

* **修复** 修复了 IPv6 优先级双栈服务的监听器地址重复的问题。
  ([Issue #56151](https://github.com/istio/istio/issues/56151))

## 安全性 {#security}

* **新增** 添加了对 v1alpha1 `ClusterTrustBundle` API 的实验性支持。
  您可以通过设置 `values.pilot.env.ENABLE_CLUSTER_TRUST_BUNDLE_API=true` 来启用此功能。
  请确保您的集群中已启用相应的功能门控；
  详情请参阅 [KEP-3257](https://github.com/kubernetes/enhancements/tree/master/keps/sig-auth/3257-cluster-trust-bundles)。
  ([Issue #43986](https://github.com/istio/istio/issues/43986))

## 遥测 {#telemetry}

* **新增** 通过 Telemetry API 添加了对 `EnvoyFileAccessLog`
  提供程序中的 `omit_empty_values` 字段的支持。
  ([Issue #54930](https://github.com/istio/istio/issues/54930))

* **新增** 添加了环境变量 `PILOT_SPAWN_UPSTREAM_SPAN_FOR_GATEWAY`，
  用于分隔服务器和客户端网关的链路追踪跨度。当前默认为 `false`，但将来会默认开启。

* **新增** 添加了使用弃用的遥测提供商 Lightstep 和 OpenCensus 的警告消息。
  ([Issue #54002](https://github.com/istio/istio/issues/54002))

## 安装 {#installation}

* **改进** 改进了 GKE 上的安装体验。设置 `global.platform=gke` 后，
  所需的 `ResourceQuota` 资源将自动部署。通过 `istioctl` 安装时，
  如果检测到 GKE，此设置也会自动启用。此外，`cniBinDir` 现已被正确配置。

* **改进** 改进了 `ztunnel` Helm Chart，不再将资源名称分配给 `.Release.Name`，
  而是默认使用 `ztunnel`。此操作撤销了 Istio 1.25 中引入的更改。

* **新增** 添加了通过 `istioctl` 或 Helm 安装 Istio 时在修订标签 webhook 中设置 `reinvocationPolicy` 的支持。

* **新增** 添加了在 Gateway Helm Chart 中配置服务 `loadBalancerClass` 的功能。
  ([Issue #39079](https://github.com/istio/istio/issues/39079))

* **新增** 添加了一个 `ConfigMap` Value，
  用于存储用户提供的 Helm Value 以及应用 `istiod` Chart 的配置文件后的合并 Value。

* **新增** 添加了从 `istiod` 环境变量读取标头值的支持。
  ([Issue #53408](https://github.com/istio/istio/issues/53408))

* **新增** 为 `ztunnel` 和 `istio-cni` Helm Chart 添加了可配置的 `updateStrategy`。

* **修复** 修复了 Sidecar 注入模板中的一个错误，
  当流量拦截和原生 Sidecar 都被禁用时，该问题会错误地删除现有的 init 容器。
  ([Issue #54562](https://github.com/istio/istio/issues/54562))

* **修复** 修复了使用 `--set networkGateway` 时网关
  Pod 上缺少 `topology.istio.io/network` 标签的问题。
  ([Issue #54909](https://github.com/istio/istio/issues/54909))

* **修复** 修复了在 `istio/gateway` Helm Chart 中设置 `replicaCount=0`
  导致 `replicas` 字段被省略而不是明确设置为 `0` 的问题。
  ([Issue #55092](https://github.com/istio/istio/issues/55092))

* **修复** 修复了使用 SPIRE 作为 CA 时导致基于文件的证书引用（例如来自 `DestinationRule` 或 `Gateway`）失败的问题。

* **移除** 删除了已弃用的 `ENABLE_AUTO_SNI` 标志和相关代码路径。

## istioctl

* **新增** 在 `istioctl experiment workload group create` 上添加了一个 `--locality` 参数。
  ([Issue #54022](https://github.com/istio/istio/issues/54022))

* **新增** 添加了使用 `istioctl analyze` 命令运行特定分析器检查的功能。

* **新增** 在 `istioctl create-remote-secret` 中添加了 `--tls-server-name` 参数，
  允许在生成的 kubeconfig 中设置 `tls-server-name`。
  这可确保当 `server` 字段被网关代理主机名覆盖时，TLS 连接能够成功。

* **新增** 添加了对 `istiod` Chart 中的 `envVarFrom` 字段的支持。

* **修复** 修复了 `istioctl analyze` 报告未知注解 `sidecar.istio.io/statsCompression` 的问题。
  ([Issue #52082](https://github.com/istio/istio/issues/52082))

* **修复** 修复了省略 `IstioOperator.components.gateways.ingressGateways.label`
  或 `IstioOperator.components.gateways.ingressGateways.label` 时阻止安装的错误。
  ([Issue #54955](https://github.com/istio/istio/issues/54955))

* **修复** 修复了 `istioctl` 忽略 `IstioOperator.components.gateways.ingressGateways`
  和 `egressGateways` 下的 `tag` 字段的错误。
  ([Issue #54955](https://github.com/istio/istio/issues/54955))

* **修复** 修复了当指定名称时，`istioctl waypoint delete` 可能会删除非 waypoint Gateway 资源的问题。
  ([Issue #55235](https://github.com/istio/istio/issues/55235))

* **修复** 修复了 `istioctl experiment describe` 不遵循 `--namespace` 标志的问题。
  ([Issue #55243](https://github.com/istio/istio/issues/55243))

* **修复** 修复了使用 `istioctl` 创建 waypoint 代理时阻止同时生成
  `istio.io/waypoint-for` 和 `istio.io/rev` 标签的错误。
  ([Issue #55437](https://github.com/istio/istio/issues/55437))

* **修复** 修复了 `istioctl admin log` 无法修改 `ingress status` 日志级别的问题。
  ([Issue #55741](https://github.com/istio/istio/issues/55741))

* **修复** 修复了在 `istioctl` YAML 配置中设置
  `reconcileIptablesOnStartup: true` 时验证失败的问题。
  ([Issue #55347](https://github.com/istio/istio/issues/55347))
