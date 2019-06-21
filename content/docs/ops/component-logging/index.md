---
title: Component Logging
description: Describes how to use component-level logging to get insights into a running component's behavior.
weight: 10
keywords: [ops]
aliases:
    - /help/ops/component-logging
---

Istio components are built with a flexible logging framework which provides a number of features and controls to
help operate these components and facilitate diagnostics. You control these logging features by passing
command-line options when starting the components.

## Logging scopes

Logging messages output by a component are categorized by *scopes*. A scope represents a set of related log messages which
you can control as a whole. Different components have different scopes, depending on the features the component
provides. All components have the `default` scope, which is used for non-categorized log messages.

As an example, as of this writing, Mixer has 5 scopes, representing different functional areas within Mixer:

- `adapters`
- `api`
- `attributes`
- `default`
- `grpcAdapter`

Pilot, Citadel, and Galley have their own scopes which you can discover by looking at their [reference documentation](/docs/reference/commands/).

Each scope has a unique output level which is one of:

1. none
1. error
1. warning
1. info
1. debug

where `none` produces no output for the scope, and `debug` produces the maximum amount of output. The default level for all scopes
is `info` which is intended to provide the right amount of logging information for operating Istio in normal conditions.

To control the output level, you use the `--log_output_level` command-line option. For example:

{{< text bash >}}
$ mixs server --log_output_level attributes=debug,adapters=warning
{{< /text >}}

In addition to controlling the output level from the command-line, you can also control the output level of a running component
by using its [ControlZ](/docs/ops/controlz) interface.

## Controlling output

Log messages are normally sent to a component's standard output stream. The `--log_target` option lets you direct the output to
any number of different locations. You give the option a comma-separated list of file system paths, along with the special
values `stdout` and `stderr` to indicate the standard output and standard error streams respectively.

Log messages are normally output in a human-friendly format. The `--log_as_json` option can be used to force the output into JSON,
which can be easier for tools to process.

## Log rotation

Istio components can automatically manage log rotation, which make it simple to break up large logs into smaller log files.
The `--log_rotate` option lets you specify the base file name to use for rotation. Derived names will be used for individual
log files.

The `--log_rotate_max_age` option lets you specify the maximum number of days before file rotation takes place, while the `--log_rotate_max_size` option
let you specify the maximum size in megabytes before file rotation takes place. Finally, the `--log_rotate_max_backups` option lets you control
the maximum number of rotated files to keep, older files will be automatically deleted.

## Component debugging

The `--log_caller` and `--log_stacktrace_level` options let you control whether log information includes
programmer-level information. This is useful when trying to track down bugs in a component but is not
normally used in day-to-day operation.
