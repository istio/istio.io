---
title: Multi-cluster Traffic Management
description: How to configure how traffic is distributed among clusters in the mesh.
weight: 70
keywords: [traffic-management,multicluster]
owner: istio/wg-networking-maintainers
test: no
---

### Prerequisites

1. Read [Deployment Models](/docs/ops/deployment/deployment-models/#multiple-clusters)
2. Make sure your deployed services follow the concept of {{< gloss "namespace sameness" >}}namespace sameness{{< /gloss >}}.

### Keeping traffic in-cluster

In some cases the default cross-cluster load balancing behavior is not desirable. To keep traffic "cluster-local" (i.e.
traffic sent from `cluster-a` will only reach destinations in `cluster-a`), mark hostnames or wildcards as `clusterLocal`
using [`MeshConfig.serviceSettings`](/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig-ServiceSettings-Settings).

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

{{< tab name="global" category-value="service" >}}

{{< text yaml >}}
serviceSettings:
- settings:
  clusterLocal: true
  hosts:
    - "*"
{{< /text >}}

{{< /tab >}}

{{< /tabset >}}

### Partitioning Services {#partitioning-services}

[DestinationRule.subsets](/docs/reference/config/networking/destination-rule/#Subset) allows partitioning a service
by selecting labels. These labels can be the labels from Kubernetes metadata, or from [built-in labels](/docs/reference/config/labels/).
One of these built-in labels, `topology.istio.io/cluster`, in the subset selector for a DestinationRule allows creating
per-cluster subsets.

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

### Locality Load Balancing

When using a multi-cluster mesh for redundancy and resiliency, it may be desirable to only send cross-cluster traffic
when necessary. Using [Locality Load Balancing](/docs/tasks/traffic-management/locality-load-balancing/) settings, you
can configure locality weighted distribution or failover.

On top of default locality components of `region/zone/subzone`, you can use [`failoverPriority`](/docs/reference/config/networking/destination-rule/#LocalityLoadBalancerSetting)
to failover based on the cluster or network explicitly. Using the following destination rule, traffic will prefer first
in-cluster traffic, then in-network, then in-region, etc.

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: mysvc-cluster-failover
spec:
  host: mysvc.myns.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
      localityLbSetting:
        enabled: true
        failoverPriority:
        - "topology.istio.io/cluster"
        - "topology.istio.io/network"
        - "topology.kubernetes.io/region"
        - "topology.kubernetes.io/zone"
        - "topology.istio.io/subzone"
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 1m
{{< /text >}}
