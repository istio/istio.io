---
title: Workload Instance
test: n/a
---
A single instantiation of a [workload's](/es/docs/reference/glossary/#workload) binary.
A workload instance can expose zero or more [service endpoints](/es/docs/reference/glossary/#service-endpoint),
and can consume zero or more [services](/es/docs/reference/glossary/#service).

Workload instances have a number of properties:

- Name and namespace
- Unique ID
- IP Address
- Labels
- Principal

These properties are available in policy and telemetry configuration
using the many [`source.*` and `destination.*` attributes](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/attribute-vocabulary/).
