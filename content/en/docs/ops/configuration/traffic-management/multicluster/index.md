---
title: Multi-cluster Traffic Management
description: How to configure how traffic is distributed among clusters in the mesh.
weight: 70
keywords: [traffic-management,multicluster]
owner: istio/wg-networking-maintainers
test: no
---

Within a multicluster mesh, traffic rules specific to the cluster topology may be desirable. This document describes
a few ways to manage traffic in a multicluster mesh. Before reading this guide:

1. Read [Deployment Models](/docs/ops/deployment/deployment-models/#multiple-clusters)
1. Make sure your deployed services follow the concept of {{< gloss "namespace sameness" >}}namespace sameness{{< /gloss >}}.

## Keeping traffic in-cluster

In some cases the default cross-cluster load balancing behavior is not desirable. To keep traffic "cluster-local" (i.e.
traffic sent from `cluster-a` will only reach destinations in `cluster-a`), mark hostnames or wildcards as `clusterLocal`
using [`MeshConfig.serviceSettings`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ServiceSettings-Settings).

For example, you can enforce cluster-local traffic for an individual service, all services in a particular namespace, or globally for all services in the mesh, as follows:

{{< tabset category-name="meshconfig" >}}

{{< tab name="per-service" category-value="service" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "mysvc.myns.svc.cluster.local"
{{< /text >}}

{{< /tab >}}

{{< tab name="per-namespace" category-value="namespace" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "*.myns.svc.cluster.local"
{{< /text >}}

{{< /tab >}}

{{< tab name="global" category-value="global" >}}

{{< text yaml >}}
serviceSettings:
- settings:
    clusterLocal: true
  hosts:
  - "*"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

## Partitioning Services {#partitioning-services}

[`DestinationRule.subsets`](/docs/reference/config/networking/destination-rule/#Subset) allows partitioning a service
by selecting labels. These labels can be the labels from Kubernetes metadata, or from [built-in labels](/docs/reference/config/labels/).
One of these built-in labels, `topology.istio.io/cluster`, in the subset selector for a `DestinationRule` allows
creating per-cluster subsets.

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: mysvc-per-cluster-dr
spec:
  host: mysvc.myns.svc.cluster.local
  subsets:
  - name: cluster-1
    labels:
      topology.istio.io/cluster: cluster-1
  - name: cluster-2
    labels:
      topology.istio.io/cluster: cluster-2
{{< /text >}}

Using these subsets you can create various routing rules based on the cluster such as [mirroring](/docs/tasks/traffic-management/mirroring/)
or [shifting](/docs/tasks/traffic-management/traffic-shifting/).

This provides another option to create cluster-local traffic rules by restricting the destination subset in a `VirtualService`:

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: mysvc-cluster-local-vs
spec:
  hosts:
  - mysvc.myns.svc.cluster.local
  http:
  - name: "cluster-1-local"
    match:
    - sourceLabels:
        topology.istio.io/cluster: "cluster-1"
    route:
    - destination:
        host: mysvc.myns.svc.cluster.local
        subset: cluster-1
  - name: "cluster-2-local"
    match:
    - sourceLabels:
        topology.istio.io/cluster: "cluster-2"
    route:
    - destination:
        host: mysvc.myns.svc.cluster.local
        subset: cluster-2
{{< /text >}}

Using subset-based routing this way to control cluster-local traffic, as opposed to
[`MeshConfig.serviceSettings`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ServiceSettings-Settings),
has the downside of mixing service-level policy with topology-level policy.
For example, a rule that sends 10% of traffic to `v2` of a service will need twice the
number of subsets (e.g., `cluster-1-v2`, `cluster-2-v2`).
This approach is best limited to situations where more granular control of cluster-based routing is needed.
