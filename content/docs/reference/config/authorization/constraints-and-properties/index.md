---
title: Constraints and Properties
description: Describes the supported constraints and properties.
weight: 10
---

This page lists the supported keys and value formats that could be used in Constraints and Properties.
Constraints and Properties are extra conditions that could be used in `ServiceRole` and `ServiceRoleBinding`
to specify detailed access control requirements.

Specifically, `Constraints` are used to specify additional custom constraints in the `AccessRule` of
a `ServiceRole` and `Properties` are used to specify additional custom properties in the `Subject` of
a `ServiceRoleBinding`

* For service using HTTP protocol, all keys listed in this page are supported
* For service using plain TCP protocol, only part of the keys are supported, use of unsupported keys
  will result the whole policy to be ignored
* Unsupported keys and values will be silently ignored

For more information, please refer to [authorization concept page](/docs/concepts/security/#authorization).

## Available Constraints

The following table lists the currently supported keys in Constraints.

| Name | Description | Supported for TCP services | Key Example | Values Example |
|------|-------------|----------------------------|-------------|----------------|
| `destination.ip` | Destination workload instance IP address, supports single IP or CIDR | YES | `destination.ip` |  `["10.1.2.3", "10.2.0.0/16"]` |
| `destination.port` | The recipient port on the server IP address, must be in the range [0, 65535] | YES | `destination.port` | `["80", "443"]` |
| `destination.labels` | A map of key-value pairs attached to the server instance | YES | `destination.labels[version]` | `["v1", "v2"]` |
| `destination.name` | Destination workload instance name | YES | `destination.name` | `["productpage*", "*-test"]` |
| `destination.namespace` | Destination workload instance namespace | YES | `destination.namespace` | `["default"]` |
| `destination.user` | The identity of the destination workload | YES | `destination.user` | `["bookinfo-productpage"]` |
| `request.headers` | HTTP request headers, The actual header name is surrounded by brackets | NO | `request.headers[X-Custom-Token]` | `["abc123"]` |

## Available Properties

The following table lists the currently supported keys in Properties.

| Name | Description | Supported for TCP services | Key Example | Value Example |
|------|-------------|----------------------------|-------------|---------------|
| `source.ip`  | Source workload instance IP address, supports single IP or CIDR | YES | `source.ip` | `"10.1.2.3"` |
| `source.namespace`  | Source workload instance namespace | YES | `source.namespace` | `"default"` |
| `source.principal` | The identity of the source workload | YES | `source.principal` | `"cluster.local/ns/default/sa/productpage"` |
| `request.headers` | HTTP request headers. The actual header name is surrounded by brackets | NO | `request.headers[User-Agent]` | `"Mozilla/*"` |
| `request.auth.principal` | The authenticated principal of the request. | NO | `request.auth.principal` | `"accounts.my-svc.com/104958560606"` |
| `request.auth.audiences` | The intended audience(s) for this authentication information | NO | `request.auth.audiences` | `"my-svc.com"` |
| `request.auth.presenter` | The authorized presenter of the credential | NO | `request.auth.presenter` | `"123456789012.my-svc.com"` |
| `request.auth.claims` | Claims from the origin JWT. The actual claim name is surrounded by brackets | NO | `request.auth.claims[iss]` | `"*@foo.com"` |
