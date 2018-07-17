---
title: Constraints and Properties
description: Describes the supported constraints and properties.
weight: 10
---

This page lists the supported keys that could be used in `Constraints` and `Properties`.
`Constraints` are used to specify additional custom conditions in a `ServiceRole`, `Properties` are used to specify
additional custom conditions in a `ServiceRoleBinding`. For more information, please refer to [authorization concept page](/docs/concepts/security/#authorization).

## Constraints

The following table lists the currently supported keys in Constraints:

| Name | Description | Key Example | Values Example |
|------|-------------|-------------|----------------|
| `destination.ip` | Destination workload instance IP address, supports single IP or CIDR | `destination.ip` |  `["10.1.2.3", "10.2.0.0/16"]` |
| `destination.port` | The recipient port on the server IP address, must be in the range [0, 65535] | `destination.port` | `["80", "443"]` |
| `destination.labels` | A map of key-value pairs attached to the server instance | `destination.labels[version]` | `["v1", "v2"]` |
| `destination.name` | Destination workload instance name | `destination.name` | `["productpage*", "*-test"]` |
| `destination.namespace` | Destination workload instance namespace | `destination.namespace` | `["default"]` |
| `destination.user` | The identity of the destination workload | `destination.user` | `["bookinfo-productpage"]` |
| `request.headers` | HTTP request headers, The actual header name is surrounded by brackets | `request.headers[X-Custom-Token]` | `["abc123"]` |

## Properties

The following table lists the currently supported keys in Properties:

| Name | Description | Key Example | Value Example |
|------|-------------|-------------|---------------|
| `source.ip`  | Source workload instance IP address, supports single IP or CIDR | `source.ip` | `"10.1.2.3"` |
| `source.namespace`  | Source workload instance namespace | `source.namespace` | `"default"` |
| `source.principal` | The identity of the source workload | `source.principal` | `"cluster.local/ns/default/sa/productpage"` |
| `request.headers` | HTTP request headers. The actual header name is surrounded by brackets | `request.headers[User-Agent]` | `"Mozilla/*"` |
| `request.auth.principal` | The authenticated principal of the request. | `request.auth.principal` | `"accounts.my-svc.com/104958560606"` |
| `request.auth.audiences` | The intended audience(s) for this authentication information | `request.auth.audiences` | `"my-svc.com"` |
| `request.auth.presenter` | The authorized presenter of the credential | `request.auth.presenter` | `"123456789012.my-svc.com"` |
| `request.auth.claims` | Claims from the origin JWT. The actual claim name is surrounded by brackets | `request.auth.claims[iss]` | `"*@foo.com"` |
