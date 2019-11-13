---
title: 工作负载实例
---
[工作负载](#workload) 二进制文件的一个单实例.
一个工作负载实例可以暴露零个或多个 [服务端点](#service-endpoint),
and can consume zero or more [services](#service).

Workload instances have a number of properties:

- Name and namespace
- Unique ID
- IP Address
- Labels
- Principal

These properties are available in policy and telemetry configuration
using the many [`source.*` and `destination.*` attributes](/docs/reference/config/policy-and-telemetry/attribute-vocabulary/).
