---
title: 发布 Istio 1.31.0
linktitle: 1.31.0
subtitle: 大版本更新
description: Istio 1.31 发布公告。
publishdate: 2026-08-31
release: 1.31.0
aliases:
    - /zh/news/announcing-1.31
    - /zh/news/announcing-1.31.0
---

我们很高兴地宣布 Istio 1.31 发布。感谢所有贡献者、测试人员、
用户和爱好者帮助我们发布 1.31.0 版本！我们要感谢此版本的发布经理，
来自 Red Hat 的 **Jacek Ewertowski**、来自 Microsoft 的 **Jackson Greer**
和来自 Tetrate 的 **Jianpeng He**。

{{< relnote >}}

{{< tip >}}
Kubernetes 版本 1.32 至 1.36 正式支持 Istio 1.31.0。{{< /tip >}}

## 弃用 GCP 基础设施和托管 {#deprecation-of-gcp-infrastructure-and-hosting}

从 Istio 1.31 开始，我们将不再将制品发布到 `gcr.io/istio-release`、
`registry.istio.io` 和 `istio-release.storage.googleapis.com`。

- Docker 镜像仍可在 Docker Hub 上使用。
- Helm Chart 将在 `blob.istio.io/istio-release/charts` 上提供。
- 其他工件将在 `blob.istio.io/istio-release` 上提供。
- OCI Helm Chart 将在 `ghcr.io/istio/release/charts` 上提供。

我们将进行尖叫测试，我们将在短时间内禁用所有 GCP 托管的工件。

首次尖叫测试将于 UTC 时间 2026 年 9 月 15 日下午 3:00 至 4:00 进行。
第二次尖叫测试将于 UTC 时间 2026 年 10 月 13 日下午 3:00 至 6:00 进行。
第三次尖叫测试将于 UTC 时间 2026 年 11 月 17 日下午 3:00 至晚上 9:00 进行。
第四次也是最后一次尖叫测试将于 2026 年 12 月 8 日下午 3:00 UTC 至 2026 年 12 月 9 日下午 3:00 UTC 进行。

有关更多详细信息，请参阅[此博文](/zh/blog/2026/retirement-of-gcp/)。

## 新特性 {#whats-new}

### agentgateway 作为路点 {#agentgateway-as-a-waypoint}

