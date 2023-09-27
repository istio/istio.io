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

## Life of a request

In these examples, we will walk through what happens when an application runs `curl example.com`.
While `curl` is used here, the same applies to almost all clients.

When you send a request to a domain, a client will do DNS resolution to resolve that to an IP address.
This happens regardless of any Istio settings, as Istio only intercepts networking traffic; it cannot change your application's behavior or decision to send a DNS request.
In the example below, `example.com` resolved to `192.0.2.0`.

{{< text bash >}}
$ curl example.com -v
*   Trying 192.0.2.0:80...
{{< /text >}}

Next, the request will be intercepted by Istio.
At this point, Istio will see both the hostname (from a `Host: example.com` header), and the destination address (`192.0.2.0:80`).
Istio uses this information to determine the intended destination.
[Understanding Traffic Routing](/docs/ops/configuration/traffic-management/traffic-routing/) gives a deep dive into how this behavior works.

If the client was unable to resolve the DNS request, the request would terminate before Istio receives it.
This means that if a request is sent to a hostname which is known to Istio (for example, by a `ServiceEntry`) but not to the DNS server, the request will fail.
Istio [DNS proxying](#dns-proxying) can change this behavior.

Once Istio has identified the intended destination, it must choose which address to send to.
Because of Istio's advanced [load balancing capabilities](/docs/concepts/traffic-management/#load-balancing-options), this is often not the original IP address the client sent.
Depending on the service configuration, there are a few different ways Istio does this.

* Use the original IP address of the client (`192.0.2.0`, in the example above).
  This is the case for `ServiceEntry` of type `resolution: NONE` (the default) and [headless `Services`](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services).
* Load balance over a set of static IP addresses.
  This is the case for `ServiceEntry` of type `resolution: STATIC`, where all `spec.endpoints` will be used, or for standard `Services`, where all `Endpoints` will be used.
* Periodically resolve an address using DNS, and load balance across all results.
  This is the case for `ServiceEntry` of type `resolution: DNS`.

Note that in all cases, DNS resolution within the Istio proxy is orthogonal to DNS resolution in a user application.
Even when the client does DNS resolution, the proxy may ignore the resolved IP address and use its own, which could be from
a static list of IPs or by doing its own DNS resolution (potentially of the same hostname or a different one).

## Proxy DNS resolution

Unlike most clients, which will do DNS requests on demand at the time of requests (and then typically cache the results),
the Istio proxy never does synchronous DNS requests.
When a `resolution: DNS` type `ServiceEntry` is configured, the proxy will periodically resolve the configured hostnames and use those for all requests.
This interval is determined by the [TTL](https://en.wikipedia.org/wiki/Time_to_live#DNS_records) of the DNS response.
This happens even if the proxy never sends any requests to these applications.

For meshes with many proxies or many `resolution: DNS` type `ServiceEntries`, especially when low `TTL`s are used, this may cause a high load on DNS servers.
In these cases, the following can help reduce the load:

* Switch to `resolution: NONE` to avoid proxy DNS lookups entirely. This is suitable for many use cases.
* If you control the domains being resolved, increase their TTL.
* If your `ServiceEntry` is only needed by a few workloads, limit its scope with `exportTo` or a [`Sidecar`](/docs/reference/config/networking/sidecar/).

## DNS Proxying

Istio offers a feature to [proxy DNS requests](/docs/ops/configuration/traffic-management/dns-proxy/).
This allows Istio to capture DNS requests sent by the client and return a response directly.
This can improve DNS latency, reduce load, and allow `ServiceEntries`, which otherwise would not be known to `kube-dns`, to be resolved.

Note this proxying only applies to DNS requests sent by user applications; when `resolution: DNS` type `ServiceEntries` are used,
the proxy has no impact on the DNS resolution of the Istio proxy.
