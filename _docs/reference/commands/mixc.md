---
title: mixc
overview: Utility to trigger direct calls to Mixer's API.
layout: docs
order: 101
type: markdown
---

<a name="mixc_cmd"></a>
## mixc

Utility to trigger direct calls to Mixer's API.

### Synopsis


This command lets you interact with a running instance of
Mixer. Note that you need a pretty good understanding of Mixer's
API in order to use this command.

### Options

```
      --alsologtostderr                  log to standard error as well as files
  -a, --attributes string                List of name/value auto-sensed attributes specified as name1=value1,name2=value2,...
  -b, --bool_attributes string           List of name/value bool attributes specified as name1=value1,name2=value2,...
      --bytes_attributes string          List of name/value bytes attributes specified as name1=b0:b1:b3,name2=b4:b5:b6,...
  -d, --double_attributes string         List of name/value float64 attributes specified as name1=value1,name2=value2,...
      --duration_attributes string       List of name/value duration attributes specified as name1=value1,name2=value2,...
  -i, --int64_attributes string          List of name/value int64 attributes specified as name1=value1,name2=value2,...
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --log_dir string                   If non-empty, write log files in this directory
      --logtostderr                      log to standard error instead of files
  -m, --mixer string                     Address and port of a running Mixer instance (default "localhost:9091")
  -r, --repeat int                       Sends the specified number of requests in quick succession (default 1)
      --stderrthreshold severity         logs at or above this threshold go to stderr (default 2)
  -s, --string_attributes string         List of name/value string attributes specified as name1=value1,name2=value2,...
      --stringmap_attributes string      List of name/value string map attributes specified as name1=k1:v1;k2:v2,name2=k3:v3...
  -t, --timestamp_attributes string      List of name/value timestamp attributes specified as name1=value1,name2=value2,...
      --trace                            Whether to trace rpc executions
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="mixc_check"></a>
## mixc check

Invokes Mixer's Check API to perform precondition checks.

### Synopsis


The Check method is used to perform precondition checks. Mixer
expects a set of attributes as input, which it uses, along with
its configuration, to determine which adapters to invoke and with
which parameters in order to perform the precondition check.

```
mixc check
```

### Options inherited from parent commands

```
      --alsologtostderr                  log to standard error as well as files
  -a, --attributes string                List of name/value auto-sensed attributes specified as name1=value1,name2=value2,...
  -b, --bool_attributes string           List of name/value bool attributes specified as name1=value1,name2=value2,...
      --bytes_attributes string          List of name/value bytes attributes specified as name1=b0:b1:b3,name2=b4:b5:b6,...
  -d, --double_attributes string         List of name/value float64 attributes specified as name1=value1,name2=value2,...
      --duration_attributes string       List of name/value duration attributes specified as name1=value1,name2=value2,...
  -i, --int64_attributes string          List of name/value int64 attributes specified as name1=value1,name2=value2,...
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --log_dir string                   If non-empty, write log files in this directory
      --logtostderr                      log to standard error instead of files
  -m, --mixer string                     Address and port of a running Mixer instance (default "localhost:9091")
  -r, --repeat int                       Sends the specified number of requests in quick succession (default 1)
      --stderrthreshold severity         logs at or above this threshold go to stderr (default 2)
  -s, --string_attributes string         List of name/value string attributes specified as name1=value1,name2=value2,...
      --stringmap_attributes string      List of name/value string map attributes specified as name1=k1:v1;k2:v2,name2=k3:v3...
  -t, --timestamp_attributes string      List of name/value timestamp attributes specified as name1=value1,name2=value2,...
      --trace                            Whether to trace rpc executions
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="mixc_quota"></a>
## mixc quota

Invokes Mixer's Quota API in order to perform quota management.

### Synopsis


The Quota method is used to perform quota management. Mixer
expects a set of attributes as input, which it uses, along with
its configuration, to determine which adapters to invoke and with
which parameters in order to perform the quota operations.

```
mixc quota
```

### Options

```
      --amount int    The amount of quota to request (default 1)
      --bestEffort    Whether to use all-or-nothing or best effort semantics
      --name string   The name of the quota to allocate
```

### Options inherited from parent commands

