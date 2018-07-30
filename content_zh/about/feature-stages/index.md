---
title: 功能状态
description: 功能列表和发布阶段。
weight: 10
aliases:
    - /docs/reference/release-roadmap.html
    - /docs/reference/feature-stages.html
    - /docs/welcome/feature-stages.html
    - /docs/home/roadmap.html
page_icon: /img/feature-status.svg
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
| [协议： HTTP 1.1](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http_connection_management.html#http-protocols)  | Beta
| [协议： HTTP 2.0](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/http_connection_management.html#http-protocols)  | Alpha
| [协议： gRPC](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/grpc)   | Alpha
| [协议： MongoDB](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/mongo)      | Alpha
| [请求路由](/docs/tasks/traffic-management/request-routing/)      | Alpha
| [故障注入](/docs/tasks/traffic-management/fault-injection/)      | Alpha
| [流量转移](/docs/tasks/traffic-management/traffic-shifting/)      | Alpha
| [熔断](/docs/tasks/traffic-management/circuit-breaking/)      | Alpha
| [镜像](/docs/tasks/traffic-management/mirroring/)      | Alpha
| [Ingress 流量](/docs/tasks/traffic-management/ingress/)      | Alpha
| [Egress 流量](/docs/tasks/traffic-management/egress/)      | Alpha
| [Egress TCP 流量](/blog/2018/egress-tcp/)      | Alpha
| [增强路由规则：组合服务](/docs/reference/config/istio.networking.v1alpha3/) | Alpha
| [配额/Redis 速率限制（Adapter 和 Server）](/docs/tasks/policy-enforcement/rate-limiting/) | Alpha
| [Memquota 实现和集成](/docs/tasks/telemetry/metrics-logs/) | Stable
| [Ingress TLS](/docs/tasks/traffic-management/ingress/) | Alpha
| Egress 策略和遥测 | Alpha

### 可观察性

| 功能           | 阶段
|-------------------|-------------------
| [Prometheus 集成](/docs/tasks/telemetry/querying-metrics/) | Stable
| [本地日志记录（STDIO）](/docs/examples/telemetry/) | Stable
| [Statsd 集成](/docs/reference/config/policy-and-telemetry/adapters/statsd/) | Stable
| [Grafana 中的 Service Dashboard](/docs/tasks/telemetry/using-istio-dashboard/) | Beta
| [Stackdriver 集成](/docs/reference/config/policy-and-telemetry/adapters/stackdriver/) | Alpha
| [SolarWinds 集成](/docs/reference/config/policy-and-telemetry/adapters/solarwinds/) | Alpha
| [Service Graph](/docs/tasks/telemetry/servicegraph/) | Alpha
| [Zipkin/Jaeger 的分布式追踪](/docs/tasks/telemetry/distributed-tracing/) | Alpha
| [Grafana 中的 Istio 组件 Dashboard](/docs/tasks/telemetry/using-istio-dashboard/) | Beta
| [服务追踪](/docs/tasks/telemetry/distributed-tracing/) | Alpha
| [Fluentd 日志记录](/docs/tasks/telemetry/fluentd/) | Alpha
| [Client & Server 遥测报告](/docs/concepts/policies-and-telemetry/) | Stable

### 安全

| 功能           | 阶段
|-------------------|-------------------
| [Deny Checker](/docs/reference/config/policy-and-telemetry/adapters/denier/)         | Stable
| [List Checker](/docs/reference/config/policy-and-telemetry/adapters/list/)        | Stable
| [Kubernetes：服务凭证分发](/docs/concepts/security/#mutual-tls-authentication)   | Stable
| [Istio CA 的可拔插 Key/Cert 支持](/docs/tasks/security/plugin-ca-cert/)        | Stable
| [服务间相互 TLS](/docs/concepts/security/#mutual-tls-authentication)         | Stable
| [认证策略](/docs/concepts/security/#authentication-policies)  | Alpha
| [End User（JWT）认证](/docs/concepts/security/#authentication)  | Alpha
| [VM：服务凭证分发](/docs/concepts/security/#key-management)         | Beta
| [增量 mTLS](/docs/tasks/security/mtls-migration)    | Beta
| [OPA Checker]({{< github_file >}}/mixer/adapter/opa/README.md)    | Alpha
| [认证（RBAC）](/docs/concepts/security/#authorization)   | Alpha

### Core

| 功能           | 阶段
|-------------------|-------------------
| [Kubernetes：Envoy 安装和流量拦截](/docs/setup/kubernetes/)        | Beta
| [Kubernetes：Istio 控制平面安装](/docs/setup/kubernetes/) | Beta
| [Kubernetes：Istio 控制平面升级](/docs/setup/kubernetes/) | Beta
| [Pilot 集成 Kubernetes 服务发现](/docs/setup/kubernetes/)         | Stable
| [属性表达语言](/docs/reference/config/policy-and-telemetry/expression-language/)        | Stable
| [Mixer Adapter Authoring Model](/blog/2017/adapter-model/)        | Stable
| [VM：Envoy 安装、流量拦截和服务注册](/docs/examples/integrating-vms/)    | Alpha
| [VM：Istio 控制平面安装和升级（Galley、 Mixer、 Pilot、CA）](https://github.com/istio/istio/issues/2083)  | Alpha
| VM：Ansible Envoy 安装、拦截和注册 | Alpha
| [Pilot 集成 Consul](/docs/setup/consul/quick-start/) | Alpha
| [Pilot 集成 Cloud Foundry 服务发现](/docs/setup/consul/quick-start/)    | Alpha
| [基本配置资源验证](https://github.com/istio/istio/issues/1894) | Alpha
| [Mixer 遥测收集（追踪、日志记录、监控）](/help/faq/mixer/#mixer-self-monitoring) | Alpha
| [自定义 Mixer 构建模型](https://github.com/istio/istio/wiki/Mixer-Compiled-In-Adapter-Dev-Guide) | Alpha
| [进程外 Mixer 适配器](https://github.com/istio/istio/wiki/Out-Of-Process-gRPC-Adapter-Dev-Guide) | Alpha
| 使用 IDL 启用 API 属性 | Alpha
| [Helm](/docs/setup/kubernetes/helm-install/) | Beta
| [多集群 Mesh](/docs/setup/kubernetes/multicluster-install/) | Alpha

> {{< idea_icon >}}
>
> 如果您希望未来的版本中具有某些功能，请加入[社区](/about/community/)与我们联系！