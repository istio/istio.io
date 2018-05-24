---
title: Fault Injection
description: Introduces the idea of systematic fault injection that can be used to uncover conflicting failure recovery policies across services.

weight: 40

toc: false
---

While Envoy sidecar/proxy provides a host of
[failure recovery mechanisms](./handling-failures.html) to services running
on Istio, it is still
imperative to test the end-to-end failure recovery capability of the
application as a whole. Misconfigured failure recovery policies (e.g.,
incompatible/restrictive timeouts across service calls) could result in
continued unavailability of critical services in the application, resulting
in poor user experience.

Istio enables protocol-specific fault injection into the network, instead
of killing pods, delaying or corrupting packets at TCP layer. Our rationale
is that the failures observed by the application layer are the same
regardless of network level failures, and that more meaningful failures can
be injected at the application layer (e.g., HTTP error codes) to exercise
the resilience of an application.

Operators can configure faults to be injected into requests that match
specific criteria. Operators can further restrict the percentage of
requests that should be subjected to faults. Two types of faults can be
injected: delays and aborts. Delays are timing failures, mimicking
increased network latency, or an overloaded upstream service. Aborts are
crash failures that mimic failures in upstream services. Aborts usually
manifest in the form of HTTP error codes, or TCP connection failures.

Refer to [Istio's traffic management rules](./rules-configuration.html) for more details.
