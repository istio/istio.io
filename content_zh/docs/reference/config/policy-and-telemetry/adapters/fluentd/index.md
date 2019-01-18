---
title: Fluentd
description: 用于将日志发送给 Fluentd 守护进程的适配器。
weight: 70
---

Fluentd 适配器的设计目的是将 Istio 的日志发送给 [fluentd](https://www.fluentd.org/) 守护进程。

该适配器支持 [logentry template](/zh/docs/reference/config/policy-and-telemetry/templates/logentry/)。

## 参数

Fluentd 适配器的可接受 Instance 类型为 `kind: logentry`。这个适配器会用最小传输量的方式将日志传输给监听日志的 Fluentd 守护进程。Fluentd 会给收到的所有日志添加 `tag`。如果日志条目中包含了一个 `tag` 变量，就会使用它；否则将会使用 `Name` 作为 `tag`。

|字段|类型|说明|
|---|---|---|
|`address`|`string`|Fluentd 守护进程的地址。例如：`fluentd-server:24224`，缺省值为 `localhost:24224`|
|`integerDuration`|`bool`|将日志中的 `duration` 类型的属性转换为以毫秒为单位的整数值。缺省情况下会用包含计数单位的字符串来表达这种类型。|
