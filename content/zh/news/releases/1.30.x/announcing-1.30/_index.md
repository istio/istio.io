---
title: 发布 Istio 1.30.0
linktitle: 1.30.0
subtitle: 大版本更新
description: Istio 1.30 发布公告。
publishdate: 2026-05-18
release: 1.30.0
aliases:
    - /zh/news/announcing-1.30
    - /zh/news/announcing-1.30.0
---

我们很高兴地宣布 Istio 1.30 正式发布。感谢所有的贡献者、测试人员、用户及爱好者，
正是得益于你们的协助，我们才得以顺利发布 1.30.0 版本！在此，
我们要特别感谢本次发布的版本管理者：来自 Solo.io 的 **Petr McAllister**、
来自 Red Hat 的 **Jacek Ewertowski** 以及来自 Microsoft 的 **Jackson Greer**。

{{< relnote >}}

{{< tip >}}
Istio 1.30.0 已正式支持 Kubernetes 1.32 至 1.36 版本。
{{< /tip >}}

## 新特性 {#whats-new}

### Agentgateway：实验性新网关实现 {#agentgateway-experimental-new-gateway-implementation}

Istio 1.30 版本新增了对 [agentgateway](https://agentgateway.dev) 的实验性支持，
将其作为 Gateway API 的一种实现。Agentgateway 是一款专为 AI
代理（AI agent）和 MCP 服务器流量构建的新型数据平面代理；
启用后，它将替代网关 Pod 中的 Envoy 代理。在此版本中，
它被配置为一个独立的 `GatewayClass`（即 `istio-agentgateway`），
且仅支持作为 Gateway API 网关使用，不支持作为 Sidecar 或 waypoint 部署。
若要启用此功能，请在 istiod 上设置环境变量 `PILOT_ENABLE_AGENTGATEWAY=true`。
有关安装和配置的详细信息，请参阅 [agentgateway Kubernetes 文档](https://agentgateway.dev/docs/kubernetes/latest/)。
请注意，这是一项早期体验功能，目前可能尚存一些待完善之处；欢迎用户提供反馈意见。

### Gateway API 与 TLSRoute 改进 {#gateway-api-and-tlsroute-improvements}

此版本新增了对 [`TLSRoute`](https://gateway-api.sigs.k8s.io/api-types/tlsroute/) 终止及混合模式的支持，
支持在东西向网关上配置 TLS 透传监听器，并在 `Gateway` 状态中报告已挂载的 `ListenerSets` 和路由。
综合来看，这些变更使 Istio 的 Gateway API 实现更加接近与上游规范的功能对等，
并提升了多租户网关场景下的可操作性。

### Ambient 模式增强功能 {#ambient-mode-enhancements}

1.30 版本新增了多项 Ambient 特性：

- **`ServiceEntry` 支持 CIDR 地址**。`ServiceEntry` 资源现在可以使用 CIDR 地址来指定端点，
  从而无需逐一列举具体工作负载，即可为特定 IP 范围启用 Ambient 路由。
- **在 waypoint 处可选合成 XFCC**。通过在 Waypoint Gateway 上添加注解
  `ambient.istio.io/xfcc-include-client-identity: "true"`，
  该 waypoint 即可利用 ztunnel 提供的源工作负载 SPIFFE 身份来合成
  `x-forwarded-client-cert` 头部，从而使上游应用程序能够识别出原始客户端。
- **可配置的 HBONE 窗口大小**：通过 `PILOT_HBONE_INITIAL_STREAM_WINDOW_SIZE`
  和 `PILOT_HBONE_INITIAL_CONNECTION_WINDOW_SIZE` 进行设置，
  有助于针对高吞吐量的 Ambient 工作负载对 HBONE CONNECT 集群进行调优。
- **ztunnel 中的 Tokio 运行时指标**，以提供更清晰的单实例资源可见性。
- **新增 [Sidecar 到 Ambient 模式迁移指南](/zh/docs/ambient/migrate/)**。这是一份分步指南，
  旨在指导您将现有的基于 Sidecar 的服务网格迁移至 Ambient 模式，
  内容涵盖 Ambient 组件的安装、策略迁移以及按命名空间启用等环节。
  该迁移过程被设计为渐进式且可逆的，在迁移期间，基于 Sidecar 和基于 Ambient 的工作负载可以共存。

### 流量管理新增功能 {#traffic-management-additions}

- **命名空间级流量分配注解**。当服务未显式设置流量分配规则时，
  将继承命名空间层面的注解配置，从而减少了每个服务的样板配置。
- **`ServiceEntry` 上的 `istio.io/connect-strategy` 注解**，
  配合 `RACE_FIRST_TCP_CONNECT` 模式使用；当 DNS 返回多个 A 记录，
  且客户端需要选取首个成功完成 TCP 连接的端点时，此注解非常有用。
- **DNS 上游超时**现可通过 `DNS_FORWARD_TIMEOUT` 进行配置，并保留了现有的 `5s` 默认值。
- 支持 DNS 集群的**DNS 故障转移优先级**。
- **每个工作负载支持多个自定义授权提供程序**，从而能够在不同的 API 路径上启用不同的身份验证方案（OAuth、LDAP、API 密钥）。
- **[`TrafficExtension` API](/zh/blog/2026/traffic-extension-api/)**, a single unified API for configuring Wasm and Lua extensions on Envoy-based sidecars, gateways, and waypoints, replacing `WasmPlugin` as the primary proxy extensibility mechanism.
- **[`TrafficExtension` API](/zh/blog/2026/traffic-extension-api/)**：一套统一的 API，
  用于在基于 Envoy 的 Sidecar、网关和 waypoint 上配置 Wasm 和 Lua 扩展，
  取代 `WasmPlugin` 成为主要的代理扩展机制。

### Helm v4 支持 {#helm-v4-support}

Istio 1.30 新增了对 Helm v4（服务器端应用）的支持。此外，升级过程中 Webhook
`failurePolicy` 字段所有权归属这一长期存在的问题也已得到解决。
使用 Helm v4 的用户现在应能顺畅完成升级，无需再依赖此前的变通方案。

### 安全 {#security}

- **调试端点认证强化。** 当 `ENABLE_DEBUG_ENDPOINT_AUTH=true`（默认设置）时，
  端口 15010 上的 XDS 调试端点（`syncz`、`config_dump`）现已强制要求进行认证。
  新增的 `DEBUG_ENDPOINT_AUTH_ALLOWED_NAMESPACES` 配置项允许运维人员在系统命名空间之外，
  额外放行特定的命名空间。有关此项破坏性变更的详细信息，请参阅[升级说明](upgrade-notes/)。
- `pilot-discovery` 的 **TLS 最低版本标志**（`--tls-min-version`），
  允许运维人员提高控制平面 TLS 的最低版本要求。
- Istio 镜像的**默认仓库**现已更改为 `registry.istio.io`。旧的仓库仍可访问，但新安装将默认使用新位置。

### 安装与可操作性 {#installation-and-operability}

- **网络网关服务的可配置端口覆盖功能**：通过 `networkGatewayPorts` Helm 值实现；
  此外新增模板验证机制，若 `service.ports` 为空且未设置 `networkGateway`，则会提前报错。
- **`WorkloadEntry` 资源上的 `WaypointBound` 状态条件**：用于报告每个工作负载当前是否已绑定到 Waypoint。
- **ztunnel Helm Chart 中的 `dnsPolicy` 和 `dnsConfig` 字段**：专为非标准 DNS 环境设计。
- **istio-cni Helm Chart 中的 `useAppArmorAnnotation` 字段**：默认为 `true`。
- **`global.enableReaderRBAC` 字段**（默认为 `true`）：用于控制是否安装 Reader RBAC 权限。

### 遥测 {#telemetry}

- 服务属性丰富功能现已遵循 OpenTelemetry 语义约定，
  包括支持 `app.kubernetes.io/name` 和 `service.istio.io/canonical-name`。
- Telemetry Tracing API 中新增了 `disableContextPropagation` 字段，
  适用于 Istio 不应传播追踪上下文的环境。
- ztunnel Grafana 仪表板新增了“资源使用”面板，
  用于展示每个实例的活跃 TCP 连接数、打开的文件描述符数以及打开的套接字数。

### 以及更多内容 {#plus-much-more}

- **istioctl** 改进：包括新增并贯通 `--tls-min-version` 参数、修复连接输出的排序问题、
  提供 distroless 版本的 istioctl 镜像，以及对 `ztunnel-config` 命令的优化。
- **CNI** 改进：修复了针对 AWS EKS 中使用“Pod 安全组”（即分支 ENI）的
  Ambient 模式 Pod 的 kubelet 探针问题（该修复受 `AMBIENT_ENABLE_AWS_BRANCH_ENI_PROBE` 特性开关控制，默认为开启）；
  新增对 `excludeInterfaces` 参数的输入校验；以及对协调逻辑的微调。
- **Wasm**：支持配置二进制文件大小上限、支持配置 gzip 解压大小上限，
  并针对 Wasm 资源获取过程增加了 SSRF 防护机制。
- **多集群**：支持从本地文件系统路径加载远程 `Secret` 资源。

欲了解这些及更多内容，请阅读完整的[发布说明](change-notes/)。

## 升级至 1.30 {#upgrading-to-1.30}

我们非常希望能听到您关于升级至 Istio 1.30 的体验反馈。
您可以在我们的 [Slack 工作区](https://slack.istio.io/)中的 `#release-1_30` 频道提供反馈。

您想直接为 Istio 做出贡献吗？请查找并加入我们的
[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一，协助我们进行改进。
