---
title: 发布 Istio 1.29.0
linktitle: 1.29.0
subtitle: 大版本更新
description: Istio 1.29 发布公告。
publishdate: 2026-02-16
release: 1.29.0
aliases:
    - /zh/news/announcing-1.29
    - /zh/news/announcing-1.29.0
---

我们很高兴地宣布 Istio 1.29 正式发布。感谢所有贡献者、
测试人员、用户和爱好者们帮助我们发布 1.29.0 版本！
我们还要感谢本次发布的发布经理：来自红帽的 **Francisco Herrera**、
来自微软的 **Darrin Cecil** 以及来自 Solo.io 的 **Petr McAllister**。

{{< relnote >}}

{{< tip >}}
Istio 1.29.0 已正式支持 Kubernetes 1.31 至 1.35 版本。
{{< /tip >}}

## 新特性 {#whats-new}

### Ambient 网格生产就绪增强功能 {#ambient-mesh-production-ready-enhancements}

Istio 1.29 为 Ambient 网格新增了两项默认启用的运维改进：Ambient 工作负载的
DNS 捕获功能现已默认启用，从而提升了安全性和性能，
同时还支持更完善的服务发现和流量管理等高级功能。
此增强功能可确保来自 Ambient 工作负载的 DNS 流量能够通过网格基础架构进行正确的代理。

此外，iptables 规则协调功能现已默认启用，可在 istio-cni `DaemonSet`
升级时自动更新网络规则。这消除了之前为确保现有 Ambient Pod 接收更新的网络配置而需要的手动干预，
从而使 Ambient 网格网络的运行更加流畅可靠，尤其适用于生产环境。

### 增强安全态势 {#enhanced-security-posture}

此版本在多个组件中增强了安全性。ztunnel 现在支持证书吊销列表 (CRL)，
允许在使用外部证书颁发机构时验证并拒绝已吊销的证书。这增强了使用外部 CA 的服务网格部署的安全性。

调试端点授权默认启用，为端口 15014 上的调试端点提供基于命名空间的访问控制。
非系统命名空间现在仅限于特定端点（`config_dump`、`ndsz`、`edsz`）以及相同命名空间的代理，
从而在不影响正常运行的情况下提高了安全性。
**特别感谢 Luntry 的 Sergey KANIBOR 报告调试端点授权问题。**

现在 istiod、istio-cni 和 ztunnel 组件可以使用可选的 NetworkPolicy 部署，
使用户能够部署默认的 `NetworkPolicies`，并启用 `global.networkPolicy.enabled=true`，以增强网络安全。

### 通配符主机的 TLS 流量管理 {#tls-traffic-management-for-wildcard-hosts}

Istio 1.29 引入了对 `ServiceEntry` 资源中通配符主机的 Alpha 支持，
并专门针对 TLS 流量使用 `DYNAMIC_DNS` 解析。它允许基于 TLS 握手中的
SNI（服务器名称指示）进行路由，而无需终止 TLS 连接来检查主机头。

虽然此功能存在潜在的 SNI 欺骗风险，存在重要的安全隐患，
但它在与受信任客户端配合使用时，能够为管理外部 TLS 服务提供强大的功能。此功能需要通过
`ENABLE_WILDCARD_HOST_SERVICE_ENTRIES_FOR_TLS` 功能标志显式启用。

### 性能和可观测性改进 {#performance-and-observability-improvements}

Envoy 指标的 HTTP 压缩功能现已默认启用，可根据客户端的 `Accept-Header`
值自动为 Prometheus 统计信息端点提供压缩（`brotli`、`gzip` 和 `zstd`）。
这既能降低指标收集的网络开销，又能保持与现有监控基础架构的兼容性。

Ambient 网格网络 (Ambient Mesh) 的 Alpha 版本新增了基于数据包的可观测支持，
尤其适用于多网络部署。启用此功能后，通过 `AMBIENT_ENABLE_BAGGAGE` 试点环境变量，
可以确保跨网络流量指标的正确源地址和目标地址归属，从而提高复杂网络拓扑中的可观测性。

### 简化运营和资源管理 {#simplified-operations-and-resource-management}

Istio 1.29 通过 `PILOT_IGNORE_RESOURCES` 环境变量引入了试点资源过滤功能，
使管理员能够将 Istio 部署为仅作为 Gateway API 的控制器，
或部署为包含特定资源子集的控制器。这对于 GAMMA（用于网格管理和维护的 Gateway API）部署尤为重要。