在 1.30 中引入的实验性仅网关支持的基础上，Istio 1.31 添加了 `istio-agentgateway-waypoint` `GatewayClass`，
用于将 [agentgateway](https://agentgateway.dev)
部署为 waypoint 代理。此版本还修复了 agentgateway 后端的 `ListenerSet` 处理和 mTLS 连接的多个问题。

### Gateway API: AllowInsecureFallback

Istio 现在实现了用于客户端证书验证的 Gateway API `AllowInsecureFallback` 功能。
启用后，网关会请求客户端证书并尝试验证它，但如果未提供证书或验证失败，
仍允许连接。填充 `x-forwarded-client-cert` 标头，以便后端可以执行自己的验证。

### Ambient 模式增强 {#ambient-mode-enhancements}

- **加权 waypoint 金丝雀。**服务或命名空间现在可以通过 `istio.io/use-waypoint-canary`
  和 `istio.io/use-waypoint-canary-namespace` 标签引用主路点和金丝雀路点。
  `istio.io/use-waypoint-canary-weight` 注解将网格内连接的可配置份额定向到 Canary waypoint，
  无需任何客户端更改，从而能够逐步推出路点配置更改。
- **多集群稳定性。**此版本包含大量环境模式修复，特别是围绕多集群部署：
  凭证轮换不再导致陈旧快照或丢失端点分片，多集群模式下的多个内存和 goroutine 泄漏已得到解决，
  CNI 节点代理修复解决了并发映射写入恐慌、文件描述符泄漏和 Pod 删除期间的死锁。

### 流量管理新增功能 {#traffic-management-additions}

- **区域感知负载均衡。** `DestinationRule.TrafficPolicy.LoadBalancerSettings`
  和 `MeshConfig` 上的新 `zoneAwareLbSetting` 字段使 Envoy 自动将流量路由到与下游代理相同的可用区域中的端点，
  仅当本地容量不足时才溢出到其他区域。这与现有的`localityLbSetting` 不同，
  区域级路由由 Envoy 自动处理，而不是通过静态百分比处理。跨区域故障转移排序和基于标签的优先级可以分层在顶部。
- **网格范围内的默认流量策略。** `MeshConfig` 中的新 `defaultTrafficPolicy`
  允许网格管理员设置所有出站集群继承的基线 `connectionPool` 和 `outlierDetection`。
  设置这些块之一的 `DestinationRule` 会覆盖该块的基线；
  未设置的字段现在继承网格基线，而不是 Istio 的内置默认值。基线 `connectionPool` 也适用于入站集群和直通集群。
- **未知主机的动态转发代理。** 新的 `ALLOW_ANY_DYNAMIC_DNS`
  出站流量策略模式可在请求时通过 Envoy 的动态转发代理解析 HTTP `Host` 标头中的主机名，
  从而消除每个外部目标对 `ServiceEntry` 资源的需求。非 HTTP 流量继续使用 `PassthroughCluster`。
  可选的上游 TLS 发起可以通过 `meshConfig.outboundTrafficPolicy.tls` 进行配置。
- **Sidecar 出口主机排除。** `Sidecar` 出口侦听器现在支持命名空间和主机条目上的 `~` 前缀，
  以从导入集中减去。例如，`*/*` 加上 `~ns1/*` 导入除名称空间 `ns1` 之外的所有内容。
  这使得大型网格可以排除一些命名空间，而无需枚举很长的白名单。

### 安全 {#security}

- **FIPS 140-3 合规性策略。** `COMPLIANCE_POLICY` 环境变量的新 `fips-140-3`
  值通过符合 FIPS 的密码套件和 P-256/P-384 曲线强制实施 TLS 1.2+。
  Go 组件必须使用 `GOFIPS140=v1.0.0` 使用 Go 1.24+ 构建。
- **`AuthorizationPolicy` 中的信任域匹配。** `Source` 上的新 `trustDomains` 和 `notTrustDomains`
  字段允许根据从对等证书派生的信任域来匹配或排除请求。
- **严格网关合并。** `PILOT_ENABLE_STRICT_GATEWAY_MERGING`（默认启用）可防止
  Istio `Gateway` CRD 与托管 Gateway API `Gateway` 代理的跨命名空间合并。
- **XDS API 生成器身份验证。** MCP 配置服务端点现在需要经过验证的控制平面身份。
  标准 Sidecar、网关和 ztunnel 流量不受影响。

### 安装和操作 {#installation-and-operability}

- **Kiali** 插件更新至 v2.26.0。
- **ztunnel CPU 感知工作线程**通过 `ZTUNNEL_RESOURCE_CPU_LIMIT`
  和 `ZTUNNEL_RESOURCE_CPU_REQUEST` 环境变量。
- **`istioctl 清单生成 -o`** 标志将生成的清单写入文件而不是标准输出。
- **`global.readerServiceAccount`** 允许将 `istio-reader` `ClusterRole` 绑定到自定义服务帐户。

### 可观测 {#telemetry}

- **多目标 Prometheus 抓取。**新的 `prometheus.istio.io/scrape-targets` Pod
  注解允许用户将每个 Pod 的多个应用程序指标端点声明为逗号分隔的 `port:path` 列表。
  Pilot-agent 同时抓取它们并合并输出。
- **安全指标端口。**新的 `ENVOY_SECURE_METRICS_PORT` 和 `ENVOY_SECURE_MERGED_METRICS_PORT`
  环境变量在每个 Sidecar 代理上公开受 mTLS 保护的 Prometheus 抓取端点。
- **Envoy 统计数据合并切换。** `PILOT_AGENT_MERGE_ENVOY_STATS` 可以设置为 `false` 以禁用将 Envoy 统计数据合并到代理统计端点中。

### 还有更多 {#plus-much-more}

- **`ProxyConfig` `connectionSettings`** 具有针对网关代理的固执己见的 `EDGE` 配置文件
- **`MERGE_AND_REPLACE_LIST`** `EnvoyFilter` 补丁操作用于替换列表字段而不是追加
- ****`HTTPRedirect` 中的 `prefix_rewrite`**，用于重定向规则中的前缀感知路径重写
- **HTTP/2 keepalive PING 设置**可通过“DestinationRule”在上游连接上配置
- **`ServiceEntry` 可见性控制**通过 `meshConfig.serviceEntryVisibility`
- **`budget_interval`** 字段 `RetryBudget` `TrafficPolicy` API 中
- **`istioctl analyze`** 针对 `ServiceEntry` 协议冲突和过时的 Gateway API CRD 发出警告

请阅读完整的[发行说明](change-notes/)，了解这些内容以及更多内容。

## 升级到 1.31 版本 {#upgrading-to-1.31}

我们希望听到您关于升级到 Istio 1.31 的体验。您可以在我们的
[Slack 工作区](https://slack.istio.io/)的 `#release-1_31` 频道中提供反馈。

您想直接为 Istio 做出贡献吗？查找并加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一并帮助我们改进。
