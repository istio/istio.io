---
title: Introducing multicluster support for ambient mode
description: Introducing multicluster support for ambient mode
date: 2025-08-04
attribution: Jackie Maertens (Microsoft), Keith Mattix (Microsoft), Mikhail Krinkin (Microsoft), Steven Jin (Microsoft)
keywords: [ambient,multicluster]
---

Multicluster has been one of the most requested Ambient features — and as of Istio 1.27, it's now available.
We sought to capture the benefits and avoid the complications of multicluster architectures using the same modular design that ambient users love.
While still in alpha, this release delivers the core functionality of a multicluster mesh and lays the groundwork for a full feature set in upcoming releases.

## Multicluster's Many Benefits (and Challenges)

Multicluster architectures increase outage resilience, shrink the blast radiuses,
ease adoption of data residence policies, and simplify cost tracking.
That said, integrating multiple clusters poses connectivity, security, and operation hurdles.

In a single Kubernetes cluster, every pod can directly connect to another pod via a pod IP or service VIP.
However, in a multicluster deployment, there is no guarantee that the IP address spaces of different clusters are disjoint.
Even if the spaces were disjoint, users would need to configure routing tables to route traffic from one cluster to another.
Cross-cluster connectivity means that pod-to-pod traffic can leave cluster boundaries -- and that pods may accept connections from outside the cluster.
Without care, an attacker could connect to a vulnerable pod, or sniff unencrypted traffic.
All of this must be orchestrated through APIs that are both secure and simple enough to keep pace with ever-changing environments.

## Key Components.

Ambient multicluster extends ambient with new components and minimal APIs to
securely connect clusters using the same lightweight, modular architecture of ambient.

### East-West Gateways

Each cluster deploys an East-West gateway with a globally routable IP that acts as an entrypoint for cross cluster communication.
A ztunnel communicates across clusters by connecting to the east-west gateway and sending the destination service FQDN.
The east-west gateway will then forward the connection to a cluster-local pod of its choosing.
As such, we do not need to worry about overlapping IP spaces because we never directly address a pod in a remote cluster.
Ambient multicluster achieves cross-cluster connectivity without changes to cluster connectivity.

The east-west gateways are configured using GatewayAPI and controlled by istiod.
By using these ambient and declarative APIs, there is no need to restart workloads, manage IP address spaces, or configure routing tables.

### Double HBONE

Ambient Multicluster uses nested [HBONE](https://istio.io/latest/docs/ambient/architecture/hbone/) connections to secure traffic traversing cluster boundaries to extend ambient's strong security.
An outer HBONE connects the source ztunnel to its the east-west gateway while an inner HBONE tunnel extends the outer the connection to the destination.
The outer HBONE connection encrypts cross cluster traffic, encrypts the destination service FQDN, and allows the east-west gateway to verify the source's identity.
The inner HBONE connection encrypts traffic end-to-end, allowing for identity verification of the destination pod.
Put together, the two HBONE layers stop unauthenticated access, protect against data sniffing, and still allow ztunnel to verify the destination’s identity.
At the same time, it allows ztunnel to effectively reuse cross cluster connections, minimizing TLS handshakes.

The one drawback is that we encrypt application data twice (once for the outer HBONE and once for the inner HBONE).
We found this to be an acceptable drawback because it allows us to stick with open standards, and we expect the extra encryption to be negligible compared to the cost of sending data across clusters.

{{< image link="./mc-ambient-traffic-flow.png" caption="Istio Ambient Multicluster traffic Flow" >}}

### ServiceScope API

Once clusters are securely connected, marking services as global to allow cross cluster communication,
the `ServiceScope` API allows mesh administrators to mark which combinations of labels make a service global,
and app developers can label their services accordingly.
A global service is one has endpoints in all clusters and can be accessed from any cluster.
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
Although the default value is straightforward, the API is flexible and can express complex conditions using a mix of ANDs and ORs.

By default, ztunnel will load balance traffic uniformly across clusters, but this can be configured using the service's `trafficDistribution` field to only reach across clusters when there are no local endpoints.
Thus users have control over whether and when traffic crosses cluster boundaries.

## Limitations and Roadmap

Although the current implementation of ambient multicluster has strong security and the basic feature set of a multicluster product,
there is still a lot of work to be done.

For example, currently, we require that global services, attached waypoints, and serviceScope configuration have uniform configuration across all clusters.
Although this greatly simplified our alpha implementation, we are looking to increase flexibility by allowing for more configuration skew.

Similarly, waypoints and L7 policy enforcement have proven difficult since different clusters might have different policy.
In our alpha implementation, if a service has a waypoint, it will go through said waypoint in the destination cluster.
This reduces unexpected surprises by enforcing the destination cluster's L7 authorization policy, but does take away the ability to perform L7 cross-cluster failover.
Eventually, we would like to also apply L7 policy in the source cluster, but this is not yet implemented.

We are also looking to improve our reference documentation, guides, testing, and performance as well as thinking about deployment models other than multi-primary.

If you would like to try out Ambient Multicluster, please follow [this guide](TODO).
Since many details are in discussion, we would love to hear any of your thoughts, comments, and use cases.
You can find ways to reach us on the [Istio community page](https://istio.io/latest/about/community/).
