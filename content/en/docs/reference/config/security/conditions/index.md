---
title: Authorization Policy Conditions
description: Describes the supported conditions in authorization policies.
weight: 30
aliases:
    - /docs/reference/config/security/conditions/
---

This page describes the supported keys and value formats you can use as conditions
in the `when` field of [authorization policy resources](/docs/reference/config/security/authorization-policy/).

{{< warning >}}
Unsupported keys and values are silently ignored.
{{< /warning >}}

For more information, refer to the [authorization concept page](/docs/concepts/security/#authorization).

## Supported Conditions

| Name | Description | Supported Protocols | Example |
|------|-------------|--------------------|---------|
| `request.headers` | HTTP request headers. The actual header name is surrounded by brackets | HTTP only | `key: request.headers[User-Agent]`<br/>`values: ["Mozilla/*"]` |
| `source.ip`  | Source workload instance IP address, supports single IP or CIDR | HTTP and TCP | `key: source.ip`<br/>`values: ["10.1.2.3"]` |
| `source.namespace`  | Source workload instance namespace, requires mutual TLS enabled | HTTP and TCP | `key: source.namespace`<br/>`values: ["default"]` |
| `source.principal` | The identity of the source workload, requires mutual TLS enabled | HTTP and TCP | `key: source.principal`<br/>`values: ["cluster.local/ns/default/sa/productpage"]` |
| `request.auth.principal` | The authenticated principal of the request. | HTTP only | `key: request.auth.principal`<br/>`values: ["accounts.my-svc.com/104958560606"]` |
| `request.auth.audiences` | The intended audience(s) for this authentication information | HTTP only | `key: request.auth.audiences`<br/>`values: ["my-svc.com"]` |
| `request.auth.presenter` | The authorized presenter of the credential | HTTP only | `key: request.auth.presenter`<br/>`values: ["123456789012.my-svc.com"]` |
| `request.auth.claims` | Claims from the origin JWT. The actual claim name is surrounded by brackets | HTTP only | `key: request.auth.claims[iss]`<br/>`values: ["*@foo.com"]` |
| `destination.ip` | Destination workload instance IP address, supports single IP or CIDR | HTTP and TCP | `key: destination.ip`<br/>`values: ["10.1.2.3", "10.2.0.0/16"]` |
| `destination.port` | The recipient port on the server IP address, must be in the range [0, 65535] | HTTP and TCP | `key: destination.port`<br/>`values: ["80", "443"]` |
| `connection.sni` | The server name indication, requires mutual TLS enabled | HTTP and TCP | `key: connection.sni`<br/>`values: ["www.example.com"]` |
| `experimental.envoy.filters.*` | Experimental metadata matching for filters, values wrapped in `[]` are matched as a list | HTTP and TCP | `key: experimental.envoy.filters.network.mysql_proxy[db.table]`<br/>`values: ["[update]"]` |

{{< warning >}}
No backward compatibility is guaranteed for the `experimental.*` keys. They may be removed
at any time, and customers are advised to use them at their own risk.
{{< /warning >}}
