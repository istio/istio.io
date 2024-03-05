---
title: 部署
description: 部署。
subtitle: 阅读有关在第 1 天、第 2 天和第 1000 天快速有效实施的良好实践。
weight: 34
skip_toc: true
skip_byline: true
skip_pagenav: true
aliases:
  - /zh/deployment.html
doc_type: about
---

{{< centered_block >}}

您已经决定要使用 Istio。欢迎来到服务网格的世界。祝贺您，您拥有了一个伟大的伙伴！

如果您没用过 Istio，可能要在测试环境中进行试用，请参阅我们的[入门指南](/zh/docs/setup/getting-started/)。
这将使您对**流量管理**、**安全**和**可观测性**功能有所了解。

## 自己动手，还是带个向导？ {#do-it-yourself-or-bring-a-guide}

Istio 是开源软件，您可以自行下载和安装。在 Kubernetes 集群上安装网格就像运行一个命令一样简单：

{{< text bash >}}
$ istioctl install
{{< /text >}}

随着新版本的发布，您可以对其进行测试并逐步将它们推广到您的集群中。

许多托管 Kubernetes 服务提供商都可以选择为您自动安装和管理 Istio。
查看我们的[供应商页面](/zh/about/ecosystem/)，看看您的供应商是否支持 Istio。

Istio 还是许多商业服务管理产品的引擎，专家团队随时准备帮助您上手。

有一个不断增长的云原生顾问社区，能够在您的 Istio 之旅中为您提供帮助。
如果您要与 Istio 生态系统的成员一起工作，我们建议您尽早熟悉。
我们的许多合作伙伴和供应商已经在这个项目上工作了很长时间，并且在指导您的旅程中将发挥无价的作用。

## 您应该先启用什么？ {#what-should-you-enable-first}

采用 Istio 有很多重要理由：从为微服务增加安全性到提高应用程序的可靠性。
无论您的目标是什么，最成功的 Istio 实施都是从确定一个用例并解决该用例开始的。
一旦您配置了网格来解决一个问题，您可以轻松启用其他功能，从而增加部署的实用性。

## 我如何将网格映射到我的架构上？ {#how-do-i-map-the-mesh-to-my-architecture}

通过一次添加一个命名空间，逐步将您的服务纳入网格。默认情况下，来自多个命名空间的服务可以相互通信，
但您可以有目的地选择将哪些服务公开给其他命名空间来轻松提高隔离级别。
使用命名空间还可以提高性能，因为配置被缩小了范围。

只要 Pod 可以在网络上相互访问，Istio 就能工作；您甚至可以配置 Istio 网关，作为网络之间的堡垒主机。

在我们的文档中了解[全方位的部署模型](/zh/docs/ops/deployment/deployment-models/)。

