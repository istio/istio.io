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

All of these questions, among others, represent independent dimensions of configuration for an Istio deployment.

1. single or multiple cluster
1. single or multiple network
1. single or multiple control plane
1. single or multiple mesh

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

Within a multicluster mesh, all services are shared by default, according to the
concept of {{< gloss "namespace sameness" >}}namespace sameness{{< /gloss >}}.
[Traffic management rules](/docs/ops/configuration/traffic-management/multicluster)
provide fine-grained control over the behavior of multicluster traffic.

### DNS with multiple clusters

When a client application makes a request to some host, it must first perform a
DNS lookup for the hostname to obtain an IP address before it can proceed with
the request.
In Kubernetes, the DNS server residing within the cluster typically handles
this DNS lookup, based on the configured `Service` definitions.

Istio uses the virtual IP returned by the DNS lookup to load balance
across the list of active endpoints for the requested service, taking into account any
Istio configured routing rules.
Istio uses either Kubernetes `Service`/`Endpoint` or Istio `ServiceEntry` to
configure its internal mapping of hostname to workload IP addresses.

This two-tiered naming system becomes more complicated when you have multiple
clusters. Istio is inherently multicluster-aware, but Kubernetes is not
(today). Because of this, the client cluster must have a DNS entry for the
service in order for the DNS lookup to succeed, and a request to be
successfully sent. This is true even if there are no instances of that
service's pods running in the client cluster.

