---
title: Metric
description: 该模板用于表达一个运行时产生的监控指标数据。
weight: 80
---

`metric` 模板用来描述运行时指标数据，发送给监控后端进行处理。

配置样例：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: metric
metadata:
  name: requestsize
  namespace: istio-system
spec:
  value: request.size | 0
  dimensions:
    source_service: source.service | "unknown"
    source_version: source.labels["version"] | "unknown"
    destination_service: destination.service | "unknown"
    destination_version: destination.labels["version"] | "unknown"
    response_code: response.code | 200
  monitored_resource_type: '"UNSPECIFIED"'
{{< /text >}}

## Template

该模板配置中的字段，可以是一个常量，也可以是一个[表达式](/zh/docs/reference//config/policy-and-telemetry/expression-language/)。要注意如果字段的数据类型不是 `istio.policy.v1beta1.Value`，那么表达式的类型必须和字段的[数据类型](/zh/docs/reference/config/policy-and-telemetry/expression-language/#类型检查)相匹配。

|字段|类型|说明|
|---|---|---|
|`value`|[`istio.policy.v1beta1.Value`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#Value)|用于上报的值|
|`dimensions`|`map<string,` [`istio.policy.v1beta1.Value`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#Value)`>`|上报指标的唯一标识符|
|`monitoredResourceType`|`string`|可选字段。这是一个表达式，用来生成将要上报的指标的监控资源的类型。如果目标后端支持这一资源，则接受这一字段并对相应的资源进行处理。否则这一字段会被适配器丢弃|
|`monitoredResourceDimensions`|`map<string,` [`istio.policy.v1beta1.Value`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#Value)`>`|可选字段。一组表达式，用于生成该日志对应资源的 Dimension。如果日志后端支持针对资源的监控，这些字段就会用于对该资源的后续处理；否则适配器会丢弃该字段。|