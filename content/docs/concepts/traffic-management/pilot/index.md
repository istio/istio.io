---
title: Pilot and Envoy
description: Describes the behavior and architecture of Pilot and the role of the Envoy proxies in an Istio mesh.
weight: 2
keywords: [Pilot, Envoy, control plane, proxy, timeouts, retries, network configuration, virtual service, destination rule, service entry, gateway]
aliases:
    - /docs/concepts/traffic-management/pilot
---

The core component used for traffic management in Istio is **Pilot**, which
manages and configures all the Envoy proxy instances deployed in a particular
Istio service mesh. Pilot lets you specify which rules you want to use to route
traffic between Envoy proxies and configure [failure recovery](../failures)
features such as:

* [Timeouts](../failures/#timeouts)
* [Retries](../failures/#retries)
* [Circuit breakers](../failures/#circuit)

**Pilot** also maintains a canonical model of all the services in the mesh and
uses this model to let Envoy instances know about the other Envoy instances in
the mesh via Pilot's discovery service.

Each Envoy instance maintains [load balancing information](../load-balancing)
based on the information it gets from **Pilot** and the periodic health-checks
of other instances in its load-balancing pool. This information allows
**Pilot** to intelligently distribute traffic between destination instances
while following the configured routing rules.

**Pilot** is responsible for the life-cycle of Envoy instances deployed
across the Istio service mesh.

The following diagram shows Pilot's architecture:

{{< image width="60%"
    link="./pilot-architecture.svg"
    caption="Pilot's Architecture"
    >}}

**Pilot** maintains a canonical representation of services in the mesh in its
`Abstract Model` that is independent of the `Platform Adapters`.
Platform-specific adapters in **Pilot** populate this canonical model
appropriately. For example, the Kubernetes adapter in Pilot implements the
necessary controllers to watch the Kubernetes API server for changes to the pod
registration information, ingress resources, and third-party resources that
store traffic management rules. The adapter translates this data into the
canonical representation in the `Abstract Model`. **Pilot** then generates an
Envoy-specific configuration based on the canonical representation.

This Pilot architecture enables:

* Service discovery

* Dynamic updates to load balancing pools

* Routing tables

To specify high-level traffic management rules through **Pilot**, use the
[traffic routing APIs](/docs/reference/config/istio.networking.v1alpha3/).
These rules are translated into low-level configurations and distributed to
Envoy instances.

## Network configuration objects {#net-objects}

**Pilot** uses the Istio network configuration objects provide you with four
objects to configure the routing rules between your services and your external
resources: virtual services, destination rules, service entries, and gateways.
You can add and configure these objects in a variety of ways to suit your
needs. Each configuration object serves a specific purpose and provides
specific configurations for your Istio service mesh. To create a solution for
your specific mesh, you can combine the configuration objects in a way that
best fulfills your needs. You can configure routing rules using any of the four
network configuration objects in Istio:

* A [virtual service](../virtual-services) configures the routing rules
  controlling the requests to services within an Istio service mesh.

* A [destination rule](../destination-rules) configures the set of routing
  rules and policies **Pilot** applies to a request after the routing for
  virtual services is complete.

* A [service entry](../service-entries) adds services outside an Istio service
  mesh to Istio's service registry to enable routing rules for requests to
  services outside of the Istio service mesh.

* A [gateway](../gateways) configures a load balancer for HTTP/TCP traffic.
  Gateways most commonly operate at the edge of the mesh to configure routing
  rules for ingress or egress traffic for an application.

In Kubernetes, you can apply the configured routing rules using the `kubectl`
command. Visit the [configuring request routing task](/docs/tasks/traffic-management/request-routing/)
for examples.

You define the Istio network configuration objects as Kubernetes Custom
Resource Definition [(CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
objects and store their configuration in YAML files.
