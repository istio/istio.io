---
title: "使用金丝雀控制平面部署安全升级 Istio"
subtitle: 通过提供控制平面的安全金丝雀部署，简化 Istio 升级
description: 通过提供控制平面的安全金丝雀部署，简化 Istio 升级。
publishdate: 2020-05-19
attribution: "John Howard (Google)"
keywords: [install,upgrade,revision,control plane]
---

金丝雀部署是 Istio 的核心特性。用户依靠 Istio 的流量管理特性安全地控制新版本应用程序的推出，同时利用 Istio 丰富的遥测技术来比较金丝雀的性能。然而，当涉及到升级 Istio 时，没有一种简单的方法来监测升级，而且由于升级的就地性质，发现的问题或更改会立即影响整个网格。

Istio 1.6 将支持一种新的升级模式来安全部署 Istio 的新版本。在这个新模型中，代理将与它们使用的特定控制平面相关联。这允许新版本以较小的风险部署到集群—直到用户明确选择连接新版本时，才会有代理连接到新版本。这允许将工作负载逐步迁移到新的控制平面，当监控到更改时使用 Istio 遥测技术来调查任何问题，就像对工作负载使用 `VirtualService` 一样。每个独立的控制平面被称为一个“修订”，并有一个 `istio.io/rev` 标签。

## 升级过程解读{#understanding-upgrades}

升级 Istio 是一个复杂的过程。在两个版本之间的过渡期间(对于大型集群来说可能需要很长时间)，代理和控制平面之间存在版本差异。在旧模型中，新旧控制平面使用相同的服务，流量在两个平面之间随机分布，不向用户提供控制。然而，在新的模型中，不存在跨版本通信。看看升级是如何变化的：

<iframe src="https://docs.google.com/presentation/d/e/2PACX-1vR2R_Nd1XsjriBfwbqmcBc8KtdP4McDqNpp8S5v6woq28FnsW-kATBrKtLEG9k61DuBwTgFKLWyAxuK/embed?start=false&loop=true&delayms=3000" frameborder="0" width="960" height="569" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true"></iframe>

## 配置{#configuring}

控制平面的选择是基于 sidecar 注入 webhook。每个控制平面都配置为选择名称空间匹配 `istio.io/rev` 标签的对象。然后，升级过程将 Pod 配置为连接到指定修订版的控制平面。与当前模型不同，这意味着给定的代理在生命周期内连接到同一修订版控制平面。这避免了当代理切换时它所连接的控制平面可能出现的细微问题。

当使用修订版时，新的 `istio.io/rev` 标签将替换 `istio-injection=enabled` 标签。例如，如果我们有一个名为金丝雀的修订，我们将使用 istio.io/rev=canary 标签标记要使用该修订的名称空间。有关更多信息请参见[升级指南](/zh/docs/setup/upgrade)。
