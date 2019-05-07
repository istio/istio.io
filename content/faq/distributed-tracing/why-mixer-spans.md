---
title: Why do I see `istio-mixer` spans in some of my distributed traces?
weight: 100
---

Mixer generates application-level traces for requests that reach Mixer with tracing headers. Mixer generates spans, labeled `istio-mixer` for any critical work that it does, including dispatch to individual adapters.

Envoy caches calls to Mixer on the data path. As a result, calls out to Mixer made via the `istio-policy` service only happen for certain requests, for example: cache-expiry or different request characteristics. For this reason, you only see Mixer participate in *some* of your traces.

To turn off the application-level trace spans for Mixer itself, you must edit the deployment configuration for `istio-policy` and remove the `--trace_zipkin_url` command-line parameter.