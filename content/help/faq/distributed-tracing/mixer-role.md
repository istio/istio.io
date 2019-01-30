---
title: What role does Mixer play in the Istio tracing story?
weight: 90
---

By default, Mixer participates in tracing by generating its own spans for requests that are already selected for tracing by Envoy proxies. This enables operators to observe the participation of the mixer-based policy enforcement mechanisms within the mesh. If the `istio-policy` configuration is disabled mesh-wide, Mixer does not participate in tracing in this way.

Mixer, operating as the `istio-telemetry` service, can also be used to generate trace spans for data plane traffic. Mixer’s Stackdriver adapter is an example of an adapter that supports this capability.

For Mixer-generated traces, Istio still relies on Envoy to generate trace context and to forward it to the applications that must propagate the context. Instead of Envoy itself sending trace information directly to a tracing backend, Mixer distills client and server spans from the regular Envoy reporting for each request based on operator-supplied configuration. In this way, operators can precisely control when and how trace data is generated and perhaps remove certain services entirely from a trace or provide more detailed information for certain namespaces.
