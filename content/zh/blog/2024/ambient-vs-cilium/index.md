---
title: "云端扩展：Istio Ambient vs. Cilium"
description: 深入探讨大规模性能。
publishdate: 2024-10-21
attribution: "Mitch Connors (Microsoft); Translated by Wilson Wu (DaoCloud)"
keywords: [istio,cilium,分析]
---

潜在的Istio用户常常问的一个问题是“Istio与Cilium相比如何？” 虽然Cilium最初只提供L3/L4功能，包括网络策略，但最近的版本增加了使用Envoy的服务网格功能以及WireGuard加密。与Istio一样，Cilium是一个CNCF毕业项目，并且在社区中存在多年。

尽管在表面上提供了类似的功能集，这两个项目在架构上有着显著的不同，尤其是Cilium在内核中使用eBPF和WireGuard处理和加密L4流量，而Istio则在用户空间使用ztunnel组件处理L4流量。这些差异导致了关于Istio在大规模下性能如何的广泛猜测。

虽然关于这两个项目的租赁模型、安全协议和基本性能的比较已经很多，但尚未有在企业规模上发布的完整评估。我们不强调理论性能，而是通过实际负载场景对Istio的ambient模式和Cilium进行了测试，重点关注延迟、吞吐量和资源消耗等关键指标。我们在模拟繁忙的Kubernetes环境中增加了压力，最终将我们的AKS集群规模扩大到1,000个节点和11,000个核心，以了解这些项目在大规模下的表现。我们的结果显示了每个项目可以改进的领域，但也表明Istio是明显的赢家。

## 测试场景

为了将Istio和Cilium推向极限，我们创建了500个不同的服务，每个服务由100个pod支持。每个服务在一个单独的命名空间中，该命名空间还包含一个[Fortio](https://fortio.org/)负载生成客户端。我们将客户端限制在一个由100台32核机器组成的节点池中，以消除来自共置客户端的噪音，并将剩余的900台8核实例分配给我们的服务。

{{< image width="60%"
    link="./scale-scenario.png"
    alt="扩展到500个服务和50,000个pod。"
    >}}

在Istio测试中，我们使用了Istio的ambient模式，每个服务命名空间中都有一个[waypoint代理](/docs/ambient/usage/waypoint/)，并使用默认安装参数。为了使我们的测试场景相似，我们在Cilium中启用了几个非默认功能，包括WireGuard加密、L7代理和节点初始化。我们还在每个命名空间中创建了一个Cilium网络策略，具有基于HTTP路径的规则。在两种情况下，我们通过每秒随机将一个服务扩展到85到115个实例，并每分钟重新标记一个命名空间来生成变化。要查看我们使用的精确设置并重现我们的结果，请参阅[我的笔记](https://github.com/therealmitchconnors/tools/blob/2384dc26f114300687b21f921581a158f27dc9e1/perf/load/many-svc-scenario/README.md)。

## 可扩展性记分卡

{{< image width="80%"
    link="./scale-scorecard.png"
    alt="可扩展性记分卡：Istio vs. Cilium！"
    >}}
Istio能够以20%更低的尾部延迟提供56%更多的查询。虽然Cilium的CPU使用量减少了30%，但我们的测量不包括Cilium用于处理加密的内核资源。

考虑到使用的资源，Istio每核处理2178个查询，而Cilium为1815个，提升了20%。

* **Cilium的减速:** Cilium在默认安装参数下具有令人印象深刻的低延迟，但当启用Istio的基线功能（如L7策略和加密）时，速度显著下降。此外，即使在网格中没有流量时，Cilium的内存和CPU利用率仍然很高。这可能会影响集群的整体稳定性和可靠性，特别是在集群扩展时。
* **Istio，稳定的表现者:** Istio的ambient模式在稳定性和保持良好吞吐量方面显示了其优势，即使在增加加密开销的情况下也是如此。虽然在测试中Istio消耗的内存和CPU比Cilium多，但在没有负载时，其CPU利用率降至Cilium的一小部分。

## 幕后：差异的原因

理解这些性能差异的关键在于每个工具的架构和设计。

* **Cilium的控制平面难题:** Cilium在每个节点上运行一个控制平面实例，导致API服务器压力和配置开销随着集群扩展而增加。这经常导致我们的API服务器崩溃，随后Cilium变得不可用，整个集群变得无响应。
* **Istio的效率优势:** Istio通过其集中控制平面和基于身份的方法简化了配置，减少了API服务器和节点的负担，将关键资源用于处理和保护流量，而不是处理配置。Istio通过运行尽可能多的Envoy实例来利用控制平面未使用的资源，而Cilium则限制为每个节点一个共享的Envoy实例。

## 深入探讨

虽然本项目的目标是比较Istio和Cilium的可扩展性，但一些限制使得直接比较变得困难。

### 层4并不总是层4

虽然Istio和Cilium都提供L4策略执行，但它们的API和实现有很大不同。Cilium实现了Kubernetes网络策略，使用标签和命名空间来阻止或允许IP地址的访问。Istio提供了一个AuthorizationPolicy API，并根据用于签署每个请求的TLS身份做出允许和拒绝决定。大多数深度防御策略需要同时使用网络策略和基于TLS的策略来实现全面的安全性。

### 并非所有加密都是一样的

虽然Cilium提供了用于FIPS兼容加密的IPsec，但大多数其他Cilium功能（如L7策略和负载均衡）与IPsec不兼容。Cilium在使用WireGuard加密时具有更好的功能兼容性，但WireGuard不能在FIPS合规环境中使用。另一方面，Istio严格遵守TLS协议标准，默认情况下始终使用FIPS兼容的mTLS。

### 隐藏的成本

虽然Istio完全在用户空间运行，但Cilium的L4数据平面在Linux内核中使用eBPF。Prometheus资源消耗的指标仅测量用户空间资源，这意味着本测试中未计入Cilium使用的所有内核资源。

## 建议：选择合适的工具

那么，结论是什么？这取决于您的具体需求和优先事项。对于纯L3/L4用例且不需要加密的小型集群，Cilium提供了一种具有成本效益和高性能的解决方案。然而，对于更大的集群以及注重稳定性、可扩展性和高级功能的情况，Istio的ambient模式以及替代的网络策略实现是更好的选择。许多客户选择将Cilium的L3/L4功能与Istio的L4/L7和加密功能结合使用，以实现深度防御策略。

请记住，云原生网络的世界在不断发展。请关注Istio和Cilium的进展，因为它们将继续改进并解决这些挑战。

## 让我们继续对话

您是否使用过Istio的ambient模式或Cilium？您的经验和见解是什么？在下面的评论中分享您的想法。让我们相互学习，共同探索Kubernetes的精彩世界！
