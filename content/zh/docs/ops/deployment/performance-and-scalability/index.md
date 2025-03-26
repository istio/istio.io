---
title: 性能和可扩展性
description: 介绍 Istio 的性能和可扩展性。
weight: 30
keywords:
  - performance
  - scalability
  - scale
  - benchmarks
aliases:
  - /zh/docs/performance-and-scalability/overview
  - /zh/docs/performance-and-scalability/microbenchmarks
  - /zh/docs/performance-and-scalability/performance-testing-automation
  - /zh/docs/performance-and-scalability/realistic-app-benchmark
  - /zh/docs/performance-and-scalability/scalability
  - /zh/docs/performance-and-scalability/scenarios
  - /zh/docs/performance-and-scalability/synthetic-benchmarks
  - /zh/docs/concepts/performance-and-scalability
  - /zh/docs/ops/performance-and-scalability
owner: istio/wg-environments-maintainers
test: n/a
---

Istio 以十分便捷且对应用程序透明的方式，为已部署的服务创建网络，
提供完善的网络功能，包括：路由规则、负载均衡、服务到服务的验证以及监控等。
Istio 致力于用最小的资源开销实现最大的便易性，旨在支持高请求密度的大规模网格，
同时让延迟最小化。

Istio 的数据平面组件 Envoy 代理用来处理通过系统的数据流。控制平面组件如
Pilot、Galley 和 Citadel 负责配置数据平面。数据平面和控制平面有不同的性能关注点。

## Istio 1.24 性能总结 {#performance-summary-for-Istio}

[Istio 负载测试](https://github.com/istio/tools/tree/{{< source_branch_name >}}/perf/load)网格包含了
**1000** 个服务和 **2000** 个 Pod 在一套 Istio 网格中，全网格范围内，QPS 为 70,000。

## 控制平面性能 {#control-plane-performance}

Pilot 根据用户编写的配置文件和系统当前状态来配置 Sidecar 代理。在
Kubernetes 环境中，自定义资源定义（CRDs）和部署构成了系统的配置和状态。
像网关和虚拟服务这样的 Istio 配置对象提供了用户编写配置的能力。Pilot
综合处理配置和系统状态，生成代理的配置信息。这些配置和系统状态源自
Kubernetes 环境和用户编写的配置文件。

控制平面支持数千个服务，分布在数千个 Pod 上，
所需的用户自有虚拟服务和其它配置对象的数量级与之类似。Pilot
的 CPU 和内存资源需求量与系统配置和可能状态的量级成正比。CPU
消耗的变化取决于以下因素：

- 部署改变的频率。
- 配置改变的频率。
- 连接到 Pilot 的代理数量。

这部分本身是水平可伸缩的。当[命名空间隔离](/zh/docs/reference/config/networking/sidecar/)选项被打开，
一个单一的 Pilot 实例仅用 1 vCPU 和 1.5 GB 的内存就可以支持 1000
个服务和 2000 个 Sidecar。您可以增加 Pilot 实例的数量来降低它花在推送配置到所有代理的耗时。

## 数据平面性能 {#data-plane-performance}

数据平面的性能受很多因素影响，例如：

- 客户端连接数量
- 目标服务接收请求的密度
- 请求和响应的体量
- 代理工作线程的数量
- 协议
- CPU 核数
- 各种代理功能。特别是，遥测过滤器（日志记录、链路追踪和指标）已知具有中等影响。

根据上述因素来度量延迟、吞吐量以及代理的 CPU 和内存消耗。

### Sidecar 及 ztunnel 资源使用情况 {#sidecar-and-ztunnel-resource-usage}

由于 Sidecar 代理在数据路径上执行额外的工作，它需要消耗 CPU 和内存。
以 Istio 1.24 举例，每秒有 1000 个 http 请求，每个请求包含 1 KB 的有效负载
- 具有 2 个工作线程的单个 Sidecar 代理消耗大约 0.20 vCPU 和 60 MB 内存。
- 具有 2 个工作线程的单个 waypoint 代理消耗大约 0.25 vCPU 和 60 MB 内存
- 单个 ztunnel 代理消耗大约 0.06 vCPU 和 12 MB 内存。

代理的内存消耗取决于它的总体配置状态。大量的监听器、集群和路由会增加内存使用量。

### 延迟 {#latency}

由于 Istio 在数据路径上添加了一个 Sidecar 代理或 ztunnel 代理，因此延迟是一个重要的考虑因素。
Istio 添加的每个功能也会增加代理内部的路径长度，并可能影响延迟。

Envoy 代理在向客户端发送响应后收集原始遥测数据。
收集请求的原始遥测数据所花费的时间不计入完成该请求所需的总时间。
但是，由于工作程序正忙于处理请求，因此工作程序不会立即开始处理下一个请求。
此过程会增加下一个请求的队列等待时间，并影响平均延迟和尾部延迟。实际尾部延迟取决于流量模式。

### Istio 1.24 的延迟 {#latency-for-Istio}

在 Sidecar 模式下，请求将通过客户端 Sidecar 代理，然后通过服务器 Sidecar 代理，
然后到达服务器，反之亦然。在 Ambient 模式下，请求将通过客户端节点 ztunnel，
然后通过服务器节点 ztunnel，然后到达服务器。配置 waypoint 后，
请求将通过 ztunnel 之间的 waypoint 代理。下图展示了通过各种数据平面模式的
http/1.1 请求的 P90 和 P99 延迟。为了运行测试，
我们使用了一个由 5 台 [M3 Large](https://deploy.equinix.com/product/servers/m3-large/) 机器组成的裸机集群，
并使用 [Flannel](https://github.com/flannel-io/flannel) 作为主 CNI。
我们使用 [Istio 基准测试](https://github.com/istio/tools/tree/{{< source_branch_name >}}/perf/benchmark)获得了这些结果，
该基准测试针对 `http/1.1` 协议，负载为 1 KB，
每秒请求数为 500、750、1000、1250 和 1500 个，
使用了 4 个客户端连接、2 个代理工作程序，启用了相互 TLS。

注意：此测试是在 [CNCF 社区基础设施实验室](https://github.com/cncf/cluster)中进行的。
不同的硬件会给出不同的值。

{{< image link="./istio-1.24.0-fortio-90.png" caption="P90 延迟 vs 客户端连接" width="90%" >}}

{{< image link="./istio-1.24.0-fortio-99.png" caption="P99 延迟 vs 客户端连接" width="90%" >}}

- `no mesh`：客户端 Pod 直接调用服务器 Pod，Pod 不在 Istio 服务网格中。
- `ambient: L4`：带有{{{{< gloss "Secure L4 Overlay" >}}安全 L4 覆盖{{< /gloss >}}的默认 Ambient 模式。
- `ambient: L4+L7`：默认 Ambient 模式，为命名空间启用了安全 L4 覆盖和 waypoint。
- `sidecar`：客户端和服务器 Sidecar。

### 基准测试工具 {#benchmarking-tools}

Istio 使用下面的工具进行基准测试：

- [`fortio.org`](https://fortio.org/) - 一个恒定的吞吐量负载测试工具。
- [`nighthawk`](https://github.com/envoyproxy/nighthawk) - 基于 Envoy 的负载测试工具。
- [`isotope`](https://github.com/istio/tools/tree/master/isotope) - 一个具有可配置拓扑结构的综合应用程序。