```
      --alsologtostderr                  log to standard error as well as files
  -a, --attributes string                List of name/value auto-sensed attributes specified as name1=value1,name2=value2,...
  -b, --bool_attributes string           List of name/value bool attributes specified as name1=value1,name2=value2,...
      --bytes_attributes string          List of name/value bytes attributes specified as name1=b0:b1:b3,name2=b4:b5:b6,...
  -d, --double_attributes string         List of name/value float64 attributes specified as name1=value1,name2=value2,...
      --duration_attributes string       List of name/value duration attributes specified as name1=value1,name2=value2,...
  -i, --int64_attributes string          List of name/value int64 attributes specified as name1=value1,name2=value2,...
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --log_dir string                   If non-empty, write log files in this directory
      --logtostderr                      log to standard error instead of files
  -m, --mixer string                     Address and port of a running Mixer instance (default "localhost:9091")
  -r, --repeat int                       Sends the specified number of requests in quick succession (default 1)
      --stderrthreshold severity         logs at or above this threshold go to stderr (default 2)
  -s, --string_attributes string         List of name/value string attributes specified as name1=value1,name2=value2,...
      --stringmap_attributes string      List of name/value string map attributes specified as name1=k1:v1;k2:v2,name2=k3:v3...
  -t, --timestamp_attributes string      List of name/value timestamp attributes specified as name1=value1,name2=value2,...
      --trace                            Whether to trace rpc executions
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="mixc_report"></a>
## mixc report

Invokes Mixer's Report API to generate telemetry.

### Synopsis


The Report method is used to produce telemetry. Mixer
expects a set of attributes as input, which it uses, along with
its configuration, to determine which adapters to invoke and with
which parameters in order to output the telemetry.

```
mixc report
```

### Options inherited from parent commands

```
      --alsologtostderr                  log to standard error as well as files
  -a, --attributes string                List of name/value auto-sensed attributes specified as name1=value1,name2=value2,...
  -b, --bool_attributes string           List of name/value bool attributes specified as name1=value1,name2=value2,...
      --bytes_attributes string          List of name/value bytes attributes specified as name1=b0:b1:b3,name2=b4:b5:b6,...
  -d, --double_attributes string         List of name/value float64 attributes specified as name1=value1,name2=value2,...
      --duration_attributes string       List of name/value duration attributes specified as name1=value1,name2=value2,...
  -i, --int64_attributes string          List of name/value int64 attributes specified as name1=value1,name2=value2,...
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --log_dir string                   If non-empty, write log files in this directory
      --logtostderr                      log to standard error instead of files
  -m, --mixer string                     Address and port of a running Mixer instance (default "localhost:9091")
  -r, --repeat int                       Sends the specified number of requests in quick succession (default 1)
      --stderrthreshold severity         logs at or above this threshold go to stderr (default 2)
  -s, --string_attributes string         List of name/value string attributes specified as name1=value1,name2=value2,...
      --stringmap_attributes string      List of name/value string map attributes specified as name1=k1:v1;k2:v2,name2=k3:v3...
  -t, --timestamp_attributes string      List of name/value timestamp attributes specified as name1=value1,name2=value2,...
      --trace                            Whether to trace rpc executions
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

<a name="mixc_version"></a>
## mixc version

Prints out build version information

### Synopsis


Prints out build version information

```
mixc version
```

### Options inherited from parent commands

```
      --alsologtostderr                  log to standard error as well as files
  -a, --attributes string                List of name/value auto-sensed attributes specified as name1=value1,name2=value2,...
  -b, --bool_attributes string           List of name/value bool attributes specified as name1=value1,name2=value2,...
      --bytes_attributes string          List of name/value bytes attributes specified as name1=b0:b1:b3,name2=b4:b5:b6,...
  -d, --double_attributes string         List of name/value float64 attributes specified as name1=value1,name2=value2,...
      --duration_attributes string       List of name/value duration attributes specified as name1=value1,name2=value2,...
  -i, --int64_attributes string          List of name/value int64 attributes specified as name1=value1,name2=value2,...
      --log_backtrace_at traceLocation   when logging hits line file:N, emit a stack trace (default :0)
      --log_dir string                   If non-empty, write log files in this directory
      --logtostderr                      log to standard error instead of files
  -m, --mixer string                     Address and port of a running Mixer instance (default "localhost:9091")
  -r, --repeat int                       Sends the specified number of requests in quick succession (default 1)
      --stderrthreshold severity         logs at or above this threshold go to stderr (default 2)
  -s, --string_attributes string         List of name/value string attributes specified as name1=value1,name2=value2,...
      --stringmap_attributes string      List of name/value string map attributes specified as name1=k1:v1;k2:v2,name2=k3:v3...
  -t, --timestamp_attributes string      List of name/value timestamp attributes specified as name1=value1,name2=value2,...
      --trace                            Whether to trace rpc executions
  -v, --v Level                          log level for V logs
      --vmodule moduleSpec               comma-separated list of pattern=N settings for file-filtered logging
```

