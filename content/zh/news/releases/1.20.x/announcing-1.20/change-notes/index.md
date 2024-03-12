---
title: Istio 1.20.0 更新说明
linktitle: 1.20.0
subtitle: 次要版本
description: Istio 1.20.0 更新说明。
publishdate: 2023-11-14
release: 1.20.0
weight: 20
---

## 弃用通知 {#deprecation-notices}

以下通知说明了根据 [Istio 的弃用政策](/zh/docs/releases/feature-stages/#feature-phase-definitions)将在未来某个版本中移除的功能。
请考虑升级您的环境以移除弃用的功能。

- Istio 1.20.0 中没有新的弃用内容。

## 流量治理 {#traffic-management}

- **改进** 改进了对 `ExternalName` 服务的支持。有关详细信息，请参阅升级说明。

- **改进** 改进了 HTTP 和 TCP Envoy 过滤器的排序，以增强一致性。

- **改进** 改进了 `iptables` 锁定功能。新的实现在需要时使用
  `iptables` 内置锁等待，并在不需要时完全禁用锁定。

- **改进** 改进了通过 `ServiceEntry` 资源中的 `endpoints`
  字段内联添加的 `WorkloadEntry` 资源在不同网络上不再需要指定地址。
  ([Issue #45150](https://github.com/istio/istio/issues/45150))

- **新增** 添加了对 `VirtualService` 中多个目的地的流量镜像支持。
  ([Issue #13330](https://github.com/istio/istio/issues/13330))

- **新增** 添加了用户可以通过 Operator API 或 Helm Chart
  在 Istio Service 资源中指定 `ipFamilyPolicy` 和 `ipFamilies` 设置的功能。
  ([Issue #44017](https://github.com/istio/istio/issues/44017))

- **新增** 添加了对网络 `WasmPlugin` 的支持。

- **新增** 添加了门控标志 `ISTIO_ENABLE_IPV4_OUTBOUND_LISTENER_FOR_IPV6_CLUSTERS`，
  在只有 IPv6 的集群中用来管理一个附加的出站侦听器，以处理 IPv4 NAT 出站流量。
  这对于只有 IPv6 的集群环境（例如管理只有 Egress IPv4 以及 IPv6 IP 的 EKS）非常有用。
  ([Issue #46719](https://github.com/istio/istio/issues/46719))

- **新增** 添加了通过 `targetRef` 字段将 `AuthorizationPolicy`
  附加到 Kubernetes `Gateway` 资源的功能。
  ([Issue #46847](https://github.com/istio/istio/issues/46847))

- **新增** 通过 `values.cni.cniNetnsDir` 指定替代网络命名空间路径（例如 minikube）。
  ([Issue #47444](https://github.com/istio/istio/issues/47444))

- **更新** `failoverPriority` 和 `failover` 现在可以协同工作。

- **修复** 修复了创建 `WorkloadGroup` 时立即自动注册已连接的代理的 `WorkloadEntry` 的问题。
  ([Issue #45329](https://github.com/istio/istio/issues/45329))

- **修复** 修复了多网络端点的 DNS 解析问题，
  现在可以通过网关解析具有多网络端点 DNS 的 `ServiceEntry`。
  ([Issue #45506](https://github.com/istio/istio/issues/45506))

- **修复** 修复了在没有有效本地网关的情况下无法识别远程网关的问题。
  ([Issue #46435](https://github.com/istio/istio/issues/46435))

- **修复** 修复了添加 Waypoint 代理可能导致流量中断的问题。
  ([Issue #46540](https://github.com/istio/istio/issues/46540))

- **修复** 修复了由于 `DestinationRule` TLS 模式设置为
  `ISTIO_MUTUAL` 以外的其他模式而导致无法访问多网络端点的问题。
  ([Issue #46555](https://github.com/istio/istio/issues/46555))

- **修复** 修复了当安装时未使用 `values.global.network` 进行配置或在
  Kubernetes `Gateway` 资源上使用 `topology.istio.io/network` 进行覆盖时，
  Waypoint 代理会缺少 `ISTIO_META_NETWORK` 字段的问题。

- **修复** 修复了上游 DNS 查询将导致出现永久 `UNREPLIED` `conntrack` `iptables` 成对条目的问题。
  ([Issue #46935](https://github.com/istio/istio/issues/46935))

- **修复** 修复了自动分配会指派不正确 IP 的问题。
  ([Issue #47081](https://github.com/istio/istio/issues/47081))

- **修复** 修复了根 `VirtualService` 中的多个标头匹配生成不正确路由的问题。
  ([Issue #47148](https://github.com/istio/istio/issues/47148))

- **修复** 修复了 `ServiceEntry` 通配符基于 `glibc` 容器的搜索域后缀 DNS 代理解析的问题。
  ([Issue #47264](https://github.com/istio/istio/issues/47264))、
  ([Issue #31250](https://github.com/istio/istio/issues/31250))、
  ([Issue #33360](https://github.com/istio/istio/issues/33360))、
  ([Issue #30531](https://github.com/istio/istio/issues/30531))、
  ([Issue #38484](https://github.com/istio/istio/issues/38484))

- **修复** 修复了仅依赖 `HTTPRoute` 来检查 `ReferenceGrant` 的问题。
  ([Issue #47341](https://github.com/istio/istio/issues/47341))

- **修复** 修复了如果默认 IP 寻址不是 IPv6，
  则正在使用 `IstioIngressListener.defaultEndpoint` 的
  Sidecar 资源无法使用 [::1]:PORT 的问题。
  ([Issue #47412](https://github.com/istio/istio/issues/47412))

- **修复** 修复了多集群 Secret 过滤导致 Istio 从每个命名空间获取 Secret 的问题。
  ([Issue #47433](https://github.com/istio/istio/issues/47433))

- **修复** 修复了导致正在终止的无头服务实例的流量无法正常运行的问题。
  ([Issue #47348](https://github.com/istio/istio/issues/47348))

- **移除** 移除了 `PILOT_ENABLE_DESTINATION_RULE_INHERITANCE` 实验性功能，
  该功能自创建以来默认处于禁用状态。
  ([Issue #37095](https://github.com/istio/istio/issues/37095))

- **移除** 从 Envoy 构建中移除了自定义 Istio 网络过滤器
  `forward_downstream_sni`、`tcp_cluster_rewrite` 和 `sni_verifier`。
  此功能可以使用 Wasm 扩展性来实现。

- **移除** 移除了工作负载必须具有与其关联的 `Service` 才能实现局部负载均衡的要求。

## 安全性 {#security}

- **新增** 添加了通过 `targetRef` 字段将`RequestAuthentication`
  附加到 Kubernetes `Gateway` 资源的功能。

- **新增** 添加了对插入根证书轮换的支持。

- **修复** 修复了当自定义外部授权服务出现问题时所有请求都被拒绝的问题。
  现在，只有委托给自定义外部授权服务的请求才会被拒绝。
  ([Issue #46951](https://github.com/istio/istio/issues/46951))

## 遥测 {#telemetry}

- **新增** 添加了通过 `targetRef` 字段将 `Telemetry`
  附加到 Kubernetes `Gateway` 资源的功能。
  ([Issue #46844](https://github.com/istio/istio/issues/46844))

- **新增** 将 xDS 工作负载元数据发现作为后备添加到 TCP 元数据交换过滤器中。
  这需要在代理上启用 `PEER_METADATA_DISCOVERY` 标志，
  并在控制平面上启用 `PILOT_ENABLE_AMBIENT_CONTROLLERS`。

- **新增** 在控制平面上添加了 `PILOT_DISABLE_MX_ALPN` 标志，
  以禁用广播 TCP 元数据交换的 ALPN 令牌`istio-peer-exchange`。

## 可扩展性 {#extensibility}

- **新增** 添加了通过 `targetRef` 字段将 `WasmPlugin`
  附加到 Kubernetes `Gateway` 资源的功能。

## 安装 {#installation}

- **改进** 改进了 OpenShift 集群上的使用，无需向 Istio 和应用程序授予 `anyuid` SCC 权限。

- **更新** 更新了 Kiali 插件至 `v1.76.0` 版。

- **新增** 向网关 Helm Chart 添加了 `volumes` 和 `volumeMounts` 值。

- **新增** 添加了使用 `istioctl` 安装时对 Ztunnel 的基本修订支持。
  ([Issue #46421](https://github.com/istio/istio/issues/46421))

- **新增** 添加了 `PILOT_ENABLE_GATEWAY_API_GATEWAYCLASS_CONTROLLER`
  标志以启用/禁用内置 `GatewayClasses` 的管理。
  ([Issue #46553](https://github.com/istio/istio/issues/46553))

- **新增** 在 CNCF 建立有关双许可 eBPF 字节码的指南后，添加了 eBPF 重定向对 Ambient 的支持。
  <https://github.com/cncf/foundation/issues/474#issuecomment-1739796978>
  ([Issue #47257](https://github.com/istio/istio/issues/47257))

- **新增** 添加了 Helm Values，以便希望使用 Helm 的用户更轻松地安装 Ambient。

- **新增** 默认情况下向 Sidecar 资源添加了 `startupProbe`。
  这可以优化启动时间并最大限度地减少整个 Pod 生命周期的负载。有关详细信息，请参阅升级说明。
  ([Issue #32569](https://github.com/istio/istio/issues/32569))

- **修复** 修复了使用 `--dry-run` 选项安装时资源被误删除的问题。

- **修复** 修复了使用 `empty` 配置文件安装 Istio 时不显示组件信息的问题。

- **修复** 修复了即使资源应用失败，安装过程仍继续而导致意外行为的问题。
  ([Issue #43312](https://github.com/istio/istio/issues/43312))

- **修复** 修复了如果将 `values.global.proxy.image` 设置为自定义镜像，
  则 Waypoint 代理不会注入正确镜像的问题。

- **修复** 修复了当 Istiod 不可用时有时会在未确认的情况下执行 `uninstall` 的问题。

- **移除** 移除了对使用集群内 Operator 安装 `ambient` 配置文件的支持。
  ([Issue #46524](https://github.com/istio/istio/issues/46524))

## istioctl

- **新增** 添加了一个新的 `istioctl dashboard proxy` 命令，
  可用于显示不同代理 Pod 的管理 UI，例如 Envoy、Ztunnel、Waypoint。

- **新增** 添加了 `istioctl experimental precheck` 命令的输出格式选项。
  有效选项为 `log`、`json` 或 `yaml`。

- **新增** 在 `istioctl experimental precheck` 中添加了 `--output-threshold`
  标志来控制消息输出阈值。默认阈值现在是 `warning`，它取代了之前的默认值 `info`。

- **新增** 添加了自动检测 Pilot 监控端口（如果未设置为默认值 `15014`）的支持。
  ([Issue #46652](https://github.com/istio/istio/issues/46652))

- **新增** 在 `istioctl` 中添加了默认命名空间检测的延迟加载，
  以避免通过命令检查 kubeconfig 时不需要 Kubernetes 环境。
  ([Issue #47159](https://github.com/istio/istio/issues/47159))

- **新增** 添加了在 `istioctl proxy-config log` 命令中使用
  `--level <level>` 或 `--level level=<level>` 设置 istio-proxy 日志记录器级别的支持。

- **新增** 添加了一个分析器，用于显示与使用外部控制平面的
  Istio 安装相关的不正确/缺失信息的警告消息。
  ([Issue #47269](https://github.com/istio/istio/issues/47269))

- **新增** 添加了 IST0162 `GatewayPortNotDefinedOnService`
  消息以检测 `Service` 未公开 `Gateway` 端口的问题。

- **修复** 修复了 `istioctl operator remove`
  命令在修订版为“默认”或未指定时不删除 Operator 控制器的所有修订版的问题。
  ([Issue #45242](https://github.com/istio/istio/issues/45242))

- **修复** 修复了当安装的 Deployment 不健康时，`verify-install` 结果不正确的问题。

- **修复** 修复了 `istioctl experimental describe` 命令，
  用于在使用注入网关时提供正确的 `Gateway` 信息。

- **修复** 修复了 `istioctl analyze` 会分析不相关的配置映射的问题。
  ([Issue #46563](https://github.com/istio/istio/issues/46563))

- **修复** 修复了当跨命名空间边界在 `VirtualService` 目标中使用 `ServiceEntry` 主机时，
  `istioctl analyze` 异常报错的问题。
  ([Issue #46597](https://github.com/istio/istio/issues/46597))

- **修复** 修复了如果未提供 EDS 端点，`istioctl proxy-config` 无法处理文件中的配置转储的问题。
  ([Issue #47505](https://github.com/istio/istio/issues/47505))

- **移除** 移除了 `istioctl Experimental revision tag` 命令，
  该命令已升级为 `istioctl tag`。
