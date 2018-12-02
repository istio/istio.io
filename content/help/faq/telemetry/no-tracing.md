---
title: Requests are not being traced
weight: 20
---

Since Istio 1.0.3, the default sampling rate for tracing has been reduced to 1% when installing Istio using the helm chart. This means that only 1 out of 100 trace instances captured by Istio will be reported to the tracing backend. The sampling rate in the `istio-demo.yaml` is still set to 100%. See [this section](/docs/tasks/telemetry/distributed-tracing/#trace-sampling) for more information on how to set the sampling rate.

