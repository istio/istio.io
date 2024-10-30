---
title: "在云中扩展：Istio Ambient 与 Cilium"
description: 深入探究扩展中的性能。
publishdate: 2024-10-21
attribution: "Mitch Connors (Microsoft); Translated by Wilson Wu (DaoCloud)"
keywords: [istio,cilium,analysis]
---

潜在的 Istio 用户经常会问 “Istio 与 Cilium 相比如何？”
虽然 Cilium 最初仅提供 L3/L4 功能（包括网络策略），
但最近的版本已使用 Envoy 以及 WireGuard 加密添加了服务网格功能。
与 Istio 相同，Cilium 也是 CNCF 的毕业项目，并且已在社区中存在多年。

尽管表面上提供的功能集相似，但这两个项目的架构却大不相同，
最明显的是 Cilium 使用 eBPF 和 WireGuard 来处理和加密内核中的 L4 流量，
而 Istio 在用户空间中使用 ztunnel 组件来处理 L4 流量。
这些差异引发了人们对 Istio 与 Cilium 相比在大规模情况下表现如何的大量猜测。

虽然已经对这两个项目的租户模型、安全协议和基本性能进行了许多比较，
但尚未以企业规模形式发布完整的评估。我们没有强调理论性能，
而是对 Istio 的 Ambient 模式和 Cilium 进行了测试，重点关注延迟、
吞吐量和资源消耗等关键指标。我们通过现实的负载场景增加了压力，
模拟了一个繁忙的 Kubernetes 环境。最后，我们将 AKS 集群的规模推高到 1,000 个节点以及 11,000 个核心，
以了解这些项目在此规模上的表现。我们的结果显示了每个项目都有可以改进的地方，但也表明 Istio 是明显的赢家。

## 测试场景 {#test-scenario}

