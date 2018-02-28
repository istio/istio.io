---
title: Attribute Vocabulary
overview: Describes the base attribute vocabulary used for policy and control.

order: 10

layout: docs
type: markdown
---
{% include home.html %}

Attributes are a central concept used throughout Istio. You can find a description of what attributes are
and what they are used for [here]({{home}}/docs/concepts/policy-and-control/attributes.html).

A given Istio deployment has a fixed vocabulary of attributes that it understands. The specific vocabulary is
determined by the set of attribute producers being used in the deployment. The primary attribute producer in Istio
is Envoy, although Mixer and services can also introduce attributes.

The table below shows the set of canonical attributes and their respective types. Most Istio
deployments will have agents (Envoy or Mixer adapters) that produce these attributes.

| Name | Type | Description | Kubernetes Example |
|------|------|-------------|--------------------|
| source.ip | ip_address | Client IP address. | 10.0.0.117 |
| source.service | string | The fully qualified name of the service that the client belongs to. | redis-master.my-namespace.svc.cluster.local |
| source.name | string | The short name part of the source service. | redis-master |
| source.namespace | string | The namespace part of the source service. | my-namespace |
| source.domain | string | The domain suffix part of the source service, excluding the name and the namespace. | svc.cluster.local |
| source.uid | string | Platform-specific unique identifier for the client instance of the source service. | kubernetes://redis-master-2353460263-1ecey.my-namespace |
| source.labels | map[string, string] | A map of key-value pairs attached to the client instance. | version => v1 |
| source.user | string | The identity of the immediate sender of the request, authenticated by mTLS. | service-account-foo |
| destination.ip | ip_address | Server IP address. | 10.0.0.104 |
| destination.port | int64 | The recipient port on the server IP address. | 8080 |
| destination.service | string | The fully qualified name of the service that the server belongs to. | my-svc.my-namespace.svc.cluster.local |
| destination.name | string | The short name part of the destination service. | my-svc |
| destination.namespace | string | The namespace part of the destination service. | my-namespace |
| destination.domain | string | The domain suffix part of the destination service, excluding the name and the namespace. | svc.cluster.local |
| destination.uid | string | Platform-specific unique identifier for the server instance of the destination service. | kubernetes://my-svc-234443-5sffe.my-namespace |
| destination.labels | map[string, string] | A map of key-value pairs attached to the server instance. | version => v2 |
| destination.user | string | The user running the destination application. | service-account |
| request.headers | map[string, string] | HTTP request headers. For gRPC, its metadata will be here. | |
| request.id | string | An ID for the request with statistically low probability of collision. | |
| request.path | string | The HTTP URL path including query string | |
| request.host | string | HTTP/1.x host header or HTTP/2 authority header. | redis-master:3337 |
| request.method | string | The HTTP method. | |
| request.reason | string | The request reason used by auditing systems. | |
| request.referer | string | The HTTP referer header. | |
| request.scheme | string | URI Scheme of the request | |
| request.size | int64 | Size of the request in bytes. For HTTP requests this is equivalent to the Content-Length header. | |
| request.time | timestamp | The timestamp when the destination receives the request. This should be equivalent to Firebase "now". | |
| request.useragent | string | The HTTP User-Agent header. | |
| response.headers | map[string, string] | HTTP response headers. | |
| response.size | int64 | Size of the response body in bytes | |
| response.time | timestamp | The timestamp when the destination produced the response. | |
| response.duration | duration | The amount of time the response took to generate. | |
| response.code | int64 | The response's HTTP status code. | |
| connection.id | string | An ID for a TCP connection with statistically low probability of collision. | |
| connection.received.bytes | int64 | Number of bytes received by a destination service on a connection since the last Report() for a connection. | |
| connection.received.bytes_total | int64 | Total number of bytes received by a destination service during the lifetime of a connection. | |
| connection.sent.bytes | int64 | Number of bytes sent by a destination service on a connection since the last Report() for a connection. | |
| connection.sent.bytes_total | int64 | Total number of bytes sent by a destination service during the lifetime of a connection. | |
| connection.duration | duration | The total amount of time a connection has been open. | |
| context.protocol | string | Protocol of the request or connection being proxied. | tcp |
| context.time | timestamp | The timestamp of Mixer operation. | |
| api.service | string | The public service name. This is different than the in-mesh service identity and reflects the name of the service exposed to the client. | my-svc.com |
| api.version | string | The API version. | v1alpha1 |
| api.operation | string | Unique string used to identify the operation. The id is unique among all operations described in a specific <service, version>. | getPetsById |
| api.protocol | string | The protocol type of the API call. Mainly for monitoring/analytics. Note that this is the frontend protocol exposed to the client, not the protocol implemented by the backend service. | "http", “https”, or "grpc" |
| request.auth.principal | string | The authenticated principal of the request. This is a string of the issuer (`iss`) and subject (`sub`) claims within a JWT concatenated with “/” with a percent-encoded subject value. | accounts.my-svc.com/104958560606 |
| request.auth.audiences | string | The intended audience(s) for this authentication information. This should reflect the audience (`aud`) claim within a JWT. | ['my-svc.com', 'scopes/read'] |
| request.auth.presenter | string | The authorized presenter of the credential. This value should reflect the optional Authorized Presenter (`azp`) claim within a JWT or the OAuth2 client id. | 123456789012.my-svc.com |
| request.api_key | string | The API key used for the request. | abcde12345 |
| check.error_code | int64 | The error [code](https://github.com/google/protobuf/blob/master/src/google/protobuf/stubs/status.h#L44) for Mixer Check call. | 5 |
| check.error_message | string | The error message for Mixer Check call. | Could not find the resource |
