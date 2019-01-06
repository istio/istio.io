---
title: 功能状态
description: 功能列表和发布阶段。
weight: 10
icon: feature-status
---

此页面列出了每个 Istio 功能的相对成熟度和支持级别。请注意，阶段（Alpha、Beta 和 Stable）适用于项目中的各个功能，而不是对于整个项目。以下是对这些标签含义的高级描述：

## 功能阶段定义

|            | Alpha      | Beta         | Stable
|-------------------|-------------------|-------------------|-------------------
|   **目的**         | 可以演示，端到端可用，但有一些局限性    | 可用于生产，不再是个玩具了       | 可靠，生产可用
|   **API**         | 不保证向后兼容   | API 是版本化的         | 可靠，生产可用。 API 是版本化的，具有自动版本转换以实现向后兼容性
|  **性能**         | 未量化和保证     | 未量化和保证          | 对性能（延迟/规模）进行量化、记录，并保证不会退化
|   **废弃策略**        | 无     | 弱 - 3 个月         | 严格可靠。更改前将提前 1 年通知

## Istio 功能

以下是我们现有功能及其当前阶段的列表。此信息将在每月发布后更新。

### 流量管理

| 功能           | 阶段
|-------------------|-------------------
| 协议: HTTP1.1 / HTTP2 / gRPC / TCP | Stable
| 协议: Websockets / MongoDB  | Beta
| 流量控制: 基于标签和内容的路由以及流量迁移 | Beta
| 弹性保障: 超时、重试、连接池以及外部检测 | Beta
| 网关: 所有协议的 Ingress, Egress| Beta
| 网关中的 TLS 终结器以及 SNI 支持| Beta
| 在 Envoy 中使用自定义过滤器 | Alpha

### 可观察性

| 功能           | 阶段
|-------------------|-------------------
| [Prometheus 集成](/zh/docs/tasks/telemetry/querying-metrics/) | Stable
| [本地日志记录（STDIO）](/zh/docs/examples/telemetry/) | Stable
| [Statsd 集成](/zh/docs/reference/config/policy-and-telemetry/adapters/statsd) | Stable
| [客户端和服务端的遥测报告](/zh/docs/concepts/policies-and-telemetry/) | Stable
| [Grafana 中的 Service Dashboard](/zh/docs/tasks/telemetry/using-istio-dashboard/) | Beta
| [Grafana 中的 Istio 组件 Dashboard](/zh/docs/tasks/telemetry/using-istio-dashboard/) | Beta
| [Stackdriver 集成](/docs/reference/config/policy-and-telemetry/adapters/stackdriver/) | Alpha
| [SolarWinds 集成](/docs/reference/config/policy-and-telemetry/adapters/solarwinds/) | Alpha
| [Zipkin/Jaeger 的分布式追踪](/zh/docs/tasks/telemetry/distributed-tracing/) | Alpha
| [服务追踪](/zh/docs/tasks/telemetry/distributed-tracing/) | Alpha
| [Fluentd 日志记录](/zh/docs/tasks/telemetry/fluentd/) | Alpha
| [跟踪采样](/zh/docs/tasks/telemetry/distributed-tracing/overview/#trace-sampling) | Alpha

### 安全和策略实施

| 功能           | 阶段
|-------------------|-------------------
| [Deny Checker](/docs/reference/config/policy-and-telemetry/adapters/denier/)         | Stable
| [List Checker](/docs/reference/config/policy-and-telemetry/adapters/list/)        | Stable
| [插入外部 CA 密钥和证书](/zh/docs/tasks/security/plugin-ca-cert/)| Stable
| [服务间的双向 TLS 认证](/zh/docs/concepts/security/#双向-tls-认证)         | Stable
| [Kubernetes：服务凭证分发](/zh/docs/concepts/security/#双向-TLS-认证)   | Stable
| [VM：服务凭证分发](/zh/docs/concepts/security/#pki)         | Beta
| [双向 TLS 的迁移](/zh/docs/tasks/security/mtls-migration)    | Beta
| [认证策略](/zh/docs/concepts/security/#认证策略)  | Alpha
| [最终用户（JWT）认证](/zh/docs/concepts/security/#认证)  | Alpha
| [OPA Checker](/docs/reference/config/policy-and-telemetry/adapters/opa/)    | Alpha
| [RBAC)](/zh/docs/concepts/security/#授权和鉴权)   | Alpha

### 核心

| 功能           | 阶段
|-------------------|-------------------
| [Kubernetes：Envoy 安装和流量拦截](/zh/docs/setup/kubernetes/)        | Stable
| [Kubernetes：Istio 控制平面安装](/zh/docs/setup/kubernetes/) | Stable
| [属性表达语言](/zh/docs/reference/config/policy-and-telemetry/expression-language/)        | Stable
| [Mixer 适配器认证模型](/zh/blog/2017/adapter-model/)        | Stable
| [Helm](/zh/docs/setup/kubernetes/helm-install/) | Beta
| [多集群安装](/zh/docs/setup/kubernetes/multicluster-install/) | Alpha
| [Kubernetes：Istio 控制平面升级](/zh/docs/setup/kubernetes/) | Beta
| [Consul 集成](/zh/docs/setup/consul/quick-start/) | Alpha
| 基本配置资源校验  | Alpha
| [Mixer 遥测收集（追踪、日志记录、监控）](/help/faq/mixer/#mixer-self-monitoring) | Alpha
| [自定义 Mixer 构建模型](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide) | Alpha
| [进程外 Mixer 适配器（ gRPC Adapters ）](https://github.com/istio/istio/wiki/Mixer-Out-Of-Process-Adapter-Dev-Guide) | Alpha

> {{< idea_icon >}}
>
> 如果您希望未来的版本中具有某些功能，请加入[社区](/zh/about/community/)与我们联系！
