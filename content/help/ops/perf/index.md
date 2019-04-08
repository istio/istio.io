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
| `pilot.keepaliveMaxServerConnectionAge` | `30m` | If the connection age is too large, proxies continue to connect to previously existing instances of Pilot even as new instances are added. This could overload Pilot and cause uneven load distribution across Pilot replicas for a longer period of time. | Reduce the connection age to increase load balancing speed at the cost of increased connect and disconnect activity. |
| `pilot.traceSampling` | `1.0` |  Trace sampling 100% of Pilot's traffic can impact the latency and throughput of the mesh. | To reduce the impact, limit the amount of trace sampling. If you set trace sampling to 0.0%, you can use the `x-client-trace-id` header to trace specific requests. |
| `global.disablePolicyChecks` | `true` | Tail latency impact due to policy. | Enable policy checks *only* if you are using [rate limiting](/docs/tasks/policy-enforcement/rate-limiting/) or another istio-policy feature.|
| `mixer.telemetry.enabled` | `true` | High CPU usage and additional latency by telemetry | Telemetry is a core part of Istio. However if you are only using the networking API and have other means of getting metrics, `istio-telemetry` can be turned off for a significant reduction in CPU usage.|

When tuning the performance of the mesh, consider using the [sidecar configuration object](/docs/reference/config/networking/v1alpha3/sidecar)
to enable namespace isolation. The sidecar configuration object is disabled by default but,
in a large mesh, sidecars consume a lot of memory and Pilot consumes a lot of CPU if the
sidecars' scope includes the whole mesh. Enabling namespace isolation significantly
reduces sidecar memory usage and Pilot's CPU usage.

## Istio default configuration values vs. functionality

To provide good performance out of the box, the following features are disabled by default in Istio 1.1:

| Feature | Default | Description |
| --- | --- | --- |
| `global.proxy.accessLogFile` | `""` |  Since proxy access logging contributes to high CPU usage and I/O traffic, logging is disabled by default. To enable proxy access logging, set this value to `/dev/stdout`. |
| `mixer.adapters.stdio.enabled` | `false` |  Since Mixer access logging contributes to high CPU usage and I/O traffic, this debugging feature is disabled by default. To enable access Mixer access logging, set this value to `true`. |
| `global.disablePolicyChecks` | `true` | To avoid unnecessary latency in the data path, policy checks are disabled by default. When you add traffic management policies, set this value to `true` to ensure Pilot performs the checks. |

## Namespace isolation

Namespace isolation provides a major performance improvement in Istio 1.1. To implement namespace isolation, use a [sidecar configuration object](/docs/reference/config/networking/v1alpha3/sidecar).
Enabling namespace isolation has the following consequences for your mesh:

- The default connectivity is namespace-wide instead of mesh-wide.
- Pilot configures Envoy with only the relevant information to route traffic within the namespace.
- The Envoy proxy receives less configuration information lowering the proxy's memory usage.

The following table document shows the configuration parameters of two different meshes: Setup 1 and Setup 2.


| Parameter | Setup 1 | Setup 2 |
| --- | --- | --- |
| Namespaces (N)| 40 | 50 |
| Sidecars (N x 40) | 1600 | 2000 |
| Services (N x 20) | 800 | 1000 |
| Virtual Services (N x 2) | 80 | 100|
| Gateways (N) | 40 | 50 |
| Configuration change rate (N/4 per minute) | 10/min | 12/min |

The following table shows the impact enabling namespace isolation has in the resource consumption of Setup 1 and Setup 2:

| Resource | Setup 1 || Setup 2 ||
| --- | --- | --- | --- | --- |
| Namespace Isolation | Enabled |  Disabled | Enabled | Disabled |
| Pilot replicas | 1  | 2 | 1 | 3 |
| Pilot CPU      | 1 vCPU | 5 vCPU | 1 vCPU | 8 vCPU |
| Pilot Memory   | 1.5 GB | 4 GB | 1.5 GB | 8 GB |
| Proxy Memory (per instance) | 50 MB  | 170 MB | 50 MB  | 225 MB |

## Size and capacity planning

Using the available the performance data, you can make educated sizing and capacity planning decisions for your Istio mesh.
Your capacity planning effort depends on the following factors among many others:

* The kind of application running in the mesh.
* The transaction volume of the mesh.
* The Istio features enabled. 

You need to consider capacity from many angles: 

* How much total throughput the application has to support?
* At what latency?
* How many requests pass through the mesh? 

We updated the Grafana dashboard for Istio performance to provide this data for any workload within your Istio mesh.

The following table shows the resource requirements for Istio's main components in a typical mesh configuration:

| Istio Component | CPU | Memory | Condition |
| --- | --- | --- | --- |
| Proxy | 0.6 vCPU | 50 MB per instance | CPU: 1000 mesh requests per second (rps); Memory: 1000 services, 2000 sidecars with namespace isolation enabled. |
| Telemetry | 0.6 vCPU | 200 MB | 1000 mesh requests/sec |
| Pilot | 1 vCPU | 1.5 GB | 1000 services, 2000 sidecars with namespace isolation enabled. |


