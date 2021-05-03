---
title: 重做我们的插件集成
description: 一种管理遥测插件安装的新方法。
publishdate: 2020-06-04
attribution: John Howard (Google)
keywords: [telemetry,addons,integrations,grafana,prometheus]
---

从 Istio 1.6 开始，我们引入了一种与遥测插件集成的新方法，例如 Grafana，Prometheus，Zipkin，Jaeger 和 Kiali。

在以前的版本中，这些附加软件是作为 Istio 安装的一部分捆绑在一起的。这使用户可以快速开始使用 Istio，无需进行任何复杂的配置即可安装和集成这些插件。但是，它带来一些问题：

* Istio 插件安装不是最新的或不如上游安装方法功能丰富。用户错过了这些应用程序提供的一些很棒的功能，例如：
    * 持久化存储
    * Prometheus 的 `Alertmanager` 功能
    * 高级安全设置
*  与使用这些特性的现有部署集成比预想的更具挑战性。

## 修改{#changes}

为了解决这些问题，我们做了一些修改：

* 增加一个新的[集成](/zh/docs/ops/integrations/)文档部分，解释 Istio 可以集成哪些应用程序，如何使用它们，以及最佳实践。

* 减少设置遥测插件所需的配置数量

    * Grafana 仪表盘现在[发布到 `grafana.com`](/zh/docs/ops/integrations/grafana/#import-from-grafana-com)。

    * Prometheus 现在可以移除所有的 Istio Pod [使用标准的 `prometheus.io` 注解](/zh/docs/ops/integrations/prometheus/#option-2-metrics-merging)。这允许大多数 Prometheus 部署在没有任何特殊配置的情况下使用 Istio。

* 通过 `istioctl` 和操作面板删除绑定的插件安装。Istio 不会安装不是由 Istio 项目交付的组件。因此，Istio 将停止发送与插件相关的安装工件。但是，Istio 将在必要时保证版本兼容性。用户有责任使用相应项目提供的官方[集成](/zh/docs/ops/integrations/)文档和工件来安装这些组件。对于 demo 演示，用户可以通过 [`samples/addons/` 目录]({{< github_tree >}}/samples/addons)部署简单的 YAML 文件。

我们希望这些修改使用户能够充分利用这些附加组件，从而充分体验 Istio 可以提供的功能。

## 时间线{#timeline}

* Istio 1.6: 遥测插件的新演示部署 demo 可以在 `samples/addons/` 目录下找到。
* Istio 1.7: 建议使用上游安装方法或新的示例部署。 不推荐使用 `istioctl` 进行安装。
* Istio 1.8: 删除了 `istioctl` 对插件的安装。