内存管理得到改进，`istiod` 现在会自动将 `GOMEMLIMIT` 设置为内存限制的
90%（通过 `automemlimit` 库），从而降低因内存不足而导致程序崩溃的风险，
同时保持最佳性能。熔断器指标跟踪功能现已默认禁用，
这优化了代理内存使用，同时保留了在需要时启用旧版行为的选项。

### 推理扩展支持升级至 Beta 版 {#inference-extension-support-promoted-to-beta}

Istio 1.29 中已将 [Gateway API 推理扩展](https://gateway-api-inference-extension.sigs.k8s.io/)的支持提升至 Beta 版。
该推理扩展是一个官方的 Kubernetes 项目，它利用新的 `InferencePool` CRD 对象以及现有的
Kubernetes Gateway API 流量管理对象（`Gateway`、`HTTPRoute`），
来优化 Kubernetes 中自托管生成式 AI 模型的部署。

Istio 1.29 符合推理扩展的 `v1.0.1` 版本，
您可以通过启用 `ENABLE_GATEWAY_API_INFERENCE_EXTENSION` 试点环境变量来试用。
未来版本的 Gateway API 推理扩展将在后续的 Istio 版本中得到支持。

请参阅[我们的指南](/zh/docs/tasks/traffic-management/ingress/gateway-api-inference-extension/)和[原始博客文章](/zh/blog/2025/inference-extension-support/)以开始使用。

### 多网络多集群 Ambient 进入 Beta 测试阶段 {#multi-network-multicluster-ambient-goes-beta}

此次版本发布还将 Ambient 多网络多集群功能提升至 Beta 测试阶段。
在增强稳健性和完整性方面进行了大量改进。此次升级的重点在于遥测功能，
解决了其中的一些重要缺陷，包括在 Ambient 数据平面中实现更高级的对等元数据交换。

这意味着解决了多网络遥测中一些令人困惑的情况。例如，在 L4 指标中无法正确报告航点，
以及通过东西向网关穿越不同网络的请求无法完全获取对等信息的情况下。

此外，我们现在还有[快速指南](/zh/docs/ambient/install/multicluster/observability)，
展示了如何在 Ambient 模式下为多网络多集群部署 Prometheus 和 Kiali。

Note that some of these improvements may also be behind the `AMBIENT_ENABLE_BAGGAGE` feature flag mentioned in the sections above, so make sure to enable it if you want to try them out. If you need more information on how to deploy multi-network multicluster using the ambient data-plane, please follow [this guide](/docs/ambient/install/multicluster/multi-primary_multi-network/). You'll find more details about the feature on the [release notes](change-notes/).
请注意，上述部分改进可能也与 `AMBIENT_ENABLE_BAGGAGE` 功能标志有关，
因此如果您想尝试这些改进，请务必启用该标志。
如果您需要更多关于如何使用 Ambient 数据平面部署多网络多集群的信息，
请参阅[此指南](/zh/docs/ambient/install/multicluster/multi-primary_multi-network/)。
您可以在[发行说明](change-notes/)中找到有关此功能的更多详细信息。

请不要忘记与我们分享您的反馈意见！

### 还有更多精彩内容 {#plus-much-more}

- **增强的 istioctl 功能**：为 `istioctl waypoint status` 新增 `--wait` 标志，
  支持 `--all-namespaces` 标志，并改进了代理管理端口规范
- **安装改进**：为 istio-cni Pod 提供可配置的 `terminationGracePeriodSeconds`，
  为网关部署控制器提供安全保障，并支持自定义 Envoy 文件刷新间隔
- **流量管理增强**：支持 gRPC 无代理客户端中的 `LEAST_REQUEST`
  负载均衡和熔断机制，改进了 Ambient 多集群入口路由
- **遥测技术进展**：在航点代理跟踪中识别源和目标工作负载，支持 Zipkin 跟踪提供程序的超时和标头。

请参阅完整的[发行说明](change-notes/)了解这些内容及更多信息。

## 升级到 1.29 {#upgrading-to-1.29}

我们想了解您升级到 Istio 1.29 的体验。您可以在我们 [Slack 工作区](https://slack.istio.io/)的
`#release-1.29` 频道中提供反馈。

您想直接为 Istio 做贡献吗？请查找并加入我们的[工作组](https://github.com/istio/community/blob/master/WORKING-GROUPS.md)之一，帮助我们改进。
