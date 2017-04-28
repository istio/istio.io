---
title: Attribute Vocabulary
overview: Describes the base attribute vocabulary used for policy and control.
          
order: 30

bodyclass: docs
layout: docs
type: markdown
---

Attributes are a central concept used throughout Istio. You can find a description of what attributes are
and what they are used for [here](/docs/concepts/policy-and-control/attributes.html).

A given Istio deployment has a fixed vocabulary of attributes that it understands. The specific vocabulary is
determined by the set of attribute producers being used in the deployment. The primary attribute producer in Istio
is Envoy, although Mixer and services can also introduce attributes.

## Standard Istio attribute vocabulary

The table below shows the set of canonical attributes and their respective types. Most Istio
deployments will have agents (Envoy or Mixer adapters) that produce these attributes.

| Name | Type | Description | Kubernetes Example |
|------|------|-------------|--------------------|
| source.ip | ip_address | The IP address of the client that sent the request. | 10.0.0.117 |
| source.port | int64 | The port on the client that sent the request. | 9284 |
| source.name | string | The fully qualified name of the application that sent the request. | redis-master.my-namespace.svc.cluster.local |
| source.uid | string | A unique identifier for the particular instance of the application that sent the request. | kubernetes://redis-master-2353460263-1ecey.my-namespace |
| source.namespace | string | The namespace of the sender of the request. | my-namespace |
| source.labels | map | A map of key-value pairs attached to the source. | |
| source.user | string | The user running the target application. | service-account |
| target.ip | ip_address | The IP address the request was sent to. | 10.0.0.104 |
| target.port | int64 | The port the request was sent to. | 8080 |
| target.service | dns_name | The hostname that was the target of the request. | my-svc.my-namespace.svc.cluster.local |
| target.name | string | The fully qualified name of the application that was the target of the request. | |
| target.uid | string | A unique identifier for the particular instance of the application that received the request. | |
| target.namespace | string | The namespace of the receiver of the request. | |
| target.labels | map | A map of key-value pairs attached to the target. | |
| target.user | string | The user running the target application. | service-account |
| request.headers | map | A map of HTTP headers attached to the request. | |
| request.id | string | A unique ID for the request, which can be propagated to downstream systems. This should be a guid or a psuedo-guid with a low probability of collision in a temporal window measured in days or weeks. | |
| request.path | string | The HTTP URL path including query string | |
| request.host | string | The HTTP Host header. | |
| request.method | string | The HTTP method. | |
| request.reason | string | The system parameter for auditing reason. It is required for cloud audit logging and GIN logging | |
| request.referer | string | The HTTP referer header. | |
| request.scheme | string | URI Scheme of the request | |
| request.size | int64 | Size of the request in bytes. For HTTP requests this is equivalent to the Content-Length header. | |
| request.time | timestamp | The timestamp when the target receives the request. This should be equivalent to Firebase "now". | |
| request.user-agent | string | The HTTP User-Agent header. | |
| response.headers | map | A map of HTTP headers attached to the response. | |
| response.size | int64 | Size of the response body in bytes | |
| response.time | timestamp | The timestamp when the target produced the response. | |
| response.duration | duration | The amount of time the response took to generate. | |
| response.code | int64 | The response's HTTP status code | |
