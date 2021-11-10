---
title: Multi-cluster Traffic Management
description: How to configure how traffic is distributed among clusters in the mesh.
weight: 70
keywords: [traffic-management,multicluster]
owner: istio/wg-networking-maintainers
test: no
---

### Services that are not the same

Within a multicluster mesh, [namespace sameness](https://github.com/kubernetes/community/blob/master/sig-multicluster/namespace-sameness-position-statement.md)
applies and all namespaces with a given name are considered to be the same namespace. If multiple clusters contain a
`Service` with the same namespaced name, they will be recognized as a single combined service. By default, traffic is
load-balanced across all clusters in the mesh for a given service. 

If there is no case where this traffic should be sent across clusters, consider giving the services a different name in each cluster.

### Partitioning Service Endpoints (i.e. creating subsets) 

Using the label `topology.istio.io/cluster` in the subset selector for a DestinationRule, you can create
per-cluster subsets.

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: mysvc-dr
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

### Keeping traffic in-cluster

In some cases the default cross-cluster load balancing behavior is not desirable. To keep traffic "cluster-local" (i.e.
traffic sent from `cluster-a` will only reach destinations in `cluster-a`), there are multiple-approaches.

#### Restrict destination subsets in `VirtualService`

{{< text yaml >}}
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: mysvc-vs
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

#### Global `MeshConfig` settings

Hostnames or wildcards can also be marked as `cluster-local`

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

