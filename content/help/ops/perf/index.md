---
title: Performance Tuning
description: Istio performance, sizing and tuning guide.
weight: 90
force_inline_toc: true
---
## Istio Performance Tuning

Istio's goal is to have an out of the box configuration that is performant.
However it is difficult to create a configuration that is performant for all use cases.

The following section documents a few configuration knobs that affect performance.

| Knob | Default | Symptom | Description |
| --- | --- | --- | --- |
| [`Sidecar resource`](/docs/reference/config/networking/v1alpha3/sidecar) | Disabled | High memory usage by sidecars and high CPU by Pilot | Enable namespace isolation to get a significant reduction in sidecar memory usage and pilot cpu usage. |
| `global.proxy.concurrency` | `2` | Sidecar resource utilization and latency.| This values should be at least equal to the number of CPU core allocated to the proxy. |
| `pilot.keepaliveMaxServerConnectionAge` | `30m` | Uneven load distribution across Pilot replicas. | Reduce this number if you want quicker rebalancing of load at the cost of increased system churn. |
| `pilot.traceSampling` | `1.0` |  Latency and throughput impact due to tracing. | This can be reduced further from the default. If set to 0.0%, use `x-client-trace-id` header to trace specific requests. |
| `global.disablePolicyChecks` | `true` | Tail latency impact due to policy. | Enable policy checks *only* if you are using rate limiting or another istio-policy feature.|
| `mixer.telemetry.enabled` | `true` | High cpu usage and additional latency by telemetry | Telemetry is a core part of Istio. However if you are only using the networking API and have other means of getting metrics, istio-telemetry can be turned off for a significant reduction in CPU usage.|

### Istio default profile vs. functionality

In order to get a good out of the box performance, Istio 1.1 disabled several features by default.

| Feature | Default | Description |
| --- | --- | --- |
| `global.proxy.accessLogFile` | `""` |  Proxy access logging is disabled because it contributes to high CPU and I/O. Set this to `/dev/stdout` to enable access logging.|
| `mixer.adapters.stdio.enabled` | `false` |  Mixer access logging is disabled because it is a debug feature and it contributes to high CPU and I/O. Set this to `true` to enable access logging.|
| `global.disablePolicyChecks` | `true` | Enable policy checks *only* if you are using rate limiting or another istio-policy feature.|

### Namespace isolation

Namespace isolation using the sidecar resource is a major performance improvement in Istio 1.1
over the previous release of Istio. When namespace isolation is turned on-

- The default connectivity is namespace wide. Previously it was mesh wide.
- Pilot configures envoy with information that is relevant to routing within the namespace.
- Proxy receives less configuration information, therefore the proxy memory usage is lower.

The following table documents the reduction in resource utilization due to namespace isolation.

| Resource | Isolated | Isolated | Isolated | Not Isolated | Not Isolated |
| --- | --- | --- | --- | --- | --- |
| Namespaces (N) | 40 | 50 | 75 | 40 | 50 |
| Sidecars (N x 40) | 1600 | 2000 | 3000 | 1600 | 2000 |
| Services (N x 20) | 800 | 1000 | 1500 | 800 | 1000 |
| Virtual Services (N x 2) | 80 | 100 | 150 | 80 | 100 |
| Gateways (N) | 40 | 50 | 75 | 40 | 50 |
| Config Change Rate (N/4 per minute) | 10 per minute | 12 per minute | 18 per minute | 10 per minute | 12 per minute |
| Pilot replicas | 1  | 1 | 2 | 2 | 3 |
| Pilot CPU      | 1  | 1 | 1.5 | 5 | 8 |
| Pilot Memory   | 1.4 GB | 1.4 GB | 1.8 GB | 4 GB | 8 GB |
| Proxy Memory   | 70 MB  | 80 MB  | 85 MB  | 170 MB | 225 MB |
| Namespace Isolation | Enabled | Enabled | Enabled | Disabled | Disabled |
