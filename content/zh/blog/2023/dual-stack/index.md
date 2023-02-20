---
title: "支持双栈 Kubernetes 集群"
description: "对双栈 Kubernetes 集群的实验性支持。"
publishdate: 2023-02-20
attribution: "张怀龙 (Intel), 徐贺杰 (Intel), 丁少君 (Intel), Jacob Delgado (F5), 蔡迎春 (formerly F5)"
keywords: [双栈]
---

在过去的一年里，英特尔和 F5 在为 Istio 提供 [Kubernetes 双栈网络](https://kubernetes.io/docs/concepts/services-networking/dual-stack/)的支持中通力合作。

## 背景

对于 Istio 双栈特性支持的工作花费了比预期更长的时间，而我们也还有很多关于双栈的工作需要继续。最初这项工作基于 F5 的设计实现展开，由此我们创建了 [RFC](https://docs.google.com/document/d/1oT6pmRhOw7AtsldU0-HbfA0zA26j9LYiBD_eepeErsQ/edit?usp=sharing) ，社区根据该设计文档展开了广泛的讨论。值得注意的是，社区对此方案存在对内存和性能方面的顾虑，并且希望这些问题能够在实现之前被解决，这也引起了我们对最初设计方案的反思。

## 实验双栈分支

随着持续深入的探索，在重新评估技术方案的同时，我们创建了一个新分支 [experimental-dual-stack]({{< github_raw >}}/tree/experimental-dual-stack)来参考最初的设计来实现和验证 Istio 双栈的实现方案。 我们在后续的文章中将详细的说明如何构建使用刚才提到的实验双栈分支。但是请注意写该文章最初的目的是大家一起探索当我们希望在 Istio 中实现具有重大影响的功能而不引起系统回退时（对于本例特指双栈对单栈集群的倒退影响），我们如何更好的处理并开展工作。实验分支的双栈特性是在 Istio 1.13 和 1.14 之间创建了分支，同时并没有与 master 分支保持同步。 然而从此实验分支构建出来的 Istio 部署会被认为是高度实验性的。然而添加另一个 PR 以后，在本地创建实验双栈特性的 Istio 时，其持续集成的工作流会失败。话虽如此，仍然有一些个人和企业在验证和生产环境使用这个分支。

最初的设计是根据客户要求创建的指定客户端发起的 IPv4 请求应该通过 IPv4 进行代理，对于发起 IPv6 的请求也是如此(我们称之为原生IP家族转发)。 为此，我们的设计之初必须为 Envoy 创建重复的 listeners, clusters, routes 和 endpoints 配置。鉴于许多人已经遇到 Envoy 内存和 CPU 消耗问题，来自社区早期的反馈希望我们完全重新评估这个方案。另外很多代理都是透明地处理出站的双栈流量，并不关心该流量是如何产生的。许多最初的社区反馈是在 Istio 和 Envoy 中实现相同的行为。

## 重新定义双栈特性的支持

社区为原始 RFC 提供的大部分反馈是更改 Envoy 以更好地支持双栈用例，在 Envoy 内部而不仅仅是在 Istio 中修改。 我们吸取了经验教训和反馈并将它们应用到简化的设计中，由此我们创建了一个新的 [RFC](https://docs.google.com/document/d/15LP2XHpQ71ODkjCVItGacPgzcn19fsVhyE7ruMGXDyU/edit?usp=sharing)

## 双栈特性在 Istio 1.17中的支持

我们与 Envoy 社区合作解决了众多问题，这也是对 Istio 双栈特性的支持花费了一些时间的原因。 这些问题有： [matched IP Family for outbound listener](https://github.com/envoyproxy/envoy/issues/16804) 和 [supported multiple addresses per listener](https://github.com/envoyproxy/envoy/issues/11184). 其中徐贺杰也一直在积极的帮助解决一些悬而未解的问题，此后 Envoy 就可以以一种更聪明的方式选择 endpoints（参考Issue：[smarter way to pick endpoints for dual-stack](https://github.com/envoyproxy/envoy/issues/21640)）。 Envoy 的这些改进，比如 [enable socket options on multiple addresses](https://github.com/envoyproxy/envoy/pull/23496)，使得即将到来的 Istio 1.17 中对双栈特性的支持能够落地（Istio 中对应的修改比如： [extra source addresses on inbound clusters](https://github.com/istio/istio/pull/41618)）。

团队所做的关于 Envoy 接口定义更改如下：

1. [Listener addresses](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener.proto.html?highlight=additional_addresses)
1. [bind config](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/address.proto#config-core-v3-bindconfig).

对于 Istio 双栈特性支持的实现，这些修改是很重要的，它确保我们能够在 Envoy 的下游和上游连接上得到适当的支持。

团队总共向 Envoy 提交了十多个 PR，其中有多半数的 PR 的目的是使 Envoy 采用双栈时对 Istio 来说更加容易。

同时，在 Istio 方面，也可以在 [Issue #40394](https://github.com/istio/istio/issues/40394) 中跟踪进度。尽管最近进展有所放缓，随着我们在各种问题上继续与 Envoy 合作，我们希望到2023年2月份 Istio 1.17 版本发布之前能够得到解决。

我们希望 Istio 1.17 能够获得双栈特性的最基本支持。除此以外，来自英特尔的丁少君和李纯已经就 ambient 的网络流量重定向功能与社区一起展开工作。在 Istio 1.17 发布后不久，我们将宣布更多关于这部分内容在此版本上的修改。

### 参与其中

还有很多工作要做，欢迎各位与我们一起完成双栈特性到达 Alpha 状态所需的其他任务。 [详情请看这里](https://github.com/istio/enhancements/pull/141)
比如，来自英特尔的丁少君和李纯已经就 ambient 的网络流量重定向功能与社区一起展开工作。我们希望在后面的 Istio 1.18 alpha 双栈特性的版本中，ambient 也能够支持双栈特性。

我们非常乐意你提出宝贵意见，如果你期待与我们合作请访问我们在 [Istio Slack](https://slack.istio.io/) 中的 Slack 频道 **#dual-stack-support**。

_感谢为 Istio 双栈特性工作的团队！_
* 英特尔： [张怀龙](https://github.com/zhlsunshine), [徐贺杰](https://github.com/soulxu), [丁少君](https://github.com/irisdingbj)
* F5： [Jacob Delgado](https://github.com/jacob-delgado)
* [蔡迎春](https://github.com/ycai-aspen) （前 F5 员工）
