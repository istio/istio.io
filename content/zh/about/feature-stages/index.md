---
title: 功能状态
description: List of features and their release stages.
weight: 10
aliases:
    - /zh/docs/reference/release-roadmap.html
    - /zh/docs/reference/feature-stages.html
    - /zh/docs/welcome/feature-stages.html
    - /zh/docs/home/roadmap.html
icon: feature-status
---

此页面列出了每个功能的相对成熟度和支持等级。请注意，状态（Alpha，Beta 和 Stable）描述的是项目中的各个功能，而不是项目本身。这是这些标签的详细描述。

## 功能状态定义{#feature-phase-definitions}

|            | Alpha      | Beta         | Stable
|-------------------|-------------------|-------------------|-------------------
|   **目的**         | 可演示，端到端工作，但是有局限性。如果您在生产环境中遇到了严重的问题，我们可能无法为您修复，如果需要继续使用，请禁用。 | 生产环境可用。 | 可靠，生产环境可用。
|   **API**         | 不保证向后兼容   | API 已版本化       | 可靠，生产环境可用。 API 已版本化， 具有自动版本转换来实现向后兼容。
|  **行为**         | 没有量化或不保证     | 未量化或不保证       | 能力（latency/scale）已经量化、文档输出并保证不会出现降级情况。
|   **弃用策略**        | 无     | 弱 - 3个月         | 可信，稳定。 变更时，提前一年通知

| **安全性** | 安全漏洞将按照简单地错误修复程序公开处理 | 安全漏洞将根据我们的[安全漏洞处理规范](/zh/about/security-vulnerabilities/)进行处理 | 安全漏洞将根据我们的[安全漏洞处理规范](/zh/about/security-vulnerabilities/)进行处理

## Istio 功能{#istio-feature}

以下是我们现有的功能及其当前状态的列表。该信息将在每个月发行一次之后更新。

### 流量管理{#traffic-management}

| 功能           | 状态
|-------------------|-------------------
| 协议: HTTP1.1 / HTTP2 / gRPC / TCP | Stable
| 协议: Websockets / MongoDB  | Stable
| 流量控制: 基于标签/内容的路由, 流量切换 | Stable
| 谈性功能: 超时， 重试， 连接池，异常检测 | Stable
| 网关: 所有协议的出口入口 | Stable
| 网关的 TLS 终止和 SNI 支持 | Stable
| Ingress 的 SNI（多证书） | Stable
| [局部负载均衡](/zh/docs/ops/configuration/traffic-management/locality-load-balancing/) | Beta
| 在 Envoy 中启用自定义过滤器 | Alpha
| CNI 容器接口 | Alpha
| [Sidecar API](/zh/docs/reference/config/networking/sidecar/) | Beta
| [DNS 代理](/zh/docs/ops/configuration/traffic-management/dns-proxy/) | Alpha
| [Kubernetes service-apis](/zh/docs/tasks/traffic-management/ingress/service-apis/) | Alpha

### 可观察性{#observability}

| 功能           | 状态
|-------------------|-------------------
| [Prometheus 集成](/zh/docs/tasks/observability/metrics/querying-metrics/) | Stable
| [客户端与服务端的遥测报告](/zh/docs/reference/config/policy-and-telemetry/) | Stable
| [Grafana 的服务仪表盘](/zh/docs/tasks/observability/metrics/using-istio-dashboard/) | Stable
| [分布式链路追踪](/zh/docs/tasks/observability/distributed-tracing/) | Stable
| [Stackdriver 集成](/zh/docs/reference/config/policy-and-telemetry/adapters/stackdriver/) | Beta
| [分布式链路追踪：Zipkin / Jaeger](/zh/docs/tasks/observability/distributed-tracing/) | Beta
| [链路追踪样本](/docs/tasks/observability/distributed-tracing/configurability/#trace-sampling) | Beta
| [请求分类](/docs/tasks/observability/metrics/classify-metrics/) | Beta

### 扩展性{#extensibility}

| 功能           | 状态
|-------------------|-------------------
| WebAssembly 扩展 | Alpha

### 安全和策略执行{#security-and-policy-enforcement}

| 功能           | 状态
|-------------------|-------------------
| [Istio CA 的可插拔秘钥、证书支持](/zh/docs/tasks/security/plugin-ca-cert/)        | Stable
| [双向 TLS](/zh/docs/concepts/security/#mutual-TLS-authentication)         | Stable
| [Kubernetes: 服务凭证分发](/zh/docs/concepts/security/#PKI)   | Stable
| [VM: 服务凭证分发](/zh/docs/concepts/security/#PKI)         | Beta
| [双向 TLS 迁移](/zh/docs/tasks/security/authentication/mtls-migration)    | Beta
| [Ingress Gateway 的证书管理](/zh/docs/tasks/traffic-management/ingress/secure-ingress-sds) | Beta
| [授权 ](/zh/docs/concepts/security/#authorization)   | Beta
| [最终用户（JWT）身份验证](/zh/docs/concepts/security/#authentication)  | Alpha

### 核心{#core}

| 功能           | 状态
|-------------------|-------------------
| [标准操作器](/zh/docs/setup/install/standalone-operator/) | Beta
| [Kubernetes: Envoy 安装和流量拦截](/zh/docs/setup/) | Stable
| [Kubernetes: Istio 控制平面安装](/zh/docs/setup/) | Stable
| [基于 Helm 安装](/zh/docs/setup/install/helm/) | Beta
| [多集群网格](/zh/docs/setup/install/multicluster/) | Alpha
| [Kubernetes: Istio 控制平面升级](/zh/docs/setup/) | Beta
| [外部控制平面](/docs/setup/additional-setup/external-controlplane/) | Alpha
| 基础配置资源验证 | Beta
| [Istio CNI 插件](/zh/docs/setup/additional-setup/cni/) | Alpha
| Kubernetes 支持 IPv6  | Alpha 不能同时启用 IPv4 和 IPv6
| [Istio 的 Distroless 基础镜像](/zh/docs/ops/configuration/security/harden-docker-images/) | Alpha
| [虚机集成](/docs/setup/install/virtual-machine/) | Beta

{{< idea >}}
如果您希望在将来的版本中看到某些功能，请加入我们的[社区](/zh/about/community/)并联系我们。
{{< /idea >}}
