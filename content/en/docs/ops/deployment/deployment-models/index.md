---
title: Deployment Models
description: Describes the options and considerations when configuring your Istio deployment.
weight: 20
keywords:
  - single-cluster
  - multiple-clusters
  - control-plane
  - tenancy
  - networks
  - identity
  - trust
  - single-mesh
  - multiple-meshes
aliases:
  - /docs/concepts/multicluster-deployments
  - /docs/concepts/deployment-models
  - /docs/ops/prep/deployment-models
owner: istio/wg-environments-maintainers
test: n/a
---

When configuring a production deployment of Istio, you need to answer a number of questions.
Will the mesh be confined to a single {{< gloss >}}cluster{{< /gloss >}} or distributed across
multiple clusters? Will all the services be located in a single fully connected network, or will
gateways be required to connect services across multiple networks? Is there a single
{{< gloss >}}control plane{{< /gloss >}}, potentially shared across clusters,
or are there multiple control planes deployed to ensure high availability (HA)?
Are all clusters going to be connected into a single {{< gloss >}}multicluster{{< /gloss >}}
service mesh or will they be federated into a {{< gloss >}}multi-mesh{{< /gloss >}} deployment?

Deploying a `single Istio mesh` involves three independent dimensions of configuration:

1. single or multiple cluster
1. single or multiple network
1. single or multiple control plane

In a production environment involving multiple clusters, you can use a mix
of deployment models. For example, having more than one control plane is recommended for HA,
but you could achieve this for a 3 cluster deployment by deploying 2 clusters with
a single shared control plane and then adding the third cluster with a second
control plane in a different network. All three clusters could then be configured
to share both control planes so that all the clusters have 2 sources of control
to ensure HA.

Choosing the right deployment model depends on the isolation, performance,
and HA requirements for your use case. This guide describes the various options and
considerations when configuring your Istio deployment.

## Cluster models

The workload instances of your application run in one or more
{{< gloss "cluster" >}}clusters{{< /gloss >}}. For isolation, performance, and
high availability, you can confine clusters to availability zones and regions.

Production systems, depending on their requirements, can run across multiple
clusters spanning a number of zones or regions, leveraging cloud load balancers
to handle things like locality and zonal or regional fail over.

In most cases, clusters represent boundaries for configuration and endpoint
discovery. For example, each Kubernetes cluster has an API Server which manages
the configuration for the cluster as well as serving
{{< gloss >}}service endpoint{{< /gloss >}} information as pods are brought up
or down. Since Kubernetes configures this behavior on a per-cluster basis, this
approach helps limit the potential problems caused by incorrect configurations.

In Istio, you can configure a single service mesh to span any number of
clusters.

### Single cluster

