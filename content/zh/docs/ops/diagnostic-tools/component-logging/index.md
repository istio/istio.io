---
title: 组件日志记录
description: 如何使用组件的级别日志来记录正在运行中的组件的行为。
weight: 70
keywords: [ops]
aliases:
  - /zh/help/ops/component-logging
  - /zh/docs/ops/troubleshooting/component-logging
---

Istio 组件使用一个灵活的日志框架来构建，该框架提供了许多功能和控件去帮助操作这些组件并促进诊断，在启动组件的时候，可以通过在命令行传递参数来控制这些日志记录功能。

## 记录范围{#logging-scopes}

组件输出的日志信息按 `作用域` 分类，一个作用域代表可以被控制的相关日志信息的整体。根据组件提供的功能，不同的组件具有不同的作用域。所有组件都有 `default` 作用域，该作用域用于未分类的日志信息。

例如，在撰写本文时，Mixer 有 5 个作用域，代表了 Mixer 中的不同功能区域：

- `adapters`
- `api`
- `attributes`
- `default`
- `grpcAdapter`

Pilot、Citadel 和 Galley 具有它们自己的范围，你可以通过查看它们的[参考文档](/zh/docs/reference/commands/)来获取更多信息。

每个作用域都有一个唯一的输出级别，为下列其中之一：

1. none
1. error
1. warning
1. info
1. debug

其中 `none` 不产生任何输出信息，并且 `debug` 产生的输出信息最多。 所有作用域的默认级别是 `info` ，为在正常情况下使用 Istio 提供大量的日志信息。

要控制输出级别，也可以在命令行使用 `--log_output_level` 选项。例如：

{{< text bash >}}
$ mixs server --log_output_level attributes=debug,adapters=warning
{{< /text >}}

除了从命令行控制输出级别外，你也可以使用 [ControlZ](/zh/docs/ops/diagnostic-tools/controlz) 界面控制一个运行组件的输出级别。

## 控制输出{#controlling-output}

日志信息通常发送到组件的标准输出。 `--log_target` 选项可以定向输出到许多不同的位置。你可以使用一个逗号分隔列表中的文件系统路径，以及分别表示标准输出和标准错误输出流的特殊值 `stdout` 和 `stderr` 。

日志信息通常以友好的格式输出。 `--log_as_json` 选项可用于将输出强制转换为 JSON 格式，以便于更简单地被工具处理。

## 日志轮转{#log-rotation}

Istio 组件可以自动管理日志的轮转，将庞大的日志分解为较小的日志文件。 `--log_rotate` 选项可以让你基于文件名进行轮转。派生名称将用于单个日志文件。

`--log_rotate_max_age` 选项可以在日志文件被轮转前指定最大天数，然而 `--log_rotate_max_size` 选项可以指定文件轮转之前的最大 size （以兆字节为单位）。最后， `--log_rotate_max_backups` 选项可以控制要保留的最大轮转文件数，较旧的文件将被自动删除。

## 组件调试{#component-debugging}

`--log_caller` 和 `--log_stacktrace_level` 选项可以控制日志信息是否包括程序员级别的信息。当你试着查找组件中的错误信息时它是有用的，但是，通常在日常操作中不使用。
