---
title: "支持双栈 Kubernetes 集群"
description: "双栈 Kubernetes 集群的实验版本和主干分支 Alpha 版本支持。"

publishdate: 2023-01-17T07:00:00-06:00
attribution: "张怀龙 (Intel), 徐贺杰 (Intel), 丁少君 (Intel), Jacob Delgado (F5), 蔡迎春 (formerly F5)"
keywords: [双栈]
---

在过去的一年里，英特尔和 F5 在为 Istio 提供 [Kubernetes 双栈网络](https://kubernetes.io/docs/concepts/services-networking/dual-stack/)的支持中通力合作。

# 背景

对于 Istio 双栈支持的工作花费了比预期更长的时间，而我们也还有很多关于双栈的工作需要继续。最初这项工作基于 F5 的设计实现展开，由此我们创建了 [RFC](https://docs.google.com/document/d/1oT6pmRhOw7AtsldU0-HbfA0zA26j9LYiBD_eepeErsQ/edit?usp=sharing) ，社区根据该设计文档展开了广泛的讨论。值得注意的是，社区对此方案存在对内存和性能方面的顾虑，并且希望这些问题能够在实现之前被解决，这也引起了我们对最初设计方案的反思。

## 实验双栈分支

随着持续深入的探索，在重新评估技术方案的同时，我们创建了一个新分支 [experimental-dual-stack](https://github.com/istio/istio/tree/experimental-dual-stack)来参考最初的设计来实现和验证 Istio 双栈的实现方案。

我们在后续的文章中将详细的说明如何构建使用刚才提到的实验双栈分支。但是请注意写该文章最初的目的是大家一起探索当我们希望在 Istio 中实现具有重大影响的功能而不引起系统回退时，我们如何更好的处理并开展工作。因此它会被认为是高度实验性的使用（尽管单元和集成测试目前没有通过，但仍然有人正在他们的环境中测试和使用它）。

原始设计的很大一部分是复制大量 Envoy 配置，尤其是 listeners, clusters 和 routes 以及其对应的一系列新的可引用的 endpoints 。最初的设计是根据客户要求创建的
指定客户端发起的 IPv4 请求应该通过 IPv4 进行代理，对于发起 IPv6 的请求也是如此(我们称之为原生IP家族转发)

## 社区反馈

社区为原始 RFC 提供的大部分反馈是更改 Envoy 以更好地支持双栈用例，在 Envoy 内部而不是在 Istio 中支持它。 我们吸取了经验教训和反馈并加以应用，由此我们创建了一个新的 [RFC](https://docs.google.com/document/d/15LP2XHpQ71ODkjCVItGacPgzcn19fsVhyE7ruMGXDyU/edit?usp=sharing)

## 当前工作

我们与 Envoy 社区合作解决了众多问题，这也是对Istio双栈的支持花费了一些时间的原因。 这些问题有： [matched IP Family for outbound listener](https://github.com/envoyproxy/envoy/issues/16804) 和 [supported multiple addresses per listener](https://github.com/envoyproxy/envoy/issues/11184). 其中徐贺杰也一直在积极的帮助解决一些悬而未解的问题，此后 Envoy 就可以以一种更聪明的方式选择 endpoints（参考Issue：[smarter way to pick endpoints for dual-stack](https://github.com/envoyproxy/envoy/issues/21640)）。 Envoy 的这些改进，比如 [enable socket options on multiple addresses](https://github.com/envoyproxy/envoy/pull/23496)，使得即将到来的 Istio 1.17 中对双栈的支持能够落地（Istio 中对应的修改比如： [extra source addresses on inbound clusters](https://github.com/istio/istio/pull/41618)）。

团队所做的关于 Envoy 接口定义更改如下：

1. [Listener addresses](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/listener/v3/listener.proto.html?highlight=additional_addresses)
1. [bind config](https://www.envoyproxy.io/docs/envoy/latest/api-v3/config/core/v3/address.proto#config-core-v3-bindconfig).

对于 Istio 双栈支持的实现，这些修改确保我们能够在 Envoy 的下游和上游连接上得到适当的支持。

团队总共向 Envoy 提交了十多个 PR，其中有多半数的 PR 的目的是使 Envoy 采用双栈时对 Istio 来说更加容易。

同时，在 Istio 方面，也可以在 [Issue #40394](https://github.com/istio/istio/issues/40394) 中跟踪进度。尽管最近进展有所放缓，随着我们在各种问题上继续与 Envoy 合作，我们希望到2023年2月份 Istio 1.17 版本发布之前能够得到解决。

我们希望 Istio 1.17 能够获得对双栈工作的基本支持。

### 参与其中

虽然我们没有可供下载的具有双栈功能的 Istio 公开版本，但我们期望能在2023年初发布的 Istio 1.17 版本中完成并准备就绪。

我们很乐意收到你的反馈，如果你希望与我们合作，请访问我们在 [Istio Slack](https://slack.istio.io/) 中的 Slack 频道 **#dual-stack-support**。

_感谢为 Istio 双栈工作的团队！_
* _英特尔： [张怀龙](https://github.com/zhlsunshine), [徐贺杰](https://github.com/soulxu), [丁少君](https://github.com/irisdingbj)_
* _F5： [Jacob Delgado](https://github.com/jacob-delgado)_
* _formerly of F5： [蔡迎春](https://github.com/ycai-aspen)_