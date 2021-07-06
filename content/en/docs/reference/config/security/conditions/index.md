---
title: Authorization Policy Conditions
description: Describes the supported conditions in authorization policies.
weight: 30
aliases:
    - /docs/reference/config/security/conditions/
    - /docs/reference/config/security/constraints-and-properties/
owner: istio/wg-security-maintainers
test: n/a
---

This page describes the supported keys and value formats you can use as conditions
in the `when` field of an [authorization policy rule](/docs/reference/config/security/authorization-policy/#Rule).

For more information, refer to the [authorization concept page](/docs/concepts/security/#authorization).

## Supported Conditions

| Name | Description | Supported Protocols | Example |
|------|-------------|--------------------|---------|
| `request.headers` | HTTP request headers. The header name is surrounded by `[]` without any quotes | HTTP only | `key: request.headers[User-Agent]`<br/>`values: ["Mozilla/*"]` |
| `source.ip`  | Source workload instance IP address, supports single IP or CIDR | HTTP and TCP | `key: source.ip`<br/>`values: ["10.1.2.3", "10.2.0.0/16"]` |
| `remote.ip`  | Original client IP address as determined by X-Forwarded-For header or Proxy Protocol, supports single IP or CIDR | HTTP and TCP | `key: remote.ip`<br />`values: ["10.1.2.3", "10.2.0.0/16"]` |
| `source.namespace`  | Source workload instance namespace, requires mutual TLS enabled | HTTP and TCP | `key: source.namespace`<br/>`values: ["default"]` |
| `source.principal` | The identity of the source workload, requires mutual TLS enabled | HTTP and TCP | `key: source.principal`<br/>`values: ["cluster.local/ns/default/sa/productpage"]` |
| `request.auth.principal` | The principal of the authenticated JWT token, constructed from the JWT claims in the format of `<iss>/<sub>`, requires request authentication policy applied | HTTP only | `key: request.auth.principal`<br/>`values: ["issuer.example.com/subject-admin"]` |
| `request.auth.audiences` | The intended audiences of the authenticated JWT token, constructed from the JWT claim `<aud>`, requires request authentication policy applied | HTTP only | `key: request.auth.audiences`<br/>`values: ["example.com"]` |
| `request.auth.presenter` | The authorized presenter of the authenticated JWT token, constructed from the JWT claim `<azp>`, requires request authentication policy applied | HTTP only | `key: request.auth.presenter`<br/>`values: ["123456789012.example.com"]` |
| `request.auth.claims` | Raw claims of the authenticated JWT token. The claim name is surrounded by `[]` without any quotes, nested claim can also be used, requires request authentication policy applied. Note only support claim of type string or list of string | HTTP only | `key: request.auth.claims[iss]`<br/>`values: ["*@foo.com"]`<br/>---<br/>`key: request.auth.claims[nested1][nested2]`<br/>`values: ["some-value"]` |
| `destination.ip` | Destination workload instance IP address, supports single IP or CIDR | HTTP and TCP | `key: destination.ip`<br/>`values: ["10.1.2.3", "10.2.0.0/16"]` |
| `destination.port` | Destination workload instance port, must be in the range [0, 65535]. Note this is not the service port | HTTP and TCP | `key: destination.port`<br/>`values: ["80", "443"]` |
| `connection.sni` | The server name indication, requires TLS enabled | HTTP and TCP | `key: connection.sni`<br/>`values: ["www.example.com"]` |
| `experimental.envoy.filters.*` | Experimental metadata matching for filters, values wrapped in `[]` are matched as a list | HTTP and TCP | `key: experimental.envoy.filters.network.mysql_proxy[db.table]`<br/>`values: ["[update]"]` |

{{< warning >}}
No backward compatibility is guaranteed for the `experimental.*` keys. They may be removed
at any time, and customers are advised to use them at their own risk.
{{< /warning >}}
