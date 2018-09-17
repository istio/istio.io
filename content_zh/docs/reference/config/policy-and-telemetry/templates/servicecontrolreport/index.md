---
title: Service Control Report
description: 用于 Google Service Control 适配器的模板。
weight: 110
---

`servicecontrolreport` 模板需配合 [Google Servie Control](/docs/reference/config/policy-and-telemetry/adapters/servicecontrol/) 适配器使用。

配置样例：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: servicecontrolreport
metadata:
  name: report
  namespace: istio-system
spec:
  api_version : api.version | ""
  api_operation : api.operation | ""
  api_protocol : api.protocol | ""
  api_service : api.service | ""
  api_key : api.key | ""
  request_time : request.time
  request_method : request.method
  request_path : request.path
  request_bytes: request.size
  response_time : response.time
  response_code : response.code | 520
  response_bytes : response.size | 0
  response_latency : response.duration | "0ms"
{{< /text >}}

## 模板

[Google Servie Control](/docs/reference/config/policy-and-telemetry/adapters/servicecontrol/) 适配器会根据这个模板描述的数据点，为每个请求生成指标和日志。

|字段|类型|描述|
|---|---|---|
|`apiVersion`|`string`||
|`apiOperation`|`string`||
|`apiProtocol`|`string`||
|`apiService`|`string`||
|`apiKey`|`string`||
|`requestTime`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)||
|`requestMethod`|`string`||
|`requestPath`|`string`||
|`requestBytes`|`int64`||
|`responseTime`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)||
|`responseCode`|`int64`||
|`responseByte`|`int64`||
|`responseLatency`|[`istio.policy.v1beta1.Duration`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#Duration)||