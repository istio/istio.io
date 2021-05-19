---
title: "为企业应用程序启用深度防御"
opening_paragraph: "Istio 的流量管理模型依靠与服务一起部署的 Envoy 代理。网格服务发送和接收的所有流量（数据平面流量）都通过 Envoy 进行代理，从而可以轻松引导和控制网格网络周围的流量，而无需对服务进行任何更改。"
image: "defense.svg"
skip_toc: true
doc_type: article
sidebar_force: sidebar_solution
type: solutions
---

[comment]: <> (TODO: Replace placeholders)
跨服务的度量标准和可追溯性标准化，从而提高了可靠性，而没有增加页面疲劳或未处理数据的繁重负荷。

SRE 建立在服务的可观测性之上。成功的 SRE 需要明确的、可操作的数据:

- 关键信号作为短期可用性的警报
- 历史分析以设计以实现长期可用性

需要为所有服务（可能是所有 Pod）收集和查看延迟、流量、错误和饱和度等相同的黄金信号。

## 涉及谁 {#who-is-involved}

<div class="multi-block-wrapper">
{{< multi_block header="SRE 团队" icon="people" >}}
通过短期补救和长期服务改善，构建实现服务水平最佳实践的目标。
{{< /multi_block >}}
{{< multi_block header="Devops 团队" icon="people" >}}
开发人员负责组织中部分服务的构建，部署和操作。
{{< /multi_block >}}
</div>

## 其他利益相关者 {#additional-stakeholders}

<div class="multi-block-wrapper">
{{< multi_block header="平台所有者" icon="person" >}}
（如果与SRE团队分离）
{{< /multi_block >}}
{{< multi_block header="Devops TeBusiness 所有者" icon="person" >}}
以及相关的服务水平协议
{{< /multi_block >}}
</div>

## 前提条件 {#preconditions}

- 微服务架构，例如 Kubernetes 部署或基于 VM 的实现。
- DevOps 实践到位。

## 工作流程 {#workflow}

建立 Istio 代理和服务级别指标，收集 Envoy 统计信息并传递给 Prometheus。Grafana 标准化仪表板可供团队使用。以及实施分布式追踪。

考虑实施Kiali

如果度量指标正在创建过多的数据和流量，请实施联合 Prometheus 服务器以汇总规则。

## 代理级别 {#proxy-Level}

代理级别、服务级别和追踪指标以标准化方式提供。警报和传输是可行的，不会拖延工程师的前瞻性工作。

{{< figure src="/img/service-mesh.svg" alt="Service mesh" >}}