To ensure that DNS lookup succeeds, you must deploy a Kubernetes `Service` to
each cluster that consumes that service. This ensures that regardless of
where the request originates, it will pass DNS lookup and be handed to Istio
for proper routing.
This can also be achieved with Istio `ServiceEntry`, rather than Kubernetes
`Service`. However, a `ServiceEntry` does not configure the Kubernetes DNS server.
This means that DNS will need to be configured either manually or
with automated tooling such as the
[Address auto allocation](/docs/ops/configuration/traffic-management/dns-proxy/#address-auto-allocation)
feature of [Istio DNS Proxying](/docs/ops/configuration/traffic-management/dns-proxy/).

{{< tip >}}
There are a few efforts in progress that will help simplify the DNS story:

- [DNS sidecar proxy](/blog/2020/dns-proxy/)
  support is available for preview in Istio 1.8. This provides DNS interception
  for all workloads with a sidecar, allowing Istio to perform DNS lookup
  on behalf of the application.

- [Admiral](https://github.com/istio-ecosystem/admiral) is an Istio community
  project that provides a number of multicluster capabilities. If you need to support multi-network
  topologies, managing this configuration across multiple clusters at scale is challenging.
  Admiral takes an opinionated view on this configuration and provides automatic provisioning and
  synchronization across clusters.

- [Kubernetes Multi-Cluster Services](https://github.com/kubernetes/enhancements/tree/master/keps/sig-multicluster/1645-multi-cluster-services-api)
  is a Kubernetes Enhancement Proposal (KEP) that defines an API for exporting
  services to multiple clusters. This effectively pushes the responsibility of
  service visibility and DNS resolution for the entire `clusterset` onto
  Kubernetes. There is also work in progress to build layers of `MCS` support
  into Istio, which would allow Istio to work with any cloud vendor `MCS`
  controller or even act as the `MCS` controller for the entire mesh.
{{< /tip >}}

## Network models

Istio uses a simplified definition of {{< gloss >}}network{{< /gloss >}} to
refer to {{< gloss >}}workload instance{{< /gloss >}}s that have direct
reachability. For example, by default all workload instances in a single
cluster are on the same network.

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
Note, however, that for a single network across multiple clusters,
services and endpoints cannot have overlapping IP addresses.

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

This solution requires exposing all services (or a subset) through the gateway.
Cloud vendors may provide options that will not require exposing services on
the public internet. Such an option, if it exists and meets your requirements,
will likely be the best choice.

{{< tip >}}
In order to ensure secure communications in a multi-network scenario, Istio
only supports cross-network communication to workloads with an Istio proxy.
This is due to the fact that Istio exposes services at the Ingress Gateway with TLS
pass-through, which enables mTLS directly to the workload. A workload without
an Istio proxy, however, will likely not be able to participate in mutual
authentication with other workloads. For this reason, Istio filters
out-of-network endpoints for proxyless services.
{{< /tip >}}

## Control plane models

An Istio mesh uses the {{< gloss >}}control plane{{< /gloss >}} to configure all
communication between workload instances within the mesh. Workload instances
connect to a control plane instance to get their configuration.

In the simplest case, you can run your mesh with a control plane on a single
cluster.

{{< image width="50%"
    link="single-cluster.svg"
    alt="A single cluster with a control plane"
    title="Single control plane"
    caption="A single cluster with a control plane"
    >}}

A cluster like this one, with its own local control plane, is referred to as
a {{< gloss >}}primary cluster{{< /gloss >}}.

Multicluster deployments can also share control plane instances. In this case,
the control plane instances can reside in one or more primary clusters.
Clusters without their own control plane are referred to as
{{< gloss "remote cluster" >}}remote clusters{{< /gloss >}}.

{{< image width="75%"
    link="shared-control.svg"
    alt="A service mesh with a primary and a remote cluster"
    title="Shared control plane"
    caption="A service mesh with a primary and a remote cluster"
    >}}

To support remote clusters in a multicluster mesh, the control plane in
a primary cluster must be accessible via a stable IP (e.g., a cluster IP).
For clusters spanning networks,
this can be achieved by exposing the control plane through an Istio gateway.
Cloud vendors may provide options, such as internal load balancers, for
providing this capability without exposing the control plane on the
public internet. Such an option, if it exists and meets your requirements,
will likely be the best choice.

In multicluster deployments with more than one primary cluster, each primary
cluster receives its configuration (i.e., `Service` and `ServiceEntry`,
`DestinationRule`, etc.) from the Kubernetes API Server residing in the same
cluster. Each primary cluster, therefore, has an independent source of
configuration.
This duplication of configuration across primary clusters does require
additional steps when rolling out changes. Large production
systems may automate this process with tooling, such as CI/CD systems, in
order to manage configuration rollout.

Instead of running control planes in primary clusters inside the mesh, a
service mesh composed entirely of remote clusters can be controlled by an
{{< gloss >}}external control plane{{< /gloss >}}. This provides isolated
management and complete separation of the control plane deployment from the
data plane services that comprise the mesh.

{{< image width="100%"
    link="single-cluster-external-control-plane.svg"
    alt="A single cluster with an external control plane"
    title="External control plane"
    caption="A single cluster with an external control plane"
    >}}

A cloud vendor's {{< gloss >}}managed control plane{{< /gloss >}} is a
typical example of an external control plane.

For high availability, you should deploy multiple control planes across
clusters, zones, or regions.

{{< image width="75%"
    link="multi-control.svg"
    alt="A service mesh with control plane instances for each region"
    title="Multiple control planes"
    caption="A service mesh with control plane instances for each region"
    >}}

This model affords the following benefits:

- Improved availability: If a control plane becomes unavailable, the scope of
  the outage is limited to only workloads in clusters managed by that control plane.

- Configuration isolation: You can make configuration changes in one cluster,
  zone, or region without impacting others.

- Controlled rollout: You have more fine-grained control over configuration
  rollout (e.g., one cluster at a time). You can also canary configuration changes in a sub-section of the mesh
  controlled by a given primary cluster.

- Selective service visibility: You can restrict service visibility to part
  of the mesh, helping to establish service-level isolation. For example, an
  administrator may choose to deploy the `HelloWorld` service to Cluster A,
  but not Cluster B. Any attempt to call `HelloWorld` from Cluster B will
  fail the DNS lookup.

The following list ranks control plane deployment examples by availability:

- One cluster per region (**lowest availability**)
- Multiple clusters per region
- One cluster per zone
- Multiple clusters per zone
- Each cluster (**highest availability**)

### Endpoint discovery with multiple control planes

An Istio control plane manages traffic within the mesh by providing each proxy
with the list of service endpoints. In order to make this work in a
multicluster scenario, each control plane must observe endpoints from the API
Server in every cluster.

To enable endpoint discovery for a cluster, an administrator generates a
`remote secret` and deploys it to each primary cluster in the mesh. The
`remote secret` contains credentials, granting access to the API server in the
cluster.
The control planes will then connect and discover the service endpoints for
the cluster, enabling cross-cluster load balancing for these services.

{{< image width="75%"
    link="endpoint-discovery.svg"
    caption="Primary clusters with endpoint discovery"
    >}}

By default, Istio will load balance requests evenly between endpoints in
each cluster. In large systems that span geographic regions, it may be
desirable to use [locality load balancing](/docs/tasks/traffic-management/locality-load-balancing)
to prefer that traffic stay in the same zone or region.

In some advanced scenarios, load balancing across clusters may not be desired.
For example, in a blue/green deployment, you may deploy different versions of
the system to different clusters. In this case, each cluster is effectively
operating as an independent mesh. This behavior can be achieved in a couple of
ways:

- Do not exchange remote secrets between the clusters. This offers the
  strongest isolation between the clusters.

- Use `VirtualService` and `DestinationRule` to disallow routing between two
  versions of the services.

In either case, cross-cluster load balancing is prevented. External traffic
can be routed to one cluster or the other using an external load balancer.

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
allows workload instances in the mesh to authenticate each other when
communicating.

{{< image width="50%"
    link="single-trust.svg"
    alt="A service mesh with a common certificate authority"
    title="Trust within a mesh"
    caption="A service mesh with a common certificate authority"
    >}}

### Trust between meshes

To enable communication between two meshes with different CAs, you must
exchange the trust bundles of the meshes. Istio does not provide any tooling
to exchange trust bundles across meshes. You can exchange the trust bundles
either manually or automatically using a protocol such as [SPIFFE Trust Domain Federation](https://github.com/spiffe/spiffe/blob/main/standards/SPIFFE_Federation.md).
Once you import a trust bundle to a mesh, you can configure local policies for
those identities.

{{< image width="50%"
    link="multi-trust.svg"
    alt="Multiple service meshes with different certificate authorities"
    title="Trust between meshes"
    caption="Multiple service meshes with different certificate authorities"
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
{{< gloss >}}trust domain{{< /gloss >}}, you must federate
{{< gloss >}}identity{{< /gloss >}} and **trust bundles** between them. See the
section on [Trust between meshes](#trust-between-meshes) for more details.

## Tenancy models

In Istio, a **tenant** is a group of users that share
common access and privileges for a set of deployed workloads.
Tenants can be used to provide a level of isolation between different teams.

You can configure tenancy models to satisfy the following organizational
requirements for isolation:

- Security
- Policy
- Capacity
- Cost
- Performance

Istio supports three types of tenancy models:

- [Namespace tenancy](#namespace-tenancy)
- [Cluster tenancy](#cluster-tenancy)
- [Mesh tenancy](#mesh-tenancy)

### Namespace tenancy

A cluster can be shared across multiple teams, each using a different namespace.
You can grant a team permission to deploy its workloads only to a given namespace
or set of namespaces.

By default, services from multiple namespaces can communicate with each other,
but you can increase isolation by selectively choosing which services to expose to other
namespaces. You can configure authorization policies for exposed services to restrict
access to only the appropriate callers.

{{< image width="50%"
    link="exp-ns.svg"
    alt="A service mesh with two namespaces and an exposed service"
    title="Namespaces with an exposed service"
    caption="A service mesh with two namespaces and an exposed service"
    >}}

Namespace tenancy can extend beyond a single cluster.
When using [multiple clusters](#multiple-clusters), the namespaces in each
cluster sharing the same name are considered the same namespace by default.
For example, `Service B` in the `Team-1` namespace of cluster `West` and `Service B` in the
`Team-1` namespace of cluster `East` refer to the same service, and Istio merges their
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

To use cluster tenancy with Istio, you configure each team's cluster with its
own {{< gloss >}}control plane{{< /gloss >}}, allowing each team to manage its own configuration.
Alternatively, you can use Istio to implement a group of clusters as a single tenant
using {{< gloss "remote cluster" >}}remote clusters{{< /gloss >}} or multiple
synchronized {{< gloss "primary cluster" >}}primary clusters{{< /gloss >}}.
Refer to [control plane models](#control-plane-models) for details.

### Mesh Tenancy

In a multi-mesh deployment with {{< gloss >}}mesh federation{{< /gloss >}}, each mesh
can be used as the unit of isolation.

{{< image width="50%"
    link="cluster-iso.svg"
    alt="Two isolated service meshes with two clusters and two namespaces"
    title="Cluster isolation"
    caption="Two isolated service meshes with two clusters and two namespaces"
    >}}

Since a different team or organization operates each mesh, service naming
is rarely distinct. For example, a `Service C` in the `foo` namespace of
cluster `Team-1` and the `Service C` service in the `foo` namespace of cluster
`Team-2` will not refer to the same service. The most common example is the
scenario in Kubernetes where many teams deploy their workloads to the `default`
namespace.

When each team has its own mesh, cross-mesh communication follows the
concepts described in the [multiple meshes](#multiple-meshes) model.