In the simplest case, you can confine an Istio mesh to a single
{{< gloss >}}cluster{{< /gloss >}}. A cluster usually operates over a
[single network](#single-network), but it varies between infrastructure
providers. A single cluster and single network model includes a control plane,
which results in the simplest Istio deployment.

{{< image width="50%"
    link="single-cluster.svg"
    alt="A service mesh with a single cluster"
    title="Single cluster"
    caption="A service mesh with a single cluster"
    >}}

Single cluster deployments offer simplicity, but lack other features, for
example, fault isolation and fail over. If you need higher availability, you
should use multiple clusters.

### Multiple clusters

You can configure a single mesh to include
multiple {{< gloss "cluster" >}}clusters{{< /gloss >}}. Using a
{{< gloss >}}multicluster{{< /gloss >}} deployment within a single mesh affords
the following capabilities beyond that of a single cluster deployment:

- Fault isolation and fail over: `cluster-1` goes down, fail over to `cluster-2`.
- Location-aware routing and fail over: Send requests to the nearest service.
- Various [control plane models](#control-plane-models): Support different
  levels of availability.
- Team or project isolation: Each team runs its own set of clusters.

{{< image width="75%"
    link="multi-cluster.svg"
    alt="A service mesh with multiple clusters"
    title="Multicluster"
    caption="A service mesh with multiple clusters"
    >}}

Multicluster deployments give you a greater degree of isolation and
availability but increase complexity. If your systems have high availability
requirements, you likely need clusters across multiple zones and regions. You
can canary configuration changes or new binary releases in a single cluster,
where the configuration changes only affect a small amount of user traffic.
Additionally, if a cluster has a problem, you can temporarily route traffic to
nearby clusters until you address the issue.

You can configure inter-cluster communication based on the
[network](#network-models) and the options supported by your cloud provider. For
example, if two clusters reside on the same underlying network, you can enable
cross-cluster communication by simply configuring firewall rules.

## Network models

Many production systems require multiple networks or subnets for isolation
and high availability. Istio supports spanning a service mesh over a variety of
network topologies. This approach allows you to select the network model that
fits your existing network topology.

### Single network

In the simplest case, a service mesh operates over a single fully connected
network. In a single network model, all
{{< gloss "workload instance" >}}workload instances{{< /gloss >}}
can reach each other directly without an Istio gateway.

A single network allows Istio to configure service consumers in a uniform
way across the mesh with the ability to directly address workload instances.

{{< image width="50%"
    link="single-net.svg"
    alt="A service mesh with a single network"
    title="Single network"
    caption="A service mesh with a single network"
    >}}

### Multiple networks

You can span a single service mesh across multiple networks; such a
configuration is known as **multi-network**.

Multiple networks afford the following capabilities beyond that of single networks:

- Overlapping IP or VIP ranges for **service endpoints**
- Crossing of administrative boundaries
- Fault tolerance
- Scaling of network addresses
- Compliance with standards that require network segmentation

In this model, the workload instances in different networks can only reach each
other through one or more [Istio gateways](/docs/concepts/traffic-management/#gateways).
Istio uses **partitioned service discovery** to provide consumers a different
view of {{< gloss >}}service endpoint{{< /gloss >}}s. The view depends on the
network of the consumers.

{{< image width="50%"
    link="multi-net.svg"
    alt="A service mesh with multiple networks"
    title="Multi-network deployment"
    caption="A service mesh with multiple networks"
    >}}

## Control plane models

An Istio mesh uses the {{< gloss >}}control plane{{< /gloss >}} to configure all
communication between workload instances within the mesh. At one extreme, you can choose
to deploy one control plane per cluster in the mesh, while at the other extreme,
you can host one control plane for all clusters in the mesh.

In the simplest case, you can run your mesh with a control plane on a single
cluster.

{{< image width="50%"
    link="single-cluster.svg"
    alt="A single cluster with a control plane"
    title="Single control plane"
    caption="A single cluster with a control plane"
    >}}

A cluster like this one, with its own local control plane, is referred to as a {{< gloss >}}primary cluster{{< /gloss >}}.

Multicluster deployments can also share control plane instances. In this case,
the control plane instances can reside in one or more primary clusters.
Clusters without their own control plane are referred to as {{< gloss "remote cluster" >}}remote clusters{{< /gloss >}}.

{{< image width="75%"
    link="shared-control.svg"
    alt="A service mesh with a primary and a remote cluster"
    title="Shared control plane"
    caption="A service mesh with a primary and a remote cluster"
    >}}

Instead of running control planes in primary clusters inside the mesh, a service mesh composed entirely of
remote clusters can be controlled by an {{< gloss >}}external control plane{{< /gloss >}}.
This provides isolated management and complete separation of the control plane deployment from the
data plane services that comprise the mesh.

{{< image width="100%"
    link="single-cluster-external-control-plane.svg"
    alt="A single cluster with an external control plane"
    title="External control plane"
    caption="A single cluster with an external control plane"
    >}}

A cloud vendor's {{< gloss >}}managed control plane{{< /gloss >}} is a typical example of an external control plane.

For high availability, you should deploy one control plane in each zone/region or set of clusters, and
ensure that configuration is replicated across all control planes.

{{< image width="75%"
    link="multi-control.svg"
    alt="A service mesh with control plane instances for each region"
    title="Multiple control planes"
    caption="A service mesh with control plane instances for each region"
    >}}

This model affords the following benefits:

- Improved availability: If a control plane becomes unavailable, the scope of
  the outage is limited to only workloads in clusters managed by that control plane.

- Improved configuration isolation: Configuration changes in one control plane affects only
the workloads in clusters managed by this control plane.

### Control Plane Per Cluster

For maximum availability and configuration isolation you can deploy a control plane in each cluster. Each cluster's control plane
manages only the workloads in its own cluster. If the control plane is unavailable (due to upgrade or
temporary outage), the workloads will continue to function with the existing sidecar configuration and
will re-attempt to connect to the in-cluster control plane periodically.

This model affords the following benefits:

- Highest level of availability: If a control plane becomes unavailable, the scope of
  the outage is limited to only that cluster and the workloads within it.

- Maximum configuration isolation: You can make configuration changes in one cluster without impacting
  workloads deployed in any other cluster.

### Availability vs Config Isolation

The following list ranks control plane deployment examples by availability and configuration isolation:

- One control plane per region or a single global control plane (**lowest availability**, **lowest isolation**)
- Multiple control planes per region
- One control plane per cluster (**highest availability**, **highest isolation**)

## Mesh models

Istio supports having all of your services in a
{{< gloss "service mesh" >}}single mesh{{< /gloss >}}, or federating multiple meshes
together, which is also known as {{< gloss >}}multi-mesh{{< /gloss >}}.

### Single mesh

The simplest Istio deployment is a single mesh. A single mesh can span
[one or more clusters](#cluster-models) and [one or more networks](#network-models).
All workloads in a mesh share a common certificate authority. You can choose to use a single shared
  [trust domain](https://github.com/spiffe/spiffe/blob/master/standards/SPIFFE-ID.md#21-trust-domain) or a separate trust domain for each cluster.
If you use a single shared trust domain, a service account in a given namespace is globally unique - i.e. if
two clusters `cluster-1` and `cluster-2` have the same service account `foo` in namespace `ns`, they will be
treated the same for purposes of security. With a trust domain for each cluster, there are no
restrictions on the uniqueness of service accounts, and namespaces. You can apply Istio Authorization
policies that allow or deny all traffic from one cluster (irrespective of the namespace/service) to another
based on the source principals of incoming traffic.

### Multiple meshes

Multiple mesh deployments result from {{< gloss >}}mesh federation{{< /gloss >}}, with the following capabilities:

- Organizational boundaries: lines of business.
- Potential for cross vendor meshes to communicate with each
  other if the trust bundles are setup properly.

You can enable inter-mesh communication with {{< gloss >}}mesh federation{{</gloss >}}.
When federating, each mesh can expose a set of services and identities, which all participating meshes can recognize.

{{< image width="50%"
    link="multi-mesh.svg"
    alt="Multiple service meshes"
    title="Multi-mesh"
    caption="Multiple service meshes"
    >}}

When federating two meshes that do not share the same certificate authority, you must
{{< gloss "mesh federation">}}federate{{< /gloss >}}
{{< gloss >}}identity{{< /gloss >}} and exchange **trust bundles** between them. See the
section on [Trust between meshes](#trust-between-meshes) for an overview.

## Identity and trust models

When a workload instance is created within a service mesh, Istio assigns the
workload an {{< gloss >}}identity{{< /gloss >}}.

The Certificate Authority (CA) creates and signs the certificates used to verify
the identities used within the mesh. You can verify the identity of the message sender
with the public key of the CA that created and signed the certificate
for that identity. A **trust bundle** is the set of all CA public keys used by
an Istio mesh. With a mesh's trust bundle, anyone can verify the sender of any
message coming from that mesh.

### Trust within a mesh

Within a single Istio mesh, Istio ensures each workload instance has an
appropriate certificate representing its own identity, and the trust bundle
necessary to recognize all identities within the mesh and any federated meshes.
The CA creates and signs the certificates for those identities. This model
allows workload instances in the mesh to authenticate each other when communicating.

{{< image width="50%"
    link="single-trust.svg"
    alt="A service mesh with a common certificate authority"
    title="Trust within a mesh"
    caption="A service mesh with a common certificate authority"
    >}}

### Trust between meshes

To enable communication between two meshes with different CAs, you must
exchange the trust bundles of the meshes. Istio does not provide any tooling to exchange trust bundles across meshes. You can exchange the trust bundles
either manually or automatically using a protocol such as [SPIFFE Trust Domain Federation](https://docs.google.com/document/d/1OC9nI2W04oghhbEDJpKdIUIw-G23YzWeHZxwGLIkB8k/edit).
Once you import a trust bundle to a mesh, you can configure local policies for
those identities.

{{< image width="50%"
    link="multi-trust.svg"
    alt="Multiple service meshes with different certificate authorities"
    title="Trust between meshes"
    caption="Multiple service meshes with different certificate authorities"
    >}}

## Tenancy Models in Istio

You can achieve a great
level of isolation across different teams through the use of different namespaces, or separate clusters, or even separate meshes.
Such soft tenancy models can be used to satisfy the following organizational requirements for isolation:

- Security
- Policy
- Capacity
- Cost
- Performance

Istio supports three types of soft-tenancy models:

- [Namespace tenancy](#namespace-tenancy)
- [Cluster tenancy](#cluster-tenancy)
- [Mesh tenancy](#mesh-tenancy)

### Namespace Tenancy

By default, services from multiple namespaces can communicate with each other. If a
single cluster is shared across many teams operating in different namespaces,
you can selectively choose which services to expose to other namespaces. You can
configure authorization policies for exposed services to restrict access to only the
appropriate callers.

{{< image width="50%"
    link="exp-ns.svg"
    alt="A service mesh with two namespaces and an exposed service"
    title="Namespaces with an exposed service"
    caption="A service mesh with two namespaces and an exposed service"
    >}}

### Cluster Tenancy

You can use the cluster as the unit of isolation in a mesh by giving each team
a dedicated cluster, with its [own control plane](#independent-control-plane) allowing
them to manage their own configurations. Alternatively, if you can ensure that namespaces
are globally unique across clusters, you can use a shared control plane.

### Mesh Tenancy

In a multi-mesh deployment with {{< gloss >}}mesh federation{{< /gloss >}}, each mesh
can be used as the unit of isolation. If cross mesh communication is desired, trust
between two meshes must be established through exchange of trust bundles. See the section
on [Trust between meshes](#trust-between-meshes) for more details.
