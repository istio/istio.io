---
title: Quota
description: 该模板用于表达占用配额的请求。
weight: 90
---

`quota` 模板表达了一个要进行配额检查的项目。

示例配置：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: quota
metadata:
  name: requestcount
  namespace: istio-system
spec:
  dimensions:
    source: source.labels["app"] | source.service | "unknown"
    sourceVersion: source.labels["version"] | "unknown"
    destination: destination.labels["app"] | destination.service | "unknown"
    destinationVersion: destination.labels["version"] | "unknown"
{{< /text >}}

## Template

该模板配置中的字段，可以是一个常量，也可以是一个[表达式](/zh/docs/reference//config/policy-and-telemetry/expression-language/)。要注意如果字段的数据类型不是 `istio.policy.v1beta1.Value`，那么表达式的类型必须和字段的[数据类型](/zh/docs/reference/config/policy-and-telemetry/expression-language/#类型检查)相匹配。

|字段|类型|说明|
|---|---|---|
|`demensions`|`map<string,` [`istio.policy.v1beta1.Value`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#Value)`>`||用于进行配额处理的唯一标识。|