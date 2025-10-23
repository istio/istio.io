---
title: Ambient Multicluster Performance
description: Ambient Multicluster performance and scalability summary.
weight: 30
keywords:
  - performance
  - scalability
  - scale
  - multicluster
owner: istio/wg-environments-maintainers
test: n/a
---

Multicluster deployments with ambient mode enable you to offer truly globally resilient applications at scale with minimal overhead. In addition to its normal functions, the Istio control plane creates watches on all remote clusters to keep an up-to-date listing of what global services each cluster offers. The Istio data plane can route traffic to these remote global services, either as a part of normal traffic distribution, or specifically when the local service is unavailable.

## Control plane performance

As documented [here](/docs/ops/deployment/performance-and-scalability), the Istio control plane generally scales as the product of deployment changes, configuration changes, and the number of connected proxies. Ambient multicluster adds two new dimensions to the control plane scalability story: number of remote clusters, and number of remote services. Because the control plane is not programming proxies for remote clusters (assuming a multi-primary deployment topology), adding 10 remote services to the mesh has substantially lower impact on the control plane performance than adding 10 local services.

Our multicluster control plane load test created 300 services with 4000 endpoints in each of 10 clusters, and added these clusters to the mesh one at a time. The approximate control plane impact of adding a remote cluster at this scale was **1% of a CPU core, and 180 MB of memory**. At this scale, it should be safe to scale well beyond 10 clusters in a mesh with a properly scaled control plane. One item to note is that for multicluster scalability, horizontally scaling the control plane will not help, as each control plane instance maintains a complete cache of remote services. Instead, we recommend modifying the resource requests and limits of the control plane to scale vertically to meet the needs of your multicluster mesh.

## Data plane performance

When traffic is routed to a remote cluster, the originating data plane establishes an encrypted tunnel to the destination cluster's east/west gateway. It then establishes a secondary encrypted tunnel inside the first, which is terminated at the destination data plane. This use of inner and outer tunnels allows the data plane to securely communicate with the remote cluster without knowing the details of which pod IPs represent which services.

This double encryption does carry some overhead, however. The data plane load test measures the response latency of traffic between pods in the same cluster, versus those in two different clusters, to understand the impact of double encryption on latency. Additionally, double encryption requires double handshakes, which disproportionately affects the latency of new connections to the remote cluster. As you can see below, our initial connections observed an average of 2.2 milliseconds (346%) additional latency, while requests using existing connections observed an increase of 0.13 milliseconds (72%). While these numbers appear significant, it is expected that most multicluster traffic will cross availability zones or regions, and the observed increase in overhead latency will be minimal compared to the overall transit latency between data centers.

{{< image link="./ambient-mc-dataplane-reconnect.png" caption="request latency with reconnect" width="90%" >}}

{{< image link="./ambient-mc-dataplane-existing.png" caption="request latency without reconnect" width="90%" >}}
