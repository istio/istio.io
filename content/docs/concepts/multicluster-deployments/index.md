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
However, for many reasons such as scale, redundancy, etc., most applications will eventually
need to be distributed and have some of their services running elsewhere.

Istio supports many possible topologies for distributing the services of an
application beyond a single cluster, for example:

* Services within the mesh can use [service entries](/docs/concepts/traffic-management/#service-entries)
  to access standalone external services or to access services exposed by another loosely-coupled service mesh,
  a.k.a. *mesh federation*.
* You can [expand the service mesh](/docs/setup/kubernetes/mesh-expansion/) to include services running
  on VMs or bare metal hosts.
* You can combine the services from more than one cluster into a single composite service mesh,
  i.e., a *multicluster mesh*.

## Multicluster service mesh

A multicluster service mesh is a mesh composed of services running within more than one underlying
cluster but with all services running under a single administrative control.
In a multicluster mesh, a service named `foo` in namespace `ns1` of cluster 1 is the same service
as `foo` in `ns1` of cluster 2.
This is different from a loosely-coupled federated service mesh where two clusters may have different
definitions of the same service which will need to be reconciled when integrating the clusters.

A multicluster mesh has the advantage that all the services look the same to clients,
regardless of where the workloads are actually running. It's transparent
to the application whether it's deployed in a single or multicluster mesh.
To achieve this behavior, a single logical control plane needs to manage all services,
however, the single logical control plane doesn't necessarily need to be a single physical
Istio control plane. There are two possible deployment approaches:

1. Multiple synchronized Istio control planes that have replicated service and routing configurations.

1. A single Istio control plane that can access and configure all the services in the mesh.

Even within these two topologies, there is more than one way to configure a multicluster mesh.
Which approach to use and how to configure it depends on the requirements of the application
and on the features and limitations of the underlying cloud deployment platform.

### Multiple control plane topology

In a multiple control plane configuration, each cluster has an identical Istio control plane
installation and each control plane manages its own endpoints.
Using Istio gateways, a common root Certificate Authority (CA), and service entries,
you can configure a single logical service mesh that is composed from the participating clusters.
This approach has no special networking requirements and is therefore generally considered
the easiest approach to start with when there is no universal connectivity across clusters.

{{< image width="80%" ratio="36.01%"
    link="./multicluster-with-gateways.svg"
    caption="Istio mesh spanning multiple Kubernetes clusters using multiple Istio control planes and Gateway to reach remote pods"
    >}}

To achieve a single Istio service mesh across the clusters,
you configure a common root CA and replicate the shared services and namespaces in all clusters.
Cross-cluster communication occurs over the Istio gateways of the respective clusters.
All clusters are within a shared administrative control for policy enforcement and security.

In this configuration workloads in each cluster can access other local services using their
Kubernetes DNS suffix, e.g., `foo.ns1.svc.cluster.local`, as usual.
To provide DNS resolution for services in remote clusters, Istio includes a CoreDNS server
that can be configured to handle service names of the form `<name>.<namespace>.global`.
For example, calls from any cluster to `foo.ns1.global` will resolve to the `foo` service in
namespace `ns1` of any cluster where it is running.
To set up this kind of multicluster configuration, visit our
[multiple control planes with gateways instructions](/docs/setup/kubernetes/multicluster-install/gateways/).

### Single control plane topology

This multicluster configuration uses a single Istio control plane running on one of the clusters.
The control plane's Pilot manages services on the local and remote clusters and configures the
Envoy sidecars for all of the clusters.

#### Single control plane with VPN connectivity

The following approach works best in environments where all of the participating clusters have VPN connectivity so
every pod in the mesh is reachable from anywhere else using the same IP address.

{{< image width="80%" ratio="36.01%"
    link="./multicluster-with-vpn.svg"
    caption="Istio mesh spanning multiple Kubernetes clusters with direct network access to remote pods over VPN"
    >}}

In this configuration, the Istio control plane is deployed on one of the clusters while all other
clusters run a simpler remote Istio configuration which connects them to the single Istio control plane
that manages all of the Envoy's as a single mesh. The IP addresses on the various clusters must not
overlap and note that DNS resolution for services on remote clusters is not automatic.
Users need to replicate the services on every participating cluster.
You can find detailed steps to set up this kind of multicluster topology
in our [single control plane with VPN instructions](/docs/setup/kubernetes/multicluster-install/vpn/).

#### Single control plane without VPN connectivity

If setting up an environment with universal pod-to-pod connectivity is difficult or impossible,
it may still be possible to configure a single control plane topology using Istio gateways and
by enabling Istio Pilot's location-aware service routing feature, a.k.a. *split-horizon EDS (Endpoint Discovery Service)*.
This approach still requires connectivity to Kubernetes API servers from all of the clusters
as, for example, on managed Kubernetes platforms where the API servers run on a network accessible
to all tenant clusters.
If this is not possible, a multiple control plane topology is probably a better alternative.

{{< image width="80%" ratio="36.01%"
    link="./multicluster-split-horizon-eds.svg"
    caption="Istio mesh spanning multiple Kubernetes clusters using single Istio control plane and Gateway to reach remote pods"
    >}}

In this configuration, a request from a sidecar in one cluster to a service in
the same cluster is forwarded to the local service IP as usual.
If the destination workload is running in a different cluster,
the remote cluster Gateway IP is used to connect to the service instead.
Visit our [single control plane with gateways example](/docs/examples/multicluster/split-horizon-eds/) to experiment with this feature.
