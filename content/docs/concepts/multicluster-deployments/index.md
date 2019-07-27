---
title: Multicluster Deployments
description: Describes how a service mesh can be configured to include services from more than one cluster.
weight: 60
---

Istio is a [service mesh](/docs/concepts/what-is-istio/#what-is-a-service-mesh),
the fundamental property of which is its ability to monitor and manage
a network of cooperating microservices under a single administrative domain.
A service mesh essentially combines a set of individual microservices into
a single controllable composite application.

For applications up to a certain size, all of the microservices comprising the
application can be running on a single orchestration platform (e.g., Kubernetes cluster).
Eventually, you may need to distribute most applications and run some or all of their services elsewhere due to one or more of the following reasons:

- Scale
- Redundancy
- Workload isolation
- Compliance
- Integration with legacy services

Istio supports many possible topologies for distributing the services of an
application beyond a single cluster, for example:

- You can use [egress traffic control](/docs/tasks/traffic-management/egress/) to allow workloads inside the mesh
  to access standalone external services or to access services exposed by another loosely-coupled service mesh.
- You can [expand the service mesh](/docs/setup/kubernetes/additional-setup/mesh-expansion/) to include
  services running on VMs or bare metal hosts.
- You can combine the services from more than one cluster into a single composite service mesh.
- You can combine autonomous service meshes in multiple clusters into a loosely coupled [federation of service meshes](#mesh-federation).

## Single multicluster service mesh or mesh federation?

As you plan your multicluster topology, you need to determine if you should combine the clusters into
[a single multicluster mesh](#multicluster-service-mesh) or create [a federation of multiple meshes](#mesh-federation).
To make that decision, ask yourself the following questions:

1. Do you enforce **{{< gloss >}}uniform naming{{< /gloss >}}** in your clusters?

1. Do you want your combined clusters to **expose** all their services to each other? Due to compliance or security
   reasons, you might need {{< gloss >}}selective service exposure{{< /gloss >}}.

1. Are you required to **control all the traffic that enters your cluster**?

1. Will you be able to set **common CA root** for the Citadels running in your clusters?

To choose the correct topology, follow the decision tree below. The diagram shows what topology to implement based on the answers to the questions above:

{{< image width="80%"
    link="./single-mesh-or-mesh-federation.png"
    caption="Decision tree for selecting single multicluster mesh or mesh federation"
>}}

## Multicluster service mesh

A multicluster service mesh is a **single logical** mesh composed of services running in multiple clusters.
A multicluster service mesh has the following characteristics:

- {{< gloss >}}Uniform naming{{< /gloss >}}.
- The combined clusters expose all their services to each other.
- The traffic from the combined clusters is allowed to enter each of the clusters.
- Common CA root between the Citadels in all the clusters.

To learn more, see [single multicluster service mesh or mesh federation?](#single-multicluster-service-mesh-or-mesh-federation).

A multicluster service mesh has the advantage that all the services look the same to clients,
regardless of where the workloads are actually running. It's transparent
to the application whether it's deployed in a single or multicluster service mesh.
To achieve this behavior, a single logical control plane needs to manage all services,
however, the single logical control plane doesn't necessarily need to be a single physical
Istio control plane. There are three possible deployment approaches:

1. Multiple dedicated Istio control planes that have replicated service and routing configurations.

1. A shared Istio control plane that can access and configure the services in more than one cluster. The services are
   directly reachable from all the workloads in all the clusters.

1. The same as the previous approach, but with services reachable through connected gateways.

To select the correct topology, ask yourself the following questions:

1. Do you require **a single control plane?**. Managing multiple Istio control planes
  requires different infrastructure capabilities to those needed to manage a single
  control plane. Be certain of your preference when planning your topology.

1. Are you allowed by the security procedures in your organization to provide **access to Kubernetes APIs** of one
   cluster to other clusters?

1. Are you allowed by the security procedures in your organization to **send telemetry data from one cluster to other
   clusters**?

1. Are the services in your clusters **directly reachable** from all the workloads in all other the clusters?

To choose the correct topology, follow the decision tree below. The diagram shows what topology to implement based on the answers to the questions above:

{{< image width="80%"
    link="./multicluster-mesh-topology.png"
    caption="Decision tree for selecting the correct multicluster mesh topology"
>}}

Even with these three approaches, there is more than one way to configure a multicluster service mesh.
In a large multicluster mesh, a combination of the approaches might even be used. For example,
two clusters might share a control plane while a third has its own.
Which approach to use and how to configure it depends on the requirements of the application
and on the features and limitations of the underlying cloud deployment platform.

### Dedicated control plane topology

In a dedicated control plane topology, each cluster has an identical Istio control plane
installation and each control plane manages its own endpoints.
Using Istio gateways, a common root Certificate Authority (CA), and service entries,
you can configure a single logical service mesh that is composed from the participating clusters.
This approach has no special networking requirements beyond a functional cloud provider's load balancer
implementation and is therefore generally considered the easiest approach to start with when
there is no universal network connectivity between clusters.

{{< image width="80%"
    link="./multicluster-with-gateways.svg"
    caption="Istio mesh spanning multiple Kubernetes clusters using multiple Istio control planes and Gateway to reach remote pods"
>}}

To achieve a single Istio service mesh across the clusters, you configure a common root CA
and replicate any shared services and namespaces in all clusters.
Cross-cluster communication occurs over the Istio gateways of the respective clusters.
All clusters are within a shared administrative control for policy enforcement and security.

In this configuration workloads in each cluster can access other local services using their
Kubernetes DNS suffix, e.g., `foo.ns1.svc.cluster.local`, as usual.
To provide DNS resolution for services in remote clusters, Istio includes a CoreDNS server
that can be configured to handle service names of the form `<name>.<namespace>.global`.
For example, calls from any cluster to `foo.ns1.global` will resolve to the `foo` service in
namespace `ns1` of a specific cluster where it is running as determined by the service discovery
configuration. You configure service discovery of `foo.ns.global` by creating an appropriate
[service entry](/docs/concepts/traffic-management/#service-entries).

To configure this type of multicluster topology, visit our
[dedicated control planes instructions](/docs/setup/kubernetes/install/multicluster/gateways/).

### Shared control plane topology

This multicluster configuration uses a single Istio control plane running on one of the clusters.
The control plane's Pilot manages services on the local and remote clusters and configures the
Envoy sidecars for all of the clusters.

#### Single-network shared control plane topology

The following topology works best in environments where all of the participating clusters
have VPN or similar connectivity so every pod in the mesh is reachable from anywhere else using the
same IP address.

{{< image width="80%"
    link="./multicluster-with-vpn.svg"
    caption="Istio mesh spanning multiple Kubernetes clusters with direct network access to remote pods over VPN"
>}}

In this topology, the Istio control plane is deployed on one of the clusters while all other
clusters run a simpler remote Istio configuration which connects them to the single Istio control plane
that manages all of the Envoy's as a single mesh. The IP addresses on the various clusters must not
overlap and DNS resolution for services on remote clusters is not automatic. Users need to replicate
the services on every participating cluster.

To configure this type of multicluster topology, visit our
[single-network shared control plane instructions](/docs/setup/kubernetes/install/multicluster/shared-vpn/).

#### Multi-network shared control plane topology

If setting up an environment with universal pod-to-pod connectivity is difficult or impossible,
it may still be possible to configure a shared control plane topology using Istio gateways and
by enabling Istio Pilot's location-aware service routing feature.

This topology requires connectivity to Kubernetes API servers from all of the clusters. If this is
not possible, a dedicated control plane topology is probably a better alternative.

{{< image width="80%"
    link="./multicluster-split-horizon-eds.svg"
    caption="Istio mesh spanning multiple Kubernetes clusters using single Istio control plane and Gateway to reach remote pods"
>}}

In this topology, a request from a sidecar in one cluster to a service in the same cluster
is forwarded to the local service IP as usual. If the destination workload is running in a
different cluster, the remote cluster Gateway IP is used to connect to the service instead.

To configure this type of multicluster topology, visit our
[multi-network shared control plane instructions](/docs/setup/kubernetes/install/multicluster/shared-gateways/).

## Mesh Federation

A mesh federation is loosely coupled composition of services running in multiple meshes that only connect to each other
as necessary.
A mesh federation has the following characteristics:

- No {{< gloss >}}uniform naming{{< /gloss >}} required.
- {{< gloss >}}Selective service exposure{{< /gloss >}}.
- There is control on the traffic that arrives from the coupled clusters.
- Common CA root between the Citadels in the coupled clusters is optional.

To learn more, see
[single multicluster service mesh or mesh federation?](#single-multicluster-service-mesh-or-mesh-federation).

To create a mesh federation, configure traffic control for [ingress](/docs/tasks/traffic-management/ingress/) and
[egress](/docs/tasks/traffic-management/egress/) traffic in your service meshes and specify which services
to expose in one mesh and which to consume in the other meshes.
