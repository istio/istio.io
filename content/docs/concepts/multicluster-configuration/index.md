---
title: Multicluster Istio
description: Describes how a service mesh can be configured to include services from more than one cluster.
weight: 60
---

Istio is a [service mesh](/docs/concepts/what-is-istio/#what-is-a-service-mesh),
the fundamental property of which is its ability to monitor and manage
a network of cooperating microservices under a single administrative domain,
essentially combining the microservices into a controllable composite application.
For applications up to a certain size, all of the microservices comprising the
application can be running on a single orchestration platform (e.g., kubernetes cluster),
but for many reasons (e.g., scale, redundancy, etc.) most applications will eventually
need to be distributed and have some of their services running elsewhere.

Istio supports many possible topologies for distributing the services of an
application beyond a single cluster.
Services within the mesh can use [service entries](/docs/concepts/traffic-management/#service-entries)
to access standalone external services or services exposed by another loosely-coupled
service mesh, a.k.a. *mesh federation*.
Alternatively, if all the services can be under the same administrative control,
you can [expand the service mesh](/docs/setup/kubernetes/mesh-expansion/) to include services running
on VMs or bare metal hosts, or you can combine the services from more than one cluster into a
single composite service mesh, i.e., a *multicluster mesh*.

## Multicluster service mesh

A multicluster service mesh is defined as a single composite service mesh composed of services
running in more than one underlying cluster with all services running
under a single administrative control.
A service named `foo` in cluster 1 is the same service as `foo` in cluster 2. This is
unlike a loosely-coupled federated service mesh where two clusters may have different
definitions of the same service, which need to be reconciled when integrating them.

A multicluster mesh has the advantage that all the services look the same to clients,
regardless of where the workloads are actually running. It's transparent
to the application whether it's deployed in a single or multicluster mesh.
To achieve this, all of the services need to be managed by a single logical
control plane, although not necessarily a single physical Istio control plane.
There are two possible deployment approaches:

1. A single Istio control plane with access to and configuration for all the services in the mesh.

1. Multiple synchronized Istio control planes with replicated service and routing configurations. 

Even within these two topologies, there is more than one way to configure things.
Which approach to use and how to configure it depends on the requirements of the application
as well as the features and limitations of the underlying cloud deployment platform.

### Single control plane topology

This multicluster configuration uses a single Istio control plane,
typically running on one of the clusters, whose Pilot
manages services on both local and remote clusters and configures the Envoy sidecars
for all of them. This approach works best in environments where all of the contributing
clusters have VPN connectivity so every pod in the mesh is reachable from anywhere else using
the same IP address.

{{< image width="80%" ratio="36.01%"
    link="./multicluster-with-vpn.svg"
    caption="Istio mesh spanning multiple Kubernetes clusters with direct network access to remote pods over VPN"
    >}}

In this configuration, one or more clusters run a remote Istio configuration which connects them
to a single Istio control plane, allowing it to manage all of the Envoy's as a single mesh.
Detailed instructions for setting up this kind of multicluster topology can be found
in [single control plane with vpn](/docs/setup/kubernetes/multicluster-install/vpn/).

If setting up a VPN network to provide universal pod-to-pod connectivity is difficult or impossible,
Istio Pilot can be configured to enable location-aware service routing (a.k.a. split-horizon EDS).
When configured this way, a request from a sidecar in one cluster to a service that is
also running in the same cluster will be forwarded to the local service IP as usual, but when the destination
workload is running in a different cluster it will use the remote cluster Gateway IP to connect to the service instead.

{{< image width="80%" ratio="36.01%"
    link="./multicluster-split-horizon-eds.svg"
    caption="Istio mesh spanning multiple Kubernetes clusters using single Istio control plane and Gateway to reach remote pods"
    >}}

The [single control plane with gateways](TBD) example provides instructions for experimenting with this feature.

### Multiple control plane topology

Instead of using a central Istio control plane to manage the mesh,
in this configuration each cluster has an **identical** Istio control plane
installation, each managing its own endpoints.
All of the clusters are under a shared administrative control for the purposes of
policy enforcement and security.

{{< image width="80%" ratio="36.01%"
    link="./multicluster-with-gateways.svg"
    caption="Istio mesh spanning multiple Kubernetes clusters using multiple Istio control planes and Gateway to reach remote pods"
    >}}

A single Istio service mesh across the clusters is achieved by replicating
shared services and namespaces and using a common root CA in all of the clusters.
Cross-cluster communication occurs over Istio Gateways of the respective clusters.

Check out [multiple control plane with gateways](/docs/setup/kubernetes/multicluster-install/gateways/)
for instructions on setting up this this kind of multicluster configuration.
