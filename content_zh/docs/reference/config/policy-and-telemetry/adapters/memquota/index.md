---
title: Memory quota
description: 简单内存配额管理系统适配器。
weight: 100
---

内存配额 (`memquota`) 适配器用于支持 Istio 配额管理系统。虽然功能齐全，但该适配器不适合生产使用，仅适用于本地测试。这种限制的原因是此适配器只能用于运行一个 Mixer 的环境中，不支持 HA 配置。如果该 Mixer 单点故障，则所有重要的配额值都将丢失。

这个适配器支持 [`quota template`](/zh/docs/reference/config/policy-and-telemetry/templates/quota/)。

## 参数

内存配额适配器配置参数

| 字段 | 类型 | 描述 |
| --- | --- | --- |
|quotas|Params.Quota[]|quota 集合|
|minDeduplicationDuration|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration)|去重操作持续时间的最小秒数。|

## Override

定义配额的覆盖值。如果没有覆盖匹配特定配额请求，则使用配额的默认值。

| 字段 | 类型 | 描述 |
| --- | --- | --- |
|dimensions|`map<string, string>`|特定的配额维度被覆盖，需要检查是否配置的维度|
|maxAmount|int64|配额的上限数量|
|validDuration|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration)|`google.protobuf.Duration` 有效的配额持续时间分配。此值只对速率配额有效，否则此值必须为零。|

## Quota

定义配额限制和持续时间。

| 字段 | 类型 | 描述 |
| --- | --- | --- |
|name|string|配额名称|
|maxAmount|int64|配额的上限数量|
|validDuration|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration)|有效的配额持续时间分配。此值只对速率配额有效，否则此值必须为零。|
|overrides|[`Params.Override[]`](#override)|配额的覆盖值。首先定义的有效。|
