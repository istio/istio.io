---
title: Introducing multicluster support for ambient mode (alpha)
description: Istio 1.27 adds alpha ambient multicluster support, extending ambient's familiar lightweight, modular architecture to deliver secure connectivity, discovery and load balancing across clusters.
date: 2025-08-04
attribution: Jackie Maertens (Microsoft), Keith Mattix (Microsoft), Mikhail Krinkin (Microsoft), Steven Jin (Microsoft)
keywords: [ambient,multicluster]
---

Multicluster has been one of the most requested features of ambient -— and as of Istio 1.27, it is available in alpha status!
We sought to capture the benefits and avoid the complications of multicluster architectures while using the same modular design that ambient users love.
This release brings the core functionality of a multicluster mesh and lays the groundwork for a richer feature set in upcoming releases.

## The Power & Complexity of Multicluster

Multicluster architectures increase outage resilience, shrink your blast radius, and scale across data centers.
That said, integrating multiple clusters poses connectivity, security, and operational challenges.

In a single Kubernetes cluster, every pod can directly connect to another pod via a unique pod IP or service VIP.
These guarantees break down in multicluster architectures;
IP address spaces of different clusters might overlap,
and even without overlap, the underlying infrastructure would need configuration to route cross-cluster traffic.

Cross-cluster connectivity also presents security challenges.
Pod-to-pod traffic will leave cluster boundaries and pods will accept connections from outside their cluster.
Without identity verification at the edge of the cluster and strong encryption,
an outside attacker could exploit a vulnerable pod or intercept unencrypted traffic.

A multicluster solution must securely connect clusters and do so
through simple, declarative APIs that keep pace with dynamic environments where clusters are frequently added and removed.

## Key Components

Ambient multicluster extends ambient with new components and minimal APIs to
securely connect clusters using ambient's lightweight, modular architecture.
It builds on the {{< gloss "namespace sameness" >}}namespace sameness{{< /gloss >}} model
so services keep their existing DNS names across clusters, allowing you to control cross-cluster communication without changing application code.

### East-West Gateways

Each cluster has an east-west gateway with a globally routable IP acting as an entry point for cross-cluster communication.
A ztunnel connects to the remote cluster's east-west gateway, identifying the destination service by its namespaced name.
The east-west gateway then load balances the connection to a local pod.
Using the east-west gateway's routable IP removes the need for inter-cluster routing configuration,
and addressing pods by namespaced name rather than IP eliminates issues with overlapping IP spaces.
Together, these design choices enable cross-cluster connectivity without changing cluster networking or restarting workloads,
even as clusters are added or removed.

### Double HBONE

Ambient multicluster uses nested [HBONE](/docs/ambient/architecture/hbone) connections to efficiently secure traffic traversing cluster boundaries.
An outer HBONE connection encrypts traffic to the east-west gateway and allows the source ztunnel and east-west gateway to verify each other's identity.
An inner HBONE connection encrypts traffic end-to-end, which allows the source ztunnel and destination ztunnel to verify each other's identity.
At the same time, the HBONE layers allow ztunnel to effectively reuse cross-cluster connections, minimizing TLS handshakes.

{{< image link="./mc-ambient-traffic-flow.png" caption="Istio ambient multicluster traffic flow" >}}

### Service Discovery and Scope

Marking a service global enables cross-cluster communication.
Istiod configures east-west gateways to accept and route global service traffic to local pods and
programs ztunnels to load balance global service traffic to remote clusters.

Mesh administrators define the label-based criteria for global services via the `ServiceScope` API,
and app developers label their services accordingly.
The default `ServiceScope` is

{{< text yaml >}}
serviceScopeConfigs:
  - servicesSelector:
      matchExpressions:
        - key: istio.io/global
          operator: In
          values: ["true"]
    scope: GLOBAL
{{< /text >}}

meaning that any service with the `istio.io/global=true` label is global.
Although the default value is straightforward, the `ServiceScope` API can express complex conditions using a mix of ANDs and ORs.

By default, ztunnel load balances traffic uniformly across all endpoints --even remote ones--,
but this is configurable through the service's `trafficDistribution` field to only cross cluster boundaries when there are no local endpoints.
Thus, users have control over whether and when traffic crosses cluster boundaries with no changes to application code.

## Limitations and Roadmap

Although the current implementation of ambient multicluster has the foundational features for a multicluster solution,
there is still a lot of work to be done.
We are looking to improve the following areas

* Service and waypoint configuration must be uniform across all clusters.
* No cross-cluster L7 failover (L7 policy is applied at the destination cluster).
* No support for direct pod addressing or headless services.
* Support only for multi-primary deployment model.
* Support only for one network per cluster deployment model.

We are also looking to improve our reference documentation, guides, testing, and performance.

If you would like to try out ambient multicluster, please follow [this guide](/docs/ambient/install/multicluster).
Remember, this feature is in alpha status and not ready for production use.
We welcome your bug reports, thoughts, comments, and use cases -- you can reach us on [GitHub](https://github.com/istio/istio) or [Slack](https://istio.slack.com/).
