---
title: Attribute
test: no
---

Attributes control the runtime behavior of services running in the mesh.
Attributes are named and typed pieces of metadata describing ingress and egress traffic and the
environment this traffic occurs in. An Istio attribute carries a specific piece
of information such as the error code of an API request, the latency of an API request, or the
original IP address of a TCP connection. For example:

{{< text yaml >}}
request.path: xyz/abc
request.size: 234
request.time: 12:34:56.789 04/17/2017
source.ip: 192.168.0.1
destination.workload.name: example
{{< /text >}}

Attributes are used by Istio's [policy and telemetry](https://istio.io/v1.6/docs/reference/config/policy-and-telemetry/) features.
