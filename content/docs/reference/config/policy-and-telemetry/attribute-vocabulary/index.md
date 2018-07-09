---
title: Attribute Vocabulary
description: Describes the base attribute vocabulary used for policy and control.
weight: 10
aliases:
    - /docs/reference/config/mixer/attribute-vocabulary.html
---

Attributes are a central concept used throughout Istio. You can find a description of what attributes are
and what they are used for [here](/docs/concepts/policies-and-telemetry/#attributes).

A given Istio deployment has a fixed vocabulary of attributes that it understands. The specific vocabulary is
determined by the set of attribute producers being used in the deployment. The primary attribute producer in Istio
is Envoy, although Mixer and services can also introduce attributes.

The table below shows the set of canonical attributes and their respective types. Most Istio
deployments will have agents (Envoy or Mixer adapters) that produce these attributes.

| Name | Type | Description | Kubernetes Example |
|------|------|-------------|--------------------|
| `source.uid`                | string | Platform-specific unique identifier for the source workload instance. | kubernetes://redis-master-2353460263-1ecey.my-namespace |
| `source.ip`                 | ip_address | Source workload instance IP address. | 10.0.0.117 |
| `source.labels`             | map[string, string] | A map of key-value pairs attached to the source instance. | version => v1 |
| `source.name`               | string | Source workload instance name. | redis-master-2353460263-1ecey |
| `source.namespace`          | string | Source workload instance namespace. | my-namespace |
| `source.principal`          | string | The identity of the immediate sender of the request, authenticated by mTLS. | service-account-foo |
| `source.owner`              | string | Reference to the workload controlling the source workload instance. | `kubernetes://apis/extensions/v1beta1/namespaces/istio-system/deployments/istio-policy` |
| `source.workload.uid`       | string | Unique identifier of the source workload. | istio://istio-system/workloads/istio-policy |
| `source.workload.name`      | string | Source workload name. | istio-policy |
| `source.workload.namespace` | string | Source workload namespace.  | istio-system |
| `destination.uid`               | string | Platform-specific unique identifier for the server instance. | kubernetes://my-svc-234443-5sffe.my-namespace |
| `destination.ip`                | ip_address | Server IP address. | 10.0.0.104 |
| `destination.port`              | int64 | The recipient port on the server IP address. | 8080 |
| `destination.labels`            | map[string, string] | A map of key-value pairs attached to the server instance. | version => v2 |
| `destination.name`              | string | Destination workload instance name. | `istio-telemetry-2359333` |
| `destination.namespace`         | string | Destination workload instance namespace. | istio-system |
| `destination.principal`         | string | The user running the destination application. | service-account |
| `destination.owner`             | string | Reference to the workload controlling the destination workload instance.| `kubernetes://apis/extensions/v1beta1/namespaces/istio-system/deployments/istio-telemetry` |
| `destination.workload.uid`      | string | Unique identifier of the destination workload. | istio://istio-system/workloads/istio-telemetry |
| `destination.workload.name`     | string | Destination workload name. | istio-telemetry |
| `destination.workload.namespace`| string | Destination workload namespace. | istio-system |
| `destination.container.name`    | string | Container name of the server workload instance. | mixer |
| `destination.container.image`   | string | Image source for the destination container. | `gcr.io/istio-testing/mixer:0.8.0` |
| `destination.service.host`      | string | Destination host address. | istio-telemetry.istio-system.svc.cluster.local |
| `destination.service.uid`       | string | Unique identifier of the destination service. | istio://istio-system/services/istio-telemetry |
| `destination.service.name`      | string | Destination service name. | istio-telemetry |
| `destination.service.namespace` | string | Destination service namespace. | istio-system |
| `request.headers` | map[string, string] | HTTP request headers. For gRPC, its metadata will be here. | |
| `request.id` | string | An ID for the request with statistically low probability of collision. | |
| `request.path` | string | The HTTP URL path including query string | |
| `request.host` | string | HTTP/1.x host header or HTTP/2 authority header. | redis-master:3337 |
| `request.method` | string | The HTTP method. | |
| `request.reason` | string | The request reason used by auditing systems. | |
| `request.referer` | string | The HTTP referer header. | |
| `request.scheme` | string | URI Scheme of the request | |
| `request.size` | int64 | Size of the request in bytes. For HTTP requests this is equivalent to the Content-Length header. | |
| `request.total_size` | int64 | Total size of HTTP request in bytes, including request headers, body and trailers. | |
| `request.time` | timestamp | The timestamp when the destination receives the request. This should be equivalent to Firebase "now". | |
| `request.useragent` | string | The HTTP User-Agent header. | |
| `response.headers` | map[string, string] | HTTP response headers. | |
| `response.size` | int64 | Size of the response body in bytes | |
| `response.total_size` | int64 | Total size of HTTP response in bytes, including response headers and body. | |
| `response.time` | timestamp | The timestamp when the destination produced the response. | |
| `response.duration` | duration | The amount of time the response took to generate. | |
| `response.code` | int64 | The response's HTTP status code. | |
| `response.grpc_status` | string | The response's gRPC status. | |
| `response.grpc_message` | string | The response's gRPC status message. | |
| `connection.id` | string | An ID for a TCP connection with statistically low probability of collision. | |
| `connection.event` | string | Status of a TCP connection, its value is one of "open", "continue" and "close". | |
| `connection.received.bytes` | int64 | Number of bytes received by a destination service on a connection since the last Report() for a connection. | |
| `connection.received.bytes_total` | int64 | Total number of bytes received by a destination service during the lifetime of a connection. | |
| `connection.sent.bytes` | int64 | Number of bytes sent by a destination service on a connection since the last Report() for a connection. | |
| `connection.sent.bytes_total` | int64 | Total number of bytes sent by a destination service during the lifetime of a connection. | |
| `connection.duration` | duration | The total amount of time a connection has been open. | |
| `connection.mtls` | boolean | Indicates whether a request is received over a mTLS enabled downstream connection. | |
| `context.protocol`      | string | Protocol of the request or connection being proxied. | tcp |
| `context.time`          | timestamp | The timestamp of Mixer operation. | |
| `context.reporter.kind` | string | Contextualizes the reported attribute set. Set to `inbound` for the server-side calls from sidecars and `outbound` for the client-side calls from sidecars and gateways | `inbound` |
| `context.reporter.uid`  | string | Platform-specific identifier of the attribute reporter. |  kubernetes://my-svc-234443-5sffe.my-namespace |
| `api.service` | string | The public service name. This is different than the in-mesh service identity and reflects the name of the service exposed to the client. | my-svc.com |
| `api.version` | string | The API version. | v1alpha1 |
| `api.operation` | string | Unique string used to identify the operation. The id is unique among all operations described in a specific &lt;service, version&gt;. | getPetsById |
| `api.protocol` | string | The protocol type of the API call. Mainly for monitoring/analytics. Note that this is the frontend protocol exposed to the client, not the protocol implemented by the backend service. | "http", “https”, or "grpc" |
| `request.auth.principal` | string | The authenticated principal of the request. This is a string of the issuer (`iss`) and subject (`sub`) claims within a JWT concatenated with “/” with a percent-encoded subject value. This attribute may come from the peer or the origin in the Istio authentication policy, depending on the binding rule defined in the Istio authentication policy. | accounts.my-svc.com/104958560606 |
| `request.auth.audiences` | string | The intended audience(s) for this authentication information. This should reflect the audience (`aud`) claim within a JWT. | ['my-svc.com', 'scopes/read'] |
| `request.auth.presenter` | string | The authorized presenter of the credential. This value should reflect the optional Authorized Presenter (`azp`) claim within a JWT or the OAuth2 client id. | 123456789012.my-svc.com |
| `request.auth.claims` | map[string, string] | all raw string claims from the `origin` JWT | `iss`: `issuer@foo.com`, `sub`: `sub@foo.com`, `aud`: `aud1` |
| `request.api_key` | string | The API key used for the request. | abcde12345 |
| `check.error_code` | int64 | The error [code](https://github.com/google/protobuf/blob/master/src/google/protobuf/stubs/status.h#L44) for Mixer Check call. | 5 |
| `check.error_message` | string | The error message for Mixer Check call. | Could not find the resource |
| `check.cache_hit` | boolean | Indicates whether Mixer check call hits local cache. | |
| `quota.cache_hit` | boolean | Indicates whether Mixer quota call hits local cache. | |

## Deprecated attributes

The following attributes have been renamed. We strongly encourage to use the replacement attributes, as the original names will be removed in subsequent releases:

| Name | Replacement |
|------|-------------|
|`source.user`          |`source.principal`|
|`destination.user`     |`destination.principal`|
|`destination.service`  |`destination.service.host`|

Attributes `source.name` and `destination.name` have been re-purposed to refer
to the corresponding source and destination workload instance names instead of
the service names.

The following attributes have been deprecated and will be removed in subsequent releases:

| Name | Type | Description | Kubernetes Example |
|------|------|-------------|--------------------|
| `source.service` | string | The fully qualified name of the service that the client belongs to. | redis-master.my-namespace.svc.cluster.local |
| `source.domain` | string | The domain suffix part of the source service, excluding the name and the namespace. | svc.cluster.local |
| `destination.domain`            | string | The domain suffix part of the destination service, excluding the name and the namespace. | svc.cluster.local |
