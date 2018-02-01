---
title: mixs
overview: Mixer is Istio's abstraction on top of infrastructure backends.
layout: docs
---
Mixer is Istio's point of integration with infrastructure backends and is the
nexus for policy evaluation and telemetry reporting.

|Option|Shorthand|Description
|------|---------|-----------
|`--alsologtostderr`||log to standard error as well as files 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_dir <string>`||If non-empty, write log files in this directory  (default `""`)
|`--logtostderr`||log to standard error instead of files 
|`--stderrthreshold <severity>`||logs at or above this threshold go to stderr  (default `2`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)


## mixs crd

CRDs (CustomResourceDefinition) available in Mixer

|Option|Shorthand|Description
|------|---------|-----------
|`--alsologtostderr`||log to standard error as well as files 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_dir <string>`||If non-empty, write log files in this directory  (default `""`)
|`--logtostderr`||log to standard error instead of files 
|`--stderrthreshold <severity>`||logs at or above this threshold go to stderr  (default `2`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)


## mixs crd adapter

List CRDs for available adapters
```bash
mixs crd adapter [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|`--alsologtostderr`||log to standard error as well as files 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_dir <string>`||If non-empty, write log files in this directory  (default `""`)
|`--logtostderr`||log to standard error instead of files 
|`--stderrthreshold <severity>`||logs at or above this threshold go to stderr  (default `2`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)


## mixs crd all

List all CRDs
```bash
mixs crd all [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|`--alsologtostderr`||log to standard error as well as files 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_dir <string>`||If non-empty, write log files in this directory  (default `""`)
|`--logtostderr`||log to standard error instead of files 
|`--stderrthreshold <severity>`||logs at or above this threshold go to stderr  (default `2`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)


## mixs crd instance

List CRDs for available instance kinds (mesh functions)
```bash
mixs crd instance [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|`--alsologtostderr`||log to standard error as well as files 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_dir <string>`||If non-empty, write log files in this directory  (default `""`)
|`--logtostderr`||log to standard error instead of files 
|`--stderrthreshold <severity>`||logs at or above this threshold go to stderr  (default `2`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)


## mixs probe

Check the liveness or readiness of a locally-running server
```bash
mixs probe [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|`--alsologtostderr`||log to standard error as well as files 
|`--interval <duration>`||Duration used for checking the target file's last modified time.  (default `0s`)
|`--log_as_json`||Whether to format output as JSON or in plain console-friendly format 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_callers`||Include caller information, useful for debugging 
|`--log_dir <string>`||If non-empty, write log files in this directory  (default `""`)
|`--log_output_level <string>`||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default `"info"`)
|`--log_rotate <string>`||The path for the optional rotating log file  (default `""`)
|`--log_rotate_max_age <int>`||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default `30`)
|`--log_rotate_max_backups <int>`||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default `1000`)
|`--log_rotate_max_size <int>`||The maximum size in megabytes of a log file beyond which the file is rotated  (default `104857600`)
|`--log_stacktrace_level <string>`||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default `"none"`)
|`--log_target <stringArray>`||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default `[stdout]`)
|`--logtostderr`||log to standard error instead of files 
|`--probe-path <string>`||Path of the file for checking the availability.  (default `""`)
|`--stderrthreshold <severity>`||logs at or above this threshold go to stderr  (default `2`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)


## mixs server