现在也是考虑要使用哪些集成的好时机：我们推荐[设置 Prometheus](/zh/docs/ops/integrations/prometheus/#Configuration)
用于服务监控，并使用[与外部服务器的分层联合](/zh/docs/ops/best-practices/observability/)。
如果您的公司的可观测性堆栈是由不同的团队运行的，现在是让他们加入的时候了。

## 第一天，将服务添加到网格中 {#adding-services-to-the-mesh-on-day1}

您的网格现在已配置并准备好接受服务。要做到这一点，您只需在 Kubernetes 给您的命名空间添加标签，
当这些服务被重新部署时，它们现在将包括配置为与 Istio 控制平面对话的 Envoy 代理。

### 配置服务 {#configuring-services}

许多服务开箱即用，但通过向您的 Kubernetes 清单添加一些信息，您可以使 Istio 更加智能。
例如，为 `app` 和 `version` 设置标签将有助于稍后查询指标。

对于常见的端口和协议，Istio 将检测流量类型。如果它无法检测到，它将退回到将流量视为 TCP，
但您可以轻松地[给服务添加流量类型的注解](/zh/docs/ops/configuration/traffic-management/protocol-selection/)。

了解有关[启用应用程序以与 Istio 一起使用](/zh/docs/ops/deployment/requirements/)的更多信息。

### 启用安全性 {#enabling-security}

Istio 将在网格中配置服务以在相互通信时尽可能使用 mTLS。
默认情况下，Istio 将以 `permissive mTLS` 模式运行，这意味着服务将接受加密和未加密的流量，以允许来自非网格服务的流量保持功能。
在所有服务都加入网格后，您可以[改变认证策略，只允许加密流量](/zh/docs/tasks/security/authentication/mtls-migration/)。
然后您可以确定所有流量都已加密。

Istio 将配置网格中的服务，使其在相互交谈时尽可能使用 mTLS。
Istio 默认以"允许的 mTLS" 模式运行，这意味着服务将同时接受加密和未加密的流量，以允许来自非网格服务的流量保持正常流通。
在所有的服务都进入网格后，您可以改变认证策略，只允许加密的流量，然后您可以确定所有的流量都是加密的。

### Istio 的两类 API {#istio's-two-types-of-apis}

Istio 为平台所有者和服务所有者提供 API。根据您扮演的角色，您只需要考虑一个子集。
例如，平台所有者将拥有安装、认证和授权资源。流量管理资源将由服务所有者处理。[了解哪些 API 对您有用](/zh/docs/reference/config/)。

### 在虚拟机上连接服务 {#connect-services-on-virtual-machines}

Istio 不仅适用于 Kubernetes；还可以将虚拟机（或裸机）上的[服务添加到网格](/zh/docs/setup/install/virtual-machine/)中，
以获得 Istio 提供的所有功能，例如 TLS、丰富的遥测和高级流量管理功能。

### 监测您的服务 {#monitor-your-services}

使用 [Kiali](/zh/docs/ops/integrations/kiali/) 检查流经您的网格的流量，或者使用 [Zipkin](/zh/docs/tasks/observability/distributed-tracing/zipkin/)
或 [Jaeger](/zh/docs/tasks/observability/distributed-tracing/jaeger/)追踪请求。

使用 Istio 的默认 [Grafana](/zh/docs/ops/integrations/grafana/) 仪表板，自动报告在网格中运行的服务的关键信号。

## 第二天，操作注意事项 {#operational-considerations-and-day2}

作为平台所有者，您负责安装网格并使其保持最新状态，同时不要对服务团队造成太大的影响。

### 安装 {#installation}

借助 istioctl，您可以使用内置配置文件之一轻松安装 Istio。
当您自定义安装以满足您的要求时，建议使用 IstioOperator 自定义资源（CR）定义您的配置。
这使您可以选择将安装管理工作完全委托给 Istio Operator，而不是使用 istioctl 手动完成。
仅将 IstioOperator CR 用于控制平面，将额外的 IstioOperator CR 用于网关，以提高升级的灵活性。

### 安全升级 {#upgrade-safely}

当发布新版本时，Istio 允许就地升级和金丝雀升级。
在两者之间进行选择，是在简单性和潜在停机时间之间进行权衡。
对于生产环境，推荐使用[金丝雀升级方式](/zh/docs/setup/upgrade/canary/)。
在新的控制和数据平面版本被验证工作后，您可以升级您的网关。

### 监控网格 {#monitor-the-mesh}

Istio 为网格内的所有服务通信生成详细的遥测数据。
这些指标、链路和访问日志对于了解您的应用程序如何交互以及识别所有性能瓶颈至关重要。
使用此信息可帮助您设置熔断器、超时和重试并强化您的应用程序。

就像在网格中运行的应用程序一样，Istio 控制平面组件也会导出指标。
利用这些指标和预配置的 Grafana 仪表板来调整您的资源请求、限制和扩展。

## 加入 Istio 社区 {#join-the-Istio-community}

一旦您运行了 Istio，您就成为了一个大型全球社区的成员。您可以在[我们的论坛](https://discuss.istio.io/)或
[hop on Slack](https://slack.istio.io/) 提问。如果您想改进一些东西，或者有一个功能请求，您可以直接去
[GitHub](https://github.com/istio/istio)。

快乐地网格化！

{{< /centered_block >}}
