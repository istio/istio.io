---
title: 部署模型
description: 描述 Istio 的部署配置建议及可选选项
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
  - /zh/docs/concepts/multicluster-deployments
  - /zh/docs/concepts/deployment-models
  - /zh/docs/ops/prep/deployment-models
---

当您配置 Istio 为生产环境部署时，需要回答一系列的问题。
网格将被限制在单个 {{< gloss >}}cluster{{< /gloss >}} 中还是分布在多个群集中？
是将所有服务都放置在单个完全连接的网络中，还是需要网关来跨多个网络连接服务？
是否存在单个 {{< gloss >}}control plane{{< /gloss >}} （可能在群集之间共享），或者是否部署了多个控制平面以确保高可用（HA）？
如果要部署多个群集，更具体地说是在隔离的网络中，是否要将它们连接到单个 {{< gloss >}}multicluster{{< /gloss >}} 服务网格中，
还是将它们联合到一个 {{< gloss >}}multi-mesh{{< /gloss >}} 部署中？

所有这些问题，都代表了 Istio 部署的独立配置维度。

1. 单个或多个群集
1. 单个或多个网络
1. 单或多控制平面
1. 单个或多个网格

所有组合都是可能的，尽管某些组合比其他组合更常见，并且某些组合显然不是很有趣（例如，单个群集中有多个网格）。

在涉及多个集群的生产部署中，部署可能使用多种模式。例如，对于 HA，建议拥有多个控制平面，
但是对于 3 个集群部署，您可以通过使用单个共享控制平面部署 2 个集群，然后在另一个网络中添加第 3 个集群和第 2 个控制平面来实现。
然后，可以将所有三个集群配置为共享两个控制平面，以便所有集群都有 2 个控制源来确保 HA。

选择正确的部署模型取决于您对隔离性、性能和 HA 的要求。本指南介绍了配置 Istio 部署时的各种选项和注意事项。

## 集群模型{#cluster-models}

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
other through one or more [Istio gateways](/zh/docs/concepts/traffic-management/#gateways).
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
communication between workload instances within the mesh. You can replicate the
control plane, and workload instances connect to any control plane instance to
get their configuration.

In the simplest case, you can run your mesh with a control plane on a single
cluster.

{{< image width="50%"
    link="single-cluster.svg"
    alt="A service mesh with a control plane"
    title="Single control plane"
    caption="A service mesh with a control plane"
    >}}

Multicluster deployments can also share control plane instances. In this case,
the control plane instances can reside in one or more clusters.

{{< image width="75%"
    link="shared-control.svg"
    alt="A service mesh with two clusters sharing a control plane"
    title="Shared control plane"
    caption="A service mesh with two clusters sharing a control plane"
    >}}

For high availability, you should deploy a control plane across multiple
clusters, zones, or regions.

{{< image width="75%"
    link="multi-control.svg"
    alt="A service mesh with control plane instances for each region"
    title="Multiple control planes"
    caption="A service mesh with control plane instances for each region"
    >}}

This model affords the following benefits:

- Improved availability: If a control plane becomes unavailable, the scope of
  the outage is limited to only that control plane.

- Configuration isolation: You can make configuration changes in one cluster,
  zone, or region without impacting others.

You can improve control plane availability through fail over. When a control
plane instance becomes unavailable, workload instances can connect to
another available control plane instance. Fail over can happen across clusters,
zones, or regions.

{{< image width="50%"
    link="failover.svg"
    alt="A service mesh after a control plane instance fails"
    title="Control plane fail over"
    caption="A service mesh after a control plane instance fails"
    >}}

The following list ranks control plane deployment examples by availability:

- One cluster per region (**lowest availability**)
- Multiple clusters per region
- One cluster per zone
- Multiple clusters per zone
- Each cluster (**highest availability**)

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

## Mesh models

Istio supports having all of your services in a
{{< gloss "service mesh" >}}mesh{{< /gloss >}}, or federating multiple meshes
together, which is also known as {{< gloss >}}multi-mesh{{< /gloss >}}.

### Single mesh

The simplest Istio deployment is a single mesh. Within a mesh, service names are
unique. For example, only one service can have the name `mysvc` in the `foo`
namespace. Additionally, workload instances share a common identity since
service account names are unique within a namespace, just like service names.

A single mesh can span [one or more clusters](#cluster-models) and
[one or more networks](#network-models). Within a mesh,
[namespaces](#namespace-tenancy) are used for [tenancy](#tenancy-models).

### Multiple meshes

Multiple mesh deployments result from {{< gloss >}}mesh federation{{< /gloss >}}.

Multiple meshes afford the following capabilities beyond that of a single mesh:

- Organizational boundaries: lines of business
- Service name or namespace reuse: multiple distinct uses of the `default`
  namespace
- Stronger isolation: isolating test workloads from production workloads

You can enable inter-mesh communication with {{< gloss >}}mesh federation{{<
/gloss >}}. When federating, each mesh can expose a set of services and
identities, which all participating meshes can recognize.

{{< image width="50%"
    link="multi-mesh.svg"
    alt="Multiple service meshes"
    title="Multi-mesh"
    caption="Multiple service meshes"
    >}}

To avoid service naming collisions, you can give each mesh a globally unique
**mesh ID**, to ensure that the fully qualified domain
name (FQDN) for each service is distinct.

When federating two meshes that do not share the same
{{< gloss >}}trust domain{{< /gloss >}}, you must
{{< gloss "mesh federation">}}federate{{< /gloss >}}
{{< gloss >}}identity{{< /gloss >}} and **trust bundles** between them. See the
section on [Multiple Trust Domains](#trust-between-meshes) for an overview.

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

Istio uses [namespaces](https://kubernetes.io/docs/reference/glossary/?fundamental=true#term-namespace)
as a unit of tenancy within a mesh. Istio also works in environments that don't
implement namespace tenancy. In environments that do, you can grant a team
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
    title="Multicluster namespaces"
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
scenario in Kubernetes where many teams deploy their workloads to the `default`
namespace.

When each team has their own mesh, cross-mesh communication follows the
concepts described in the [multiple meshes](#multiple-meshes) model.