为了将 Istio 和 Cilium 推向极限，我们创建了 500 个不同的服务，
每个服务由 100 个 Pod 支持。每个服务都位于一个单独的命名空间中，
该命名空间还包含一个 [Fortio](https://fortio.org/) 负载生成器客户端。
我们将客户端限制为 100 台 32 核机器的节点池，以消除来自共置客户端的噪音，
并将剩余的 900 个 8 核实例分配给我们的服务。

{{< image width="60%"
    link="./scale-scenario.png"
    alt="扩展到 500 个服务，并拥有 50,000 个 Pod。"
    >}}

对于 Istio 测试，我们使用了 Istio 的 Ambient 模式，
每个服务命名空间中都有一个 [waypoint 代理](/zh/docs/ambient/usage/waypoint/)，
并使用默认安装参数。为了使我们的测试场景相似，我们必须在 Cilium 中启用一些非默认功能，包括 WireGuard 加密、L7 代理和 Node Init。
我们还在每个命名空间中创建了一个 Cilium 网络策略，其中包含基于 HTTP 路径的规则。
在这两种情况下，我们通过每秒随机将一项服务扩展到 85 到 115 个实例，
并每分钟重新标记一个命名空间来产生搅动。要查看我们使用的精确设置并重现我们的结果，
请参阅[我的笔记](https://github.com/therealmitchconnors/tools/blob/2384dc26f114300687b21f921581a158f27dc9e1/perf/load/many-svc-scenario/README.md)。

## 可扩展性记录 {#scalability-scorecard}

{{< image width="80%"
    link="./scale-scorecard.png"
    alt="可扩展性记录：Istio 与 Cilium！"
    >}}

Istio 能够以低于 20% 的尾部延迟情况下处理 56% 以上的查询。
并且比 Cilium 的 CPU 使用率低了 30%，
但我们的测量不包括 Cilium 用于处理加密的核心，加密是在内核中完成的。

考虑到所使用的资源，Istio 每个核心处理 2178 个查询，
而 Cilium 每个核心处理 1815 个查询，高出了 20%。

* **Cilium 速度变慢**：虽然 Cilium 在默认安装参数下具有令人印象深刻的低延迟，
  但当 Istio 的基本功能（例如 L7 策略和加密）启用时，其速度会大幅降低。
  此外，即使网格中没有流量流动，Cilium 的内存和 CPU 利用率仍然很高。
  这可能会影响集群的整体稳定性和可靠性，尤其是在集群增长时。
* **Istio，表现稳定**：另一方面，Istio 的 Ambient 模式显示出其在稳定性和保持良好吞吐量方面的优势，
  即使增加了加密开销。虽然 Istio 在测试中确实比 Cilium 消耗更多的内存和 CPU，
  但在非负载下，其 CPU 利用率稳定在 Cilium 的一小部分。

## 幕后：为什么会有差异？ {#behind-the-scenes-why-the-difference}

理解这些性能差异的关键在于每个工具的架构和设计。

* **Cilium 的控制平面难题**：Cilium 在每个节点上运行一个控制平面实例，
  随着集群的扩展，会导致 API 服务器压力和配置开销。
  这经常导致我们的 API 服务器崩溃，随后 Cilium 变得无法就绪，整个集群变得无响应。
* **Istio 的效率优势**：Istio 具有集中控制平面和基于身份的方法，
  可简化配置并减轻 API 服务器和节点的负担，将关键资源用于处理和保护流量，
  而不是处理配置。Istio 通过运行工作负载所需的尽可能多的 Envoy 实例，
  进一步利用控制平面中未使用的资源，而 Cilium 仅限于每个节点一个共享 Envoy 实例。

## 深入挖掘 {#digging-deeper}

虽然该项目的目标是比较 Istio 和 Cilium 的可扩展性，但由于存在一些限制，因此直接比较变得困难。

### 四层并不总是四层 {#layer-4-isnt-always-layer-4}

虽然 Istio 和 Cilium 都提供 L4 策略实施，但它们的 API 和实现方式却大不相同。
Cilium 实现了 Kubernetes NetworkPolicy，
它使用标签和命名空间来阻止或允许对 IP 地址的访问。
Istio 提供了 AuthorizationPolicy API，并根据用于签署每个请求的 TLS 身份做出允许和拒绝的决定。
大多数纵深防御策略都需要同时使用 NetworkPolicy 和基于 TLS 的策略来实现全面的安全性。

### 并非所有加密都相同 {#not-all-encryption-is-created-equal}

虽然 Cilium 提供 IPsec 以实现与 FIPS 兼容的加密，
但大多数其他 Cilium 功能（例如 L7 策略和负载均衡）与 IPsec 不兼容。
使用 WireGuard 加密时，Cilium 具有更好的功能兼容性，
但 WireGuard 不能在符合 FIPS 的环境中使用。另一方面，
由于 Istio 严格遵守 TLS 协议标准，因此默认情况下始终使用符合 FIPS 的 mTLS。

### 隐性成本 {#hidden-costs}

Istio 完全在用户空间中运行，而 Cilium 的 L4 数据平面使用 eBPF 在 Linux 内核中运行。
Prometheus 的资源消耗指标仅衡量用户空间资源，这意味着 Cilium 使用的所有内核资源均未被计入此测试中。

## 建议：选择合适的工具 {#recommendations-choosing-the-right-tool-for-the-job}

那么，结论是什么？这取决于您的具体需求和优先事项。
对于具有纯 L3/L4 用例且不需要加密的小型集群，
Cilium 提供了一种经济高效且性能卓越的解决方案。但是，
对于较大的集群并注重稳定性、可扩展性和高级功能，
Istio 的 Ambient 模式以及备用 NetworkPolicy 实现才是最佳选择。
许多客户选择将 Cilium 的 L3/L4 功能与 Istio 的 L4/L7 和加密功能相结合，以形成纵深防御策略。

请记住，云原生网络的世界在不断发展。
密切关注 Istio 和 Cilium 的发展，因为它们会不断改进并应对这些挑战。

## 让我们保持沟通 {#lets-keep-the-conversation-going}

您是否使用过 Istio 的 Ambient 模式或 Cilium？您的经验和见解是什么？
在下面的评论中分享您的想法。让我们互相学习，一起探索令人兴奋的 Kubernetes 世界！
