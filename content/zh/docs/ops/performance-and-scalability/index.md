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

Pilot configures sidecar proxies based on user authored configuration files and the current
state of the system. In a Kubernetes environment, Custom Resource Definitions (CRDs) and deployments
constitute the configuration and state of the system. The Istio configuration objects like gateways and virtual
services, provide the user-authored configuration.
To produce the configuration for the proxies, Pilot processes the combined configuration and system state
from the Kubernetes environment and the user-authored configuration.

The control plane supports thousands of services, spread across thousands of pods with a
similar number of user authored virtual services and other configuration objects.
Pilot's CPU and memory requirements scale with the amount of configurations and possible system states.
The CPU consumption scales with the following factors:

- The rate of deployment changes.
- The rate of configuration changes.
- The number of proxies connecting to Pilot.

however this part is inherently horizontally scalable.

When [namespace isolation](/zh/docs/reference/config/networking/sidecar/) is enabled,
a single Pilot instance can support 1000 services, 2000 sidecars with 1 vCPU and 1.5 GB of memory.
You can increase the number of Pilot instances to reduce the amount of time it takes for the configuration
to reach all proxies.

## 数据平面性能 {#data-plane-performance}

Data plane performance depends on many factors, for example:

- Number of client connections
- Target request rate
- Request size and Response size
- Number of proxy worker threads
- Protocol
- CPU cores
- Number and types of proxy filters, specifically Mixer filter.

The latency, throughput, and the proxies' CPU and memory consumption are measured as a function of said factors.

### CPU 和内存 {#cpu-and-memory}

Since the sidecar proxy performs additional work on the data path, it consumes CPU
and memory. As of Istio 1.1, a proxy consumes about 0.6 vCPU per 1000
requests per second.

The memory consumption of the proxy depends on the total configuration state the proxy holds.
A large number of listeners, clusters, and routes can increase memory usage.
Istio 1.1 introduced namespace isolation to limit the scope of the configuration sent
to a proxy. In a large namespace, the proxy consumes approximately 50 MB of memory.

Since the proxy normally doesn't buffer the data passing through,
request rate doesn't affect the memory consumption.

### 延迟 {#latency}

Since Istio injects a sidecar proxy on the data path, latency is an important
consideration. Istio adds an authentication and a Mixer filter to the proxy. Every
additional filter adds to the path length inside the proxy and affects latency.

The Envoy proxy collects raw telemetry data after a response is sent to the
client. The time spent collecting raw telemetry for a request does not contribute
to the total time taken to complete that request. However, since the worker
is busy handling the request, the worker won't start handling the next request
immediately. This process adds to the queue wait time of the next request and affects
average and tail latencies. The actual tail latency depends on the traffic pattern.

Inside the mesh, a request traverses the client-side proxy and then the server-side
proxy. This two proxies on the data path add about 7ms to the 90th percentile latency at 1000 requests per second.
The server-side proxy alone adds 2ms to the 90th percentile latency.

### Istio {{< istio_release_name >}} 的延迟 {#latency-for-istio-hahahugoshortcode-s3-hbhb}

The default configuration of Istio {{< istio_release_name >}} adds 7ms to the 90th percentile latency of the data plane over the baseline.
We obtained these results using the [Istio benchmarks](https://github.com/istio/tools/tree/master/perf/benchmark)
for the `http/1.1` protocol, with a 1 kB payload at 1000 requests per second using 16 client connections, 2 proxy workers and mutual TLS enabled.

In upcoming Istio releases we are moving `istio-policy` and `istio-telemetry` functionality into the proxy as `MixerV2`.
This will decrease the amount data flowing through the system, which will in turn reduce the CPU usage and latency.

{{< image width="90%"
    link="latency_p90.svg"
    alt="P90 latency vs client connections"
    caption="P90 latency vs client connections"
>}}

- `baseline` Client pod directly calls the server pod, no sidecars are present.
- `server-sidecar` Only server sidecar is present.
- `both-sidecars` Client and server sidecars are present. This is a default case inside the mesh.
- `nomixer-both` Same as **both-sidecars** without Mixer. `MixerV2` latency profile will be similar.
- `nomixer-server` Same as **server-sidecar** without Mixer. `MixerV2` latency profile will be similar.

### 基准测试工具 {#benchmarking-tools}

Istio uses the following tools for benchmarking

- [`fortio.org`](https://fortio.org/) - a constant throughput load testing tool.
- [`blueperf`](https://github.com/blueperf/) - a realistic cloud native application.
- [`isotope`](https://github.com/istio/tools/tree/master/isotope) - a synthetic application with configurable topology.
