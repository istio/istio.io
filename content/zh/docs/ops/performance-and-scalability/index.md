---
title: 性能和可扩展性
description: 介绍 Istio 的性能和可扩展性
weight: 25
aliases:
- /zh/docs/performance-and-scalability/overview
- /zh/docs/performance-and-scalability/microbenchmarks
- /zh/docs/performance-and-scalability/performance-testing-automation
- /zh/docs/performance-and-scalability/realistic-app-benchmark
- /zh/docs/performance-and-scalability/scalability
- /zh/docs/performance-and-scalability/scenarios
- /zh/docs/performance-and-scalability/synthetic-benchmarks
- /zh/docs/concepts/performance-and-scalability
keywords:
- performance
- scalability
- scale
- benchmarks
---

Istio 使得创建一个部署了服务的网络变得很容易，该网络具有丰富的路由规则、负载均衡、服务到服务验证和监控等功能，而所有的这些都不需要对应用程序代码进行任何更改。Istio 尽可能用最小的资源开销来提供这些好处，旨在支持很大的网格与高请求率，同时仅增加尽可能低的延迟。

Istio 的数据平面组件和 Envoy 代理用来处理通过系统的数据流。控制平面组件如 Pilot、Galley 和 Citadel 用来配置数据平面。数据平面和控制平面有不同的性能关注点。

## Istio {{< istio_release_name >}} 性能总结 {#performance-summary-for-istio-hahahugoshortcode-s0-hbhb}

[Istio 负载测试](https://github.com/istio/tools/tree/master/perf/load)网格包含了 **1000** 个服务和 **2000** 个 sidecar，在网格访问内每秒钟有 70,000 个请求。
在使用 Istio {{< istio_release_name >}} 运行测试后，我们得到了如下结果：

- 通过代理的 QPS 有 1000 时，Envoy 使用了 **0.6 vCPU** 和 **50 MB 内存**。
- 网格总的 QPS 为 1000 时，`istio-telemetry` 服务使用了 **0.6 vCPU**。
- Pilot 使用了 **1 vCPU** 和 1.5 GB 内存。
- 90%的情况 Envoy 代理只增加了 8ms 的延迟。

## 控制平面性能 {#control-plane-performance}

Pilot 根据用户编写的配置文件和系统当前状态来配置 sidecar 代理。在 Kubernetes 环境中，自定义资源定义（CRDs）和部署构成了系统的配置和状态。像网关和虚拟服务这样的 Istio 配置对象提供了用户编写配置的能力。
为了生成代理配置，Pilot 从 Kubernetes 环境和用户创建的配置来处理组合的配置和系统状态。

The control plane supports thousands of services, spread across thousands of pods with a
similar number of user authored virtual services and other configuration objects.
Pilot's CPU and memory requirements scale with the amount of configurations and possible system states.
The CPU consumption scales with the following factors:

控制平面支持数千个服务，分布在数千个 pod 上，包含数量相似的由用户创建的虚拟服务和其他配置对象。Pilot 的 CPU 和内存需求随配置数量和可能的系统状态而变化。CPU 消耗的变化取决于以下因素：

- 部署改变的频率。
- 配置改变的频率。
- 连接到 Pilot 的代理数量。

这部分本身是水平可伸缩的。当 [namespace isolation](/zh/docs/reference/config/networking/sidecar/) 选项被打开，一个单一的 Pilot 实例仅用 1 vCPU 和 1.5 GB 的内存就可以支持 1000 个服务和 2000 个 sidecar。你可以增加 Pilot 实例的数量来降低它花在推送配置到所有代理的耗时。

## 数据平面性能 {#data-plane-performance}

数据平面的性能受很多因素影响，例如：

- 客户端连接数量
- 目标请求率
- 请求和响应体的大小
- 代理工作线程的数量
- 协议
- CPU 核数
- 代理过滤器的数量和类型，特别是 Mixer 过滤器

根据上述因素来度量延迟、吞吐量以及代理的 CPU 和内存消耗。

### CPU 和内存 {#cpu-and-memory}

只要 sidecar 代理在数据路径上执行额外的工作，它就会消耗 CPU 和内存。以 Istio 1.1举例，1000 QPS 会使用大约 0.6 vCPU。

代理的内存消耗取决于它持有的总体配置状态。大量的监听器、集群和路由会增加内存使用量。Istio 1.1 引入了命名空间隔离来限制配置发送到代理的范围。在一个比较大的命名空间中，代理将消耗大约 50 MB 的内存。

由于代理通常不缓冲通过的数据，请求速率不会影响内存消耗。

### 延迟 {#latency}

因为 Istio 在数据路径上注入了一个 sidecar 代理，所以延迟是重要的考量因素。Istio 向代理添加了身份验证和 Mixer过滤器。每一个额外的过滤器都会增加代理内的路径长度并影响延迟。

响应被返回给客户端后，Envoy 代理将收集原始的遥测数据。为请求收集原始遥测数据所花费的时间并没有统计在完成该请求所需的总时间里。但是，worker 在忙着处理请求时是不会立刻开始处理下一个请求的。此过程会增加下一个请求的队列等待时间并影响平均延迟和尾部延迟。实际的尾部延迟取决于流量模式。

在网格内部，一个请求会先遍历客户端代理，然后遍历服务端代理。在90%的情况下，数据路径上的这两个代理每 1000 QPS 会产生 7ms 的延迟。

90%的情况下仅服务端代理会增加 2ms 的延迟。

### Istio {{< istio_release_name >}} 的延迟 {#latency-for-istio-hahahugoshortcode-s3-hbhb}

Istio {{< istio_release_name >}} 的默认配置在 90% 的情况下使数据平面的延迟比基线增加了 7ms。我们通过 `http/1.1` 协议的 [Istio 基准测试](https://github.com/istio/tools/tree/master/perf/benchmark)获得了结果，测试标准是每秒 1000 请求，负载为 1kB，使用了 16 个客户端连接和 2 个代理，mTLS打开状态。

在接下来的 Istio 版本中我们会把 `istio-policy` 和 `istio-telemetry` 的功能移动到 `MixerV2` 的代理。这将降低通过系统的数据流量，从而减少 CPU 使用和延迟。

{{< image width="90%"
    link="latency_p90.svg"
    alt="P90 latency vs client connections"
    caption="P90 latency vs client connections"

>}}

- `baseline` 客户端 pod 直接调用服务端 pod，没有 sidecar 参与。
- `server-sidecar` 只有服务端 sidecar。
- `both-sidecars` 客户端和服务端 sidecar 都存在。这也是网格的默认情况。
- `nomixer-both` 没有 Mixer 的 **both-sidecars** 模式。和 `MixerV2` 的延迟情况类似。
- `nomixer-server` 没有 Mixer 的 **server-sidecar** 模式。和 `MixerV2` 的延迟情况类似。

### 基准测试工具 {#benchmarking-tools}

Istio 使用下面的工具进行基准测试：

- [`fortio.org`](https://fortio.org/) - 一个恒定的吞吐量负载测试工具。
- [`blueperf`](https://github.com/blueperf/) - 一个真实的云原生应用。
- [`isotope`](https://github.com/istio/tools/tree/master/isotope) - 一个具有可配置拓扑结构的综合应用程序。
