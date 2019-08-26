---
title: Deployment Models
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
    link="single-cluster.svg"
    alt="A service mesh with a single cluster"
    title="Single cluster"
    caption="A service mesh with a single cluster"
    >}}

Single cluster deployments offer simplicity, but lack other features like fault
isolation and failover for example. If you need higher availability, you should
use multiple clusters.

### Multiple clusters

You can configure a single mesh to include multiple clusters; such configurations
are known as **multi-cluster**. Using multiple clusters within a single mesh
affords the following capabilities beyond that of a single cluster deployment:

- Fault isolation and failover: `cluster-1` goes down, failover to `cluster-2`.
- Location-aware routing and failover: Send requests to the nearest service.
- Various [control plane models](#control-plane-models): Support different
  levels of availability.
- Team or project isolation: Each team runs its own set of clusters.

{{< image width="50%"
    link="multi-cluster.svg"
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

## Mesh models

Istio supports having all of your services in a **single mesh**, or connecting
multiple meshes together, which is also known as **multi-mesh**.

### Single mesh

The simplest Istio deployment is a single mesh. Within a mesh, service names are
unique. For example, only one service can have the name `mysvc` in the `foo/`
namespace. Additionally, workload instances share a common identity since
service account names are unique within a namespace, just like service names.

A single mesh can span [one or more clusters](#cluster-models) and
[one or more networks](#network-models). Within a mesh,
[namespaces](#namespace-tenancy) are used for [tenancy](#tenancy-models).

### Multiple meshes

You can deploy multiple meshes; such a configuration is known as
{{< gloss >}}multi-mesh{{< /gloss >}}.

Multiple meshes afford the following capabilities beyond that of a single mesh:

- Organizational boundaries: lines of business
- Service name or namespace reuse: multiple distinct uses of the `default`
  namespace
- Stronger isolation: isolating test workloads from production workloads

In the most basic multiple mesh model, each mesh forms a strict
boundary and there is no communication between meshes. However, you can enable
inter-mesh communication with {{< gloss >}}mesh federation{{< /gloss >}}. When
federating, each mesh can expose a set of services and identities, which all
participating meshes can recognize.

{{< image width="50%"
    link="multi-mesh.svg"
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

In Istio, a control plane is a set of one or more instances that share the
same configuration source. The control plane configures the mesh or a subset of
the mesh to manage the communication between workload instances within. For Kubernetes
environments, each process gets its configuration from the same [API server](https://kubernetes.io/docs/concepts/overview/components/#kube-apiserver)
residing in the cluster.

Since the control plane uses a single configuration source, a workload
instance receives the same configuration when connecting to any instance of
the control plane.

Depending on your overall system architecture and cloud provider, the following
Istio control plane models are possible:

- Single control plane
- Multiple control planes
- Managed control plane

### Single control plane

In the simplest case, you can run your mesh using a single
{{< gloss >}}control plane{{< /gloss >}} deployment. In this model, each
workload instance connects to the same control plane for configuration.

Single cluster deployments typically use a single control plane since
there is only one configuration source.

{{< image width="50%"
    link="single-cluster.svg"
    alt="A service mesh with a single logical control plane"
    title="Single control plane"
    caption="A service mesh with a single control plane"
    >}}

Multi-cluster deployments can also share a single control plane. In this
case, the control plane instances can reside in one or more clusters, but they
all use the same configuration source.

{{< image width="50%"
    link="shared-control.svg"
    alt="A service mesh with two clusters sharing a control plane"
    title="Shared control plane"
    caption="A service mesh with two clusters sharing a control plane"
    >}}

### Multiple control planes

You can deploy multiple {{< gloss "control plane" >}}control planes{{< /gloss >}}
if your mesh spans across multiple zones and regions.

{{< image width="50%"
    link="multi-control.svg"
    alt="A service mesh with two clusters each with their control plane"
    title="Multiple control planes"
    caption="A service mesh with two clusters each with their control plane"
    >}}

Multiple control planes afford the following benefits:

- Improved availability: If a configuration source or control plane becomes
  unavailable, the scope of the outage is limited to only that control plane.

- Configuration isolation: You can canary configuration changes in one control
  plane without impacting others.

Istio supports the following deployment models ranked from lowest to highest availability:

- Single control plane per region (**lowest availability**)
- Multiple control planes per region
- Single control plane per zone
- Multiple control planes per zone
- One control plane per cluster (**highest availability**)

### Managed Control Plane

Many cloud providers offer a {{< gloss >}}control plane{{< /gloss >}}, which
they manage on behalf of their customers.

{{< image width="50%"
    link="managed-control.svg"
    alt="A service mesh with a managed control plane"
    title="Managed control plane"
    caption="A service mesh with a managed control plane"
    >}}

Typically, managed control planes guarantee some level of performance and
availability, which you can assume when building your system. Managed control
planes afford the following benefits:

- Greatly reduce the complexity of user deployments
- Greatly reduce system administration costs
- Effectively eliminate the usage costs associated with the control plane:
    - CPU
    - Memory
    - Network

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
The CA only creates and signs the certificates for those identities. This model
allows workload instances in the mesh to authenticate each other when
communicating.

{{< image width="50%"
    link="single-trust.svg"
    alt="A service mesh with a certificate authority"
    title="Trust within a mesh"
    caption="A service mesh with a certificate authority"
    >}}

### Trust between meshes

If a service in a mesh requires a service in another, you must federate identity
and trust between the two meshes. To federate identity and trust, you must
exchange the trust bundles of the meshes. You can exchange the trust bundles
either manually or automatically using a protocol such as [SPIFFE Trust Domain Federation](https://docs.google.com/document/d/1OC9nI2W04oghhbEDJpKdIUIw-G23YzWeHZxwGLIkB8k/edit).
Once you import a trust bundle to a mesh, you can configure local policies for
those identities.

{{< image width="50%"
    link="multi-trust.svg"
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

If you use Istio in a Kubernetes environment, a
[namespace](https://kubernetes.io/docs/reference/glossary/?fundamental=true#term-namespace)
is a unit of tenancy within a single mesh. Istio also works in environments that
don't implement namespace tenancy. In environments that do, you can grant a team
permission to deploy their workloads only to a given namespace or set of
namespaces. By default, services from multiple tenant namespaces can communicate
with each other.

{{< image width="50%"
    link="iso-ns.svg"
    alt="A service mesh with two isolated namespaces"
    title="Isolated namespaces"
    caption="A service mesh with two isolated namespaces"
    >}}

To improve isolation, you can selectively choose which services to expose to
other namespaces. You can configure authorization policies for exposed services
to restrict access to only the appropriate callers.

{{< image width="50%"
    link="exp-ns.svg"
    alt="A service mesh with two namespaces and an exposed service"
    title="Namespaces with an exposed service"
    caption="A service mesh with two namespaces and an exposed service"
    >}}

When using [multiple clusters](#multiple-clusters), the namespaces in each
cluster sharing the same name are considered the same namespace. For example,
`Service B` in the `foo` namespace of `cluster-1` and `Service B` in the
`foo` namespace of `cluster-2` refer to the same service, and Istio merges their
endpoints for service discovery and load balancing.

{{< image width="50%"
    link="cluster-ns.svg"
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

To use cluster tenancy with Istio, you configure each cluster as an independent
mesh. Alternatively, you can use Istio to implement a group of clusters as a
single tenant. Then, each team can own one or more clusters, but you configure
all their clusters as a single mesh. To connect the meshes of the various teams
together, you can federate the meshes into a multi-mesh deployment.

{{< image width="50%"
    link="cluster-iso.svg"
    alt="Two isolated service meshes with two clusters and two namespaces"
    title="Cluster isolation"
    caption="Two isolated service meshes with two clusters and two namespaces"
    >}}

Since a different team or organization operates each mesh, service naming
is rarely distinct. For example, the `mysvc` in the `foo` namespace of
`cluster-1` and the `mysvc` service in the `foo` namespace of
`cluster-2` do not refer to the same service. The most common example is the
scenario in Kubernetes where many teams deploy their workloads to the default
namespace.

Because each team has their own mesh, cross-mesh communication follows the
concepts described in the [multiple meshes](#multiple-meshes) model.
