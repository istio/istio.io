---
title: Apigee
description: Apigee 的分布式策略检查以及分析适配器。
weight: 10
---

Apigee Mixer 适配器提供了 Apigee 的分布式认证以及配额策略检查功能，同时还支持接收 Istio 遥测数据用于进行分析和报告。可以阅读 [Apigee 的 Istio 适配器](https://docs.apigee.com/api-platform/istio-adapter/concepts)文档来了解这一适配器的完整概念和用途。还可以联系 [Apigee 支持](https://apigee.com/about/support/portal) 获取更多信息。

该适配器支持 [authorization](/zh/docs/reference/config/policy-and-telemetry/templates/authorization/) 以及 Apigee 的 [analytics](/zh/docs/reference/config/policy-and-telemetry/templates/analytics/) 模板。

配置样例：

{{< text yaml >}}
apiVersion: config.istio.io/v1alpha2
kind: apigee
metadata:
  name: apigee-handler
  namespace: istio-system
spec:
  apigee_base: https://istioservices.apigee.net/edgemicro
  customer_base: https://myorg-test.apigee.net/istio-auth
  org_name: myorg
  env_name: test
  key: 5f1132b7ff037fa187463c324d029ca26de28b7279df0ea161
  secret: fa147e8afc35219b7e1db688c609196923f663b5e835975
  temp_dir: "/tmp/apigee-istio"
  client_timeout: 30s
  products:
    refresh_rate: 2m
  analytics:
    legacy_endpoint: false
    file_limit: 1024
  api_key_claim:
{{< /text >}}

## 参数

|字段|类型|描述|
|---|---|---|
|`apigee_base`|`string`|必要字段。Apigee 的共享代理 URI|
|`customer_base`|`string`|必要字段。组织特定的 Apigee 共享代理 URI|
|`org_name`|`string`|必要字段。Apigee 上的组织名称|
|`env_name`|`string`|必要字段。Apigee 上的环境名称|
|`key`|`string`|必要字段。用于在 Apigee 代理端点上进行认证，在实例化时候生成|
|`secret`|`string`|必要字段。用于在 Apigee 代理端点上进行认证，在实例化时候生成|
|`temp_dir`|`string`|可选字段。给适配器指定临时文件存储位置。缺省值为 `/tmp/apigee-istio`|
|`client_timeout`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration)|可选字段。适配器请求 Apigee 服务器的超时时间。缺省值为 `30s`|
|`api_key_claim`|`string`|可选字段。JWT 声明的名称，用于查找 `api_key`。缺省值 `none`|
|`products`|[`product_options`](#product-options)|Product 参数|
|`analytics`|[`analytics_options`](#analytics-options)|Analytics 参数|

## analytics_options

|字段|类型|描述|
|---|---|---|
|`legacy_endpoint`|`bool`|可选字段。如果为真就是用旧式的直接通信分析协议，而不进行缓冲。使用 OPDK 的场景下必须为真。缺省值为 `false`|
|`file_limit`|`int64`|可选字段。在删除最旧文件之前，最多可以缓冲的分析文件的数量。缺省值为 `1024`|

## product_options

|字段|类型|描述|
|---|---|---|
|`refresh_rate`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration)|可选字段。从 Apigee 刷新 Product 列表的频率。缺省值为 `2m`|
