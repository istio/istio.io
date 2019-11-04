---
title: Constraints and Properties
description: Describes the supported constraints and properties.
weight: 10
---

This section contains the supported keys and value formats you can use as constraints and properties
in the service roles and service role bindings configuration objects.
Constraints and properties are extra conditions you can add as fields in configuration objects with
a `kind:` value of `ServiceRole` and `ServiceRoleBinding` to specify detailed access control requirements.

Specifically, you can use constraints to specify extra conditions in the access rule field of a service
role. You can use properties to specify extra conditions in the subject field of a service role binding.
Istio supports all keys listed on this page for the HTTP protocol but supports only some for the plain TCP protocol.

{{< warning >}}
Unsupported keys and values will be ignored silently.
{{< /warning >}}

For more information, refer to the [authorization concept page](/docs/concepts/security/#authorization).

## Supported constraints

The following table lists the currently supported keys for the `constraints` field:

| Name | Description | Supported for TCP services | Key Example | Values Example |
|------|-------------|----------------------------|-------------|----------------|
| `destination.ip` | Destination workload instance IP address, supports single IP or CIDR | YES | `destination.ip` |  `["10.1.2.3", "10.2.0.0/16"]` |
| `destination.port` | The recipient port on the server IP address, must be in the range [0, 65535] | YES | `destination.port` | `["80", "443"]` |
| `destination.labels` | A map of key-value pairs attached to the server instance | YES | `destination.labels[version]` | `["v1", "v2"]` |
| `destination.namespace` | Destination workload instance namespace | YES | `destination.namespace` | `["default"]` |
| `destination.user` | The identity of the destination workload | YES | `destination.user` | `["bookinfo-productpage"]` |
| `experimental.envoy.filters.*` | Experimental metadata matching for filters, values wrapped in `[]` are matched as a list | YES | `experimental.envoy.filters.network.mysql_proxy[db.table]` | `["[update]"]` |
| `request.headers` | HTTP request headers, The actual header name is surrounded by brackets | NO | `request.headers[X-Custom-Token]` | `["abc123"]` |

{{< warning >}}
Note that no backward compatibility is guaranteed for the `experimental.*` keys. They may be removed
at any time, and customers are advised to use them at their own risk.
{{< /warning >}}

## Supported properties

The following table lists the currently supported keys for the `properties` field:

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
