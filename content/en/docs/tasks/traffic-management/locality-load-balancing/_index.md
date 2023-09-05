---
title: Locality Load Balancing
description: This series of tasks demonstrate how to configure locality load balancing in Istio.
weight: 65
keywords: [locality,load balancing,priority,prioritized,kubernetes,multicluster]
list_below: true
simple_list: true
content_above: true
aliases:
  - /help/ops/traffic-management/locality-load-balancing
  - /help/ops/locality-load-balancing
  - /help/tasks/traffic-management/locality-load-balancing
  - /docs/ops/traffic-management/locality-load-balancing
  - /docs/ops/configuration/traffic-management/locality-load-balancing
owner: istio/wg-networking-maintainers
test: n/a
---
A *locality* defines the geographic location of a
{{< gloss >}}workload instance{{</ gloss >}} within your mesh. The following
triplet defines a locality:

- **Region**: Represents a large geographic area, such as *us-east*. A region
  typically contains a number of availability *zones*. In Kubernetes, the label
  [`topology.kubernetes.io/region`](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#topologykubernetesioregion)
  determines a node's region.

- **Zone**: A set of compute resources within a region. By running services in
  multiple zones within a region, failover can occur between zones within the
  region while maintaining data locality with the end-user. In Kubernetes, the
  label [`topology.kubernetes.io/zone`](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#topologykubernetesiozone)
  determines a node's zone.

- **Sub-zone**: Allows administrators to further subdivide zones for more
  fine-grained control, such as "same rack". The sub-zone concept doesn't exist
  in Kubernetes. As a result, Istio introduced the custom node label
  [`topology.istio.io/subzone`](/docs/reference/config/labels/#:~:text=topology.istio.io/subzone)
  to define a sub-zone.

{{< tip >}}
If you are using a hosted Kubernetes service your cloud provider should
configure the region and zone labels for you. If you are running your own
Kubernetes cluster you will need to add these labels to your nodes.
{{< /tip >}}

Localities are hierarchical, in the matching order:

1. Region

1. Zone

1. Sub-zone

That means that a pod running in zone `bar` of region `foo`
is **not** considered to be local to a pod running in zone `bar` of region
`baz`.

Istio uses this locality information to control load balancing behavior.
Follow one of the tasks in this series to configure locality load balancing for
your mesh.
