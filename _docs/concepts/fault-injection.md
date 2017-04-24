---
category: Concepts
title: Fault Injection

parent: Traffic Management
order: 40

bodyclass: docs
layout: docs
type: markdown
---

 
While Envoy sidecar/proxy provides a host of
[failure recovery mechanisms](./handling-failures.html) to services running
on Istio, it is still
imperative to test the end-to-end failure recovery capability of the
application as a whole. Misconfigured failure recovery policies (e.g.,
incompatible/restrictive timeouts across service calls) could result in
continued unavailability of critical services in the application, resulting
in poor user experience.

**Systematic fault injection:** Istio advocates a systematic approach to
testing the failure recovery of the application as a whole as opposed to a
chaotic model. Specifically, Istio implements fault injection at the Envoy
proxy/sidecar layer, instead of killing pods, delaying or corrupting
packets at TCP layer. Our rationale is that the failures observed by the
application layer are the same regardless of network level failures, and
that more meaningful failures can be injected at the application layer
(e.g., HTTP error codes) to exercise the resilience of an
application. Secondly, a systematic approach to fault injection allows
developers to quickly triage the root cause of failures as opposed to a
chaotic fault injection model. Our approach is similar to the
[Failure Injection Testing](http://techblog.netflix.com/2014/10/fit-failure-injection-testing.html)
approach that Netflix uses.

Operators can configure faults to be injected into requests that match a
specific criteria. Operators can further restrict the percentage of
requests that should be subjected to faults. Two types of faults can be
injected: delays and aborts. Delays are timing failures, mimicking
increased network latency, or an overloaded upstream service. Aborts are
crash failures that mimick failures in upstream services. Aborts usually
manifest in the form of HTTP error codes, or TCP connection failures.
