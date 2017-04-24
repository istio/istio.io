---
category: Concepts
title: Istio-Manager

parent: Traffic Management
order: 10

bodyclass: docs
layout: docs
type: markdown
---

The Istio-Manager service is responsible for managing the lifecycle of
Envoy instances deployed across the Istio service mesh. It acts as a
discovery service for Envoy, providing service discovery, dynamic route
updates, etc. The discovery API decouples Envoy from
platform-specific nuances, simplifying the design and increasing
portability across platforms.

_Note that Istio does not provide service registration_. Instead, it relies
on the platform (e.g., Kubernetes, Mesos, CloudFoundry, etc.) to
automatically register pods/containers to their respective services, as
they come online.

The Istio-Manager maintains a canonical representation of services in the
mesh that is independent of the underlying platform. Platform-specific
adapters in the manager are responsible for populating this canonical model
appropriately. For example, the Kubernetes adapter in the Istio-Manager
implements the necessary controllers to watch the Kubernetes API server for
changes to the pod registration information, ingress resources, and third
party resources that store traffic management rules. This data is
translated into the canonical representation. Envoy-specific configuration
is generated based on the canonical representation.

Operators can specify high-level traffic management rules through the
[Istio-Manager's API (TBD)](). These rules are translated into low-level
configurations and distributed to Envoy instances via the discovery API.

Diagram showing adapters. TBD
