---
title: Workload Instance
---
A single instantiation of a [workload's](#workload) binary.
A workload instance can expose zero or more [service endpoints](#service-endpoint),
and can consume zero or more [services](#service).

Workload instances have a number of properties:

- Name and namespace
- Unique ID
- IP Address
- Labels
- Principal

These properties are available in policy and telemetry configuration
using the many [`source.*` and `destination.*` attributes](/pt-br/docs/reference/config/policy-and-telemetry/attribute-vocabulary/).
