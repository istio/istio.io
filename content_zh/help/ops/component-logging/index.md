---
title: 组件日志
description: 描述如何使用组件日志来深入了解运行组件的行为。
weight: 10
keywords: [ops]
---

Istio 组件采用灵活的日志框架构建，日志框架提供了许多有利于组件操作和诊断的功能。日志记录功能可在组件启动时通过命令行选项进行控制。

## 日志 Scopes

组件输出的记录消息按 `scope` 分类。scope 表示一组可以作为整体控制的相关日志消息。取决于提供的功能，组件可具有不同的 scope。所有组件都具有 `default` scope ，用于未分类的日志消息。

例如，截止当前，Mixer 有 5 个 scope ，表示 Mixer 内不同功能区域：

- `adapters`
- `api`
- `attributes`
- `default`
- `grpcAdapter`

Pilot，Citadel 和 Galley 有不同的 scope ，具体参见[参考文档](/zh/docs/reference/commands/)。

每个 scope 都有一个独特的输出级别，取值如下：

1. none
1. error
1. warning
1. info
1. debug

其中 `none` 级别 scope 不产生输出，`debug` 将产生最大量输出。所有 scope 的默认级别是 `info`，保证正常条件下 Istio 操作提供适当的日志信息。

要控制日志输出级别，可使用 `--log_output_level` 命令行选项。例如：

{{< text bash >}}
$ mixs server --log_output_level attributes=debug,adapters=warning
{{< /text >}}

除从命令行控制输出级别外，还可以使用其 [ControlZ](/zh/help/ops/controlz) 接口控制正在运行的组件的日志输出级别。

## 控制输出

日志消息通常发送到组件的标准输出流。`--log_target` 选项允许将输出定向到任意数量的其他位置。可以为其选项提供逗号分隔的文件系统路径列表，以及特殊值 `stdout` 和 `stderr`，分别表示标准输出和标准错误流。

日志消息通常以人性化的格式输出。`--log_as_json` 选项可用于强制输出为 JSON 格式，以方便于工具处理。

## 日志轮换

Istio 组件可以自动管理日志轮换，这使得将大型日志分解为更小的日志文件变得简单。 `--log_rotate` 选项允许指定用于轮换的基本文件名。派生名称将用于单个日志文件。

`--log_rotate_max_age` 选项允许指定文件轮换发生前的最大天数，而 `--log_rotate_max_size` 选项允许指定文件轮换发生前的最大大小（以兆字节为单位）。最后，使用 `--log_rotate_max_backups` 选项可以控制要保留的最大轮换文件数，用于自动删除旧文件。

## 组件调试

使用 `--log_caller` 和 `--log_stacktrace_level` 选项可以控制日志信息是否包含程序级别的信息。这在尝试跟踪组件中的错误时很有用，但通常不会在日常操作中使用。