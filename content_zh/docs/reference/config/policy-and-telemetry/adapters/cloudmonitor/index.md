---
title: CloudMonitor
description: CloudMonitor 适配器使 Istio 可以向 [AliCloud CloudMonitor](https://cloudmonitor.console.aliyun.com/) 提供指标。
weight: 70
---

CloudMonitor 适配器使 Istio 可以向 [AliCloud CloudMonitor](https://cloudmonitor.console.aliyun.com/) 提供指标。

要使用此适配器将指标推送到 CloudMonitor，您必须使用 AliCloud SDK 以支持 AliCloud。（参见 [AliCloud 官方 SDK](https://github.com/aliyun/alibaba-cloud-sdk-go) ）。

处理程序配置必须包含与实例配置相同的指标。实例和处理程序配置中指定的度量标准将发送到 CloudMonitor。

此适配器支持[度量标准模板](/zh/docs/reference/config/policy-and-telemetry/templates/metric/)。

## PARAMS

`cloudmonitor` 适配器的配置。

| 属性 | 类型 | 描述 |
| --- | --- | --- |
| `regiondId` | `string` | AliCloud Cloud Monitor 服务实例所在的一个区域的 ID |
| `accessKeyId` | `string` | AliCloud 访问帐户的访问密钥 ID |
| `accessKeySecret` | `string` | AliCloud 访问帐户的访问密钥秘密 |
| `groupId` | `int64` | AliCloud Cloud Monitor 服务实例中的应用程序组的 ID |
| `metricInfo` | `map<string,` [Params.MetricList](#Params-MetricList)`>` | Istio 度量标准名称到 CloudMonitor 度量标准信息的映射。 |

## Params.MetricList

CloudMonitor 指标格式。 [CloudMonitor 自定义度量请求](https://github.com/aliyun/alibaba-cloud-sdk-go/blob/master/services/cms/put_custom_metric.go)