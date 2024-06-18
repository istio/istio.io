---
title: Istio 服务网格
description: 服务网格。
subtitle: Istio 解决了开发人员和运维人员在分布式或微服务架构中面临的挑战。无论您是从头开始构建、将现有应用程序迁移到云原生，还是保护现有资产，Istio 都可以提供帮助。
weight: 34
skip_toc: true
skip_byline: true
skip_pagenav: true
aliases:
    - /zh/service-mesh.html
    - /zh/docs/concepts/what-is-istio/overview
    - /zh/docs/concepts/what-is-istio/goals
    - /zh/about/intro
    - /zh/docs/concepts/what-is-istio/
    - /zh/latest/docs/concepts/what-is-istio/
doc_type: about
---

{{< centered_block >}}
{{< figure src="/zh/about/service-mesh/service-mesh.svg" alt="服务网格" title="通过使用应用程序代理，Istio 让您可以在网络中编程应用程序感知的流量管理、令人难以置信的可观察性和强大的安全功能。" >}}
{{< /centered_block >}}

{{< centered_block >}}

[comment]: <> (下面的标题仅在此处，因为 lint 要求第一个标题是 <h2>，而稍后我们需要 <h1>。)

## Istio 介绍 {#what-is-Istio}

**服务网格**是一个基础设施层，它为应用程序提供零信任安全、可观察性和高级流量管理等功能，
而无需更改代码。**Istio** 是最受欢迎、最强大、最值得信赖的服务网格。
Istio 由 Google、IBM 和 Lyft 于 2016 年创立，是云原生计算基金会的一个毕业项目，
与 Kubernetes 和 Prometheus 等项目并列。

Istio 可确保云原生和分布式系统具有弹性，帮助现代企业在保持连接和保护的同时跨不同平台维护其工作负载。
它[启用安全和治理控制](/zh/docs/concepts/observability/)，包括 mTLS 加密、策略管理和访问控制、
[支持网络功能](/zh/docs/concepts/traffic-management/)，例如金丝雀部署、A/B 测试、负载平衡、故障恢复，
并[增加对整个资产流量的可观察性](/zh/docs/concepts/observability/)。

Istio 并不局限于单个集群、网络或运行时的边界——在 Kubernetes 或 VM、多云、混合或本地上运行的服务都可以包含在单个网格中。

Istio 经过精心设计，具有可扩展性，并受到贡献者和合作伙伴的[广泛生态系统](/zh/about/ecosystem)的支持，
它为各种用例提供​​打包的集成和分发。您可以独立安装 Istio，也可以选择由提供基于 Istio 的解决方案的商业供应商提供的托管支持。

<div class="cta-container">
    <a class="btn" href="/zh/docs/overview/">了解有关 Istio 的更多信息</a>
</div>

{{< /centered_block >}}

<br/><br/>

# 特性 {#features}

{{< feature_block header="默认安全" image="security.svg" >}}
Istio 提供基于工作负载身份、双向 TLS 和强大策略控制的市场领先零信任解决方案。
Istio 在开源中实现了 [BeyondProd](https://cloud.google.com/security/beyondprod/) 的价值，同时避免了供应商锁定或 SPOF。

<a class="btn" href="/zh/docs/concepts/security/">了解安全性</a>
{{< /feature_block>}}

{{< feature_block header="提高可观察性" image="observability.svg" >}}
Istio 在服务网格内生成可观测数据，从而实现对服务行为的可观察性。
它与 Grafana 和 Prometheus 等 APM 系统集成，为操作员提供有洞察力的指标，以排除故障、维护和优化应用程序。

<a class="btn" href="/zh/docs/concepts/observability/">了解可观察性</a>
{{< /feature_block>}}

{{< feature_block header="管理流量" image="management.svg" >}}
Istio 简化了流量路由和服务级别配置，允许轻松控制服务之间的流量以及设置 A/B 测试、金丝雀部署和基于百分比流量分割的分阶段推出等任务。

<a class="btn" href="/zh/docs/concepts/traffic-management/">了解流量管理</a>
{{< /feature_block>}}

<br/><br/>

# 为什么选择 Istio？ {#why-istio}

{{< feature_block header="多种部署模式" image="deployment-modes.svg" >}}
Istio 提供两种数据平面模式供用户选择。使用新的 Ambient 模式部署可简化应用程序的运行生命周期，或使用传统的 Sidecar 进行复杂配置。

<a class="btn" href="/zh/docs/overview/dataplane-modes/">了解数据平面模式</a>
{{< /feature_block>}}

{{< feature_block header="由 Envoy 提供支持" image="envoy.svg" >}}
Istio 建立在适用于云原生应用的行业标准网关代理之上，具有高性能和可扩展性。使用 WebAssembly 添加自定义流量功能，或集成第三方策略系统。

<a class="btn" href="/zh/docs/overview/why-choose-istio/#envoy">了解 Istio 和 Envoy</a>
{{< /feature_block>}}

{{< feature_block header="真正的社区项目" image="community-project.svg" >}}
Istio 专为现代工作负载而设计，由云原生领域的庞大创新者社区打造。

<a class="btn" href="/zh/docs/overview/why-choose-istio/#community">了解 Istio 的贡献者</a>
{{< /feature_block>}}

{{< feature_block header="稳定的二进制版本" image="stable-releases.svg" >}}
自信地在生产工作负载中部署 Istio。所有版本均可完全免费使用。

<a class="btn" href="/zh/docs/overview/why-choose-istio/#packages">了解 Istio 的打包方式</a>
{{< /feature_block>}}
