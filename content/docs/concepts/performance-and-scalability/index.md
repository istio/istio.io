---
title: Performance and Scalability
description: Introduces performance and scalability for Istio.
weight: 50
aliases:
    - /docs/performance-and-scalability/overview
    - /docs/performance-and-scalability/microbenchmarks
    - /docs/performance-and-scalability/performance-testing-automation
    - /docs/performance-and-scalability/realistic-app-benchmark
    - /docs/performance-and-scalability/scalability
    - /docs/performance-and-scalability/scenarios
    - /docs/performance-and-scalability/synthetic-benchmarks
keywords: [performance,scalability,scale,benchmarks]
---

Istio makes it easy to create a network of deployed services with rich routing,
 load balancing, service-to-service authentication, monitoring, and more - all
 does so without any changes to the application code. Istio strives to provide
 these benefits with minimal resource overhead. Istio also aims to support very
 large meshes with high request rates while adding minimal latency.

## Data plane performance

Istio consists of data plane components (proxy, mixer for headers only) that handle
 data flowing thru the system and control plane components (pilot, galley, citadel)
 that configure the data plane. Data plane and control plane have distinct
 performance concerns.

### Latency

Istio injects a sidecar proxy on the data path therefore latency is an important
 consideration. Istio adds an auth and mixer filter to the proxy. Every
 additional filter adds to the path length inside the proxy and affects latency.

Istio proxy collects raw telemetry data after a response is sent back to the
 client. Time spent collecting raw telemetry for a request does not contribute
 to the total time taken to complete that request. However, since the worker
 is busy doing this work, it will not start work on the next request
 immediately. This adds to the queue wait time of the next request affecting
 average and tail latencies. The actual tail latency depends on the traffic pattern.

Inside the mesh, a request traverses the client-side proxy and then the server-side
 proxy. Two proxies on the data path add about `10ms` to the p99 latency at `1k rps`.
 The server-side proxy alone adds `6ms` to the p99 latency.

### CPU and memory

Since the sidecar proxy performs additional work on the data path, it consumes CPU
 and memory. As of Istio 1.1, the `istio-proxy` consumes about 0.5 vCPU per 1000
 requests per second.

Memory consumption of the proxy depends on the total configuration state held by it.
 A large number of listeners, clusters, and routes can increase memory usage.
 Istio 1.1 introduced namespace isolation to limit the scope of configuration sent
 to a proxy. In a large namespace, this amounts to about 50MB memory consumed by the proxy.

The proxy does not normally buffer data passing through it, therefore memory
 consumption is not affected by the request rate.

Data plane performance depends on many factors.

* Number of client connections
* Target request rate
* Request size and Response size
* Enabling `mTLS`
* Number of proxy worker threads
* Protocol
* Host cores

Latency, throughput and proxy CPU are measured as a function of the above parameters.

## Control plane performance

Pilot configures sidecar proxies based on user authored configuration and the current
 state of the system. In a Kubernetes environment services, deployments, and endpoints
 are the ambient configuration and state. Istio configuration like `gateway` and
 `virtual service` is the user authored portion of the configuration.
 Pilot processes the combined configuration and state to produce configuration for the proxies.

Control plane supports thousands of services, spread across thousands of pods with a
 similar number of user authored virtual services and other configuration.
 CPU and memory requirements for Pilot scale with the amount of configuration and state.
 The CPU consumption also scales with the rate of change of deployments and the
 rate of change of configuration.

Lastly, the number of proxies connecting to a pilot affect the pilot CPU,
 however this part is inherently horizontally scalable.

When [namespace isolation](/docs/reference/config/networking/v1alpha3/sidecar/) is enabled,
 a single pilot instance can support 1000 services, 2000 sidecars with 1 vCPU and 1.5 GB of memory.
 You may increase the number of pilots to reduce the amount of time it takes for configuration
 to reach all the proxies.

## Release 1.1 performance summary

**Mesh Traffic:** The total traffic in the mesh; includes ingress, egress, and all traffic going
 into and out of every pod.

### Data plane latency

The default configuration of Istio 1.1 adds `10ms` to the p99 latency over the baseline.
The results were obtained by [Istio benchmarks](https://github.com/istio/tools/tree/master/perf/benchmark)
 for `http/1.1` protocol, `1kB` payload at `1k rps` using 16 client connections.

{{< image width="90%" ratio="75%"
    link="latency.svg?sanitize=true"
    alt="P99 latency vs client connections"
    caption="P99 latency vs client connections"
>}}

### Data plane resources

Istio proxy uses 0.5 vCPU per 1000 rps and `istio-telemetry` uses 0.5 vCPU per 1000 mesh rps.

### Control plane

Istio pilot needs 1 vCPU and 1.5 GB of memory to support 1000 services and 2000 sidecars.

