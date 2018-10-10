---
title: statsd
description: 该适配器用于向 statsd 后端发送指标数据。
weight: 170
---

`statsd` 适配器让 istio 能够向 [statsd](https://github.com/etsy/statsd) 监控后端发送指标数据。该适配器支持 [`metric` 模板](/zh/docs/reference/config/policy-and-telemetry/templates/metric/)。

## 参数

配置 `statsd` 适配器。

|字段|类型|描述|
|---|---|---|
|`address`|`string`|statsd 服务器的地址，例如 `localhost:8125`|
|`prefix`|`string`|可选字段。指标前缀|
|`flushDuration`|[`google.protobuf.Duration`](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf)|这一字段控制向 statsd 服务器发送指标的时间间隔。由上一次指标发送开始，`flushBytes` 或者 `flushDuration` 都会触发下一次指标汇报动作|
|`flushBytes`|`int32`|待发送的最大 UDP 数据包尺寸；如果没有指定的话，会使用缺省值 512 字节。如果statsd 服务器是运行在同一个（内部）网络中，建议把这一数值修改为 1432 字节，以获得更好的效率|
|`samplingRate`|`float`|指标变化时对指标进行采样的几率。取值范围是 `[0, 1]`，如果没有指定，则取缺省值 1|
|`metrics`|`map<string,` [`MetricInfo`](#metricinfo) `>`|指标名称和结构的映射关系，名字不在这一列表中的指标不会被发送到 statsd|

## `MetricInfo`

描述在 statsd 中呈现该指标的方式。

|字段|类型|描述|
|---|---|---|
|`type`|[`MetricInfo.Type`](#metricinfo-type)||
|`nameTemplate`|`string`|来自指标数据中的标签的值会填充这一模板，生成的字符串会用作 statsd 中的指标名称。这样就能比较轻松的生成 statsd 指标名称，例如 `action_name-response_code`。模板使用 Go 模板语法。例如使用模板 `{{.apiMethod}}-{{.responseCode}}` 生成指标 `action_name-response_code`。该字段为空的情况下，就会使用 Istio 指标名称作为 statsd 的指标名称|

## MetricInfo.Type

指标类型。

|名称|描述|
|---|---|
|`UNKNOWN`||
|`COUNTER`||
|`GAUGE`||
|`DISTRIBUTION`||