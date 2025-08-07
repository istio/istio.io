---
title: Introducing multicluster support for ambient mode
description: Introducing multicluster support for ambient mode.
date: 2025-08-04
attribution: Jackie Maertens (Microsoft), Keith Mattix (Microsoft), Mikhail Krinkin (Microsoft), Steven Jin (Microsoft)
keywords: [ambient,multicluster]
---

Multicluster has been one of the most requested ambient features — and as of Istio 1.27, it's now available.
We sought to capture the benefits and avoid the complications of multicluster architectures using the same modular design that ambient users love.
While still in alpha, this release delivers the core functionality of a multicluster mesh and lays the groundwork for a full feature set in upcoming releases.

## Multicluster's Many Benefits (and Challenges)

Multicluster architectures increase outage resilience, shrink the blast radii,
ease adoption of data residence policies, and simplify cost tracking.
That said, integrating multiple clusters poses connectivity, security, and operation hurdles.

In a single Kubernetes cluster, every pod can directly connect to another pod via a unique pod IP or service VIP.
We lose these guarantees when we start thinking of multicluster architectures.
IP address spaces of different clusters might overlap.
Even if they didn't, nodes in one cluster would not know how to route traffic from one cluster to another.

Establishing cross-cluster connectivity also presents security challenges.
Cross-cluster connectivity means that pod-to-pod traffic can leave cluster boundaries -- and that pods may accept connections from outside the cluster.
Without care, an attacker could connect to a vulnerable pod, or sniff unencrypted traffic.

For a multicluster solution to be viable, it must at least securely connect clusters, and do so
through APIs that are simple enough to keep pace with ever-changing environments.

## Key Components.

Ambient multicluster extends ambient with new components and minimal APIs to
securely connect clusters using the same lightweight, modular architecture.

### East-West Gateways

Each cluster deploys an east-west gateway with a globally routable IP that acts as an entrypoint for cross-cluster communication.
The east-west gateways are configured using GatewayAPI and controlled by istiod.
A ztunnel communicates across clusters by connecting to the remote cluster's east-west gateway and sending the destination service FQDN.
The east-west gateway will then forward the connection to a cluster-local pod of its choosing.
As such, overlapping IP spaces are of no concern because we never directly address a pod in a remote cluster.
Ambient multicluster achieves cross-cluster connectivity without changes to cluster networking configuration.
We can achieve this connectivity using only ambient and declarative APIs.
There is no need to restart workloads, manage IP address spaces, or configure routing tables.

### Double HBONE

Ambient Multicluster uses nested [HBONE](https://istio.io/latest/docs/ambient/architecture/hbone/) connections to secure traffic traversing cluster boundaries while preserving ambient's strong security.
An outer HBONE connects the source ztunnel to its east-west gateway while an inner HBONE tunnel extends the connection to the destination.
The outer HBONE connection encrypts cross-cluster traffic, encrypts the destination service FQDN, and allows the source ztunnel and east-west gateway to verify each other's identity.
The inner HBONE connection encrypts traffic end-to-end, which allows the source ztunnel and destination ztunnel to verify each other's identity.
Put together, the two HBONE layers stop unauthenticated access, protect against data sniffing, and allow identity verification at every step.
At the same time, the HBONE layers allow ztunnel to effectively reuse cross-cluster connections, minimizing TLS handshakes.

One drawback is that we encrypt application data twice (once for the outer HBONE and once for the inner HBONE).
We found this to be an acceptable drawback because it allows us to stick with open standards, and we expect the extra encryption to be negligible compared to the cost of sending data across clusters.

{{< image link="./mc-ambient-traffic-flow.png" caption="Istio ambient multicluster traffic flow" >}}

### Service discovery and scope

Once we have securely connected our clusters, we enable cross-cluster communication for a service by marking it global.
When a service becomes global, istiod will configure east-west gateways to accept and route traffic destined to the global service.
Istiod will also read remote apiservers and configure ztunnel with the number of pods for the global service per remote cluster.
Ztunnel can then proxy traffic to the global service across clusters.

Mesh administrators define the label-based criteria for global services via the `ServiceScope` API,
and app developers opt into global behavior by labeling their services accordingly.
The default `ServiceScope` is

{{< text yaml >}}
=======
serviceScopeConfigs:
  - servicesSelector:
      matchExpressions:
        - key: istio.io/global
          operator: In
          values: ["true"]
    scope: GLOBAL
{{< /text >}}

meaning that any service with the `istio.io/global=true` label is global.
Although the default value is straightforward, the API is flexible and can express complex conditions using a mix of ANDs and ORs.

By default, ztunnel will load balance traffic uniformly across all endpoints --even remote ones--, but this can be configured using the service's `trafficDistribution` field to only cross cluster boundaries when there are no local endpoints.
Thus, users have control over whether and when traffic crosses cluster boundaries.

## Limitations and Roadmap

Although the current implementation of ambient multicluster has the foundational features for a multicluster implementation,
there is still a lot of work to be done.

For example, currently, we require that global services, attached waypoints, and `ServiceScope` configuration have uniform configuration across all clusters.
This greatly simplified our alpha implementation, but we are looking to allow for more configuration skew.

Similarly, waypoints and L7 policy enforcement have proven difficult since different clusters might have different policies.
In our alpha implementation, if a service has a waypoint, it will go through said waypoint in the destination cluster.
This reduces unexpected surprises by enforcing the destination cluster's L7 authorization policy, but remove the ability to perform L7 cross-cluster failover.
Eventually, we would like to apply L7 policy in both the source and destination cluster.
We are also looking to improve our reference documentation, guides, testing, and performance.
Currently, we only support a multi-primary deployment model with a single network per cluster, but would eventually want to support other cluster and network models.

If you would like to try out ambient multicluster, please follow [this guide](TODO).
Since many details are in discussion, we would love to hear any of your thoughts, comments, and use cases.
You can find ways to reach us on the [Istio community page](https://istio.io/latest/about/community/).
