---
title: Multi-cluster Traffic Management
description: How to configure how traffic is distributed among clusters in the mesh.
weight: 70
keywords: [traffic-management,multicluster]
owner: istio/wg-networking-maintainers
test: no
---

Within a multicluster mesh, [namespace sameness](https://github.com/kubernetes/community/blob/master/sig-multicluster/namespace-sameness-position-statement.md)
applies and all namespaces with a given name are considered to be the same namespace. If multiple clusters contain a
`Service` with the same namespaced name, they will be recognized as a single combined service. By default, traffic is
load-balanced across all clusters in the mesh for a given service. In some cases, that behavior is not desirable, and
this document describes the different options for overriding that default.

## Cluster Local Services

### `DestinationRule` subsets 

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

To restrict traffic to only the local cluster, add a VirtualService. You can extend this configuration
to apply traffic shifting or mirroring rules on a per-cluster basis.

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
    route:
    - destination:
      host: mysvc.myns.svc.cluster.local
      subset: cluster-1
{{< /text >}}

### Per-cluster `Service` or `Namespace`

If `Services` aren't meant to be used cross-cluster at all, it may make sense to simply give them unique names in each
cluster. Naming the service `svc-a` in `cluster-a` and `svc-b` in `cluster-b` will ensure there is no cross-cluster
communication.

### `MeshConfig`

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