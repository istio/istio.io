---
title: Performance and Scalability
description: Istio performance and scalability summary.
weight: 30
keywords:
  - performance
  - scalability
  - scale
  - benchmarks
aliases:
  - /docs/performance-and-scalability/overview
  - /docs/performance-and-scalability/microbenchmarks
  - /docs/performance-and-scalability/performance-testing-automation
  - /docs/performance-and-scalability/realistic-app-benchmark
  - /docs/performance-and-scalability/scalability
  - /docs/performance-and-scalability/scenarios
  - /docs/performance-and-scalability/synthetic-benchmarks
  - /docs/concepts/performance-and-scalability
  - /docs/ops/performance-and-scalability
owner: istio/wg-environments-maintainers
test: n/a
---

Istio makes it easy to create a network of deployed services with rich routing,
load balancing, service-to-service authentication, monitoring, and more - all
without any changes to the application code. Istio strives to provide
these benefits with minimal resource overhead and aims to support very
large meshes with high request rates while adding minimal latency.

The Istio data plane components, the Envoy proxies, handle data flowing through
the system. The Istio control plane component, Istiod, configures
the data plane. The data plane and control plane have distinct performance concerns.

## Performance summary for Istio 1.24

The [Istio load tests](https://github.com/istio/tools/tree/{{< source_branch_name >}}/perf/load) mesh consists
of **1000** services and **2000** pods in an Istio mesh with 70,000 mesh-wide requests per second.

## Control plane performance

Istiod configures sidecar proxies based on user authored configuration files and the current
state of the system. In a Kubernetes environment, Custom Resource Definitions (CRDs) and deployments
constitute the configuration and state of the system. The Istio configuration objects like gateways and virtual
services, provide the user-authored configuration.
To produce the configuration for the proxies, Istiod processes the combined configuration and system state
from the Kubernetes environment and the user-authored configuration.

The control plane supports thousands of services, spread across thousands of pods with a
similar number of user authored virtual services and other configuration objects.
Istiod's CPU and memory requirements scale with the amount of configurations and possible system states.
The CPU consumption scales with the following factors:

- The rate of deployment changes.
- The rate of configuration changes.
- The number of proxies connecting to Istiod.

However, this part is inherently horizontally scalable.

You can increase the number of Istiod instances to reduce the amount of time it takes for the configuration
to reach all proxies.

At large scale, [configuration scoping](/es/docs/ops/configuration/mesh/configuration-scoping) is highly recommended.

## data plane performance

data plane performance depends on many factors, for example:

- Number of client connections
- Target request rate
- Request size and Response size
- Number of proxy worker threads
- Protocol
- CPU cores
- Various proxy features. In particular, telemetry filters (logging, tracing, and metrics) are known to have a moderate impact.

The latency, throughput, and the proxies' CPU and memory consumption are measured as a function of said factors.

### Sidecar and ztunnel resource usage

Since the sidecar proxy performs additional work on the data path, it consumes CPU
and memory. In Istio 1.24, with 1000 http requests per second containing 1 KB of payload each
- a single sidecar proxy with 2 worker threads consumes about 0.20 vCPU and 60 MB of memory.
- a single waypoint proxy with 2 worker threads consumes about 0.25 vCPU and 60 MB of memory
- a single ztunnel proxy consumes about 0.06 vCPU and 12 MB of memory.

The memory consumption of the proxy depends on the total configuration state the proxy holds.
A large number of listeners, clusters, and routes can increase memory usage.

### Latency

Since Istio adds a sidecar proxy or ztunnel proxy on the data path, latency is an important
consideration.
Every feature Istio adds also adds to the path length inside the proxy and potentially affects latency.

The Envoy proxy collects raw telemetry data after a response is sent to the
client.
The time spent collecting raw telemetry for a request does not contribute to the total time taken to complete that request.
However, since the worker is busy handling the request, the worker won't start handling the next request immediately.
This process adds to the queue wait time of the next request and affects average and tail latencies.
The actual tail latency depends on the traffic pattern.

### Latency for Istio 1.24

In sidecar mode, a request will pass through the client sidecar proxy and then the server sidecar proxy before reaching the server, and vice versa.
In ambient mode, a request will pass through the client node ztunnel and then the server node ztunnel before reaching the server.
With waypoints configured, a request will go through a waypoint proxy between the ztunnels.
The following charts show the P90 and P99 latency of http/1.1 requests traveling through various data plane modes.
To run the tests, we used a bare-metal cluster of 5 [M3 Large](https://deploy.equinix.com/product/servers/m3-large/) machines and [Flannel](https://github.com/flannel-io/flannel) as the primary CNI.
We obtained these results using the [Istio benchmarks](https://github.com/istio/tools/tree/{{< source_branch_name >}}/perf/benchmark) for the `http/1.1` protocol with a 1 KB payload at 500, 750, 1000, 1250, and 1500 requests per second using 4 client connections, 2 proxy workers and mutual TLS enabled.

Note: This testing was performed on the [CNCF Community Infrastructure Lab](https://github.com/cncf/cluster).
Different hardware will give different values.

{{< image link="./istio-1.24.0-fortio-90.png" caption="P90 latency vs client connections" width="90%" >}}

{{< image link="./istio-1.24.0-fortio-99.png" caption="P99 latency vs client connections" width="90%" >}}

- `no mesh`: Client pod directly calls the server pod, no pods in Istio service mesh.
- `ambient: L4`: Default ambient mode with the {{< gloss >}}secure L4 overlay{{< /gloss >}}
- `ambient: L4+L7` Default ambient mode with the secure L4 overlay and waypoints enabled for the namespace.
- `sidecar` Client and server sidecars.

### Benchmarking tools

Istio uses the following tools for benchmarking

- [`fortio.org`](https://fortio.org/) - a constant throughput load testing tool.
- [`nighthawk`](https://github.com/envoyproxy/nighthawk) - a load testing tool based on Envoy.
- [`isotope`](https://github.com/istio/tools/tree/{{< source_branch_name >}}/isotope) - a synthetic application with configurable topology.
