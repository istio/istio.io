---
title: Introducint Ambient Multicluster
description: How Ambient Multicluster lets you connect multiple clusters in a single ambient mesh.
publishdate: 08-04-2025
attribution: Steven Jin Xuan (Microsoft)
keywords: [ambient,multicluster]
---

Multicluster has been one of the most requested Ambient features — and as of Istio 1.27, it’s now available in alpha.
Ambient Multicluster enables secure, transparent communication between clusters using the same lightweight, modular architecture users already rely on.
While still in alpha, this release delivers the core functionality of a multicluster mesh and lays the groundwork for a complete feature set in upcoming releases.

## Connectivity

In a single Kubernetes cluster, every pod can directly connect to another pod via a pod or service through a unique IP address as per the [Kubernetes Network Model](https://kubernetes.io/docs/concepts/services-networking/).
However, in a multicluster mesh, there is no guarantee that the IP address spaces of different clusters are disjoint.
Even if it was, there is no guarantee that routing tables are set up to route from one cluster to another.
In Ambient Multicluster, we connect clusters by deploying east-west gateways with globally routable IP addresses and by marking services as global.

The `ServiceScope` API allows mesh administrators to mark which combinations of labels make a service global,
and app developers can label their services accordingly.
By default, services labeled `istio.io/global=true` are marked global.
Then, `istiod` informs each ztunnel how many endpoints there are for each global service.
If ztunnel decides to send traffic to a remote cluster, then it will direct the traffic to the remote cluster's east-west gateway
and the east-west gateway will pick the destination pod.
This architecture obviates the need for ztunnel to know about every pod in the mesh, while still providing enough information for ztunnel to load balance across clusters.

By default ztunnel will load balance traffic uniformly across all clusters,
but you can control the load balancing behavior of a service with its [`trafficDistribution`](https://kubernetes.io/docs/concepts/services-networking/service/#traffic-distribution).

## Security

In both Sidecar and Ambient Multicluster, proxies send traffic to east-west gateways indicating the destination service, and the east-west gateway picks the destination pod.
Sidecar mode indicates the destination service using TLS SNI.
Not only does this communicate the destination service with no encryption,
there is no way for the east-west gateway to apply identity-based policy at the edge of your cluster.

Rather than relying on SNI tricks, Ambient Multicluster uses nested [HBONE](https://istio.io/latest/docs/ambient/architecture/hbone/) connections to enable cross-cluster connectivity.
We first establish an outer HBONE connection to the east-west gateway.
Then, within the outer HBONE connection we create an inner HBONE connection that the east-west gateway forwards opaquely to the destination ztunnel of its choosing.

Since the client ztunnel participates in two mTLS (once with the east-west gateway, and once with the destination ztunnel), identity is enforced both at the edge of the cluster and the destination.
As such, non-mesh traffic cannot enter clusters through east-west gateways.
Also, since ztunnel communicates the destination service in HBONE, it is invisible to outside observers.
Further, HBONE allows us to reuse TLS connections between ztunnel proxies and east-west gateways (already implemented) as well as between ztunnel proxies in different clusters (to be implemented), thus reducing the total number of TCP/TLS handshakes and identity verification steps.
The one drawback is that we encrypt application data twice (once for the outer HBONE and once for the inner HBONE).
We found this to be an acceptable drawback because it allows us to stick with open standards, and we expect the extra encryption to be negligible compared to the cost of sending data across clusters. 

## Sameness

Even though clusters in a multicluster mesh need not be identical, we do require some uniformity across clusters.
Some requirements are necessary for two clusters to function in the same mesh,
while others only exist because of Ambient Multicluster's alpha state.

### Identity

Since a core feature of double HBONE is allowing identity verification at the east-west gateway, we must define how identities change across cluster boundaries.
Ambient Multicluster adopts {{< gloss "namespace sameness" >}}namespace sameness{{< /gloss >}} just like the rest of Istio.
This means that the same identity is indistinguishable across clusters.
Cluster boundaries have no effect on identity.
We have no plans on departing from namespace sameness in any future releases.

### Service configuration

For our alpha release, we require all services and service entries to have the exact same configuration across clusters.
Notably, waypoint configuration also has to be uniform.

One question we struggled with was that of where cross cluster traffic should traverse a waypoint.
When sending cross cluster traffic to a service with a waypoint, should traffic traverse a waypoint in the client's cluster or the destination's cluster?
Traversing waypoints in the client's cluster allows us to apply policies such as L7 cross-cluster failover.
On the other hand, traversing waypoints in the destination cluster allows enforcing the destination cluster's L7 policy.
Ultimately, we decided on the latter for our alpha release to avoid any authorization policy-related surprises.

There are many other nuances on how we apply L7 policy and how to handle cross-cluster configuration skew.
That said, we are actively looking for ways to loosen these requirements and support L7 policy to be applied in the client cluster.
This should ease the setup process of Ambient and allow for gradual configuration rollouts without the risk of undefined behavior.

### Meshconfig

Given that we have multiple clusters in a single mesh, we assume that MeshConfig is uniform across clusters.
Crucially, this assumption means that `ServiceScope` must be uniform across clusters, since `ServiceScope` is part of MeshConfig.
In other words, the criteria for a service to be marked as global must be the same in all clusters.
If we also consider the fact that all services must share the same configuration, services are marked global in every cluster, or no cluster.
As with service configuration, we are exploring ways to loosen Meshconfig sameness requirements and more fine-grained ways of marking services global.

## Looking ahead

Other than allowing configuration skew across clusters, there is a lot of work to do to promote Ambient Multicluster to beta.
We are looking to improve our reference documentation, guides, testing, and performance.
We are also thinking about deployment models other than multi-primary.
If you would like to try out Ambient Multicluster, please follow [this guide](TODO).
Since many details are in discussion, we would love to hear any of your thoughts, comments, and use cases.
You can contact us through [Slack](TODO) or [GitHub](TODO).
