---
title: Istio Deployment Models
description: Describes the system models that impact your overall Istio depolyment.
weight: 60
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
- /docs/concepts/multicluster-deployments/
---

Important system models impact your overall Istio deployment model. This page
discusses the options for each of these models and describes how you can
configure Istio to address them.

## Cluster models

A {{< gloss >}}cluster{{< /gloss >}} is a group of compute nodes within physical
proximity that, typically, can reach each other directly. For isolation,
performance, and high availability, most cloud providers confine clusters to
availability zones and regions. Production systems, depending on their
requirements, can run across multiple clusters spanning a number of zones or
regions, leveraging cloud load balancers to handle things like locality and
zonal or regional failover.

In most cases, clusters represent boundaries for configuration and endpoint
discovery. For example, each Kubernetes cluster has an API Server which manages
the configuration for the cluster as well as serving
{{< gloss >}}service endpoint{{< /gloss >}} information as pods are brought up
or down. Since Kubernetes configures this behavior on a per-cluster basis, this
approach helps limit the potential problems caused by incorrect configurations.

In Istio, you can configure a single service mesh to span any number of
clusters.

### Single cluster

In the simplest case, you can confine an Istio mesh to a single cluster. A
single cluster usually operates over a [single network](#single-network), but it
varies between infrastructure providers. In single cluster and single network
models, you commonly deploy a single Istio control plane, which results in the
simplest Istio deployment.

{{< image width="50%"
    link="./single-cluster.svg"
    alt="A service mesh with a single cluster"
    title="Single cluster"
    caption="A service mesh with a single cluster"
    >}}

Single cluster deployments offer simplicity, but lack fault isolation and
failover. If you need higher availability, you should use multiple clusters.

### Multiple clusters

You can configure your mesh to include multiple clusters; such configurations
are known as **multi-cluster**. Using multiple clusters
affords the following capabilities beyond that of a single cluster model:

- Fault isolation and failover: `cluster-1` goes down, failover to `cluster-2`.
- Location-aware routing and failover: Send requests to the nearest service.
- Configuration isolation: A wrong configuration only affects a single cluster.
- Various [control plane models](#control-plane-models): Support different
  levels of availability.
- Team or project isolation: Each team runs its own set of clusters.

{{< image width="50%"
    link="./multi-cluster.svg"
    alt="A service mesh with multiple clusters"
    title="Multi-cluster"
    caption="A service mesh with multiple clusters"
    >}}

Multi-cluster deployments give you a greater degree of isolation and
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
network topologies.

### Single network

In the simplest case, a service mesh operates over a single fully
connected network. A single network model satisfies the following conditions:

- The network consists of a number of connected subnets without any
  overlap in IP or VIP ranges.
- All {{< gloss >}}workload instance{{< /gloss >}}s can reach each other directly
  without an Istio gateway.

A single network allows Istio to configure service consumers in a uniform
way across the mesh with the ability to directly address workload instances.

{{< image width="50%"
    link="./single-net.svg"
    alt="A service mesh with a single network"
    title="Single network"
    caption="A service mesh with a single network"
    >}}

### Multiple networks

You can span a single service mesh across multiple networks; such a
configuration is known as **multi-network**.

Multiple networks afford the following capabilities beyond that of single networks:

- An existing network topology
- Overlapping IP or VIP ranges for **service endpoints**
- Crossing of administrative boundaries
- Fault tolerance
- Scaling of network addresses

In this model, the workload instances in different networks can only reach each
other through one or more [Istio gateways](/docs/concepts/traffic-management/#gateways).
Istio uses **partitioned service discovery** to provide consumers a different
view of {{< gloss >}}service endpoint{{< /gloss >}}s. The view depends on the
network of the consumers.

{{< image width="50%"
    link="./multi-net.svg"
    alt="A service mesh with multiple networks"
    title="Multi-network deployment"
    caption="A service mesh with multiple networks"
    >}}

## Mesh models

Istio supports two mesh models:

- Single mesh
- Multiple meshes, also known as **multi-mesh**

### Single mesh

The simplest Istio deployment is a single mesh. Within a mesh, service names are
unique. For example, only one service can have the name `foo/mysvc`.
Additionally, workload instances all share a common identity and authentication
infrastructure and can authenticate each other. With a single mesh you can do
the following tasks:

- Span [one or more clusters](#cluster-models)
- Span [one or more networks](#network-models)
- Use [namespaces for tenancy](#namespace-tenancy)

### Multiple Meshes

You can deploy multiple meshes; such a configuration is known as
**multi-mesh**.

Multiple meshes afford the following capabilities beyond that of a single mesh:

- Organizational boundaries: lines of business
- Service name or namespace collisions: multiple distinct uses of the `default`
  namespace
- Stronger isolation: isolating test workloads from production workloads

In the most basic multiple mesh model, each mesh forms a strict
boundary and there is no communication between meshes. However, you can enable
inter-mesh communication with **mesh peering**. When
peering, each mesh can export a set of services and identities, which all
participating meshes can recognize.

{{< image width="50%"
    link="./multi-mesh.svg"
    alt="Multiple service meshes"
    title="Multi-mesh"
    caption="Multiple service meshes"
    >}}

To avoid service naming collisions, you can give each mesh a globally unique
**mesh ID**, to ensure that the fully qualified domain
name (FQDN) for each service is distinct.

When peering two meshes that do not share the same
{{< gloss >}}trust domain{{< /gloss >}}, {{< gloss >}}identity{{< /gloss >}} and
**trust bundles** must be federated between them. See the section
on [Multiple Trust Domains](#trust-between-meshes) for an overview.

## Control plane models

The Istio [control plane](https://kubernetes.io/docs/reference/glossary/?fundamental=true#term-control-plane)
configures the mesh or a subset of the mesh to manage the communication between
workload instances. A single deployment of the control plane consists of several
redundant processes that share a common view of the mesh and provide workload
instances with identical configuration.

Depending on your overall system architecture and cloud provider, the following
Istio control plane models are possible:

- [single control plane](#single-control-plane)
- [multiple control planes](#multiple-control-planes)
- [managed control planes](#managed-control-plane)

### Single control plane

In the simplest case, you can run your mesh using a single control plane
deployment. The single control plane model is typically used for [single
cluster](#single-cluster) meshes.

If you run your mesh on a single cluster, a single control plane deployment
suffices. Each workload instance in the cluster connects to a control plane
instance to get its configuration.

{{< image width="50%"
    link="./single-cluster.svg"
    alt="A service mesh with a single control plane"
    title="Single control plane"
    caption="A service mesh with a single control plane"
    >}}

### Multiple control planes

You can deploy multiple control planes across the mesh; such a configuration is
known as a **multi-control plane**.

Multiple control planes afford improved performance and availability for meshes
that span [multiple clusters](#multiple-clusters) across multiple zones and
regions.

Istio supports control plane deployments at various levels of availability:

- Control plane per region: *lowest availability*
- Control plane per zone
- Control plane per cluster *highest availability*

The configuration of each control plane could be identical or different
depending on the [network](#network-models) and [cluster](#cluster-models)
models of the system.

{{< image width="50%"
    link="./multi-control.svg"
    alt="A service mesh with multiple control planes"
    title="Multiple control planes"
    caption="A service mesh with multiple control planes"
    >}}

### Managed control plane

Many cloud providers offer a control plane, which they manage on behalf of their
customer.

Typically, managed control planes guarantee some level of performance and
availability, which you can assume when building your system. Managed control
planes affords the following benefits:

- Greatly reduce the complexity of user deployments
- Greatly reduce system administration costs
- Effectively eliminate the usage costs associated with the control plane:
    - CPU
    - Memory
    - Network

{{< image width="50%"
    link="./managed-control.svg"
    alt="A service mesh with a managed control plane"
    title="Managed control plane"
    caption="A service mesh with a managed control plane"
    >}}

## Identity and trust models

When a workload instance is created within a service mesh, Istio assigns the
workload an identity. An identity is a unique name backed by a key material, for
example:

- [X.509 certificate](https://en.wikipedia.org/wiki/X.509)
- [JWT](https://en.wikipedia.org/wiki/JSON_Web_Token)

Each identity Istio assigns is understood throughout the mesh and you can use it
to enable mutual authentication and enforce policies.

An identity contains a substring identifying the mesh that created it. For
example in `spiffe://mytrustdomain.com/ns/default/sa/myname` the substring
identifying the mesh is: `mytrustdomain.com`. We call this substring the {{<
gloss>}}trust domain{{< /gloss >}} of the mesh. Every Istio mesh has a globally
unique trust domain used to create identity names.

The Certificate Authority (CA) creates the identities and their key material.
You can verify the message sender's identity with the public key of the CA that
created the identity. A **trust bundle** is the set of
all CA public keys used by an Istio mesh. With a mesh's trust bundle, anyone can
verify the sender of any message coming from that mesh.

### Trust within a mesh

Within a single Istio mesh, a CA creates identities and ensures that each
workload instance has the key material needed to recognize all identities in the
mesh. This model allows workload instances in the mesh to authenticate each
other when communicating.

{{< image width="50%"
    link="./single-trust.svg"
    alt="A service mesh with a certificate authority"
    title="Trust within a mesh"
    caption="A service mesh with a certificate authority"
    >}}

### Trust between meshes

If a service in a mesh requires a service in another, you must federate identity
and trust between the two meshes. To federate identity and trust,, you must
exchange the trust bundles of the meshes. You can exchange the trust bundles
either manually or automatically using a protocol such as [SPIFFE Trust Domain Federation](https://docs.google.com/document/d/1OC9nI2W04oghhbEDJpKdIUIw-G23YzWeHZxwGLIkB8k/edit).
Once you import a trust bundle to a mesh, you can configure local policies for
those identities.

{{< image width="50%"
    link="./multi-cluster.svg"
    alt="Multiple service meshes with certificate authorities"
    title="Trust between meshes"
    caption="Multiple service meshes with certificate authorities"
    >}}

## Tenancy models

In Istio, a **tenant** is a group of users that share
common access and privileges to a set of deployed workloads. Generally, you
isolate the workload instances from multiple tenants from each other through
network configuration and policies.

You can configure tenancy models to satisfy the following organizational
requirements for isolation:

- Security
- Policy
- Capacity
- Cost
- Performance

Istio supports two types of tenancy models:

- [Namespace tenancy](#namespace-tenancy)
- [Cluster tenancy](#cluster-tenancy)

### Namespace tenancy

In Istio, a [namespace](https://kubernetes.io/docs/reference/glossary/?fundamental=true#term-namespace)
is a unit of tenancy within a single mesh. For example, you can grant a team
permission to deploy their workloads only to a given namespace or set of
namespaces. By default, services from multiple tenant namespaces can communicate
with each other.

{{< image width="50%"
    link="./iso-ns.svg"
    alt="A service mesh with two isolated namespaces"
    title="Isolated namespaces"
    caption="A service mesh with two isolated namespaces"
    >}}

To improve isolation, you can selectively choose which services to expose to
other namespaces. You can configure authorization policies for exposed services
to restrict access to only the appropriate callers.

{{< image width="50%"
    link="./exp-ns.svg"
    alt="A service mesh with two namespaces and an exposed service"
    title="Namespaces with an exposed service"
    caption="A service mesh with two namespaces and an exposed service"
    >}}

When using [multiple clusters](#multiple-clusters), the
namespaces in each cluster sharing the same name are considered as the
same namespace. For example, `foo/B` in `cluster-1` and `foo/B` in
`cluster-2` refer to the same service, and Istio merges their endpoints for
service discovery and load balancing.

{{< image width="50%"
    link="./cluster-ns.svg"
    alt="A service mesh with two clusters with the same namespace"
    title="Multi-cluster namespaces"
    caption="A service mesh with clusters with the same namespace"
    >}}

### Cluster tenancy

Istio supports using clusters as a unit of tenancy. In this case, you can give
each team a dedicated cluster or set of clusters to deploy their
workloads. Permissions for a cluster are usually limited to the members of the
team that owns it. You can set various roles for finer grained control, for
example:

- Cluster administrator
- Developer

With cluster tenancy, Istio considers each cluster as an independent mesh.

{{< image width="50%"
    link="./cluster-iso.svg"
    alt="Two isolated service meshes with two clusters and two namespaces"
    title="Cluster isolation"
    caption="Two isolated service meshes with two clusters and two namespaces"
    >}}

Since a different team or organization operates each mesh, service naming
is rarely distinct. For example, `foo/mysvc` in `cluster-1` and `foo/mysvc` in
`cluster-2` do not refer to the same service. The most common example is the
scenario in Kubernetes where many teams deploy their workloads to the default
namespace.

Because each team has their own mesh, cross-mesh communication follows the
concepts described in the [multiple meshes](#multiple-meshes) model.
