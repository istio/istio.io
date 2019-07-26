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
However, for many reasons such as scale, redundancy, workload isolation, compliance, integration with legacy services,
etc., most applications will eventually need to be distributed and have some of their services running elsewhere.

Istio supports many possible topologies for distributing the services of an
application beyond a single cluster, for example:

* You can use [egress traffic control](/docs/tasks/traffic-management/egress/) to allow workloads inside the mesh
  to access standalone external services or to access services exposed by another loosely-coupled service mesh.
* You can [expand the service mesh](/docs/setup/kubernetes/additional-setup/mesh-expansion/) to include
  services running on VMs or bare metal hosts.
* You can combine the services from more than one cluster into a single composite service mesh.
* You can combine autonomous service meshes in multiple clusters into a loosely coupled [federation of service meshes](#mesh-federation).

## Criteria for selecting the right topology

When you plan your multi-mesh topology, ask yourself the following questions:

**Uniform naming**: Will your meshes have _unoform naming_. In case of multiple Kubernetes clusters, _uniform naming_
means that a service named `foo` in namespace `ns1` of cluster 1 has the same API and semantics as a service named `foo`
in `ns1` of cluster 2.

**Exposing behavior**: Will your combined clusters expose all their services one to another, or selective exposure is
required? _Selective exposure_ means that the owner of cluster 1 may want to control which services are exposed to the
workloads in mesh 2. Selective exposure may be required for security or compliance reasons. Some security standards
require exposure of services on the need-to-know basis.

**Isolation for security or compliance**: Are you required to control all the traffic that enters your mesh **at the
point of entrance**, for example at the Ingres Gateway?

**Common trust**: Can you setup a common CA root for your meshes? Will you perform authentication by Istio
[mutual TLS](/docs/concepts/security/#mutual-tls-authentication) or will you use access tokens like
[JWT](https://istio.io/docs/concepts/security/#origin-authentication)?

**Operating multiple control planes**: Do you have infrastructure capabilities to manage multiple Istio control planes
or do you prefer to manage a single control plane for multiple clusters?

**Providing access to Kubernetes APIs**: Are you allowed to provide access to Kubernetes APIs of one cluster to
other clusters?

**Sending telemetry to external meshes**: Are you allowed to send telemetry data from your mesh to other meshes, from
the security or compliance point of view? In particular, are your pods allowed to communicate with external meshes
directly?

The following decision diagram instructs you on choosing the correct topology based on the answers to the questions
above:

{{< image width="80%"
    link="./multicluster-patterns.png"
    caption="Decision diagram for selecting the right multi-cluster topology"
>}}

## Multicluster service mesh

A multicluster service mesh is a **single locical** mesh composed of services running in multiple clusters.
It exhibits the following characteristics
(see [Criteria for selecting the right topology](#criteria-for-selecting-the-right-topology)):

1. Uniform naming.
1. Expose-all behavior: all the services are exposed by default to all the clusters.
1. Common CA root between Citadel instances in all the clusters.

A multicluster service mesh has the advantage that all the services look the same to clients,
regardless of where the workloads are actually running. It's transparent
to the application whether it's deployed in a single or multicluster service mesh.
To achieve this behavior, a single logical control plane needs to manage all services,
however, the single logical control plane doesn't necessarily need to be a single physical
Istio control plane. There are two possible deployment approaches:

1. Multiple dedicated Istio control planes that have replicated service and routing configurations.

1. A shared Istio control plane that can access and configure the services in more than one cluster.

Even with these two approaches, there is more than one way to configure a multicluster service mesh.
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

Mesh federation is ad-hoc, loosely coupled composition of services running in multiple meshes.
It exhibits the following characteristics
(see [Criteria for selecting the right topology](#criteria-for-selecting-the-right-topology)):

1. No uniform naming is assumed.
1. Selective exposure: the mesh operators decide which services to expose to other meshes. By default, no service is
exposed.
1. Ingress Gateways control the incoming traffic from the coupled meshes.
1. Common CA root between Citadel instances in the federated meshes is optional.

You can achieve mesh federation by applying Istio [Ingress](/docs/tasks/traffic-management/ingress/) and
[Egress](/docs/tasks/traffic-management/egress/) traffic control in your service meshes and by specifying the services
you expose in one mesh and consume in other meshes.
