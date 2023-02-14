---
title: 部署
description: 部署。
subtitle: 了解有关第1天，第2天和第1000天快速有效实施的良好实践。
weight: 34
skip_toc: true
skip_byline: true
skip_pagenav: true
aliases:
    - /zh/deployment.html
doc_type: about
---
[comment]: <> (TODO: Replace placeholders)

{{< centered_block >}}

你已经决定要使用 Istio 了。欢迎来到服务网格的世界。祝贺你，你是在一个很棒的公司!

如果你还没有尝试过，你可能想在测试环境中尝试一下 Istio，并通过我们的[入门指南](/zh/docs/setup/getting-started/)进行操作。这将使你对**流量管理**、**安全**和**可观测性**功能有一个概念。

## 自己动手，还是带个向导？

Istio 是一个你可以自己下载安装的开源软件。在 Kubernetes 集群上安装服务网格非常简单，只需运行一个命令：

{{< text bash >}}
$ istioctl install
{{< /text >}}

随着新版本的发布，你可以对它们进行测试，并逐步在你的集群中推广。

许多托管的 Kubernetes 服务提供商都提供了自动安装和管理 Istio 的选项。查看我们的[分销商](/zh/about/ecosystem/)页面，看看你的供应商是否支持 Istio。

Istio 还是许多商业服务管理产品的引擎，有专家团队随时准备帮助您使用。

有一个不断增长的云原生顾问社区，他们能够在你的 Istio 旅程中帮助你。如果你要与 Istio 生态系统的成员合作，我们建议你尽早让他们参与进来。我们的许多合作伙伴和经销商已经与该项目合作了很长时间，他们在指导你的旅程方面将是非常有用的。

## 你应该先启用什么？

采用 Istio 有很多很好的理由：从为你的微服务增加安全性到提高你的应用程序的可靠性。无论你的目标是什么，最成功的 Istio 实现都是从确定一个用例并解决它开始的。一旦你配置了网格来解决一个问题，你就可以轻松地启用其他功能，增加部署的实用性。

## 如何将网格映射到我的架构上？

通过一次添加一个命名空间，逐步将你的服务加入到网格中。默认情况下，来自多个命名空间的服务可以相互通信，但你可以通过有选择地选择将哪些服务暴露给其他命名空间来轻松提高隔离度。使用名称空间还可以提高性能，因为配置范围较小。

Istio 可以灵活地匹配 Kubernetes 集群和网络架构的配置。你可能希望在单个集群上运行单个网格和控制平面，或者你可能有一个集群。

只要 pod 能在网络上相互联系，Istio 就能工作；你甚至可以配置 Istio 网关，作为网络之间的堡垒主机。

在我们的文档中了解[全面的部署模型](/zh/docs/ops/deployment/deployment-models/)。

现在也是考虑你想使用哪些集成的好时机：我们建议 [设置 Prometheus](/zh/docs/ops/integrations/prometheus/#Configuration)作为服务监控，并与[外部服务器进行分层联合](/zh/docs/ops/best-practices/observability/)。如果你的公司的可观测性堆栈是由不同的团队运行的，现在是时候让他们加入了。

## 第一天：将服务添加到网格中

现在，你的网格已配置并准备好接受服务。要做到这一点，你只需在 Kubernetes 中标记你的命名空间，当这些服务被重新部署时，它们现在将包括配置为与 Istio 控制平面对话的 Envoy 代理。

### 配置服务

许多服务都可以开箱即用，但是通过在 Kubernetes 清单中添加一些信息，可以使 Istio 变得更加智能。例如，为 "app" 和 "version" 设置标签将有助于以后查询指标。

对于常见的端口和协议，Istio 会检测流量类型。如果检测不到，它将退回到将流量作为 TCP 处理，但你可以很容易地用流量类型来[注释服务](/zh/docs/ops/configuration/traffic-management/protocol-selection/)。

了解更多关于[启用与 Istio 一起使用的应用程序](/zh/docs/ops/deployment/requirements/)的信息。

### 启用安全

Istio 将配置网状结构中的服务，使其在相互通信时尽可能使用 mTLS。Istio 默认以"允许的mTLS" 模式运行，这意味着服务将同时接受加密和未加密的流量，以允许来自非网状服务的流量保持功能。在将所有的服务接入网状结构后，你可以[改变认证策略，只允许加密的流量](/zh/docs/tasks/security/authentication/mtls-migration/)。这样，你就可以确定你的所有流量都是加密的。

### Istio 的两类 API

Istio 为平台所有者和服务所有者提供了 API。根据你扮演的角色，你只需要考虑一个子集。例如，平台所有者将拥有安装、认证和授权资源。流量管理资源将由服务所有者处理。[了解哪些 API 对你有用。](/zh/docs/reference/config/)

### 在虚拟机上连接服务

Istio 不只是为 Kubernetes 服务；可以[在虚拟机上添加服务](/zh/docs/setup/install/virtual-machine/)（或裸机）到一个网状结构中，以获得 Istio 提供的所有优势，如相互 TLS、丰富的遥测和高级流量管理能力。

### 监测你的服务

使用 [Kiali](/zh/docs/ops/integrations/kiali/) 检查流经你的网格的流量，或者使用 [Zipkin](/zh/docs/tasks/observability/distributed-tracing/zipkin/) 或 [Jaeger](/zh/docs/tasks/observability/distributed-tracing/jaeger/) 追踪请求。

使用 Istio 的默认 [Grafana](/docs/ops/integrations/grafana/) 仪表盘，以获得网格中运行的服务的黄金信号的自动报告。

## 第二天：业务考虑

作为平台所有者，你负责安装并保持网格的更新，同时保证对服务团队的影响很小。

### 安装

通过 istioctl，你可以使用内置的配置文件之一轻松地安装 Istio。当你定制你的安装以满足你的要求时，建议使用 IstioOperator 自定义资源（CR）来定义你的配置。这让你可以选择将安装管理的工作完全委托给 Istio 操作员，而不是使用 istioctl 手动完成。只为控制平面使用一个 IstioOperator CR，为网关使用额外的 IstioOperator CR，以增加升级的灵活性。

### 安全升级

当新版本发布时，Istio 允许原地升级和金丝雀升级。在两者之间做出选择是在简单性和潜在的停机时间之间进行权衡。对于生产环境，建议使用[金丝雀升级法]（/zh/docs/set/upgrade/canary/）。在新的控制面和数据面版本被验证可以工作后，你可以升级你的网关。

### 监测网格

Istio 为网状结构内的所有服务通信生成详细的遥测数据。这些指标、跟踪和访问日志对于了解你的应用程序如何相互作用和识别任何性能瓶颈至关重要。使用这些信息来帮助你设置断路器、超时和重试，并加固你的应用程序。

就像你在网格中运行的应用程序一样，Istio 控制平面组件也会输出指标。利用这些指标和预先配置的 Grafana 仪表板来调整你的资源请求、限制和扩展。

## 加入 Istio 社区

一旦你运行 Istio，你就成为了一个大型全球社区的成员。你可以在[我们的讨论论坛](https://discuss.istio.io/)上提出问题，或[跳上 Slack](https://slack.istio.io/)。如果你想改进一些东西，或者有一个功能请求，你可以直接去 [GitHub](https://github.com/istio/istio)。

快乐的网格化!

{{< /centered_block >}}