---
title: Performance and Scalability
description: Introduces performance and scalability for Istio.
weight: 75
aliases:
- /docs/performance-and-scalability/overview
- /docs/performance-and-scalability/microbenchmarks
- /docs/performance-and-scalability/performance-testing-automation
- /docs/performance-and-scalability/realistic-app-benchmark
- /docs/performance-and-scalability/scalability
- /docs/performance-and-scalability/scenarios
- /docs/performance-and-scalability/synthetic-benchmarks
- /docs/concepts/performance-and-scalability
keywords:
- performance
- scalability
- scale
- benchmarks
---

Istio makes it easy to create a network of deployed services with rich routing,
load balancing, service-to-service authentication, monitoring, and more - all
without any changes to the application code. Istio strives to provide
these benefits with minimal resource overhead and aims to support very
large meshes with high request rates while adding minimal latency.

The Istio data plane components, the Envoy proxies, handle data flowing through
the system. The Istio control plane components, Pilot, Galley and Citadel, configure
the data plane. The data plane and control plane have distinct performance concerns.

## Performance summary for Istio {{< istio_release_name >}}

The [Istio load tests](https://github.com/istio/tools/tree/{{< source_branch_name >}}/perf/load) mesh consists
of **1000** services and **2000** sidecars with 70,000 mesh-wide requests per second.
After running the tests using Istio {{< istio_release_name >}}, we get the following results:

- The Envoy proxy uses **0.5 vCPU** and **50 MB memory** per 1000 requests per second going through the proxy.
- The `istio-telemetry` service uses **0.6 vCPU** per 1000 **mesh-wide** requests per second.
- Pilot uses **1 vCPU** and 1.5 GB of memory.
- The Envoy proxy adds 6.3 ms to the 90th percentile latency.

## Control plane performance

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

When [namespace isolation](/docs/reference/config/networking/sidecar/) is enabled,
a single Pilot instance can support 1000 services, 2000 sidecars with 1 vCPU and 1.5 GB of memory.
You can increase the number of Pilot instances to reduce the amount of time it takes for the configuration
to reach all proxies.

## Data plane performance

Data plane performance depends on many factors, for example:

- Number of client connections
- Target request rate
- Request size and Response size
- Number of proxy worker threads
- Protocol
- CPU cores
- Number and types of proxy filters, specifically Mixer filter.

The latency, throughput, and the proxies' CPU and memory consumption are measured as a function of said factors.

### CPU and memory

Since the sidecar proxy performs additional work on the data path, it consumes CPU
and memory. As of Istio 1.1, a proxy consumes about 0.6 vCPU per 1000
requests per second.

The memory consumption of the proxy depends on the total configuration state the proxy holds.
A large number of listeners, clusters, and routes can increase memory usage.
Istio 1.1 introduced namespace isolation to limit the scope of the configuration sent
to a proxy. In a large namespace, the proxy consumes approximately 50 MB of memory.

Since the proxy normally doesn't buffer the data passing through,
request rate doesn't affect the memory consumption.

### Latency

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
proxy. This two proxies on the data path add about 6.3 ms to the 90th percentile latency at 1000 requests per second.
The server-side proxy alone adds 1.7 ms to the 90th percentile latency.

### Latency for Istio {{< istio_release_name >}}

The default configuration of Istio {{< istio_release_name >}} adds 6.3 ms to the 90th percentile latency of the data plane over the baseline.
We obtained these results using the [Istio benchmarks](https://github.com/istio/tools/tree/{{< source_branch_name >}}/perf/benchmark)
for the `http/1.1` protocol, with a 1 kB payload at 1000 requests per second using 16 client connections, 2 proxy workers and mutual TLS enabled.

In upcoming Istio releases we are moving `istio-policy` and `istio-telemetry` functionality into the proxy as `TelemetryV2`.
This will decrease the amount data flowing through the system, which will in turn reduce the CPU usage and latency.

{{< image width="90%"
    link="latency_p90.svg"
    alt="P90 latency vs client connections"
    caption="P90 latency vs client connections"
>}}

- `baseline` Client pod directly calls the server pod, no sidecars are present.
- `server-sidecar` Only server sidecar is present.
- `both-sidecars` Client and server sidecars are present. This is a default case inside the mesh.
- `nomixer-both` Same as **both-sidecars** without Mixer.
- `nomixer-server` Same as **server-sidecar** without Mixer.
- `telemetryv2-nullvm_both` Same as **both-sidecars** but with telemetry v2. This is targeted to perform the same as "No Mixer" in the future.
- `telemetryv2-nullvm_serveronly` Same as **server-sidecar** but with telemetry v2. This is targeted to perform the same as "No Mixer" in the future.

### Benchmarking tools

Istio uses the following tools for benchmarking

- [`fortio.org`](https://fortio.org/) - a constant throughput load testing tool.
- [`blueperf`](https://github.com/blueperf/) - a realistic cloud native application.
- [`isotope`](https://github.com/istio/tools/tree/{{< source_branch_name >}}/isotope) - a synthetic application with configurable topology.
