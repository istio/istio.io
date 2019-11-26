---
title: Mixer and the SPOF Myth
description: Improving availability and reducing latency.
publishdate: 2017-12-07
subtitle: Improving availability and reducing latency
attribution: Martin Taillefer
keywords: [adapters,mixer,policies,telemetry,availability,latency]
aliases:
    - /zh/blog/posts/2017/mixer-spof-myth.html
    - /zh/blog/mixer-spof-myth.html
target_release: 0.3
---

As [Mixer](/zh/docs/reference/config/policy-and-telemetry/) is in the request path, it is natural to question how it impacts
overall system availability and latency. A common refrain we hear when people first glance at Istio architecture diagrams is
"Isn't this just introducing a single point of failure?"

In this post, we’ll dig deeper and cover the design principles that underpin Mixer and the surprising fact Mixer actually
increases overall mesh availability and reduces average request latency.

Istio's use of Mixer has two main benefits in terms of overall system availability and latency:

* **Increased SLO**. Mixer insulates proxies and services from infrastructure backend failures, enabling higher effective mesh availability. The mesh as a whole tends to experience a lower rate of failure when interacting with the infrastructure backends than if Mixer were not present.

* **Reduced Latency**. Through aggressive use of shared multi-level caches and sharding, Mixer reduces average observed latencies across the mesh.

We'll explain this in more detail below.

## How we got here

For many years at Google, we’ve been using an internal API & service management system to handle the many APIs exposed by Google. This system has been fronting the world’s biggest services (Google Maps, YouTube, Gmail, etc) and sustains a peak rate of hundreds of millions of QPS. Although this system has served us well, it had problems keeping up with Google’s rapid growth, and it became clear that a new architecture was needed in order to tamp down ballooning operational costs.

In 2014, we started an initiative to create a replacement architecture that would scale better. The result has proven extremely successful and has been gradually deployed throughout Google, saving in the process millions of dollars a month in ops costs.

The older system was built around a centralized fleet of fairly heavy proxies into which all incoming traffic would flow, before being forwarded to the services where the real work was done. The newer architecture jettisons the shared proxy design and instead consists of a very lean and efficient distributed sidecar proxy sitting next to service instances, along with a shared fleet of sharded control plane intermediaries:

{{< image width="75%"
    link="./mixer-spof-myth-1.svg"
    title="Google System Topology"
    caption="Google's API & Service Management System"
    >}}

Look familiar? Of course: it’s just like Istio! Istio was conceived as a second generation of this distributed proxy architecture. We took the core lessons from this internal system, generalized many of the concepts by working with our partners, and created Istio.

## Architecture recap

As shown in the diagram below, Mixer sits between the mesh and the infrastructure backends that support it:

{{< image width="75%" link="./mixer-spof-myth-2.svg" caption="Istio Topology" >}}

The Envoy sidecar logically calls Mixer before each request to perform precondition checks, and after each request to report telemetry.
The sidecar has local caching such that a relatively large percentage of precondition checks can be performed from cache. Additionally, the
sidecar buffers outgoing telemetry such that it only actually needs to call Mixer once for every several thousands requests. Whereas precondition
checks are synchronous to request processing, telemetry reports are done asynchronously with a fire-and-forget pattern.

At a high level, Mixer provides:

* **Backend Abstraction**. Mixer insulates the Istio components and services within the mesh from the implementation details of individual infrastructure backends.

* **Intermediation**. Mixer allows operators to have fine-grained control over all interactions between the mesh and the infrastructure backends.

However, even beyond these purely functional aspects, Mixer has other characteristics that provide the system with additional benefits.

## Mixer: SLO booster

Contrary to the claim that Mixer is a SPOF and can therefore lead to mesh outages, we believe it in fact improves the effective availability of a mesh. How can that be? There are three basic characteristics at play:

* **Statelessness**. Mixer is stateless in that it doesn’t manage any persistent storage of its own.

* **Hardening**. Mixer proper is designed to be a highly reliable component. The design intent is to achieve > 99.999% uptime for any individual Mixer instance.

* **Caching and Buffering**. Mixer is designed to accumulate a large amount of transient ephemeral state.

The sidecar proxies that sit next to each service instance in the mesh must necessarily be frugal in terms of memory consumption, which constrains the possible amount of local caching and buffering. Mixer, however, lives independently and can use considerably larger caches and output buffers. Mixer thus acts as a highly-scaled and highly-available second-level cache for the sidecars.

Mixer’s expected availability is considerably higher than most infrastructure backends (those often have availability of perhaps 99.9%). Its local caches and buffers help mask infrastructure backend failures by being able to continue operating even when a backend has become unresponsive.

## Mixer: Latency slasher

As we explained above, the Istio sidecars generally have fairly effective first-level caching. They can serve the majority of their traffic from cache. Mixer provides a much greater shared pool of second-level cache, which helps Mixer contribute to a lower average per-request latency.

While it’s busy cutting down latency, Mixer is also inherently cutting down the number of calls your mesh makes to infrastructure backends. Depending on how you’re paying for these backends, this might end up saving you some cash by cutting down the effective QPS to the backends.

## Work ahead

We have opportunities ahead to continue improving the system in many ways.

### Configuration canaries

Mixer is highly scaled so it is generally resistant to individual instance failures. However, Mixer is still susceptible to cascading
failures in the case when a poison configuration is deployed which causes all Mixer instances to crash basically at the same time
(yeah, that would be a bad day). To prevent this from happening, configuration changes can be canaried to a small set of Mixer instances,
and then more broadly rolled out.

Mixer doesn’t yet do canarying of configuration changes, but we expect this to come online as part of Istio’s ongoing work on reliable
configuration distribution.

### Cache tuning

We have yet to fine-tune the sizes of the sidecar and Mixer caches. This work will focus on achieving the highest performance possible using the least amount of resources.

### Cache sharing

At the moment, each Mixer instance operates independently of all other instances. A request handled by one Mixer instance will not leverage data cached in a different instance. We will eventually experiment with a distributed cache such as memcached or Redis in order to provide a much larger mesh-wide shared cache, and further reduce the number of calls to infrastructure backends.

### Sharding

In very large meshes, the load on Mixer can be great. There can be a large number of Mixer instances, each straining to keep caches primed to
satisfy incoming traffic. We expect to eventually introduce intelligent sharding such that Mixer instances become slightly specialized in
handling particular data streams in order to increase the likelihood of cache hits. In other words, sharding helps improve cache
efficiency by routing related traffic to the same Mixer instance over time, rather than randomly dispatching to
any available Mixer instance.

## Conclusion

Practical experience at Google showed that the model of a slim sidecar proxy and a large shared caching control plane intermediary hits a sweet
spot, delivering excellent perceived availability and latency. We’ve taken the lessons learned there and applied them to create more sophisticated and
effective caching, prefetching, and buffering strategies in Istio. We’ve also optimized the communication protocols to reduce overhead when a cache miss does occur.

Mixer is still young. As of Istio 0.3, we haven’t really done significant performance work within Mixer itself. This means when a request misses the sidecar
cache, we spend more time in Mixer to respond to requests than we should. We’re doing a lot of work to improve this in coming months to reduce the overhead
that Mixer imparts in the synchronous precondition check case.

We hope this post makes you appreciate the inherent benefits that Mixer brings to Istio.
Don’t hesitate to post comments or questions to [istio-policies-and-telemetry@](https://groups.google.com/forum/#!forum/istio-policies-and-telemetry).

