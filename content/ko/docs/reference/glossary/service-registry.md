---
title: Service Registry
test: n/a
---

Istio maintains an internal service registry containing the set of [services](/ko/docs/reference/glossary/#service),
and their corresponding [service endpoints](/ko/docs/reference/glossary/#service-endpoint), running in a service mesh.
Istio uses the service registry to generate [Envoy](/ko/docs/reference/glossary/#envoy) configuration.

Istio does not provide [service discovery](https://en.wikipedia.org/wiki/Service_discovery),
although most services are automatically added to the registry by [Pilot](/ko/docs/reference/glossary/#pilot)
adapters that reflect the discovered services of the underlying platform (Kubernetes, Consul, plain DNS).
Additional services can also be registered manually using a
[`ServiceEntry`](/ko/docs/concepts/traffic-management/#service-entries) configuration.
