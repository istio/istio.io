---
title: Trace Span
description: 该模板用于表达分布式跟踪数据中的一个 Span。
weight: 120
---
`tracespan` 模板用在分布式跟踪中，用于表达一个单独的 Span。

配置样例：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: tracespan
metadata:
  name: default
  namespace: istio-system
spec:
  traceId: request.headers["x-b3-traceid"]
  spanId: request.headers["x-b3-spanid"] | ""
  parentSpanId: request.headers["x-b3-parentspanid"] | ""
  spanName: request.path | "/"
  startTime: request.time
  endTime: response.time
  clientSpan: (context.reporter.local | true) == false
  rewriteClientSpanId: false
  spanTags:
    http.method: request.method | ""
    http.status_code: response.code | 200
    http.url: request.path | ""
    request.size: request.size | 0
    response.size: response.size | 0
    source.ip: source.ip | ip("0.0.0.0")
    source.service: source.service | ""
    source.user: source.user | ""
    source.version: source.labels["version"] | ""
{{< /text >}}

请参照[分布式跟踪](/zh/docs/tasks/telemetry/distributed-tracing/)任务来了解更多相关信息。

## 模板

该模板配置中的字段，可以是一个常量，也可以是一个[表达式](/zh/docs/reference//config/policy-and-telemetry/expression-language/)。要注意如果字段的数据类型不是 `istio.policy.v1beta1.Value`，那么表达式的类型必须和字段的[数据类型](/zh/docs/reference/config/policy-and-telemetry/expression-language/#类型检查)相匹配。

|字段|类型|说明|
|---|---|---|
|`traceId`|`string`|必要字段。Trace ID 是一次跟踪的唯一标识符。一次跟踪中的所有 Span 都会使用同一个 Trace ID|
|`spanId`|`string`|可选字段。Span ID 是跟踪中一个 Span 的唯一标识符，在创建 Span 时生成|
|`parentSpanId`|`string`|可选字段。该 Span 的上级 Span ID。如果这是一个根级 Span，那么这个字段必须为空|
|`spanName`|`string`|必要字段。对于该 Span 的操作内容的描述。例如可以是一个方法的完全限定名，或者是方法所在的文件名和行号。建议的最佳实践是，一个应用中，在同一个调用点使用同样的名称，以便于在不同跟踪中识别出正确的 Span|
|`startTime`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)|必要字段：Span 的开始时间|
|`endTime`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)|必要字段：Span 的结束时间|
|`spanTags`|`map<string,` [`istio.policy.v1beta1.Value`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#Value)`>`|可选字段。Span 标签是一组键值对，用于表达 Span 的元数据。其中的值部分可以使用表达式动态生成|
|`httpStatusCode`|`int64`|可选字段。HTTP 状态码，代表 Span 的状态。如果没有值或者值为 0，可以假设该 Span 成功完成|
|`clientSpan`|`bool`|可选字段。表示 Span 的类型。如果值为 `True`，则代表是一个客户端 Span。因为 Mixer 不支持枚举值，因此该字段目前临时使用布尔型|
|`rewriteClientSpanId`|`bool`|可选字段。用于确定是否为 Zipkin 的共享 Span 模型创建一个新的客户端 Span。有的跟踪系统，例如 Stackdriver 会把一个 RPC Span 分为客户端和服务器端。为了解决这个不兼容问题，可以把客户端 Span 和服务端 Span 的上级 Span 的 ID 重写为新生成的 ID|