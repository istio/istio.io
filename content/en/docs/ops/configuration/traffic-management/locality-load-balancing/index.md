---
title: Locality Load Balancing
description: Information on how to enable and understand Locality Load Balancing.
weight: 20
keywords: [locality,load balancing,priority,prioritized]
aliases:
  - /help/ops/traffic-management/locality-load-balancing
  - /help/ops/locality-load-balancing
  - /help/tasks/traffic-management/locality-load-balancing
  - /docs/ops/traffic-management/locality-load-balancing
---

A locality defines a geographic location within your mesh using the following triplet:

- Region
- Zone
- Sub-zone

The geographic location typically represents a data center. Istio uses
this information to prioritize load balancing pools to control
the geographic location where requests are sent.

## Configuring locality load balancing

This feature is enabled by default. To disable locality load balancing,
pass the `--set global.localityLbSetting.enabled=false` flag when installing Istio.

## Requirements

Currently, the service discovery platform populates the locality automatically.
In Kubernetes, a pod's locality is determined via the [well-known labels for region and zone](https://kubernetes.io/docs/reference/kubernetes-api/labels-annotations-taints/#failure-domainbetakubernetesioregion)
on the node it is deployed. If you are using a hosted Kubernetes service your cloud provider
should configure this for you. If you are running your own Kubernetes cluster you will need
to add these labels to your nodes. The sub-zone concept doesn't exist in Kubernetes.
As a result, Istio introduced the custom node label `topology.istio.io/subzone` to define a sub-zone.

In order for Istio to determine locality, a Service must be associated with the caller.

To determine when instances are unhealthy, the proxies require an [outlier detection](/docs/reference/config/networking/destination-rule/#OutlierDetection)
configuration in a destination rule for each service.

## Locality-prioritized load balancing

_Locality-prioritized load balancing_ is the default behavior for _locality load balancing_.
In this mode, Istio tells Envoy to prioritize traffic to the workload instances most closely matching
the locality of the Envoy sending the request. When all instances are healthy, the requests
remains within the same locality. When instances become unhealthy, traffic spills over to
instances in the next prioritized locality. This behavior continues until all localities are
receiving traffic. You can find the exact percentages in the [Envoy documentation](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/load_balancing/priority).

  {{< warning >}}
  If no outlier detection configurations are defined in destination rules, the proxy can't determine if an instance is healthy, and it
  routes traffic globally even if you enabled **locality-prioritized** load balancing.
  {{< /warning >}}

A typical prioritization for an Envoy with a locality of `us-west/zone2` is as follows:

- Priority 0: `us-west/zone2`
- Priority 1: `us-west/zone1`, `us-west/zone3`
- Priority 2: `us-east/zone1`, `us-east/zone2`, `eu-west/zone1`

The hierarchy of prioritization matches in the following order:

1. Region
1. Zone
1. Sub-zone

Proxies in the same zone but different regions are not considered local to one another.

### Overriding the locality fail-over

Sometimes, you need to constrain the traffic fail-over to avoid sending traffic to
endpoints across the globe when there are not enough healthy endpoints in the
same region. This behavior is useful when sending fail-over traffic across regions
would not improve service health or many other reasons including regulatory controls.
To constrain traffic to a region, configure the `values.localityLbSetting` option during install. See the
[Locality load balancing reference guide](/docs/reference/config/networking/destination-rule#LocalityLoadBalancerSetting)
for options.

An example configuration:

{{< text yaml >}}
global:
  localityLbSetting:
    enabled: true
    failover:
    - from: us-east
      to: eu-west
    - from: us-west
      to: us-east
{{< /text >}}

## Locality-weighted load balancing

Locality-weighted load balancing distributes user-defined percentages of traffic to certain localities.

For example, if we want to keep 80% of traffic within our region, and send 20% of traffic out of region:

{{< text yaml >}}
global:
  localityLbSetting:
    enabled: true
    distribute:
    - from: "us-central1/*"
      to:
        "us-central1/*": 80
        "us-central2/*": 20
{{< /text >}}
