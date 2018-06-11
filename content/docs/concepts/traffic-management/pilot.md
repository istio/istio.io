---
title: Pilot
description: Introduces Pilot, the component responsible for managing a distributed deployment of Envoy proxies in the service mesh.
weight: 10
keywords: [traffic-management,pilot]
aliases:
    - /docs/concepts/traffic-management/manager.html
---

Pilot is responsible for the lifecycle of Envoy instances deployed
across the Istio service mesh.

{{< image width="60%" ratio="72.17%"
    link="../img/pilot/PilotAdapters.svg"
    caption="Pilot Architecture"
    >}}

As illustrated in the figure above, Pilot maintains a canonical
representation of services in the mesh that is independent of the underlying
platform. Platform-specific adapters in Pilot are responsible for
populating this canonical model appropriately. For example, the Kubernetes
adapter in Pilot implements the necessary controllers to watch the
Kubernetes API server for changes to the pod registration information, ingress
resources, and third party resources that store traffic management rules.
This data is translated into the canonical representation. Envoy-specific
configuration is generated based on the canonical representation.

Pilot exposes APIs for [service discovery](https://www.envoyproxy.io/docs/envoy/latest/api-v1/cluster_manager/sds),
dynamic updates to [load balancing pools](https://www.envoyproxy.io/docs/envoy/latest/configuration/cluster_manager/cds)
and [routing tables](https://www.envoyproxy.io/docs/envoy/latest/configuration/http_conn_man/rds).
These APIs decouple Envoy from platform-specific nuances, simplifying the
design and increasing portability across platforms.

Operators can specify high-level traffic management rules through
[Pilot's Rules API](/docs/reference/config/istio.routing.v1alpha1/). These rules are translated into low-level
configurations and distributed to Envoy instances via the discovery API.
