---
title: Circonus
description: 适用于 circonus.com 的监控解决方案。
weight: 70
---

该 `circonus` 适配器使 Istio metric 数据传送到 [Circonus](https://www.circonus.com) 的监控后端。

此适配器支持[度量标准模板](/zh/docs/reference/config/policy-and-telemetry/templates/metric/)。

## PARAMS

Circonus 适配器的配置格式。

| 属性 | 类型 | 描述 |
| --- | --- | --- |
| `submissionUrl` | `string` | Circonus SubmissionURL 到 HTTPTrap 检查 |
| `submissionInterval` | [google.protobuf.Duration](https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.Duration) |  |
| `metrics` | [Params.MetricInfo[]](#Params-MetricInfo) |  |

## Params.MetricInfo

描述如何表示度量标准

| 属性 | 类型 | 描述 |
| --- | --- | --- |
| `name` | `string` | 名称 |
| `type` | [Params.MetricInfo.Type](#Params-MetricInfo-Type) |  |

## Params.MetricInfo.Type

指标的类型。

| 名称 | 描述 |
| --- | --- |
| `UNKNOWN` |  |
| `COUNTER` |  |
| `GAUGE` |  |
| `DISTRIBUTION` |  |