---
title: Analytics
description: Analytics 模板用于向 Apigee 发送运行时遥测数据。
weight: 20
---

`analytics` 模板是一个汇报给 Apigee 分析系统的请求。[Apigee Adapter for Istio](https://docs.apigee.com/api-platform/istio-adapter/concepts) 网站中包含了相关的用法、概念等内容。要获取更多相关信息或产品支持，请联系 [Apigee](https://apigee.com/about/support/portal)。

配置样例：

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: analytics
metadata:
  name: apigee
  namespace: istio-system
spec:
  api_key: request.api_key | request.headers["x-api-key"] | ""
  api_proxy: api.service | destination.service | ""
  response_status_code: response.code | 0
  client_ip: source.ip | ip("0.0.0.0")
  request_verb: request.method | ""
  request_uri: request.path | ""
  request_path: request.path | ""
  useragent: request.useragent | ""
  client_received_start_timestamp: request.time
  client_received_end_timestamp: request.time
  target_sent_start_timestamp: request.time
  target_sent_end_timestamp: request.time
  target_received_start_timestamp: response.time
  target_received_end_timestamp: response.time
  client_sent_start_timestamp: response.time
  client_sent_end_timestamp: response.time
  api_claims: # from jwt
    json_claims: request.auth.raw_claims | ""
{{< /text >}}

## 模板

该模板向 Apigee 分析引擎提供 Istio 的遥测数据。

|字段|类型|说明|
|---|---|---|
|`apiProxy`|`string`|Proxy 的名称，通常是 Istio API 或者服务名称|
|`responseStatusCode`|`int64`|HTTP 响应码|
|`clientIp`|[`string`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#IPAddress)|客户端 IP 地址|
|`requestVerb`|`string`|HTTP 请求方法|
|`requestUri`|`string`|HTTP 请求 URI|
|`requestPath`|`string`|HTTP 请求路径|
|`useragent`|`string`|HTTP user agent Header|
|`clientReceiveStartTimestampe`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)|api_proxy 开始接收请求的时间戳|
|`clientReceivedEndTimestamp`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)|api_proxy 完成接收请求的时间戳|
|`clientSentStartTimestamp`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)|api_proxy 开始向目标发送请求的时间戳|
|`clientSentEndTimestamp`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)|api_proxy 完成向目标发送请求的时间戳|
|`targetSentStartTimestamp`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)|api_proxy 开始请求目标的时间戳|
|`targetSentEndTimestamp`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)|api_proxy 完成目标请求的时间戳|
|`targetReceivedStartTimestamp`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)|api_proxy 开始从目标接收响应的时间戳|
|`targetReceivedEndTimestamp`|[`istio.policy.v1beta1.TimeStamp`](/docs/reference/config/policy-and-telemetry/istio.policy.v1beta1/#TimeStamp)|api_proxy 完成从目标接收响应的时间戳|
|`apiClaims`|`map<string, string>`|JWT 声明，用于在需要的情况下进行请求的认证。使用 `json_claims` 来传递所有声明|
|`apiKey`|`string`|API Key，用于在需要的情况下进行请求的认证|