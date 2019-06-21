---
title: Overview and Terminology
description: Learn about Pilot, Istio's core traffic management component and Envoy proxies and how they enable service discovery and load balancing.
weight: 1
keywords: [traffic-management, pilot, envoy-proxies, service-discovery, load-balancing]
---

With Istio, you can manage [traffic routing](/docs/concepts/traffic-management/routing)
and [load balancing](/docs/concepts/traffic-management/overview/#load-balancing)
for your service mesh without having to update your services. Istio simplifies
configuration of service-level properties like timeouts and retries, and makes
it straightforward to set up tasks like staged rollouts with percentage-based
traffic splits.

Istio's traffic management model relies on the following two components:

- {{< gloss >}}Pilot{{</ gloss >}}, the core traffic management component.
- {{< gloss >}}Envoy{{</ gloss >}} proxies, which enforce configurations and policies set through Pilot.

These components enable the following high-level features:

- Service discovery
- Load balancing

## Pilot: Core traffic management {#pilot}

The following diagram shows the Pilot architecture:

{{< image width="40%"
    link="./pilot-arch.svg"
    caption="Pilot architecture"
    >}}

As the diagram illustrates, Pilot maintains an **abstract model** of all the
services in the mesh. **Platform-specific adapters** in Pilot translate the
abstract model appropriately for your platform.

For example, the Kubernetes adapter implements controllers to watch the
Kubernetes API server for changes to pod registration information, ingress
resources, and third-party resources like custom resource definitions (CRDs)
that store traffic management rules. The Kubernetes adapter translates this
data for the abstract model, so Pilot can generate and deliver the appropriate
Envoy-specific configurations.

The Pilot **service discovery and traffic rules** use the abstract model to let
Envoy proxies know about one another in the mesh through the **Envoy API.**

You can use the **Networking and Rules APIs** to exercise more granular control
over the traffic in your service mesh.

## Envoy proxies

Traffic in Istio is categorized as data plane traffic and control plane
traffic. Data plane traffic refers to the data that the business logic of the
workloads manipulate. Control plane traffic refers to configuration and control
data sent between Istio components to program the behavior of the mesh. Traffic
management in Istio refers exclusively to data plane traffic.

Envoy proxies are the only Istio components that interact with data plane
traffic. Envoy proxies route the data plane traffic across the mesh and enforce
the configurations and traffic rules without the services having to be aware of
them. Envoy proxies mediate all inbound and outbound traffic for all services
in the mesh. Envoy proxies are deployed as sidecars to services, logically
augmenting the services with traffic management features, including the two
discussed in this overview:

- [Service discovery](/docs/concepts/traffic-management/overview/#discovery)
- [Load balancing](/docs/concepts/traffic-management/overview/#load-balancing)

The [traffic routing and configuration](/docs/concepts/traffic-management/routing/)
and [network resilience and testing](/docs/concepts/traffic-management/network/)
sections dig into more sophisticated features and tasks enabled by Envoy
proxies, which include:

- Traffic control features: enforce fine-grained traffic control with rich
   routing rules for HTTP, gRPC, WebSocket, and TCP traffic.

- Network resiliency features: setup retries, failovers, circuit breakers, and
   fault injection.

- Security and authentication features: enforce security policies and enforce
   access control and rate limiting defined through the configuration API.

### Platform-agnostic service discovery {#discovery}

Service discovery works in a similar way regardless of what platform you're
using:

1. The platform starts a new instance of a service which notifies its platform
   adapter.

1. The platform adapter registers the instance with the Pilot abstract model.

1. **Pilot** distributes traffic rules and configurations to the Envoy proxies
   to account for the change.

The following diagram shows how the platform adapters and Envoy proxies
interact.

{{< image width="40%"
    link="./discovery.svg"
    caption="Service discovery"
    >}}

Because the service discovery feature is platform-independent:

- A service mesh can include services across multiple platforms.

- Envoy proxies enforce the traffic rules, configurations, and load balancing
   for all instances.

You can use the Istio service discovery features with the features provided by
platforms like Kubernetes for container-based applications. See your platform's
documentation for more information.

### Load balancing

Using Istio, all traffic bound to a service goes through the appropriate Envoy
proxy. Envoy proxies distribute the traffic across the instances in the calling
service's load balancing pool, and update load balancing pools according to
changes to the Pilot abstract model.

Istio supports the following load balancing methods:

- Round robin: Requests are forwarded to instances in the pool in turn, and
   the algorithm instructs the load balancer to go back to the top of the pool
   and repeat.

- Random: Requests are forwarded at random to instances in the pool.

- Weighted: Requests are forwarded to instances in the pool according to a
   specific percentage.

- Least requests: Requests are forwarded to instances with the least number of
   requests. See the [Envoy load balancing documentation](https://www.envoyproxy.io/docs/envoy/v1.5.0/intro/arch_overview/load_balancing)
   for more information.

You can also choose to prioritize your load balancing pools based on geographic
location. Visit the [operations guide](/docs/ops/traffic-management/locality-load-balancing/)
for more information on the locality load balancing feature.

### Example traffic configuration

The following diagram shows a basic example of traffic management using Pilot
and Envoy proxies:

{{< image width="60%"
    link="./routing-overview.svg"
    caption="Traffic management example"
    >}}

To learn more about the traffic management resources shown, see the [Traffic routing and configuration concept](/docs/concepts/traffic-management/routing/)

