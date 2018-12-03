---
title: Why can't Istio propagate headers instead of the application?
weight: 10
---

Although an Istio sidecar will process both inbound and outbound requests for an associated application instance, it has no implicit way of correlating the outbound requests to the inbound request that caused them. The only way this correlation can be achieved is if the application [propagates relevant information](/docs/tasks/telemetry/distributed-tracing/#understanding-what-happened) (i.e. headers) from the inbound request to the outbound requests.

