---
title: CloudMonitor
description: CloudMonitor 适配器使 Istio 可以向 AliCloud CloudMonitor 提供指标。
weight: 70
---

`cloudmonitor` 适配器让 Istio 可以向 [AliCloud CloudMonitor](https://cloudmonitor.console.aliyun.com/) 提供指标数据。

The handler configuration must contain the same metrics as the instance configuration. The metrics specified in both instance and handler configurations will be sent to CloudMonitor.

This adapter supports the metric template.

要使用此适配器将指标推送到 CloudMonitor，必须提供 AliCloud 凭证以便使用 AliCloud SDK。（参见 [AliCloud 官方 SDK](https://github.com/aliyun/alibaba-cloud-sdk-go) ）。

Handler 配置必须和 Instance 配置包含一致的指标，满足这一要求的指标才会发送给 CloudMonitor。

此适配器支持 [Metric 模板](/zh/docs/reference/config/policy-and-telemetry/templates/metric/)。

## PARAMS

`cloudmonitor` 适配器的配置。

| 属性 | 类型 | 描述 |
| --- | --- | --- |
| `regiondId` | `string` | AliCloud Cloud Monitor 服务实例所在的一个区域的 ID |
| `accessKeyId` | `string` | AliCloud 访问帐户的访问密钥 ID |
| `accessKeySecret` | `string` | AliCloud 访问帐户的访问密钥秘密 |
| `groupId` | `int64` | AliCloud Cloud Monitor 服务实例中的应用程序组的 ID |
| `metricInfo` | `map<string,` [Params.MetricList](#params-metriclist)`>` | Istio 指标名称到 CloudMonitor 指标信息的映射。 |

## Params.MetricList

CloudMonitor 指标格式。参考：[CloudMonitor 自定义指标](https://github.com/aliyun/alibaba-cloud-sdk-go/blob/master/services/cms/put_custom_metric.go)