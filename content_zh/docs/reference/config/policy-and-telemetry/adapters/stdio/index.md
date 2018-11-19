---
title: Stdio
description: 该适配器可以在本地输出日志和指标。
weight: 200
---

`stdio` 适配器让 Istio 能够在本机上输出日志和指标数据。日志和指标能够定向输出到 Mixer 的 stdout、stderror 或者任意本地可达的文件中。当输出到文件时，可以启用日志翻转特性，让适配器在输出数据的同时，自动的进行文件备份。

该适配器支持 [`logentry`](/zh/docs/reference/config/policy-and-telemetry/templates/logentry/) 和 [`metric`](/zh/docs/reference/config/policy-and-telemetry/templates/metric/) 两种模板。

## 参数

`stdio` 的格式配置。

|字段|类型|描述|
|---|---|---|
|`logStream`|[`Stream`](#stream)|选择一个用于写入的输出流，缺省会选择 `STDERR`|
|`severityLevels`|`map<string,` [`Level`](#level) `>`|从 LogEntry 实例的字符串映射到该适配器支持的日志级别列表，缺省的映射关系见附表|
|`metricLevel`|[`Level`](#level)|分配给被输出指标的级别，缺省为 `INFO`|
|`outputAsJson`|`bool`|是否将输出调整为 JSON 格式|
|`outputLevel`|[`Level`](#level)|输出的最低级别，高于此级别的内容不予输出。缺省设置为 `INFO`|
|`outputPath`|`string`|进行文件输出和翻转的时候所使用的文件路径。当使用日志文件翻转特性时，这一路径会作为基础路径。通常情况下日志输出到这里。当因为文件尺寸超大或者时间太久启动翻转时，该文件会在文件名中加入时间戳进行重命名。这些被重命名的文件被称为备份。备份文件创建成功以后，就恢复到原路径的输出|
|`maxMegabytesBeforeRotation`|`int32`|以兆为单位的文件尺寸限制，超过这一尺寸则进行翻转。缺省为 100 兆|
|`maxDaysBeforeRotation`|`int32`|备份文件的保留天数，文件的时间戳从文件名中获取。注意这里定义每天 24 个小时，会因为夏令时影响而无法完全对应。默认情况下会删除超过 30 天的日志。0 表示没限制|
|`maxRotateFiles`|`int32`|备份文件的保留数量|

### 日志级别映射关系

{{< text plain >}}
"INFORMATIONAL" : INFO,
"informational" : INFO,
"INFO" : INFO,
"info" : INFO,
"WARNING" : WARNING,
"warning" : WARNING,
"WARN": WARNING,
"warning": WARNING,
"ERROR": ERROR,
"error": ERROR,
"ERR": ERROR,
"err": ERROR,
"FATAL": ERROR,
"fatal": ERROR,
{{< /text >}}

## `Level`

适配器输出的项目的级别。

|字段|描述|
|---|---|
|`INFO`|包括信息、警告和错误信息|
|`WARNING`|包括警告和错误信息|
|`ERROR`|只包括错误信息|

## `Stream`

这一参数用于指定输出位置。

|字段|描述|
|---|---|
|`STDOUT`|输出到 Mixer 进程的标准输出流，这是缺省选项|
|`STDERR`|输出到 Mixer 进程的标准错误流|
|`FILE`|输出到指定文件|
|`ROTATED_FILE`|输出到指定的翻转文件，具体翻转方式由前述参数指定|