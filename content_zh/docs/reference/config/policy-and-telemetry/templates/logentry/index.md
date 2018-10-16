---
title: Log Entry
description: 该模板用于表达一条运行时日志项。
weight: 70
---

`logentry` 模板用于表示日志中的一条记录。

配置样例：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: logentry
metadata:
  name: accesslog
  namespace: istio-system
spec:
  severity: '"Default"'
  timestamp: request.time
  variables:
    sourceIp: source.ip | ip("0.0.0.0")
    destinationIp: destination.ip | ip("0.0.0.0")
    sourceUser: source.user | ""
    method: request.method | ""
    url: request.path | ""
    protocol: request.scheme | "http"
    responseCode: response.code | 0
    responseSize: response.size | 0
    requestSize: request.size | 0
    latency: response.duration | "0ms"
  monitored_resource_type: '"UNSPECIFIED"'
{{< /text >}}

## Template

该模板配置中的字段，可以是一个常量，也可以是一个[表达式](/zh/docs/reference//config/policy-and-telemetry/expression-language/)。要注意如果字段的数据类型不是 `istio.policy.v1beta1.Value`，那么表达式的类型必须和字段的[数据类型](/zh/docs/reference/config/policy-and-telemetry/expression-language/#类型检查)相匹配。

|字段|类型|说明|
|---|---|---|
|`variables`|`map<string,` [`istio.policy.v1beta1.Value`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#Value)`>`|发送给日志条目的变量。|
|`timestamp`|[`istio.policy.v1beta1.Value`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1#TimeStamp)|日志条目的时间|
|`severity`|`string`|日志条目的紧要程度|
|`monitoredResourceType`|`string`|可选字段。一个指出该日志条目相关资源的表达式。如果日志后端支持针对资源的监控，这些字段就会用于对该资源的后续处理；否则适配器会丢弃该字段。|
|`monitoredResourceDimensions`|`map<string,` [`istio.policy.v1beta1.Value`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#Value)`>`|可选字段。一组表达式，用于生成该日志对应资源的 Dimension。如果日志后端支持针对资源的监控，这些字段就会用于对该资源的后续处理；否则适配器会丢弃该字段。|