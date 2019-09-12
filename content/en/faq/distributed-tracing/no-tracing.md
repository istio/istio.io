---
title: Why are my requests not being traced?
weight: 30
---

Since Istio 1.0.3, the default sampling rate for tracing has been reduced to 1% when installing Istio using the Helm chart. This means that only 1 out of 100 trace
instances captured by Istio will be reported to the tracing backend. The sampling rate in the `istio-demo.yaml` is still set to 100%. See
[this section](/docs/tasks/observability/distributed-tracing/overview/#trace-sampling) for more information on how to set the sampling rate.

If you still do not see any trace data, please confirm that your ports conform to the Istio [port naming conventions](/faq/traffic-management/#naming-port-convention) and that the appropriate container port is exposed (via pod spec, for example) to enable
traffic capture by the sidecar proxy (Envoy).
