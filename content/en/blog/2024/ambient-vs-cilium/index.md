---
title: "Scaling in the Clouds: Istio Ambient vs. Cilium"
description: A Deep Dive into Performance at Scale.
publishdate: 2024-10-16
attribution: "Mitch Connors (Microsoft)"
keywords: [istio,cilium,analysis]
---

A common question from prospective Istio users is "how does Istio compare to Cilium?"  While Cilium originally only provided L3/L4 Network Policy, recent releases have added L7 functionality with Envoy, as well as Wireguard Encryption. Like Istio, Cilium is a CNCF Graduated project, and has been around in the community for many years.

Despite these similarities, the two projects have substantially different architectures, most notably cilium’s eBPF program for processing L4 in the kernel, contrasted with Istio’s ztunnel component for L4 in user space. These differences have resulted in substantial speculation about how Istio will perform at scale compared to Cilium.

Rather than emphasizing theoretical performance, we put Istio Ambient and Cilium through their paces, focusing on key metrics like latency, throughput, and resource consumption. We also cranked up the pressure with realistic load scenarios, simulating a bustling Kubernetes environment. Finally, we pushed the size of our AKS cluster up to 1000 nodes on 11,000 cores, to understand how these products perform at scale. Our results show areas where each project can improve, but also indicate a clear winner at scale.

## Test Scenario

In order to push Istio and Cilium to their limits, we created 500 different services, each backed by 100 pods. Each service is in a separate namespace, which also contains one Fortio load generator client. We restricted the clients to a node pool of 100 32 core machines, to eliminate noise from collocated clients, and allocated the remaining 900 8 core instances to our services.

{{< image width="60%"
    link="./scale-scenario.png"
    alt="Scaling to 500 services with 50,000 pods."
    >}}

For the Istio test, we used Istio’s Ambient Mode, with a Waypoint in every service namespace, and default install parameters. In order to make our test scenarios similar, we had to turn on a few non-default features in Cilium, including Wireguard Encryption, L7 Proxies, and Node Init. We also created a Cilium Network Policy in each namespace, with HTTP path-based rules. In both scenarios, we generated churn by scaling one service to between 85 and 115 instances at random every second, and relabeling one namespace every minute. To see the precise settings we used, and to reproduce our results, see this site.

## Scalability Scorecard

{{< image width="80%"
    link="./scale-scorecard.png"
    alt="Scalability Scorecard: Istio vs. Cilium!"
    >}}

* **The Cilium Slowdown** Cilium, while boasting impressive low latency with default install parameters, slows down substantially when Istio’s baseline features such as L7 policy and encryption are turned on. Additionally, cilium’s memory and CPU utilization remained high even when no traffic was flowing in the mesh. This can impact the overall stability and reliability of your cluster, especially as it grows.
* **Istio Ambient: The Steady Performer** Istio Ambient, on the other hand, showed its strength in stability and maintaining decent throughput, even with the added overhead of encryption. While Ambient did consume more memory and CPU than cilium under test, its CPU utilization settled to a fraction of cilium’s when not under load.

## Behind the Scenes: Why the Difference?

The key to understanding these performance differences lies in the architecture and design of each tool.

* **Cilium's Control Plane Conundrum:** Cilium runs a control plane instance on each node, leading to potential API server strain and configuration overhead as your cluster expands. This frequently caused our API Server to crash, followed by cilium becoming unready, and the entire cluster becoming unresponsive.
* **Istio's Efficiency Edge:** Istio, with its centralized control plane and identity-based approach, streamlines configuration and reduces the burden on your API server, directing critical resources to processing and securing your traffic, rather than processing configuration.

## Digging Deeper

While the objective of this project is to compare Istio and Cilium scalability, several constraints make a direct comparison difficult.

### Layer 4 Isn’t always Layer 4

While Istio and Cilium both offer L4 policy enforcement, their APIs and implementation differ substantially. Cilium implements Kubernetes NetworkPolicy, which uses labels and namespaces to block or allow access to and from IP Addresses. Istio offers the AuthorizationPolicy API, and makes allow and deny decisions based on the TLS identity used to sign each request. Most defense-in-depth strategies will need to make use of both NetworkPolicy and TLS-based policy for comprehensive security.

### Not all Encryption is Created Equal

One challenge when comparing Istio and Cilium is the difference between how these projects approach encryption. While Cilium offers IPsec for FIPS-compatible encryption, most other Cilium features such as L7 Policy and Load Balancing are incompatible with IPsec. Cilium has much better feature compatibility when using Wireguard encryption, but Wireguard cannot be used in FIPS-compliant environments. Istio, on the other-hand, uses FIPS-compliant mTLS by default, which has the added benefit of complying with Zero-Trust principles.

### Hidden Costs

While Istio operates entirely in user space, Cilium’s L4 dataplane runs in the Linux Kernel using eBPF. Prometheus metrics for resource consumption only measure user space resources, meaning that all Kernel resources used by Cilium are not accounted for in this test.

## Recommendations: Choosing the Right Tool for the Job

So, what's the verdict? Well, it depends on your specific needs and priorities. If low latency is your absolute top priority and you have a smaller cluster, Cilium might still be a viable option. However, for larger clusters and a focus on stability, scalability, and advanced features, Istio Ambient, along with an alternate NetworkPolicy implementation is the way to go.

Remember, the world of cloud-native networking is constantly evolving. Keep an eye on developments in both Istio and Cilium, as they continue to improve and address these challenges.

## Let's Keep the Conversation Going

Have you worked with Istio Ambient or Cilium? What are your experiences and insights? Share your thoughts in the comments below. Let's learn from each other and navigate the exciting world of Kubernetes together\!
