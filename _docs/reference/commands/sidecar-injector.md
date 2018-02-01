---
title: sidecar-injector
overview: Kubernetes webhook for automatic Istio sidecar injection
layout: docs
---
Kubernetes webhook for automatic Istio sidecar injection
```bash
sidecar-injector [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|`--injectConfig <string>`||File containing the Istio sidecar injection configuration and template  (default `"/etc/istio/inject/config"`)
|`--log_as_json`||Whether to format output as JSON or in plain console-friendly format 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_callers`||Include caller information, useful for debugging 
|`--log_output_level <string>`||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default `"info"`)
|`--log_rotate <string>`||The path for the optional rotating log file  (default `""`)
|`--log_rotate_max_age <int>`||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default `30`)
|`--log_rotate_max_backups <int>`||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default `1000`)
|`--log_rotate_max_size <int>`||The maximum size in megabytes of a log file beyond which the file is rotated  (default `104857600`)
|`--log_stacktrace_level <string>`||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default `"none"`)
|`--log_target <stringArray>`||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default `[stdout]`)
|`--meshConfig <string>`||File containing the Istio mesh configuration  (default `"/etc/istio/config/mesh"`)
|`--port <int>`||Webhook port  (default `443`)
|`--tlsCertFile <string>`||File containing the x509 Certificate for HTTPS.  (default `"/etc/istio/certs/cert.pem"`)
|`--tlsKeyFile <string>`||File containing the x509 private key matching --tlsCertFile.  (default `"/etc/istio/certs/key.pem"`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)


## sidecar-injector version

Prints out build version information
```bash
sidecar-injector version [flags]
```


|Option|Shorthand|Description
|------|---------|-----------
|`--injectConfig <string>`||File containing the Istio sidecar injection configuration and template  (default `"/etc/istio/inject/config"`)
|`--log_as_json`||Whether to format output as JSON or in plain console-friendly format 
|`--log_backtrace_at <traceLocation>`||when logging hits line file:N, emit a stack trace  (default `:0`)
|`--log_callers`||Include caller information, useful for debugging 
|`--log_output_level <string>`||The minimum logging level of messages to output, can be one of "debug", "info", "warn", "error", or "none"  (default `"info"`)
|`--log_rotate <string>`||The path for the optional rotating log file  (default `""`)
|`--log_rotate_max_age <int>`||The maximum age in days of a log file beyond which the file is rotated (0 indicates no limit)  (default `30`)
|`--log_rotate_max_backups <int>`||The maximum number of log file backups to keep before older files are deleted (0 indicates no limit)  (default `1000`)
|`--log_rotate_max_size <int>`||The maximum size in megabytes of a log file beyond which the file is rotated  (default `104857600`)
|`--log_stacktrace_level <string>`||The minimum logging level at which stack traces are captured, can be one of "debug", "info", "warn", "error", or "none"  (default `"none"`)
|`--log_target <stringArray>`||The set of paths where to output the log. This can be any path as well as the special values stdout and stderr  (default `[stdout]`)
|`--meshConfig <string>`||File containing the Istio mesh configuration  (default `"/etc/istio/config/mesh"`)
|`--port <int>`||Webhook port  (default `443`)
|`--short`|`-s`|Displays a short form of the version information 
|`--tlsCertFile <string>`||File containing the x509 Certificate for HTTPS.  (default `"/etc/istio/certs/cert.pem"`)
|`--tlsKeyFile <string>`||File containing the x509 private key matching --tlsCertFile.  (default `"/etc/istio/certs/key.pem"`)
|`--v <Level>`|`-v`|log level for V logs  (default `0`)
|`--vmodule <moduleSpec>`||comma-separated list of pattern=N settings for file-filtered logging  (default ``)

