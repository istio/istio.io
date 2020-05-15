---
title: Mixer 和 SPOF 神话
description: 提高可用，降低延迟。
publishdate: 2017-12-07
subtitle: 提高可用，降低延迟
attribution: Martin Taillefer
keywords: [adapters,mixer,policies,telemetry,availability,latency]
aliases:
    - /zh/blog/posts/2017/mixer-spof-myth.html
    - /zh/blog/mixer-spof-myth.html
target_release: 0.3
---

[Mixer](/zh/docs/reference/config/policy-and-telemetry/) 出现在请求路径上，很自然的会引发一个疑问：他对系统可用性和延迟会产生什么样的影响？第一次看到 Istio 架构图时，人们最常见的问题就是："这不就是一个单点失败的典型案例么？”

本文中我们会深入挖掘和阐述 Mixer 的设计原则，在这些设计原则的支持下 Mixer 能够令人惊奇的提高网格内的系统可用性，降低平均请求延时。

Istio 的 Mixer 对系统总体可用性和延迟有两个主要的好处：

* **提高 SLO**：Mixer 把 Proxy 和服务从基础设施后端的故障中隔离出来，提供了高级、高效的网格可用性保障。作为一个整体来说，在同基础设施后端的交互中，有了 Mixer 的帮助，会有更低的故障率。

* **降低延迟**：通过对各个层次的分片缓存的积极使用和共享，Mixer 能够降低平均延迟。

接下来会对上面的内容进行一下解释。

## Istio 是怎么来的{#how-we-got-here}

Google 在多年中都在使用一个内部的 API 和服务管理系统，用于处理 Google 提供的众多 API。这一系统支持了最大的服务群（Google Maps、YouTube 以及 Gmail 等），承受上百万 QPS 峰值的冲击。这套系统运行的虽然很好，但是仍然无法跟上 Google 快速增长的脚步，很显然，要有新的架构来降低飞涨的运维成本。

2014 年，我们开始了一个草案，准备替换这一系统，进行更好的伸缩。这一决定最后证明是非常正确的，在 Google 进行整体部署之后，每月降低了上百万美元的运维成本。

过去，流量在进入具体的服务之前，首先会进入一个较重的代理，旧系统就是以这个代理为中心构建的。新的架构摒弃了共享代理的设计，用轻量高效的 Sidecar 代理取而代之，这一代理和服务实例并行，共享一个控制平面。

{{< image width="75%"
    link="./mixer-spof-myth-1.svg"
    title="Google 系统拓扑"
    caption="Google 的 API 和 服务管理系统"
    >}}

看起来很面熟吧？是的，跟 Istio 很像。Istio 就是作为这一分布式代理架构的继任者进行构思的。我们从内部系统中获取了核心的灵感，在同合作伙伴的协同工作中产生了很多概念，这些导致了 Istio 的诞生。

## 架构总结{#architecture-recap}

下图中，Mixer 在 Mesh 和基础设施之间：

{{< image width="75%" link="./mixer-spof-myth-2.svg" caption="Istio 拓扑" >}}

逻辑上，Envoy Sidecar 会在每次请求之前调用 Mixer，进行前置检查，每次请求之后又要进行指标报告。Sidecar 中包含本地缓存，一大部分的前置检查可以通过缓存来进行。另外，Sidecar 会把待发送的指标数据进行缓冲，这样可能在几千次请求之后才调用一次 Mixer。前置检查和请求处理是同步的，指标数据上送是使用 fire-and-forget 模式异步完成的。

抽象一点说，Mixer 提供：

* **后端抽象**：Mixer 把 Istio 组件和网格中的服务从基础设施细节中隔离开来。

* **中间人**：Mixer 让运维人员能够对所有网格和基础设施后端之间的交互进行控制。

除了这些纯功能方面，Mixer 还有一些其他特点，为系统提供更多益处。

### Mixer：SLO 助推器{#mixer-booster}

