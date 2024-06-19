---
title: 为什么选择 Istio？
description: 将 Istio 与其他服务网格解决方案进行比较。
weight: 20
keywords: [comparison]
owner: istio/wg-docs-maintainers-english
test: n/a
---

Istio 在 2017 年推出时率先提出了基于 Sidecar 的服务网格概念。
该项目从一开始就包含了定义服务网格的功能，包括用于零信任网络的基于标准的双向 TLS、
智能流量路由以及通过指标、日志和链路追踪实现的可观察性。

从那时起，该项目推动了网格领域的进步，
包括[多集群和多网络拓扑](/zh/docs/ops/deployment/deployment-models/)、
[通过 WebAssembly 实现可扩展性](/zh/docs/concepts/wasm/)、
[Kubernetes Gateway API 的开发](/zh/blog/2022/gateway-api-beta/)，
以及使用 [Ambient 模式](/zh/docs/ambient/overview/)将网格基础设施从应用程序开发人员手中移开。

以下是我们认为您应该使用 Istio 作为服务网格的几个原因。

## 简单而强大 {#simple-and-powerful}

Kubernetes 有数百种功能和数十种 API，但您只需一个命令即可开始使用它。
我们构建 Istio 的方式也一样。渐进式公开意味着您可以使用一小部分 API，
并且仅在需要时才使用更强大的功能。其他“简单”服务网格花了数年时间才赶上 Istio 在第一天就拥有的功能集。

拥有一个功能而不需要它比需要而没有这项功能更加美好！

## Envoy 代理 {#envoy}

从一开始，Istio 就由 {{< gloss >}}Envoy{{< /gloss >}} 代理提供支持，
这是一个最初由 Lyft 构建的高性能服务代理。Istio 是第一个采用 Envoy 的项目，
[Istio 团队是第一批外部提交者](https://eng.lyft.com/envoy-7-months-later-41986c2fd443)。
Envoy 后来成为[为 Google Cloud 提供支持的负载均衡器](https://cloud.google.com/load-balancing/docs/https?hl=zh-cn)以及几乎所有其他服务网格平台的代理。

Istio 继承了 Envoy 的所有功能和灵活性，包括使用
[Istio 团队在 Envoy 中开发的](/zh/blog/2020/wasm-announce/)实现世界级可扩展性。

## 社区 {#community}

Istio 是一个真正的社区项目。2023 年，
有 10 家公司为 Istio 做出了超过 1,000 项贡献，并没有一家公司的贡献超过 25%。
（[在此处查看数字](https://istio.devstats.cncf.io/d/5/companies-table?var-period_name=Last%20year&var-metric=contributions&orgId=1)）。

没有其他服务网格项目像 Istio 一样获得业界如此广泛的支持。

## 软件包 {#packages}

我们每次发布时都会向所有人提供稳定的二进制版本，并承诺继续这样做。
我们为[我们的最新版本和许多先前版本](/zh/docs/releases/supported-releases/)发布免费且定期的安全补丁。
我们的许多供应商都会支持旧版本，但我们认为，在稳定的开源项目中，
与供应商合作不应该成为确保安全的必要条件。

## 曾被考虑的替代方案 {#alternatives-considered}

一份好的设计文档应该包含一些被考虑过但最终被拒绝的替代方案。

### 为什么不“使用 eBPF”？ {#why-not-use-ebpf}

我们会这样做 - 只要合适！Istio 可以配置为使用 {{< gloss >}}eBPF{{< /gloss >}}
[将流量从 Pod 路由到代理](/zh/blog/2022/merbridge/)。
与使用 `iptables` 相比，这显示出了轻微的性能提升。

为什么不把它用在一切事情上呢？没有人这么做，因为没有人真正能做到。

eBPF 是一个在 Linux 内核中运行的虚拟机。它专为保证在有限的计算范围内完成的功能而设计，
以避免破坏内核行为，例如执行简单的 L3 流量路由或应用程序可观察性的功能。
它不是为像 Envoy 中那样的长期运行或复杂功能而设计的：
这就是为什么操作系统有[用户空间](https://en.wikipedia.org/wiki/User_space_and_kernel_space)！
eBPF 维护者认为它最终可以扩展以支持运行像 Envoy 一样复杂的程序，
但这是一个科学项目，不太可能具有现实世界的实用性。

其他声称“使用 eBPF”的网格实际上使用每个节点的 Envoy 代理或其他用户空间工具来实现其大部分功能。

### 为什么不使用每个节点的代理？ {#why-not-use-a-per-node-proxy}

Envoy 本身并不是多租户的。因此，我们在共享实例中混合来自多个不受约束的租户的 L7 流量的复杂处理规则时，
存在严重的安全性和稳定性问题。由于 Kubernetes 默认可以将任何命名空间中的 Pod 调度到任何节点上，
因此该节点不是合适的租户边界。预算和成本归因也是主要问题，因为 L7 处理的成本比 L4 高得多。

在 Ambient 模式下，我们严格限制 ztunnel 代理进行 L4 处理 - [就像 Linux 内核一样](https://blog.howardjohn.info/posts/ambient-spof/)。
这大大减少了漏洞的暴露面，并允许我们安全地操作共享组件。
然后，流量被转发到按命名空间运行的 Envoy 代理，这样 Envoy 代理就永远不会是多租户的。

## 我有 CNI。为什么我需要 Istio？ {#i-have-a-cni-why-do-i-need-istio}

如今，一些 CNI 插件开始以附加组件的形式提供类似服务网格的功能，
这些附加组件位于其自己的 CNI 实现之上。例如，
它们可以为节点或 Pod 之间的流量、工作负载身份实现自己的加密方案，
或者通过将流量重定向到 L7 代理来支持一定数量的传输级策略。
这些服务网格附加组件是非标准的，因此只能在搭载它们的 CNI 之上工作。
它们还提供不同的功能集。例如，在 Wireguard 之上构建的解决方案无法符合 FIPS 标准。

为此，Istio 实现了零信任隧道（ztunnel）组件，该组件使用成熟的行业标准加密协议透明高效地提供此功能。
[了解有关 ztunnel 的更多信息](/zh/docs/ambient/overview)。

Istio 旨在成为一个服务网格，它提供一致、高度安全、高效且符合标准的服务网格实现，
提供[一组强大的 L7 策略](/zh/docs/concepts/security/#authorization)、
[与平台无关的工作负载身份](/zh/docs/concepts/security/#istio-identity)，
使用[业界验证的 mTLS 协议](/zh/docs/concepts/security/#mutual-tls-authentication) - 在任何环境、任何 CNI，甚至跨具有不同 CNI 的集群。
