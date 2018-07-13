---
title: Service Registry
---

Istio maintains an internal service registry containing the set of [services](#service),
and their corresponding [service endpoints](#service-endpoint), running in a service mesh.
Most services are automatically added to the registry by platform-specific Pilot plug-ins,
but additional services can be registered manually using a
[ServiceEntry](/docs/concepts/traffic-management/#service-entries) configuration.

The service registry manifests itself as the set of available clusters that Pilot
provides to [Envoy](#envoy), via the CDS API, which it uses to forward service requests.
