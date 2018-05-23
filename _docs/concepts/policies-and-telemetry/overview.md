---
title: Overview
description: Describes the design of the policy and telemetry mechanisms.
weight: 5
redirect_from:
    - /docs/concepts/policy-and-control/mixer.html
---

{% include home.html %}

Istio provides a flexible model to enforce authorization policies and collect telemetry for the
services in a mesh.

Infrastructure backends are designed to provide support functionality
used to build services. They include such things as access control systems,
telemetry capturing systems, quota enforcement systems, billing systems, and so
forth. Services traditionally directly integrate with these backend systems,
creating a hard coupling and baking-in specific semantics and usage options.

Istio provides a uniform abstraction that makes it possible for Istio to interface with
an open-ended set of infrastructure backends. This is done in such a way to provide rich
and deep controls to the operator, while imposing no burden on service developers.
Istio is designed to change the boundaries between layers in order to reduce
systemic complexity, eliminate policy logic from service code and give
control to operators.

Mixer is the Istio component responsible for providing policy controls and telemetry collection:

{% include image.html width="75%" ratio="49.26%"
    link="./img/topology-without-cache.svg"
    caption="Mixer Topology"
    %}

The Envoy sidecar logically calls Mixer before each request to perform precondition checks, and after each request to report telemetry.
The sidecar has local caching such that a relatively large percentage of precondition checks can be performed from cache. Additionally, the
sidecar buffers outgoing telemetry such that it only actually needs to call Mixer infrequently.

At a high level, Mixer provides:

* **Backend Abstraction**. Mixer insulates the rest of Istio from the implementation details of individual infrastructure backends.

* **Intermediation**. Mixer allows operators to have fine-grained control over all interactions between the mesh and infrastructure backends.

Beyond these purely functional aspects, Mixer also has [reliability and scalability](#reliability-and-latency) benefits as outlined below.

Policy enforcement and telemetry collection are entirely driven from configuration.
It's possible to completely disable these features and avoid the need to run a
Mixer component in an Istio deployment.

## Adapters

Mixer is a highly modular and extensible component. One of its key functions is
to abstract away the details of different policy and telemetry backend systems,
allowing the rest of Istio to be agnostic of those backends.

Mixer's flexibility in dealing with different infrastructure backends is
achieved by having a general-purpose plug-in model. Individual plug-ins are
known as *adapters* and they allow Mixer to interface to different
infrastructure backends that deliver core functionality, such as logging,
monitoring, quotas, ACL checking, and more. The exact set of
adapters used at runtime is determined through configuration and can easily be
extended to target new or custom infrastructure backends.

{% include image.html width="35%" ratio="138%"
    link="./img/adapters.svg"
    alt="Showing Mixer with adapters."
    caption="Mixer and its Adapters"
    %}

## Reliability and latency

Mixer is a highly available component whose design helps increase overall availability and reduce average latency
of services in the mesh. Key aspects of its design deliver these benefits:

* **Statelessness**. Mixer is stateless in that it doesn’t manage any persistent storage of its own.

* **Hardening**. Mixer proper is designed to be a highly reliable component. The design intent is to achieve > 99.999% uptime for any individual Mixer instance.

* **Caching and Buffering**. Mixer is designed to accumulate a large amount of transient ephemeral state.

The sidecar proxies that sit next to each service instance in the mesh must necessarily be frugal in terms of memory consumption, which constrains the possible amount of local
caching and buffering. Mixer, however, lives independently and can use considerably larger caches and output buffers. Mixer thus acts as a highly-scaled and highly-available second-level
cache for the sidecars.

{% include image.html width="75%" ratio="65.89%"
    link="./img/topology-with-cache.svg"
    caption="Mixer Topology"
    %}

Since Mixer’s expected availability is considerably higher than most infrastructure backends (those often have availability of perhaps 99.9%). Mixer's local
caches and buffers not only contribute to reduce latency, they also help mask infrastructure backend failures by being able to continue operating
even when a backend has become unresponsive.

Finally, Mixer's caching and buffering helps reduce the frequency of calls to backends, and can sometimes reduce the amount of data
sent to backends (through local aggregation). Both of these can reduce operational expense in certain cases.

## What's next

* Read the [Mixer adapter model]({{home}}/blog/2017/adapter-model.html) blog post.
