---
title: SignalFx
description: 该 `signalfx` 适配器收集 Istio 指标和跟踪 span 并将它们发送到 [SignalFx](https://signalfx.com) 。
weight: 70
---

该 `signalfx` 适配器收集 Istio 指标和跟踪 span 并将它们发送到 [SignalFx](https://signalfx.com) 。

此适配器支持[度量模板](/zh/docs/reference/config/policy-and-telemetry/templates/metric/)和[跟踪模板](/zh/docs/reference/config/policy-and-telemetry/templates/tracespan/) 。

如果发送跟踪 span，则此适配器可以使用配置文件,为发送到此适配器的 tracespan 格式的某些规范。以下是一个适用的跟踪示例：

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
  # 如果此值 >=500，则 span 将获得 `error` 标记
  httpStatusCode: response.code | 0
  clientSpan: context.reporter.kind == "outbound"
  # 下面没有注释的 Span 标签很有用，可以不加修改地传递给 SignalFx。具有注释的标签做了详细解释，但是他们都是可选的。
  spanTags:
    # 这用于确定 span 是否属于请求的客户端或服务器端。
    context.reporter.local: context.reporter.local
    # 这将放入 remoteEndpoint.ipv4 字段
    destination.ip: destination.ip | ip("0.0.0.0")
    # 这会变得扁平化为表单的各个标签
    # 'destination.labels.<key>: <value>'.
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
    # 这会变得扁平化为表单的各个标签
    # 'source.labels.<key>: <value>'.
    source.labels: source.labels
    source.version: source.labels["version"] | "unknown"

{{< /text >}}

## PARAMS

`signalfx` 适配器的配置格式 。

| 属性 | 类型 | 描述 |
| --- | --- | --- |
| `metrics` | [Params.MetricConfig[]](#Params-MetricConfig) | 需要。要发送到 SignalFx 的度量标准集。如果将 Istio 度量标准配置为发送到此适配器，则此处必须具有相应的描述。|
| `ingestUrl` | `string` | 可选的。要使用的 SignalFx 摄取服务器的 URL。如果未指定，将默认为全局摄取服务器。|
| `accessToken` | `string` | 必选项。应接收指标的 SignalFx 组织的访问令牌。|
| `datapointInterval` | [google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#duration) | 可选的。指定将指标发送到 SignalFx 的频率。报告给此适配器的度量标准将作为时间序列进行收集和报告。这将四舍五入到最接近的秒，小于一秒的舍入值无效。如果未指定，则默认为10秒。|
| `enableMetrics` | `bool` | 可选的。如果设置为 false，则不会发送度量标准（但将发送跟踪 span ，除非另行禁用）。|
| `enableTracing` | `bool` | 可选的。如果设置为 false，则不会发送跟踪 span （除非另行禁用，否则将发送度量标准）。|
| `tracingBufferSize` | `uint32` | 可选的。适配器在丢弃之前将缓冲的跟踪 span 数。默认为 1000 个 span ，但如果需要，可以配置更高。如果删除 span，将记录错误消息。|
| `tracingSampleProbability` | `double` | 可选的。如果父节点尚未被采样，则给定 span 的均匀概率（[0.0,1.0]）。如果他们的父节点是，子节点 span 将始终被采样。如果未提供，则默认为发送所有 span。|

## Params.MetricConfig

描述应以何种形式将哪些指标发送到 SignalFx。

| 属性 | 类型 | 描述 |
| --- | --- | --- |
| `name` | `string` | 需要。发送到适配器的度量标准的名称。在 Kubernetes 中，这是 “.metric” 哪里 “ ” 是度量资源的名称字段，“ ” 是度量资源的命名空间。|
| `type` | [Params.MetricConfig.Type](#Params-MetricConfig-Type) | 度量标准类型  |

## Params.MetricConfig.Type

描述这是什么类型的指标。

| 名称 | 描述 |
| --- | --- |
| `NONE` | 无是默认值且无效  |
| `COUNTER` | 具有相同维度集的值将作为连续递增值一起添加。|
| `HISTOGRAM` | 直方图分布。这将导致为每个唯一维度集发出多个指标。 |