Starts Mixer as a server
```bash
mixs server [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|`--adapterWorkerPoolSize <int>`||Max number of goroutines in the adapter worker pool  (default `1024`)
|`--alsologtostderr`||log to standard error as well as files 
|`--apiWorkerPoolSize <int>`||Max number of goroutines in the API worker pool  (default `1024`)
|`--configDefaultNamespace <string>`||Namespace used to store mesh wide configuration.  (default `"istio-system"`)
|`--configStoreURL <string>`||URL of the config store. Use k8s://path_to_kubeconfig or fs:// for file system. If path_to_kubeconfig is empty, in-cluster kubeconfig is used.  (default `""`)
|`--expressionEvalCacheSize <int>`||Number of entries in the expression cache  (default `1024`)
|`--livenessProbeInterval <duration>`||Interval of updating file for the liveness probe.  (default `0s`)
|`--livenessProbePath <string>`||Path to the file for the liveness probe.  (default `""`)
|`--log_as_json`||Whether to format output as JSON or in plain console-friendly format 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_callers`||Include caller information, useful for debugging 
|`--log_dir <string>`||If non-empty, write log files in this directory  (default `""`)
|`--log_output_level <string>`||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default `"info"`)
|`--log_rotate <string>`||The path for the optional rotating log file  (default `""`)
|`--log_rotate_max_age <int>`||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default `30`)
|`--log_rotate_max_backups <int>`||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default `1000`)
|`--log_rotate_max_size <int>`||The maximum size in megabytes of a log file beyond which the file is rotated  (default `104857600`)
|`--log_stacktrace_level <string>`||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default `"none"`)
|`--log_target <stringArray>`||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default `[stdout]`)
|`--logtostderr`||log to standard error instead of files 
|`--maxConcurrentStreams <uint>`||Maximum number of outstanding RPCs per connection  (default `1024`)
|`--maxMessageSize <uint>`||Maximum size of individual gRPC messages  (default `1048576`)
|`--monitoringPort <uint16>`||HTTP port to use for the exposing mixer self-monitoring information  (default `9093`)
|`--port <uint16>`|`-p`|TCP port to use for Mixer's gRPC API  (default `9091`)
|`--readinessProbeInterval <duration>`||Interval of updating file for the readiness probe.  (default `0s`)
|`--readinessProbePath <string>`||Path to the file for the readiness probe.  (default `""`)
|`--singleThreaded`||If true, each request to Mixer will be executed in a single go routine (useful for debugging) 
|`--stderrthreshold <severity>`||logs at or above this threshold go to stderr  (default `2`)
|`--trace_jaeger_url <string>`||URL of Jaeger HTTP collector (example: 'http://jaeger:14268/api/traces?format=jaeger.thrift').  (default `""`)
|`--trace_log_spans`||Whether or not to log trace spans. 
|`--trace_zipkin_url <string>`||URL of Zipkin collector (example: 'http://zipkin:9411/api/v1/spans').  (default `""`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)


## mixs validator

Runs an https server for validations. Works as an external admission webhook for k8s
```bash
mixs validator [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|`--alsologtostderr`||log to standard error as well as files 
|`--external-admission-webook-name <string>`||the name of the external admission webhook registration. Needs to be a domain with at least three segments separated by dots.  (default `"mixer-webhook.istio.io"`)
|`--kubeconfig <string>`||Use a Kubernetes configuration file instead of in-cluster configuration  (default `""`)
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_dir <string>`||If non-empty, write log files in this directory  (default `""`)
|`--logtostderr`||log to standard error instead of files 
|`--namespace <string>`||the namespace where this webhook is deployed  (default `"istio-system"`)
|`--port <int>`|`-p`|the port number of the webhook  (default `9099`)
|`--registration-delay <duration>`||Time to delay webhook registration after starting webhook server  (default `5s`)
|`--secret-name <string>`||The name of k8s secret where the certificates are stored  (default `""`)
|`--stderrthreshold <severity>`||logs at or above this threshold go to stderr  (default `2`)
|`--target-namespaces <stringArray>`||the list of namespaces where changes should be validated. Empty means to validate everything. Used for test only.  (default `[]`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)
|`--webhook-name <string>`||the name of the webhook  (default `"istio-mixer-webhook"`)


## mixs version

Prints out build version information
```bash
mixs version [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|`--alsologtostderr`||log to standard error as well as files 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_dir <string>`||If non-empty, write log files in this directory  (default `""`)
|`--logtostderr`||log to standard error instead of files 
|`--short`|`-s`|Displays a short form of the version information 
|`--stderrthreshold <severity>`||logs at or above this threshold go to stderr  (default `2`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)

