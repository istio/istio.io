---
title: API Key
description: 该模板用于表达一个 API Key。
weight: 10
---

`apikey` 模板中包含一个用于认证检查的 API Key。

配置样例：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: apikey
metadata:
  name: validate-apikey
  namespace: istio-system
spec:
  api: api.service | ""
  api_version: api.version | ""
  api_operation: api.operation | ""
  api_key: api.key | ""
  timestamp: request.time
{{< /text >}}

## 模板

|字段|类型|描述|
|---|---|---|
|`api`|`string`|被调用的 API（api.service）|
|`apiVersion`|`string`|API 版本（api.version）|
|`apiOperation`|`string`|被调用的 API 操作|
|`apiKey`|`string`|API 调用中使用的 API Key|
|`timestamp`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)|API 调用的时间戳|