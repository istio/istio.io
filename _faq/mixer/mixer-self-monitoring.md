---
title: Does Mixer provide any self-monitoring?
weight: 30
---
{% include home.html %}

Mixer exposes a monitoring endpoint (default port: `9093`). There are a few
useful paths to investigate Mixer performance and audit
function:

- `/metrics` provides Prometheus metrics on the Mixer process as well as gRPC
  metrics related to API calls and metrics on adapter dispatch.
- `/debug/pprof` provides an endpoint for profiling data in [pprof
  format](https://golang.org/pkg/net/http/pprof/).
- `/debug/vars` provides an endpoint exposing server metrics in JSON format.

Mixer logs can be accessed via a `kubectl logs` command, as follows:

```bash
kubectl -n istio-system logs $(kubectl -n istio-system get pods -listio=mixer -o jsonpath='{.items[0].metadata.name}') mixer
```
Mixer trace generation is controlled by the command-line flag `traceOutput`. If
the flag value is set to `STDOUT` or `STDERR` trace data will be written
directly to those locations. If a URL is provided, Mixer will post
Zipkin-formatted data to that endpoint (example:
`http://zipkin:9411/api/v1/spans`).

In the 0.2 release, Mixer only supports Zipkin tracing.
