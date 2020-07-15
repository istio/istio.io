---
title: Attribute Vocabulary (Deprecated)
description: Describes the base attribute vocabulary used for policy and control.
weight: 10
aliases:
    - /docs/reference/config/mixer/attribute-vocabulary.html
    - /docs/reference/config/mixer/aspects/attributes.html
owner: istio/wg-policies-and-telemetry-maintainers
test: n/a
---

Attributes are a central concept used throughout Istio. You can find a description of what attributes are
and what they are used for [here](/docs/reference/config/policy-and-telemetry/mixer-overview/#attributes).

A given Istio deployment has a fixed vocabulary of attributes that it understands. The specific vocabulary is
determined by the set of attribute producers being used in the deployment. The primary attribute producer in Istio
is Envoy, although Mixer and services can also introduce attributes.

The table below shows the set of canonical attributes and their respective types. Most Istio
deployments will have agents (Envoy or Mixer adapters) that produce these attributes.

| Name | Type | Description | Kubernetes Example |
|------|------|-------------|--------------------|
| `source.uid`                | string | Platform-specific unique identifier for the source workload instance. | `kubernetes://redis-master-2353460263-1ecey.my-namespace` |
| `source.ip`                 | ip_address | Source workload instance IP address. | `10.0.0.117` |
| `source.labels`             | map[string, string] | A map of key-value pairs attached to the source instance. | version => v1 |
| `source.name`               | string | Source workload instance name. | `redis-master-2353460263-1ecey` |
| `source.namespace`          | string | Source workload instance namespace. | `my-namespace` |
| `source.principal`          | string | Authority under which the source workload instance is running. | `service-account-foo` |
| `source.owner`              | string | Reference to the workload controlling the source workload instance. | `kubernetes://apis/apps/v1/namespaces/istio-system/deployments/istio-policy` |
| `source.workload.uid`       | string | Unique identifier of the source workload. | `istio://istio-system/workloads/istio-policy` |
| `source.workload.name`      | string | Source workload name. | `istio-policy` |
| `source.workload.namespace` | string | Source workload namespace.  | `istio-system` |
| `destination.uid`               | string | Platform-specific unique identifier for the server instance. | `kubernetes://my-svc-234443-5sffe.my-namespace` |
| `destination.ip`                | ip_address | Server IP address. | `10.0.0.104` |
| `destination.port`              | int64 | The recipient port on the server IP address. | `8080` |
| `destination.labels`            | map[string, string] | A map of key-value pairs attached to the server instance. | version => v2 |
| `destination.name`              | string | Destination workload instance name. | `istio-telemetry-2359333` |
| `destination.namespace`         | string | Destination workload instance namespace. | `istio-system` |
| `destination.principal`         | string | Authority under which the destination workload instance is running. | `service-account` |
| `destination.owner`             | string | Reference to the workload controlling the destination workload instance.| `kubernetes://apis/apps/v1/namespaces/istio-system/deployments/istio-telemetry` |
| `destination.workload.uid`      | string | Unique identifier of the destination workload. | `istio://istio-system/workloads/istio-telemetry` |
| `destination.workload.name`     | string | Destination workload name. | `istio-telemetry` |
| `destination.workload.namespace` | string | Destination workload namespace. | `istio-system` |
| `destination.container.name`    | string | Name of the destination workload instance's container. | `mixer` |
| `destination.container.image`   | string | Image of the destination workload instance's container. | `gcr.io/istio-testing/mixer:0.8.0` |
| `destination.service.host`      | string | Destination host address. | `istio-telemetry.istio-system.svc.cluster.local` |
| `destination.service.uid`       | string | Unique identifier of the destination service. | `istio://istio-system/services/istio-telemetry` |
| `destination.service.name`      | string | Destination service name. | `istio-telemetry` |
| `destination.service.namespace` | string | Destination service namespace. | `istio-system` |
| `origin.ip` | ip_address | IP address of the proxy client, e.g. origin for the ingress proxies. | `127.0.0.1` |
| `request.headers` | map[string, string] | HTTP request headers with lowercase keys. For gRPC, its metadata will be here. | |
| `request.id` | string | An ID for the request with statistically low probability of collision. | |
| `request.path` | string | The HTTP URL path including query string | |
| `request.url_path` | string | The path part of HTTP URL, with query string being stripped | |
| `request.query_params` | map[string, string] | A map of query parameters extracted from the HTTP URL. | |
| `request.host` | string | HTTP/1.x host header or HTTP/2 authority header. | `redis-master:3337` |
| `request.method` | string | The HTTP method. | |
| `request.reason` | string | The request reason used by auditing systems. | |
| `request.referer` | string | The HTTP referer header. | |
| `request.scheme` | string | URI Scheme of the request | |
| `request.size` | int64 | Size of the request in bytes. For HTTP requests this is equivalent to the Content-Length header. | |
| `request.total_size` | int64 | Total size of HTTP request in bytes, including request headers, body and trailers. | |
| `request.time` | timestamp | The timestamp when the destination receives the request. This should be equivalent to Firebase "now". | |
| `request.useragent` | string | The HTTP User-Agent header. | |
| `response.headers` | map[string, string] | HTTP response headers with lowercase keys. | |
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
| `connection.mtls` | boolean | Indicates whether a request is received over a mutual TLS enabled downstream connection. | |
| `connection.requested_server_name` | string | The requested server name (SNI) of the connection | |
| `context.protocol`      | string | Protocol of the request or connection being proxied. | `tcp` |
| `context.time`          | timestamp | The timestamp of Mixer operation. | |
| `context.reporter.kind` | string | Contextualizes the reported attribute set. Set to `inbound` for the server-side calls from sidecars and `outbound` for the client-side calls from sidecars and gateways | `inbound` |
| `context.reporter.uid`  | string | Platform-specific identifier of the attribute reporter. | `kubernetes://my-svc-234443-5sffe.my-namespace` |
| `context.proxy_error_code` | string | Additional details about the response or connection from proxy. In case of Envoy, see `%RESPONSE_FLAGS%` in [Envoy Access Log](https://www.envoyproxy.io/docs/envoy/latest/configuration/observability/access_log/usage#config-access-log-format-response-flags) for more detail | `UH` |
| `api.service` | string | The public service name. This is different than the in-mesh service identity and reflects the name of the service exposed to the client. | `my-svc.com` |
| `api.version` | string | The API version. | `v1alpha1` |
| `api.operation` | string | Unique string used to identify the operation. The id is unique among all operations described in a specific &lt;service, version&gt;. | `getPetsById` |
| `api.protocol` | string | The protocol type of the API call. Mainly for monitoring/analytics. Note that this is the frontend protocol exposed to the client, not the protocol implemented by the backend service. | `http`, `https`, or `grpc` |
| `request.auth.principal` | string | The authenticated principal of the request. This is a string of the issuer (`iss`) and subject (`sub`) claims within a JWT concatenated with "/” with a percent-encoded subject value. This attribute may come from the peer or the origin in the Istio authentication policy, depending on the binding rule defined in the Istio authentication policy. | `issuer@foo.com/sub@foo.com` |
| `request.auth.audiences` | string | The intended audience(s) for this authentication information. This should reflect the audience (`aud`) claim within a JWT. | `aud1` |
| `request.auth.presenter` | string | The authorized presenter of the credential. This value should reflect the optional Authorized Presenter (`azp`) claim within a JWT or the OAuth2 client id. | 123456789012.my-svc.com |
| `request.auth.claims` | map[string, string] | all raw string claims from the `origin` JWT | `iss`: `issuer@foo.com`, `sub`: `sub@foo.com`, `aud`: `aud1` |
| `request.api_key` | string | The API key used for the request. | abcde12345 |
| `check.error_code` | int64 | The error [code](https://github.com/google/protobuf/blob/master/src/google/protobuf/stubs/status.h) for Mixer Check call. | 5 |
| `check.error_message` | string | The error message for Mixer Check call. | Could not find the resource |
| `check.cache_hit` | boolean | Indicates whether Mixer check call hits local cache. | |
| `quota.cache_hit` | boolean | Indicates whether Mixer quota call hits local cache. | |

## Timestamp and duration attributes format

Timestamp attributes are represented in the RFC 3339 format. When operating with timestamp attributes, you can use the `timestamp` function defined in [CEXL](/docs/reference/config/policy-and-telemetry/expression-language/) to convert a textual timestamp in RFC 3339 format into the `TIMESTAMP` type, for example: `request.time | timestamp("2018-01-01T22:08:41+00:00")`, `response.time > timestamp("2020-02-29T00:00:00-08:00")`.

Duration attributes represent an amount of time, expressed as a series of decimal numbers with an optional fractional part denoted with a period, and a unit value. The possible unit values are `ns` for nanoseconds, `us` (or `µs`) for microseconds, `ms` for milliseconds, `s` for seconds, `m` for minutes, `h` for hours. For example:

* `1ms` represents 1 millisecond
* `2.3s` represents 2.3 seconds
* `4m` represents 4 minutes
* `5h10m` represents 5 hours and 10 minutes
