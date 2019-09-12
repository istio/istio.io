---
title: SignalFx
description: 将指标发送到 SignalFx 的适配器。
weight: 70
---

`signalfx` 适配器收集 Istio 指标和 tracespan 并将它们发送到 [SignalFx](https://signalfx.com)。

此适配器支持[指标模板](/zh/docs/reference/config/policy-and-telemetry/templates/metric/)和 [tracespan 模板](/zh/docs/reference/config/policy-and-telemetry/templates/tracespan/)。

在发送 tracespan 时，该适配器可以对接收到的 tracespan 进行一些配置来生成发送内容。以下是一个适用的 tracespan 示例：

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: tracespan
metadata:
  name: signalfx
spec:
  traceId: request.headers["x-b3-traceid"] | ""
  spanId: request.headers["x-b3-spanid"] | ""
  parentSpanId: request.headers["x-b3-parentspanid"] | ""
  # 如果路径包含查询参数，它们将被拆分并放入标记中，以便发送到 SignalFx 的范围名称仅包含路径本身。
  spanName: request.path | "/"
  startTime: request.time
  endTime: response.time
  # 如果此值 >=500 ，则 span 将获得 `error` 标记
  httpStatusCode: response.code | 0
  clientSpan: context.reporter.kind == "outbound"
  # 下面的注释标签都是可选项。没有注释的的部分会不加修改地传递给 SignalFx。有注释的标签会使用特定方式进行解释。
  spanTags:
    # 这用于分辨当前 span 是属于客户端还是服务器端。
    context.reporter.local: context.reporter.local
    # 这将放入 remoteEndpoint.ipv4 字段
    destination.ip: destination.ip | ip("0.0.0.0")
    # 用 `destination.labels.<key>: <value>` 的形式将标签进行扁平化处理。
    destination.labels: destination.labels
    #  这将放入 remoteEndpoint.name 字段
    destination.name: destination.name | "unknown"
    destination.namespace: destination.namespace | "unknown"
    request.host: request.host | ""
    request.method: request.method | ""
    request.path: request.path | ""
    request.size: request.size | 0
    request.useragent: request.useragent | ""
    response.size: response.size | 0
    # 这将放入 localEndpoint.name 字段
    source.name: source.name | "unknown"
    # 这将放入 localEndpoint.ipv4 字段
    source.ip: source.ip | ip("0.0.0.0")
    source.namespace: source.namespace | "unknown"
    # 用 `source.labels.<key>: <value>` 的形式将标签进行扁平化处理。
    source.labels: source.labels
    source.version: source.labels["version"] | "unknown"

{{< /text >}}

## PARAMS

`signalfx` 适配器的配置格式。

| 属性 | 类型 | 描述 |
| --- | --- | --- |
| `metrics` | [Params.MetricConfig[]](#params-metricconfig) | 必选项。要发送到 SignalFx 的指标标准集。如果将 Istio 指标标准配置为发送到此适配器，则此处必须具有相应的描述。|
| `ingestUrl` | `string` | 可选项。要使用的 SignalFx 接受服务器的 URL。如果未指定，将默认为全局摄取服务器。|
| `accessToken` | `string` | 必选项。应接收指标的 SignalFx 组织的访问令牌。|
| `datapointInterval` | [google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) | 可选项。指定将指标发送到 SignalFx 的频率。报告给此适配器的指标标准将作为时间序列进行收集和报告。这将四舍五入到最接近的秒，小于一秒的舍入值无效。如果未指定，则默认为10秒。|
| `enableMetrics` | `bool` | 可选项。如果设置为 false，则不会发送指标标准（但将发送 trace span ，除非另行禁用）。|
| `enableTracing` | `bool` | 可选项。如果设置为 false，则不会发送 tracespan （除非另行禁用，否则将发送指标标准）。|
| `tracingBufferSize` | `uint32` | 可选项。适配器在丢弃之前将缓冲的 tracespan 数。默认为 1000 个 span ，但如果必选项，可以配置更高。如果删除 span，将记录错误消息。|
| `tracingSampleProbability` | `double` | 可选项。如果父 span 尚未被采样的情况下，当前 span 的采样概率为（[0.0,1.0]）。如果它们的父 span 被采样，子 span 则一定会被采样。如果没有赋值，则默认为发送所有的 span。|

## Params.MetricConfig

描述应以何种形式将哪些指标发送到 SignalFx。

| 属性 | 类型 | 描述 |
| --- | --- | --- |
| `name` | `string` | 必选项。发送到适配器的指标标准的名称。在 Kubernetes 中，其形式为 ".metric." 其中双引号中 “ ” 既有指标资源的名称字段， 也有指标资源的命名空间。|
| `type` | [Params.MetricConfig.Type](#params-metricconfig-type) | 指标标准类型  |

## Params.MetricConfig.Type

描述这是什么类型的指标。

| 名称 | 描述 |
| --- | --- |
| `NONE` | NONE 是默认值  |
| `COUNTER` | 具有相同维度集的值将作为连续递增值一起添加。|
| `HISTOGRAM` | 直方图分布。这将导致为每个唯一维度集发出多个指标。 |