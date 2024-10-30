---
title: "Scaling in the Clouds: Istio Ambient vs. Cilium"
description: A Deep Dive into Performance at Scale.
publishdate: 2024-10-21
attribution: "Mitch Connors"
keywords: [istio,cilium,analysis]
---

A common question from prospective Istio users is "how does Istio compare to Cilium?"  While Cilium originally only provided L3/L4 functionality, including network policy, recent releases have added service mesh functionality using Envoy, as well as WireGuard encryption. Like Istio, Cilium is a CNCF Graduated project, and has been around in the community for many years.

Despite offering a similar feature set on the surface, the two projects have substantially different architectures, most notably Cilium’s use of eBPF and WireGuard for processing and encrypting L4 traffic in the kernel, contrasted with Istio’s ztunnel component for L4 in user space. These differences have resulted in substantial speculation about how Istio will perform at scale compared to Cilium.

While many comparisons have been made about tenancy models, security protocols and basic performance of the two projects, there has not yet been a full evaluation published at enterprise scale. Rather than emphasizing theoretical performance, we put Istio's ambient mode and Cilium through their paces, focusing on key metrics like latency, throughput, and resource consumption. We cranked up the pressure with realistic load scenarios, simulating a bustling Kubernetes environment. Finally, we pushed the size of our AKS cluster up to 1,000 nodes on 11,000 cores, to understand how these projects perform at scale. Our results show areas where each can improve, but also indicate that Istio is the clear winner.

## Test Scenario

In order to push Istio and Cilium to their limits, we created 500 different services, each backed by 100 pods. Each service is in a separate namespace, which also contains one [Fortio](https://fortio.org/) load generator client. We restricted the clients to a node pool of 100 32-core machines, to eliminate noise from collocated clients, and allocated the remaining 900 8-core instances to our services.

{{< image width="60%"
    link="./scale-scenario.png"
    alt="Scaling to 500 services with 50,000 pods."
    >}}

For the Istio test, we used Istio’s ambient mode, with a [waypoint proxy](/docs/ambient/usage/waypoint/) in every service namespace, and default install parameters. In order to make our test scenarios similar, we had to turn on a few non-default features in Cilium, including WireGuard encryption, L7 Proxies, and Node Init. We also created a Cilium Network Policy in each namespace, with HTTP path-based rules. In both scenarios, we generated churn by scaling one service to between 85 and 115 instances at random every second, and relabeling one namespace every minute. To see the precise settings we used, and to reproduce our results, see [my notes](https://github.com/therealmitchconnors/tools/blob/2384dc26f114300687b21f921581a158f27dc9e1/perf/load/many-svc-scenario/README.md).

## Scalability Scorecard

{{< image width="80%"
    link="./scale-scorecard.png"
    alt="Scalability Scorecard: Istio vs. Cilium!"
    >}}
Istio was able to deliver 56% more queries at 20% lower tail latency.  The CPU usage was 30% less for Cilium, though our measurement does not include the cores Cilium used to process encryption, which is done in the kernel.

Taking into account the resource used, Istio processed 2178 Queries Per Core, vs Cilium's 1815, a 20% improvement.

* **The Cilium Slowdown:** Cilium, while boasting impressive low latency with default install parameters, slows down substantially when Istio’s baseline features such as L7 policy and encryption are turned on. Additionally, Cilium’s memory and CPU utilization remained high even when no traffic was flowing in the mesh. This can impact the overall stability and reliability of your cluster, especially as it grows.
* **Istio, The Steady Performer:** Istio's ambient mode, on the other hand, showed its strength in stability and maintaining decent throughput, even with the added overhead of encryption. While Istio did consume more memory and CPU than Cilium under test, its CPU utilization settled to a fraction of Cilium’s when not under load.

## Behind the Scenes: Why the Difference?

The key to understanding these performance differences lies in the architecture and design of each tool.

* **Cilium's Control Plane Conundrum:** Cilium runs a control plane instance on each node, leading to API server strain and configuration overhead as your cluster expands. This frequently caused our API server to crash, followed by Cilium becoming unready, and the entire cluster becoming unresponsive.
* **Istio's Efficiency Edge:** Istio, with its centralized control plane and identity-based approach, streamlines configuration and reduces the burden on your API server and nodes, directing critical resources to processing and securing your traffic, rather than processing configuration. Istio takes further advantage of the resources not used in the control plane by running as many Envoy instances as a workload needs, while Cilium is limited to one shared Envoy instance per node.

## Digging Deeper

While the objective of this project is to compare Istio and Cilium scalability, several constraints make a direct comparison difficult.

### Layer 4 Isn’t always Layer 4

While Istio and Cilium both offer L4 policy enforcement, their APIs and implementation differ substantially. Cilium implements Kubernetes NetworkPolicy, which uses labels and namespaces to block or allow access to and from IP Addresses. Istio offers an AuthorizationPolicy API, and makes allow and deny decisions based on the TLS identity used to sign each request. Most defense-in-depth strategies will need to make use of both NetworkPolicy and TLS-based policy for comprehensive security.

### Not all Encryption is Created Equal

While Cilium offers IPsec for FIPS-compatible encryption, most other Cilium features such as L7 policy and load balancing are incompatible with IPsec. Cilium has much better feature compatibility when using WireGuard encryption, but WireGuard cannot be used in FIPS-compliant environments. Istio, on the other-hand, because it strictly complies with TLS protocol standards, always uses FIPS-compliant mTLS by default.

### Hidden Costs

While Istio operates entirely in user space, Cilium’s L4 dataplane runs in the Linux kernel using eBPF. Prometheus metrics for resource consumption only measure user space resources, meaning that all kernel resources used by Cilium are not accounted for in this test.

## Recommendations: Choosing the Right Tool for the Job

So, what's the verdict? Well, it depends on your specific needs and priorities. For small clusters with pure L3/L4 use cases and no requirement for encryption, Cilium offers a cost-effective and performant solution. However, for larger clusters and a focus on stability, scalability, and advanced features, Istio's ambient mode, along with an alternate NetworkPolicy implementation, is the way to go. Many customers choose to combine the L3/L4 features of Cilium with the L4/L7 and encryption features of Istio for a defense-in-depth strategy.

Remember, the world of cloud-native networking is constantly evolving. Keep an eye on developments in both Istio and Cilium, as they continue to improve and address these challenges.

## Let's Keep the Conversation Going

Have you worked with Istio's ambient mode or Cilium? What are your experiences and insights? Share your thoughts in the comments below. Let's learn from each other and navigate the exciting world of Kubernetes together!
