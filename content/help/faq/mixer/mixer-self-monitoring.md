---
title: Does Mixer provide any self-monitoring?
weight: 30
---

Mixer exposes a monitoring endpoint (default port: `10514`). There are a few
useful paths to investigate Mixer performance and audit
function:

- `/metrics` provides Prometheus metrics on the Mixer process as well as gRPC
  metrics related to API calls and metrics on adapter dispatch.
- `/debug/pprof` provides an endpoint for profiling data in [pprof
  format](https://golang.org/pkg/net/http/pprof/).
- `/debug/vars` provides an endpoint exposing server metrics in JSON format.

Mixer logs can be accessed via a `kubectl logs` command, as follows:

- For the `istio-policy` service:

{{< text bash >}}
$ kubectl -n istio-system logs -l app=policy -c mixer
{{< /text >}}

- For the `istio-telemetry` service:

{{< text bash >}}
$ kubectl -n istio-system logs -l app=telemetry -c mixer
{{< /text >}}

Mixer trace generation is controlled by command-line flags: `trace_zipkin_url`, `trace_jaeger_url`, and `trace_log_spans`. If
any of those flag values are set, trace data will be written directly to those locations. If no tracing options are provided, Mixer
will not generate any application-level trace information.
