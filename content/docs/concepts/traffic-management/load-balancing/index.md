---
title: Discovery and Load Balancing
description: Describes the service discovery and load balancing behavior of Istio.
weight: 7
keywords: [load balance, virtual service, service registry, load balance pool, gateway, service entry, routing rules, destination rules]
aliases:
---

Istio load balances traffic across the instances of a service in the mesh.

Istio assumes the presence of a service registry to keep track of the pods or
VMs implementing a service in the application. Any new instances of a service
must automatically register with the service registry and unhealthy instances
must be automatically removed. Platforms such as **Kubernetes** and **Mesos**
provide such functionality for container-based applications, and many solutions
exist for VM-based applications.

**Pilot** consumes information from the service registry and provides a
platform-independent service discovery interface. Envoy instances in the mesh
perform service discovery and dynamically update their load balancing pools
accordingly.

{{< image width="40%"
    link="./load-balancing.svg"
    caption="Istio's discovery and load balancing model"
    >}}

The figure above shows how services in the mesh access each other
using their DNS names. All HTTP traffic bound to a service is automatically
re-routed through Envoy. Envoy distributes the traffic across instances in
the load balancing pool. While Envoy supports several
[sophisticated load balancing algorithms](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/load_balancing),
Istio currently allows three load balancing modes:

- Round robin
- Random
- Weighted least request

Additionally, Envoy periodically checks the health of each instance in the
pool. Envoy follows a circuit breaker pattern to classify instances as
unhealthy or healthy based on their failure rates for the health check API
call.

In other words, when the number of failed health checks for a given instance
exceeds a specified threshold, Envoy ejects the instance from the load balancing
pool. Similarly, when the number of passed health checks exceeds a
specified threshold, Envoy adds the instance back into the load balancing
pool.

To find out more about Envoy's failure-handling features, visit the [Handling Failures section](../failures).

Services can actively shed load with an `HTTP 503` response to a health check.
In such an event, Envoy immediately removes the service instance from the
caller's load balancing pool.