有人说 Mixer 是一个 SPOF，会导致 Mesh 的崩溃，而我们认为 Mixer 增加了 Mesh 的可用性。这是如何做到的？下面是三个理由：

* **无状态**：Mixer 没有状态，他不管理任何自己的持久存储。

* **稳固**：Mixer 是一个高可靠性的组件，设计要求所有 Mixer 实例都要有超过 99.999% 的可靠性。

* **缓存和缓冲**：Mixer 能够积累大量的短期状态数据。

Sidecar 代理伴随每个服务实例而运行，必须节约使用内存，这样就限制了本地缓存和缓冲的数量。但是 Mixer 是独立运行的，能使用更大的缓存和缓冲。因此 Mixer 为 Sidecar 提供了高伸缩性高可用的二级缓存服务。

Mixer 的预期可用性明显高于多数后端（多数是 99.9%）。他的本地缓存和缓冲区能够在后端无法响应的时候继续运行，因此有助于对基础设施故障的屏蔽，降低影响。

### Mixer：延迟削减器{#mixer-latency-slasher}

上面我们解释过，Istio Sidecar 具备有效的一级缓存，在为流量服务的时候多数时间都可以使用缓存来完成。Mixer 提供了更大的共享池作为二级缓存，这也帮助了 Mixer 降低平均请求的延迟。

不只是降低延迟，Mixer 还降低了 Mesh 到底层的请求数量，这样就能显著降低到基础设施后端的 QPS，如果你要付款给这些后端，那么这一优点就会节省更多成本。

## 下一步{#work-ahead}

我们还有机会对系统做出更多改进。

### 以金丝雀部署的方式进行配置发布{#configuration-canaries}

Mixer 具备高度的伸缩性，所以他通常不会故障。然而如果部署了错误的配置，还是会引发 Mixer 进程的崩溃。为了防止这种情况的出现，可以用金丝雀部署的方式来发布配置，首先为一小部分 Mixer 进行部署，然后扩大部署范围。

目前的 Mixer 并未具备这样的能力，我们期待这一功能成为 Istio 可靠性配置工作的一部分最终得以发布。

### 缓存调优{#cache-tuning}

我们的 Sidecar 和 Mixer 缓存还需要更好的调整，这部分的工作会着眼于资源消耗的降低和性能的提高。

### 缓存共享{#cache-sharing}

现在 Mixer 的实例之间是各自独立的。一个请求在被某个 Mixer 实例处理之后，并不会把过程中产生的缓存传递给其他 Mixer 实例。我们最终会试验使用 Memcached 或者 Redis 这样的分布式缓存，以期提供一个网格范围内的共享缓存，更好的降低对后端基础设施的调用频率。

### 分片{#Sharding}

在大规模的网格中，Mixer 的负载可能很重。我们可以使用大量的 Mixer 实例，每个实例都为各自承担的流量维护各自的缓存。我们希望引入智能分片能力，这样 Mixer 实例就能针对特定的数据流提供特定的服务，从而提高缓存命中率；换句话说，分片可以利用把相似的流量分配给同一个 Mixer 实例的方式来提高缓存效率，而不是把请求交给随机选择出来的 Mixer 实例进行处理。

## 结语{#conclusion}

Google 的实际经验展示了轻代理、大缓存控制平面结合的好处：提供更好的可用性和延迟。过去的经验帮助 Istio 构建了更精确更有效的缓存、预抓取以及缓冲策略等功能。我们还优化了通讯协议，用于降低缓存无法命中的时候，对性能产生的影响。

Mixer 还很年轻。在 Istio 0.3 中，Mixer 并没有性能方面的重要改进。这意味着如果一个请求没有被 Sidecar 缓存命中，Mixer 就会花费更多时间。未来的几个月中我们会做很多工作来优化同步的前置检查过程中的这种情况。

我们希望本文能够让读者能够意识到 Mixer 对 Istio 的益处。

如果有意见或者问题，无需犹豫，请前往 [istio-policies-and-telemetry@](https://groups.google.com/forum/#!forum/istio-policies-and-telemetry)。
