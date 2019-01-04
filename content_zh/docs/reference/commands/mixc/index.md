---
title: mixc
description: 用于触发直接调用 Mixer API 的实用程序。
generator: pkg-collateral-docs
number_of_entries: 5
---

此命令允许您与正在运行的 Mixer 实例进行交互。请注意，您需要非常深入地了解 Mixer 的 API 才能使用此命令。

## `mixc` check

Check 方法用于检查执行前提条件和配额分配。Mixer 需要一组属性作为输入，它使用输入的配置来确定要调用哪些适配器，以及使用哪些参数来执行检查和配额分配。

{{< text bash >}}

$ mixc check [flags]

{{< /text >}}

| 参数 | 缩写 | 描述 |
| --- | --- | --- |
| `--attributes <string>` | `-a` | 名称/值自动感知属性列表，指定为 `name1=value1`，`name2=value2`，...（默认为 `''`） |
| `--bool_attributes <string>` | `-b` | 名称/值 `bool` 属性列表，指定为 `name1=value1`，`name2=value2`，...（默认为 `''`） |
| `--bytes_attributes <string>` |  | 名称/值 `bytes` 属性列表，指定为 `name1=b0:b1:b3`，`name2=b4:b5:b6`，...（默认为 `''`） |
| `--double_attributes <string>` | `-d` | 名称/值 `float64` 属性列表，指定为 `name1=value1`，`name2=value2`，...（默认 `''`） |
| `--duration_attributes <string>` |  | 名称/值 `duration` 属性列表，指定为 `name1=value1`，`name2=value2`，...（默认为 `''`） |
| `--int64_attributes <string>` | `-i` | 名称/值 int64 属性列表指定为 `name1=value1`，`name2=value2`，...（默认 `''`） |
| `--mixer <string>` | `-m` | 正在运行的 Mixer 实例的地址和端口（默认为`localhost:9091`） |
| `--quotas <string>` | `-q` | 要分配的配额列表，指定为 `name1=amount1`，`name2=amount2`，...（默认 `''`） |
| `--repeat <int>` | `-r` | 快速连续发送指定数量的请求（默认为 `1`） |
| `--string_attributes <string>` | `-s` | 指定为 `name1=value1`，`name2=value2`，...的名称/值字符串属性列表（默认为 `''`） |
| `--stringmap_attributes <string>` |  | 名称/值字符串 map 属性的列表，指定为 `name1=k1:v1; k2:v2`，`name2=k3:v3` ...（默认为 `''`） |
| `--timestamp_attributes <string>` | `-t` | 名称/值时间戳属性列表，指定为 `name1=value1`，`name2=value2`，...（默认为 `''`） |
| `--trace_jaeger_url <string>` |  | Jaeger HTTP 收集器的 URL（例如: `http://jaeger:14268/api/traces?format=jaeger.thrift` ）。（默认 `''`） |
| `--trace_log_spans` |  | 是否记录跟踪 span。|
| `--trace_zipkin_url <string>` |  | Zipkin 收集器的 URL（例如: `http://zipkin:9411/api/v1/spans` ）。（默认 `''`） |

## `mixc` report

Report 方法用于生成遥测。Mixer 需要一组属性作为输入，它使用输入的配置来确定要调用哪些适配器，以及使用哪些参数来输出遥测。

{{< text bash >}}

$ mixc report [flags]

{{< /text >}}

| 参数 | 缩写 | 描述 |
| --- | --- | --- |
| `--attributes <string>` | `-a` | 名称/值自动感知属性列表，指定为 `name1=value1`，`name2=value2`，...（默认为 `''`） |
| `--bool_attributes <string>` | `-b` | 名称/值 `bool` 属性列表，指定为 `name1=value1`，`name2=value2`，...（默认为 `''`） |
| `--bytes_attributes <string>` |  | 名称/值字节属性列表，指定为 `name1=b0:b1:b3`，`name2=b4:b5:b6`，...（默认为 `''`） |
| `--double_attributes <string>` | `-d` | 名称/值 `float64` 属性列表，指定为 `name1=value1`，`name2=value2`，...（默认 `''`） |
| `--duration_attributes <string>` |  | 名称/值持续时间属性列表，指定为 `name1=value1`，`name2=value2`，...（默认为 `''`） |
| `--int64_attributes <string>` | `-i` | 名称/值 int64 属性列表指定为 `name1=value1`，`name2=value2`，...（默认 `''`） |
| `--mixer <string>` | `-m` | 正在运行的 Mixer 实例的地址和端口（默认为`localhost:9091`） |
| `--repeat <int>` | `-r` | 快速连续发送指定数量的请求（默认为 `1`） |
| `--string_attributes <string>` | `-s` | 指定为 `name1=value1`，`name2=value2`，...的名称/值字符串属性列表（默认为 `''`） |
| `--stringmap_attributes <string>` |  | 名称/值字符串 map 属性的列表，指定为 `name1=k1:v1`; `k2:v2`，`name2=k3:v3` ...（默认为 `''`） |
| `--timestamp_attributes <string>` | `-t` | 名称/值时间戳属性列表，指定为 `name1=value1`，`name2=value2`，...（默认为 `''`） |
| `--trace_jaeger_url <string>` |  | Jaeger HTTP 收集器的 URL（例如: `http://jaeger:14268/api/traces?format=jaeger.thrift` ）。（默认 `''`） |
| `--trace_log_spans` |  | 是否记录跟踪 span。|
| `--trace_zipkin_url <string>` |  | Zipkin 收集器的 URL（例如: `http://zipkin:9411/api/v1/spans` ）。（默认 `''`） |

## `mixc` version

打印出版本信息

{{< text bash >}}

$ mixc version [flags]

{{< /text >}}

| 参数 | 缩写 | 描述 |
| --- | --- | --- |
| `--short` | `-s` | 显示简短形式的版本信息 |