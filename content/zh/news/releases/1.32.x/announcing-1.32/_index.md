---
title: 发布 Istio 1.32.0
linktitle: 1.32.0
subtitle: 大版本更新
description: Istio 1.32 发布公告。
publishdate: 2026-11-09
release: 1.32.0
aliases:
    - /zh/news/announcing-1.32
    - /zh/news/announcing-1.32.0
---

我们很高兴地宣布 Istio 1.32 发布。感谢所有贡献者、测试人员、
用户和爱好者帮助我们发布 1.32.0 版本！我们要感谢此版本的发布经理，
来自 Microsoft 的 **Jackson Greer**、来自 Tetrate 的 **Jianpeng He**
和来自 Solo.io 的 **Jack Kawell**。

{{< relnote >}}

{{< tip >}}
Kubernetes 版本 1.33 至 1.37 正式支持 Istio 1.32.0。
{{< /tip >}}

## 新特性 {#whats-new}

### Gateway API {#gateway-api}

- **以 `HTTPRoute` 为目标的 `AuthorizationPolicy`。**作为一项实验性功能，
  `AuthorizationPolicy` 现在可以通过 `targetRefs` 以 Gateway API `HTTPRoute` 资源为目标，
  使 `ALLOW` 和 `DENY` 规则仅应用于该路由匹配的流量。
- **网关上的 TLS 调优。**终止 TLS 的网关可以通过 `alpnProtocols` 覆盖所通告的 ALPN 协议，
  并通过 `ecdhCurves` 配置 ECDH 曲线。
- **实验性的 `XBackend` 支持**，用于描述客户端连接到特定目标时必须采用的方式。
- **`agentgateway`** 现在会遵循 Gateway API 前端客户端证书验证。

### Ambient 模式 {#ambient-mode}

- **混合网格只需一个东西向网关。**`istio-east-west` 网关现在还可以通过端口 15443 上的
  `AUTO_PASSTHROUGH` 监听器为 Sidecar 多网络流量提供服务，
  因此同时包含 Ambient 和 Sidecar 工作负载的网格不再需要在每个集群中为 Sidecar 单独部署东西向网关。
  此功能要求启用 `AMBIENT_ENABLE_MULTI_NETWORK`。

### 流量管理 {#traffic-management}

- **基于利用率的负载均衡。**`DestinationRule` 上新的 `backendUtilization` 策略
  使用后端上报的 ORCA 负载报告，向较繁忙的端点发送较少的请求。
- **更丰富的异常值检测。**`DestinationRule.OutlierDetection` 新增了
  `outlierDetectionHttpErrorCodes`（用于选择哪些 HTTP 状态码被计为错误）
  和 `failurePercentageThreshold`（用于根据失败率驱逐主机）。
- **可配置的入站重试。**新的 `defaultInboundHttpRetryPolicy` 网格配置字段用于配置
  Sidecar 入站路由上的默认重试策略，或通过 `{}` 将其禁用。
- **`EnvoyFilter` 传输套接字匹配。**过滤器链匹配现在可以按 `transportSocket` 进行选择，
  使补丁能够精确地指向终止 TLS 的过滤器链。
- **带有选择器的网格范围 `ProxyConfig`。**根命名空间中带有工作负载选择器的
  `ProxyConfig` 资源现在会应用于所有命名空间中匹配的工作负载。

### 安全 {#security}

- **JWT 规则的 `presence`。**`RequestAuthentication` 的 `jwtRules` 可以被标记为 `REQUIRED`，
  即使其他规则已满足，缺少该令牌的请求也会被拒绝。
- **`PILOT_DISABLE_SELF_SIGNED_CA`** 会使 istiod 无法启动其 CA，而不是生成或重用自签名根证书。

### 可观测 {#telemetry}

- **原生 Prometheus 直方图。**当抓取器请求 Prometheus protobuf 格式时，
  `pilot-agent` 的指标合并器会透传该格式，
  并通过新的 `istio_agent_scrape_format_total` 计数器报告协商的格式。

### 还有更多 {#plus-much-more}

- **无头 TCP 服务**可以选择启用单个通配符监听器，而不是为每个 Pod IP 创建一个监听器
- **`IST0178`** 分析器警告：当 `EnvoyFilter` 插入 HTTP 过滤器，
  同时存在以 `HTTPRoute` 为目标的 `AuthorizationPolicy` 时发出警告
- **`ServiceEntry` 验证**会对全匹配地址和范围过宽的地址发出警告
- Istio 组件中的 **Kubernetes API 客户端超时**，可通过 `ISTIO_KUBE_HEADER_TIMEOUT`
  和 `ISTIO_KUBE_REQUEST_TIMEOUT` 进行配置
- 已从所有 Chart 中移除 **`GOMAXPROCS`**，因为 Go 现在会根据 CPU 限制自动设置该值

请阅读完整的[发行说明](change-notes/)，了解这些内容以及更多内容。

## 升级到 1.32 版本 {#upgrading-to-1.32}

我们希望听到您关于升级到 Istio 1.32 的体验。您可以在我们的
[Slack 工作区](https://slack.istio.io/)的 `#release-1_32` 频道中提供反馈。

您想直接为 Istio 做出贡献吗？查找并加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一并帮助我们改进。
