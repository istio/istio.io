---
title: Understanding DNS
linktitle: DNS
description: How DNS interacts with Istio.
weight: 31
keywords: [traffic-management,proxy]
owner: istio/wg-networking-maintainers
test: n/a
---

Istio interacts with DNS in different ways that can be confusing to understand.
This document provides a deep dive into how Istio and DNS work together.

{{< warning >}}
This document describes low level implementation details. For a higher level overview, check out the traffic management [Concepts](/docs/concepts/traffic-management/) or [Tasks](/docs/tasks/traffic-management/) pages.
{{< /warning >}}

## Scope and perspective

This document describes DNS behavior for application workloads running inside the Istio service mesh
(with Envoy sidecar proxies enabled).

Throughout this document, the term `client` refers to a workload inside the mesh.

## Life of a request

In these examples, we will walk through what happens when an application inside the mesh
runs `curl example.com`. While `curl` is used here for simplicity, the same applies to
almost all HTTP clients running within the mesh.

When you send a request to a domain, a client will first perform DNS resolution to resolve
the hostname to an IP address.
This happens regardless of any Istio settings, as Istio only intercepts network traffic;
it cannot change an application's decision to perform a DNS lookup.
In the example below, `example.com` resolves to `192.0.2.0`.

{{< text bash >}}
$ curl example.com -v
*   Trying 192.0.2.0:80...
{{< /text >}}

Only after DNS resolution succeeds does the application attempt to open a network connection,
which is the point at which Istio can intercept the traffic.

Next, the request is intercepted by Istio.
At this point, Istio sees both the hostname (from a `Host: example.com` header) and the
destination address (`192.0.2.0:80`).
Istio uses this information to determine the intended destination.
[Understanding Traffic Routing](/docs/ops/configuration/traffic-management/traffic-routing/)
provides a deep dive into how this behavior works.

If a mesh workload is unable to resolve the DNS name using its configured DNS resolver,
the connection is never initiated.

This means that if a workload sends a request to a hostname that is known to Istio
(for example, through a `ServiceEntry`) but is not resolvable by DNS,
the request will fail before any HTTP connection is attempted.
Istio [DNS proxying](#dns-proxying) can change this behavior by intercepting DNS requests
from the application and returning a response directly.

Once Istio has identified the intended destination, it must choose which address to send to.
Because of Istio's advanced [load balancing capabilities](/docs/concepts/traffic-management/#load-balancing-options),
this is often not the original IP address the client sent.
Depending on the service configuration, there are a few different ways Istio does this.

* Use the original IP address of the client (`192.0.2.0`, in the example above).
  This is the case for `ServiceEntry` of type `resolution: NONE` (the default) and
  [headless `Services`](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services).
* Load balance over a set of static IP addresses.
  This is the case for `ServiceEntry` of type `resolution: STATIC`, where all `spec.endpoints`
  are used, or for standard `Services`, where all `Endpoints` are used.
* Periodically resolve an address using DNS, and load balance across all results.
  This is the case for `ServiceEntry` of type `resolution: DNS`.

Note that in all cases, DNS resolution within the Istio proxy is orthogonal to DNS resolution
performed by the user application.
Even when the client performs DNS resolution, the proxy may ignore the resolved IP address
and use its own, which could be from a static list of IPs or from its own DNS resolution
(potentially of the same hostname or a different one).

## Proxy DNS resolution

Unlike most clients, which perform DNS requests on demand at request time (and then typically
cache the results), the Istio proxy never performs synchronous DNS requests.
When a `resolution: DNS` type `ServiceEntry` is configured, the proxy periodically resolves
the configured hostnames and uses those results for all requests.

This interval is fixed at 30 seconds and cannot be changed at this time.
DNS resolution occurs even if the proxy never sends any requests to the associated services.

For meshes with many proxies or many `resolution: DNS` type `ServiceEntries`, especially when
low DNS `TTL`s are used, this may cause a high load on DNS servers.
In these cases, the following can help reduce the load:

* Switch to `resolution: NONE` to avoid proxy DNS lookups entirely. This is suitable for many use cases.
* If you control the domains being resolved, increase their DNS `TTL`.
* If a `ServiceEntry` is only needed by a small number of workloads, limit its scope using
  `exportTo` or a [`Sidecar`](/docs/reference/config/networking/sidecar/).

## DNS proxying

Istio offers a feature to [proxy DNS requests](/docs/ops/configuration/traffic-management/dns-proxy/).
This allows Istio to capture DNS requests sent by the application and return responses directly.

DNS proxying can improve DNS latency, reduce load on upstream DNS servers, and allow
`ServiceEntry` hostnames that would otherwise be unknown to `kube-dns` to be resolved.

Note that DNS proxying only applies to DNS requests sent by user applications.
When `resolution: DNS` type `ServiceEntries` are used, DNS proxying does not affect
how the Istio proxy itself performs DNS resolution.
