---
title: "Sail Operator 介绍：管理 Istio 的新方法"
description: 引入 Sail Operator 来管理 Istio，它是 istio-ecosystem 组织内的一个项目。
publishdate: 2024-08-19
attribution: "Francisco Herrera - Red Hat; Translated by Wilson Wu (DaoCloud)"
keywords: [istio,operator,sail,incluster,deprecation]
---

随着最近宣布在 Istio 1.23 中[弃用](/zh/blog/2024/in-cluster-operator-deprecation-announcement/)集群内 IstioOperator
以及随后在 Istio 1.24 中删除该 Operator，我们希望提高人们对 Red Hat 团队一直在开发的作为
[istio-ecosystem](https://github.com/istio-ecosystem)
组织内的用于管理 Istio 的[新 Operator](https://github.com/istio-ecosystem)。

Sail Operator 管理 Istio 控制平面的生命周期，使集群管理员能够更轻松、
更高效地在大规模生产环境中部署、配置和升级 Istio。
Sail Operator API 是围绕 Istio 的 Helm Chart API 构建的，
无需创建新的配置模式以及重复造轮子。Istio 的 Helm Chart
公开的所有安装和配置选项都可通过 Sail Operator CRD 的值字段获得。
这意味着您可以使用熟悉的配置轻松管理和自定义 Istio，而无需添加其他需要学习的内容。

Sail Operator 有 3 个主要资源概念：
* [Istio](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istio-resource)：
  用于管理 Istio 控制平面。
* [Istio Revision](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istiorevision-resource)：
  表示该控制平面的修订，它是具有特定版本和修订名称的 Istio 实例。
* [Istio CNI](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#istiocni-resource)：
  用于管理 Istio 的 CNI 插件的资源和生命周期。
  要安装 Istio CNI 插件，您需要创建一个 `IstioCNI` 资源。

目前，Sail Operator 的主要功能是更新策略。
该 Operator 提供了一个管理 Istio 控制平面升级的接口。它目前支持两种更新策略：
* [In Place](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#inplace)：
  使用 `InPlace` 策略，现有 Istio 控制平面将被新版本替换，
  工作负载 Sidecar 会立即连接到新的控制平面。这样，
  工作负载无需从一个控制平面实例移动到另一个控制平面实例。
* [Revision Based](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md#revisionbased)：
  使用 `RevisionBased` 策略，每次对 `Istio.spec.version`
  字段进行更改时都会创建一个新的 Istio 控制平面实例。旧控制平面将保留，
  直到所有工作负载都已移动到新控制平面实例。可选地，可以设置 `updateWorkloads`
  标志以在准备就绪时自动将工作负载移动到新控制平面。

我们知道，升级 Istio 控制平面存在风险，并且对于大型部署来说可能需要大量的手动工作，
这就是我们目前关注的重点。未来，我们正在研究如何让 Sail Operator
更好地支持多租户和隔离、多集群联合以及与第三方项目的简化集成等用例。

Sail Operator 项目仍处于 Alpha 阶段，并且正在大力开发中。
请注意，作为 istio-ecosystem 项目，它不受 Istio 项目的支持。
我们正在积极寻求社区的反馈和贡献。如果您想参与该项目，
请参阅仓库[文档](https://github.com/istio-ecosystem/sail-operator/blob/main/README.md)和[贡献指南](https://github.com/istio-ecosystem/sail-operator/blob/main/CONTRIBUTING.md)。
如果您是用户，您还可以按照[用户文档](https://github.com/istio-ecosystem/sail-operator/blob/main/docs/README.md)中的说明尝试新的运算符。

如需了解更多信息，请联系我们：

* [Discussions](https://github.com/istio-ecosystem/sail-operator/discussions)
* [Issues](https://github.com/istio-ecosystem/sail-operator/issues)
* [Slack](https://istio.slack.com/archives/C06SE9XCK3Q)
