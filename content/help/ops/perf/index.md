---
title: Performance Tuning
description: Istio performance, sizing and tuning guide.
weight: 90
force_inline_toc: true
---
## Istio Performance Tuning

Istio's goal is to offer a performance-optimized configuration out of the box.
However, each use case has different performance criteria. Thus, creating performance-optimized configurations for all use cases is difficult.

The following table shows a few configuration options that affect performance:

| Key | Default Value | Performance Impact | Recommendation |
| --- | --- | --- | --- |
| `global.proxy.concurrency` | `2` | An incorrect value can cause high sidecar resource use and latency. | Set this value to equal to the number of CPU cores allocated to the proxy. |
| `pilot.keepaliveMaxServerConnectionAge` | `30m` | Uneven load distribution across Pilot replicas for a longer period of time. | Reduce this number if you want quicker balancing of load at the cost of increased connect/disconnect activity. |
| `pilot.traceSampling` | `1.0` |  Latency and throughput impact due to tracing. | This can be reduced further from the default. If set to 0.0%, use `x-client-trace-id` header to trace specific requests. |
| `global.disablePolicyChecks` | `true` | Tail latency impact due to policy. | Enable policy checks *only* if you are using [rate limiting](/docs/tasks/policy-enforcement/rate-limiting/) or another istio-policy feature.|
| `mixer.telemetry.enabled` | `true` | High CPU usage and additional latency by telemetry | Telemetry is a core part of Istio. However if you are only using the networking API and have other means of getting metrics, `istio-telemetry` can be turned off for a significant reduction in CPU usage.|

Another important configuration option that should be is the considered for tuning is the [`sidecar resource`](/docs/reference/config/networking/v1alpha3/sidecar), which is disabled by default. In a large mesh, there will be a high memory usage by sidecars and high CPU by Pilot, if the sidecar scope includes the whole mesh. By enabling namespace isolation there should be a significant reduction in sidecar memory usage and pilot CPU usage.

### Istio default profile vs. functionality

In order to get a good performance out of the box, Istio 1.1 disabled several features by default:

| Feature | Default | Description |
| --- | --- | --- |
| `global.proxy.accessLogFile` | `""` |  Proxy access logging is disabled because it contributes to high CPU and I/O. Set this to `/dev/stdout` to enable access logging.|
| `mixer.adapters.stdio.enabled` | `false` |  Mixer access logging is disabled because it is a debug feature and it contributes to high CPU and I/O. Set this to `true` to enable access logging.|
| `global.disablePolicyChecks` | `true` | Policy checks are disabled by default to avoid unnecessary latency in the data path. Set it to `true` in case of traffic management policies are added. |

### Namespace isolation

Namespace isolation using the [`sidecar resource`](/docs/reference/config/networking/v1alpha3/sidecar) is a major performance improvement in Istio 1.1
over the previous release of Istio. When namespace isolation is turned on-

- The default connectivity is namespace wide. Previously it was mesh wide.
- Pilot configures envoy with information that is relevant to routing within the namespace.
- Proxy receives less configuration information, therefore the proxy memory usage is lower.

The following tables documents the reduction in resource utilization due to namespace isolation for 2 different setups.

Configuration of each setup:

| Parameter | Setup 1 | Setup 2 |
| --- | --- | --- |
| Namespaces (N)| 40 | 50 |
| Sidecars (N x 40) | 1600 | 2000 |
| Services (N x 20) | 800 | 1000 |
| Virtual Services (N x 2) | 80 | 100|
| Gateways (N) | 40 | 50 |
| Configuration change rate (N/4 per minute) | 10/min | 12/min |

, and a comparison of resource utilization for each, with and without namespace isolation:

| Resource | Setup 1 || Setup 2 ||
| --- | --- | --- | --- | --- |
| Namespace Isolation | Enabled |  Disabled | Enabled | Disabled |
| Pilot replicas | 1  | 2 | 1 | 3 |
| Pilot CPU      | 1 vCPU | 5 vCPU | 1 vCPU | 8 vCPU |
| Pilot Memory   | 1.5 GB | 4 GB | 1.5 GB | 8 GB |
| Proxy Memory (per instance) | 50 MB  | 170 MB | 50 MB  | 225 MB |

### Istio Sizing and Capacity Planning Guidance

Based on all the performance data available, one can have an educated sizing and capacity planning decisions for Istio. The capacity planning effort depends on the kind of application, transaction volume and what features of Istio are enabled among many other factors. It can be looked at from how much total throughput the application has to support at what latency and can also be viewed as how many requests pass through the mesh. The Istio Performance Grafana dashboard is updated to provide this data for any workload using Istio.

The following table summarizes the resources requirements for Istio main components for the default configuration:

| Istio Component | CPU | Memory | Condition |
| --- | --- | --- | --- |
| Proxy | 0.6 vCPU | 50 MB `*` | CPU: 1000 mesh requests/sec; Mem: 1000 services, 2000 sidecars `**` |
| Telemetry | 0.6 vCPU | 200 MB | 1000 mesh requests/sec |
| Pilot | 1 vCPU | 1.5 GB | 1000 services, 2000 sidecars `**` |

`*` proxy memory is per instance

`**` with namespace isolation enabled
