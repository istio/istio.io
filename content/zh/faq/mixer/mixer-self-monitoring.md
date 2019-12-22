---
title: Mixer 是否提供内部监控？
weight: 30
---

Mixer 提供了监控端点（默认端口：`15014`）。Mixer 提供的性能和审计功能的服务路径如下：

- `/metrics` 提供有关 Mixer 处理的 Prometheus 指标、API 调用相关的 gRPC 指标和 adapter 调度指标。
- `/debug/pprof` 提供了性能剖析相关的数据，格式为 [pprof](https://golang.org/pkg/net/http/pprof/)。
- `/debug/vars` 提供了服务器指标，数据为 JSON 格式。

可通过 `kubectl logs` 命令访问 Mixer 的日志，如下所示：

- 关于 `istio-policy` 服务：

{{< text bash >}}
$ kubectl -n istio-system logs -l app=policy -c mixer
{{< /text >}}

- 关于 `istio-telemetry` 服务：

{{< text bash >}}
$ kubectl -n istio-system logs -l app=telemetry -c mixer
{{< /text >}}

Mixer 追踪功能由以下命令行参数控制：`trace_zipkin_url`、`trace_jaeger_url` 和 `trace_log_spans`。如果设置了以上参数中的任何一个，则追踪数据将上报至配置的相关服务地址。如果未提供追踪相关设置参数，则 Mixer 将不会产生应用程序级别的追踪信息。
