---
title: Workload Instance
---
A single instantiation of a [workload's](/docs/reference/glossary/#workload) binary.
A workload instance can expose zero or more [service endpoints](/docs/reference/glossary/#service-endpoint),
and can consume zero or more [services](/docs/reference/glossary/#service).

Workload instances have a number of properties:

- Name and namespace
- Unique ID
- IP Address
- Labels
- Principal

These properties are available in policy and telemetry configuration
using the many [`source.*` and `destination.*` attributes](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/).
