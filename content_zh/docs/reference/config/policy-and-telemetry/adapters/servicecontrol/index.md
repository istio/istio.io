---
title: Service Control
description: 用于向 Google Service Control 发送日志和指标的适配器。
weight: 150
---

`servicecontroler` 适配器能够向 [Google Service Control](https://cloud.google.com/service-control) 发送日志和指标。

该适配器支持 [servicecontrolreport](/zh/docs/reference/config/policy-and-telemetry/templates/servicecontrolreport/)、[quota](/zh/docs/reference/config/policy-and-telemetry/templates/quota/) 以及 [apikey](/zh/docs/reference/config/policy-and-telemetry/templates/apikey/) 模板。

配置样例：

{{< text yaml >}}
apiVersion: "config.istio.io/v1alpha2"
kind: servicecontrol
metadata:
  name: testhandler
  namespace: istio-system
spec:
  runtime_config:
    check_cache_size: 200
    check_result_expiration: 60s
  credential_path: "/path/to/token.json"
  service_configs:
    - mesh_service_name: "echo.local.svc"
      google_service_name: "echo.endpoints.cloud.goog"
      quotas:
        - name: ratelimit.quota.istio-system
          google_quota_metric_name: read-requests
          expiration: 1m
{{< /text >}}

## 参数

|字段|类型|描述|
|---|---|---|
|`runtime_config`|[`RuntimeConfig`](#runtimeconfig)||
|`credential_path`|`string`|一个 JSON Token 文件，一般用 Kubernetes Secret 的形式加载到 Pod 里|
|`service_configs`|[`GcpServiceSetting`](#gcpservicesetting)||

## `RuntimeConfig`

适配器的运行时配置参数。

|字段|类型|描述|
|---|---|---|
|`checkCacheSize`|`int32`||
|`checkResultExpiration`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration)||

## `GcpServiceSetting`

GCP 服务的适配设置。

|字段|类型|描述|
|---|---|---|
|`mesh_service_name`|`string`|网格中的服务名称，用于匹配 `destination.service` 属性|
|`google_service_name`|`string`|GCP 服务的完全限定名|
|`quotas`|[`Quota[]`](#quota)|配额设置|

## `Quota`

|字段|类型|描述|
|---|---|---|
|`name`|`string`|Istio 配额名称|
|`google_quota_metric_name`|`string`|Google 配额指标名称|
|`expiration`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration)|配额 Token 的有效期|