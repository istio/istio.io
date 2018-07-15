---
title: Service Registry
---

Istio maintains an internal service registry containing the set of [services](#service),
and their corresponding [service endpoints](#service-endpoint), running in a service mesh.
Istio uses the service registry to generate [Envoy](#envoy) configuration.

Istio does not provide [service discovery](https://en.wikipedia.org/wiki/Service_discovery),
although most services are automatically added to the registry by Pilot
adapters that reflect the discovered services of the underlying platform (k8s/consul/plain DNS).
Additional services can also be registered manually using a
[`ServiceEntry`](/docs/concepts/traffic-management/#service-entries) configuration.
