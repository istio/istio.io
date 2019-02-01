---
title: Why can't Istio propagate headers instead of the application?
weight: 20
---

Although an Istio sidecar will process both inbound and outbound requests for an associated application instance, it has no implicit way of correlating
the outbound requests to the inbound request that caused them. The only way this correlation can be achieved is if the application
propagates relevant information (i.e. headers) from the inbound request to the outbound requests. Header propagation may be accomplished through client
libraries or manually. Further discussion is provided in [What is required for distributed tracing with Istio?](/help/faq/distributed-tracing/#how-to-support-tracing).
